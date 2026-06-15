import 'package:flutter/material.dart';

import '../motion/app_loading_indicator.dart';
import '../student_mobile_ui.dart';
import '../../theme/app_spacing.dart';

/// Chỉ hiện [child] khi **không** đang load; lúc chờ API thì hiện loading animation.
///
/// ```dart
/// AppLoadGate(
///   isLoading: state.status == MyStatus.loading,
///   errorMessage: state.status == MyStatus.error ? state.message : null,
///   onRetry: () => bloc.add(Load()),
///   child: MyList(...),
/// )
/// ```
class AppLoadGate extends StatelessWidget {
  const AppLoadGate({
    super.key,
    required this.isLoading,
    required this.child,
    this.loading,
    this.errorMessage,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.showContentUnderLoading = false,
  });

  final bool isLoading;
  final Widget child;
  final Widget? loading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String retryLabel;

  /// Giữ nội dung cũ mờ phía dưới khi refresh (tùy màn).
  final bool showContentUnderLoading;

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null && !isLoading) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: StudentMobileUi.errorBanner(
          message: errorMessage!,
          onRetry: onRetry ?? () {},
          retryLabel: retryLabel,
        ),
      );
    }

    if (isLoading) {
      final indicator = loading ??
          const Center(
            child: AppLoadingIndicator.center(),
          );

      if (!showContentUnderLoading) {
        return indicator;
      }

      return Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          IgnorePointer(child: Opacity(opacity: 0.35, child: child)),
          indicator,
        ],
      );
    }

    return child;
  }
}
