import 'package:english_for_community/core/entity/notification_entity.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/notification/notification_navigation.dart';
import 'package:english_for_community/core/repository/notification_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/motion/app_lottie_preset.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/ui/feedback/app_feedback.dart';
import 'package:english_for_community/core/ui/widget/app_load_gate.dart';
import 'package:english_for_community/feature/home/bloc_noti/notification_bloc.dart';
import 'package:english_for_community/feature/home/bloc_noti/notification_event.dart';
import 'package:english_for_community/feature/home/bloc_noti/notification_state.dart';
import 'package:english_for_community/feature/teacher/teacher_classroom_detail_page.dart';
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

/// Shared notification list body — rendered inside [NotificationDialog].
class NotificationInboxBody extends StatefulWidget {
  const NotificationInboxBody({super.key, this.closeBeforeNavigate = true});

  /// When true (dialog mode), pop the overlay before deep-link navigation.
  final bool closeBeforeNavigate;

  @override
  State<NotificationInboxBody> createState() => _NotificationInboxBodyState();
}

class _NotificationInboxBodyState extends State<NotificationInboxBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationBloc>().add(const NotificationLoadStarted());
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

  void _closeOverlayIfNeeded() {
    if (!widget.closeBeforeNavigate) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _respond(
    BuildContext context,
    NotificationEntity item,
    String action,
    AppLocalizations t,
  ) async {
    final result = await getIt<NotificationRepository>().respondToNotification(item.id, action);
    if (!context.mounted) return;
    final actionStatus = action == 'accept' ? 'accepted' : 'declined';
    var ok = false;
    result.fold(
      (f) => AppFeedback.error(context, f.message),
      (_) {
        ok = true;
        context.read<NotificationBloc>().add(
          NotificationItemResolved(notificationId: item.id, actionStatus: actionStatus),
        );
      },
    );
    if (!ok) return;

    final router = GoRouter.of(context);
    if (action == 'accept' && item.type == 'CO_TEACHER_INVITE') {
      final cid = item.data?['classroomId']?.toString();
      if (cid != null && cid.isNotEmpty) {
        _closeOverlayIfNeeded();
        router.push('${TeacherClassroomDetailPage.routePath}/$cid');
        AppFeedback.success(context, t.notificationInviteAccepted);
        return;
      }
    }
    if (item.type == 'CLASSROOM_JOIN_REQUEST') {
      AppFeedback.success(
        context,
        action == 'accept' ? t.notificationJoinApproved : t.notificationJoinDeclined,
      );
      return;
    }
    AppFeedback.success(
      context,
      action == 'accept' ? t.notificationInviteAccepted : t.notificationInviteDeclined,
    );
  }

  void _handleNavigation(BuildContext context, NotificationEntity item) {
    final router = GoRouter.of(context);
    _closeOverlayIfNeeded();
    if (!navigateFromNotification(router, item: item)) {
      debugPrint('No route for notification type: ${item.type}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    return BlocBuilder<NotificationBloc, NotificationState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.notifications != curr.notifications ||
          prev.hasReachedMax != curr.hasReachedMax ||
          prev.errorMessage != curr.errorMessage,
      builder: (context, state) {
        final isLoading = state.status == NotificationStatus.loading;
        final error = state.status == NotificationStatus.failure
            ? (state.errorMessage ?? t.failedToLoadData)
            : null;

        return AppLoadGate(
          isLoading: isLoading,
          errorMessage: error,
          onRetry: () {
            context.read<NotificationBloc>().add(const NotificationLoadStarted());
          },
          retryLabel: t.retry,
          loading: Center(
            child: StudentMobileUi.runnerLoading(),
          ),
          child: state.notifications.isEmpty
              ? StudentMobileUi.emptyState(
                  context,
                  icon: Icons.notifications_off_outlined,
                  lottie: AppLottiePreset.emptyNotifications,
                  title: t.notificationsEmptyTitle,
                  body: t.notificationsEmptyBody,
                )
              : ListView.separated(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  itemCount: state.hasReachedMax
                      ? state.notifications.length
                      : state.notifications.length + 1,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.outline),
                  itemBuilder: (context, index) {
                    if (index >= state.notifications.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.s4),
                          child: AppLoadingIndicator.inline(color: AppColors.primary),
                        ),
                      );
                    }

                    final item = state.notifications[index];
                    return _NotificationItem(
                      item: item,
                      l10n: t,
                      onTap: item.supportsInAppResponse
                          ? null
                          : () {
                              context.read<NotificationBloc>().add(NotificationMarkRead(item.id));
                              _handleNavigation(context, item);
                            },
                      onAccept: item.supportsInAppResponse
                          ? () => _respond(context, item, 'accept', t)
                          : null,
                      onDecline: item.supportsInAppResponse
                          ? () => _respond(context, item, 'decline', t)
                          : null,
                    );
                  },
                ),
        );
      },
    );
  }
}

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({
    required this.item,
    required this.l10n,
    this.onTap,
    this.onAccept,
    this.onDecline,
  });

  final NotificationEntity item;
  final AppLocalizations l10n;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    final bgColor = item.isRead ? AppColors.surfaceCard : AppColors.primaryTint;
    final bool isSystem = item.senderAvatar == null || item.senderAvatar!.isEmpty;
    final hasActions = onAccept != null && onDecline != null;

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6, vertical: AppSpacing.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
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
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              if (hasActions) ...[
                const SizedBox(height: AppSpacing.s4),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDecline,
                        child: Text(l10n.notificationDecline),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(
                      child: FilledButton(
                        onPressed: onAccept,
                        child: Text(l10n.notificationAccept),
                      ),
                    ),
                  ],
                ),
              ],
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
      case 'CO_TEACHER_INVITE':
        return Icon(Icons.group_add_outlined, size: 12, color: AppColors.accent);
      case 'CO_TEACHER_INVITE_ACCEPTED':
      case 'CO_TEACHER_INVITE_DECLINED':
      case 'CO_TEACHER_REMOVED':
        return Icon(Icons.groups_outlined, size: 12, color: AppColors.textMuted);
      case 'SYSTEM_ANNOUNCEMENT':
        return Icon(Icons.campaign_rounded, size: 12, color: AppColors.accent);
      default:
        return const Icon(Icons.notifications_rounded, size: 12, color: AppColors.textMuted);
    }
  }
}
