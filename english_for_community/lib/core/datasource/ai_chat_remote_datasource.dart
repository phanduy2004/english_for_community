import 'package:dio/dio.dart';
import '../../feature/home/bloc_ai/ai_chat_state.dart';

class AiChatRemoteDataSource {
  final Dio dio;

  AiChatRemoteDataSource({required this.dio});

  Future<String> askAi(String message, List<ChatMessageEntity> history) async {
    // Convert Entity sang Format JSON mà Google Gemini SDK yêu cầu
    // Cấu trúc: { "role": "user"|"model", "parts": [{ "text": "..." }] }
    final historyJson = history.map((msg) {
      return {
        "role": msg.isUser ? "user" : "model",
        "parts": [
          { "text": msg.text }
        ]
      };
    }).toList();

    final response = await dio.post(
      '/chat/ask', // Đảm bảo endpoint đúng với server
      data: {
        'message': message,
        'history': historyJson,
      },
    );

    // Trả về text trả lời từ server
    return response.data['reply'];
  }
}