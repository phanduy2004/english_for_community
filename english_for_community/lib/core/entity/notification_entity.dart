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

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {

    // Parse Sender info an toàn
    String sName = 'Hệ thống';
    String? sAvatar;
    if (json['senderId'] != null && json['senderId'] is Map) {
      sName = json['senderId']['fullName'] ?? 'Người dùng ẩn danh';
      sAvatar = json['senderId']['avatarUrl'];
    }

    return NotificationEntity(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Thông báo',
      message: json['message'] ?? '',
      type: json['type'] ?? 'SYSTEM',
      isRead: json['isRead'] ?? false,

      senderName: sName,   // ✅ Luôn hiển thị tên đẹp
      senderAvatar: sAvatar,

      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
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