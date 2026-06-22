import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_fonts.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_dashboard_motion.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_widgets.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Work zone height — grading + live.
const double kTeacherDashboardWorkZoneHeight = 360;

/// Grading column gets more width on desktop (asymmetric split).
const int kTeacherDashboardGradingFlex = 3;
const int kTeacherDashboardLiveFlex = 2;

enum TeacherDashboardPanelAccent { none, primary, accent, live }

class TeacherDashboardMetric {
  const TeacherDashboardMetric({
    required this.label,
    required this.value,
    required this.onTap,
    this.emphasis = false,
    this.icon,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool emphasis;
  final IconData? icon;
}

class TeacherDashboardAttentionItem {
  const TeacherDashboardAttentionItem({
    required this.label,
    required this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;
}

/// Monochrome metric strip inside hero — amber only when [emphasis].
class TeacherDashboardMetricStrip extends StatelessWidget {
  const TeacherDashboardMetricStrip({super.key, required this.metrics});

  final List<TeacherDashboardMetric> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, c) {
        final stacked = c.maxWidth < 640;
        if (stacked) {
          return Column(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.outlineMuted),
                _MetricCell(metric: metrics[i], compact: true),
              ],
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                if (i > 0) const VerticalDivider(width: 1, color: AppColors.outlineMuted),
                Expanded(child: _MetricCell(metric: metrics[i])),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.metric, this.compact = false});

  final TeacherDashboardMetric metric;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final valueColor = metric.emphasis ? AppColors.accentDark : AppColors.textPrimary;

    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Row(
        children: [
          if (metric.icon != null) ...[
            Icon(metric.icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.s3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  metric.value,
                  style: TeacherWebUi.webKpiValue(context).copyWith(color: valueColor),
                ),
                const SizedBox(height: AppSpacing.s1),
                Text(metric.label, style: TeacherWebUi.webCaption(context)),
              ],
            ),
          ),
          Icon(
            Icons.north_east,
            size: 14,
            color: AppColors.textMuted.withValues(alpha: 0.65),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: metric.onTap,
        hoverColor: AppColors.primaryStrong,
        child: content,
      ),
    );
  }
}

/// Hero band — metrics + quick actions in one cohesive surface.
class TeacherDashboardHeroBand extends StatelessWidget {
  const TeacherDashboardHeroBand({
    super.key,
    required this.metrics,
    required this.quickActions,
    this.attention,
  });

  final List<TeacherDashboardMetric> metrics;
  final Widget quickActions;
  final Widget? attention;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TeacherDashboardMetricStrip(metrics: metrics),
          if (attention != null) ...[
            const Divider(height: 1, color: AppColors.outlineMuted),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s3, AppSpacing.s4, AppSpacing.s3),
              child: attention!,
            ),
          ],
          const Divider(height: 1, color: AppColors.outlineMuted),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s3, AppSpacing.s4, AppSpacing.s4),
            child: quickActions,
          ),
        ],
      ),
    );
  }
}

/// Compact alert rows — semantic tint, no amber pill buttons.
class TeacherDashboardAttentionStrip extends StatelessWidget {
  const TeacherDashboardAttentionStrip({
    super.key,
    required this.items,
    this.showGroupLabel = false,
    this.groupLabel = 'Needs attention',
  });

  final List<TeacherDashboardAttentionItem> items;
  final bool showGroupLabel;
  final String groupLabel;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showGroupLabel) ...[
          Text(
            groupLabel,
            style: TeacherWebUi.webCaption(context).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.s2),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.warningBg,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.outlineMuted),
                _AttentionRow(item: items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.item});

  final TeacherDashboardAttentionItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.color ?? AppColors.warning;
    final icon = item.icon ?? Icons.info_outline;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
          child: Row(
            children: [
              Container(
                width: AppSpacing.s6,
                height: AppSpacing.s6,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Text(
                  item.label,
                  style: TeacherWebUi.webBody(context).copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right, size: 14, color: AppColors.textMuted.withValues(alpha: 0.75)),
            ],
          ),
        ),
      ),
    );
  }
}

