import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/feature/teacher/bloc/gradebook/teacher_gradebook_event.dart';
import 'package:english_for_community/feature/teacher/bloc/gradebook/teacher_gradebook_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherGradebookBloc extends Bloc<TeacherGradebookEvent, TeacherGradebookState> {
  TeacherGradebookBloc({
    required this.repository,
    required this.classroomId,
  }) : super(TeacherGradebookState.initial()) {
    on<TeacherGradebookLoadRequested>(_onLoad);
    on<TeacherGradebookExportCsvRequested>(_onExport);
  }

  final TeacherExamRepository repository;
  final String classroomId;

  Future<void> _onLoad(
    TeacherGradebookLoadRequested event,
    Emitter<TeacherGradebookState> emit,
  ) async {
    emit(state.copyWith(status: TeacherGradebookStatus.loading, clearError: true));
    final r = await repository.getClassroomGradebook(classroomId);
    r.fold(
      (f) => emit(state.copyWith(
        status: TeacherGradebookStatus.error,
        errorMessage: f.message,
      )),
      (d) => emit(state.copyWith(
        status: TeacherGradebookStatus.success,
        data: Map<String, dynamic>.from(d as Map),
      )),
    );
  }

  Future<void> _onExport(
    TeacherGradebookExportCsvRequested event,
    Emitter<TeacherGradebookState> emit,
  ) async {
    emit(state.copyWith(exportInProgress: true));
    final r = await repository.downloadClassroomGradebookCsv(classroomId);
    emit(state.copyWith(exportInProgress: false));
    r.fold(
      (f) => emit(state.copyWith(errorMessage: f.message)),
      (csv) => emit(state.copyWith(lastExportCsv: csv)),
    );
  }
}
