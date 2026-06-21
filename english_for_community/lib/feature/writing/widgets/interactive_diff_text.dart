import 'package:flutter/material.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:pretty_diff_text/pretty_diff_text.dart';

import '../../../core/locale/l10n_context.dart';
import '../../../core/theme/app_color.dart';

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
    final regex = RegExp(r'\{\{(.*?)\|\|(.*?)(?:\|\|(.*?))?\}\}');
    List<InlineSpan> spans = [];
    int lastMatchEnd = 0;
    bool hasValidCorrectionToken = false;

    for (final Match match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: AppColors.textPrimary,
          ),
        ));
      }

      String oldText = match.group(1) ?? '';
      String newText = match.group(2) ?? '';
      String reason = match.group(3) ?? '';
      if (oldText.trim().toLowerCase() == newText.trim().toLowerCase()) {
        spans.add(TextSpan(
          text: newText,
          style: const TextStyle(fontSize: 15, height: 1.6, color: AppColors.textPrimary),
        ));
        lastMatchEnd = match.end;
        continue;
      }
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

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: const TextStyle(
          fontSize: 15,
          height: 1.6,
          color: AppColors.textPrimary,
        ),
      ));
    }

    if (!hasValidCorrectionToken) {
      final oldText = _normalizeForDiff(originalText ?? '');
      final newText = _normalizeForDiff(text);
      if (oldText.isNotEmpty && newText.isNotEmpty && oldText != newText) {
        return PrettyDiffText(
          oldText: oldText,
          newText: newText,
          defaultTextStyle: const TextStyle(fontSize: 15, height: 1.6, color: AppColors.textPrimary),
          addedTextStyle: const TextStyle(
            backgroundColor: AppColors.successBg,
            color: AppColors.success,
            fontWeight: FontWeight.w600,
          ),
          deletedTextStyle: const TextStyle(
            backgroundColor: AppColors.dangerBg,
            color: AppColors.danger,
            decoration: TextDecoration.lineThrough,
          ),
        );
      }
      return Text(newText, style: const TextStyle(fontSize: 15, height: 1.6, color: AppColors.textPrimary));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}

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
          color: AppColors.dangerBg,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: AppColors.dangerBg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (oldText.isNotEmpty) ...[
              Text(
                oldText,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.danger,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.danger,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_right_alt, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
            ],
            Text(
              newText,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: const Icon(Icons.auto_fix_high, color: AppColors.info),
              ),
              const SizedBox(width: 12),
              Text(
                t.writingAiSuggestionTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sheet),
              border: Border.all(color: AppColors.outline),
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
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.5),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
              ),
              child: Text(t.writingGotIt),
            ),
          )
        ],
      ),
    );
  }
}
