import 'package:equatable/equatable.dart';

abstract class TeacherStudentLiveScreenEvent extends Equatable {
  const TeacherStudentLiveScreenEvent();

  @override
  List<Object?> get props => [];
}

class TeacherStudentLiveScreenStarted extends TeacherStudentLiveScreenEvent {
  const TeacherStudentLiveScreenStarted({
    required this.attemptId,
    this.initialLiveScreen,
  });

  final String attemptId;
  final Map<String, dynamic>? initialLiveScreen;

  @override
  List<Object?> get props => [attemptId, initialLiveScreen];
}

class TeacherStudentLiveScreenPayloadReceived extends TeacherStudentLiveScreenEvent {
  const TeacherStudentLiveScreenPayloadReceived(this.payload);

  final Map<String, dynamic> payload;

  @override
  List<Object?> get props => [payload];
}

class TeacherStudentLiveScreenStopped extends TeacherStudentLiveScreenEvent {
  const TeacherStudentLiveScreenStopped();
}
