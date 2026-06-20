import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/feature/teacher/bloc/analytics/teacher_analytics_derived.dart';
import 'package:english_for_community/feature/teacher/bloc/analytics/teacher_analytics_event.dart';
import 'package:english_for_community/feature/teacher/bloc/analytics/teacher_analytics_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherAnalyticsBloc extends Bloc<TeacherAnalyticsEvent, TeacherAnalyticsState> {
  TeacherAnalyticsBloc({required this.repository}) : super(TeacherAnalyticsState.initial()) {
    on<TeacherAnalyticsLoadRequested>(_onLoad);
    on<TeacherAnalyticsPeriodChanged>(_onPeriodChanged);
  }

  final TeacherExamRepository repository;

  Future<void> _onLoad(
    TeacherAnalyticsLoadRequested event,
    Emitter<TeacherAnalyticsState> emit,
  ) async {
    final period = event.period;
    emit(state.copyWith(status: TeacherAnalyticsStatus.loading, period: period, clearError: true));
    final r = await repository.getTeacherAnalyticsFull(days: period);
    r.fold(
      (f) => emit(state.copyWith(
        status: TeacherAnalyticsStatus.error,
        errorMessage: f.message,
      )),
      (d) {
        final m = Map<String, dynamic>.from(d as Map);
        final charts = m['charts'] is Map ? Map<String, dynamic>.from(m['charts'] as Map) : null;
        final derived = teacherAnalyticsDeriveCharts(charts);
        emit(state.copyWith(
          status: TeacherAnalyticsStatus.success,
          period: period,
          summary: m['summary'] is Map
              ? Map<String, dynamic>.from(m['summary'] as Map)
              : m,
          charts: charts,
          submissionRows: derived.submissionRows,
          scoreDistRows: derived.scoreDistRows,
          submissionMaxY: derived.submissionMaxY,
          scoreDistMaxY: derived.scoreDistMaxY,
        ));
      },
    );
  }

  Future<void> _onPeriodChanged(
    TeacherAnalyticsPeriodChanged event,
    Emitter<TeacherAnalyticsState> emit,
  ) async {
    add(TeacherAnalyticsLoadRequested(period: event.period));
  }
}
