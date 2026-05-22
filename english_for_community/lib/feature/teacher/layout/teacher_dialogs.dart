import 'package:english_for_community/feature/teacher/layout/teacher_account_menu.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_assign_exam_dialog.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_change_password_dialog.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_dialog_shell.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_edit_profile_dialog.dart';
import 'package:flutter/material.dart';

export 'teacher_account_menu.dart' show showTeacherAccountMenu;

/// Teacher workspace dialog entry points — `docs/ui-ux-system/14-teacher-dialogs.md`.
abstract final class TeacherDialogs {
  static void showAccountMenu(BuildContext context) => showTeacherAccountMenu(context);

  static Future<void> showEditProfile(BuildContext context) {
    return TeacherDialogShell.show<void>(
      context,
      child: const TeacherEditProfileDialog(),
    );
  }

  static Future<void> showChangePassword(BuildContext context) {
    return TeacherDialogShell.show<void>(
      context,
      child: const TeacherChangePasswordDialog(),
    );
  }

  /// Assign published exam to class or public link (`14-teacher-dialogs` §3).
  static Future<Map<String, dynamic>?> showAssignExam(
    BuildContext context, {
    required String examId,
    String? initialClassroomId,
  }) =>
      TeacherAssignExamDialog.show(
        context,
        examId: examId,
        initialClassroomId: initialClassroomId,
      );
}
