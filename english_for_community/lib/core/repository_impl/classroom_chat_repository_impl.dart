import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:english_for_community/core/datasource/classroom_chat_remote_datasource.dart';
import 'package:english_for_community/core/entity/classroom_chat_entity.dart';
import 'package:english_for_community/core/model/either.dart';
import 'package:english_for_community/core/model/failure.dart';
import 'package:english_for_community/core/repository/classroom_chat_repository.dart';

class ClassroomChatRepositoryImpl implements ClassroomChatRepository {
  final ClassroomChatRemoteDataSource remote;

  ClassroomChatRepositoryImpl({required this.remote});

  String _errMsg(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['message']?.toString();
        if (msg != null && msg.isNotEmpty) return msg;
      }
      if (e.response?.statusCode != null) {
        return 'Lỗi máy chủ (${e.response!.statusCode})';
      }
      return e.message ?? 'Lỗi kết nối';
    }
    if (e is ArgumentError) {
      return e.message?.toString() ?? 'Dữ liệu file không hợp lệ';
    }
    final text = e.toString();
    if (text.startsWith('Exception: ')) return text.substring(11);
    return text;
  }

  @override
  Future<Either<Failure, ({List<ClassroomChatMessage> messages, bool hasMore, String? nextCursor})>>
      getMessages(String classroomId, {String? before, int limit = 30}) async {
    try {
      final raw = await remote.getMessages(classroomId, before: before, limit: limit);
      final list = (raw['messages'] as List?)
              ?.map((e) => ClassroomChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [];
      return Right((
        messages: list,
        hasMore: raw['hasMore'] as bool? ?? false,
        nextCursor: raw['nextCursor'] as String?,
      ));
    } catch (e) {
      return Left(ServerFailure(message: _errMsg(e)));
    }
  }

  @override
  Future<Either<Failure, ClassroomChatMessage>> sendMessage(
      String classroomId, Map<String, dynamic> body) async {
    try {
      final msg = await remote.sendMessage(classroomId, body);
      return Right(msg);
    } catch (e) {
      return Left(ServerFailure(message: _errMsg(e)));
    }
  }

  @override
  Future<Either<Failure, ClassroomChatMessage>> editMessage(
      String classroomId, String messageId, String newContent) async {
    try {
      final msg = await remote.editMessage(classroomId, messageId, newContent);
      return Right(msg);
    } catch (e) {
      return Left(ServerFailure(message: _errMsg(e)));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String classroomId, String messageId) async {
    try {
      await remote.deleteMessage(classroomId, messageId);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(message: _errMsg(e)));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> reactMessage(
      String classroomId, String messageId, String emoji) async {
    try {
      final result = await remote.reactMessage(classroomId, messageId, emoji);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: _errMsg(e)));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> uploadMedia(
    String classroomId, {
    String? filePath,
    Uint8List? bytes,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      final result = await remote.uploadMedia(
        classroomId,
        filePath: filePath,
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: _errMsg(e)));
    }
  }

  @override
  Future<Either<Failure, List<ChatMember>>> getChatMembers(String classroomId) async {
    try {
      final members = await remote.getChatMembers(classroomId);
      return Right(members);
    } catch (e) {
      return Left(ServerFailure(message: _errMsg(e)));
    }
  }

  @override
  Future<Either<Failure, ClassroomChatSettings>> getChatSettings(String classroomId) async {
    try {
      final settings = await remote.getChatSettings(classroomId);
      return Right(settings);
    } catch (e) {
      return Left(ServerFailure(message: _errMsg(e)));
    }
  }

  @override
  Future<Either<Failure, ({String name, String coverImageUrl})>> updateChatSettings(
    String classroomId, {
    String? name,
    String? coverImageUrl,
  }) async {
    try {
      final raw = await remote.updateChatSettings(
        classroomId,
        name: name,
        coverImageUrl: coverImageUrl,
      );
      return Right((
        name: raw['name'] as String? ?? '',
        coverImageUrl: raw['coverImageUrl'] as String? ?? '',
      ));
    } catch (e) {
      return Left(ServerFailure(message: _errMsg(e)));
    }
  }

  @override
  Future<Either<Failure, String>> uploadChatAvatar(
    String classroomId, {
    String? filePath,
    Uint8List? bytes,
    required String fileName,
  }) async {
    try {
      final raw = await remote.uploadChatAvatar(
        classroomId,
        filePath: filePath,
        bytes: bytes,
        fileName: fileName,
      );
      return Right(raw['coverImageUrl'] as String? ?? '');
    } catch (e) {
      return Left(ServerFailure(message: _errMsg(e)));
    }
  }

  @override
  Future<Either<Failure, ClassroomChatMessage?>> pinMessage(
    String classroomId,
    String messageId,
  ) async {
    try {
      final raw = await remote.pinMessage(classroomId, messageId);
      final pinnedRaw = raw['pinnedMessage'];
      if (pinnedRaw is Map) {
        return Right(ClassroomChatMessage.fromJson(Map<String, dynamic>.from(pinnedRaw)));
      }
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(message: _errMsg(e)));
    }
  }

  @override
  Future<Either<Failure, void>> unpinMessage(String classroomId) async {
    try {
      await remote.unpinMessage(classroomId);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(message: _errMsg(e)));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getChatInbox() async {
    try {
      final raw = await remote.getChatInbox();
      return Right(raw);
    } catch (e) {
      return Left(ServerFailure(message: _errMsg(e)));
    }
  }

  @override
  Future<Either<Failure, void>> markChatRead(String classroomId) async {
    try {
      await remote.markChatRead(classroomId);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(message: _errMsg(e)));
    }
  }

  @override
  Future<Either<Failure, void>> setChatMuted(String classroomId, bool muted) async {
    try {
      await remote.setChatMuted(classroomId, muted);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(message: _errMsg(e)));
    }
  }

  @override
  Future<Either<Failure, void>> setChatPinned(String classroomId, bool pinned) async {
    try {
      await remote.setChatPinned(classroomId, pinned);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(message: _errMsg(e)));
    }
  }
}
