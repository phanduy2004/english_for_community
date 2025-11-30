abstract class AiChatEvent {}

class SendMessageEvent extends AiChatEvent {
  final String message;
  SendMessageEvent(this.message);
}

class ClearChatEvent extends AiChatEvent {}