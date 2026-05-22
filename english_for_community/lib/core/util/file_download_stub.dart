import 'package:flutter/services.dart';

/// Non-web: copy text to clipboard (no native save dialog in stub).
Future<void> downloadBytes({
  required String filename,
  required List<int> bytes,
  String? mimeType,
}) async {
  await Clipboard.setData(ClipboardData(text: '[Binary file: $filename — ${bytes.length} bytes]'));
}
