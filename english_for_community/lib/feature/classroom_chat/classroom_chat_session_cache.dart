import 'dart:async';

import 'package:english_for_community/core/entity/classroom_chat_entity.dart';
import 'package:english_for_community/core/repository/classroom_chat_repository.dart';

/// Cache phiên chat trong bộ nhớ — mở lại hội thoại hiển thị tin nhắn ngay.
class ClassroomChatSessionCache {
  ClassroomChatSessionCache._();

  static final Map<String, _CachedChatSession> _sessions = {};
  static final Set<String> _prefetching = {};

  static _CachedChatSession? peek(String classroomId) => _sessions[classroomId];

  static void put({
    required String classroomId,
    required List<ClassroomChatMessage> messages,
    required bool hasMore,
    String? nextCursor,
    String? coverImageUrl,
    String? groupName,
    List<ChatMember> members = const [],
  }) {
    if (classroomId.isEmpty) return;
    _sessions[classroomId] = _CachedChatSession(
      messages: List<ClassroomChatMessage>.from(messages),
      members: List<ChatMember>.from(members),
      hasMore: hasMore,
      nextCursor: nextCursor,
      coverImageUrl: coverImageUrl,
      groupName: groupName,
      cachedAt: DateTime.now(),
    );
  }

  static void seedMeta({
    required String classroomId,
    String? coverImageUrl,
    String? groupName,
  }) {
    if (classroomId.isEmpty) return;
    final existing = _sessions[classroomId];
    if (existing != null) {
      _sessions[classroomId] = existing.copyWith(
        coverImageUrl: coverImageUrl ?? existing.coverImageUrl,
        groupName: groupName ?? existing.groupName,
      );
      return;
    }
    _sessions[classroomId] = _CachedChatSession(
      messages: const [],
      hasMore: false,
      coverImageUrl: coverImageUrl,
      groupName: groupName,
      cachedAt: DateTime.now(),
    );
  }

  /// Tải tin nhắn nền khi user chuẩn bị mở hội thoại.
  static void prefetch({
    required String classroomId,
    required ClassroomChatRepository repo,
    String? coverImageUrl,
    String? groupName,
  }) {
    if (classroomId.isEmpty) return;
    seedMeta(
      classroomId: classroomId,
      coverImageUrl: coverImageUrl,
      groupName: groupName,
    );
    final cached = peek(classroomId);
    if (cached != null && cached.messages.isNotEmpty) return;
    if (_prefetching.contains(classroomId)) return;

    _prefetching.add(classroomId);
    unawaited(() async {
      try {
        final msgResult = await repo.getMessages(classroomId, limit: 25);
        final memResult = await repo.getChatMembers(classroomId);
        var members = peek(classroomId)?.members ?? const <ChatMember>[];
        memResult.fold((_) {}, (m) => members = m);
        msgResult.fold((_) {}, (r) {
          put(
            classroomId: classroomId,
            messages: r.messages,
            members: members,
            hasMore: r.hasMore,
            nextCursor: r.nextCursor,
            coverImageUrl: coverImageUrl ?? peek(classroomId)?.coverImageUrl,
            groupName: groupName ?? peek(classroomId)?.groupName,
          );
        });
      } finally {
        _prefetching.remove(classroomId);
      }
    }());
  }
}

class _CachedChatSession {
  const _CachedChatSession({
    required this.messages,
    this.members = const [],
    required this.hasMore,
    this.nextCursor,
    this.coverImageUrl,
    this.groupName,
    required this.cachedAt,
  });

  final List<ClassroomChatMessage> messages;
  final List<ChatMember> members;
  final bool hasMore;
  final String? nextCursor;
  final String? coverImageUrl;
  final String? groupName;
  final DateTime cachedAt;

  _CachedChatSession copyWith({
    List<ClassroomChatMessage>? messages,
    List<ChatMember>? members,
    bool? hasMore,
    String? nextCursor,
    String? coverImageUrl,
    String? groupName,
    DateTime? cachedAt,
  }) =>
      _CachedChatSession(
        messages: messages ?? this.messages,
        members: members ?? this.members,
        hasMore: hasMore ?? this.hasMore,
        nextCursor: nextCursor ?? this.nextCursor,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        groupName: groupName ?? this.groupName,
        cachedAt: cachedAt ?? this.cachedAt,
      );
}