class TeacherDashboardQuickAction {
  const TeacherDashboardQuickAction({
    required this.label,
    required this.onTap,
    this.icon,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool primary;
}

class TeacherDashboardQuickActions extends StatelessWidget {
  const TeacherDashboardQuickActions({
    super.key,
    this.title,
    required this.actions,
  });

  final String? title;
  final List<TeacherDashboardQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null && title!.isNotEmpty) ...[
          Text(title!, style: TeacherWebUi.webCaption(context)),
          const SizedBox(height: AppSpacing.s2),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.s2),
                _QuickActionChip(action: actions[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({required this.action});

  final TeacherDashboardQuickAction action;

  @override
  Widget build(BuildContext context) {
    final icon = action.icon == null ? null : Icon(action.icon, size: 16);

    if (action.primary) {
      return FilledButton.icon(
        style: TeacherWebUi.compactFilledStyle(context),
        onPressed: action.onTap,
        icon: icon ?? const Icon(Icons.add, size: 16),
        label: Text(action.label),
      );
    }

    return OutlinedButton.icon(
      style: TeacherWebUi.compactOutlinedStyle(context).copyWith(
        backgroundColor: WidgetStateProperty.all(AppColors.surfaceSubtle),
      ),
      onPressed: action.onTap,
      icon: icon ?? const SizedBox(width: 16),
      label: Text(action.label),
    );
  }
}

class TeacherDashboardPanel extends StatelessWidget {
  const TeacherDashboardPanel({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    this.header,
    required this.child,
    this.height,
    this.fillHeight = false,
    this.expand = false,
    this.padding,
    this.accent = TeacherDashboardPanelAccent.none,
    this.liveActive = false,
  });

  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? header;
  final Widget child;
  final double? height;
  final bool fillHeight;
  /// Fill parent [Expanded] height without a fixed pixel height.
  final bool expand;
  final EdgeInsets? padding;
  final TeacherDashboardPanelAccent accent;
  final bool liveActive;

  double? get _resolvedHeight => height ?? (fillHeight ? kTeacherDashboardWorkZoneHeight : null);

  bool get _flexBody => expand || _resolvedHeight != null;

  Color? get _accentColor => switch (accent) {
        TeacherDashboardPanelAccent.primary => AppColors.primary,
        TeacherDashboardPanelAccent.accent => AppColors.accent,
        TeacherDashboardPanelAccent.live => AppColors.success,
        TeacherDashboardPanelAccent.none => null,
      };

  @override
  Widget build(BuildContext context) {
    final resolved = _resolvedHeight;
    final accentColor = _accentColor;

    final body = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null)
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.outlineMuted)),
            ),
            child: header,
          )
        else if (title != null)
          _PanelHeader(
            title: title!,
            subtitle: subtitle,
            trailing: trailing,
            liveActive: liveActive,
          ),
        if (_flexBody) Expanded(child: body) else body,
      ],
    );

    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        border: Border.all(color: AppColors.outline),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowHairline,
            blurRadius: 0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: accentColor != null
          ? DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sheet),
                border: Border(left: BorderSide(color: accentColor, width: 3)),
              ),
              child: column,
            )
          : column,
    );

    if (resolved != null) {
      return RepaintBoundary(
        child: SizedBox(
          height: resolved,
          width: double.infinity,
          child: decorated,
        ),
      );
    }
    if (expand) {
      return RepaintBoundary(
        child: SizedBox(width: double.infinity, child: decorated),
      );
    }
    return RepaintBoundary(child: decorated);
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    this.liveActive = false,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool liveActive;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(bottom: BorderSide(color: AppColors.outline)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s3, AppSpacing.s3, AppSpacing.s3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (liveActive) ...[
              TeacherDashboardMotion.livePulse(
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                active: true,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TeacherWebUi.webH3(context).copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: TeacherWebUi.metaMuted),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class TeacherDashboardSectionHeader extends StatelessWidget {
  const TeacherDashboardSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 36,
            margin: const EdgeInsets.only(right: AppSpacing.s3, top: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TeacherWebUi.webH3(context).copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: TeacherWebUi.metaMuted),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Work zone — asymmetric split, nested in subtle band.
class TeacherDashboardWorkZoneShell extends StatelessWidget {
  const TeacherDashboardWorkZoneShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        border: Border.all(color: AppColors.outlineMuted),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: child,
      ),
    );
  }
}

