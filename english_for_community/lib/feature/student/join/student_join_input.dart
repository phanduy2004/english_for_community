enum StudentJoinInputKind {
  empty,
  invalid,
  classInviteCode,
  classInviteToken,
  publicExamToken,
  examSession,
}

class StudentJoinInput {
  const StudentJoinInput._(this.kind, {this.value, this.sessionId});

  const StudentJoinInput.empty() : this._(StudentJoinInputKind.empty);
  const StudentJoinInput.invalid() : this._(StudentJoinInputKind.invalid);

  const StudentJoinInput.classInviteCode(String code)
      : this._(StudentJoinInputKind.classInviteCode, value: code);

  const StudentJoinInput.classInviteToken(String token)
      : this._(StudentJoinInputKind.classInviteToken, value: token);

  const StudentJoinInput.publicExamToken(String token)
      : this._(StudentJoinInputKind.publicExamToken, value: token);

  const StudentJoinInput.examSession(String sessionId)
      : this._(StudentJoinInputKind.examSession, sessionId: sessionId);

  final StudentJoinInputKind kind;
  final String? value;
  final String? sessionId;
}

/// Classroom invite codes use an unambiguous alphabet (no 0/O/1/I).
const _classInviteCodeChars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

StudentJoinInput parseStudentJoinInput(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return const StudentJoinInput.empty();

  final sessionInPath = RegExp(r'exam-session/([a-fA-F0-9]{24})').firstMatch(s);
  if (sessionInPath != null) {
    return StudentJoinInput.examSession(sessionInPath.group(1)!);
  }

  final uri = Uri.tryParse(s.contains('://') ? s : 'https://placeholder?$s');
  final queryToken = uri?.queryParameters['token']?.trim();
  if (queryToken != null && queryToken.isNotEmpty) {
    s = queryToken;
  } else if (s.contains('/')) {
    s = s.split('/').where((p) => p.trim().isNotEmpty).last.trim();
  }

  s = s.replaceAll(RegExp(r'\s+'), '');
  if (s.isEmpty) return const StudentJoinInput.invalid();

  if (RegExp(r'^[a-fA-F0-9]{48}$').hasMatch(s)) {
    return StudentJoinInput.classInviteToken(s);
  }
  if (RegExp(r'^[a-fA-F0-9]{36}$').hasMatch(s)) {
    return StudentJoinInput.publicExamToken(s);
  }
  if (RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(s)) {
    return StudentJoinInput.examSession(s);
  }
  if (RegExp(r'^[a-zA-Z0-9_-]{20,}$').hasMatch(s)) {
    return StudentJoinInput.publicExamToken(s);
  }

  final upper = s.toUpperCase();
  if (upper.length == 6 && _isClassInviteCode(upper)) {
    return StudentJoinInput.classInviteCode(upper);
  }
  if (upper.length <= 8 && RegExp(r'^[A-Z0-9]+$').hasMatch(upper)) {
    return StudentJoinInput.classInviteCode(upper);
  }

  return const StudentJoinInput.invalid();
}

bool _isClassInviteCode(String upper) {
  for (var i = 0; i < upper.length; i++) {
    if (!_classInviteCodeChars.contains(upper[i])) return false;
  }
  return true;
}
