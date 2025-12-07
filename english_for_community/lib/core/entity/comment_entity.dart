import 'package:equatable/equatable.dart';

// Enum các loại cảm xúc (Khớp với Backend)
enum ReactionType { LIKE, LOVE, HAHA, WOW, SAD, ANGRY }

// Helper để parse từ String sang Enum
ReactionType _stringToReactionType(String type) {
  return ReactionType.values.firstWhere(
        (e) => e.name == type,
    orElse: () => ReactionType.LIKE,
  );
}

class ReactionEntity extends Equatable {
  final String userId;
  final ReactionType type;

  const ReactionEntity({required this.userId, required this.type});

  factory ReactionEntity.fromJson(Map<String, dynamic> json) {
    // Backend trả về userId có thể là object (nếu populate) hoặc string
    final uId = json['userId'] is Map ? json['userId']['_id'] : json['userId'];
    return ReactionEntity(
      userId: uId.toString(),
      type: _stringToReactionType(json['type']),
    );
  }

  // Helper để hiển thị UI (Icon/Màu sắc) nếu cần
  @override
  List<Object?> get props => [userId, type];
}

class CommentEntity extends Equatable {
  final String id;
  final String listeningId;
  final String cueId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime createdAt;
  final String? parentId;
  final List<CommentEntity> replies;

  // 🔥 THAY ĐỔI: Dùng List<ReactionEntity> thay vì List<String>
  final List<ReactionEntity> reactions;

  const CommentEntity({
    required this.id,
    required this.listeningId,
    required this.cueId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.createdAt,
    this.parentId,
    this.replies = const [],
    this.reactions = const [], // 🔥
  });

  factory CommentEntity.fromJson(Map<String, dynamic> json) {
    final userObj = json['userId'] as Map<String, dynamic>?;
    return CommentEntity(
      id: json['_id'] ?? json['id'] ?? '',
      listeningId: json['listeningId']?.toString() ?? '',
      cueId: json['cueId']?.toString() ?? '',
      userId: userObj?['_id'] ?? userObj?['id'] ?? '',
      userName: userObj?['fullName'] ?? 'Unknown',
      userAvatar: userObj?['avatarUrl'],
      content: json['content'] ?? '',
      parentId: json['parentId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      replies: [],

      // 🔥 Parse mảng reactions từ Backend
      reactions: (json['reactions'] as List?)
          ?.map((e) => ReactionEntity.fromJson(e))
          .toList() ?? [],
    );
  }

  CommentEntity copyWith({
    List<CommentEntity>? replies,
    List<ReactionEntity>? reactions, // 🔥
  }) {
    return CommentEntity(
      id: id,
      listeningId: listeningId,
      cueId: cueId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      content: content,
      createdAt: createdAt,
      parentId: parentId,
      replies: replies ?? this.replies,
      reactions: reactions ?? this.reactions, // 🔥
    );
  }

  // 🔥 Helper: Lấy reaction của user hiện tại (nếu có)
  ReactionType? getMyReaction(String currentUserId) {
    try {
      return reactions.firstWhere((r) => r.userId == currentUserId).type;
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [id, content, parentId, replies, reactions];
}