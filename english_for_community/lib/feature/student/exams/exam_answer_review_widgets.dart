import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:flutter/material.dart';

/// Parses [correctOptionIndexes] from an exam item map.
Set<int> mcqCorrectIndexesFromItem(Map<String, dynamic> item) {
  final raw = item['correctOptionIndexes'];
  if (raw is! List) return {};
  return raw.map((e) => int.tryParse('$e') ?? -1).where((i) => i >= 0).toSet();
}

/// Parses [selectedIndexes] from a stored answer map.
Set<int> mcqSelectedIndexesFromAnswer(Map<String, dynamic>? answer) {
  final raw = answer?['selectedIndexes'];
  if (raw is! List) return {};
  return raw.map((e) => int.tryParse('$e') ?? -1).where((i) => i >= 0).toSet();
}

String _optionLetter(int index) => String.fromCharCode(65 + index);

/// Teacher / review MCQ list — green = correct, red = wrong selection (matches reading review).
class McqGradingReviewList extends StatelessWidget {
  const McqGradingReviewList({
    super.key,
    required this.options,
    required this.correctIndexes,
    required this.selectedIndexes,
    this.showHeader = true,
  });

  final List<String> options;
  final Set<int> correctIndexes;
  final Set<int> selectedIndexes;
  final bool showHeader;

  static McqGradingReviewList fromMaps({
    required Map<String, dynamic> item,
    Map<String, dynamic>? answer,
    bool showHeader = true,
  }) {
    final options = (item['options'] as List?)?.map((e) => '$e').toList() ?? <String>[];
    return McqGradingReviewList(
      options: options,
      correctIndexes: mcqCorrectIndexesFromItem(item),
      selectedIndexes: mcqSelectedIndexesFromAnswer(answer),
      showHeader: showHeader,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          '—',
          style: ExamSystemUi.captionSecondary.copyWith(color: AppColors.textPrimary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Text(
              context.l10n.teacherAttemptGradeChoicesLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
        for (var i = 0; i < options.length; i++)
          _McqReviewOptionTile(
            letter: _optionLetter(i),
            text: options[i],
            isCorrect: correctIndexes.contains(i),
            isSelected: selectedIndexes.contains(i),
            isLast: i == options.length - 1,
          ),
      ],
    );
  }
}

class _McqReviewOptionTile extends StatelessWidget {
  const _McqReviewOptionTile({
    required this.letter,
    required this.text,
    required this.isCorrect,
    required this.isSelected,
    required this.isLast,
  });

  final String letter;
  final String text;
  final bool isCorrect;
  final bool isSelected;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    const correctGreen = Color(0xFF16A34A);
    const wrongRed = Color(0xFFDC2626);

    Color bg = AppColors.surfaceCard;
    Color border = AppColors.outline;
    Color textColor = AppColors.textPrimary;
    IconData? icon;
    Color? iconColor;

    if (isCorrect) {
      bg = const Color(0xFFECFDF5);
      border = correctGreen;
      textColor = const Color(0xFF14532D);
      icon = Icons.check_circle_rounded;
      iconColor = correctGreen;
    } else if (isSelected) {
      bg = const Color(0xFFFEF2F2);
      border = wrongRed;
      textColor = const Color(0xFF7F1D1D);
      icon = Icons.cancel_rounded;
      iconColor = wrongRed;
    }

    return Container(
      margin: EdgeInsets.fromLTRB(12, 0, 12, isLast ? 12 : 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 1.25),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: border.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
            ),
            child: Text(
              letter,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: textColor,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(top: 12, right: 12),
              child: Icon(icon, color: iconColor, size: 22),
            ),
        ],
      ),
    );
  }
}

/// Score + manual grading fields (teacher attempt page).
class TeacherAttemptGradingFooter extends StatelessWidget {
  const TeacherAttemptGradingFooter({
    super.key,
    required this.awarded,
    required this.max,
    required this.pointsController,
    required this.noteController,
    required this.canEdit,
    this.rationale,
  });

  final num awarded;
  final num max;
  final TextEditingController pointsController;
  final TextEditingController noteController;
  final bool canEdit;
  final String? rationale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final frac = max > 0 ? (awarded / max).clamp(0.0, 1.0).toDouble() : 0.0;
    const labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
    const fieldStyle = TextStyle(fontSize: 14, color: AppColors.textPrimary);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.teacherAttemptGradePointsShort('$awarded', '$max'),
                style: ExamSystemUi.listTitle(context).copyWith(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (max > 0)
                Text(
                  '${(frac * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: max > 0 ? frac : 0,
              minHeight: 8,
              backgroundColor: AppColors.outlineMuted,
              color: AppColors.primary,
            ),
          ),
          if (rationale != null && rationale!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(l10n.teacherGradingAiRationale, style: labelStyle),
            const SizedBox(height: 6),
            Text(
              rationale!,
              style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.textPrimary),
            ),
          ],
          if (canEdit) ...[
            const SizedBox(height: 14),
            Text(l10n.teacherGradingAwardedPoints, style: labelStyle),
            const SizedBox(height: 6),
            TextField(
              controller: pointsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: fieldStyle,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceCard,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.teacherGradingNotesHint, style: labelStyle),
            const SizedBox(height: 6),
            TextField(
              controller: noteController,
              maxLines: 3,
              style: fieldStyle,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceCard,
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
