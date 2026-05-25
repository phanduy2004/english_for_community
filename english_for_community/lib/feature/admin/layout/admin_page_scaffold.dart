import 'dart:math' as math;

import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminBreadcrumb {
  const AdminBreadcrumb({required this.label, this.location});

  final String label;
  final String? location;
}

/// Standard admin content area below the shell top bar.
class AdminPageScaffold extends StatelessWidget {
  const AdminPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.breadcrumbs = const [],
    this.actions = const [],
    this.maxWidth = AdminWebUi.contentMaxDashboard,
    this.scrollable = true,
    this.padding,
    this.showBack = false,
    this.headerBottom,
  });

  final String title;
  final String? subtitle;
  final List<AdminBreadcrumb> breadcrumbs;
  final List<Widget> actions;
  final Widget body;
  final double maxWidth;
  final bool scrollable;
  final EdgeInsets? padding;
  final bool showBack;
  final Widget? headerBottom;

  @override
  Widget build(BuildContext context) {
    final pad = padding ?? AdminWebUi.pagePadding;
    final header = _AdminPageHeader(
      title: title,
      subtitle: subtitle,
      breadcrumbs: breadcrumbs,
      actions: actions,
      showBack: showBack,
      bottom: headerBottom,
    );

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
      ],
    );
  }
}

class _AdminPageHeader extends StatelessWidget {
  const _AdminPageHeader({
    required this.title,
    this.subtitle,
    required this.breadcrumbs,
    required this.actions,
    required this.showBack,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final List<AdminBreadcrumb> breadcrumbs;
  final List<Widget> actions;
  final bool showBack;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AdminWebUi.pageHeaderPadding,
      constraints: const BoxConstraints(minHeight: AdminWebUi.pageHeaderMinHeight),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(bottom: BorderSide(color: AppColors.outline, width: 1)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final compact = c.maxWidth < 640;
          final crumbRow = breadcrumbs.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _BreadcrumbTrail(items: breadcrumbs),
                )
              : null;

          final titleRow = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    Text(title, style: AdminWebUi.webPageTitle(context)),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: AdminWebUi.webCaption(context)),
                    ],
                  ],
                ),
              ),
              if (!compact && actions.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.s5),
                Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
            ],
          );

          final children = <Widget>[titleRow];
          if (compact && actions.isNotEmpty) {
            children.add(const SizedBox(height: AppSpacing.s4));
            children.add(Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: actions));
          }
          if (bottom != null) {
            children.add(const SizedBox(height: AppSpacing.s4));
            children.add(bottom!);
          }

          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
        },
      ),
    );
  }
}

class _BreadcrumbTrail extends StatelessWidget {
  const _BreadcrumbTrail({required this.items});

  final List<AdminBreadcrumb> items;

  @override
  Widget build(BuildContext context) {
    final style = AdminWebUi.webBreadcrumb(context);
    final activeStyle = style.copyWith(color: AppColors.textPrimary);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
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

  final AdminBreadcrumb item;
  final TextStyle style;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final text = Text(item.label, style: style);
    if (isLast || item.location == null) return text;
    return InkWell(
      onTap: () => context.go(item.location!),
      borderRadius: BorderRadius.circular(4),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1), child: text),
    );
  }
}

class AdminKpiGrid extends StatelessWidget {
  const AdminKpiGrid({super.key, required this.children});

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

class AdminCardGrid extends StatelessWidget {
  const AdminCardGrid({super.key, required this.children});

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

class AdminSegmentedControl<T> extends StatelessWidget {
  const AdminSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelected,
    this.labelBuilder,
  });

  final List<T> segments;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: segments.map((seg) {
          final active = seg == selected;
          return Material(
            color: active ? AppColors.surfaceCard : Colors.transparent,
            elevation: active ? 1 : 0,
            shadowColor: const Color(0x0A000000),
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: () => onSelected(seg),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Text(
                  labelBuilder?.call(seg) ?? seg.toString(),
                  style: AdminWebUi.webBody(context).copyWith(
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
