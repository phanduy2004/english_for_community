import 'package:equatable/equatable.dart';
import 'dart:typed_data';

// ─── Media ────────────────────────────────────────────────────────────────────

class ChatMedia extends Equatable {
  final String url;
  final String name;
  final int size;
  final String mimeType;
  final String? thumbnailUrl;
  final int? width;
  final int? height;
  final int? durationSeconds;

  /// Preview cục bộ khi tin nhắn media đang upload (không gửi lên server).
  final Uint8List? localPreviewBytes;
  final String? localPreviewPath;

  const ChatMedia({
    required this.url,
    required this.name,
    required this.size,
    required this.mimeType,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.durationSeconds,
    this.localPreviewBytes,
    this.localPreviewPath,
  });

  bool get hasLocalPreview =>
      (localPreviewBytes != null && localPreviewBytes!.isNotEmpty) ||
      (localPreviewPath != null && localPreviewPath!.isNotEmpty);

  factory ChatMedia.fromJson(Map<String, dynamic> j) => ChatMedia(
        url: j['url'] as String? ?? '',
        name: j['name'] as String? ?? '',
        size: (j['size'] as num?)?.toInt() ?? 0,
        mimeType: j['mimeType'] as String? ?? '',
        thumbnailUrl: j['thumbnailUrl'] as String?,
        width: (j['width'] as num?)?.toInt(),
        height: (j['height'] as num?)?.toInt(),
        durationSeconds: (j['durationSeconds'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'name': name,
        'size': size,
        'mimeType': mimeType,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
      };

  ChatMedia copyWith({
    String? url,
    String? name,
    int? size,
    String? mimeType,
    String? thumbnailUrl,
    int? width,
    int? height,
    int? durationSeconds,
    Uint8List? localPreviewBytes,
    String? localPreviewPath,
    bool clearLocalPreview = false,
  }) =>
      ChatMedia(
        url: url ?? this.url,
        name: name ?? this.name,
        size: size ?? this.size,
        mimeType: mimeType ?? this.mimeType,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        width: width ?? this.width,
        height: height ?? this.height,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        localPreviewBytes:
            clearLocalPreview ? null : (localPreviewBytes ?? this.localPreviewBytes),
        localPreviewPath:
            clearLocalPreview ? null : (localPreviewPath ?? this.localPreviewPath),
      );

  @override
  List<Object?> get props => [
        url,
        name,
        size,
        mimeType,
        thumbnailUrl,
        width,
        height,
        durationSeconds,
        localPreviewBytes?.length,
        localPreviewPath,
      ];
}

// ─── Reply snapshot ───────────────────────────────────────────────────────────

class ChatReplySnapshot extends Equatable {
  final String messageId;
  final String senderId;
  final String senderName;
  final String contentPreview;
  final String messageType;

  const ChatReplySnapshot({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.contentPreview,
    required this.messageType,
  });

  factory ChatReplySnapshot.fromJson(Map<String, dynamic> j) => ChatReplySnapshot(
        messageId: j['messageId'] as String? ?? '',
        senderId: j['senderId'] is Map
            ? (j['senderId'] as Map)['_id']?.toString() ??
                (j['senderId'] as Map)['id']?.toString() ?? ''
            : j['senderId']?.toString() ?? '',
        senderName: j['senderName'] as String? ?? '',
        contentPreview: j['contentPreview'] as String? ?? '',
        messageType: j['messageType'] as String? ?? 'text',
      );

  @override
  List<Object?> get props =>
      [messageId, senderId, senderName, contentPreview, messageType];
}

// ─── Reaction ─────────────────────────────────────────────────────────────────

class ChatReaction extends Equatable {
  final String emoji;
  final int count;
  final List<String> userIds;

  const ChatReaction({
    required this.emoji,
    required this.count,
    required this.userIds,
  });

  factory ChatReaction.fromJson(Map<String, dynamic> j) => ChatReaction(
        emoji: j['emoji'] as String? ?? '',
        count: (j['count'] as num?)?.toInt() ?? (j['userIds'] as List?)?.length ?? 0,
        userIds: (j['userIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );

  @override
  List<Object?> get props => [emoji, count, userIds];
}

// ─── Sender info (embedded in message) ───────────────────────────────────────

class ChatSender extends Equatable {
  final String id;
  final String fullName;
  final String username;
  final String? avatarUrl;

  const ChatSender({
    required this.id,
    required this.fullName,
    required this.username,
    this.avatarUrl,
  });

  factory ChatSender.fromJson(Map<String, dynamic> j) {
    final id = j['id']?.toString() ?? j['_id']?.toString() ?? '';
    return ChatSender(
      id: id,
      fullName: j['fullName'] as String? ?? '',
      username: j['username'] as String? ?? '',
      avatarUrl: j['avatarUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, fullName, username, avatarUrl];
}

// ─── Main entity ──────────────────────────────────────────────────────────────

enum ChatMessageType { text, image, video, file }

ChatMessageType _typeFromString(String? s) {
  switch (s) {
    case 'image':
      return ChatMessageType.image;
    case 'video':
      return ChatMessageType.video;
    case 'file':
      return ChatMessageType.file;
    default:
      return ChatMessageType.text;
  }
}

class ClassroomChatMessage extends Equatable {
  final String id;
  final String classroomId;
  final ChatSender? sender;
  final String senderId;
  final ChatMessageType type;
  final String content;
  final ChatMedia? media;
  final ChatReplySnapshot? replyTo;
  final List<String> mentions;
  final List<ChatReaction> reactions;
  final DateTime? deletedAt;
  final DateTime? editedAt;
  final DateTime createdAt;

  /// Used locally for optimistic sends before server confirms.
  final bool isPending;
  /// Client-generated idempotency key.
  final String? clientId;

  const ClassroomChatMessage({
    required this.id,
    required this.classroomId,
    this.sender,
    required this.senderId,
    required this.type,
    required this.content,
    this.media,
    this.replyTo,
    this.mentions = const [],
    this.reactions = const [],
    this.deletedAt,
    this.editedAt,
    required this.createdAt,
    this.isPending = false,
    this.clientId,
  });

  bool get isDeleted => deletedAt != null;
  bool get isEdited => editedAt != null;
  bool get hasMedia => media != null;

  static DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString()) ?? DateTime.now();
  }

  factory ClassroomChatMessage.fromJson(Map<String, dynamic> j) {
    final senderRaw = j['senderId'];
    ChatSender? sender;
    String senderId = '';
    if (senderRaw is Map<String, dynamic>) {
      sender = ChatSender.fromJson(senderRaw);
      senderId = sender.id;
    } else {
      senderId = senderRaw?.toString() ?? '';
    }

    return ClassroomChatMessage(
      id: j['id']?.toString() ?? j['_id']?.toString() ?? '',
      classroomId: j['classroomId']?.toString() ?? '',
      sender: sender,
      senderId: senderId,
      type: _typeFromString(j['type'] as String?),
      content: j['content'] as String? ?? '',
      media: j['media'] is Map<String, dynamic>
          ? ChatMedia.fromJson(j['media'] as Map<String, dynamic>)
          : null,
      replyTo: j['replyTo'] is Map<String, dynamic>
          ? ChatReplySnapshot.fromJson(j['replyTo'] as Map<String, dynamic>)
          : null,
      mentions: (j['mentions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      reactions: (j['reactions'] as List?)
              ?.map((e) => ChatReaction.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      deletedAt: j['deletedAt'] != null ? _parseDate(j['deletedAt']) : null,
      editedAt: j['editedAt'] != null ? _parseDate(j['editedAt']) : null,
      createdAt: _parseDate(j['createdAt']),
      clientId: j['clientId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'classroomId': classroomId,
        'senderId': senderId,
        'type': type.name,
        'content': content,
        if (media != null) 'media': media!.toJson(),
        'createdAt': createdAt.toIso8601String(),
      };

  ClassroomChatMessage copyWith({
    String? id,
    List<ChatReaction>? reactions,
    DateTime? deletedAt,
    DateTime? editedAt,
    String? content,
    bool? isPending,
    String? clientId,
  }) =>
      ClassroomChatMessage(
        id: id ?? this.id,
        classroomId: classroomId,
        sender: sender,
        senderId: senderId,
        type: type,
        content: content ?? this.content,
        media: media,
        replyTo: replyTo,
        mentions: mentions,
        reactions: reactions ?? this.reactions,
        deletedAt: deletedAt ?? this.deletedAt,
        editedAt: editedAt ?? this.editedAt,
        createdAt: createdAt,
        isPending: isPending ?? this.isPending,
        clientId: clientId ?? this.clientId,
      );

  @override
  List<Object?> get props => [
        id,
        classroomId,
        senderId,
        type,
        content,
        media,
        replyTo,
        mentions,
        reactions,
        deletedAt,
        editedAt,
        createdAt,
        isPending,
      ];
}

// ─── Chat member (for @mention) ───────────────────────────────────────────────

class ChatMember extends Equatable {
  final String id;
  final String fullName;
  final String username;
  final String? avatarUrl;
  final String role; // 'teacher' | 'co_teacher' | 'student'

  const ChatMember({
    required this.id,
    required this.fullName,
    required this.username,
    this.avatarUrl,
    required this.role,
  });

  factory ChatMember.fromJson(Map<String, dynamic> j) => ChatMember(
        id: j['id'] as String? ?? '',
        fullName: j['fullName'] as String? ?? '',
        username: j['username'] as String? ?? '',
        avatarUrl: j['avatarUrl'] as String?,
        role: j['role'] as String? ?? 'student',
      );

  bool get isTeacher => role == 'teacher' || role == 'co_teacher';

  /// Chủ lớp (GV sở hữu lớp) — khác co_teacher.
  bool get isClassOwner => role == 'teacher';

  /// Thứ tự hiển thị danh sách: teacher → co_teacher → student.
  static int compareForMemberList(ChatMember a, ChatMember b) {
    final ra = _memberListSortRank(a);
    final rb = _memberListSortRank(b);
    if (ra != rb) return ra.compareTo(rb);
    return a.fullName.compareTo(b.fullName);
  }

  static int _memberListSortRank(ChatMember m) {
    if (m.isClassOwner) return 0;
    if (m.role == 'co_teacher') return 1;
    return 2;
  }

  @override
  List<Object?> get props => [id, fullName, username, avatarUrl, role];
}

enum ChatAttachmentKind { image, video, file }

/// Tệp đính kèm đang chờ gửi (preview trong ô nhập).
class ChatPendingAttachment extends Equatable {
  const ChatPendingAttachment({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.kind,
    this.filePath,
    this.bytes,
    this.size = 0,
  }) : assert(filePath != null || bytes != null, 'Cần filePath hoặc bytes');

  final String id;
  final String fileName;
  final String mimeType;
  final ChatAttachmentKind kind;
  final String? filePath;
  final Uint8List? bytes;
  final int size;

  ChatUploadPayload toPayload() => ChatUploadPayload(
        fileName: fileName,
        mimeType: mimeType,
        filePath: filePath,
        bytes: bytes,
      );

  @override
  List<Object?> get props => [id, fileName, mimeType, kind, filePath, bytes?.length, size];
}

/// Payload upload file — mobile dùng [filePath], web dùng [bytes].
class ChatUploadPayload extends Equatable {
  const ChatUploadPayload({
    required this.fileName,
    required this.mimeType,
    this.filePath,
    this.bytes,
  }) : assert(filePath != null || bytes != null, 'Cần filePath hoặc bytes');

  final String fileName;
  final String mimeType;
  final String? filePath;
  final Uint8List? bytes;

  @override
  List<Object?> get props => [fileName, mimeType, filePath, bytes?.length];
}

// ─── Chat settings (tên nhóm, ảnh, ghim) ─────────────────────────────────────

class ClassroomChatSettings extends Equatable {
  final String name;
  final String coverImageUrl;
  final ClassroomChatMessage? pinnedMessage;

  const ClassroomChatSettings({
    required this.name,
    this.coverImageUrl = '',
    this.pinnedMessage,
  });

  factory ClassroomChatSettings.fromJson(Map<String, dynamic> j) {
    ClassroomChatMessage? pinned;
    final rawPinned = j['pinnedMessage'];
    if (rawPinned is Map<String, dynamic>) {
      pinned = ClassroomChatMessage.fromJson(rawPinned);
    }
    return ClassroomChatSettings(
      name: j['name'] as String? ?? '',
      coverImageUrl: j['coverImageUrl'] as String? ?? '',
      pinnedMessage: pinned,
    );
  }

  @override
  List<Object?> get props => [name, coverImageUrl, pinnedMessage?.id];
}

/// Preview ngắn cho banner ghim / danh sách.
String classroomChatMessagePreview(ClassroomChatMessage m, {int maxLen = 80}) {
  if (m.isDeleted) return '[Tin nhắn đã bị xóa]';
  switch (m.type) {
    case ChatMessageType.text:
      final t = m.content.trim();
      if (t.isEmpty) return 'Tin nhắn';
      return t.length > maxLen ? '${t.substring(0, maxLen)}…' : t;
    case ChatMessageType.image:
      return '📷 Ảnh';
    case ChatMessageType.video:
      return '🎬 Video';
    case ChatMessageType.file:
      return '📎 ${m.media?.name.isNotEmpty == true ? m.media!.name : 'Tệp đính kèm'}';
  }
}
