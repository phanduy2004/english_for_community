import 'package:flutter/material.dart';

abstract final class AppMotion {
  /// Hover / press micro-feedback. `docs/ui-ux-system/18` §5.10.
  static const Duration micro = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 180);
  static const Duration web = Duration(milliseconds: 160);
  static const Duration page = Duration(milliseconds: 220);
  static const Duration celebrate = Duration(milliseconds: 380);

  /// Bước stagger khi list/card vào màn.
  static const Duration staggerStep = Duration(milliseconds: 55);

  /// Nhịp pulse chấm live.
  static const Duration pulse = Duration(milliseconds: 900);

  /// Reduce-motion: thay slide bằng fade ngắn (`10-accessibility` §6).
  static const Duration reducedFade = Duration(milliseconds: 80);

  /// Segmented / choice tile transition.
  static const Duration segment = Duration(milliseconds: 150);

  /// Panel expand/collapse micro animation.
  static const Duration panel = Duration(milliseconds: 140);

  /// Fade-in companion (live pulse, overlays).
  static const Duration fade = Duration(milliseconds: 200);

  /// Search / lobby debounce.
  static const Duration debounce = Duration(milliseconds: 350);

  /// Tooltip wait before show.
  static const Duration tooltipWait = Duration(milliseconds: 400);

  /// Dashboard section enter.
  static const Duration enter = Duration(milliseconds: 420);

  /// Editor autosave debounce after last keystroke (`18` §5.7).
  static const Duration autosave = Duration(milliseconds: 1500);

  /// Saved indicator fade-out.
  static const Duration savedFade = Duration(milliseconds: 800);

  /// Respect `MediaQuery.disableAnimationsOf` (`10-accessibility` §6).
  static Duration effective(BuildContext context, Duration duration) {
    return MediaQuery.disableAnimationsOf(context) ? reducedFade : duration;
  }
}
