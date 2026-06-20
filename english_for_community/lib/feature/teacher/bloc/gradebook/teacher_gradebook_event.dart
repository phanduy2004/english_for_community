import 'package:english_for_community/feature/teacher/bloc/gradebook/teacher_gradebook_derived.dart';
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

class TeacherGradebookSearchChanged extends TeacherGradebookEvent {
  const TeacherGradebookSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class TeacherGradebookModeFilterChanged extends TeacherGradebookEvent {
  const TeacherGradebookModeFilterChanged(this.modeFilter);

  final String? modeFilter;

  @override
  List<Object?> get props => [modeFilter];
}

class TeacherGradebookSortChanged extends TeacherGradebookEvent {
  const TeacherGradebookSortChanged(this.sort);

  final TeacherGradebookSort sort;

  @override
  List<Object?> get props => [sort];
}

class TeacherGradebookHideEmptyChanged extends TeacherGradebookEvent {
  const TeacherGradebookHideEmptyChanged(this.hideEmpty);

  final bool hideEmpty;

  @override
  List<Object?> get props => [hideEmpty];
}
