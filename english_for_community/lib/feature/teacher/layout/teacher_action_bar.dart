import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_mobile_ui.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:flutter/material.dart';

/// Body-level actions: intrinsic width in a [Wrap], never full-bleed.
///
/// Prefer [TeacherPageScaffold.actions] (top-right toolbar) for primary/destructive
/// page actions — same pattern as dashboard "New exam".
class TeacherInlineActions extends StatelessWidget {
  const TeacherInlineActions({
    super.key,
    required this.children,
    this.alignment = Alignment.centerLeft,
    this.spacing = 8,
    this.runSpacing = 8,
  });

  final List<Widget> children;
  final Alignment alignment;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final mobile = TeacherMobileUi.isMobileWorkspace(context);
    if (mobile && children.length == 1) {
      return Align(
        alignment: alignment,
        child: SizedBox(width: double.infinity, child: children.first),
      );
    }
    return Align(
      alignment: alignment,
      child: Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
  }
}

/// Sticky bottom bar for primary mobile CTAs (`04-mobile-components` §4.3).
class TeacherMobileBottomActionBar extends StatelessWidget {
  const TeacherMobileBottomActionBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Material(
      elevation: 6,
      color: AppColors.surfaceCard,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.outlineMuted)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact filled button — content width (teacher workspace).
class TeacherFilledButton extends StatelessWidget {
  const TeacherFilledButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final mobile = TeacherMobileUi.isMobileWorkspace(context);
    final style = mobile
        ? TeacherMobileUi.mobileFilledStyle(context)
        : TeacherWebUi.compactFilledStyle(context);
    final iconSize = mobile ? 18.0 : 16.0;
    if (icon != null) {
      return FilledButton.icon(
        style: style,
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
        label: Text(label),
      );
    }
    return FilledButton(style: style, onPressed: onPressed, child: Text(label));
  }
}

/// Compact outlined button — content width.
class TeacherOutlinedButton extends StatelessWidget {
  const TeacherOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final mobile = TeacherMobileUi.isMobileWorkspace(context);
    final style = mobile
        ? TeacherMobileUi.mobileOutlinedStyle(context)
        : TeacherWebUi.compactOutlinedStyle(context);
    final iconSize = mobile ? 18.0 : 16.0;
    if (icon != null) {
      return OutlinedButton.icon(
        style: style,
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
        label: Text(label),
      );
    }
    return OutlinedButton(style: style, onPressed: onPressed, child: Text(label));
  }
}

/// Destructive outlined action (end session, archive, etc.).
class TeacherDangerOutlinedButton extends StatelessWidget {
  const TeacherDangerOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final mobile = TeacherMobileUi.isMobileWorkspace(context);
    final style = mobile
        ? TeacherMobileUi.mobileDangerOutlinedStyle(context)
        : TeacherWebUi.compactDangerOutlinedStyle(context);
    final iconSize = mobile ? 18.0 : 16.0;
    if (icon != null) {
      return OutlinedButton.icon(
        style: style,
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
        label: Text(label),
      );
    }
    return OutlinedButton(style: style, onPressed: onPressed, child: Text(label));
  }
}

/// Centered retry for error/empty states (not full width).
class TeacherRetryButton extends StatelessWidget {
  const TeacherRetryButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TeacherFilledButton(label: context.l10n.retry, onPressed: onPressed);
  }
}
