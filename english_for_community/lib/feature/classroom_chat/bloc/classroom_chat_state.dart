import 'package:equatable/equatable.dart';
import 'package:english_for_community/core/entity/classroom_chat_entity.dart';

enum ClassroomChatStatus { initial, loading, ready, loadingMore, error }

class ClassroomChatState extends Equatable {
  final ClassroomChatStatus status;
  final List<ClassroomChatMessage> messages;
  final List<ChatMember> members;
  final bool hasMore;
  final String? nextCursor;
  final String? errorMessage;
  final bool isSending;
  final bool isUploading;
  /// userId -> true/false typing state
  final Map<String, bool> typingUsers;
  final String? groupName;
  final String? coverImageUrl;
  final ClassroomChatMessage? pinnedMessage;
  final bool isUpdatingSettings;

  const ClassroomChatState({
    this.status = ClassroomChatStatus.initial,
    this.messages = const [],
    this.members = const [],
    this.hasMore = false,
    this.nextCursor,
    this.errorMessage,
    this.isSending = false,
    this.isUploading = false,
    this.typingUsers = const {},
    this.groupName,
    this.coverImageUrl,
    this.pinnedMessage,
    this.isUpdatingSettings = false,
  });

  ClassroomChatState copyWith({
    ClassroomChatStatus? status,
    List<ClassroomChatMessage>? messages,
    List<ChatMember>? members,
    bool? hasMore,
    String? nextCursor,
    String? errorMessage,
    bool clearError = false,
    bool? isSending,
    bool? isUploading,
    Map<String, bool>? typingUsers,
    String? groupName,
    String? coverImageUrl,
    ClassroomChatMessage? pinnedMessage,
    bool clearPinned = false,
    bool? isUpdatingSettings,
  }) =>
      ClassroomChatState(
        status: status ?? this.status,
        messages: messages ?? this.messages,
        members: members ?? this.members,
        hasMore: hasMore ?? this.hasMore,
        nextCursor: nextCursor ?? this.nextCursor,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
        isSending: isSending ?? this.isSending,
        isUploading: isUploading ?? this.isUploading,
        typingUsers: typingUsers ?? this.typingUsers,
        groupName: groupName ?? this.groupName,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        pinnedMessage: clearPinned ? null : pinnedMessage ?? this.pinnedMessage,
        isUpdatingSettings: isUpdatingSettings ?? this.isUpdatingSettings,
      );

  String displayName(String fallback) =>
      (groupName != null && groupName!.trim().isNotEmpty) ? groupName!.trim() : fallback;

  bool isClassOwner(String userId) {
    final uid = userId.trim();
    if (uid.isEmpty) return false;
    final me = members.where((m) => m.id.trim() == uid);
    if (me.isEmpty) return false;
    return me.first.isClassOwner;
  }

  /// Members who are currently typing (excluding self).
  List<ChatMember> typingMembers(String selfId) => members
      .where((m) => m.id != selfId && typingUsers[m.id] == true)
      .toList();

  @override
  List<Object?> get props => [
        status,
        messages,
        members,
        hasMore,
        nextCursor,
        errorMessage,
        isSending,
        isUploading,
        typingUsers,
        groupName,
        coverImageUrl,
        pinnedMessage?.id,
        isUpdatingSettings,
      ];
}
