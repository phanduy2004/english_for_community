import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/feature/teacher/bloc/gradebook/teacher_gradebook_derived.dart';
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
    on<TeacherGradebookSearchChanged>(_onSearch);
    on<TeacherGradebookModeFilterChanged>(_onModeFilter);
    on<TeacherGradebookSortChanged>(_onSort);
    on<TeacherGradebookHideEmptyChanged>(_onHideEmpty);
  }

  final TeacherExamRepository repository;
  final String classroomId;

  TeacherGradebookState _withDerived(TeacherGradebookState base) {
    final visible = teacherGradebookVisibleAssignments(base.assignments, base.modeFilter);
    final filtered = teacherGradebookFilteredRows(
      rows: base.rows,
      query: base.searchQuery,
      sort: base.sort,
      hideEmpty: base.hideEmpty,
    );
    return base.copyWith(
      visibleAssignments: visible,
      filteredRows: filtered,
    );
  }

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
      (d) {
        final data = Map<String, dynamic>.from(d as Map);
        final next = state.copyWith(
          status: TeacherGradebookStatus.success,
          data: data,
          assignments: teacherGradebookParseList(data['assignments']),
          rows: teacherGradebookParseList(data['rows']),
          classAverages: teacherGradebookParseList(data['classAverages']),
          summary: teacherGradebookParseSummary(data),
        );
        emit(_withDerived(next));
      },
    );
  }

  void _onSearch(TeacherGradebookSearchChanged event, Emitter<TeacherGradebookState> emit) {
    if (event.query == state.searchQuery) return;
    emit(_withDerived(state.copyWith(searchQuery: event.query)));
  }

  void _onModeFilter(TeacherGradebookModeFilterChanged event, Emitter<TeacherGradebookState> emit) {
    if (event.modeFilter == state.modeFilter) return;
    emit(_withDerived(state.copyWith(
      modeFilter: event.modeFilter,
      clearModeFilter: event.modeFilter == null,
    )));
  }

  void _onSort(TeacherGradebookSortChanged event, Emitter<TeacherGradebookState> emit) {
    if (event.sort == state.sort) return;
    emit(_withDerived(state.copyWith(sort: event.sort)));
  }

  void _onHideEmpty(TeacherGradebookHideEmptyChanged event, Emitter<TeacherGradebookState> emit) {
    if (event.hideEmpty == state.hideEmpty) return;
    emit(_withDerived(state.copyWith(hideEmpty: event.hideEmpty)));
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
