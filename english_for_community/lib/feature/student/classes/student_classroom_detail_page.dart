import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/feature/student/bloc/classroom_detail/student_classroom_detail_bloc.dart';
import 'package:english_for_community/feature/student/bloc/classroom_detail/student_classroom_detail_event.dart';
import 'package:english_for_community/feature/student/bloc/classroom_detail/student_classroom_detail_state.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
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
  void _reload() {
    context.read<StudentClassroomDetailBloc>().add(const StudentClassroomDetailLoadRequested());
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

  Future<void> _open(
    String assignmentId,
    String mode,
    Map<String, dynamic>? activeSession,
    Map<String, dynamic> assignment,
  ) async {
    final hint = assignment['studentStatusHint'] as String?;
    if (hint == 'session_ended') {
      final att = assignment['myAttempt'];
      if (att is Map) {
        final attemptId = att['id'] as String? ?? '';
        if (attemptId.isNotEmpty) {
          await context.push('/student/exam-run/$attemptId');
          _reload();
          return;
        }
      }
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ExamSystemUi.cardRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: ExamSystemUi.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.15,
                ),
          ),
          if (teacherLine.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.person_outline, size: 18, color: AppColors.onPrimary.withValues(alpha: 0.9)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    teacherLine,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _heroChip(
                context,
                Icons.groups_outlined,
                l10n.studentClassMemberCount(active),
              ),
              _heroChip(
                context,
                Icons.policy_outlined,
                _joinPolicyLabel(l10n, policy),
              ),
              if (pending > 0)
                _heroChip(
                  context,
                  Icons.hourglass_empty_rounded,
                  l10n.teacherClassroomMemberCountPending(pending),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.onPrimary.withValues(alpha: 0.95)),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (_) => getIt<StudentClassroomDetailBloc>(param1: widget.classroomId)
        ..add(const StudentClassroomDetailLoadRequested()),
      child: BlocBuilder<StudentClassroomDetailBloc, StudentClassroomDetailState>(
        builder: (context, state) {
          final loading = state.status == StudentClassroomDetailStatus.loading;
          final error = state.status == StudentClassroomDetailStatus.error ? state.errorMessage : null;
          final classroom = state.classroom;
          final assignments = state.assignments;

          return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: ExamSystemUi.appBar(context, title: l10n.studentClassDetailTitle),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: ExamSystemUi.pagePadding,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(error, textAlign: TextAlign.center, style: ExamSystemUi.captionSecondary),
                        const SizedBox(height: ExamSystemUi.blockGap),
                        FilledButton(onPressed: _reload, child: Text(l10n.retry)),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView(
                    padding: ExamSystemUi.pagePadding,
                    children: [
                      if (classroom != null) _heroHeader(context, l10n, classroom),
                      const SizedBox(height: ExamSystemUi.sectionGap),
                      AppCard(
                        variant: AppCardVariant.outline,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.studentClassInfoTitle, style: ExamSystemUi.sectionTitle(context)),
                              const SizedBox(height: ExamSystemUi.blockGap),
                              Builder(
                                builder: (ctx) {
                                  final desc = (classroom?['description'] as String?)?.trim() ?? '';
                                  final emptyHint = l10n.studentClassNoDescription;
                                  return Text(
                                    desc.isNotEmpty ? desc : emptyHint,
                                    style: ExamSystemUi.captionSecondary.copyWith(
                                      color: desc.isNotEmpty ? AppColors.textPrimary : AppColors.textMuted,
                                      fontSize: 14,
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
                                            style: ExamSystemUi.captionMuted,
                                          ),
                                        if (updated != null) ...[
                                          if (created != null) const SizedBox(height: 6),
                                          Text(
                                            l10n.studentClassUpdatedAt(updated),
                                            style: ExamSystemUi.captionMuted,
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
                      const SizedBox(height: ExamSystemUi.sectionGap),
                      Text(l10n.studentClassDetailAssignmentsTitle, style: ExamSystemUi.sectionTitle(context)),
                      const SizedBox(height: 14),
                      if (assignments.isEmpty)
                        AppCard(
                          variant: AppCardVariant.outline,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
                            child: Column(
                              children: [
                                Icon(Icons.assignment_turned_in_outlined,
                                    size: 40, color: AppColors.primary.withValues(alpha: 0.35)),
                                const SizedBox(height: 12),
                                Text(
                                  l10n.studentClassNoAssignments,
                                  textAlign: TextAlign.center,
                                  style: ExamSystemUi.captionSecondary,
                                ),
                              ],
                            ),
                          ),
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
