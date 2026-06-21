import 'package:english_for_community/core/entity/speaking/speaking_attempt_entity.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/entity/speaking/speaking_set_entity.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:flutter/material.dart';

/// Read-only speaking review — student transcript vs reference sentence (no mic UI).
class ExamEmbeddedSpeakingReviewPanel extends StatefulWidget {
  const ExamEmbeddedSpeakingReviewPanel({
    super.key,
    required this.speakingSet,
  });

  final SpeakingSetEntity speakingSet;

  @override
  State<ExamEmbeddedSpeakingReviewPanel> createState() =>
      _ExamEmbeddedSpeakingReviewPanelState();
}

class _ExamEmbeddedSpeakingReviewPanelState extends State<ExamEmbeddedSpeakingReviewPanel> {
  int _selectedIndex = 0;

  List<({String id, String script, SpeakingAttemptEntity? attempt})> get _rows {
    final sentences = [...widget.speakingSet.sentences]
      ..sort((a, b) => a.order.compareTo(b.order));
    return [
      for (final s in sentences)
        (
          id: s.id,
          script: s.script.trim(),
          attempt: s.history.isNotEmpty ? s.history.first : null,
        ),
    ];
  }

  bool _sentencePassed(String expected, SpeakingAttemptEntity? attempt) {
    if (attempt == null) return false;
    final wer = attempt.score?.wer;
    if (wer != null) return wer <= 0.25;
    final user = attempt.userTranscript?.trim() ?? '';
    if (user.isEmpty || expected.isEmpty) return false;
    return _normalizeSpeakingText(user) == _normalizeSpeakingText(expected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = _rows;
    if (rows.isEmpty) {
      return AppCard(
        variant: AppCardVariant.outline,
        child: Text(l10n.integratedExamEmbeddedNoResource, style: ExamSystemUi.captionSecondary),
      );
    }

    final idx = _selectedIndex.clamp(0, rows.length - 1);
    final row = rows[idx];
    final user = row.attempt?.userTranscript?.trim() ?? '';
    final answered = user.isNotEmpty;
    final correct = answered && _sentencePassed(row.script, row.attempt);

    Color userBorder = AppColors.outline;
    Color userBg = AppColors.surfaceCard;
    if (answered) {
      userBorder = correct ? AppColors.success : AppColors.danger;
      userBg = correct ? AppColors.successBg : AppColors.dangerBg;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < rows.length; i++)
              _SentencePill(
                number: i + 1,
                selected: i == idx,
                answered: (rows[i].attempt?.userTranscript?.trim().isNotEmpty ?? false),
                isCorrect: _sentencePassed(rows[i].script, rows[i].attempt),
                onTap: () => setState(() => _selectedIndex = i),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l10n.listeningSentenceNumber(idx + 1),
          style: ExamSystemUi.embeddedSectionLabelStyle,
        ),
        const SizedBox(height: 8),
        _ReviewBlock(
          label: l10n.integratedExamReviewYourAnswer,
          text: answered ? user : l10n.integratedExamReviewNotAnswered,
          borderColor: userBorder,
          bgColor: userBg,
          muted: !answered,
        ),
        const SizedBox(height: 10),
        _ReviewBlock(
          label: l10n.integratedExamReviewCorrectAnswer,
          text: row.script.isNotEmpty ? row.script : '—',
          borderColor: AppColors.success.withValues(alpha: 0.45),
          bgColor: AppColors.successBg.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}

String _normalizeSpeakingText(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[.,!?]'), '').trim();

class _SentencePill extends StatelessWidget {
  const _SentencePill({
    required this.number,
    required this.selected,
    required this.answered,
    required this.isCorrect,
    required this.onTap,
  });

  final int number;
  final bool selected;
  final bool answered;
  final bool isCorrect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.surfaceCard;
    Color border = AppColors.outline;
    Color fg = AppColors.textSecondary;
    if (selected) {
      border = AppColors.primary;
      bg = AppColors.primaryTint;
      fg = AppColors.primary;
    } else if (answered) {
      border = isCorrect ? AppColors.success : AppColors.danger;
      bg = isCorrect ? AppColors.successBg : AppColors.dangerBg;
      fg = isCorrect ? AppColors.success : AppColors.danger;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(color: border, width: selected ? 1.5 : 1),
          ),
          child: Text(
            '$number',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
          ),
        ),
      ),
    );
  }
}

class _ReviewBlock extends StatelessWidget {
  const _ReviewBlock({
    required this.label,
    required this.text,
    required this.borderColor,
    required this.bgColor,
    this.muted = false,
  });

  final String label;
  final String text;
  final Color borderColor;
  final Color bgColor;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.outline,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: ExamSystemUi.captionMuted.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              style: ExamSystemUi.captionSecondary.copyWith(
                height: 1.45,
                fontSize: 15,
                color: muted ? AppColors.textMuted : AppColors.textPrimary,
                fontStyle: muted ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
