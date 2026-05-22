import 'package:equatable/equatable.dart';

abstract class StudentClassesHubEvent extends Equatable {
  const StudentClassesHubEvent();

  @override
  List<Object?> get props => [];
}

class StudentClassesHubLoadRequested extends StudentClassesHubEvent {
  const StudentClassesHubLoadRequested();
}

class StudentClassesHubJoinByCodeRequested extends StudentClassesHubEvent {
  const StudentClassesHubJoinByCodeRequested(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

class StudentClassesHubJoinByTokenRequested extends StudentClassesHubEvent {
  const StudentClassesHubJoinByTokenRequested(this.token);

  final String token;

  @override
  List<Object?> get props => [token];
}
