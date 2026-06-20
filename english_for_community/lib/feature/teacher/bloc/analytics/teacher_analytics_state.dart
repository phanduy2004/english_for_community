import 'package:english_for_community/feature/teacher/bloc/analytics/teacher_analytics_derived.dart';
import 'package:equatable/equatable.dart';

enum TeacherAnalyticsStatus { initial, loading, success, error }

class TeacherAnalyticsState extends Equatable {
  const TeacherAnalyticsState({
    required this.status,
    this.errorMessage,
    this.summary,
    this.charts,
    this.period = 14,
    this.submissionRows = const [],
    this.scoreDistRows = const [],
    this.submissionMaxY = 1,
    this.scoreDistMaxY = 1,
  });

  final TeacherAnalyticsStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? summary;
  final Map<String, dynamic>? charts;
  final int period;

  /// Pre-parsed chart series (P0-F3 — no `.map().toList()` in widget build).
  final List<Map<String, dynamic>> submissionRows;
  final List<Map<String, dynamic>> scoreDistRows;
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
    List<Map<String, dynamic>>? submissionRows,
    List<Map<String, dynamic>>? scoreDistRows,
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
      submissionRows: submissionRows ?? this.submissionRows,
      scoreDistRows: scoreDistRows ?? this.scoreDistRows,
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
        submissionRows,
        scoreDistRows,
        submissionMaxY,
        scoreDistMaxY,
      ];
}
