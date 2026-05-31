import 'package:equatable/equatable.dart';

abstract class TeacherGradebookEvent extends Equatable {
  const TeacherGradebookEvent();

  @override
  List<Object?> get props => [];
}

class TeacherGradebookLoadRequested extends TeacherGradebookEvent {
  const TeacherGradebookLoadRequested();
}

class TeacherGradebookExportCsvRequested extends TeacherGradebookEvent {
  const TeacherGradebookExportCsvRequested();
}
