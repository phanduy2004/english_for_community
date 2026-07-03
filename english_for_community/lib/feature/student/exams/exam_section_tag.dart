import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:flutter/material.dart';

enum ExamSectionTagVariant { primary, sub }

/// Shared border-only palette for exam navigation chips (skill tabs, resources, cues).
class ExamNavTokens {
  const ExamNavTokens._();

  static const double selectedBorderWidth = 1.5;
  static const double defaultBorderWidth = 1;

  static Color borderColor({
    required bool selected,
    required bool done,
    SkillColorSet? skillAccent,
  }) {
    if (selected) return skillAccent?.color ?? AppColors.textPrimary;
    return AppColors.outlineMuted;
  }

  static double borderWidth({required bool selected}) =>
      selected ? selectedBorderWidth : defaultBorderWidth;

  static Color backgroundColor() => AppColors.surfaceCard;

  static Color textColor({
    required bool selected,
    required bool done,
    SkillColorSet? skillAccent,
  }) {
    if (selected) return skillAccent?.dark ?? AppColors.textPrimary;
    if (done) return AppColors.textPrimary;
    return AppColors.textSecondary;
  }

  static Color checkColor({
    required bool selected,
    SkillColorSet? skillAccent,
  }) {
    if (selected) return skillAccent?.dark ?? AppColors.textPrimary;
    return AppColors.textSecondary;
  }

  static FontWeight fontWeight({required bool selected, required bool done}) =>
      selected || done ? FontWeight.w600 : FontWeight.w500;

  static SkillColorSet? accentForSkill(String? skill) {
    switch (skill) {
      case 'reading':
        return AppSkillColors.reading;
      case 'listening':
        return AppSkillColors.listening;
      case 'writing':
        return AppSkillColors.writing;
      case 'speaking':
        return AppSkillColors.speaking;
      default:
        return null;
    }
  }
}

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
    final showCheck = done && !selected;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(radius),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: Curves.easeOut,
          height: height,
          padding: EdgeInsets.symmetric(horizontal: _isSub ? 7 : 8),
          decoration: BoxDecoration(
            color: ExamNavTokens.backgroundColor(),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: ExamNavTokens.borderColor(
                selected: selected,
                done: done,
                skillAccent: skillAccent,
              ),
              width: ExamNavTokens.borderWidth(selected: selected),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showCheck) ...[
                Icon(
                  Icons.check,
                  size: _isSub ? 10 : 11,
                  color: ExamNavTokens.checkColor(selected: false, skillAccent: skillAccent),
                ),
                SizedBox(width: _isSub ? 3 : 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: ExamNavTokens.fontWeight(selected: selected, done: done),
                  color: ExamNavTokens.textColor(
                    selected: selected,
                    done: done,
                    skillAccent: skillAccent,
                  ),
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

/// Picker for multiple CMS resources inside an embedded skill panel (reading, speaking, …).
class ExamResourcePickerChip extends StatelessWidget {
  const ExamResourcePickerChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.enabled = true,
    this.skillAccent,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;
  final SkillColorSet? skillAccent;

  static const double height = 36;
  static const double radius = 8;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(radius),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: Curves.easeOut,
          constraints: const BoxConstraints(maxWidth: 300),
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: ExamNavTokens.backgroundColor(),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: ExamNavTokens.borderColor(
                selected: selected,
                done: false,
                skillAccent: skillAccent,
              ),
              width: ExamNavTokens.borderWidth(selected: selected),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(
                  Icons.check,
                  size: 14,
                  color: ExamNavTokens.checkColor(selected: true, skillAccent: skillAccent),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: ExamSystemUi.embeddedCaptionStyle.copyWith(
                    fontWeight: ExamNavTokens.fontWeight(selected: selected, done: false),
                    color: ExamNavTokens.textColor(
                      selected: selected,
                      done: false,
                      skillAccent: skillAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Numbered navigation chip (grammar questions, listening sentences, …).
class ExamNavNumberChip extends StatelessWidget {
  const ExamNavNumberChip({
    super.key,
    required this.number,
    required this.selected,
    this.done = false,
    this.onTap,
    this.skillAccent,
    this.size = 32,
    this.radius = 6,
  });

  final int number;
  final bool selected;
  final bool done;
  final VoidCallback? onTap;
  final SkillColorSet? skillAccent;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bgColor = done ? AppColors.success : ExamNavTokens.backgroundColor();
    final borderColor = done
        ? AppColors.success
        : ExamNavTokens.borderColor(
            selected: selected,
            done: done,
            skillAccent: skillAccent,
          );
    final fgColor = done
        ? AppColors.onPrimary
        : ExamNavTokens.textColor(
            selected: selected,
            done: done,
            skillAccent: skillAccent,
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: Curves.easeOut,
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor,
              width: ExamNavTokens.borderWidth(selected: selected),
            ),
          ),
          child: Text(
            '$number',
            style: TextStyle(
              fontWeight: ExamNavTokens.fontWeight(selected: selected, done: done),
              fontSize: size <= 32 ? 11 : 13,
              color: fgColor,
              height: 1,
            ),
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

/// Nested sub-exercises under Listening — same neutral shell as other exam nav.
class ExamListeningSubNavGroup extends StatelessWidget {
  const ExamListeningSubNavGroup({
    super.key,
    required this.sectionTitle,
    required this.hint,
    required this.tags,
    this.skillAccent = AppSkillColors.listening,
  });

  final String sectionTitle;
  final String hint;
  final List<Widget> tags;
  final SkillColorSet skillAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: AppColors.outlineMuted),
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
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(color: AppColors.outlineMuted),
                ),
                child: Icon(Icons.headphones_outlined, size: 13, color: skillAccent.dark),
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
                        color: AppColors.textPrimary,
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
