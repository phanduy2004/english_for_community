import 'dart:async';

import 'package:english_for_community/core/entity/classroom_chat_entity.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/feedback/app_feedback.dart';
import 'package:english_for_community/core/ui/motion/app_lottie_preset.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/feature/auth/bloc/user_bloc.dart';
import 'package:english_for_community/feature/classroom_chat/classroom_chat_page.dart';
import 'package:english_for_community/feature/classroom_chat/dock/classroom_chat_dock_controller.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/chat_group_cover_avatar.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/chat_pinned_banner.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_ui.dart';
import 'package:english_for_community/feature/student/bloc/classroom_detail/student_classroom_detail_bloc.dart';
import 'package:english_for_community/feature/student/bloc/classroom_detail/student_classroom_detail_event.dart';
import 'package:english_for_community/feature/student/bloc/classroom_detail/student_classroom_detail_state.dart';
import 'package:english_for_community/feature/student/classes/student_classroom_assignment_utils.dart';
import 'package:english_for_community/feature/student/classes/student_classroom_grouped_card.dart';
import 'package:english_for_community/feature/student/classes/student_classroom_info_sheet.dart';
import 'package:english_for_community/feature/student/classes/student_classroom_member_tile.dart';
import 'package:english_for_community/feature/student/exams/student_exam_assignment_tile.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Accent lớp học — emerald (đồng bộ hub "Lớp của tôi"), không phải skill runner.
abstract final class _ClassroomAccent {
  static SkillColorSet get colors => AppSkillColors.speaking;
}

class StudentClassroomDetailPage extends StatefulWidget {
  const StudentClassroomDetailPage({super.key, required this.classroomId});

  final String classroomId;

  static const String routePath = '/student/classroom';
  static const String routeName = 'StudentClassroomDetailPage';

  @override
  State<StudentClassroomDetailPage> createState() => _StudentClassroomDetailPageState();
}

