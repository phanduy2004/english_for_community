import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/feature/teacher/bloc/dashboard/teacher_dashboard_derived.dart';
import 'package:english_for_community/feature/teacher/bloc/dashboard/teacher_dashboard_event.dart';
import 'package:english_for_community/feature/teacher/bloc/dashboard/teacher_dashboard_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherDashboardBloc extends Bloc<TeacherDashboardEvent, TeacherDashboardState> {
  TeacherDashboardBloc({required this.repository}) : super(TeacherDashboardState.initial()) {
    on<TeacherDashboardLoadRequested>(_onLoad);
    on<TeacherDashboardCloseAssignmentRequested>(_onCloseAssignment);
    on<TeacherDashboardRotatePublicLinkRequested>(_onRotatePublicLink);
    on<TeacherDashboardSearchQueryChanged>(_onSearchQuery);
    on<TeacherDashboardAssignmentFilterChanged>(_onAssignmentFilter);
    on<TeacherDashboardClassroomFilterChanged>(_onClassroomFilter);
  }

  final TeacherExamRepository repository;

  List<Map<String, dynamic>> _filtered(List<dynamic> assignments) =>
      teacherDashboardFilterAssignments(
        assignments: assignments,
        searchQuery: state.searchQuery,
        assignmentFilter: state.assignmentFilter,
        classroomFilterId: state.classroomFilterId,
      );

  void _onSearchQuery(
    TeacherDashboardSearchQueryChanged event,
    Emitter<TeacherDashboardState> emit,
  ) {
    emit(state.copyWith(
      searchQuery: event.query,
      filteredAssignments: teacherDashboardFilterAssignments(
        assignments: state.assignments,
        searchQuery: event.query,
        assignmentFilter: state.assignmentFilter,
        classroomFilterId: state.classroomFilterId,
      ),
    ));
  }

  void _onAssignmentFilter(
    TeacherDashboardAssignmentFilterChanged event,
    Emitter<TeacherDashboardState> emit,
  ) {
    if (event.filter == state.assignmentFilter) return;
    emit(state.copyWith(
      assignmentFilter: event.filter,
      filteredAssignments: teacherDashboardFilterAssignments(
        assignments: state.assignments,
        searchQuery: state.searchQuery,
        assignmentFilter: event.filter,
        classroomFilterId: state.classroomFilterId,
      ),
    ));
  }

  void _onClassroomFilter(
    TeacherDashboardClassroomFilterChanged event,
    Emitter<TeacherDashboardState> emit,
  ) {
    if (event.classroomId == state.classroomFilterId) return;
    emit(state.copyWith(
      classroomFilterId: event.classroomId,
      clearClassroomFilter: event.classroomId == null,
      filteredAssignments: teacherDashboardFilterAssignments(
        assignments: state.assignments,
        searchQuery: state.searchQuery,
        assignmentFilter: state.assignmentFilter,
        classroomFilterId: event.classroomId,
      ),
    ));
  }

  Future<void> _onLoad(
    TeacherDashboardLoadRequested event,
    Emitter<TeacherDashboardState> emit,
  ) async {
    emit(state.copyWith(
      status: TeacherDashboardStatus.loading,
      gradingLoading: true,
      clearError: true,
      classrooms: [],
      assignments: [],
      exams: [],
      gradingQueue: [],
    ));

    String? err;
    List<dynamic> classrooms = [];
    List<dynamic> assignments = [];
    List<dynamic> exams = [];
    Map<String, dynamic>? actionItems;

    // Load core dashboard data in parallel (was 4 sequential round-trips).
    final results = await Future.wait([
      repository.listMyClassroomsAsTeacher(),
      repository.listMyAssignments(),
      repository.listMyExams(),
      repository.getTeacherDashboardActionItems(),
    ]);

    results[0].fold((f) => err = f.message, (list) => classrooms = list as List<dynamic>);
    if (err == null) {
      results[1].fold((f) => err ??= f.message, (list) => assignments = list as List<dynamic>);
    }
    if (err == null) {
      results[2].fold((f) => err ??= f.message, (list) => exams = list as List<dynamic>);
    }
    if (err == null) {
      results[3].fold((_) {}, (d) => actionItems = d as Map<String, dynamic>);
    }

    if (err != null) {
      emit(state.copyWith(
        status: TeacherDashboardStatus.error,
        errorMessage: err,
        gradingLoading: false,
      ));
      return;
    }

    final gradingQueue = _parseGradingQueue(actionItems?['gradingQueue']);

    emit(state.copyWith(
      status: TeacherDashboardStatus.success,
      classrooms: classrooms,
      assignments: assignments,
      exams: exams,
      actionItems: actionItems,
      gradingQueue: gradingQueue,
      gradingLoading: false,
      filteredAssignments: _filtered(assignments),
    ));
  }

  Future<void> _onCloseAssignment(
    TeacherDashboardCloseAssignmentRequested event,
    Emitter<TeacherDashboardState> emit,
  ) async {
    emit(state.copyWith(mutationInProgress: true));
    final r = await repository.closeExamAssignment(event.assignmentId);
    r.fold(
      (f) => emit(state.copyWith(mutationInProgress: false, errorMessage: f.message)),
      (_) {
        emit(state.copyWith(mutationInProgress: false));
        add(const TeacherDashboardLoadRequested());
      },
    );
  }

  Future<void> _onRotatePublicLink(
    TeacherDashboardRotatePublicLinkRequested event,
    Emitter<TeacherDashboardState> emit,
  ) async {
    emit(state.copyWith(mutationInProgress: true));
    final r = await repository.rotateExamAssignmentPublicJoin(event.assignmentId);
    r.fold(
      (f) => emit(state.copyWith(mutationInProgress: false, errorMessage: f.message)),
      (_) {
        emit(state.copyWith(mutationInProgress: false));
        add(const TeacherDashboardLoadRequested());
      },
    );
  }

  static List<TeacherGradingQueueItem> _parseGradingQueue(dynamic raw) {
    if (raw is! List) return [];
    final items = <TeacherGradingQueueItem>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final m = Map<String, dynamic>.from(entry);
      final attemptId = m['attemptId'] as String? ?? '';
      if (attemptId.isEmpty) continue;
      items.add(
        TeacherGradingQueueItem(
          attemptId: attemptId,
          assignmentId: m['assignmentId'] as String? ?? '',
          assignmentTitle: (m['assignmentTitle'] as String?)?.trim().isNotEmpty == true
              ? (m['assignmentTitle'] as String).trim()
              : 'Exam',
          studentLabel: (m['studentLabel'] as String?)?.trim().isNotEmpty == true
              ? (m['studentLabel'] as String).trim()
              : 'Student',
          gradingState: m['gradingState'] as String? ?? '',
          resultsReleased: m['resultsReleased'] == true,
          classroomName: (m['classroomName'] as String?)?.trim(),
          submittedAt: _parseDate(m['submittedAt']),
        ),
      );
    }
    return items;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
