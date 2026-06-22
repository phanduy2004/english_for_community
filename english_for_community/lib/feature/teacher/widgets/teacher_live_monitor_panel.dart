import 'package:english_for_community/feature/teacher/layout/teacher_skeleton.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/feature/teacher/bloc/live_monitor/teacher_live_monitor_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/live_monitor/teacher_live_monitor_event.dart';
import 'package:english_for_community/feature/teacher/bloc/live_monitor/teacher_live_monitor_state.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_widgets.dart';
import 'package:english_for_community/feature/teacher/teacher_student_live_screen_page.dart';
import 'package:english_for_community/feature/teacher/widgets/teacher_exam_participant_status_chip.dart';
import 'package:english_for_community/feature/teacher/widgets/teacher_exam_question_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';

class TeacherLiveMonitorPanel extends StatelessWidget {
  const TeacherLiveMonitorPanel({
    super.key,
    this.onKickStudent,
  });

  final void Function(Map<String, dynamic> student)? onKickStudent;

  String _displayName(Map<String, dynamic> s, String unknown) {
    final n = (s['fullName'] as String?)?.trim();
    if (n != null && n.isNotEmpty) return n;
    final u = (s['username'] as String?)?.trim();
    if (u != null && u.isNotEmpty) return u;
    final e = (s['email'] as String?)?.trim();
    if (e != null && e.isNotEmpty) return e;
    return unknown;
  }

  Color _riskColor(String? level) {
    switch (level) {
      case 'high':
        return AppColors.chartTrend;
      case 'medium':
        return Colors.orange.shade700;
      default:
        return AppColors.textMuted;
    }
  }

