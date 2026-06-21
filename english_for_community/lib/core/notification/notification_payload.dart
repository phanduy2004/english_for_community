import 'dart:convert';

/// Build a JSON payload for local/FCM notifications with deeplink fields.
String? buildNotificationPayload(Map<String, dynamic> map) {
  Map<String, dynamic>? data;
  if (map['data'] is Map) {
    data = Map<String, dynamic>.from(map['data'] as Map);
  }
  data ??= <String, dynamic>{};

  final type = map['type']?.toString();
  if (type != null && type.isNotEmpty) {
    data['type'] ??= type;
  }

  for (final key in [
    'classroomId',
    'assignmentId',
    'attemptId',
    'sessionId',
    'listeningId',
    'wordId',
    'commentId',
    'cueId',
    'audioUrl',
  ]) {
    if (map[key] != null && data[key] == null) {
      data[key] = map[key];
    }
  }

  if (data.isEmpty && type == null) return null;
  return jsonEncode(data);
}
