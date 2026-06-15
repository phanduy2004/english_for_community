import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/utils/global_keys.dart';
import 'package:english_for_community/feature/auth/bloc/user_bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// In-app feedback toast.
///
/// - **Student mobile** (`role == user`, Android/iOS): full-width bottom [SnackBar]
///   (native mobile pattern). Realtime/push alerts use [LocalNotificationService]
///   + inbox [NotificationDialog] — not this widget.
/// - **Web / teacher / admin**: compact floating toast at bottom-right (desk UX).
class AppCornerToast {
  AppCornerToast._();

  static const double _horizontalPadding = 16;
  static const double _edgeInset = 20;
  static const double _minWidth = 120;
  static const double _maxWidth = 360;

  /// Student app on phone/tablet — not web, not teacher/admin console.
  static bool isStudentMobileFeedback() {
    if (kIsWeb) return false;
    final role = getIt<UserBloc>().state.userEntity?.role ?? 'user';
    return role == 'user';
  }

  static ScaffoldMessengerState? _resolveMessenger(BuildContext context) {
    final local = ScaffoldMessenger.maybeOf(context);
    if (local != null) return local;
    final rootCtx = rootNavigatorKey.currentContext;
    if (rootCtx != null) return ScaffoldMessenger.maybeOf(rootCtx);
    return null;
  }

  static void show(
    BuildContext context,
    String message, {
    bool error = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = _resolveMessenger(context);
    if (messenger == null) {
      debugPrint('[AppCornerToast] $message');
      return;
    }

    final textStyle = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      height: 1.25,
    );

    messenger.hideCurrentSnackBar();

    if (isStudentMobileFeedback()) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(message, style: textStyle, maxLines: 4, overflow: TextOverflow.ellipsis),
          backgroundColor: error ? AppColors.danger : AppColors.success,
          behavior: SnackBarBehavior.fixed,
          duration: duration,
        ),
      );
      return;
    }

    final textDirection = Directionality.of(context);
    final painter = TextPainter(
      text: TextSpan(text: message, style: textStyle),
      textDirection: textDirection,
      maxLines: 3,
    )..layout(maxWidth: _maxWidth - _horizontalPadding * 2);

    final estimatedWidth =
        (painter.size.width + _horizontalPadding * 2).clamp(_minWidth, _maxWidth);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    messenger.showSnackBar(
      SnackBar(
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(message, style: textStyle),
        ),
        backgroundColor: error ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        duration: duration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.only(
          right: _edgeInset,
          bottom: bottomSafe + _edgeInset,
          left: screenWidth - estimatedWidth - _edgeInset,
        ),
      ),
    );
  }
}
