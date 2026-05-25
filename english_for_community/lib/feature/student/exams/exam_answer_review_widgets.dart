import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
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

/// Teacher / review MCQ list — green = correct, red = wrong selection (`04` §11).
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
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Text('—', style: StudentMobileUi.body(context)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              StudentMobileUi.pageHPadding,
              AppSpacing.s2,
              StudentMobileUi.pageHPadding,
              AppSpacing.s3,
            ),
            child: Text(
              context.l10n.teacherAttemptGradeChoicesLabel,
              style: StudentMobileUi.cardTitle(context),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: StudentMobileUi.pageHPadding),
          child: Column(
            children: [
              for (var i = 0; i < options.length; i++)
                StudentMobileUi.mcqOption(
                  context: context,
                  index: i,
                  text: options[i],
                  showReviewCorrect: correctIndexes.contains(i),
                  showReviewWrong:
                      selectedIndexes.contains(i) && !correctIndexes.contains(i),
                  margin: EdgeInsets.only(
                    bottom: i == options.length - 1 ? 0 : AppSpacing.s3,
                  ),
                ),
            ],
          ),
        ),
      ],
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

    return AppCard(
      variant: AppCardVariant.filled,
      padding: const EdgeInsets.all(StudentMobileUi.pageHPadding),
      radius: AppRadius.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.teacherAttemptGradePointsShort('$awarded', '$max'),
                style: StudentMobileUi.sectionTitle(context),
              ),
              const Spacer(),
              if (max > 0)
                Text(
                  '${(frac * 100).round()}%',
                  style: StudentMobileUi.cardTitle(context),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: LinearProgressIndicator(
              value: max > 0 ? frac : 0,
              minHeight: 6,
              backgroundColor: AppColors.outlineMuted,
              color: AppColors.primary,
            ),
          ),
          if (rationale != null && rationale!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(l10n.teacherGradingAiRationale, style: StudentMobileUi.cardTitle(context)),
            const SizedBox(height: AppSpacing.s3),
            Text(rationale!, style: StudentMobileUi.body(context)),
          ],
          if (canEdit) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(l10n.teacherGradingAwardedPoints, style: StudentMobileUi.cardTitle(context)),
            const SizedBox(height: AppSpacing.s3),
            TextField(
              controller: pointsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTypography.body(),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceCard,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input + 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: StudentMobileUi.pageHPadding,
                  vertical: StudentMobileUi.pageHPadding,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(l10n.teacherGradingNotesHint, style: StudentMobileUi.cardTitle(context)),
            const SizedBox(height: AppSpacing.s3),
            TextField(
              controller: noteController,
              maxLines: 3,
              style: AppTypography.body(),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceCard,
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input + 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: StudentMobileUi.pageHPadding,
                  vertical: StudentMobileUi.pageHPadding,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
