import 'package:equatable/equatable.dart';

class AppReleaseAdminEntity extends Equatable {
  final String id;
  final String platform;
  final String environment;
  final String versionName;
  final int versionCode;
  final int minSupportedVersionCode;
  final bool forceUpdate;
  final String updateType;
  final String status;
  final String? gitSha;
  final String? gitBranch;
  final String? ciRunId;
  final String? changelog;
  final DateTime? createdAt;
  final DateTime? scheduledPublishAt;
  final DateTime? publishedAt;

  const AppReleaseAdminEntity({
    required this.id,
    required this.platform,
    required this.environment,
    required this.versionName,
    required this.versionCode,
    required this.minSupportedVersionCode,
    required this.forceUpdate,
    required this.updateType,
    required this.status,
    required this.gitSha,
    required this.gitBranch,
    required this.ciRunId,
    required this.changelog,
    required this.createdAt,
    required this.scheduledPublishAt,
    required this.publishedAt,
  });

  bool get isForce => forceUpdate || updateType == 'force';

  factory AppReleaseAdminEntity.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic raw) {
      if (raw == null) return null;
      return DateTime.tryParse(raw.toString());
    }

    return AppReleaseAdminEntity(
      id: (json['_id'] ?? '').toString(),
      platform: (json['platform'] ?? 'android').toString(),
      environment: (json['environment'] ?? 'production').toString(),
      versionName: (json['versionName'] ?? '').toString(),
      versionCode: (json['versionCode'] as num?)?.toInt() ?? 0,
      minSupportedVersionCode:
          (json['minSupportedVersionCode'] as num?)?.toInt() ?? 0,
      forceUpdate: (json['forceUpdate'] as bool?) ?? false,
      updateType: (json['updateType'] ?? 'soft').toString(),
      status: (json['status'] ?? 'pending_approval').toString(),
      gitSha: json['gitSha']?.toString(),
      gitBranch: json['gitBranch']?.toString(),
      ciRunId: json['ciRunId']?.toString(),
      changelog: json['changelog']?.toString(),
      createdAt: parseDate(json['createdAt']),
      scheduledPublishAt: parseDate(json['scheduledPublishAt']),
      publishedAt: parseDate(json['publishedAt']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        platform,
        environment,
        versionName,
        versionCode,
        minSupportedVersionCode,
        forceUpdate,
        updateType,
        status,
        gitSha,
        gitBranch,
        ciRunId,
        changelog,
        createdAt,
        scheduledPublishAt,
        publishedAt,
      ];
}
