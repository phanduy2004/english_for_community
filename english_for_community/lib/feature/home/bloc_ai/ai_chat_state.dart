import 'package:equatable/equatable.dart';

enum AiChatStatus { initial, loading, success, error }

class ChatMessageEntity extends Equatable {
  final String text;
  final bool isUser;

  const ChatMessageEntity({required this.text, required this.isUser});

  @override
  List<Object?> get props => [text, isUser];
}

class AiChatState extends Equatable {
  final AiChatStatus status;
  final List<ChatMessageEntity> messages;
  final String? errorMessage;

  const AiChatState({
    this.status = AiChatStatus.initial,
    this.messages = const [],
    this.errorMessage,
  });

  AiChatState copyWith({
    AiChatStatus? status,
    List<ChatMessageEntity>? messages,
    String? errorMessage,
  }) {
    return AiChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, messages, errorMessage];
}