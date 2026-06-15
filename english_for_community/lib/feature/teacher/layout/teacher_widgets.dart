import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:flutter/material.dart';

class TeacherKpiCard extends StatelessWidget {
  const TeacherKpiCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Icon(icon, color: accent, size: 16),
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: TeacherWebUi.webKpiValue(context)),
                const SizedBox(height: 2),
                Text(label, style: TeacherWebUi.webCaption(context), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          decoration: TeacherWebUi.cardDecoration(),
          child: child,
        ),
      ),
    );
  }
}

class TeacherEmptyCard extends StatelessWidget {
  const TeacherEmptyCard({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s4),
      decoration: TeacherWebUi.cardDecoration(),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.s5),
          Expanded(child: Text(message, style: TeacherWebUi.webBody(context))),
        ],
      ),
    );
  }
}

class TeacherStatusPill extends StatelessWidget {
  const TeacherStatusPill({
    super.key,
    required this.label,
    this.tone = TeacherStatusTone.neutral,
  });

  final String label;
  final TeacherStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      TeacherStatusTone.success => (AppColors.successBg, AppColors.success),
      TeacherStatusTone.warning => (AppColors.warningBg, AppColors.warning),
      TeacherStatusTone.danger => (AppColors.dangerBg, AppColors.danger),
      TeacherStatusTone.primary => (AppColors.primaryTint, AppColors.primaryDark),
      TeacherStatusTone.neutral => (AppColors.outlineMuted, AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
              height: 1.2,
            ),
      ),
    );
  }
}

enum TeacherStatusTone { neutral, primary, success, warning, danger }

class TeacherFilterChip extends StatelessWidget {
  const TeacherFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      selectedColor: AppColors.primaryTint,
      labelStyle: TextStyle(
        fontSize: 12,
        color: selected ? AppColors.primaryDark : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      side: BorderSide(color: AppColors.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
    );
  }
}

/// One option for [TeacherSegmentTileRow] — replaces Material `SegmentedButton` in teacher web UI.
class TeacherSegmentOption<T> {
  const TeacherSegmentOption({
    required this.value,
    required this.label,
    this.icon,
    this.count,
    this.fg,
    this.bg,
    this.border,
  });

  final T value;
  final String label;
  final IconData? icon;
  final int? count;
  final Color? fg;
  final Color? bg;
  final Color? border;
}

/// Two- or three-way segment control as equal-width coloured tiles (`docs/ui-ux-system/07` §7.4).
class TeacherSegmentTileRow<T> extends StatelessWidget {
  const TeacherSegmentTileRow({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.options,
    this.spacing = 10,
  });

  final T selected;
  final ValueChanged<T> onChanged;
  final List<TeacherSegmentOption<T>> options;
  final double spacing;

  static final _defaultPalettes = [
    (fg: AppColors.primary, bg: AppColors.primaryTint, border: AppColors.primary),
    (fg: AppColors.info, bg: AppColors.infoBg, border: AppColors.info),
    (fg: AppColors.accentDark, bg: AppColors.warningBg, border: AppColors.accent),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(child: _tile(context, options[i], i)),
        ],
      ],
    );
  }

  Widget _tile(BuildContext context, TeacherSegmentOption<T> opt, int index) {
    final isSelected = selected == opt.value;
    final palette = opt.fg != null
        ? (fg: opt.fg!, bg: opt.bg ?? AppColors.surfaceCard, border: opt.border ?? AppColors.outline)
        : _defaultPalettes[index.clamp(0, _defaultPalettes.length - 1)];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(opt.value),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? palette.bg : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? palette.border : AppColors.outline,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              if (opt.icon != null) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? palette.fg.withValues(alpha: 0.12)
                        : AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    opt.icon,
                    size: 15,
                    color: isSelected ? palette.fg : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  opt.label,
                  style: TeacherWebUi.webLabel(context).copyWith(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? palette.fg : AppColors.textPrimary,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (opt.count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? palette.fg.withValues(alpha: 0.12)
                        : AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected
                          ? palette.border.withValues(alpha: 0.5)
                          : AppColors.outlineMuted,
                    ),
                  ),
                  child: Text(
                    '${opt.count}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? palette.fg : AppColors.textSecondary,
                      height: 1.1,
                    ),
                  ),
                ),
              ] else if (isSelected)
                Icon(Icons.check_circle_rounded, size: 16, color: palette.fg),
            ],
          ),
        ),
      ),
    );
  }
}

