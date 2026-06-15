import 'package:english_for_community/feature/teacher/bloc/dashboard/teacher_dashboard_ui.dart';
import 'package:equatable/equatable.dart';

enum TeacherDashboardStatus { initial, loading, success, error }

class TeacherGradingQueueItem extends Equatable {
  const TeacherGradingQueueItem({
    required this.attemptId,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.studentLabel,
    required this.gradingState,
    required this.resultsReleased,
    this.classroomName,
    this.submittedAt,
  });

  final String attemptId;
  final String assignmentId;
  final String assignmentTitle;
  final String studentLabel;
  final String gradingState;
  final bool resultsReleased;
  final String? classroomName;
  final DateTime? submittedAt;

  @override
  List<Object?> get props => [
        attemptId,
        assignmentId,
        assignmentTitle,
        studentLabel,
        gradingState,
        resultsReleased,
        classroomName,
        submittedAt,
      ];
}

class TeacherDashboardState extends Equatable {
  const TeacherDashboardState({
    required this.status,
    this.errorMessage,
    this.classrooms = const [],
    this.assignments = const [],
    this.exams = const [],
    this.gradingQueue = const [],
    this.actionItems,
    this.gradingLoading = false,
    this.mutationInProgress = false,
    this.searchQuery = '',
    this.assignmentFilter = TeacherDashboardAssignmentFilter.all,
    this.classroomFilterId,
    this.filteredAssignments = const [],
  });

  final TeacherDashboardStatus status;
  final String? errorMessage;
  final List<dynamic> classrooms;
  final List<dynamic> assignments;
  final List<dynamic> exams;
  final List<TeacherGradingQueueItem> gradingQueue;
  final Map<String, dynamic>? actionItems;
  final bool gradingLoading;
  final bool mutationInProgress;
  final String searchQuery;
  final TeacherDashboardAssignmentFilter assignmentFilter;
  final String? classroomFilterId;
  final List<Map<String, dynamic>> filteredAssignments;

  factory TeacherDashboardState.initial() =>
      const TeacherDashboardState(status: TeacherDashboardStatus.initial);

  TeacherDashboardState copyWith({
    TeacherDashboardStatus? status,
    String? errorMessage,
    List<dynamic>? classrooms,
    List<dynamic>? assignments,
    List<dynamic>? exams,
    List<TeacherGradingQueueItem>? gradingQueue,
    Map<String, dynamic>? actionItems,
    bool? gradingLoading,
    bool? mutationInProgress,
    String? searchQuery,
    TeacherDashboardAssignmentFilter? assignmentFilter,
    String? classroomFilterId,
    List<Map<String, dynamic>>? filteredAssignments,
    bool clearError = false,
    bool clearClassroomFilter = false,
  }) {
    return TeacherDashboardState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      classrooms: classrooms ?? this.classrooms,
      assignments: assignments ?? this.assignments,
      exams: exams ?? this.exams,
      gradingQueue: gradingQueue ?? this.gradingQueue,
      actionItems: actionItems ?? this.actionItems,
      gradingLoading: gradingLoading ?? this.gradingLoading,
      mutationInProgress: mutationInProgress ?? this.mutationInProgress,
      searchQuery: searchQuery ?? this.searchQuery,
      assignmentFilter: assignmentFilter ?? this.assignmentFilter,
      classroomFilterId:
          clearClassroomFilter ? null : (classroomFilterId ?? this.classroomFilterId),
      filteredAssignments: filteredAssignments ?? this.filteredAssignments,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        classrooms,
        assignments,
        exams,
        gradingQueue,
        actionItems,
        gradingLoading,
        mutationInProgress,
        searchQuery,
        assignmentFilter,
        classroomFilterId,
        filteredAssignments,
      ];
}
