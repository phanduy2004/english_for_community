import 'package:equatable/equatable.dart';

abstract class TeacherExamSessionConsoleEvent extends Equatable {
  const TeacherExamSessionConsoleEvent();

  @override
  List<Object?> get props => [];
}

class TeacherExamSessionConsoleStarted extends TeacherExamSessionConsoleEvent {
  const TeacherExamSessionConsoleStarted(this.assignmentId);

  final String assignmentId;

  @override
  List<Object?> get props => [assignmentId];
}

class TeacherExamSessionConsoleLobbyPayloadReceived extends TeacherExamSessionConsoleEvent {
  const TeacherExamSessionConsoleLobbyPayloadReceived(this.payload);

  final Map<String, dynamic> payload;

  @override
  List<Object?> get props => [payload];
}

class TeacherExamSessionConsoleLobbyApplied extends TeacherExamSessionConsoleEvent {
  const TeacherExamSessionConsoleLobbyApplied(this.payload);

  final Map<String, dynamic> payload;

  @override
  List<Object?> get props => [payload];
}

class TeacherExamSessionConsoleCreateRequested extends TeacherExamSessionConsoleEvent {
  const TeacherExamSessionConsoleCreateRequested();
}

class TeacherExamSessionConsoleStartRequested extends TeacherExamSessionConsoleEvent {
  const TeacherExamSessionConsoleStartRequested();
}

class TeacherExamSessionConsoleEndRequested extends TeacherExamSessionConsoleEvent {
  const TeacherExamSessionConsoleEndRequested();
}

class TeacherExamSessionConsoleKickRequested extends TeacherExamSessionConsoleEvent {
  const TeacherExamSessionConsoleKickRequested(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class TeacherExamSessionConsoleReloadRequested extends TeacherExamSessionConsoleEvent {
  const TeacherExamSessionConsoleReloadRequested();
}

class TeacherExamSessionConsoleStopped extends TeacherExamSessionConsoleEvent {
  const TeacherExamSessionConsoleStopped();
}
