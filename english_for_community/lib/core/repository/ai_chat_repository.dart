// Trong file abstract class AiChatRepository
import '../../core/model/either.dart';
import '../../core/model/failure.dart';
import '../../feature/home/bloc_ai/ai_chat_state.dart'; // Import Entity

abstract class AiChatRepository {
  // Sửa List<dynamic> thành List<ChatMessageEntity>
  Future<Either<Failure, String>> askAi(String message, List<ChatMessageEntity> history);
}