class TeacherDashboardWorkZone extends StatelessWidget {
  const TeacherDashboardWorkZone({
    super.key,
    required this.gradingPanel,
    required this.livePanel,
    this.breakpoint = 960,
  });

  final Widget gradingPanel;
  final Widget livePanel;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= breakpoint;
        if (wide) {
          return SizedBox(
            height: kTeacherDashboardWorkZoneHeight,
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: kTeacherDashboardGradingFlex, child: gradingPanel),
                const SizedBox(width: AppSpacing.s4),
                Expanded(flex: kTeacherDashboardLiveFlex, child: livePanel),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            gradingPanel,
            const SizedBox(height: AppSpacing.s4),
            livePanel,
          ],
        );
      },
    );
  }
}

class TeacherDashboardDividedList extends StatelessWidget {
  const TeacherDashboardDividedList({
    super.key,
    required this.children,
    this.scrollable = false,
  });

  final List<Widget> children;
  /// When true, uses [ListView] — required inside [Expanded] with bounded height.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    if (scrollable) {
      return ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: children.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.outlineMuted),
        itemBuilder: (_, i) => children[i],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.outlineMuted),
          children[i],
        ],
      ],
    );
  }
}

class TeacherDashboardClassroomTile extends StatelessWidget {
  const TeacherDashboardClassroomTile({
    super.key,
    required this.name,
    required this.meta,
    required this.onOpen,
    this.inviteCode,
    this.onCopyCode,
    this.index = 0,
  });

  final String name;
  final String meta;
  final VoidCallback onOpen;
  final String? inviteCode;
  final VoidCallback? onCopyCode;
  final int index;

  @override
  Widget build(BuildContext context) {
    final tile = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        hoverColor: AppColors.primaryStrong,
        child: Ink(
          decoration: TeacherWebUi.panelDecoration(),
          padding: const EdgeInsets.all(AppSpacing.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.outlineMuted),
                    ),
                    child: const Icon(Icons.groups_outlined, size: 20, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward, size: 16, color: AppColors.textMuted.withValues(alpha: 0.85)),
                ],
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(name, style: TeacherWebUi.listTitle(context), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(meta, style: TeacherWebUi.metaMuted),
              if (inviteCode != null && inviteCode!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s4),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(AppRadius.input),
                          border: Border.all(color: AppColors.outlineMuted),
                        ),
                        child: Text(
                          inviteCode!,
                          style: TeacherWebUi.webCaption(context).copyWith(
                            fontFamily: AppFonts.fontFamily,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    IconButton(
                      style: TeacherWebUi.compactHeaderIconStyle(),
                      onPressed: onCopyCode,
                      icon: const Icon(Icons.copy_outlined, size: 16),
                      tooltip: MaterialLocalizations.of(context).copyButtonLabel,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return TeacherDashboardMotion.hoverLift(tile, useScale: true);
  }
}

class TeacherDashboardFilterBar extends StatelessWidget {
  const TeacherDashboardFilterBar({
    super.key,
    required this.searchField,
    required this.filters,
    this.trailing,
  });

  final Widget searchField;
  final Widget filters;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s3, AppSpacing.s4, AppSpacing.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: searchField),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.s3),
                Expanded(child: trailing!),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          filters,
        ],
      ),
    );
  }
}

typedef TeacherDashboardInlineAlerts = TeacherDashboardAttentionStrip;
typedef TeacherDashboardSectionLabel = TeacherDashboardSectionHeader;
typedef TeacherDashboardClassroomRow = TeacherDashboardClassroomTile;

// --- Schedule-style inbox (single viewport, no page scroll) ---

enum TeacherDashboardInboxKind { grading, live, dueSoon, pendingJoin }

class TeacherDashboardInboxEntry {
  const TeacherDashboardInboxEntry({
    required this.kind,
    required this.title,
    required this.badge,
    required this.onTap,
    this.subtitle,
    this.classroomName,
    this.timestamp,
  });

  final TeacherDashboardInboxKind kind;
  final String title;
  final String badge;
  final VoidCallback onTap;
  /// Exam / assignment title, or secondary line for summary rows.
  final String? subtitle;
  final String? classroomName;
  /// Pre-formatted submitted time or deadline hint.
  final String? timestamp;
}

