import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/locale/l10n_context.dart';
import '../../../core/theme/app_color.dart';
import '../../../core/theme/app_skill_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/student_mobile_ui.dart';

class WritingCard extends StatelessWidget {
  final String title;
  final IconData leadingIcon;
  final VoidCallback? onTap;
  final VoidCallback? onHistoryTap;
  final String? taskType;
  final String? level;
  final int? submissions;
  final double? avgScore;

  const WritingCard({
    super.key,
    required this.title,
    this.leadingIcon = Icons.article_outlined,
    this.onTap,
    this.onHistoryTap,
    this.taskType,
    this.level,
    this.submissions,
    this.avgScore,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = StudentMobileUi.difficultyColor(level);

    return StudentMobileUi.skillAccentCard(
      skill: SkillType.writing,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudentMobileUi.skillIconBox(
            leadingIcon,
            size: 48,
            skill: SkillType.writing,
          ),
          const SizedBox(width: AppSpacing.s5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: StudentMobileUi.cardTitle(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.s3),
                Wrap(
                  spacing: AppSpacing.s3,
                  runSpacing: AppSpacing.s2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (level != null && level!.isNotEmpty)
                      _Badge(
                        text: level!,
                        color: badgeColor,
                      ),
                    if (submissions != null && submissions! > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.description_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.s2),
                          Text(
                            context.l10n.writingSubmissionsCount(submissions!),
                            style: StudentMobileUi.caption(context),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (onHistoryTap != null)
                kIsWeb
                    ? GestureDetector(
                        onTap: onHistoryTap,
                        child: const Padding(
                          padding: EdgeInsets.all(AppSpacing.s2),
                          child: Icon(Icons.history, color: AppColors.textMuted, size: 22),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.history, color: AppColors.textMuted, size: 22),
                        onPressed: onHistoryTap,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
              if (avgScore != null) ...[
                const SizedBox(height: AppSpacing.s3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s3,
                    vertical: AppSpacing.s2,
                  ),
                  decoration: BoxDecoration(
                    color: avgScore! >= 7.0 ? AppColors.successBg : AppColors.warningBg,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    border: Border.all(
                      color: avgScore! >= 7.0
                          ? AppColors.success.withValues(alpha: 0.35)
                          : AppColors.warning.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rate_rounded,
                        size: 14,
                        color: avgScore! >= 7.0 ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.s2),
                      Text(
                        avgScore!.toStringAsFixed(1),
                        style: AppTypography.label(
                          color: avgScore! >= 7.0 ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.label(color: color),
      ),
    );
  }
}
