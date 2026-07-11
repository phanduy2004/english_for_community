import 'package:english_for_community/core/debug/app_dev_log.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/core/ui/workspace_layout_scope.dart';
import 'package:flutter/material.dart';

/// Semantic feedback API — routes to SnackBar (student), corner toast (web workspace),
/// inline field errors, or blocking dialogs per `docs/ui-ux-system/26`.
abstract final class AppFeedback {
  static const Duration _dedupWindow = Duration(seconds: 3);
  static const Duration _successDuration = Duration(milliseconds: 1800);

  static String? _lastMessage;
  static DateTime? _lastShownAt;
  static bool _blockingDialogOpen = false;

  /// Student learner UI (mobile pattern), including student on Flutter web.
  static bool isStudentMobileFeedback(BuildContext context) {
    return !WorkspaceLayoutScope.isWebWorkspace(context);
  }

  static bool _consumeDuplicate(String message) {
    final now = DateTime.now();
    if (_lastMessage == message &&
        _lastShownAt != null &&
        now.difference(_lastShownAt!) < _dedupWindow) {
      return true;
    }
    _lastMessage = message;
    _lastShownAt = now;
    return false;
  }

  /// Light confirmation — SnackBar (student) / corner toast (teacher/admin web).
  static void success(BuildContext context, String message) {
    if (_consumeDuplicate(message)) return;
    AppCornerToast.show(context, message, duration: _successDuration);
  }

  static void info(BuildContext context, String message) {
    success(context, message);
  }

  /// Errors: [blocking] → dialog; otherwise SnackBar/banner with optional retry.
  static void error(
    BuildContext context,
    String message, {
    bool blocking = false,
    VoidCallback? onRetry,
  }) {
    if (_consumeDuplicate(message)) return;
    AppDevLog.uiError(message);

    if (blocking) {
      _showBlockingDialog(context, message, onRetry: onRetry);
      return;
    }

    if (onRetry != null && isStudentMobileFeedback(context)) {
      _showRetrySnackBar(context, message, onRetry);
      return;
    }

    AppCornerToast.show(context, message, error: true);
  }

  /// Inline validation under a form field — no floating feedback.
  static Widget fieldError(String? message) {
    if (message == null || message.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s2),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: AppTypography.mobileCaption,
          fontWeight: FontWeight.w500,
          color: AppColors.danger,
          height: 1.3,
        ),
      ),
    );
  }

  static Future<void> _showBlockingDialog(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) async {
    if (_blockingDialogOpen) return;
    _blockingDialogOpen = true;
    final l10n = context.l10n;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: onRetry == null,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.commonError),
          content: Text(message),
          actions: [
            if (onRetry != null)
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onRetry();
                },
                child: Text(l10n.tryAgain),
              ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.close),
            ),
          ],
        ),
      );
    } finally {
      _blockingDialogOpen = false;
    }
  }

  static void _showRetrySnackBar(
    BuildContext context,
    String message,
    VoidCallback onRetry,
  ) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      AppCornerToast.show(context, message, error: true);
      return;
    }
    final l10n = context.l10n;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: l10n.tryAgain,
          textColor: Colors.white,
          onPressed: onRetry,
        ),
      ),
    );
  }
}
