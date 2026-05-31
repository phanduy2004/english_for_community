import 'package:english_for_community/feature/teacher/bloc/grading_hub/teacher_grading_hub_filter.dart';
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
  const TeacherGradingHubReleaseRequested(this.attemptId, {this.resultsDetailLevel});

  final String attemptId;
  final String? resultsDetailLevel;

  @override
  List<Object?> get props => [attemptId, resultsDetailLevel];
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

class TeacherGradingHubFilterChanged extends TeacherGradingHubEvent {
  const TeacherGradingHubFilterChanged(this.filter);

  final TeacherGradingHubFilter filter;

  @override
  List<Object?> get props => [filter];
}
