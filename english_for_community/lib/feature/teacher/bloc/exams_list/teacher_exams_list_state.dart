import 'package:english_for_community/feature/teacher/bloc/exams_list/teacher_exams_list_filter.dart';
import 'package:equatable/equatable.dart';

enum TeacherExamsListStatus { initial, loading, success, error }

class TeacherExamsListState extends Equatable {
  const TeacherExamsListState({
    required this.status,
    this.errorMessage,
    this.exams = const [],
    this.mutationInProgress = false,
    this.statusFilter = TeacherExamsListStatusFilter.all,
    this.visibleExams = const [],
  });

  final TeacherExamsListStatus status;
  final String? errorMessage;
  final List<dynamic> exams;
  final bool mutationInProgress;
  final TeacherExamsListStatusFilter statusFilter;
  final List<dynamic> visibleExams;

  factory TeacherExamsListState.initial() =>
      const TeacherExamsListState(status: TeacherExamsListStatus.initial);

  TeacherExamsListState copyWith({
    TeacherExamsListStatus? status,
    String? errorMessage,
    List<dynamic>? exams,
    bool? mutationInProgress,
    TeacherExamsListStatusFilter? statusFilter,
    List<dynamic>? visibleExams,
    bool clearError = false,
  }) {
    return TeacherExamsListState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      exams: exams ?? this.exams,
      mutationInProgress: mutationInProgress ?? this.mutationInProgress,
      statusFilter: statusFilter ?? this.statusFilter,
      visibleExams: visibleExams ?? this.visibleExams,
    );
  }

  @override
  List<Object?> get props =>
      [status, errorMessage, exams, mutationInProgress, statusFilter, visibleExams];
}