abstract final class TeacherDashboardInboxStyle {
  static Color color(TeacherDashboardInboxKind kind) => switch (kind) {
        TeacherDashboardInboxKind.grading => AppColors.warning,
        TeacherDashboardInboxKind.live => AppColors.info,
        TeacherDashboardInboxKind.dueSoon => AppColors.warning,
        TeacherDashboardInboxKind.pendingJoin => AppColors.success,
      };

  static Color bg(TeacherDashboardInboxKind kind) => switch (kind) {
        TeacherDashboardInboxKind.grading => AppColors.warningBg,
        TeacherDashboardInboxKind.live => AppColors.infoBg,
        TeacherDashboardInboxKind.dueSoon => AppColors.warningBg,
        TeacherDashboardInboxKind.pendingJoin => AppColors.successBg,
      };

  static IconData icon(TeacherDashboardInboxKind kind) => switch (kind) {
        TeacherDashboardInboxKind.grading => Icons.grade_outlined,
        TeacherDashboardInboxKind.live => Icons.sensors_outlined,
        TeacherDashboardInboxKind.dueSoon => Icons.schedule_outlined,
        TeacherDashboardInboxKind.pendingJoin => Icons.group_add_outlined,
      };
}

/// Legend bar — same pattern as [TeacherCalendarPage] `_CalendarLegendBar`.
class TeacherDashboardLegendBar extends StatelessWidget {
  const TeacherDashboardLegendBar({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: TeacherWebUi.panelDecoration(bg: AppColors.surfaceSubtle),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
      child: Wrap(
        spacing: AppSpacing.s4,
        runSpacing: AppSpacing.s2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            l10n.teacherDashboardWorkZoneTitle,
            style: TeacherWebUi.webCaption(context).copyWith(fontWeight: FontWeight.w600),
          ),
          _LegendDot(label: l10n.teacherDashboardSectionGrading, color: AppColors.warning),
          _LegendDot(label: l10n.teacherDashboardSectionLive, color: AppColors.info),
          _LegendDot(label: l10n.teacherDashboardDueSoon, color: AppColors.danger),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TeacherWebUi.webCaption(context)),
      ],
    );
  }
}

const double kTeacherDashboardInboxCardMinHeight = 76;

/// Inbox action card — white surface, left accent, 3-line hierarchy (v3 density).
class TeacherDashboardInboxCard extends StatelessWidget {
  const TeacherDashboardInboxCard({super.key, required this.entry});

  final TeacherDashboardInboxEntry entry;

  static TeacherStatusTone _toneForKind(TeacherDashboardInboxKind kind) => switch (kind) {
        TeacherDashboardInboxKind.grading => TeacherStatusTone.secondary,
        TeacherDashboardInboxKind.live => TeacherStatusTone.primary,
        TeacherDashboardInboxKind.dueSoon => TeacherStatusTone.danger,
        TeacherDashboardInboxKind.pendingJoin => TeacherStatusTone.success,
      };

