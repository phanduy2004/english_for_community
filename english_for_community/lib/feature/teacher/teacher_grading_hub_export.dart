import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/util/file_download.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_corner_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> exportAssignmentScoresExcel(
  BuildContext context, {
  required String assignmentId,
}) async {
  final l10n = context.l10n;
  final r = await getIt<TeacherExamRepository>().downloadAssignmentScoresXlsx(assignmentId);
  if (!context.mounted) return;

  await r.fold(
    (f) async {
      TeacherCornerToast.show(context, f.message, error: true);
    },
    (file) async {
      if (file.bytes.isEmpty) {
        TeacherCornerToast.show(context, l10n.teacherGradingHubExportEmpty, error: true);
        return;
      }

      const mime =
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

      if (kIsWeb) {
        await downloadBytes(
          filename: file.filename,
          bytes: file.bytes,
          mimeType: mime,
        );
        if (!context.mounted) return;
        TeacherCornerToast.show(context, l10n.teacherGradingHubExportDone);
        return;
      }

      await Clipboard.setData(
        ClipboardData(text: l10n.teacherGradingHubExportMobileHint(file.filename)),
      );
      if (!context.mounted) return;
      TeacherCornerToast.show(context, l10n.teacherGradingHubExportMobileCopied);
    },
  );
}
