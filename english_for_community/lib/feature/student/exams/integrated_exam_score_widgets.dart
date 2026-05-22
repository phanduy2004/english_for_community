import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Integrated / skills exams use per-skill 0–10 scores and an arithmetic mean — not `pts`.
bool isIntegratedExamFormat(String? examFormat) {
  return examFormat == 'integrated_four_skills' || examFormat == 'skills_exam';
}

bool isIntegratedExamFromAttempt(Map<String, dynamic>? attempt) {
  if (attempt == null) return false;
  final scores = attempt['scores'];
  if (scores is Map && scores['examFormat'] != null) {
    return isIntegratedExamFormat('${scores['examFormat']}');
  }
  final snap = attempt['examSnapshot'];
  if (snap is Map) {
    final settings = snap['settings'];
    if (settings is Map && settings['examFormat'] != null) {
      return isIntegratedExamFormat('${settings['examFormat']}');
    }
  }
  return false;
}

String formatIntegratedScore(dynamic score) {
  final n = num.tryParse('$score');
  if (n == null) return '—';
  if (n == n.truncate()) return '${n.toInt()}';
  return n.toStringAsFixed(1);
}

/// One row in the integrated skill score breakdown (teacher grade / student result).
class IntegratedScoreRowData {
  const IntegratedScoreRowData({
    required this.icon,
    required this.skill,
    required this.label,
    this.score,
    this.detail,
    required this.isPending,
    this.sectionId,
  });

  final IconData icon;
  final String skill;
  final String label;
  final dynamic score;
  final String? detail;
  final bool isPending;
  final String? sectionId;
}

IconData integratedSkillIcon(String skill) {
  switch (skill) {
    case 'listening':
      return Icons.headphones_outlined;
    case 'speaking':
      return Icons.mic_none_outlined;
    case 'reading':
      return Icons.menu_book_outlined;
    case 'writing':
      return Icons.edit_outlined;
    case 'grammar':
      return Icons.spellcheck_outlined;
    default:
      return Icons.category_outlined;
  }
}

String integratedSkillLabel(AppLocalizations l10n, String skill) {
  switch (skill) {
    case 'listening':
      return l10n.integratedSkillListening;
    case 'reading':
      return l10n.integratedSkillReading;
    case 'writing':
      return l10n.integratedSkillWriting;
    case 'speaking':
      return l10n.integratedSkillSpeaking;
    case 'grammar':
      return l10n.integratedSkillGrammar;
    default:
      return skill;
  }
}

