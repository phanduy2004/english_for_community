class ClassroomChatRoomItem {
  const ClassroomChatRoomItem({
    required this.id,
    required this.name,
    this.coverImageUrl,
    this.memberCount,
    this.lastMessagePreview,
    this.lastSenderName,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  final String id;
  final String name;
  final String? coverImageUrl;
  final int? memberCount;
  final String? lastMessagePreview;
  final String? lastSenderName;
  final DateTime? lastMessageAt;
  final int unreadCount;

  bool get hasUnread => unreadCount > 0;

  ClassroomChatRoomItem copyWith({
    String? name,
    String? coverImageUrl,
    int? memberCount,
    String? lastMessagePreview,
    String? lastSenderName,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool clearLastMessage = false,
  }) =>
      ClassroomChatRoomItem(
        id: id,
        name: name ?? this.name,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        memberCount: memberCount ?? this.memberCount,
        lastMessagePreview:
            clearLastMessage ? null : lastMessagePreview ?? this.lastMessagePreview,
        lastSenderName: clearLastMessage ? null : lastSenderName ?? this.lastSenderName,
        lastMessageAt: clearLastMessage ? null : lastMessageAt ?? this.lastMessageAt,
        unreadCount: unreadCount ?? this.unreadCount,
      );
}

class ClassroomChatSession {
  ClassroomChatSession({
    required this.classroomId,
    required this.classroomName,
    this.minimized = false,
  });

  final String classroomId;
  final String classroomName;
  bool minimized;
}
