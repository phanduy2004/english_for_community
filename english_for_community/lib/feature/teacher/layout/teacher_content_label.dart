import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:flutter/material.dart';

/// Parses optional bracket tags; strips `[SEED:…]` from display (legacy seed data).
class ParsedTaggedLabel {
  const ParsedTaggedLabel({
    required this.raw,
    this.tag,
    required this.title,
    this.subtitle,
  });

  final String raw;
  final String? tag;
  final String title;
  final String? subtitle;

  bool get hasTag => tag != null && tag!.isNotEmpty;

  static ParsedTaggedLabel parse(String raw) {
    var rest = raw.trim();
    String? tag;
    final tagMatch = RegExp(r'^\[([^\]]+)\]\s*').firstMatch(rest);
    if (tagMatch != null) {
      tag = tagMatch.group(1)?.trim();
      rest = rest.substring(tagMatch.end).trim();
      final tagKey = tag?.toUpperCase() ?? '';
      if (tagKey.startsWith('SEED:')) {
        tag = null;
      }
    }

    String title = rest;
    String? subtitle;
    final dash = rest.indexOf(' — ');
    if (dash >= 0) {
      title = rest.substring(0, dash).trim();
      final sub = rest.substring(dash + 3).trim();
      if (sub.isNotEmpty) subtitle = sub;
    }

    if (title.isEmpty) title = raw.trim();

    return ParsedTaggedLabel(raw: raw, tag: tag, title: title, subtitle: subtitle);
  }
}

/// Semantic colours for known seed / system tags.
({Color fg, Color bg, Color border}) tagColorsFor(String tag) {
  final key = tag.toUpperCase();
  if (key.contains('HOANGDONG')) {
    return (fg: AppColors.accentDark, bg: AppColors.warningBg, border: AppColors.accent.withValues(alpha: 0.45));
  }
  if (key.contains('STUDENTAPP')) {
    return (fg: AppColors.info, bg: AppColors.infoBg, border: AppColors.info.withValues(alpha: 0.35));
  }
  if (key.startsWith('SEED:')) {
    return (fg: AppColors.textSecondary, bg: AppColors.surfaceSubtle, border: AppColors.outlineStrong);
  }
  return (fg: AppColors.textSecondary, bg: AppColors.surfaceSubtle, border: AppColors.outline);
}

/// Compact pill for `[SEED:…]` tags — not raw bracket text.
class TeacherSeedTagChip extends StatelessWidget {
  const TeacherSeedTagChip({
    super.key,
    required this.tag,
    this.compact = false,
  });

  final String tag;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = tagColorsFor(tag);
    final label = tag.startsWith('SEED:') ? tag.substring(5) : tag;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 9.5 : 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          height: 1.1,
          color: c.fg,
        ),
      ),
    );
  }
}

/// Title row: optional tag chip + main title + optional subtitle.
class TeacherTaggedTitleRow extends StatelessWidget {
  const TeacherTaggedTitleRow({
    super.key,
    required this.label,
    this.titleStyle,
    this.subtitleStyle,
    this.compact = false,
    this.maxLines = 2,
  });

  final ParsedTaggedLabel label;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final bool compact;
  final int maxLines;

  factory TeacherTaggedTitleRow.fromRaw(
    String raw, {
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
    bool compact = false,
    int maxLines = 2,
  }) =>
      TeacherTaggedTitleRow(
        label: ParsedTaggedLabel.parse(raw),
        titleStyle: titleStyle,
        subtitleStyle: subtitleStyle,
        compact: compact,
        maxLines: maxLines,
      );

  @override
  Widget build(BuildContext context) {
    final title = titleStyle ??
        TeacherWebUi.webBody(context).copyWith(
          fontSize: compact ? 13 : 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.25,
        );
    final sub = subtitleStyle ??
        TeacherWebUi.metaMuted.copyWith(fontSize: compact ? 11 : 12, height: 1.3);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.hasTag) ...[
          Padding(
            padding: EdgeInsets.only(top: compact ? 2 : 3),
            child: TeacherSeedTagChip(tag: label.tag!, compact: compact),
          ),
          SizedBox(width: compact ? 8 : 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.title, style: title, maxLines: maxLines, overflow: TextOverflow.ellipsis),
              if (label.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(label.subtitle!, style: sub, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Selectable classroom row for assign / filter dialogs.
class TeacherClassroomSelectTile extends StatelessWidget {
  const TeacherClassroomSelectTile({
    super.key,
    required this.name,
    required this.selected,
    required this.onTap,
    this.memberCount,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;
  final int? memberCount;

  @override
  Widget build(BuildContext context) {
    final parsed = ParsedTaggedLabel.parse(name);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: TeacherWebUi.choiceTileDecoration(selected: selected),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: TeacherWebUi.choiceTileIconBoxColor(selected: selected),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.class_outlined,
                  size: 18,
                  color: TeacherWebUi.choiceTileIconColor(selected: selected),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: TeacherTaggedTitleRow(label: parsed, compact: true)),
              if (selected)
                const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary)
              else
                Icon(Icons.circle_outlined, size: 18, color: AppColors.outlineStrong.withValues(alpha: 0.8)),
            ],
          ),
        ),
      ),
    );
  }
}
