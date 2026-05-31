import 'package:english_for_community/feature/teacher/bloc/exam_session_console/teacher_exam_session_console_state.dart';

/// Merges socket/API lobby payload into console state fields.
TeacherExamSessionConsoleState applyLobbyPayload(
  TeacherExamSessionConsoleState state,
  Map<String, dynamic> p,
) {
  var participants = state.participants;
  final raw = p['participants'];
  if (raw is List) {
    participants = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  var joinedCount = state.joinedCount;
  final jc = p['joinedCount'];
  if (jc is num) {
    joinedCount = jc.toInt();
  } else {
    joinedCount = participants.length;
  }

  var readyCount = state.readyCount;
  final rc = p['readyCount'];
  if (rc is num) {
    readyCount = rc.toInt();
  } else {
    readyCount = participants.where((x) => x['ready'] == true).length;
  }

  var session = state.session != null ? Map<String, dynamic>.from(state.session!) : <String, dynamic>{};
  final st = p['status']?.toString();
  if (st != null) session['status'] = st;
  final room = p['roomCode'];
  if (room is String && room.isNotEmpty) session['roomCode'] = room;
  final created = p['createdAt'];
  if (created != null) session['createdAt'] = created;
  for (final key in ['startedAt', 'endedAt', 'scheduledEndAt', 'hardEndAt', 'timeLimitSeconds']) {
    final v = p[key];
    if (v != null) session[key] = v;
  }

  var assignmentContext = state.assignmentContext;
  final ctx = p['context'];
  if (ctx is Map) assignmentContext = Map<String, dynamic>.from(ctx);

  return state.copyWith(
    participants: participants,
    joinedCount: joinedCount,
    readyCount: readyCount,
    session: session.isEmpty && state.session == null ? null : session,
    assignmentContext: assignmentContext,
  );
}
