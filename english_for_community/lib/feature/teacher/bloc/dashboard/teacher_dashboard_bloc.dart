import 'dart:math' as math;

import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/feature/teacher/bloc/dashboard/teacher_dashboard_event.dart';
import 'package:english_for_community/feature/teacher/bloc/dashboard/teacher_dashboard_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherDashboardBloc extends Bloc<TeacherDashboardEvent, TeacherDashboardState> {
  TeacherDashboardBloc({required this.repository}) : super(TeacherDashboardState.initial()) {
    on<TeacherDashboardLoadRequested>(_onLoad);
    on<TeacherDashboardCloseAssignmentRequested>(_onCloseAssignment);
    on<TeacherDashboardRotatePublicLinkRequested>(_onRotatePublicLink);
  }

  final TeacherExamRepository repository;

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

    final cr = await repository.listMyClassroomsAsTeacher();
    cr.fold((f) => err = f.message, (list) => classrooms = list);

    if (err == null) {
      final ar = await repository.listMyAssignments();
      ar.fold((f) => err ??= f.message, (list) => assignments = list);
    }

    if (err == null) {
      final er = await repository.listMyExams();
      er.fold((f) => err ??= f.message, (list) => exams = list);
    }

    if (err != null) {
      emit(state.copyWith(
        status: TeacherDashboardStatus.error,
        errorMessage: err,
        gradingLoading: false,
      ));
      return;
    }

    Map<String, dynamic>? actionItems;
    final air = await repository.getTeacherDashboardActionItems();
    air.fold((_) {}, (d) => actionItems = d);

    emit(state.copyWith(
      status: TeacherDashboardStatus.success,
      classrooms: classrooms,
      assignments: assignments,
      exams: exams,
      actionItems: actionItems,
      gradingLoading: true,
    ));

    final queue = await _buildGradingQueue(assignments);
    emit(state.copyWith(
      gradingQueue: queue,
      gradingLoading: false,
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

  Future<List<TeacherGradingQueueItem>> _buildGradingQueue(List<dynamic> assignments) async {
    final collected = <TeacherGradingQueueItem>[];
    final assignmentMeta = <String, Map<String, dynamic>>{};
    for (final raw in assignments) {
      final m = Map<String, dynamic>.from(raw as Map);
      final id = m['id'] as String? ?? '';
      if (id.isNotEmpty) assignmentMeta[id] = m;
    }
    final ids = assignmentMeta.keys.toList();
    const batch = 5;
    for (var i = 0; i < ids.length; i += batch) {
      final end = math.min(i + batch, ids.length);
      final chunk = ids.sublist(i, end);
      final futures = chunk.map(repository.listAssignmentAttempts).toList();
      final results = await Future.wait(futures);
      for (var j = 0; j < chunk.length; j++) {
        final assignmentId = chunk[j];
        final meta = assignmentMeta[assignmentId]!;
        final title = _examTitleFromAssignment(meta);
        results[j].fold((_) {}, (attempts) {
          for (final raw in attempts) {
            final a = Map<String, dynamic>.from(raw as Map);
            if (!_needsGradingAttention(a)) continue;
            final attemptId = a['id'] as String? ?? '';
            if (attemptId.isEmpty) continue;
            collected.add(
              TeacherGradingQueueItem(
                attemptId: attemptId,
                assignmentId: assignmentId,
                assignmentTitle: title,
                studentLabel: _formatStudentLabel(a['userId']),
                gradingState: a['gradingState'] as String? ?? '',
                resultsReleased: a['resultsReleased'] == true,
                submittedAt: _parseDate(a['submittedAt']),
              ),
            );
          }
        });
      }
    }
    collected.sort((a, b) {
      final ta = a.submittedAt?.millisecondsSinceEpoch ?? 0;
      final tb = b.submittedAt?.millisecondsSinceEpoch ?? 0;
      return tb.compareTo(ta);
    });
    return collected.length > 15 ? collected.sublist(0, 15) : collected;
  }

  static bool _needsGradingAttention(Map<String, dynamic> m) {
    if ((m['status'] as String?) != 'submitted') return false;
    final gs = m['gradingState'] as String? ?? '';
    final released = m['resultsReleased'] == true;
    if (gs == 'pending_manual' || gs == 'pending_ai') return true;
    if (gs == 'finalized' && !released) return true;
    return false;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  static String _formatStudentLabel(dynamic userField) {
    if (userField is Map) {
      final m = Map<String, dynamic>.from(userField);
      for (final key in ['fullName', 'email', 'username']) {
        final s = (m[key] as String?)?.trim();
        if (s != null && s.isNotEmpty) return s;
      }
    }
    return 'Student';
  }

  static String _examTitleFromAssignment(Map<String, dynamic> m) {
    final exam = m['examId'];
    if (exam is Map) {
      final t = (exam['title'] as String?)?.trim();
      if (t != null && t.isNotEmpty) return t;
    }
    return 'Exam';
  }
}
