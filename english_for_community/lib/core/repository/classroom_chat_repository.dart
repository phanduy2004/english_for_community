import 'package:english_for_community/core/entity/classroom_chat_entity.dart';
import 'package:english_for_community/core/model/either.dart';
import 'package:english_for_community/core/model/failure.dart';
import 'dart:typed_data';

abstract class ClassroomChatRepository {
  Future<Either<Failure, ({List<ClassroomChatMessage> messages, bool hasMore, String? nextCursor})>>
      getMessages(String classroomId, {String? before, int limit});

  Future<Either<Failure, ClassroomChatMessage>> sendMessage(
      String classroomId, Map<String, dynamic> body);

  Future<Either<Failure, ClassroomChatMessage>> editMessage(
      String classroomId, String messageId, String newContent);

  Future<Either<Failure, void>> deleteMessage(String classroomId, String messageId);

  Future<Either<Failure, Map<String, dynamic>>> reactMessage(
      String classroomId, String messageId, String emoji);

  Future<Either<Failure, Map<String, dynamic>>> uploadMedia(
    String classroomId, {
    String? filePath,
    Uint8List? bytes,
    required String fileName,
    required String mimeType,
  });

  Future<Either<Failure, List<ChatMember>>> getChatMembers(String classroomId);

  Future<Either<Failure, ClassroomChatSettings>> getChatSettings(String classroomId);

  Future<Either<Failure, ({String name, String coverImageUrl})>> updateChatSettings(
    String classroomId, {
    String? name,
    String? coverImageUrl,
  });

  Future<Either<Failure, String>> uploadChatAvatar(
    String classroomId, {
    String? filePath,
    Uint8List? bytes,
    required String fileName,
  });

  Future<Either<Failure, ClassroomChatMessage?>> pinMessage(String classroomId, String messageId);

  Future<Either<Failure, void>> unpinMessage(String classroomId);

  Future<Either<Failure, Map<String, dynamic>>> getChatInbox();

  Future<Either<Failure, void>> markChatRead(String classroomId);
}