  @override
  Widget build(BuildContext context) {
    final accent = TeacherDashboardInboxStyle.color(entry.kind);
    final icon = TeacherDashboardInboxStyle.icon(entry.kind);
    final contextLine = _contextLine(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: entry.onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        hoverColor: AppColors.primaryTint.withValues(alpha: 0.35),
        child: Ink(
          decoration: TeacherWebUi.panelDecoration(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kTeacherDashboardInboxCardMinHeight),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(AppRadius.card),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.s4,
                        AppSpacing.s3,
                        AppSpacing.s2,
                        AppSpacing.s3,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.chip),
                            ),
                            child: Icon(icon, size: 18, color: accent),
                          ),
                          const SizedBox(width: AppSpacing.s3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.title,
                                        style: TeacherWebUi.listTitle(context),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.s2),
                                    TeacherStatusPill(
                                      label: entry.badge,
                                      tone: _toneForKind(entry.kind),
                                    ),
                                  ],
                                ),
                                if (entry.subtitle != null && entry.subtitle!.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.s2),
                                  Text(
                                    entry.subtitle!,
                                    style: TeacherWebUi.webBody(context),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (contextLine != null) ...[
                                  const SizedBox(height: AppSpacing.s3),
                                  contextLine,
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: AppColors.textMuted.withValues(alpha: 0.75),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _contextLine(BuildContext context) {
    final hasClass = entry.classroomName != null && entry.classroomName!.isNotEmpty;
    final hasTime = entry.timestamp != null && entry.timestamp!.isNotEmpty;
    if (!hasClass && !hasTime) return null;

    return Row(
      children: [
        if (hasClass) ...[
          const Icon(Icons.school_outlined, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              entry.classroomName!,
              style: TeacherWebUi.metaMuted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        if (hasClass && hasTime) ...[
          Text(' · ', style: TeacherWebUi.metaMuted),
        ],
        if (hasTime) ...[
          const Icon(Icons.schedule_outlined, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              entry.timestamp!,
              style: TeacherWebUi.metaMuted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

/// Inbox list — fixed rows, no scroll; overflow → view all.
class TeacherDashboardInboxPanel extends StatelessWidget {
  const TeacherDashboardInboxPanel({
    super.key,
    required this.sectionTitle,
    required this.entries,
    required this.maxVisible,
    this.emptyMessage,
    this.onViewAll,
    this.viewAllLabel,
    this.loading = false,
  });

  final String sectionTitle;
  final List<TeacherDashboardInboxEntry> entries;
  final int maxVisible;
  final String? emptyMessage;
  final VoidCallback? onViewAll;
  final String? viewAllLabel;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final visible = entries.take(maxVisible).toList();
    final hidden = entries.length - visible.length;

    return DecoratedBox(
      decoration: TeacherWebUi.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s3, AppSpacing.s4, AppSpacing.s2),
            child: Text(sectionTitle, style: TeacherWebUi.sectionTitle(context)),
          ),
          const Divider(height: 1, color: AppColors.outlineMuted),
          Expanded(
            child: loading
                ? const Center(child: AppLoadingIndicator.inline(color: AppColors.primary))
                : entries.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.s5),
                          child: Text(
                            emptyMessage ?? '',
                            style: TeacherWebUi.metaMuted,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(AppSpacing.s3),
                        child: Column(
                          children: [
                            for (var i = 0; i < visible.length; i++) ...[
                              if (i > 0) const SizedBox(height: AppSpacing.s2),
                              RepaintBoundary(
                                child: TeacherDashboardInboxCard(entry: visible[i]),
                              ),
                            ],
                            if (hidden > 0 && onViewAll != null) ...[
                              const SizedBox(height: AppSpacing.s2),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  style: TeacherWebUi.linkActionStyle(context),
                                  onPressed: onViewAll,
                                  child: Text(viewAllLabel ?? '+$hidden'),
                                ),
                              ),
                            ],
                            const Spacer(),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

/// Bottom shortcut strip — classes + nav (no scroll).
class TeacherDashboardNavFooter extends StatelessWidget {
  const TeacherDashboardNavFooter({
    super.key,
    required this.classCount,
    required this.classLabel,
    required this.onOpenClasses,
    required this.onOpenSchedule,
    required this.onOpenExamBank,
    required this.onCreateClass,
    required this.scheduleLabel,
    required this.examBankLabel,
    required this.newClassLabel,
  });

  final int classCount;
  final String classLabel;
  final VoidCallback onOpenClasses;
  final VoidCallback onOpenSchedule;
  final VoidCallback onOpenExamBank;
  final VoidCallback onCreateClass;
  final String scheduleLabel;
  final String examBankLabel;
  final String newClassLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: TeacherWebUi.panelDecoration(bg: AppColors.surfaceSubtle),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
      child: Row(
        children: [
          InkWell(
            onTap: onOpenClasses,
            borderRadius: BorderRadius.circular(AppRadius.input),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.groups_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '$classCount $classLabel',
                    style: TeacherWebUi.webBody(context).copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          TextButton(
            style: TeacherWebUi.linkActionStyle(context),
            onPressed: onOpenSchedule,
            child: Text(scheduleLabel),
          ),
          TextButton(
            style: TeacherWebUi.linkActionStyle(context),
            onPressed: onOpenExamBank,
            child: Text(examBankLabel),
          ),
          const SizedBox(width: AppSpacing.s2),
          OutlinedButton(
            style: TeacherWebUi.compactOutlinedStyle(context),
            onPressed: onCreateClass,
            child: Text(newClassLabel),
          ),
        ],
      ),
    );
  }
}
