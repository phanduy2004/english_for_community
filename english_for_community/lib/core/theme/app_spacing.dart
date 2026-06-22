/// Spacing scale — `docs/ui-ux-system/02-design-tokens.md`.
abstract final class AppSpacing {
  static const double s1 = 2;
  static const double s2 = 4;
  static const double s3 = 8;
  static const double s4 = 12;
  static const double s5 = 16;
  static const double s6 = 20;
  static const double s7 = 24;
  static const double s8 = 32;
  static const double s9 = 40;
  static const double s10 = 56;
  static const double s11 = 80;
}

abstract final class AppRadius {
  /// Rung nhỏ — progress bar, skeleton mảnh, chip mini (gồm 2–4px cũ).
  static const double xs = 4;
  static const double chip = 6;
  static const double input = 8;
  static const double card = 10;
  static const double sheet = 14;
  /// Rung lớn — card nổi / pill-chip cỡ to (gồm 18–22px cũ). KHÔNG phải pill tròn.
  static const double lg = 20;
  static const double pill = 999;
}
