import 'package:equatable/equatable.dart';

abstract class TeacherExamsListEvent extends Equatable {
  const TeacherExamsListEvent();

  @override
  List<Object?> get props => [];
}

class TeacherExamsListLoadRequested extends TeacherExamsListEvent {
  const TeacherExamsListLoadRequested();
}

class TeacherExamsListDuplicateRequested extends TeacherExamsListEvent {
  const TeacherExamsListDuplicateRequested(this.examId);

  final String examId;

  @override
  List<Object?> get props => [examId];
}

class TeacherExamsListArchiveRequested extends TeacherExamsListEvent {
  const TeacherExamsListArchiveRequested(this.examId);

  final String examId;

  @override
  List<Object?> get props => [examId];
}

class TeacherExamsListRestoreRequested extends TeacherExamsListEvent {
  const TeacherExamsListRestoreRequested(this.examId);

  final String examId;

  @override
  List<Object?> get props => [examId];
}

class TeacherExamsListDeleteRequested extends TeacherExamsListEvent {
  const TeacherExamsListDeleteRequested(this.examId);

  final String examId;

  @override
  List<Object?> get props => [examId];
}

class TeacherExamsListPublishRequested extends TeacherExamsListEvent {
  const TeacherExamsListPublishRequested(this.examId);

  final String examId;

  @override
  List<Object?> get props => [examId];
}
