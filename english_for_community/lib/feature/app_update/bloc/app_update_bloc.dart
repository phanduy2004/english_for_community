import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:english_for_community/core/repository/app_update_repository.dart';
import 'package:english_for_community/feature/app_update/bloc/app_update_event.dart';
import 'package:english_for_community/feature/app_update/bloc/app_update_state.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateBloc extends Bloc<AppUpdateEvent, AppUpdateState> {
  final AppUpdateRepository repository;

  AppUpdateBloc({required this.repository}) : super(AppUpdateState.initial()) {
    on<AppUpdateCheckRequested>(_onCheckRequested);
  }

  Future<void> _onCheckRequested(
    AppUpdateCheckRequested event,
    Emitter<AppUpdateState> emit,
  ) async {
    final lastChecked = state.lastCheckedAt;
    if (!event.forceRefresh && lastChecked != null) {
      final elapsed = DateTime.now().difference(lastChecked);
      if (elapsed.inMinutes < 30) return;
    }

    emit(state.copyWith(isChecking: true, clearError: true));
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 1;
    final platform = Platform.isIOS ? 'ios' : 'android';

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
