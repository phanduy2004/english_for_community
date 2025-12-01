import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repository/ai_chat_repository.dart';
import 'ai_chat_event.dart';
import 'ai_chat_state.dart';

class AiChatBloc extends Bloc<AiChatEvent, AiChatState> {
  final AiChatRepository aiChatRepository;

  AiChatBloc({required this.aiChatRepository})
      : super(const AiChatState(messages: [
    ChatMessageEntity(
        text: "Chào bạn! Tôi là trợ lý AI. Tôi có thể giúp gì?",
        isUser: false)
  ])) {
    on<SendMessageEvent>(_onSendMessage);
    on<ClearChatEvent>(_onClearChat);
  }

  Future<void> _onSendMessage(
      SendMessageEvent event, Emitter<AiChatState> emit) async {

    // 1. Lấy lịch sử CŨ (chưa bao gồm tin nhắn mới đang gửi) để gửi cho AI làm context
    final historyForApi = List<ChatMessageEntity>.from(state.messages);

    // 2. Tạo danh sách MỚI để cập nhật UI (bao gồm tin nhắn user vừa nhập)
    final newMessagesForUi = List<ChatMessageEntity>.from(state.messages);
    newMessagesForUi.add(ChatMessageEntity(text: event.message, isUser: true));

    // Emit trạng thái Loading để UI hiển thị tin nhắn user và loading indicator
    emit(state.copyWith(
      status: AiChatStatus.loading,
      messages: newMessagesForUi,
    ));

    // 3. Gọi Repository
    final result = await aiChatRepository.askAi(event.message, historyForApi);

    result.fold(
          (failure) {
        // Thêm tin nhắn lỗi
        final errorMessages = List<ChatMessageEntity>.from(state.messages);
        errorMessages.add(ChatMessageEntity(
            text: "Lỗi: ${failure.message}", isUser: false));

        emit(state.copyWith(
            status: AiChatStatus.error, messages: errorMessages));
      },
          (reply) {
        // Thêm tin nhắn trả lời từ AI
        final successMessages = List<ChatMessageEntity>.from(state.messages);
        successMessages.add(ChatMessageEntity(text: reply, isUser: false));

        emit(state.copyWith(
            status: AiChatStatus.success, messages: successMessages));
      },
    );
  }

  void _onClearChat(ClearChatEvent event, Emitter<AiChatState> emit) {
    // Reset về trạng thái ban đầu
    emit(const AiChatState(
        status: AiChatStatus.initial,
        messages: [
          ChatMessageEntity(
              text: "Chào bạn! Tôi là trợ lý AI. Tôi có thể giúp gì?", isUser: false)
        ]));
  }
}