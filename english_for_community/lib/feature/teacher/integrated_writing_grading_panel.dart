import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/feature/student/exams/integrated_exam_score_widgets.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:flutter/material.dart';

/// Teacher grading block for integrated exam writing (manual 0–10 + AI draft).
class IntegratedWritingGradingPanel extends StatelessWidget {
  const IntegratedWritingGradingPanel({
    super.key,
    required this.sectionId,
    required this.sectionAnswers,
    required this.skillEntry,
    required this.scoreController,
    required this.noteController,
    required this.onSave,
    required this.onRunAi,
    bool? aiLoading,
    bool? canEdit,
  })  : aiLoading = aiLoading ?? false,
        canEdit = canEdit ?? true;

  final String sectionId;
  final Map<String, dynamic>? sectionAnswers;
  final Map<String, dynamic>? skillEntry;
  final TextEditingController scoreController;
  final TextEditingController noteController;
  final VoidCallback onSave;
  final VoidCallback onRunAi;
  final bool aiLoading;
  final bool canEdit;

  String get _draft {
    final d = sectionAnswers?['writingDraft'];
    return d is String ? d.trim() : '';
  }

  int get _wordCount {
    final w = sectionAnswers?['wordCount'];
    if (w is num) return w.toInt();
    if (_draft.isEmpty) return 0;
    return _draft.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
  }

  Map<String, dynamic>? get _aiFeedback {
    final fb = skillEntry?['aiFeedback'];
    return fb is Map ? Map<String, dynamic>.from(fb) : null;
  }

  num? get _aiDraftScore {
    final s = skillEntry?['aiDraftScore'] ?? skillEntry?['score'];
    return s is num ? s : num.tryParse('$s');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final seScore = skillEntry?['score'];
    final aiBand = _aiFeedback?['overall'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_draft.isEmpty)
            Text(
              l10n.integratedWritingGradingNoDraft,
              style: ExamSystemUi.captionMuted,
            )
          else ...[
            Text(
              l10n.integratedWritingGradingEssayLabel,
              style: ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineMuted),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _draft,
                  style: const TextStyle(fontSize: 13, height: 1.45),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.integratedWritingGradingWordCount('$_wordCount'),
              style: ExamSystemUi.captionMuted.copyWith(fontSize: 11),
            ),
          ],
          const SizedBox(height: 12),
          if (seScore != null) ...[
            Text(
              l10n.integratedSkillScoreLabel(formatIntegratedScore(seScore)),
              style: ExamSystemUi.listTitle(context).copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (_aiFeedback != null && aiBand != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.integratedWritingGradingAiBand('$aiBand'),
                    style: ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (_aiDraftScore != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.integratedWritingGradingAiExamScore(
                        formatIntegratedScore(_aiDraftScore),
                      ),
                      style: ExamSystemUi.captionMuted.copyWith(fontSize: 12),
                    ),
                  ],
                  ..._aiBulletPreview(context),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (canEdit)
                aiLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TeacherOutlinedButton(
                        onPressed: onRunAi,
                        icon: Icons.auto_awesome_outlined,
                        label: l10n.integratedWritingGradingRunAi,
                      ),
              if (canEdit && _aiDraftScore != null)
                TeacherFilledButton(
                  onPressed: () {
                    scoreController.text = formatIntegratedScore(_aiDraftScore);
                    onSave();
                  },
                  label: l10n.integratedWritingGradingApplyAi,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.integratedWritingGradingManual,
            style: ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 90,
                child: TextField(
                  controller: scoreController,
                  enabled: canEdit,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: const OutlineInputBorder(),
                    labelText: l10n.integratedSkillEnterScore,
                    labelStyle: const TextStyle(fontSize: 11),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: noteController,
                  enabled: canEdit,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: const OutlineInputBorder(),
                    hintText: l10n.teacherGradingNotesHint,
                    hintStyle: const TextStyle(fontSize: 11),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              if (canEdit) ...[
                const SizedBox(width: 8),
                TeacherFilledButton(
                  onPressed: onSave,
                  label: l10n.integratedSkillSaveScore,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _aiBulletPreview(BuildContext context) {
    final fb = _aiFeedback;
    if (fb == null) return [];
    final lines = <String>[];
    void takeBullets(String key, int max) {
      final raw = fb[key];
      if (raw is! List) return;
      for (final item in raw.take(max)) {
        final s = '$item'.trim();
        if (s.isNotEmpty) lines.add(s);
      }
    }
    takeBullets('trBullets', 1);
    takeBullets('ccBullets', 1);
    if (lines.isEmpty) return [];
    return [
      const SizedBox(height: 8),
      ...lines.map(
        (line) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '• $line',
            style: ExamSystemUi.captionMuted.copyWith(fontSize: 11, height: 1.35),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ];
  }
}
