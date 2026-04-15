import 'package:flutter/material.dart';
import 'package:pretty_diff_text/pretty_diff_text.dart';

import '../../../core/locale/l10n_context.dart';

class InteractiveDiffText extends StatelessWidget {
  final String text;
  final String? originalText;

  const InteractiveDiffText({super.key, required this.text, this.originalText});

  String _normalizeForDiff(String source) {
    return source
        .replaceAll('\\n', '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    // Regex tìm pattern: {{old||new||reason}}
    // Group 1: old, Group 2: new, Group 3: reason
    final regex = RegExp(r'\{\{(.*?)\|\|(.*?)(?:\|\|(.*?))?\}\}');
    List<InlineSpan> spans = [];
    int lastMatchEnd = 0;
    bool hasValidCorrectionToken = false;

    // Duyệt qua tất cả các lỗi tìm thấy trong chuỗi
    for (final Match match in regex.allMatches(text)) {
      // 1. Thêm phần văn bản bình thường trước lỗi (nếu có)
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Color(0xFF09090B), // Màu đen chuẩn
          ),
        ));
      }

      // 2. Lấy thông tin lỗi
      String oldText = match.group(1) ?? '';
      String newText = match.group(2) ?? '';
      String reason = match.group(3) ?? '';
      if (oldText.trim().toLowerCase() == newText.trim().toLowerCase()) {
        spans.add(TextSpan(
          text: newText, // Hiển thị luôn từ đó bình thường
          style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF09090B)),
        ));
        lastMatchEnd = match.end;
        continue; // Bỏ qua, chạy vòng lặp tiếp theo
      }
      // 3. Thêm Widget tương tác (Lỗi)
      hasValidCorrectionToken = true;
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _ErrorToken(
          oldText: oldText,
          newText: newText,
          reason: reason,
        ),
      ));

      lastMatchEnd = match.end;
    }

    // 4. Thêm phần văn bản còn lại sau lỗi cuối cùng
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: const TextStyle(
          fontSize: 15,
          height: 1.6,
          color: Color(0xFF09090B),
        ),
      ));
    }

    // Nếu không có token sửa hợp lệ, fallback sang diff trực tiếp giữa bài gốc và bài rewrite.
    // Trường hợp backend trả token lỗi format/không hữu dụng thì vẫn có highlight đỏ/xanh.
    if (!hasValidCorrectionToken) {
      final oldText = _normalizeForDiff(originalText ?? '');
      final newText = _normalizeForDiff(text);
      if (oldText.isNotEmpty && newText.isNotEmpty && oldText != newText) {
        return PrettyDiffText(
          oldText: oldText,
          newText: newText,
          defaultTextStyle: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF09090B)),
          addedTextStyle: const TextStyle(
            backgroundColor: Color(0xFFDCFCE7),
            color: Color(0xFF14532D),
            fontWeight: FontWeight.w600,
          ),
          deletedTextStyle: const TextStyle(
            backgroundColor: Color(0xFFFEE2E2),
            color: Color(0xFF991B1B),
            decoration: TextDecoration.lineThrough,
          ),
        );
      }
      return Text(newText, style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF09090B)));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}

// Widget hiển thị cụm lỗi (Gạch đỏ -> Xanh)
class _ErrorToken extends StatelessWidget {
  final String oldText;
  final String newText;
  final String reason;

  const _ErrorToken({
    required this.oldText,
    required this.newText,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Hiển thị Dialog Cute
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: _CuteReasonPopup(old: oldText, newT: newText, reason: reason),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2), // Nền đỏ rất nhạt
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFECACA)), // Viền đỏ nhạt
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Từ sai (Gạch ngang)
            if (oldText.isNotEmpty) ...[
              Text(
                oldText,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFDC2626), // Đỏ đậm
                  decoration: TextDecoration.lineThrough,
                  decorationColor: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_right_alt, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
            ],
            // Từ đúng (Xanh lá)
            Text(
              newText,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF16A34A), // Xanh lá đậm
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog hiển thị lý do
class _CuteReasonPopup extends StatelessWidget {
  final String old;
  final String newT;
  final String reason;

  const _CuteReasonPopup({required this.old, required this.newT, required this.reason});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_fix_high, color: Color(0xFF3B82F6)),
              ),
              const SizedBox(width: 12),
              Text(
                t.writingAiSuggestionTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // So sánh
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4E4E7)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (old.isNotEmpty) ...[
                  Text(old, style: const TextStyle(color: Colors.red, decoration: TextDecoration.lineThrough)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                  ),
                ],
                Text(newT, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(t.writingWhyCorrection, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937), height: 1.5),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 24),

          // Button Close
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF18181B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(t.writingGotIt),
            ),
          )
        ],
      ),
    );
  }
}