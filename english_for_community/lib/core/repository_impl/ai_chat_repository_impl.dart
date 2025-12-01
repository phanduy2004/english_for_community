import 'package:dio/dio.dart';
import '../../core/datasource/ai_chat_remote_datasource.dart';
import '../../core/model/either.dart';
import '../../core/model/failure.dart';
import '../../feature/home/bloc_ai/ai_chat_state.dart';
import '../repository/ai_chat_repository.dart';

class AiChatRepositoryImpl implements AiChatRepository {
  final AiChatRemoteDataSource remoteDataSource;

  AiChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, String>> askAi(String message, List<ChatMessageEntity> history) async {
    try {
      // Truyền trực tiếp List<ChatMessageEntity> xuống RemoteDataSource
      final result = await remoteDataSource.askAi(message, history);
      return Right(result);
    } on DioException catch (e) {
      return Left(AiChatFailure(message: e.message ?? "Lỗi kết nối mạng"));
    } catch (e) {
      return Left(AiChatFailure(message: e.toString()));
    }
  }
}