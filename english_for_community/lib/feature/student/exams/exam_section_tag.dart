import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:flutter/material.dart';

enum ExamSectionTagVariant { primary, sub }

/// Square compact tag for exam section / sub-section navigation.
class ExamSectionTag extends StatelessWidget {
  const ExamSectionTag({
    super.key,
    required this.label,
    required this.selected,
    required this.done,
    this.onTap,
    this.enabled = true,
    this.variant = ExamSectionTagVariant.primary,
    this.skillAccent,
  });

  final String label;
  final bool selected;
  final bool done;
  final VoidCallback? onTap;
  final bool enabled;
  final ExamSectionTagVariant variant;
  /// Skill tint when this primary tag is selected (e.g. Listening = blue).
  final SkillColorSet? skillAccent;

  static const double primaryHeight = 28;
  static const double subHeight = 26;
  static const double primaryRadius = 6;
  static const double subRadius = 5;
  static const double gap = 4;

  bool get _isSub => variant == ExamSectionTagVariant.sub;

  @override
  Widget build(BuildContext context) {
    final height = _isSub ? subHeight : primaryHeight;
    final radius = _isSub ? subRadius : primaryRadius;
    final fontSize = _isSub ? 10.0 : 11.0;

    final accent = skillAccent;
    final borderColor = selected
        ? (accent?.dark ?? AppColors.textPrimary)
        : (_isSub ? accent?.color.withValues(alpha: 0.35) ?? AppColors.outline : AppColors.outline);
    final borderWidth = selected ? 1.5 : 1.0;

    final Color bg;
    if (selected) {
      bg = accent?.tint ?? AppColors.surfaceCard;
    } else if (done) {
      bg = _isSub
          ? AppColors.surfaceCard
          : AppColors.outlineMuted.withValues(alpha: 0.45);
    } else {
      bg = AppColors.surfaceCard;
    }

    final textColor = selected
        ? (accent?.dark ?? AppColors.textPrimary)
        : done
            ? AppColors.textPrimary
            : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(radius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          height: height,
          padding: EdgeInsets.symmetric(horizontal: _isSub ? 7 : 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (done) ...[
                Icon(Icons.check, size: _isSub ? 10 : 11, color: textColor),
                SizedBox(width: _isSub ? 3 : 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                  height: 1,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal row of primary [ExamSectionTag]s without scrollbar.
class ExamSectionTagRow extends StatelessWidget {
  const ExamSectionTagRow({
    super.key,
    required this.tags,
  });

  final List<Widget> tags;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ExamSectionTag.primaryHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        primary: false,
        itemCount: tags.length,
        itemBuilder: (_, i) => tags[i],
        separatorBuilder: (_, __) => const SizedBox(width: ExamSectionTag.gap),
      ),
    );
  }
}

/// Nested sub-exercises under Listening — visually distinct from main skill tabs.
class ExamListeningSubNavGroup extends StatelessWidget {
  const ExamListeningSubNavGroup({
    super.key,
    required this.sectionTitle,
    required this.hint,
    required this.tags,
  });

  final String sectionTitle;
  final String hint;
  final List<Widget> tags;

  static const _skill = AppSkillColors.listening;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: _skill.tint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _skill.color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _skill.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(Icons.headphones_outlined, size: 13, color: _skill.dark),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sectionTitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _skill.dark,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      hint,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textMuted,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: ExamSectionTag.gap,
            runSpacing: ExamSectionTag.gap,
            children: tags,
          ),
        ],
      ),
    );
  }
}
