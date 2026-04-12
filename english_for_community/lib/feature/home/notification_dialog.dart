import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/locale/l10n_context.dart';
import '../../l10n/generated/app_localizations.dart';

// Import Bloc & Entity
import '../../../../core/entity/notification_entity.dart';
import 'bloc_noti/notification_bloc.dart';
import 'bloc_noti/notification_event.dart';
import 'bloc_noti/notification_state.dart';

String formatNotificationTime(DateTime time, AppLocalizations t) {
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inMinutes < 1) return t.timeJustNow;
  if (diff.inMinutes < 60) return t.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return t.timeHoursAgo(diff.inHours);
  return DateFormat('dd/MM HH:mm').format(time);
}

class NotificationDialog extends StatefulWidget {
  const NotificationDialog({super.key});

  @override
  State<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Call event to load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationBloc>().add(const NotificationLoadStarted(isRefresh: true));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<NotificationBloc>().add(NotificationLoadMore());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  /// Điều hướng sau khi đóng dialog — lấy [GoRouter] trước [Navigator.pop] để không dùng
  /// [BuildContext] của route đã gỡ sau pop.
  void _handleNavigation(BuildContext context, NotificationEntity item) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();

    try {
      final Map<String, dynamic> data = item.data ?? {};
      final String type = (data['type'] as String?) ?? item.type;

      if (data.containsKey('listeningId')) {
        final String listeningId = '${data['listeningId']}';
        final String? commentId = data['commentId']?.toString();
        final String? cueId = data['cueId']?.toString();
        final String audioUrl = data['audioUrl']?.toString() ?? '';

        router.pushNamed(
          'ListeningSkillsPage',
          pathParameters: {'listeningId': listeningId},
          extra: {
            'listeningId': listeningId,
            'audioUrl': audioUrl,
            'targetCommentId': commentId,
            'cueId': cueId,
            'openDiscussion': true,
          },
        );
      } else if (type == 'REVIEW_REMINDER') {
        router.pushNamed(
          'VocabularyPage',
          extra: const {'initialTabIndex': 1},
        );
      } else if (type == 'DAILY_VOCAB' || type == 'DAILY_REMINDER' || data.containsKey('wordId')) {
        router.pushNamed(
          'VocabularyPage',
          extra: const {'initialTabIndex': 0},
        );
      }
    } catch (e, st) {
      debugPrint('Error navigating from notification: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    const borderColor = Color(0xFFE4E4E7);
    const primaryText = Color(0xFF09090B);
    const mutedText = Color(0xFF71717A);
    const bgHover = Color(0xFFF4F4F5);

    return Dialog(
      backgroundColor: Colors.white,
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- HEADER ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.notificationsTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryText,
                    letterSpacing: -0.5,
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    context.read<NotificationBloc>().add(NotificationMarkAllRead());
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      t.markAllRead,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- BODY LIST ---
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 500),
              child: BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  if (state.status == NotificationStatus.loading && state.notifications.isEmpty) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  }

                  if (state.status == NotificationStatus.failure && state.notifications.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            state.errorMessage ?? t.failedToLoadData,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: mutedText, fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              context.read<NotificationBloc>().add(const NotificationLoadStarted(isRefresh: false));
                            },
                            child: Text(t.retry),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state.notifications.isEmpty) {
                    return _EmptyState(primaryText: primaryText, mutedText: mutedText, l10n: t);
                  }

                  return ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    itemCount: state.hasReachedMax
                        ? state.notifications.length
                        : state.notifications.length + 1,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: borderColor),
                    itemBuilder: (context, index) {
                      if (index >= state.notifications.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      final item = state.notifications[index];
                      return _NotificationItem(
                        item: item,
                        primaryText: primaryText,
                        mutedText: mutedText,
                        bgHover: bgHover,
                        l10n: t,
                        onTap: () {
                          // 1. Mark as read
                          context.read<NotificationBloc>().add(NotificationMarkRead(item.id));

                          // 2. Navigate
                          _handleNavigation(context, item);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // --- FOOTER ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: mutedText,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(t.close, style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}

// ... (Sub-widgets)
class _NotificationItem extends StatelessWidget {
  final NotificationEntity item;
  final Color primaryText;
  final Color mutedText;
  final Color bgHover;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.item,
    required this.primaryText,
    required this.mutedText,
    required this.bgHover,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = item.isRead ? Colors.white : const Color(0xFFF8FAFC);
    final bool isSystem = item.senderAvatar == null || item.senderAvatar!.isEmpty;
    return Material(
      color: bgColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE4E4E7)),
                      // Show avatar if available
                      image: !isSystem
                          ? DecorationImage(image: NetworkImage(item.senderAvatar!), fit: BoxFit.cover)
                          : null,
                      // If System -> Show different bg color
                      color: isSystem ? Colors.blue.withOpacity(0.1) : Colors.white,
                    ),
                    child: isSystem
                    // 🔥 SYSTEM ICON
                        ? Icon(Icons.notifications_active, size: 20, color: Theme.of(context).primaryColor)
                        : null,
                  ),

                  // Notification Type Icon (Small)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE4E4E7), width: 1),
                      ),
                      child: _getTypeIcon(item.type),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 14, color: primaryText, height: 1.4),
                        children: [
                          TextSpan(
                            text: "${item.senderName} ",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: item.message,
                            style: const TextStyle(color: Color(0xFF3F3F46)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatNotificationTime(item.createdAt, l10n),
                      style: TextStyle(fontSize: 12, color: mutedText, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (!item.isRead)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 8),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getTypeIcon(String type) {
    switch (type) {
      case 'COMMENT_REPLY':
        return const Icon(Icons.reply_rounded, size: 12, color: Colors.blue);
      case 'COMMENT_REACTION':
        return const Icon(Icons.favorite_rounded, size: 12, color: Colors.redAccent);
      case 'SYSTEM_ANNOUNCEMENT':
      case 'DAILY_VOCAB':
      case 'REVIEW_REMINDER':
        return const Icon(Icons.campaign_rounded, size: 12, color: Colors.amber);
      default:
        return const Icon(Icons.notifications_rounded, size: 12, color: Colors.grey);
    }
  }

}

class _EmptyState extends StatelessWidget {
  final Color primaryText;
  final Color mutedText;
  final AppLocalizations l10n;
  const _EmptyState({required this.primaryText, required this.mutedText, required this.l10n});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF4F4F5), shape: BoxShape.circle),
            child: Icon(Icons.notifications_off_outlined, size: 32, color: mutedText),
          ),
          const SizedBox(height: 16),
          Text(l10n.notificationsEmptyTitle, style: TextStyle(color: primaryText, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(l10n.notificationsEmptyBody, style: TextStyle(color: mutedText, fontSize: 13)),
        ],
      ),
    );
  }
}