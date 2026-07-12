import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/feature/teacher/bloc/analytics/teacher_analytics_derived.dart';
import 'package:english_for_community/feature/teacher/bloc/analytics/teacher_analytics_event.dart';
import 'package:english_for_community/feature/teacher/bloc/analytics/teacher_analytics_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherAnalyticsBloc extends Bloc<TeacherAnalyticsEvent, TeacherAnalyticsState> {
  TeacherAnalyticsBloc({required this.repository}) : super(TeacherAnalyticsState.initial()) {
    on<TeacherAnalyticsLoadRequested>(_onLoad);
    on<TeacherAnalyticsPeriodChanged>(_onPeriodChanged);
    on<TeacherAnalyticsClassChanged>(_onClassChanged);
  }

  final TeacherExamRepository repository;

  static String _cid(Map c) => (c['id'] ?? c['_id'])?.toString() ?? '';

  Future<void> _onLoad(
    TeacherAnalyticsLoadRequested event,
    Emitter<TeacherAnalyticsState> emit,
  ) async {
    final period = event.period;
    emit(state.copyWith(status: TeacherAnalyticsStatus.loading, period: period, clearError: true));

    // Danh sách lớp của GV (chỉ nạp 1 lần) — analytics xem theo TỪNG lớp.
    var classes = state.classes;
    if (classes.isEmpty) {
      final cr = await repository.listMyClassroomsAsTeacher();
      cr.fold((_) {}, (list) {
        classes = [for (final raw in list) Map<String, dynamic>.from(raw as Map)];
      });
    }

    // Lớp cần xem: event > lớp đang chọn > lớp đầu tiên.
    String? classroomId = event.classroomId ?? state.classroomId;
    if (classroomId == null || !classes.any((c) => _cid(c) == classroomId)) {
      classroomId = classes.isNotEmpty ? _cid(classes.first) : null;
    }

    // GV chưa có lớp nào → success rỗng (UI hiện empty note).
    if (classroomId == null) {
      emit(state.copyWith(
        status: TeacherAnalyticsStatus.success,
        period: period,
        classes: classes,
        summary: const {},
        charts: const {},
        submissionRows: const [],
        scoreDistRows: const [],
        scoreTrendRows: const [],
      ));
      return;
    }

    final target = classroomId;
    final r = await repository.getTeacherAnalyticsFull(days: period, classroomId: target);
    r.fold(
      (f) => emit(state.copyWith(
        status: TeacherAnalyticsStatus.error,
        errorMessage: f.message,
        classes: classes,
        classroomId: target,
      )),
      (d) {
        final m = Map<String, dynamic>.from(d as Map);
        final charts = m['charts'] is Map ? Map<String, dynamic>.from(m['charts'] as Map) : null;
        final derived = teacherAnalyticsDeriveCharts(charts);
        emit(state.copyWith(
          status: TeacherAnalyticsStatus.success,
          period: period,
          classes: classes,
          classroomId: target,
          summary: m['summary'] is Map
              ? Map<String, dynamic>.from(m['summary'] as Map)
              : m,
          charts: charts,
          submissionRows: derived.submissionRows,
          scoreDistRows: derived.scoreDistRows,
          scoreTrendRows: derived.scoreTrendRows,
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

  Future<void> _onClassChanged(
    TeacherAnalyticsClassChanged event,
    Emitter<TeacherAnalyticsState> emit,
  ) async {
    if (event.classroomId == state.classroomId) return;
    add(TeacherAnalyticsLoadRequested(period: state.period, classroomId: event.classroomId));
  }
}
