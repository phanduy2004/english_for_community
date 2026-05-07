import 'package:english_for_community/core/entity/app_update_info_entity.dart';
import 'package:equatable/equatable.dart';

class AppUpdateState extends Equatable {
  final bool isChecking;
  final AppUpdateInfoEntity? info;
  final String? errorMessage;
  final DateTime? lastCheckedAt;

  const AppUpdateState({
    required this.isChecking,
    required this.info,
    required this.errorMessage,
    required this.lastCheckedAt,
  });

  factory AppUpdateState.initial() {
    return const AppUpdateState(
      isChecking: false,
      info: null,
      errorMessage: null,
      lastCheckedAt: null,
    );
  }

  AppUpdateState copyWith({
    bool? isChecking,
    AppUpdateInfoEntity? info,
    bool clearInfo = false,
    String? errorMessage,
    bool clearError = false,
    DateTime? lastCheckedAt,
  }) {
    return AppUpdateState(
      isChecking: isChecking ?? this.isChecking,
      info: clearInfo ? null : (info ?? this.info),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    );
  }

  @override
  List<Object?> get props => [isChecking, info, errorMessage, lastCheckedAt];
}
