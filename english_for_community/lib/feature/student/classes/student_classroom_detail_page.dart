import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/feature/auth/bloc/user_bloc.dart';
import 'package:english_for_community/feature/auth/bloc/user_state.dart';
import 'package:english_for_community/feature/classroom_chat/classroom_chat_page.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/feature/student/bloc/classroom_detail/student_classroom_detail_bloc.dart';
import 'package:english_for_community/feature/student/bloc/classroom_detail/student_classroom_detail_event.dart';
import 'package:english_for_community/feature/student/bloc/classroom_detail/student_classroom_detail_state.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/motion/app_lottie_preset.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/feature/student/exams/student_exam_assignment_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class StudentClassroomDetailPage extends StatefulWidget {
  const StudentClassroomDetailPage({super.key, required this.classroomId});

  final String classroomId;

  static const String routePath = '/student/classroom';
  static const String routeName = 'StudentClassroomDetailPage';

  @override
  State<StudentClassroomDetailPage> createState() => _StudentClassroomDetailPageState();
}

class _StudentClassroomDetailPageState extends State<StudentClassroomDetailPage> {
  late final StudentClassroomDetailBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<StudentClassroomDetailBloc>(param1: widget.classroomId)
      ..add(const StudentClassroomDetailLoadRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _reload() {
    _bloc.add(const StudentClassroomDetailLoadRequested());
  }

  String _teacherLine(AppLocalizations l10n, Map<String, dynamic>? c) {
    if (c == null) return '';
    final t = c['teacherId'];
    if (t is Map) {
      final name = (t['fullName'] as String?)?.trim();
      if (name != null && name.isNotEmpty) {
        return l10n.studentClassTeacher(name);
      }
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
        _reload();
        return;
      }
      if (hint == 'session_ended') return;
    }

    if (hint == 'resume' && existingAttemptId != null) {
      await context.push('/student/exam-run/$existingAttemptId');
      _reload();
      return;
    }
    if (mode == 'realtime' && activeSession != null) {
      final sid = activeSession['id'] as String? ?? '';
      if (sid.isNotEmpty) {
        await context.push('/student/exam-session/$sid');
        _reload();
        return;
      }
    }
    final start = await getIt<TeacherExamRepository>().startExamAttempt(assignmentId);
    await start.fold(
      (f) async => AppCornerToast.show(context, f.message, error: true),
      (attempt) async {
        final map = Map<String, dynamic>.from(attempt as Map);
        final attemptId = map['id'] as String? ?? '';
        if (!context.mounted || attemptId.isEmpty) return;
        await context.push('/student/exam-run/$attemptId');
        _reload();
      },
    );
  }

  Widget _classHero(BuildContext context, AppLocalizations l10n, Map<String, dynamic> c) {
    final name = (c['name'] as String?)?.trim() ?? l10n.studentClassDetailTitle;
    final teacherLine = _teacherLine(l10n, c);
    final active = _memberCount(c, 'memberCountActive');
    final pending = _memberCount(c, 'memberCountPending');
    final policy = c['joinPolicy'] as String?;
    final desc = (c['description'] as String?)?.trim() ?? '';
    final colors = AppSkillColors.speaking;

    return StudentMobileUi.skillAccentCard(
      skill: SkillType.speaking,
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: StudentMobileUi.sectionTitle(context)),
                    if (teacherLine.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        teacherLine,
                        style: StudentMobileUi.body(context).copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              StudentMobileUi.skillIconBox(Icons.menu_book_rounded, skill: SkillType.speaking, size: 40),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Wrap(
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s2,
            children: [
              _heroChip(Icons.people_outline, l10n.studentClassMemberCount(active), colors.color),
              _heroChip(Icons.lock_open_outlined, _joinPolicyLabel(l10n, policy), AppColors.textSecondary),
              if (pending > 0)
                _heroChip(
                  Icons.hourglass_empty_outlined,
                  l10n.teacherClassroomMemberCountPending(pending),
                  AppColors.warning,
                ),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s4),
            Divider(height: 1, color: AppColors.outlineMuted.withValues(alpha: 0.6)),
            const SizedBox(height: AppSpacing.s3),
            Text(
              desc,
              style: StudentMobileUi.body(context).copyWith(height: 1.5, color: AppColors.textPrimary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _heroChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text, style: AppTypography.label(color: color)),
        ],
      ),
    );
  }

  Widget _assignmentsHeader(BuildContext context, AppLocalizations l10n, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                l10n.studentClassDetailAssignmentsTitle,
                style: StudentMobileUi.sectionTitle(context),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          l10n.studentClassDetailAssignmentsSubtitle,
          style: StudentMobileUi.caption(context),
        ),
      ],
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
          final assignments = state.assignments;
          final className = (classroom?['name'] as String?)?.trim();

          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: StudentMobileUi.skillAppBar(
              context,
              title: className?.isNotEmpty == true ? className! : l10n.studentClassDetailTitle,
              skill: SkillType.speaking,
            ),
            floatingActionButton: classroom != null
                ? FloatingActionButton.extended(
                    elevation: 2,
                    highlightElevation: 4,
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textInverse,
                    extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    label: const Text(
                      'Nhóm chat',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    onPressed: () {
                      final userId =
                          getIt<UserBloc>().state.userEntity?.id ?? '';
                      if (userId.isEmpty) return;
                      context.push(
                        ClassroomChatPage.studentRoutePath(widget.classroomId),
                        extra: {
                          'classroomName':
                              className ?? l10n.studentClassDetailTitle,
                          'currentUserId': userId,
                        },
                      );
                    },
                  )
                : null,
            body: loading
                ? const Center(child: AppLoadingIndicator.center(color: AppColors.primary))
                : error != null
                    ? Center(
                        child: Padding(
                          padding: StudentMobileUi.pagePadding,
                          child: StudentMobileUi.errorBanner(
                            message: error,
                            onRetry: _reload,
                            retryLabel: l10n.retry,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () async {
                          _reload();
                          await _bloc.stream.firstWhere(
                            (s) => s.status != StudentClassroomDetailStatus.loading,
                          );
                        },
                        child: ListView(
                          padding: StudentMobileUi.pagePadding,
                          children: [
                            if (classroom != null) _classHero(context, l10n, classroom),
                            const SizedBox(height: StudentMobileUi.sectionGap),
                            _assignmentsHeader(context, l10n, assignments.length),
                            const SizedBox(height: AppSpacing.s4),
                            if (assignments.isEmpty)
                              StudentMobileUi.emptyState(
                                context,
                                icon: Icons.assignment_turned_in_outlined,
                                lottie: AppLottiePreset.emptyClasses,
                                title: l10n.studentClassNoAssignments,
                                body: '',
                              )
                            else
                              ...assignments.map((raw) {
                                final m = Map<String, dynamic>.from(raw as Map);
                                final id = m['id'] as String? ?? '';
                                final mode = m['mode'] as String? ?? 'self_paced';
                                Map<String, dynamic>? activeSession;
                                final rawActive = m['activeSession'];
                                if (rawActive is Map) {
                                  activeSession = Map<String, dynamic>.from(rawActive);
                                }
                                return StudentExamAssignmentTile(
                                  assignment: m,
                                  onOpen: () => _open(id, mode, activeSession, m),
                                );
                              }),
                          ],
                        ),
                      ),
          );
        },
      ),
    );
  }
}
