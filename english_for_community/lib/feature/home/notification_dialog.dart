import 'package:english_for_community/core/entity/notification_entity.dart';
import 'package:english_for_community/core/notification/notification_navigation.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/feature/home/bloc_noti/notification_bloc.dart';
import 'package:english_for_community/feature/home/bloc_noti/notification_event.dart';
import 'package:english_for_community/feature/home/bloc_noti/notification_state.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

  void _handleNavigation(BuildContext context, NotificationEntity item) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    if (!navigateFromNotification(router, item: item)) {
      debugPrint('No route for notification type: ${item.type}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sheet + 2),
        side: const BorderSide(color: AppColors.outline),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s6, AppSpacing.s5, AppSpacing.s4, AppSpacing.s4),
              child: Row(
                children: [
                  Expanded(child: Text(t.notificationsTitle, style: StudentMobileUi.sectionTitle(context))),
                  TextButton(
                    onPressed: () {
                      context.read<NotificationBloc>().add(NotificationMarkAllRead());
                    },
                    child: Text(t.markAllRead),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.outline),
            Flexible(
              child: BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  if (state.status == NotificationStatus.loading && state.notifications.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    );
                  }

                  if (state.status == NotificationStatus.failure && state.notifications.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.s6),
                      child: StudentMobileUi.errorBanner(
                        message: state.errorMessage ?? t.failedToLoadData,
                        onRetry: () {
                          context.read<NotificationBloc>().add(const NotificationLoadStarted(isRefresh: false));
                        },
                        retryLabel: t.retry,
                      ),
                    );
                  }

                  if (state.notifications.isEmpty) {
                    return StudentMobileUi.emptyState(
                      context,
                      icon: Icons.notifications_off_outlined,
                      title: t.notificationsEmptyTitle,
                      body: t.notificationsEmptyBody,
                    );
                  }

                  return ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: state.hasReachedMax
                        ? state.notifications.length
                        : state.notifications.length + 1,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.outline),
                    itemBuilder: (context, index) {
                      if (index >= state.notifications.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.s4),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                          ),
                        );
                      }

                      final item = state.notifications[index];
                      return _NotificationItem(
                        item: item,
                        l10n: t,
                        onTap: () {
                          context.read<NotificationBloc>().add(NotificationMarkRead(item.id));
                          _handleNavigation(context, item);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1, color: AppColors.outline),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s3),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t.close),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({
    required this.item,
    required this.l10n,
    required this.onTap,
  });

  final NotificationEntity item;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = item.isRead ? AppColors.surfaceCard : AppColors.primaryTint;
    final bool isSystem = item.senderAvatar == null || item.senderAvatar!.isEmpty;

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6, vertical: AppSpacing.s5),
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
                      border: Border.all(color: AppColors.outline),
                      image: !isSystem
                          ? DecorationImage(
                              image: NetworkImage(item.senderAvatar!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: isSystem ? AppColors.accentTint : AppColors.surfaceCard,
                    ),
                    child: isSystem
                        ? Icon(Icons.notifications_active, size: 20, color: AppColors.accent)
                        : null,
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.outline, width: 1),
                      ),
                      child: _getTypeIcon(item.type),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: StudentMobileUi.body(context),
                        children: [
                          TextSpan(
                            text: '${item.senderName} ',
                            style: StudentMobileUi.cardTitle(context),
                          ),
                          TextSpan(
                            text: item.message,
                            style: StudentMobileUi.body(context).copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    Text(
                      formatNotificationTime(item.createdAt, l10n),
                      style: StudentMobileUi.caption(context),
                    ),
                  ],
                ),
              ),
              if (!item.isRead)
                Container(
                  margin: const EdgeInsets.only(left: AppSpacing.s3, top: AppSpacing.s3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
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
        return Icon(Icons.reply_rounded, size: 12, color: AppSkillColors.listening.color);
      case 'COMMENT_REACTION':
        return const Icon(Icons.favorite_rounded, size: 12, color: AppColors.danger);
      case 'DAILY_VOCAB':
      case 'REVIEW_REMINDER':
      case 'DAILY_REMINDER':
        return Icon(Icons.campaign_rounded, size: 12, color: AppSkillColors.vocabulary.color);
      case 'EXAM_ASSIGNED':
      case 'EXAM_ASSIGNMENT_UPDATED':
      case 'EXAM_SESSION_LIVE':
        return Icon(Icons.assignment_outlined, size: 12, color: AppColors.accent);
      case 'EXAM_RESULTS_RELEASED':
        return Icon(Icons.fact_check_outlined, size: 12, color: AppColors.success);
      case 'EXAM_ASSIGNMENT_CLOSED':
        return Icon(Icons.lock_outline, size: 12, color: AppColors.textMuted);
      case 'EXAM_SUBMISSION_RECEIVED':
      case 'CLASSROOM_JOIN_REQUEST':
        return Icon(Icons.school_outlined, size: 12, color: AppColors.accent);
      case 'CLASSROOM_JOIN_APPROVED':
        return Icon(Icons.check_circle_outline, size: 12, color: AppColors.success);
      case 'CLASSROOM_JOIN_REJECTED':
        return Icon(Icons.cancel_outlined, size: 12, color: AppColors.danger);
      case 'SYSTEM_ANNOUNCEMENT':
        return Icon(Icons.campaign_rounded, size: 12, color: AppColors.accent);
      default:
        return const Icon(Icons.notifications_rounded, size: 12, color: AppColors.textMuted);
    }
  }
}
