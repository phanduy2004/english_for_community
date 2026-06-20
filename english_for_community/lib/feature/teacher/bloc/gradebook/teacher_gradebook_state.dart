import 'package:english_for_community/feature/teacher/bloc/gradebook/teacher_gradebook_derived.dart';
import 'package:equatable/equatable.dart';

enum TeacherGradebookStatus { initial, loading, success, error }

class TeacherGradebookState extends Equatable {
  const TeacherGradebookState({
    required this.status,
    this.errorMessage,
    this.data,
    this.exportInProgress = false,
    this.lastExportCsv,
    this.assignments = const [],
    this.rows = const [],
    this.classAverages = const [],
    this.summary,
    this.filteredRows = const [],
    this.visibleAssignments = const [],
    this.searchQuery = '',
    this.modeFilter,
    this.sort = TeacherGradebookSort.nameAsc,
    this.hideEmpty = false,
  });

  final TeacherGradebookStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? data;
  final bool exportInProgress;
  final String? lastExportCsv;

  /// Parsed gradebook matrix (P0-F3 — computed in bloc, not in build).
  final List<Map<String, dynamic>> assignments;
  final List<Map<String, dynamic>> rows;
  final List<Map<String, dynamic>> classAverages;
  final Map<String, dynamic>? summary;
  final List<Map<String, dynamic>> filteredRows;
  final List<Map<String, dynamic>> visibleAssignments;
  final String searchQuery;
  final String? modeFilter;
  final TeacherGradebookSort sort;
  final bool hideEmpty;

  factory TeacherGradebookState.initial() =>
      const TeacherGradebookState(status: TeacherGradebookStatus.initial);

  TeacherGradebookState copyWith({
    TeacherGradebookStatus? status,
    String? errorMessage,
    Map<String, dynamic>? data,
    bool? exportInProgress,
    String? lastExportCsv,
    List<Map<String, dynamic>>? assignments,
    List<Map<String, dynamic>>? rows,
    List<Map<String, dynamic>>? classAverages,
    Map<String, dynamic>? summary,
    List<Map<String, dynamic>>? filteredRows,
    List<Map<String, dynamic>>? visibleAssignments,
    String? searchQuery,
    String? modeFilter,
    TeacherGradebookSort? sort,
    bool? hideEmpty,
    bool clearError = false,
    bool clearLastExportCsv = false,
    bool clearModeFilter = false,
  }) {
    return TeacherGradebookState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      data: data ?? this.data,
      exportInProgress: exportInProgress ?? this.exportInProgress,
      lastExportCsv: clearLastExportCsv ? null : (lastExportCsv ?? this.lastExportCsv),
      assignments: assignments ?? this.assignments,
      rows: rows ?? this.rows,
      classAverages: classAverages ?? this.classAverages,
      summary: summary ?? this.summary,
      filteredRows: filteredRows ?? this.filteredRows,
      visibleAssignments: visibleAssignments ?? this.visibleAssignments,
      searchQuery: searchQuery ?? this.searchQuery,
      modeFilter: clearModeFilter ? null : (modeFilter ?? this.modeFilter),
      sort: sort ?? this.sort,
      hideEmpty: hideEmpty ?? this.hideEmpty,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        data,
        exportInProgress,
        lastExportCsv,
        assignments,
        rows,
        classAverages,
        summary,
        filteredRows,
        visibleAssignments,
        searchQuery,
        modeFilter,
        sort,
        hideEmpty,
      ];
}
