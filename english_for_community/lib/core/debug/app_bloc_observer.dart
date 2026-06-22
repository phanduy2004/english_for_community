import 'package:english_for_community/core/debug/app_dev_log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Ghi log mọi exception trong BLoC ra Debug Console.
class AppBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    AppDevLog.error(bloc.runtimeType.toString(), error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    _maybeLogErrorState(bloc, change.nextState);
  }

  void _maybeLogErrorState(BlocBase<dynamic> bloc, Object? state) {
    if (state == null) return;
    try {
      final dynamic s = state;
      final msg = s.errorMessage;
      if (msg is String && msg.trim().isNotEmpty) {
        final status = s.status;
        final statusStr = status?.toString() ?? '';
        if (statusStr.contains('error') ||
            statusStr.contains('failure') ||
            statusStr.contains('Failure')) {
          AppDevLog.warn('[${bloc.runtimeType}] $msg');
        }
      }
    } catch (_) {
      // State không có errorMessage — bỏ qua.
    }
  }
}
