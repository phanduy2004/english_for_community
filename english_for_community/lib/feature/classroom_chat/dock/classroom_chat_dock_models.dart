class ClassroomChatRoomItem {
  const ClassroomChatRoomItem({
    required this.id,
    required this.name,
    this.coverImageUrl,
    this.memberCount,
    this.lastMessagePreview,
    this.lastSenderName,
    this.lastMessageType,
    this.lastMessageAt,
    this.pinnedAt,
    this.muted = false,
    this.online = false,
    this.unreadCount = 0,
  });

  final String id;
  final String name;
  final String? coverImageUrl;
  final int? memberCount;
  final String? lastMessagePreview;
  final String? lastSenderName;

  /// Loại tin cuối: `text` | `image` | `video` | `file` (để hiện icon prefix).
  final String? lastMessageType;
  final DateTime? lastMessageAt;

  /// Ghim hội thoại (per-user); null = không ghim.
  final DateTime? pinnedAt;

  /// Tắt thông báo hội thoại (per-user).
  final bool muted;

  /// Có thành viên khác đang online (tính lúc tải inbox).
  final bool online;
  final int unreadCount;

  bool get hasUnread => unreadCount > 0;
  bool get isPinned => pinnedAt != null;

  ClassroomChatRoomItem copyWith({
    String? name,
    String? coverImageUrl,
    int? memberCount,
    String? lastMessagePreview,
    String? lastSenderName,
    String? lastMessageType,
    DateTime? lastMessageAt,
    DateTime? pinnedAt,
    bool? muted,
    bool? online,
    int? unreadCount,
    bool clearLastMessage = false,
    bool clearPinned = false,
  }) =>
      ClassroomChatRoomItem(
        id: id,
        name: name ?? this.name,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        memberCount: memberCount ?? this.memberCount,
        lastMessagePreview:
            clearLastMessage ? null : lastMessagePreview ?? this.lastMessagePreview,
        lastSenderName: clearLastMessage ? null : lastSenderName ?? this.lastSenderName,
        lastMessageType:
            clearLastMessage ? null : lastMessageType ?? this.lastMessageType,
        lastMessageAt: clearLastMessage ? null : lastMessageAt ?? this.lastMessageAt,
        pinnedAt: clearPinned ? null : pinnedAt ?? this.pinnedAt,
        muted: muted ?? this.muted,
        online: online ?? this.online,
        unreadCount: unreadCount ?? this.unreadCount,
      );
}

class ClassroomChatSession {
  ClassroomChatSession({
    required this.classroomId,
    required this.classroomName,
    this.coverImageUrl,
    this.minimized = false,
  });

  final String classroomId;
  final String classroomName;
  final String? coverImageUrl;
  bool minimized;
}
