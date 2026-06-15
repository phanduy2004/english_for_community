import 'dart:async';

import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/feature/student/join/student_join_input.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Routes a pasted code or link to the correct join flow.
class StudentJoinCoordinator {
  const StudentJoinCoordinator._();

  static Future<bool> submit(
    BuildContext context,
    String raw, {
    void Function()? onClassJoined,
  }) async {
    final input = parseStudentJoinInput(raw);
    final l10n = context.l10n;
    final repo = getIt<TeacherExamRepository>();

    switch (input.kind) {
      case StudentJoinInputKind.empty:
        return false;
      case StudentJoinInputKind.invalid:
        AppCornerToast.show(context, l10n.studentJoinInputInvalid, error: true);
        return false;
      case StudentJoinInputKind.examSession:
        final sid = input.sessionId ?? '';
        if (sid.isEmpty) return false;
        AppCornerToast.show(context, l10n.studentJoinDetectedSession);
        await context.push('/student/exam-session/$sid');
        return true;
      case StudentJoinInputKind.classInviteCode:
        AppCornerToast.show(context, l10n.studentJoinDetectedClass);
        final codeResult = await repo.joinClassByCode(input.value ?? '');
        if (!context.mounted) return false;
        return codeResult.fold(
          (f) {
            AppCornerToast.show(context, f.message, error: true);
            return false;
          },
          (_) {
            AppCornerToast.show(context, l10n.studentJoinClassSuccess);
            onClassJoined?.call();
            return true;
          },
        );
      case StudentJoinInputKind.classInviteToken:
        AppCornerToast.show(context, l10n.studentJoinDetectedClass);
        final tokenResult = await repo.joinClassByToken(input.value ?? '');
        if (!context.mounted) return false;
        return tokenResult.fold(
          (f) {
            AppCornerToast.show(context, f.message, error: true);
            return false;
          },
          (_) {
            AppCornerToast.show(context, l10n.studentJoinClassSuccess);
            onClassJoined?.call();
            return true;
          },
        );
      case StudentJoinInputKind.publicExamToken:
        return _joinPublicExam(context, input.value ?? '');
    }
  }

  static Future<bool> _joinPublicExam(BuildContext context, String token) async {
    if (token.isEmpty) return false;
    final l10n = context.l10n;
    final repo = getIt<TeacherExamRepository>();

    AppCornerToast.show(context, l10n.studentJoinDetectedPublicExam);

    Map<String, dynamic>? previewMap;
    final preview = await repo.previewPublicExam(token);
    if (!context.mounted) return false;
    preview.fold(
      (f) => AppCornerToast.show(context, f.message, error: true),
      (d) => previewMap = Map<String, dynamic>.from(d as Map),
    );
    if (previewMap == null) return false;

    if (previewMap!['mode'] == 'realtime') {
      final sessionResult = await repo.joinPublicExamSession(token);
      if (!context.mounted) return false;
      return sessionResult.fold(
        (f) {
          AppCornerToast.show(context, f.message, error: true);
          return false;
        },
        (payload) {
          final map = Map<String, dynamic>.from(payload as Map);
          final sessionId = map['sessionId'] as String? ?? '';
          if (sessionId.isEmpty) return false;
          unawaited(context.push('/student/exam-session/$sessionId'));
          return true;
        },
      );
    }

    final attemptResult = await repo.startPublicExamAttempt(token);
    if (!context.mounted) return false;
    return attemptResult.fold(
      (f) {
        AppCornerToast.show(context, f.message, error: true);
        return false;
      },
      (attempt) {
        final map = Map<String, dynamic>.from(attempt as Map);
        final attemptId = map['id'] as String? ?? '';
        if (attemptId.isEmpty) return false;
        unawaited(context.push('/student/exam-run/$attemptId'));
        return true;
      },
    );
  }
}
