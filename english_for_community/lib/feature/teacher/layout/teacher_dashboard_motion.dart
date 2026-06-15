import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Staggered entrance for teacher dashboard sections (`01` — motion ≤ 250ms feel).
abstract final class TeacherDashboardMotion {
  static const Duration enterDuration = Duration(milliseconds: 420);
  static const Duration staggerStep = Duration(milliseconds: 55);
  static const Duration hoverDuration = Duration(milliseconds: 160);

  /// Fade + slight rise, ordered by [sectionIndex].
  static Widget enter(Widget child, {required int sectionIndex}) {
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
  }

  /// Subtle scale on hover (web).
  static Widget hoverLift(Widget child, {double scale = 1.012}) {
    return _HoverLift(scale: scale, child: child);
  }

  /// Pulsing dot for live / urgent states.
  static Widget livePulse(Widget child, {required bool active}) {
    if (!active) return child;
    return child
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1.08, 1.08),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
        )
        .fadeIn(duration: const Duration(milliseconds: 200));
  }
}

class _HoverLift extends StatefulWidget {
  const _HoverLift({required this.child, required this.scale});

  final Widget child;
  final double scale;

  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? widget.scale : 1,
        duration: TeacherDashboardMotion.hoverDuration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
