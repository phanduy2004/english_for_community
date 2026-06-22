import 'package:flutter/material.dart';

/// Editorial Black — bộ màu thống nhất E4C.
///
/// Triết lý: chữ đen, surface ấm (warm stone), brand mark = đen tinh tế,
/// accent amber chỉ dùng cho "ăn mừng" (KPI nổi, streak, chart highlight).
/// Không dùng teal/indigo làm brand. Xem `docs/ui-ux-system/02-design-tokens.md`.
abstract final class AppColors {
  // ─── Brand ────────────────────────────────────────────────────────────
  /// Brand mark — Editorial black. Filled button, AppBar logo, chevron, link nhấn.
  static const Color primary = Color(0xFF0A0A0A);

  /// Pressed / focus ring.
  static const Color primaryDark = Color(0xFF000000);

  /// Chữ trên nền primary.
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ─── Accent (highlight, celebrate, chart) ─────────────────────────────
  /// Amber — chỉ dùng cho achievement / streak / KPI nổi / chart highlight.
  /// KHÔNG dùng làm màu nút chính.
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentDark = Color(0xFFD97706);
  static const Color onAccent = Color(0xFF1C1917);

  /// Aliases legacy (nhiều màn cũ còn gọi `secondary`/`tertiary`).
  static const Color secondary = accent;
  static const Color tertiary = Color(0xFF6366F1);

  // ─── Surface (warm stone) ─────────────────────────────────────────────
  static const Color surface = Color(0xFFFAFAF9);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF5F5F4);
  static const Color surfaceInverse = Color(0xFF1C1917);

  // ─── Border ───────────────────────────────────────────────────────────
  static const Color outline = Color(0xFFE7E5E4);
  static const Color outlineMuted = Color(0xFFF1F0EE);
  static const Color outlineStrong = Color(0xFFD6D3D1);

  // ─── Text (đen-trước-tiên) ────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1C1917);
  static const Color textSecondary = Color(0xFF57534E);
  static const Color textMuted = Color(0xFFA8A29E);
  static const Color textInverse = Color(0xFFFFFFFF);

  // ─── Semantic ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  // audit-ignore: token gốc — translated text / success emphasis (doc 20 §3.1)
  static const Color successDark = Color(0xFF166534);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF6366F1);

  // ─── Tints / soft fills ───────────────────────────────────────────────
  /// BG cho chip selected, soft button, list-selected.
  static Color get primaryTint => const Color(0xFF0A0A0A).withValues(alpha: 0.06);

  /// Hover web (đậm hơn 1 nhịp).
  static Color get primaryStrong => const Color(0xFF0A0A0A).withValues(alpha: 0.10);

  /// Tint amber (badge, KPI nổi).
  static Color get accentTint => const Color(0xFFF59E0B).withValues(alpha: 0.14);

  // ─── Interaction overlays (đặt tên cho mọi alpha) ─────────────────────
  /// Hover nền row/tile trên web. Xem `docs/ui-ux-system/18` §5.2.
  static Color get hoverOverlay => const Color(0xFF0A0A0A).withValues(alpha: 0.04);

  /// Press feedback.
  static Color get pressOverlay => const Color(0xFF0A0A0A).withValues(alpha: 0.08);

  /// Ring focus 2px (Tab) — mọi phần tử tap được.
  static const Color focusRing = primary;

  /// Backdrop dialog / scrim.
  static const Color scrim = Color(0x66000000);

  /// Bóng card chuẩn (= `TeacherWebUi.cardShadow` lớp 1).
  static const Color shadowCard = Color(0x0A000000);

  /// Bóng ambient mảnh (lớp 2 của card).
  static const Color shadowAmbient = Color(0x04000000);

  /// Đường hairline 1px kiểu bóng (panel phẳng).
  static const Color shadowHairline = Color(0x06000000);

  /// Semantic backgrounds (theo `02-design-tokens.md` §1.5).
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color infoBg = Color(0xFFEEF2FF);

  // ─── Chart ────────────────────────────────────────────────────────────
  /// Cột chính — đen editorial.
  static const Color chartBar = Color(0xFF0A0A0A);
  static const Color chartHighlight = Color(0xFFF59E0B);
  static const Color chartTrend = Color(0xFFEF4444);
  static const Color chartGrid = Color(0xFFE7E5E4);

  // ─── Legacy aliases (giữ để không vỡ feature cũ — sẽ migrate dần) ────
  static const Color onSurface = surfaceCard;
  static const Color text = textPrimary;
}
