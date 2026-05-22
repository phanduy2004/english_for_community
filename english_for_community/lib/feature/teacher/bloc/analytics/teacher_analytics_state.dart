import 'package:equatable/equatable.dart';

enum TeacherAnalyticsStatus { initial, loading, success, error }

class TeacherAnalyticsState extends Equatable {
  const TeacherAnalyticsState({
    required this.status,
    this.errorMessage,
    this.summary,
    this.charts,
    this.period = 14,
  });

  final TeacherAnalyticsStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? summary;
  final Map<String, dynamic>? charts;
  final int period;

  factory TeacherAnalyticsState.initial() =>
      const TeacherAnalyticsState(status: TeacherAnalyticsStatus.initial, period: 14);

  TeacherAnalyticsState copyWith({
    TeacherAnalyticsStatus? status,
    String? errorMessage,
    Map<String, dynamic>? summary,
    Map<String, dynamic>? charts,
    int? period,
    bool clearError = false,
  }) {
    return TeacherAnalyticsState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      summary: summary ?? this.summary,
      charts: charts ?? this.charts,
      period: period ?? this.period,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, summary, charts, period];
}