class TeacherListRow extends StatelessWidget {
  const TeacherListRow({
    super.key,
    this.leading,
    this.title = '',
    this.titleWidget,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.dense = false,
  });

  final Widget? leading;
  final String title;
  final Widget? titleWidget;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  /// Flat row inside a panel — no per-row card chrome.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        if (leading != null && !dense) ...[
          leading!,
          const SizedBox(width: AppSpacing.s5),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleWidget ??
                  Text(title, style: TeacherWebUi.listTitle(context), maxLines: 2, overflow: TextOverflow.ellipsis),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                SizedBox(height: dense ? 2 : 3),
                Text(subtitle!, style: TeacherWebUi.metaMuted, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );

    if (dense) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: AppColors.surfaceSubtle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: 10),
            child: content,
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          decoration: TeacherWebUi.cardDecoration(),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: content,
        ),
      ),
    );
  }
}

class TeacherIconBadge extends StatelessWidget {
  const TeacherIconBadge({super.key, required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }
}

/// Compact KPI pill for live exam monitor summary row.
class TeacherLiveMonitorMetricChip extends StatelessWidget {
  const TeacherLiveMonitorMetricChip({
    super.key,
    required this.value,
    required this.label,
    required this.accent,
  });

  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: accent,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Skill / exam part tab — matches student integrated exam runner chips.
class TeacherExamPartTabChip extends StatelessWidget {
  const TeacherExamPartTabChip({
    super.key,
    required this.label,
    required this.selected,
    this.done = false,
    this.studentHere = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool done;
  final bool studentHere;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.primary
        : studentHere
            ? AppColors.info.withValues(alpha: 0.55)
            : AppColors.outlineMuted;
    final bg = done
        ? AppColors.primary.withValues(alpha: 0.12)
        : selected
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.surfaceCard;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 0.75),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (studentHere && !selected) ...[
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.info,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              if (done)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.check, size: 14, color: AppColors.primary),
                ),
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 12,
                  color: selected || done ? AppColors.primaryDark : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Live mirror status banner for teacher watching a student exam.
class TeacherLiveMirrorStatusBanner extends StatelessWidget {
  const TeacherLiveMirrorStatusBanner({
    super.key,
    required this.message,
    this.followingStudent = true,
    this.followActionLabel,
    this.onFollowStudent,
  });

  final String message;
  final bool followingStudent;
  final String? followActionLabel;
  final VoidCallback? onFollowStudent;

  @override
  Widget build(BuildContext context) {
    final accent = followingStudent ? AppColors.primary : AppColors.info;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              boxShadow: followingStudent
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.45),
                        blurRadius: 4,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: followingStudent ? AppColors.primaryDark : AppColors.info,
                height: 1.25,
              ),
            ),
          ),
          if (!followingStudent && onFollowStudent != null && followActionLabel != null)
            TextButton(
              onPressed: onFollowStudent,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(followActionLabel!, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

/// Visual legend for graded question number strip.
class TeacherQuestionStatusLegend extends StatelessWidget {
  const TeacherQuestionStatusLegend({
    super.key,
    required this.correctLabel,
    required this.wrongLabel,
    required this.unansweredLabel,
  });

  final String correctLabel;
  final String wrongLabel;
  final String unansweredLabel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _LegendItem(color: const Color(0xFF43A047), label: correctLabel),
        _LegendItem(color: AppColors.chartTrend, label: wrongLabel),
        _LegendItem(color: AppColors.outlineMuted, label: unansweredLabel),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: color == AppColors.outlineMuted ? 0.35 : 0.2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color, width: 1),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
