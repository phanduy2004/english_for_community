import 'user_entity.dart';

class ReportDeviceInfo {
  final String? platform; // iOS/Android
  final String? version;  // 14.0, 11.0...
  final String? device;   // iPhone 12, Samsung S21...

  ReportDeviceInfo({this.platform, this.version, this.device});

  factory ReportDeviceInfo.fromJson(Map<String, dynamic> json) {
    return ReportDeviceInfo(
      platform: json['platform'],
      version: json['version'],
      device: json['device'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'version': version,
      'device': device,
    };
  }
}

class ReportEntity {
  final String? id; // Nullable vì khi gửi lên chưa có ID
  final UserEntity? user; // Backend populate (khi nhận về)

  final String type; // 'bug', 'feature', 'improvement', 'other'
  final String title;
  final String description;
  final List<String>? images; // 🔥 Thêm images
  final ReportDeviceInfo? deviceInfo; // 🔥 Thêm deviceInfo

  final String? status; // 'pending', 'reviewed', ...
  final String? adminResponse;
  final DateTime? createdAt;

  ReportEntity({
    this.id,
    this.user,
    required this.type,
    required this.title,
    required this.description,
    this.images,
    this.deviceInfo,
    this.status,
    this.adminResponse,
    this.createdAt,
  });

  // Parse từ Server trả về
  factory ReportEntity.fromJson(Map<String, dynamic> json) {
    return ReportEntity(
      id: json['_id'] ?? json['id'],
      user: json['user'] is Map<String, dynamic> ? UserEntity.fromJson(json['user']) : null,
      type: json['type'] ?? 'other',
      title: json['title'] ?? '',
      description: json['description'] ?? '',

      // Parse Images
      images: (json['images'] as List?)?.map((e) => e.toString()).toList(),

      // Parse DeviceInfo
      deviceInfo: json['deviceInfo'] != null
          ? ReportDeviceInfo.fromJson(json['deviceInfo'])
          : null,

      status: json['status'],
      adminResponse: json['adminResponse'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  // Convert để gửi lên Server
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'images': images,
      'deviceInfo': deviceInfo?.toJson(),
    };
  }
}