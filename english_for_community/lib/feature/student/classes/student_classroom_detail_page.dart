import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/feature/student/bloc/classroom_detail/student_classroom_detail_bloc.dart';
import 'package:english_for_community/feature/student/bloc/classroom_detail/student_classroom_detail_event.dart';
import 'package:english_for_community/feature/student/bloc/classroom_detail/student_classroom_detail_state.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/student/exams/student_exam_assignment_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

  String? _formatDate(BuildContext context, dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString();
    if (s.isEmpty) return null;
    final dt = DateTime.tryParse(s);
    if (dt == null) return null;
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).add_jm().format(dt.toLocal());
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
      (f) async => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
      (attempt) async {
        final map = Map<String, dynamic>.from(attempt as Map);
        final attemptId = map['id'] as String? ?? '';
        if (!context.mounted || attemptId.isEmpty) return;
        await context.push('/student/exam-run/$attemptId');
        _reload();
      },
    );
  }

  Widget _heroHeader(BuildContext context, AppLocalizations l10n, Map<String, dynamic> c) {
    final name = (c['name'] as String?)?.trim() ?? l10n.studentClassDetailTitle;
    final teacherLine = _teacherLine(l10n, c);
    final active = _memberCount(c, 'memberCountActive');
    final pending = _memberCount(c, 'memberCountPending');
    final policy = c['joinPolicy'] as String?;

    return AppCard(
      variant: AppCardVariant.filled,
      padding: const EdgeInsets.all(AppSpacing.s5),
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
                      const SizedBox(height: AppSpacing.s3),
                      Text(teacherLine, style: StudentMobileUi.body(context)),
                    ],
                  ],
                ),
              ),
              StudentMobileUi.skillIconBox(Icons.class_outlined, size: 48),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Wrap(
            spacing: AppSpacing.s3,
            runSpacing: AppSpacing.s3,
            children: [
              _metaChip(l10n.studentClassMemberCount(active)),
              _metaChip(_joinPolicyLabel(l10n, policy)),
              if (pending > 0) _metaChip(l10n.teacherClassroomMemberCountPending(pending)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.outline),
      ),
      child: Text(text, style: AppTypography.label(color: AppColors.textSecondary)),
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

          return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: StudentMobileUi.appBar(context, title: l10n.studentClassDetailTitle),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                      if (classroom != null) _heroHeader(context, l10n, classroom),
                      const SizedBox(height: StudentMobileUi.sectionGap),
                      AppCard(
                        variant: AppCardVariant.outline,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.studentClassInfoTitle, style: StudentMobileUi.sectionTitle(context)),
                              const SizedBox(height: AppSpacing.s5),
                              Builder(
                                builder: (ctx) {
                                  final desc = (classroom?['description'] as String?)?.trim() ?? '';
                                  final emptyHint = l10n.studentClassNoDescription;
                                  return Text(
                                    desc.isNotEmpty ? desc : emptyHint,
                                    style: StudentMobileUi.body(context).copyWith(
                                      color: desc.isNotEmpty ? AppColors.textPrimary : AppColors.textMuted,
                                      height: 1.45,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 14),
                              if (classroom != null) ...[
                                Builder(
                                  builder: (ctx) {
                                    final created = _formatDate(ctx, classroom['createdAt']);
                                    final updated = _formatDate(ctx, classroom['updatedAt']);
                                    if (created == null && updated == null) return const SizedBox.shrink();
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (created != null)
                                          Text(
                                            l10n.studentClassCreatedAt(created),
                                            style: StudentMobileUi.caption(context),
                                          ),
                                        if (updated != null) ...[
                                          if (created != null) const SizedBox(height: 6),
                                          Text(
                                            l10n.studentClassUpdatedAt(updated),
                                            style: StudentMobileUi.caption(context),
                                          ),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: StudentMobileUi.sectionGap),
                      StudentMobileUi.sectionHeader(context, title: l10n.studentClassDetailAssignmentsTitle),
                      const SizedBox(height: AppSpacing.s4),
                      if (assignments.isEmpty)
                        StudentMobileUi.emptyState(
                          context,
                          icon: Icons.assignment_turned_in_outlined,
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
