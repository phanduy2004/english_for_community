import 'package:equatable/equatable.dart';

abstract class TeacherGradingHubEvent extends Equatable {
  const TeacherGradingHubEvent();

  @override
  List<Object?> get props => [];
}

class TeacherGradingHubLoadRequested extends TeacherGradingHubEvent {
  const TeacherGradingHubLoadRequested();
}

class TeacherGradingHubRunAiRequested extends TeacherGradingHubEvent {
  const TeacherGradingHubRunAiRequested(this.attemptId);

  final String attemptId;

  @override
  List<Object?> get props => [attemptId];
}

class TeacherGradingHubReleaseRequested extends TeacherGradingHubEvent {
  const TeacherGradingHubReleaseRequested(this.attemptId);

  final String attemptId;

  @override
  List<Object?> get props => [attemptId];
}

class TeacherGradingHubBatchAiRequested extends TeacherGradingHubEvent {
  const TeacherGradingHubBatchAiRequested();
}

class TeacherGradingHubBatchReleaseRequested extends TeacherGradingHubEvent {
  const TeacherGradingHubBatchReleaseRequested();
}

class TeacherGradingHubBatchFinalizeRequested extends TeacherGradingHubEvent {
  const TeacherGradingHubBatchFinalizeRequested();
}
