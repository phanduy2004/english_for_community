import 'package:flutter/material.dart';

/// Bảng màu kỹ năng — **Student vibrancy system**.
///
/// Mỗi kỹ năng học có 3 giá trị màu:
/// - [color] — màu chính (icon, progress bar, border accent)
/// - [tint]  — nền nhạt (icon box bg, chip bg)
/// - [dark]  — pressed / label đậm trên tint
///
/// Quy tắc dùng (từ `docs/ui-ux-system/02-design-tokens.md` §1.8):
/// - Chỉ dùng cho **học sinh** (student). Teacher/admin dùng `AppColors.primary`.
/// - Card **background** vẫn `surfaceCard` — chỉ icon box & progress dùng skill color.
/// - Heading/body text vẫn `textPrimary` — không tô chữ bằng skill color.
/// - Không trộn 2 skill color cạnh nhau trong cùng 1 row.
abstract final class AppSkillColors {
  static const listening = SkillColorSet(
    color: Color(0xFF3B82F6), // Blue-500 — âm thanh, sóng âm
    tint: Color(0xFFEFF6FF),  // Blue-50
    dark: Color(0xFF1D4ED8),  // Blue-700
  );

  static const speaking = SkillColorSet(
    color: Color(0xFF10B981), // Emerald-500 — giọng nói, năng động
    tint: Color(0xFFECFDF5),  // Emerald-50
    dark: Color(0xFF047857),  // Emerald-700
  );

  static const reading = SkillColorSet(
    color: Color(0xFFEA580C), // Orange-600 — ấm, sách vở
    tint: Color(0xFFFFF7ED),  // Orange-50
    dark: Color(0xFFC2410C),  // Orange-700
  );

  static const writing = SkillColorSet(
    color: Color(0xFF7C3AED), // Violet-600 — sáng tạo, tư duy
    tint: Color(0xFFF5F3FF),  // Violet-50
    dark: Color(0xFF5B21B6),  // Violet-700
  );

  static const vocabulary = SkillColorSet(
    color: Color(0xFFE11D48), // Rose-600 — nổi bật, ghi nhớ
    tint: Color(0xFFFFF1F2),  // Rose-50
    dark: Color(0xFFBE123C),  // Rose-700
  );

  /// Lấy màu kỹ năng theo enum [SkillType].
  static SkillColorSet of(SkillType skill) {
    switch (skill) {
      case SkillType.listening:
        return listening;
      case SkillType.speaking:
        return speaking;
      case SkillType.reading:
        return reading;
      case SkillType.writing:
        return writing;
      case SkillType.vocabulary:
        return vocabulary;
    }
  }
}

/// Enum định danh kỹ năng dùng xuyên suốt app học sinh.
enum SkillType {
  listening,
  speaking,
  reading,
  writing,
  vocabulary;

  /// Icon đại diện chuẩn (outlined) cho mỗi kỹ năng.
  IconData get icon {
    switch (this) {
      case SkillType.listening:
        return Icons.headphones_outlined;
      case SkillType.speaking:
        return Icons.record_voice_over_outlined;
      case SkillType.reading:
        return Icons.menu_book_outlined;
      case SkillType.writing:
        return Icons.edit_note_outlined;
      case SkillType.vocabulary:
        return Icons.style_outlined;
    }
  }
}

/// Bộ 3 màu cho 1 kỹ năng.
@immutable
class SkillColorSet {
  const SkillColorSet({
    required this.color,
    required this.tint,
    required this.dark,
  });

  /// Màu chính — icon, progress fill, left border accent.
  final Color color;

  /// Nền nhạt — icon box bg, chip bg.
  final Color tint;

  /// Màu đậm — label trên nền tint, pressed state.
  final Color dark;
}
