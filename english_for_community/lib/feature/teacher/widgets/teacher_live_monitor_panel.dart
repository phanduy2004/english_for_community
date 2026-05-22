import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/feature/teacher/bloc/live_monitor/teacher_live_monitor_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/live_monitor/teacher_live_monitor_event.dart';
import 'package:english_for_community/feature/teacher/bloc/live_monitor/teacher_live_monitor_state.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/teacher_student_live_screen_page.dart';
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
      builder: (context, state) {
        if (state.status == TeacherLiveMonitorStatus.loading && state.students.isEmpty) {
          return const Center(child: CircularProgressIndicator());
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
        final visible = state.visibleStudents;

        final avgLabel = avg == avg.roundToDouble() ? '${avg.toInt()}' : avg.toStringAsFixed(1);
        final summaryLine = l10n.teacherLiveMonitorSummaryLine(
          inProgress,
          submitted,
          flagged,
          avgLabel,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: AppColors.surfaceCard,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.outlineMuted)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      summaryLine,
                      style: ExamSystemUi.captionMuted.copyWith(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: TeacherLiveMonitorFilter.values.map((f) {
                          final selected = state.filter == f;
                          final label = switch (f) {
                            TeacherLiveMonitorFilter.all => l10n.teacherLiveMonitorFilterAll,
                            TeacherLiveMonitorFilter.inProgress => l10n.teacherLiveMonitorFilterInProgress,
                            TeacherLiveMonitorFilter.submitted => l10n.teacherLiveMonitorFilterSubmitted,
                            TeacherLiveMonitorFilter.flagged => l10n.teacherLiveMonitorFilterFlagged,
                          };
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(label, style: const TextStyle(fontSize: 12)),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              selected: selected,
                              onSelected: (_) => context.read<TeacherLiveMonitorBloc>().add(
                                    TeacherLiveMonitorFilterChanged(f),
                                  ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<TeacherLiveMonitorBloc>().add(const TeacherLiveMonitorRefreshRequested());
                  await context.read<TeacherLiveMonitorBloc>().stream.firstWhere(
                        (s) => s.status != TeacherLiveMonitorStatus.loading,
                      );
                },
                child: visible.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            child: Center(
                              child: Text(l10n.teacherLiveMonitorNoStudents, style: ExamSystemUi.captionSecondary),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final s = visible[index];
                          return _StudentMonitorTile(
                            student: s,
                            unknown: unknown,
                            l10n: l10n,
                            onKickStudent: onKickStudent,
                            onWatchScreen: () => _openLiveScreen(context, s),
                            riskColor: _riskColor,
                          );
                        },
                      ),
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
    final submittedNow = status == 'submitted';
    final strips = TeacherExamQuestionStripSection.parseStrips(student['skillStrips']);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
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
                if (risk == 'high' || risk == 'medium')
                  Tooltip(
                    message: risk == 'high'
                        ? l10n.teacherLiveMonitorIntegrityHigh
                        : l10n.teacherLiveMonitorIntegrityMedium,
                    child: Icon(Icons.flag_outlined, size: 16, color: riskColor(risk)),
                  ),
                if (!submittedNow)
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
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct.clamp(0, 1),
                minHeight: 4,
                backgroundColor: AppColors.outlineMuted.withValues(alpha: 0.25),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              submittedNow
                  ? l10n.teacherLiveMonitorStatusSubmitted
                  : l10n.teacherLiveMonitorProgressLabel(
                      (student['answeredCount'] as num?)?.toInt() ?? 0,
                      (student['totalItems'] as num?)?.toInt() ?? 0,
                      (student['progressPercent'] as num?)?.toDouble() ?? 0,
                    ),
              style: ExamSystemUi.captionMuted.copyWith(fontSize: 11),
            ),
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

// ─────────────────────────────────────────────
// Student detail bottom-sheet
// ─────────────────────────────────────────────
class _StudentDetailSheet extends StatelessWidget {
  const _StudentDetailSheet({
    required this.student,
    required this.unknownLabel,
    required this.l10n,
  });

  final Map<String, dynamic> student;
  final String unknownLabel;
  final AppLocalizations l10n;

  String _displayName() {
    final n = (student['fullName'] as String?)?.trim();
    if (n != null && n.isNotEmpty) return n;
    final u = (student['username'] as String?)?.trim();
    if (u != null && u.isNotEmpty) return u;
    return (student['email'] as String?)?.trim() ?? unknownLabel;
  }

  IconData _skillIcon(String skill) {
    switch (skill) {
      case 'listening':
        return Icons.headphones_outlined;
      case 'speaking':
        return Icons.record_voice_over_outlined;
      case 'reading':
        return Icons.menu_book_outlined;
      case 'writing':
        return Icons.edit_outlined;
      default:
        return Icons.school_outlined;
    }
  }

  String _skillLabel(String skill) {
    switch (skill) {
      case 'listening':
        return l10n.teacherExamIntegratedSkillListening;
      case 'speaking':
        return l10n.teacherExamIntegratedSkillSpeaking;
      case 'reading':
        return l10n.teacherExamIntegratedSkillReading;
      case 'writing':
        return l10n.teacherExamIntegratedSkillWriting;
      default:
        return skill;
    }
  }

  @override
  Widget build(BuildContext context) {
    final answered = (student['answeredCount'] as num?)?.toInt() ?? 0;
    final total = (student['totalItems'] as num?)?.toInt() ?? 0;
    final pct = (student['progressPercent'] as num?)?.toDouble() ?? 0;
    final currentLabel = (student['currentItemLabel'] as String?)?.trim() ?? '';
    final tabs = (student['tabSwitchCount'] as num?)?.toInt() ?? 0;
    final focus = (student['focusLossSeconds'] as num?)?.toInt() ?? 0;
    final copy = (student['copyPasteAttempts'] as num?)?.toInt() ?? 0;

    final rawGrammar = student['grammarAnswers'];
    final grammarAnswers = rawGrammar is List
        ? rawGrammar.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    final rawSections = student['sectionStatus'];
    final sectionStatus = rawSections is List
        ? rawSections.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, scrollCtrl) {
        return ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(_displayName(), style: ExamSystemUi.listTitle(context)),
            if ((student['email'] as String?)?.trim().isNotEmpty == true)
              Text(student['email'] as String, style: ExamSystemUi.captionMuted),
            const SizedBox(height: 16),

            // ── Progress bar ──
            _SectionHeader(icon: Icons.bar_chart_outlined, label: l10n.teacherLiveMonitorDetailProgress),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: AppColors.outlineMuted.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.teacherLiveMonitorProgressLabel(answered, total, pct),
              style: ExamSystemUi.captionSecondary,
            ),
            if (currentLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.edit_note_outlined, size: 15, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${l10n.teacherLiveMonitorCurrentQuestion}: $currentLabel',
                      style: ExamSystemUi.captionMuted,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // ── Skill sections ──
            if (sectionStatus.isNotEmpty) ...[
              _SectionHeader(icon: Icons.layers_outlined, label: l10n.teacherLiveMonitorDetailSections),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sectionStatus.map((sec) {
                  final done = sec['completed'] == true;
                  final skill = sec['skill']?.toString() ?? '';
                  return _StatusChip(
                    icon: _skillIcon(skill),
                    label: _skillLabel(skill),
                    done: done,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // ── Grammar MCQ answers ──
            if (grammarAnswers.isNotEmpty) ...[
              _SectionHeader(icon: Icons.quiz_outlined, label: l10n.teacherLiveMonitorDetailGrammar),
              const SizedBox(height: 8),
              ...grammarAnswers.asMap().entries.map((entry) {
                final i = entry.key;
                final g = entry.value;
                final answered = g['answered'] == true;
                final isCorrect = g['isCorrect'] as bool?;
                final selected = (g['selectedIndexes'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [];
                final options = (g['options'] as List?)?.map((e) => e.toString()).toList() ?? [];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: !answered
                          ? AppColors.outlineMuted.withValues(alpha: 0.08)
                          : isCorrect == true
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : AppColors.chartTrend.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !answered
                            ? AppColors.outlineMuted
                            : isCorrect == true
                                ? AppColors.primary.withValues(alpha: 0.4)
                                : AppColors.chartTrend.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${l10n.teacherLiveMonitorGrammarQuestion} ${i + 1}',
                                style: ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (!answered)
                              _AnswerBadge(label: l10n.teacherLiveMonitorGrammarNotAnswered, color: AppColors.textMuted)
                            else if (isCorrect == true)
                              _AnswerBadge(label: l10n.teacherLiveMonitorGrammarCorrect, color: AppColors.primary)
                            else
                              _AnswerBadge(label: l10n.teacherLiveMonitorGrammarWrong, color: AppColors.chartTrend),
                          ],
                        ),
                        if (options.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ...options.asMap().entries.map((opt) {
                            final isSelected = selected.contains(opt.key);
                            final isRight = (g['correctOptionIndexes'] as List?)
                                    ?.map((e) => (e as num).toInt())
                                    .contains(opt.key) ??
                                false;
                            Color? bg;
                            Color? fg;
                            if (isSelected && isRight) {
                              bg = AppColors.primary.withValues(alpha: 0.15);
                              fg = AppColors.primaryDark;
                            } else if (isSelected && !isRight) {
                              bg = AppColors.chartTrend.withValues(alpha: 0.12);
                              fg = AppColors.chartTrend;
                            } else if (isRight && !isSelected && answered) {
                              bg = AppColors.primary.withValues(alpha: 0.06);
                              fg = AppColors.primary;
                            }
                            return Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  if (isSelected)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Icon(
                                        isRight ? Icons.check_circle_outline : Icons.cancel_outlined,
                                        size: 15,
                                        color: isRight ? AppColors.primary : AppColors.chartTrend,
                                      ),
                                    )
                                  else if (isRight && answered)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Icon(Icons.circle_outlined, size: 15, color: AppColors.primary),
                                    )
                                  else
                                    const SizedBox(width: 21),
                                  Expanded(
                                    child: Text(
                                      '${String.fromCharCode(65 + opt.key)}. ${opt.value}',
                                      style: ExamSystemUi.captionSecondary.copyWith(
                                        color: fg,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],

            // ── Integrity ──
            _SectionHeader(icon: Icons.shield_outlined, label: l10n.teacherLiveMonitorIntegrityLabel),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _InfoChip(
                  icon: Icons.tab_outlined,
                  label: '${l10n.teacherLiveMonitorTabSwitches}: $tabs',
                  color: tabs >= 5 ? AppColors.chartTrend : AppColors.textMuted,
                ),
                _InfoChip(
                  icon: Icons.timer_off_outlined,
                  label: '${l10n.teacherLiveMonitorFocusLoss}: ${focus}s',
                  color: focus >= 120 ? AppColors.chartTrend : focus >= 45 ? Colors.orange.shade700 : AppColors.textMuted,
                ),
                _InfoChip(
                  icon: Icons.content_paste_outlined,
                  label: '${l10n.teacherLiveMonitorCopyPaste}: $copy',
                  color: copy >= 3 ? AppColors.chartTrend : copy >= 1 ? Colors.orange.shade700 : AppColors.textMuted,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(label, style: ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label, required this.done});
  final IconData icon;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.primary : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(done ? Icons.check_circle_outline : icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(label, style: ExamSystemUi.captionMuted.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}

class _AnswerBadge extends StatelessWidget {
  const _AnswerBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: ExamSystemUi.captionMuted.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: ExamSystemUi.captionMuted.copyWith(color: color)),
      ],
    );
  }
}

