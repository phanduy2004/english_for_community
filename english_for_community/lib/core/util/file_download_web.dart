// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> downloadBytes({
  required String filename,
  required List<int> bytes,
  String? mimeType,
}) async {
  final blob = html.Blob(
    [Uint8List.fromList(bytes)],
    mimeType ?? 'application/octet-stream',
  );
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