  void _openLiveScreen(BuildContext context, Map<String, dynamic> s) {
    final l10n = context.l10n;
    final attemptId = s['attemptId']?.toString() ?? '';
    if (attemptId.isEmpty) return;
    final name = _displayName(s, l10n.teacherDashboardStudentUnknown);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeacherStudentLiveScreenPage(
          attemptId: attemptId,
          studentName: name,
          initialLiveScreen: s,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unknown = l10n.teacherDashboardStudentUnknown;

    return BlocBuilder<TeacherLiveMonitorBloc, TeacherLiveMonitorState>(
      buildWhen: teacherLiveMonitorSummaryBuildWhen,
      builder: (context, state) {
        if (state.status == TeacherLiveMonitorStatus.loading && state.students.isEmpty) {
          return TeacherSkeleton.page(TeacherSkeleton.table(rows: 6));
        }
        if (state.status == TeacherLiveMonitorStatus.error && state.students.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.errorMessage ?? l10n.vocabUnknownError, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TeacherRetryButton(
                  onPressed: () => context.read<TeacherLiveMonitorBloc>().add(
                        const TeacherLiveMonitorRefreshRequested(),
                      ),
                ),
              ],
            ),
          );
        }

        final summary = state.summary;
        final inProgress = (summary['inProgress'] as num?)?.toInt() ?? 0;
        final submitted = (summary['submitted'] as num?)?.toInt() ?? 0;
        final flagged = (summary['flagged'] as num?)?.toInt() ?? 0;
        final avg = (summary['avgProgressPercent'] as num?)?.toDouble() ?? 0;

        final avgLabel = avg == avg.roundToDouble() ? '${avg.toInt()}' : avg.toStringAsFixed(1);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: AppColors.surfaceCard,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.outlineMuted)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TeacherLiveMonitorMetricChip(
                          value: '$inProgress',
                          label: l10n.teacherLiveMonitorFilterInProgress,
                          accent: AppColors.info,
                        ),
                        TeacherLiveMonitorMetricChip(
                          value: '$submitted',
                          label: l10n.teacherLiveMonitorFilterSubmitted,
                          accent: AppColors.primary,
                        ),
                        TeacherLiveMonitorMetricChip(
                          value: '$flagged',
                          label: l10n.teacherLiveMonitorFilterFlagged,
                          accent: AppColors.warning,
                        ),
                        TeacherLiveMonitorMetricChip(
                          value: '$avgLabel%',
                          label: l10n.teacherLiveMonitorDetailProgress,
                          accent: AppColors.accentDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: TeacherLiveMonitorFilter.values.map((f) {
                        final selected = state.filter == f;
                        final label = switch (f) {
                          TeacherLiveMonitorFilter.all => l10n.teacherLiveMonitorFilterAll,
                          TeacherLiveMonitorFilter.inProgress => l10n.teacherLiveMonitorFilterInProgress,
                          TeacherLiveMonitorFilter.submitted => l10n.teacherLiveMonitorFilterSubmitted,
                          TeacherLiveMonitorFilter.flagged => l10n.teacherLiveMonitorFilterFlagged,
                        };
                        return TeacherFilterChip(
                          label: label,
                          selected: selected,
                          onSelected: () => context.read<TeacherLiveMonitorBloc>().add(
                                TeacherLiveMonitorFilterChanged(f),
                              ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<TeacherLiveMonitorBloc, TeacherLiveMonitorState>(
                buildWhen: teacherLiveMonitorListBuildWhen,
                builder: (context, listState) {
                  final list = listState.visibleStudents;
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<TeacherLiveMonitorBloc>().add(const TeacherLiveMonitorRefreshRequested());
                      await context.read<TeacherLiveMonitorBloc>().stream.firstWhere(
                            (s) => s.status != TeacherLiveMonitorStatus.loading,
                          );
                    },
                    child: list.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 48),
                                child: Center(
                                  child: Text(
                                    l10n.teacherLiveMonitorNoStudents,
                                    style: ExamSystemUi.captionSecondary,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final s = list[index];
                              final uid = s['userId']?.toString() ?? '$index';
                              return RepaintBoundary(
                                child: _StudentMonitorTile(
                                  key: ValueKey('live_tile_$uid'),
                                  student: s,
                                  unknown: unknown,
                                  l10n: l10n,
                                  onKickStudent: onKickStudent,
                                  onWatchScreen: () => _openLiveScreen(context, s),
                                  riskColor: _riskColor,
                                ),
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StudentMonitorTile extends StatelessWidget {
  const _StudentMonitorTile({
    super.key,
    required this.student,
    required this.unknown,
    required this.l10n,
    required this.onWatchScreen,
    required this.riskColor,
    this.onKickStudent,
  });

  final Map<String, dynamic> student;
  final String unknown;
  final AppLocalizations l10n;
  final VoidCallback onWatchScreen;
  final Color Function(String?) riskColor;
  final void Function(Map<String, dynamic> student)? onKickStudent;

  String _name() {
    final n = (student['fullName'] as String?)?.trim();
    if (n != null && n.isNotEmpty) return n;
    final u = (student['username'] as String?)?.trim();
    if (u != null && u.isNotEmpty) return u;
    final e = (student['email'] as String?)?.trim();
    if (e != null && e.isNotEmpty) return e;
    return unknown;
  }

  @override
  Widget build(BuildContext context) {
    final pct = ((student['progressPercent'] as num?)?.toDouble() ?? 0) / 100;
    final status = student['status']?.toString() ?? '';
    final risk = student['integrityRiskLevel']?.toString();
    final chipStatus = TeacherExamParticipantStatusResolver.fromAttemptStatus(status);
    final inProgress = chipStatus == TeacherExamParticipantStatus.inProgress;
    final cached = student['_parsedSkillStrips'];
    final strips = cached is List<Map<String, dynamic>>
        ? cached
        : TeacherExamQuestionStripSection.parseStrips(student['skillStrips']);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: AppColors.outlineMuted.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _name(),
                    style: ExamSystemUi.captionSecondary.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TeacherExamParticipantStatusChip(status: chipStatus),
                const SizedBox(width: 4),
                if (risk == 'high' || risk == 'medium')
                  Tooltip(
                    message: risk == 'high'
                        ? l10n.teacherLiveMonitorIntegrityHigh
                        : l10n.teacherLiveMonitorIntegrityMedium,
                    child: Icon(Icons.flag_outlined, size: 16, color: riskColor(risk)),
                  ),
                if (inProgress)
                  IconButton(
                    tooltip: l10n.teacherLiveMonitorWatchScreen,
                    onPressed: onWatchScreen,
                    icon: const Icon(Icons.monitor_outlined, size: 20),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                if (onKickStudent != null && status == 'in_progress')
                  IconButton(
                    tooltip: l10n.examSessionKickStudentAction,
                    onPressed: () => onKickStudent!(student),
                    icon: Icon(Icons.person_remove_outlined, color: AppColors.chartTrend, size: 20),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
              ],
            ),
            if (inProgress) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xs),
                child: LinearProgressIndicator(
                  value: pct.clamp(0, 1),
                  minHeight: 4,
                  backgroundColor: AppColors.outlineMuted.withValues(alpha: 0.25),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                l10n.teacherLiveMonitorProgressLabel(
                  (student['answeredCount'] as num?)?.toInt() ?? 0,
                  (student['totalItems'] as num?)?.toInt() ?? 0,
                  (student['progressPercent'] as num?)?.toDouble() ?? 0,
                ),
                style: ExamSystemUi.captionMuted.copyWith(fontSize: 11),
              ),
            ],
            if (strips.isNotEmpty) ...[
              const SizedBox(height: 6),
              TeacherExamSkillStripsPanel(
                skillStrips: strips,
                compact: true,
                showLegend: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
