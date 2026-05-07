import 'package:equatable/equatable.dart';

enum AppUpdateStatus { upToDate, softUpdate, forceUpdate }

class AppUpdateInfoEntity extends Equatable {
  final AppUpdateStatus status;
  final String? latestVersionName;
  final int latestVersionCode;
  final int minSupportedVersionCode;
  final bool forceUpdate;
  final String? storeUrl;
  final String? downloadUrl;
  final String changelog;

  const AppUpdateInfoEntity({
    required this.status,
    required this.latestVersionName,
    required this.latestVersionCode,
    required this.minSupportedVersionCode,
    required this.forceUpdate,
    required this.storeUrl,
    required this.downloadUrl,
    required this.changelog,
  });

  bool get hasUpdate => status != AppUpdateStatus.upToDate;

  /// Ưu tiên link tải trực tiếp (APK) — phù hợp khi không dùng CH Play.
  /// [storeUrl] chỉ dùng khi không có [downloadUrl].
  String? get updateUrl {
    if (downloadUrl != null && downloadUrl!.isNotEmpty) return downloadUrl;
    if (storeUrl != null && storeUrl!.isNotEmpty) return storeUrl;
    return null;
  }

  factory AppUpdateInfoEntity.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? 'up_to_date').toString();
    final parsedStatus = switch (rawStatus) {
      'force_update' => AppUpdateStatus.forceUpdate,
      'soft_update' => AppUpdateStatus.softUpdate,
      _ => AppUpdateStatus.upToDate,
    };
    return AppUpdateInfoEntity(
      status: parsedStatus,
      latestVersionName: json['latestVersionName']?.toString(),
      latestVersionCode: (json['latestVersionCode'] as num?)?.toInt() ?? 0,
      minSupportedVersionCode:
          (json['minSupportedVersionCode'] as num?)?.toInt() ?? 0,
      forceUpdate: (json['forceUpdate'] as bool?) ??
          parsedStatus == AppUpdateStatus.forceUpdate,
      storeUrl: json['storeUrl']?.toString(),
      downloadUrl: json['downloadUrl']?.toString(),
      changelog: json['changelog']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [
        status,
        latestVersionName,
        latestVersionCode,
        minSupportedVersionCode,
        forceUpdate,
        storeUrl,
        downloadUrl,
        changelog,
      ];
}
