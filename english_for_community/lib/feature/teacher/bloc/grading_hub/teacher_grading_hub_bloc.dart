import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/feature/teacher/bloc/grading_hub/teacher_grading_hub_filter.dart';
import 'package:english_for_community/feature/teacher/bloc/grading_hub/teacher_grading_hub_event.dart';
import 'package:english_for_community/feature/teacher/bloc/grading_hub/teacher_grading_hub_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherGradingHubBloc extends Bloc<TeacherGradingHubEvent, TeacherGradingHubState> {
  TeacherGradingHubBloc({
    required this.repository,
    required this.assignmentId,
  }) : super(TeacherGradingHubState.initial()) {
    on<TeacherGradingHubFilterChanged>(_onFilter);
    on<TeacherGradingHubLoadRequested>(_onLoad);
    on<TeacherGradingHubRunAiRequested>(_onRunAi);
    on<TeacherGradingHubReleaseRequested>(_onRelease);
    on<TeacherGradingHubBatchAiRequested>(_onBatchAi);
    on<TeacherGradingHubBatchReleaseRequested>(_onBatchRelease);
    on<TeacherGradingHubBatchFinalizeRequested>(_onBatchFinalize);
  }

  final TeacherExamRepository repository;
  final String assignmentId;

  void _onFilter(
    TeacherGradingHubFilterChanged event,
    Emitter<TeacherGradingHubState> emit,
  ) {
    if (event.filter == state.filter) return;
    emit(state.copyWith(
      filter: event.filter,
      visibleAttempts: teacherGradingHubVisibleAttempts(state.attempts, event.filter),
    ));
  }

  Future<void> _onLoad(
    TeacherGradingHubLoadRequested event,
    Emitter<TeacherGradingHubState> emit,
  ) async {
    emit(state.copyWith(status: TeacherGradingHubStatus.loading, clearError: true));
    // C3: tổng hợp integrity per-bài-giao (best-effort; lỗi không chặn trang grading).
    final integrityRes = await repository.getAssignmentIntegritySummary(assignmentId);
    final Map<String, dynamic>? integrity = integrityRes.fold<Map<String, dynamic>?>(
      (_) => null,
      (v) => Map<String, dynamic>.from(v as Map),
    );
    final r = await repository.getAssignmentGradingHub(assignmentId);
    r.fold(
      (f) => emit(state.copyWith(
        status: TeacherGradingHubStatus.error,
        errorMessage: f.message,
      )),
      (hub) {
        final m = Map<String, dynamic>.from(hub as Map);
        final attempts = (m['attempts'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        emit(state.copyWith(
          status: TeacherGradingHubStatus.success,
          assignment: m['assignment'] is Map
              ? Map<String, dynamic>.from(m['assignment'] as Map)
              : null,
          stats: m['stats'] is Map
              ? Map<String, dynamic>.from(m['stats'] as Map)
              : {},
          attempts: attempts,
          visibleAttempts: teacherGradingHubVisibleAttempts(attempts, state.filter),
          integritySummary: integrity,
        ));
      },
    );
  }

  Future<void> _onRunAi(
    TeacherGradingHubRunAiRequested event,
    Emitter<TeacherGradingHubState> emit,
  ) async {
    emit(state.copyWith(attemptMutationId: event.attemptId));
    final r = await repository.runAiGradingDraft(event.attemptId);
    r.fold(
      (f) => emit(state.copyWith(errorMessage: f.message, clearAttemptMutation: true)),
      (_) {
        emit(state.copyWith(clearAttemptMutation: true));
        add(const TeacherGradingHubLoadRequested());
      },
    );
  }

  Future<void> _onRelease(
    TeacherGradingHubReleaseRequested event,
    Emitter<TeacherGradingHubState> emit,
  ) async {
    emit(state.copyWith(attemptMutationId: event.attemptId));
    final r = await repository.releaseExamResults(
      event.attemptId,
      resultsDetailLevel: event.resultsDetailLevel,
    );
    r.fold(
      (f) => emit(state.copyWith(errorMessage: f.message, clearAttemptMutation: true)),
      (_) {
        emit(state.copyWith(clearAttemptMutation: true));
        add(const TeacherGradingHubLoadRequested());
      },
    );
  }

  Future<void> _onBatchAi(
    TeacherGradingHubBatchAiRequested event,
    Emitter<TeacherGradingHubState> emit,
  ) async {
    emit(state.copyWith(batchAiRunning: true));
    final r = await repository.runAiGradingBatch(assignmentId);
    emit(state.copyWith(batchAiRunning: false));
    r.fold(
      (f) => emit(state.copyWith(errorMessage: f.message)),
      (_) => add(const TeacherGradingHubLoadRequested()),
    );
  }

  Future<void> _onBatchRelease(
    TeacherGradingHubBatchReleaseRequested event,
    Emitter<TeacherGradingHubState> emit,
  ) async {
    emit(state.copyWith(batchOpsRunning: true));
    final r = await repository.batchReleaseExamResults(assignmentId);
    emit(state.copyWith(batchOpsRunning: false));
    r.fold(
      (f) => emit(state.copyWith(errorMessage: f.message)),
      (_) => add(const TeacherGradingHubLoadRequested()),
    );
  }

  Future<void> _onBatchFinalize(
    TeacherGradingHubBatchFinalizeRequested event,
    Emitter<TeacherGradingHubState> emit,
  ) async {
    emit(state.copyWith(batchOpsRunning: true));
    final r = await repository.batchFinalizeExamAttempts(assignmentId);
    emit(state.copyWith(batchOpsRunning: false));
    r.fold(
      (f) => emit(state.copyWith(errorMessage: f.message)),
      (_) => add(const TeacherGradingHubLoadRequested()),
    );
  }
}
