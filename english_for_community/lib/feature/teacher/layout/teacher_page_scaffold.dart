import 'dart:math' as math;

import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_mobile_ui.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Breadcrumb segment for teacher page header.
class TeacherBreadcrumb {
  const TeacherBreadcrumb({required this.label, this.location});

  final String label;
  final String? location;
}

/// Standard teacher content area below the shell top bar.
class TeacherPageScaffold extends StatelessWidget {
  const TeacherPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.breadcrumbs = const [],
    this.actions = const [],
    this.maxWidth = TeacherWebUi.contentMaxDashboard,
    this.scrollable = true,
    this.padding,
    this.showBack = false,
    this.bottomActions,
  });

  final String title;
  final String? subtitle;
  final List<TeacherBreadcrumb> breadcrumbs;
  final List<Widget> actions;
  final Widget body;
  final double maxWidth;
  final bool scrollable;
  final EdgeInsets? padding;
  final bool showBack;
  /// Mobile: sticky bottom CTAs (session start/end, wizard submit, etc.).
  final List<Widget>? bottomActions;

  @override
  Widget build(BuildContext context) {
    final mobile = TeacherMobileUi.isMobileWorkspace(context);
    final pad = padding ?? (mobile ? TeacherMobileUi.pagePadding : TeacherWebUi.pagePadding);
    final useBottomBar = mobile && bottomActions != null && bottomActions!.isNotEmpty;
    final header = _TeacherPageHeader(
      title: title,
      subtitle: subtitle,
      breadcrumbs: breadcrumbs,
      actions: useBottomBar ? const [] : actions,
      showBack: showBack,
      mobile: mobile,
    );

    // scrollable: true  → Column/Wrap content in a single scroll view.
    // scrollable: false → body must be its own scrollable (ListView, etc.) inside Expanded.
    // Never nest ListView inside SingleChildScrollView — breaks hit-testing (RefreshIndicator Stack).
    final Widget expandedChild;
    if (scrollable) {
      expandedChild = SingleChildScrollView(
        padding: pad,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: body,
          ),
        ),
      );
    } else {
      expandedChild = Padding(
        padding: pad,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: body,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Expanded(child: expandedChild),
        if (useBottomBar)
          TeacherMobileBottomActionBar(children: bottomActions!),
      ],
    );
  }
}

class _TeacherPageHeader extends StatelessWidget {
  const _TeacherPageHeader({
    required this.title,
    this.subtitle,
    required this.breadcrumbs,
    required this.actions,
    required this.showBack,
    required this.mobile,
  });

  final String title;
  final String? subtitle;
  final List<TeacherBreadcrumb> breadcrumbs;
  final List<Widget> actions;
  final bool showBack;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: mobile ? TeacherMobileUi.pageHeaderPadding : TeacherWebUi.pageHeaderPadding,
      constraints: BoxConstraints(minHeight: mobile ? 48 : TeacherWebUi.pageHeaderMinHeight),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(bottom: BorderSide(color: AppColors.outline, width: 1)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final compact = mobile || c.maxWidth < 800;
          final crumbRow = breadcrumbs.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _BreadcrumbTrail(items: breadcrumbs),
                )
              : null;

          final actionBar = actions.isNotEmpty
              ? Wrap(
                  spacing: AppSpacing.s3,
                  runSpacing: AppSpacing.s5,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: actions,
                )
              : null;

          final titleRow = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showBack)
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 2),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, size: 20),
                    color: AppColors.textSecondary,
                    onPressed: () => context.pop(),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (crumbRow != null) crumbRow,
                    Text(
                      title,
                      style: mobile
                          ? TeacherMobileUi.pageTitle(context)
                          : TeacherWebUi.webPageTitle(context),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: mobile
                            ? TeacherMobileUi.caption(context)
                            : TeacherWebUi.webCaption(context),
                      ),
                    ],
                  ],
                ),
              ),
              if (!compact && actionBar != null) ...[
                const SizedBox(width: AppSpacing.s5),
                actionBar,
              ],
            ],
          );

          if (compact && actionBar != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleRow,
                const SizedBox(height: AppSpacing.s4),
                Align(alignment: Alignment.centerRight, child: actionBar),
              ],
            );
          }
          return titleRow;
        },
      ),
    );
  }
}

class _BreadcrumbTrail extends StatelessWidget {
  const _BreadcrumbTrail({required this.items});

  final List<TeacherBreadcrumb> items;

  @override
  Widget build(BuildContext context) {
    final style = (TeacherMobileUi.isMobileWorkspace(context)
            ? TeacherMobileUi.caption(context)
            : TeacherWebUi.webBreadcrumb(context))
        .copyWith(
          fontSize: TeacherMobileUi.isMobileWorkspace(context) ? 12 : null,
          color: AppColors.textPrimary,
        );
    final activeStyle = style.copyWith(fontWeight: FontWeight.w600);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.s2,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
              child: Icon(Icons.chevron_right, size: 14, color: AppColors.textMuted),
            ),
          _Crumb(
            item: items[i],
            style: i == items.length - 1 ? activeStyle : style,
            isLast: i == items.length - 1,
          ),
        ],
      ],
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({required this.item, required this.style, required this.isLast});

  final TeacherBreadcrumb item;
  final TextStyle style;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final text = Text(item.label, style: style);
    if (isLast || item.location == null) return text;
    return InkWell(
      onTap: () => context.go(item.location!),
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1), child: text),
    );
  }
}

/// Responsive grid helper for dashboard-style layouts.
class TeacherResponsiveColumns extends StatelessWidget {
  const TeacherResponsiveColumns({
    super.key,
    required this.left,
    required this.right,
    this.breakpoint = 900,
    this.gap = AppSpacing.s5,
  });

  final Widget left;
  final Widget right;
  final double breakpoint;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= breakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              SizedBox(width: gap),
              Expanded(child: right),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            left,
            SizedBox(height: gap),
            right,
          ],
        );
      },
    );
  }
}

/// KPI grid: 4 columns on wide, 2 on medium.
class TeacherKpiGrid extends StatelessWidget {
  const TeacherKpiGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 1024 ? 4 : (c.maxWidth >= 560 ? 2 : 1);
        final gap = AppSpacing.s4;
        final itemW = cols == 1 ? c.maxWidth : (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children.map((w) => SizedBox(width: itemW, child: w)).toList(),
        );
      },
    );
  }
}

/// Card grid for classrooms (min 280px).
class TeacherCardGrid extends StatelessWidget {
  const TeacherCardGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const minTile = 280.0;
        final gap = AppSpacing.s5;
        final cols = math.max(1, ((c.maxWidth + gap) / (minTile + gap)).floor());
        final itemW = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children.map((w) => SizedBox(width: itemW, child: w)).toList(),
        );
      },
    );
  }
}
