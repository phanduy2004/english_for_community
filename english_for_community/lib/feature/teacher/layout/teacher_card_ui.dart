import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:flutter/material.dart';

/// Pill badge — shared by grading hub + classroom assignment cards.
class TeacherGradingPill extends StatelessWidget {
  const TeacherGradingPill({
    super.key,
    required this.label,
    required this.color,
    this.alpha = 0.1,
  });

  final String label;
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      ),
    );
  }
}

/// Icon + muted text row under grading / assignment cards.
class TeacherGradingMetaRow extends StatelessWidget {
  const TeacherGradingMetaRow({
    super.key,
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TeacherWebUi.metaMuted)),
        ],
      ),
    );
  }
}

enum TeacherContextChipTone { neutral, live, info, warning }

/// Rounded context chip — assignment header + classroom cards.
class TeacherContextChip extends StatelessWidget {
  const TeacherContextChip({
    super.key,
    required this.icon,
    required this.label,
    this.tone = TeacherContextChipTone.neutral,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final TeacherContextChipTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (tone) {
      TeacherContextChipTone.live => (
          AppColors.successBg,
          AppColors.success,
          AppColors.success.withValues(alpha: 0.35),
        ),
      TeacherContextChipTone.info => (
          AppColors.infoBg,
          AppColors.info,
          AppColors.info.withValues(alpha: 0.3),
        ),
      TeacherContextChipTone.warning => (
          AppColors.warningBg,
          AppColors.warning,
          AppColors.warning.withValues(alpha: 0.35),
        ),
      TeacherContextChipTone.neutral => (
          AppColors.surfaceSubtle,
          AppColors.textPrimary,
          AppColors.outline,
        ),
    };

    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TeacherWebUi.webLabel(context).copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 14, color: fg.withValues(alpha: 0.7)),
          ],
        ],
      ),
    );

    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadius.lg), child: child),
    );
  }
}

/// Mini KPI column used in assignment context strips.
class TeacherCardKpiMini extends StatelessWidget {
  const TeacherCardKpiMini({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TeacherWebUi.webKpiValue(context).copyWith(color: color, fontSize: 20),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TeacherWebUi.webCaption(context),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    if (onTap == null) {
      return Expanded(child: child);
    }

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          hoverColor: AppColors.hoverOverlay,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            child: child,
          ),
        ),
      ),
    );
  }
}