class _StudentClassroomDetailPageState extends State<StudentClassroomDetailPage>
    with SingleTickerProviderStateMixin {
  late final StudentClassroomDetailBloc _bloc;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _bloc = getIt<StudentClassroomDetailBloc>(param1: widget.classroomId)
      ..add(const StudentClassroomDetailLoadRequested());
    registerClassroomChatDockController();
    unawaited(getIt<ClassroomChatDockController>().loadRooms(force: true));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _bloc.close();
    super.dispose();
  }

  void _reload({bool silent = false}) {
    _bloc.add(StudentClassroomDetailLoadRequested(silent: silent));
  }

  Future<void> _refresh() async {
    _reload(silent: true);
    await _bloc.stream.firstWhere((s) => !s.isRefreshing);
  }

  String _teacherLine(AppLocalizations l10n, Map<String, dynamic>? c) {
    if (c == null) return '';
    final t = c['teacherId'];
    if (t is Map) {
      final name = (t['fullName'] as String?)?.trim();
      if (name != null && name.isNotEmpty) return l10n.studentClassTeacher(name);
      final un = (t['username'] as String?)?.trim();
      if (un != null && un.isNotEmpty) return l10n.studentClassTeacher(un);
    }
    return '';
  }

  String _joinPolicyLabel(AppLocalizations l10n, String? policy) {
    if (policy == 'approval_required') return l10n.studentClassJoinPolicyApproval;
    return l10n.studentClassJoinPolicyOpen;
  }

  int _memberCount(Map<String, dynamic>? c, String key) {
    if (c == null) return 0;
    final v = c[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  String? _attemptIdFromAssignment(Map<String, dynamic> assignment) {
    final att = assignment['myAttempt'];
    if (att is! Map) return null;
    final id = att['id'] as String? ?? '';
    return id.isNotEmpty ? id : null;
  }

  Future<void> _open(
    String assignmentId,
    String mode,
    Map<String, dynamic>? activeSession,
    Map<String, dynamic> assignment,
  ) async {
    final hint = assignment['studentStatusHint'] as String?;
    final existingAttemptId = _attemptIdFromAssignment(assignment);
    final attStatus = assignment['myAttempt'] is Map
        ? (assignment['myAttempt'] as Map)['status'] as String?
        : null;

    if (hint == 'already_submitted' ||
        hint == 'session_ended' ||
        attStatus == 'submitted') {
      if (existingAttemptId != null) {
        await context.push('/student/exam-run/$existingAttemptId');
        _reload(silent: true);
        return;
      }
      if (hint == 'session_ended') return;
    }

    if (hint == 'resume' && existingAttemptId != null) {
      await context.push('/student/exam-run/$existingAttemptId');
      _reload(silent: true);
      return;
    }
    if (mode == 'realtime' && activeSession != null) {
      final sid = activeSession['id'] as String? ?? '';
      if (sid.isNotEmpty) {
        await context.push('/student/exam-session/$sid');
        _reload(silent: true);
        return;
      }
    }
    final start = await getIt<TeacherExamRepository>().startExamAttempt(assignmentId);
    await start.fold(
      (f) async => AppFeedback.error(context, f.message),
      (attempt) async {
        final map = Map<String, dynamic>.from(attempt as Map);
        final attemptId = map['id'] as String? ?? '';
        if (!context.mounted || attemptId.isEmpty) return;
        await context.push('/student/exam-run/$attemptId');
        _reload(silent: true);
      },
    );
  }

  void _openChat(String? className, AppLocalizations l10n) {
    final userId = getIt<UserBloc>().state.userEntity?.id ?? '';
    if (userId.isEmpty) return;
    context.push(
      ClassroomChatPage.studentRoutePath(widget.classroomId),
      extra: {
        'classroomName': className ?? l10n.studentClassDetailTitle,
        'currentUserId': userId,
      },
    );
  }

  void _openInfoSheet(Map<String, dynamic> classroom, StudentClassroomDetailState state) {
    final cover = state.chatSettings?.coverImageUrl;
    StudentClassroomInfoSheet.show(
      context,
      classroomId: widget.classroomId,
      classroom: classroom,
      teacherLine: _teacherLine,
      joinPolicyLabel: _joinPolicyLabel,
      memberCount: _memberCount,
      allowStudentInvite: StudentClassAssignmentUtils.allowStudentInvite(classroom),
      coverImageUrl: cover?.isNotEmpty == true ? cover : null,
      onLeaveClass: () async {
        _bloc.add(const StudentClassroomDetailLeaveRequested());
        await _bloc.stream.firstWhere(
          (s) => s.leaveStatus != StudentClassroomLeaveStatus.leaving,
        );
        if (!mounted) return;
        final leaveState = _bloc.state;
        if (leaveState.leaveStatus == StudentClassroomLeaveStatus.error) {
          if (!mounted) return;
          AppFeedback.error(context, leaveState.leaveError ?? context.l10n.retry);
          return;
        }
        if (!mounted) return;
        Navigator.pop(context);
        AppFeedback.success(context, context.l10n.studentClassLeaveSuccess);
        if (!mounted) return;
        context.pop();
      },
    );
  }

  void _goToAssignments(StudentClassAssignmentSegment segment) {
    _bloc.add(StudentClassroomDetailSegmentChanged(segment));
    _tabs.animateTo(1);
  }

  void _goToMembers() => _tabs.animateTo(2);

  Widget _assignmentTile(Map<String, dynamic> m) {
    final id = m['id'] as String? ?? '';
    final mode = m['mode'] as String? ?? 'self_paced';
    Map<String, dynamic>? activeSession;
    final rawActive = m['activeSession'];
    if (rawActive is Map) activeSession = Map<String, dynamic>.from(rawActive);
    return StudentExamAssignmentTile(
      assignment: m,
      compact: true,
      onOpen: () => _open(id, mode, activeSession, m),
    );
  }

  PreferredSizeWidget _primaryAppBar({
    required BuildContext context,
    required String title,
    required bool showLoading,
    required List<Widget>? actions,
  }) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(StudentMobileUi.appBarHeight + 2),
      child: Column(
        children: [
          StudentMobileUi.appBar(
            context,
            title: title,
            actions: actions,
          ),
          if (showLoading)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: _ClassroomAccent.colors.color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(_ClassroomAccent.colors.color),
            )
          else
            Container(
              height: 2,
              color: _ClassroomAccent.colors.color.withValues(alpha: 0.65),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<StudentClassroomDetailBloc, StudentClassroomDetailState>(
        builder: (context, state) {
          final loading = state.status == StudentClassroomDetailStatus.loading;
          final error = state.status == StudentClassroomDetailStatus.error ? state.errorMessage : null;
          final classroom = state.classroom;
          final className = (classroom?['name'] as String?)?.trim();
          final coverUrl = state.chatSettings?.coverImageUrl;

          final openCount = StudentClassAssignmentUtils.filter(
            state.assignments,
            StudentClassAssignmentSegment.open,
          ).length;
          final submittedCount = StudentClassAssignmentUtils.filter(
            state.assignments,
            StudentClassAssignmentSegment.submitted,
          ).length;
          final membersCount = state.memberCountActive;
          final pinned = state.chatSettings?.pinnedMessage;
          final liveItems = StudentClassAssignmentUtils.liveOrLobby(state.assignments);

          Widget chatAction() {
            return ListenableBuilder(
              listenable: getIt<ClassroomChatDockController>(),
              builder: (context, _) {
                final unread = getIt<ClassroomChatDockController>()
                    .unreadCountFor(widget.classroomId);
                final button = StudentMobileUi.headerIconButton(
                  context: context,
                  icon: Icons.chat_bubble_outline,
                  tooltip: l10n.studentClassOpenChat,
                  iconColor: _ClassroomAccent.colors.color,
                  backgroundColor: _ClassroomAccent.colors.tint,
                  borderColor: _ClassroomAccent.colors.color.withValues(alpha: 0.25),
                  onPressed: () => _openChat(className, l10n),
                );
                if (unread <= 0) return button;
                return Badge(
                  label: Text(unread > 99 ? '99+' : '$unread'),
                  backgroundColor: AppColors.danger,
                  child: button,
                );
              },
            );
          }

          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: _primaryAppBar(
              context: context,
              title: className?.isNotEmpty == true ? className! : l10n.studentClassDetailTitle,
              showLoading: (loading && classroom != null) || state.isRefreshing,
              actions: classroom != null
                  ? [
                      chatAction(),
                      StudentMobileUi.headerIconButton(
                        context: context,
                        icon: Icons.info_outline,
                        tooltip: l10n.studentClassInfoTitle,
                        iconColor: AppColors.info,
                        backgroundColor: AppColors.infoBg,
                        borderColor: AppColors.info.withValues(alpha: 0.22),
                        onPressed: () => _openInfoSheet(classroom, state),
                      ),
                    ]
                  : null,
            ),
            body: loading && classroom == null
                ? StudentMobileUi.runnerLoading()
                : error != null
                    ? Center(
                        child: Padding(
                          padding: StudentMobileUi.pagePadding,
                          child: StudentMobileUi.errorBanner(
                            message: error,
                            onRetry: () => _reload(),
                            retryLabel: l10n.retry,
                          ),
                        ),
                      )
                    : classroom == null
                        ? StudentMobileUi.runnerLoading()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  StudentMobileUi.pageHPadding,
                                  AppSpacing.s3,
                                  StudentMobileUi.pageHPadding,
                                  AppSpacing.s2,
                                ),
                                child: _ClassroomKpiHeader(
                                  className: className ?? l10n.studentClassDetailTitle,
                                  teacherLine: _teacherLine(l10n, classroom),
                                  joinPolicy: _joinPolicyLabel(
                                    l10n,
                                    classroom['joinPolicy'] as String?,
                                  ),
                                  coverImageUrl: coverUrl,
                                  openCount: openCount,
                                  submittedCount: submittedCount,
                                  membersCount: membersCount,
                                  onOpenTap: () => _goToAssignments(
                                    StudentClassAssignmentSegment.open,
                                  ),
                                  onSubmittedTap: () => _goToAssignments(
                                    StudentClassAssignmentSegment.submitted,
                                  ),
                                  onMembersTap: _goToMembers,
                                ),
                              ),
                              Material(
                                color: AppColors.surfaceCard,
                                child: TabBar(
                                  controller: _tabs,
                                  labelColor: _ClassroomAccent.colors.dark,
                                  unselectedLabelColor: AppColors.textSecondary,
                                  indicatorColor: _ClassroomAccent.colors.color,
                                  indicatorWeight: 2.5,
                                  labelStyle: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: AppTypography.mobileH3,
                                  ),
                                  tabs: [
                                    Tab(text: l10n.studentClassTabOverview),
                                    Tab(text: l10n.studentClassTabAssignments),
                                    Tab(text: l10n.studentClassTabMembers),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: TabBarView(
                                  controller: _tabs,
                                  children: [
                                    _OverviewTab(
                                      assignments: state.assignments,
                                      pinnedMessage: pinned,
                                      liveItems: liveItems,
                                      isRefreshing: state.isRefreshing,
                                      onRefresh: _refresh,
                                      onViewAll: () => _goToAssignments(
                                        StudentClassAssignmentSegment.open,
                                      ),
                                      onOpenChat: () => _openChat(className, l10n),
                                      assignmentTile: _assignmentTile,
                                    ),
                                    _AssignmentsTab(
                                      state: state,
                                      l10n: l10n,
                                      onRefresh: _refresh,
                                      onSegmentChanged: (segment) => _bloc.add(
                                        StudentClassroomDetailSegmentChanged(segment),
                                      ),
                                      onSortChanged: (sort) => _bloc.add(
                                        StudentClassroomDetailSortChanged(sort),
                                      ),
                                      assignmentTile: _assignmentTile,
                                    ),
                                    _MembersTab(
                                      members: state.members,
                                      loading: state.membersStatus ==
                                          StudentClassroomMembersStatus.loading,
                                      isRefreshing: state.isRefreshing,
                                      currentUserId:
                                          getIt<UserBloc>().state.userEntity?.id ?? '',
                                      onRefresh: _refresh,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
          );
        },
      ),
    );
  }
}

class _ClassroomKpiHeader extends StatelessWidget {
  const _ClassroomKpiHeader({
    required this.className,
    required this.teacherLine,
    required this.joinPolicy,
    this.coverImageUrl,
    required this.openCount,
    required this.submittedCount,
    required this.membersCount,
    required this.onOpenTap,
    required this.onSubmittedTap,
    required this.onMembersTap,
  });

  final String className;
  final String teacherLine;
  final String joinPolicy;
  final String? coverImageUrl;
  final int openCount;
  final int submittedCount;
  final int membersCount;
  final VoidCallback onOpenTap;
  final VoidCallback onSubmittedTap;
  final VoidCallback onMembersTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final identity = ClassroomChatUi.groupAvatarColors(className);
    final classAccent = _ClassroomAccent.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            classAccent.tint,
            AppColors.surfaceCard,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card + 2),
        border: Border.all(color: classAccent.color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ChatGroupCoverAvatar(
                coverImageUrl: coverImageUrl,
                radius: 22,
                groupName: className,
                useInitialsFallback: true,
                backgroundColor: identity.background,
                fallbackIconColor: identity.foreground,
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (teacherLine.isNotEmpty)
                      Text(
                        teacherLine,
                        style: StudentMobileUi.body(context).copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s2,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.outlineMuted),
                      ),
                      child: Text(
                        joinPolicy,
                        style: StudentMobileUi.caption(context).copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              StudentMobileUi.skillIconBox(
                Icons.school_outlined,
                skill: SkillType.speaking,
                size: 40,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              Expanded(
                child: StudentMobileUi.inkTap(
                  onTap: onOpenTap,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: StudentMobileUi.statCard(
                    context: context,
                    icon: Icons.play_circle_outline,
                    value: '$openCount',
                    label: l10n.studentClassSegmentOpen,
                    iconColor: AppColors.info,
                    iconBg: AppColors.infoBg,
                    compact: true,
                  ),
                ),
              ),
              const SizedBox(width: StudentMobileUi.cardGap),
              Expanded(
                child: StudentMobileUi.inkTap(
                  onTap: onSubmittedTap,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: StudentMobileUi.statCard(
                    context: context,
                    icon: Icons.check_circle_outline,
                    value: '$submittedCount',
                    label: l10n.studentClassSegmentSubmitted,
                    iconColor: AppColors.success,
                    iconBg: AppColors.successBg,
                    compact: true,
                  ),
                ),
              ),
              const SizedBox(width: StudentMobileUi.cardGap),
              Expanded(
                child: StudentMobileUi.inkTap(
                  onTap: onMembersTap,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: StudentMobileUi.statCard(
                    context: context,
                    icon: Icons.people_outline,
                    value: '$membersCount',
                    label: l10n.studentClassTabMembers,
                    iconColor: classAccent.color,
                    iconBg: classAccent.tint,
                    compact: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.assignments,
    required this.pinnedMessage,
    required this.liveItems,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onViewAll,
    required this.onOpenChat,
    required this.assignmentTile,
  });

  final List<dynamic> assignments;
  final ClassroomChatMessage? pinnedMessage;
  final List<Map<String, dynamic>> liveItems;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;
  final VoidCallback onViewAll;
  final VoidCallback onOpenChat;
  final Widget Function(Map<String, dynamic> m) assignmentTile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final recent = StudentClassAssignmentUtils.overviewRecent(assignments);
    final needsAction = recent.where(StudentClassAssignmentUtils.needsAttention).length;

    return RefreshIndicator(
      color: _ClassroomAccent.colors.color,
      onRefresh: onRefresh,
      child: ListView(
        padding: StudentMobileUi.pagePadding,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (liveItems.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s3,
                vertical: AppSpacing.s2,
              ),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(AppRadius.chip),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sensors, size: 18, color: AppColors.danger),
                  const SizedBox(width: AppSpacing.s2),
                  Expanded(
                    child: Text(
                      l10n.studentClassLiveBanner(liveItems.length),
                      style: StudentMobileUi.caption(context).copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
          ],
          if (pinnedMessage != null) ...[
            ChatPinnedBanner(
              message: pinnedMessage!,
              compact: true,
              onTap: onOpenChat,
            ),
            const SizedBox(height: AppSpacing.s3),
          ],
          if (needsAction > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s3,
                vertical: AppSpacing.s2,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentTint,
                borderRadius: BorderRadius.circular(AppRadius.chip),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                    color: AppColors.accentDark,
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  Expanded(
                    child: Text(
                      l10n.studentClassOverviewActionHint(needsAction),
                      style: StudentMobileUi.caption(context).copyWith(
                        color: AppColors.accentDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (needsAction > 0) const SizedBox(height: AppSpacing.s3),
          StudentMobileUi.sectionHeader(
            context,
            title: l10n.studentClassOverviewRecentTitle,
            actionLabel: recent.isNotEmpty ? l10n.studentClassViewAllAssignments : null,
            onAction: recent.isNotEmpty ? onViewAll : null,
          ),
          const SizedBox(height: AppSpacing.s3),
          if (isRefreshing)
            StudentMobileUi.listLoading()
          else if (recent.isEmpty)
            StudentMobileUi.emptyState(
              context,
              icon: Icons.assignment_turned_in_outlined,
              lottie: AppLottiePreset.emptyClasses,
              skill: SkillType.speaking,
              title: l10n.studentClassNoAssignments,
              body: l10n.studentClassOverviewEmptyBody,
              ctaLabel: l10n.studentClassOpenChat,
              onCta: onOpenChat,
            )
          else
            ...recent.map(assignmentTile),
        ],
      ),
    );
  }
}

class _AssignmentsTab extends StatelessWidget {
  const _AssignmentsTab({
    required this.state,
    required this.l10n,
    required this.onRefresh,
    required this.onSegmentChanged,
    required this.onSortChanged,
    required this.assignmentTile,
  });

  final StudentClassroomDetailState state;
  final AppLocalizations l10n;
  final Future<void> Function() onRefresh;
  final ValueChanged<StudentClassAssignmentSegment> onSegmentChanged;
  final ValueChanged<StudentClassAssignmentSort> onSortChanged;
  final Widget Function(Map<String, dynamic> m) assignmentTile;

  @override
  Widget build(BuildContext context) {
    final segment = state.assignmentSegment;
    final segmentIndex = StudentClassAssignmentSegment.values.indexOf(segment);
    final filtered = state.filteredAssignments;
    final sort = state.assignmentSort;

    return RefreshIndicator(
      color: _ClassroomAccent.colors.color,
      onRefresh: onRefresh,
      child: ListView(
        padding: StudentMobileUi.pagePadding,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          StudentMobileUi.filterRow(
            labels: [
              l10n.studentClassSegmentOpen,
              l10n.studentClassSegmentSubmitted,
              l10n.studentClassSegmentGraded,
              l10n.studentClassSegmentClosed,
            ],
            selectedIndex: segmentIndex,
            onSelected: (i) => onSegmentChanged(StudentClassAssignmentSegment.values[i]),
            skill: SkillType.speaking,
          ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              Expanded(
                child: StudentMobileUi.sectionHeader(
                  context,
                  title: l10n.studentClassDetailAssignmentsTitle,
                ),
              ),
              IconButton(
                tooltip: sort == StudentClassAssignmentSort.priority
                    ? l10n.studentClassSortDueDate
                    : l10n.studentClassSortPriority,
                onPressed: () => onSortChanged(
                  sort == StudentClassAssignmentSort.priority
                      ? StudentClassAssignmentSort.dueDate
                      : StudentClassAssignmentSort.priority,
                ),
                icon: Icon(
                  sort == StudentClassAssignmentSort.priority
                      ? Icons.schedule
                      : Icons.priority_high,
                  color: _ClassroomAccent.colors.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            l10n.studentClassAssignmentsFilteredCount(filtered.length),
            style: StudentMobileUi.caption(context),
          ),
          const SizedBox(height: AppSpacing.s4),
          if (state.isRefreshing)
            StudentMobileUi.listLoading()
          else if (filtered.isEmpty)
            StudentMobileUi.emptyState(
              context,
              icon: Icons.assignment_outlined,
              title: l10n.studentClassNoAssignmentsInSegment,
              body: '',
            )
          else
            ...filtered.map(assignmentTile),
        ],
      ),
    );
  }
}

class _MembersTab extends StatefulWidget {
  const _MembersTab({
    required this.members,
    required this.loading,
    required this.isRefreshing,
    required this.currentUserId,
    required this.onRefresh,
  });

  final List<ChatMember> members;
  final bool loading;
  final bool isRefreshing;
  final String currentUserId;
  final Future<void> Function() onRefresh;

  @override
  State<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<_MembersTab> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ChatMember> _filtered(List<ChatMember> members) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return members;
    return members.where((m) {
      return m.fullName.toLowerCase().contains(q) ||
          (m.username.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (widget.loading && widget.members.isEmpty) {
      return StudentMobileUi.listLoading();
    }

    final sorted = [...widget.members]
      ..sort(ChatMember.compareForMemberList);
    final filtered = _filtered(sorted);

    return RefreshIndicator(
      color: _ClassroomAccent.colors.color,
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: StudentMobileUi.pagePadding,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          StudentMobileUi.searchField(
            controller: _search,
            hintText: l10n.studentClassMembersSearchHint,
            onClear: () {
              _search.clear();
              setState(() {});
            },
          ),
          const SizedBox(height: AppSpacing.s3),
          StudentMobileUi.sectionHeader(
            context,
            title: l10n.studentClassTabMembers,
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            l10n.studentClassChatMemberCount(filtered.length),
            style: StudentMobileUi.caption(context),
          ),
          const SizedBox(height: AppSpacing.s3),
          if (widget.isRefreshing)
            StudentMobileUi.listLoading()
          else if (filtered.isEmpty)
            StudentMobileUi.emptyState(
              context,
              icon: Icons.people_outline,
              skill: SkillType.speaking,
              title: widget.members.isEmpty
                  ? l10n.studentClassMembersEmpty
                  : l10n.studentClassMembersNoResults,
              body: '',
            )
          else
            StudentClassroomGroupedCard(
              dividerIndent: StudentClassroomGroupedCard.memberDividerIndent(),
              accentColor: _ClassroomAccent.colors.color,
              children: filtered
                  .map(
                    (m) => StudentClassroomMemberTile(
                      member: m,
                      isMe: m.id == widget.currentUserId,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