/// Ordered skill + grammar rows from attempt snapshot and `scores.skillScores`.
List<IntegratedScoreRowData> listIntegratedScoreRowsFromAttempt(
  Map<String, dynamic>? attempt,
  AppLocalizations l10n,
) {
  if (attempt == null) return [];
  final scores = attempt['scores'];
  if (scores is! Map) return [];
  final snap = attempt['examSnapshot'];
  final skillScoresRaw = scores['skillScores'] as Map?;
  final rows = <IntegratedScoreRowData>[];

  void addSkillRow(String sid, String skill, Map? se) {
    final status = '${se?['status'] ?? ''}';
    if (status == 'no_content') return;
    final isPending =
        status == 'pending_ai' || (status == 'pending_manual' && se?['score'] == null);
    rows.add(
      IntegratedScoreRowData(
        icon: integratedSkillIcon(skill),
        skill: skill,
        label: integratedSkillLabel(l10n, skill),
        score: se?['score'],
        detail: se?['detail'] as String?,
        isPending: isPending,
        sectionId: sid.isNotEmpty ? sid : null,
      ),
    );
  }

  if (snap is Map) {
    final sections = (snap['sections'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
      ..sort(
        (a, b) => (num.tryParse('${a['order'] ?? 0}') ?? 0)
            .compareTo(num.tryParse('${b['order'] ?? 0}') ?? 0),
      );
    for (final sec in sections) {
      final skill = '${sec['skill'] ?? ''}';
      if (!['listening', 'speaking', 'reading', 'writing'].contains(skill)) continue;
      final sid = '${sec['sectionId'] ?? ''}'.trim();
      if (sid.isEmpty) continue;
      final se = skillScoresRaw?[sid] as Map?;
      addSkillRow(sid, skill, se);
    }
  } else if (skillScoresRaw != null) {
    for (final entry in skillScoresRaw.entries) {
      final se = entry.value;
      if (se is! Map) continue;
      final skill = '${se['skill'] ?? ''}';
      addSkillRow(entry.key.toString(), skill, se);
    }
  }

  final grammarScore = scores['grammarScore'] as Map?;
  final grammarItems =
      snap is Map ? ((snap['settings'] as Map?)?['grammarItems'] as List?) : null;
  if (grammarScore != null || (grammarItems != null && grammarItems.isNotEmpty)) {
    rows.add(
      IntegratedScoreRowData(
        icon: integratedSkillIcon('grammar'),
        skill: 'grammar',
        label: integratedSkillLabel(l10n, 'grammar'),
        score: grammarScore?['score'],
        detail: grammarScore?['detail'] as String?,
        isPending: false,
      ),
    );
  }

  return rows;
}

/// Teacher grading: table-style breakdown + average with formula hint.
class IntegratedGradingScorePanel extends StatelessWidget {
  const IntegratedGradingScorePanel({
    super.key,
    required this.attempt,
    this.title,
    this.showFormulaHint = true,
  });

  final Map<String, dynamic> attempt;
  final String? title;
  final bool showFormulaHint;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scores = attempt['scores'];
    if (scores is! Map) return const SizedBox.shrink();

    final rows = listIntegratedScoreRowsFromAttempt(attempt, l10n);
    final finalScore = scores['finalScore'];
    final finalStatus = '${scores['finalStatus'] ?? ''}';
    final isPartial = finalStatus == 'partial';

    if (rows.isEmpty) {
      return AppCard(
        variant: AppCardVariant.outline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(title!, style: ExamSystemUi.sectionTitle(context)),
              const SizedBox(height: 10),
            ],
            Text(
              l10n.integratedScoresAwaiting,
              style: ExamSystemUi.captionSecondary,
            ),
          ],
        ),
      );
    }

    return AppCard(
      variant: AppCardVariant.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(title!, style: ExamSystemUi.sectionTitle(context)),
            const SizedBox(height: 12),
          ],
          if (showFormulaHint) ...[
            Text(
              l10n.integratedGradingAvgFormulaHint,
              style: ExamSystemUi.captionMuted.copyWith(fontSize: 12, height: 1.35),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  l10n.integratedGradingColumnSkill,
                  style: ExamSystemUi.captionMuted.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  l10n.integratedGradingColumnScore,
                  textAlign: TextAlign.end,
                  style: ExamSystemUi.captionMuted.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...rows.map((row) => _GradingScoreRow(row: row, l10n: l10n)),
          const Divider(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPartial ? l10n.integratedSkillFinalPartial : l10n.integratedSkillFinalAvg,
                        style: ExamSystemUi.listTitle(context).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      if (isPartial)
                        Text(
                          l10n.integratedSkillScorePending,
                          style: ExamSystemUi.captionMuted.copyWith(fontSize: 11),
                        ),
                    ],
                  ),
                ),
                Text(
                  finalScore != null
                      ? l10n.integratedSkillScoreLabel(formatIntegratedScore(finalScore))
                      : '—',
                  style: ExamSystemUi.listTitle(context).copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isPartial ? AppColors.warning : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradingScoreRow extends StatelessWidget {
  const _GradingScoreRow({required this.row, required this.l10n});

  final IntegratedScoreRowData row;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(row.icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: ExamSystemUi.captionSecondary.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (row.detail != null && row.detail!.isNotEmpty)
                  Text(
                    row.detail!,
                    style: ExamSystemUi.captionMuted.copyWith(fontSize: 11),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: row.isPending
                  ? Text(
                      l10n.integratedSkillScorePending,
                      style: ExamSystemUi.captionMuted.copyWith(
                        color: AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : Text(
                      row.score != null
                          ? l10n.integratedSkillScoreLabel(formatIntegratedScore(row.score))
                          : '—',
                      style: ExamSystemUi.captionSecondary.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.success,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Summary card: one row per skill/grammar + average (partial or finalized).
class IntegratedScoreSummaryCard extends StatelessWidget {
  const IntegratedScoreSummaryCard({
    super.key,
    required this.scores,
    this.attempt,
    this.title,
    this.compact = false,
  });

  final Map<String, dynamic> scores;
  final Map<String, dynamic>? attempt;
  final String? title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final finalScore = scores['finalScore'];
    final finalStatus = '${scores['finalStatus'] ?? ''}';
    final isPartial = finalStatus == 'partial';

    final attemptMap = attempt ?? {'scores': scores};
    final rows = listIntegratedScoreRowsFromAttempt(
      Map<String, dynamic>.from(attemptMap),
      l10n,
    );

    if (rows.isEmpty) {
      return AppCard(
        variant: AppCardVariant.outline,
        child: Text(
          l10n.integratedScoresAwaiting,
          style: ExamSystemUi.captionSecondary,
        ),
      );
    }

    final rowWidgets = <Widget>[];
    for (final row in rows) {
      rowWidgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: compact ? 6 : 8),
          child: Row(
            children: [
              Icon(row.icon, size: compact ? 14 : 15, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  row.label,
                  style: ExamSystemUi.captionSecondary.copyWith(color: AppColors.textPrimary),
                ),
              ),
              if (row.isPending)
                Text(
                  l10n.integratedSkillScorePending,
                  style: ExamSystemUi.captionMuted.copyWith(
                    color: AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Text(
                  row.score != null
                      ? l10n.integratedSkillScoreLabel(formatIntegratedScore(row.score))
                      : '—',
                  style: ExamSystemUi.captionSecondary.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return AppCard(
      variant: AppCardVariant.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(title!, style: ExamSystemUi.sectionTitle(context)),
            SizedBox(height: compact ? 8 : 12),
          ],
          ...rowWidgets,
          Divider(height: compact ? 14 : 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  isPartial ? l10n.integratedSkillFinalPartial : l10n.integratedSkillFinalAvg,
                  style: ExamSystemUi.listTitle(context).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 13 : 14,
                  ),
                ),
              ),
              Text(
                finalScore != null
                    ? l10n.integratedSkillScoreLabel(formatIntegratedScore(finalScore))
                    : '—',
                style: ExamSystemUi.listTitle(context).copyWith(
                  fontSize: compact ? 16 : 18,
                  fontWeight: FontWeight.w700,
                  color: isPartial ? AppColors.warning : AppColors.primary,
                ),
              ),
            ],
          ),
          if (isPartial) ...[
            const SizedBox(height: 4),
            Text(
              l10n.integratedSkillScorePending,
              style: ExamSystemUi.captionMuted.copyWith(fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

/// Per grammar question: show correct count — never "pts" on integrated exams.
class IntegratedGrammarItemResultFooter extends StatelessWidget {
  const IntegratedGrammarItemResultFooter({super.key, required this.itemResult});

  final Map<String, dynamic>? itemResult;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ap = num.tryParse('${itemResult?['awardedPoints'] ?? 0}') ?? 0;
    final mx = num.tryParse('${itemResult?['maxPoints'] ?? 0}') ?? 0;
    if (mx <= 0) return const SizedBox.shrink();

    final correct = ap >= mx && mx > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Row(
        children: [
          Icon(
            correct ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 16,
            color: correct ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(width: 8),
          Text(
            l10n.integratedGrammarItemResult('${ap.toInt()}', '${mx.toInt()}'),
            style: ExamSystemUi.captionSecondary.copyWith(
              fontWeight: FontWeight.w600,
              color: correct ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
