import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String? senderName;
  final String? senderAvatar;
  final DateTime createdAt;

  // 🔥 THÊM TRƯỜNG NÀY
  final Map<String, dynamic>? data;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.senderName,
    this.senderAvatar,
    required this.createdAt,

    // 🔥 THÊM VÀO CONSTRUCTOR
    this.data,
  });

  static DateTime _parseCreatedAt(dynamic raw) {
    if (raw == null) return DateTime.now();
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    final s = raw.toString();
    if (s.isEmpty) return DateTime.now();
    return DateTime.tryParse(s) ?? DateTime.now();
  }

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    String sName = 'Hệ thống';
    String? sAvatar;
    final sender = json['senderId'];
    if (sender is Map) {
      sName = sender['fullName']?.toString() ?? 'Người dùng ẩn danh';
      sAvatar = sender['avatarUrl']?.toString();
    }

    Map<String, dynamic>? dataMap;
    final rawData = json['data'];
    if (rawData is Map) {
      dataMap = Map<String, dynamic>.from(rawData);
    }

    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';

    return NotificationEntity(
      id: id,
      title: json['title']?.toString() ?? 'Thông báo',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'SYSTEM',
      isRead: json['isRead'] == true,
      senderName: sName,
      senderAvatar: sAvatar,
      createdAt: _parseCreatedAt(json['createdAt']),
      data: dataMap,
    );
  }

  // Hàm copyWith để update trạng thái (ví dụ đánh dấu đã đọc)
  NotificationEntity copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    String? senderName,
    String? senderAvatar,
    DateTime? createdAt,
    Map<String, dynamic>? data, // 🔥 Thêm vào copyWith
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data, // 🔥
    );
  }

  @override
  List<Object?> get props => [id, title, message, type, isRead, senderName, senderAvatar, createdAt, data];
}