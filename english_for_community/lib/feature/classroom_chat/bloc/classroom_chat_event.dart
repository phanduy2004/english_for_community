import 'package:equatable/equatable.dart';
import 'package:english_for_community/core/entity/classroom_chat_entity.dart';
import 'dart:typed_data';

abstract class ClassroomChatEvent extends Equatable {
  const ClassroomChatEvent();
  @override
  List<Object?> get props => [];
}

class ClassroomChatLoaded extends ClassroomChatEvent {
  const ClassroomChatLoaded();
}

class ClassroomChatLoadMore extends ClassroomChatEvent {
  const ClassroomChatLoadMore();
}

class ClassroomChatSendText extends ClassroomChatEvent {
  final String content;
  final ClassroomChatMessage? replyTo;
  final List<String> mentionIds;
  const ClassroomChatSendText({
    required this.content,
    this.replyTo,
    this.mentionIds = const [],
  });
  @override
  List<Object?> get props => [content, replyTo, mentionIds];
}

class ClassroomChatSendMedia extends ClassroomChatEvent {
  final String fileName;
  final String mimeType;
  final String? filePath;
  final Uint8List? bytes;
  final ClassroomChatMessage? replyTo;
  const ClassroomChatSendMedia({
    required this.fileName,
    required this.mimeType,
    this.filePath,
    this.bytes,
    this.replyTo,
  }) : assert(filePath != null || bytes != null, 'Cần filePath hoặc bytes');
  @override
  List<Object?> get props => [filePath, fileName, mimeType, bytes?.length, replyTo];
}

class ClassroomChatReact extends ClassroomChatEvent {
  final String messageId;
  final String emoji;
  const ClassroomChatReact({required this.messageId, required this.emoji});
  @override
  List<Object?> get props => [messageId, emoji];
}

class ClassroomChatDeleteMessage extends ClassroomChatEvent {
  final String messageId;
  const ClassroomChatDeleteMessage(this.messageId);
  @override
  List<Object?> get props => [messageId];
}

class ClassroomChatEditMessage extends ClassroomChatEvent {
  final String messageId;
  final String newContent;
  const ClassroomChatEditMessage({required this.messageId, required this.newContent});
  @override
  List<Object?> get props => [messageId, newContent];
}

class ClassroomChatMembersLoaded extends ClassroomChatEvent {
  const ClassroomChatMembersLoaded();
}

class ClassroomChatSettingsLoaded extends ClassroomChatEvent {
  const ClassroomChatSettingsLoaded();
}

class ClassroomChatUpdateGroupName extends ClassroomChatEvent {
  final String name;
  const ClassroomChatUpdateGroupName(this.name);
  @override
  List<Object?> get props => [name];
}

class ClassroomChatUploadGroupAvatar extends ClassroomChatEvent {
  final String fileName;
  final String? filePath;
  final Uint8List? bytes;
  const ClassroomChatUploadGroupAvatar({
    required this.fileName,
    this.filePath,
    this.bytes,
  }) : assert(filePath != null || bytes != null, 'Cần filePath hoặc bytes');
  @override
  List<Object?> get props => [filePath, fileName, bytes?.length];
}

class ClassroomChatPinMessage extends ClassroomChatEvent {
  final String messageId;
  const ClassroomChatPinMessage(this.messageId);
  @override
  List<Object?> get props => [messageId];
}

class ClassroomChatUnpinMessage extends ClassroomChatEvent {
  const ClassroomChatUnpinMessage();
}

class ClassroomChatDismissError extends ClassroomChatEvent {
  const ClassroomChatDismissError();
}

// Socket-driven events
class ClassroomChatSocketMessage extends ClassroomChatEvent {
  final ClassroomChatMessage message;
  const ClassroomChatSocketMessage(this.message);
  @override
  List<Object?> get props => [message.id];
}

class ClassroomChatSocketReactUpdate extends ClassroomChatEvent {
  final String messageId;
  final List<ChatReaction> reactions;
  const ClassroomChatSocketReactUpdate({required this.messageId, required this.reactions});
  @override
  List<Object?> get props => [messageId, reactions];
}

class ClassroomChatSocketDeleted extends ClassroomChatEvent {
  final String messageId;
  const ClassroomChatSocketDeleted(this.messageId);
  @override
  List<Object?> get props => [messageId];
}

class ClassroomChatSocketEdited extends ClassroomChatEvent {
  final ClassroomChatMessage message;
  const ClassroomChatSocketEdited(this.message);
  @override
  List<Object?> get props => [message.id];
}

class ClassroomChatSocketTyping extends ClassroomChatEvent {
  final String userId;
  final bool isTyping;
  const ClassroomChatSocketTyping({required this.userId, required this.isTyping});
  @override
  List<Object?> get props => [userId, isTyping];
}

class ClassroomChatSocketPinnedUpdated extends ClassroomChatEvent {
  final ClassroomChatMessage? pinnedMessage;
  const ClassroomChatSocketPinnedUpdated({this.pinnedMessage});
  @override
  List<Object?> get props => [pinnedMessage?.id];
}

class ClassroomChatSocketSettingsUpdated extends ClassroomChatEvent {
  final String name;
  final String coverImageUrl;
  const ClassroomChatSocketSettingsUpdated({
    required this.name,
    required this.coverImageUrl,
  });
  @override
  List<Object?> get props => [name, coverImageUrl];
}
