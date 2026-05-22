import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/feature/teacher/bloc/exams_list/teacher_exams_list_event.dart';
import 'package:english_for_community/feature/teacher/bloc/exams_list/teacher_exams_list_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherExamsListBloc extends Bloc<TeacherExamsListEvent, TeacherExamsListState> {
  TeacherExamsListBloc({required this.repository}) : super(TeacherExamsListState.initial()) {
    on<TeacherExamsListLoadRequested>(_onLoad);
    on<TeacherExamsListDuplicateRequested>(_onDuplicate);
    on<TeacherExamsListArchiveRequested>(_onArchive);
    on<TeacherExamsListRestoreRequested>(_onRestore);
    on<TeacherExamsListDeleteRequested>(_onDelete);
    on<TeacherExamsListPublishRequested>(_onPublish);
  }

  final TeacherExamRepository repository;

  Future<void> _onLoad(
    TeacherExamsListLoadRequested event,
    Emitter<TeacherExamsListState> emit,
  ) async {
    emit(state.copyWith(status: TeacherExamsListStatus.loading, clearError: true));
    final r = await repository.listMyExams();
    r.fold(
      (f) => emit(state.copyWith(
        status: TeacherExamsListStatus.error,
        errorMessage: f.message,
      )),
      (exams) => emit(state.copyWith(
        status: TeacherExamsListStatus.success,
        exams: exams,
      )),
    );
  }

  Future<void> _afterMutation(
    Emitter<TeacherExamsListState> emit, {
    required dynamic result,
  }) async {
    result.fold(
      (f) => emit(state.copyWith(mutationInProgress: false, errorMessage: f.message)),
      (_) {
        emit(state.copyWith(mutationInProgress: false));
        add(const TeacherExamsListLoadRequested());
      },
    );
  }

  Future<void> _onDuplicate(
    TeacherExamsListDuplicateRequested event,
    Emitter<TeacherExamsListState> emit,
  ) async {
    emit(state.copyWith(mutationInProgress: true, clearError: true));
    await _afterMutation(emit, result: await repository.duplicateExam(event.examId));
  }

  Future<void> _onArchive(
    TeacherExamsListArchiveRequested event,
    Emitter<TeacherExamsListState> emit,
  ) async {
    emit(state.copyWith(mutationInProgress: true, clearError: true));
    await _afterMutation(emit, result: await repository.archiveExam(event.examId));
  }

  Future<void> _onRestore(
    TeacherExamsListRestoreRequested event,
    Emitter<TeacherExamsListState> emit,
  ) async {
    emit(state.copyWith(mutationInProgress: true, clearError: true));
    await _afterMutation(emit, result: await repository.restoreExam(event.examId));
  }

  Future<void> _onDelete(
    TeacherExamsListDeleteRequested event,
    Emitter<TeacherExamsListState> emit,
  ) async {
    emit(state.copyWith(mutationInProgress: true, clearError: true));
    await _afterMutation(emit, result: await repository.deleteExam(event.examId));
  }

  Future<void> _onPublish(
    TeacherExamsListPublishRequested event,
    Emitter<TeacherExamsListState> emit,
  ) async {
    emit(state.copyWith(mutationInProgress: true, clearError: true));
    await _afterMutation(emit, result: await repository.publishExam(event.examId));
  }
}
