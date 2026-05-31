import 'package:equatable/equatable.dart';

enum TeacherGradebookStatus { initial, loading, success, error }

class TeacherGradebookState extends Equatable {
  const TeacherGradebookState({
    required this.status,
    this.errorMessage,
    this.data,
    this.exportInProgress = false,
    this.lastExportCsv,
  });

  final TeacherGradebookStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? data;
  final bool exportInProgress;
  final String? lastExportCsv;

  factory TeacherGradebookState.initial() =>
      const TeacherGradebookState(status: TeacherGradebookStatus.initial);

  TeacherGradebookState copyWith({
    TeacherGradebookStatus? status,
    String? errorMessage,
    Map<String, dynamic>? data,
    bool? exportInProgress,
    String? lastExportCsv,
    bool clearError = false,
    bool clearLastExportCsv = false,
  }) {
    return TeacherGradebookState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      data: data ?? this.data,
      exportInProgress: exportInProgress ?? this.exportInProgress,
      lastExportCsv: clearLastExportCsv ? null : (lastExportCsv ?? this.lastExportCsv),
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, data, exportInProgress, lastExportCsv];
}
