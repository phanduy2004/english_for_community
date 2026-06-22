import 'package:flutter/material.dart';

import 'app_color.dart';

/// Thang màu điểm — **một nguồn** cho chart phân phối điểm, ô gradebook,
/// status skill. Thay các hex rời rạc (`0xFFEA580C`, `0xFF65A30D`, `0xFF43A047`…).
///
/// Spec: `docs/ui-ux-system/18-teacher-web-audit-and-standards.md` §5.3.
/// Hợp nhất mọi sắc "đạt/xanh" về [AppColors.success].
abstract final class AppScoreScale {
  /// < 4.0
  static const Color fail = AppColors.danger;

  /// 4.0 – 5.5
  static const Color weak = Color(0xFFEA580C); // audit-ignore: token gốc

  /// 5.5 – 7.0
  static const Color mid = AppColors.warning;

  /// 7.0 – 8.5
  static const Color good = Color(0xFF65A30D); // audit-ignore: token gốc

  /// ≥ 8.5
  static const Color strong = AppColors.success;

  /// Ramp 5 bậc (fail → strong) cho legend & bucket chart.
  static const List<Color> ramp = [fail, weak, mid, good, strong];

  /// Map điểm 0–10 → màu bậc tương ứng.
  static Color forScore10(double score) {
    if (score < 4.0) return fail;
    if (score < 5.5) return weak;
    if (score < 7.0) return mid;
    if (score < 8.5) return good;
    return strong;
  }

  /// Map tỉ lệ phần trăm 0–100 → màu bậc.
  static Color forPercent(double percent) => forScore10(percent / 10.0);
}
