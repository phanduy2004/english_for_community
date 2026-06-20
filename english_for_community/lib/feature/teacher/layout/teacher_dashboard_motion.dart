import 'dart:async';

import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Staggered entrance for teacher dashboard sections (`01` — motion ≤ 250ms feel).
abstract final class TeacherDashboardMotion {
  static const Duration enterDuration = AppMotion.enter;
  static const Duration staggerStep = AppMotion.staggerStep;
  static const Duration hoverDuration = AppMotion.web;

  /// Fade + slight rise, ordered by [sectionIndex].
  static Widget enter(Widget child, {required int sectionIndex}) {
    return Builder(
      builder: (context) {
        if (MediaQuery.disableAnimationsOf(context)) {
          return child;
        }
        final delay = staggerStep * sectionIndex;
        return child
            .animate()
            .fadeIn(duration: enterDuration, delay: delay, curve: Curves.easeOutCubic)
            .slideY(
              begin: 0.035,
              end: 0,
              duration: enterDuration,
              delay: delay,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }

  /// Hover affordance — decoration overlay by default; [useScale] only for classroom tiles.
  static Widget hoverLift(
    Widget child, {
    bool useScale = false,
    double scale = 1.012,
  }) {
    return _HoverLift(scale: scale, useScale: useScale, child: child);
  }

  /// Pulsing dot for live / urgent states.
  static Widget livePulse(Widget child, {required bool active}) {
    return Builder(
      builder: (context) {
        if (!active || MediaQuery.disableAnimationsOf(context)) return child;
        return child
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(0.92, 0.92),
              end: const Offset(1.08, 1.08),
              duration: AppMotion.pulse,
              curve: Curves.easeInOut,
            )
            .fadeIn(duration: AppMotion.fade);
      },
    );
  }
}

/// Tracks whether the user is actively scrolling — gates expensive hover effects (P0-R1).
class TeacherScrollActivity extends InheritedWidget {
  const TeacherScrollActivity({
    super.key,
    required this.isScrolling,
    required super.child,
  });

  final bool isScrolling;

  static bool isScrollingOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TeacherScrollActivity>()?.isScrolling ?? false;
  }

  @override
  bool updateShouldNotify(TeacherScrollActivity oldWidget) => isScrolling != oldWidget.isScrolling;
}

/// Listens for scroll notifications and debounces the scrolling flag (~120ms after stop).
class TeacherScrollActivityScope extends StatefulWidget {
  const TeacherScrollActivityScope({super.key, required this.child});

  final Widget child;

  @override
  State<TeacherScrollActivityScope> createState() => _TeacherScrollActivityScopeState();
}

class _TeacherScrollActivityScopeState extends State<TeacherScrollActivityScope> {
  bool _isScrolling = false;
  Timer? _debounce;

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollStartNotification || notification is ScrollUpdateNotification) {
      _debounce?.cancel();
      _setScrolling(true);
    } else if (notification is ScrollEndNotification) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 120), () {
        if (mounted) _setScrolling(false);
      });
    }
    return false;
  }

  void _setScrolling(bool value) {
    if (_isScrolling == value) return;
    setState(() => _isScrolling = value);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: TeacherScrollActivity(
        isScrolling: _isScrolling,
        child: widget.child,
      ),
    );
  }
}

class _HoverLift extends StatefulWidget {
  const _HoverLift({
    required this.child,
    required this.scale,
    required this.useScale,
  });

  final Widget child;
  final double scale;
  final bool useScale;

  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _hover = false;

  void _setHover(bool value) {
    if (TeacherScrollActivity.isScrollingOf(context)) return;
    if (_hover != value) setState(() => _hover = value);
  }

  @override
  Widget build(BuildContext context) {
    final scrolling = TeacherScrollActivity.isScrollingOf(context);
    final hover = _hover && !scrolling;

    if (widget.useScale) {
      return MouseRegion(
        onEnter: (_) => _setHover(true),
        onExit: (_) => _setHover(false),
        child: AnimatedScale(
          scale: hover ? widget.scale : 1,
          duration: AppMotion.effective(context, TeacherDashboardMotion.hoverDuration),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: AnimatedContainer(
        duration: AppMotion.effective(context, AppMotion.micro),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: hover ? AppColors.hoverOverlay : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sheet),
          border: Border.all(
            color: hover ? AppColors.outlineStrong : Colors.transparent,
            width: 1,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
