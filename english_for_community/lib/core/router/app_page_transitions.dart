import 'package:english_for_community/core/ui/motion/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Route transition styles for [GoRouter] `pageBuilder`.
enum AppRouteTransition {
  /// Sidebar / bottom-nav siblings — subtle fade + tiny vertical shift.
  shell,
  /// Deeper routes (push) — fade + light slide from the right.
  push,
}

/// Shared page transitions — Calm Momentum (`AppMotion`).
abstract final class AppPageTransitions {
  static Page<T> build<T>({
    required GoRouterState state,
    required Widget child,
    AppRouteTransition transition = AppRouteTransition.shell,
  }) {
    final duration = switch (transition) {
      AppRouteTransition.shell => AppMotion.normal,
      AppRouteTransition.push => AppMotion.slow,
    };

    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: AppMotion.fast,
      transitionsBuilder: (context, animation, secondaryAnimation, pageChild) {
        return switch (transition) {
          AppRouteTransition.shell => _shell(animation, pageChild),
          AppRouteTransition.push => _push(animation, pageChild),
        };
      },
    );
  }

  static Widget _shell(Animation<double> animation, Widget child) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.01), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }

  static Widget _push(Animation<double> animation, Widget child) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.03, 0), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}
