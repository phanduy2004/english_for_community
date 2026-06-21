import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/e4c_scroll_behavior.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:flutter/material.dart';

/// Read-only writing review — prompt, student draft, teacher feedback/score.
class ExamEmbeddedWritingReviewPanel extends StatelessWidget {
  const ExamEmbeddedWritingReviewPanel({
    super.key,
    this.promptTitle,
    this.promptText,
    required this.studentDraft,
    this.feedback,
    this.score,
  });

  final String? promptTitle;
  final String? promptText;
  final String studentDraft;
  final String? feedback;
  final dynamic score;

  int get _wordCount {
    final t = studentDraft.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = promptTitle?.trim() ?? '';
    final prompt = promptText?.trim() ?? '';
    final draft = studentDraft.trim();
    final fb = feedback?.trim() ?? '';

    return e4cNoScrollbarScroll(
      child: SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
        if (title.isNotEmpty || prompt.isNotEmpty)
          AppCard(
            variant: AppCardVariant.outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(title, style: ExamSystemUi.sectionTitle(context)),
                if (title.isNotEmpty && prompt.isNotEmpty) const SizedBox(height: 8),
                if (prompt.isNotEmpty)
                  Text(prompt, style: ExamSystemUi.captionSecondary.copyWith(height: 1.45)),
              ],
            ),
          ),
        if (title.isNotEmpty || prompt.isNotEmpty) const SizedBox(height: ExamSystemUi.cardGap),
        AppCard(
          variant: AppCardVariant.outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.integratedExamReviewYourAnswer,
                      style: ExamSystemUi.captionMuted.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (score != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: Text(
                        l10n.integratedSkillScoreLabel('$score'),
                        style: ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                draft.isNotEmpty ? draft : l10n.integratedExamReviewNotAnswered,
                style: ExamSystemUi.captionSecondary.copyWith(
                  height: 1.5,
                  fontSize: 15,
                  color: draft.isEmpty ? AppColors.textMuted : AppColors.textPrimary,
                  fontStyle: draft.isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
              ),
              const SizedBox(height: 8),
              Text(l10n.wordCountN(_wordCount), style: ExamSystemUi.captionMuted),
            ],
          ),
        ),
        if (fb.isNotEmpty) ...[
          const SizedBox(height: ExamSystemUi.cardGap),
          AppCard(
            variant: AppCardVariant.outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.integratedExamReviewTeacherFeedback,
                  style: ExamSystemUi.captionMuted.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(fb, style: ExamSystemUi.captionSecondary.copyWith(height: 1.5)),
              ],
            ),
          ),
        ],
          ],
        ),
      ),
    );
  }
}
