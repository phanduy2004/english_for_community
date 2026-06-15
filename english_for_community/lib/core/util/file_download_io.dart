import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<void> downloadBytes({
  required String filename,
  required List<int> bytes,
  String? mimeType,
}) async {
  Directory? dir = await getDownloadsDirectory();
  dir ??= await getApplicationDocumentsDirectory();

  final safeName = p.basename(filename).replaceAll(RegExp(r'[^\w.\-]'), '_');
  var target = File(p.join(dir.path, safeName));

  if (await target.exists()) {
    final stem = p.basenameWithoutExtension(safeName);
    final ext = p.extension(safeName);
    var i = 1;
    while (await target.exists()) {
      target = File(p.join(dir.path, '$stem ($i)$ext'));
      i++;
    }
  }

  await target.writeAsBytes(bytes);
}
