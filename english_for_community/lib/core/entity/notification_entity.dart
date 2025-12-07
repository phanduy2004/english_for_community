import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String type; // 'COMMENT_REPLY', 'COMMENT_REACTION'...
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  // Thông tin người gửi
  final String senderName;
  final String? senderAvatar;

  // Payload data
  final String? listeningId;
  final String? commentId;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.senderName,
    this.senderAvatar,
    this.listeningId,
    this.commentId,
  });

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    final sender = json['senderId'] as Map<String, dynamic>?;
    final data = json['data'] as Map<String, dynamic>?;

    return NotificationEntity(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      senderName: sender?['fullName'] ?? 'System',
      senderAvatar: sender?['avatarUrl'],
      listeningId: data?['listeningId'],
      commentId: data?['commentId'],
    );
  }

  NotificationEntity copyWith({bool? isRead}) {
    return NotificationEntity(
      id: id, type: type, title: title, message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt, senderName: senderName, senderAvatar: senderAvatar,
      listeningId: listeningId, commentId: commentId,
    );
  }

  @override
  List<Object?> get props => [id, isRead, createdAt];
}