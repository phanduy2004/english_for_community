import 'package:english_for_community/core/entity/cue_entity.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/entity/listening_entity.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:flutter/material.dart';

String _normalizeDictationText(String s) {
  return s
      .toLowerCase()
      .replaceAll(RegExp(r'[.,\/#!$%^&*;:{}=\-_`~()?"\u2019]'), '')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();
}

bool _dictationAnswerIsCorrect(String expected, String user) {
  final u = _normalizeDictationText(user);
  if (u.isEmpty) return false;
  final e = _normalizeDictationText(expected);
  if (e.isEmpty) return false;
  return u == e;
}

/// Read-only post-submit dictation review — no audio, student vs correct text.
class ExamEmbeddedListeningDictationReviewPanel extends StatefulWidget {
  const ExamEmbeddedListeningDictationReviewPanel({
    super.key,
    required this.listening,
    required this.userCueTextsByIndex,
  });

  final ListeningEntity listening;
  final Map<String, String> userCueTextsByIndex;

  @override
  State<ExamEmbeddedListeningDictationReviewPanel> createState() =>
      _ExamEmbeddedListeningDictationReviewPanelState();
}

class _ExamEmbeddedListeningDictationReviewPanelState
    extends State<ExamEmbeddedListeningDictationReviewPanel> {
  int _selectedIndex = 0;

  List<CueEntity> get _cues {
    final list = [...widget.listening.cues];
    list.sort((a, b) => a.startMs.compareTo(b.startMs));
    return list;
  }

  String _userTextAt(int index) {
    return widget.userCueTextsByIndex['$index']?.trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cues = _cues;
    if (cues.isEmpty) {
      return AppCard(
        variant: AppCardVariant.outline,
        child: Text(l10n.integratedExamEmbeddedNoResource, style: ExamSystemUi.captionSecondary),
      );
    }

    final idx = _selectedIndex.clamp(0, cues.length - 1);
    final cue = cues[idx];
    final expected = cue.text?.trim() ?? '';
    final user = _userTextAt(idx);
    final answered = user.isNotEmpty;
    final correct = answered && _dictationAnswerIsCorrect(expected, user);

    Color borderColor = AppColors.outline;
    Color bgColor = AppColors.surfaceCard;
    if (answered) {
      borderColor = correct ? AppColors.success : AppColors.danger;
      bgColor = correct ? AppColors.successBg : AppColors.dangerBg;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < cues.length; i++)
              _CuePill(
                number: i + 1,
                selected: i == idx,
                answered: _userTextAt(i).isNotEmpty,
                isCorrect: _userTextAt(i).isNotEmpty &&
                    _dictationAnswerIsCorrect(cues[i].text?.trim() ?? '', _userTextAt(i)),
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
        _AnswerBlock(
          label: l10n.integratedExamReviewYourAnswer,
          text: answered ? user : l10n.integratedExamReviewNotAnswered,
          borderColor: borderColor,
          bgColor: bgColor,
          muted: !answered,
        ),
        const SizedBox(height: 10),
        _AnswerBlock(
          label: l10n.integratedExamReviewCorrectAnswer,
          text: expected.isNotEmpty ? expected : '—',
          borderColor: AppColors.success.withValues(alpha: 0.45),
          bgColor: AppColors.successBg.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}

class _CuePill extends StatelessWidget {
  const _CuePill({
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
            style: TextStyle(fontSize: AppTypography.mobileCaption, fontWeight: FontWeight.w700, color: fg),
          ),
        ),
      ),
    );
  }
}

class _AnswerBlock extends StatelessWidget {
  const _AnswerBlock({
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
            Text(label, style: ExamSystemUi.captionMuted.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              text,
              style: ExamSystemUi.embeddedBodyStyle.copyWith(
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
