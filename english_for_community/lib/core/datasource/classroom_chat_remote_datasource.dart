import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:english_for_community/core/entity/classroom_chat_entity.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Web không hỗ trợ [MultipartFile.fromFile] — luôn gửi bytes.
Future<MultipartFile> _chatMultipartFile({
  required String fileName,
  String? filePath,
  Uint8List? bytes,
}) async {
  if (bytes != null) {
    return MultipartFile.fromBytes(bytes, filename: fileName);
  }
  if (filePath == null) {
    throw ArgumentError('Cần bytes hoặc filePath để upload');
  }
  if (kIsWeb) {
    final data = await XFile(filePath).readAsBytes();
    return MultipartFile.fromBytes(data, filename: fileName);
  }
  return MultipartFile.fromFile(filePath, filename: fileName);
}

/// Đọc bytes từ [PlatformFile] (web có thể trả [readStream] thay vì [bytes]).
Future<Uint8List?> platformFileBytes(PlatformFile file) async {
  if (file.bytes != null && file.bytes!.isNotEmpty) return file.bytes;
  final stream = file.readStream;
  if (stream != null) {
    final chunks = await stream.toList();
    if (chunks.isEmpty) return null;
    var total = 0;
    for (final chunk in chunks) {
      total += chunk.length;
    }
    final merged = Uint8List(total);
    var offset = 0;
    for (final chunk in chunks) {
      merged.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return merged;
  }
  return null;
}

class ClassroomChatRemoteDataSource {
  final Dio dio;

  ClassroomChatRemoteDataSource({required this.dio});

  String _base(String classroomId) => '/classroom-chat/$classroomId';

  Future<Map<String, dynamic>> getMessages(
    String classroomId, {
    String? before,
    int limit = 30,
  }) async {
    final res = await dio.get(
      '${_base(classroomId)}/messages',
      queryParameters: {
        if (before != null) 'before': before,
        'limit': limit,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<ClassroomChatMessage> sendMessage(
    String classroomId,
    Map<String, dynamic> body,
  ) async {
    final res = await dio.post(
      '${_base(classroomId)}/messages',
      data: body,
    );
    return ClassroomChatMessage.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<ClassroomChatMessage> editMessage(
    String classroomId,
    String messageId,
    String newContent,
  ) async {
    final res = await dio.patch(
      '${_base(classroomId)}/messages/$messageId',
      data: {'content': newContent},
    );
    return ClassroomChatMessage.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> deleteMessage(String classroomId, String messageId) async {
    await dio.delete('${_base(classroomId)}/messages/$messageId');
  }

  Future<Map<String, dynamic>> reactMessage(
    String classroomId,
    String messageId,
    String emoji,
  ) async {
    final res = await dio.post(
      '${_base(classroomId)}/messages/$messageId/react',
      data: {'emoji': emoji},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> uploadMedia(
    String classroomId, {
    String? filePath,
    Uint8List? bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final filePart = await _chatMultipartFile(
      fileName: fileName,
      filePath: filePath,
      bytes: bytes,
    );
    final formData = FormData.fromMap({'file': filePart});
    final res = await dio.post(
      '${_base(classroomId)}/upload',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<List<ChatMember>> getChatMembers(String classroomId) async {
    final res = await dio.get('${_base(classroomId)}/members');
    final list = res.data as List;
    return list
        .map((e) => ChatMember.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ClassroomChatSettings> getChatSettings(String classroomId) async {
    final res = await dio.get('${_base(classroomId)}/settings');
    return ClassroomChatSettings.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<Map<String, dynamic>> updateChatSettings(
    String classroomId, {
    String? name,
    String? coverImageUrl,
  }) async {
    final res = await dio.patch(
      '${_base(classroomId)}/settings',
      data: {
        if (name != null) 'name': name,
        if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> uploadChatAvatar(
    String classroomId, {
    String? filePath,
    Uint8List? bytes,
    required String fileName,
  }) async {
    final filePart = await _chatMultipartFile(
      fileName: fileName,
      filePath: filePath,
      bytes: bytes,
    );
    final formData = FormData.fromMap({'file': filePart});
    final res = await dio.post(
      '${_base(classroomId)}/avatar',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 1),
      ),
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> pinMessage(String classroomId, String messageId) async {
    final res = await dio.post('${_base(classroomId)}/messages/$messageId/pin');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> unpinMessage(String classroomId) async {
    final res = await dio.delete('${_base(classroomId)}/pin');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> getChatInbox() async {
    final res = await dio.get('/classroom-chat/inbox');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> markChatRead(String classroomId) async {
    await dio.post('${_base(classroomId)}/read');
  }
}
