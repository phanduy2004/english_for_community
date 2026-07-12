import 'package:equatable/equatable.dart';

enum TeacherAnalyticsStatus { initial, loading, success, error }

class TeacherAnalyticsState extends Equatable {
  const TeacherAnalyticsState({
    required this.status,
    this.errorMessage,
    this.summary,
    this.charts,
    this.period = 14,
    this.classroomId,
    this.classes = const [],
    this.submissionRows = const [],
    this.scoreDistRows = const [],
    this.scoreTrendRows = const [],
    this.submissionMaxY = 1,
    this.scoreDistMaxY = 1,
  });

  final TeacherAnalyticsStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? summary;
  final Map<String, dynamic>? charts;
  final int period;

  /// Lớp đang xem (analytics theo TỪNG lớp) + danh sách lớp của giáo viên.
  final String? classroomId;
  final List<Map<String, dynamic>> classes;

  /// Pre-parsed chart series (P0-F3 — no `.map().toList()` in widget build).
  final List<Map<String, dynamic>> submissionRows;
  final List<Map<String, dynamic>> scoreDistRows;
  final List<Map<String, dynamic>> scoreTrendRows;
  final double submissionMaxY;
  final double scoreDistMaxY;

  factory TeacherAnalyticsState.initial() =>
      const TeacherAnalyticsState(status: TeacherAnalyticsStatus.initial, period: 14);

  TeacherAnalyticsState copyWith({
    TeacherAnalyticsStatus? status,
    String? errorMessage,
    Map<String, dynamic>? summary,
    Map<String, dynamic>? charts,
    int? period,
    String? classroomId,
    List<Map<String, dynamic>>? classes,
    List<Map<String, dynamic>>? submissionRows,
    List<Map<String, dynamic>>? scoreDistRows,
    List<Map<String, dynamic>>? scoreTrendRows,
    double? submissionMaxY,
    double? scoreDistMaxY,
    bool clearError = false,
  }) {
    return TeacherAnalyticsState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      summary: summary ?? this.summary,
      charts: charts ?? this.charts,
      period: period ?? this.period,
      classroomId: classroomId ?? this.classroomId,
      classes: classes ?? this.classes,
      submissionRows: submissionRows ?? this.submissionRows,
      scoreDistRows: scoreDistRows ?? this.scoreDistRows,
      scoreTrendRows: scoreTrendRows ?? this.scoreTrendRows,
      submissionMaxY: submissionMaxY ?? this.submissionMaxY,
      scoreDistMaxY: scoreDistMaxY ?? this.scoreDistMaxY,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        summary,
        charts,
        period,
        classroomId,
        classes,
        submissionRows,
        scoreDistRows,
        scoreTrendRows,
        submissionMaxY,
        scoreDistMaxY,
      ];
}
