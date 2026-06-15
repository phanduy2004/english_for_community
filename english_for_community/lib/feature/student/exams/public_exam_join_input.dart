import 'package:english_for_community/feature/student/join/student_join_input.dart';

enum PublicJoinInputKind { empty, token, sessionLink, invalid }

class PublicJoinInput {
  const PublicJoinInput._(this.kind, {this.token, this.sessionId});

  const PublicJoinInput.empty() : this._(PublicJoinInputKind.empty);
  const PublicJoinInput.invalid() : this._(PublicJoinInputKind.invalid);

  const PublicJoinInput.token(String value)
      : this._(PublicJoinInputKind.token, token: value);

  const PublicJoinInput.sessionLink(String sessionId)
      : this._(PublicJoinInputKind.sessionLink, sessionId: sessionId);

  final PublicJoinInputKind kind;
  final String? token;
  final String? sessionId;
}

/// Legacy wrapper — prefer [parseStudentJoinInput].
PublicJoinInput parsePublicJoinInput(String raw) {
  final input = parseStudentJoinInput(raw);
  switch (input.kind) {
    case StudentJoinInputKind.empty:
      return const PublicJoinInput.empty();
    case StudentJoinInputKind.examSession:
      return PublicJoinInput.sessionLink(input.sessionId!);
    case StudentJoinInputKind.publicExamToken:
      return PublicJoinInput.token(input.value!);
    case StudentJoinInputKind.classInviteCode:
    case StudentJoinInputKind.classInviteToken:
    case StudentJoinInputKind.invalid:
      return const PublicJoinInput.invalid();
  }
}
