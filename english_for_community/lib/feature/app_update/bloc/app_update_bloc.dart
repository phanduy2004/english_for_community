import 'package:bloc/bloc.dart';
import 'package:english_for_community/core/repository/app_update_repository.dart';
import 'package:english_for_community/feature/app_update/bloc/app_update_event.dart';
import 'package:english_for_community/feature/app_update/bloc/app_update_state.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateBloc extends Bloc<AppUpdateEvent, AppUpdateState> {
  final AppUpdateRepository repository;

  AppUpdateBloc({required this.repository}) : super(AppUpdateState.initial()) {
    on<AppUpdateCheckRequested>(_onCheckRequested);
  }

  /// Backend chỉ hỗ trợ `android` / `ios`. Trên web không dùng `dart:io` (sẽ crash).
  static String _apiPlatform() {
    if (kIsWeb) return 'android';
    return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  }

  Future<void> _onCheckRequested(
    AppUpdateCheckRequested event,
    Emitter<AppUpdateState> emit,
  ) async {
    // Web (Firebase Hosting): không gọi version-check native; tránh dart:io / logic sai platform.
    if (kIsWeb) {
      emit(state.copyWith(
        isChecking: false,
        clearError: true,
        lastCheckedAt: DateTime.now(),
      ));
      return;
    }

    final lastChecked = state.lastCheckedAt;
    if (!event.forceRefresh && lastChecked != null) {
      final elapsed = DateTime.now().difference(lastChecked);
      if (elapsed.inMinutes < 30) return;
    }

    emit(state.copyWith(isChecking: true, clearError: true));
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 1;
    final platform = _apiPlatform();

    final result = await repository.checkVersion(
      platform: platform,
      versionCode: currentVersionCode,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          isChecking: false,
          errorMessage: failure.message,
          lastCheckedAt: DateTime.now(),
        ),
      ),
      (info) => emit(
        state.copyWith(
          isChecking: false,
          info: info,
          clearError: true,
          lastCheckedAt: DateTime.now(),
        ),
      ),
    );
  }
}
