import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/feature/teacher/bloc/exam_attempt_grade/teacher_exam_attempt_grade_event.dart';
import 'package:english_for_community/feature/teacher/bloc/exam_attempt_grade/teacher_exam_attempt_grade_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherExamAttemptGradeBloc extends Bloc<TeacherExamAttemptGradeEvent, TeacherExamAttemptGradeState> {
  TeacherExamAttemptGradeBloc({
    required this.repository,
    required this.attemptId,
  }) : super(TeacherExamAttemptGradeState.initial()) {
    on<TeacherExamAttemptGradeLoadRequested>(_onLoad);
    on<TeacherExamAttemptGradeRefreshRequested>(_onRefresh);
    on<TeacherExamAttemptGradeRunAiRequested>(_onRunAi);
    on<TeacherExamAttemptGradeSectionExpandedToggled>(_onSectionToggled);
    on<TeacherExamAttemptGradeSaveRequested>(_onSave);
    on<TeacherExamAttemptGradeSaveSkillScoreRequested>(_onSaveSkillScore);
  }

  final TeacherExamRepository repository;
  final String attemptId;

  Set<String> _initialExpandedSections(Map<String, dynamic> attempt) {
    final expanded = <String>{};
    final sw = attempt['skillWork'];
    if (sw is Map) {
      for (final k in sw.keys) {
        expanded.add(k.toString());
      }
    }
    return expanded;
  }

  Future<void> _onLoad(
    TeacherExamAttemptGradeLoadRequested event,
    Emitter<TeacherExamAttemptGradeState> emit,
  ) async {
    emit(state.copyWith(status: TeacherExamAttemptGradeStatus.loading, clearError: true));
    final r = await repository.getGradingAttempt(attemptId);
    r.fold(
      (f) => emit(state.copyWith(
        status: TeacherExamAttemptGradeStatus.error,
        errorMessage: f.message,
      )),
      (d) {
        final m = Map<String, dynamic>.from(d as Map);
        emit(state.copyWith(
          status: TeacherExamAttemptGradeStatus.success,
          attempt: m,
          expandedSkillSections: _initialExpandedSections(m),
        ));
      },
    );
  }

  /// Silent refresh: nạp lại attempt KHÔNG bật status=loading → không rơi vào skeleton
  /// toàn màn, chỉ cập nhật dữ liệu tại chỗ. Giữ nguyên expandedSkillSections (UI state của GV).
  /// Lỗi refresh: giữ dữ liệu hiện tại + báo toast (không blank màn bằng status=error).
  Future<void> _onRefresh(
    TeacherExamAttemptGradeRefreshRequested event,
    Emitter<TeacherExamAttemptGradeState> emit,
  ) async {
    final r = await repository.getGradingAttempt(attemptId);
    r.fold(
      (f) => emit(state.copyWith(errorMessage: f.message)),
      (d) {
        final m = Map<String, dynamic>.from(d as Map);
        emit(state.copyWith(
          status: TeacherExamAttemptGradeStatus.success,
          attempt: m,
          clearSuccess: true, // toast của mutation đã hiện ở emit trước; tránh double-toast
        ));
      },
    );
  }

  Future<void> _onRunAi(
    TeacherExamAttemptGradeRunAiRequested event,
    Emitter<TeacherExamAttemptGradeState> emit,
  ) async {
    emit(state.copyWith(aiGrading: true, clearError: true));
    final r = await repository.runAiGradingDraft(attemptId);
    emit(state.copyWith(aiGrading: false));
    r.fold(
      (f) => emit(state.copyWith(errorMessage: f.message)),
      (_) {
        emit(state.copyWith(successMessage: 'ai_done'));
        add(const TeacherExamAttemptGradeRefreshRequested());
      },
    );
  }

  void _onSectionToggled(
    TeacherExamAttemptGradeSectionExpandedToggled event,
    Emitter<TeacherExamAttemptGradeState> emit,
  ) {
    final next = Set<String>.from(state.expandedSkillSections);
    if (next.contains(event.sectionId)) {
      next.remove(event.sectionId);
    } else {
      next.add(event.sectionId);
    }
    emit(state.copyWith(expandedSkillSections: next));
  }

  Future<void> _onSave(
    TeacherExamAttemptGradeSaveRequested event,
    Emitter<TeacherExamAttemptGradeState> emit,
  ) async {
    final body = <String, dynamic>{'items': event.items};
    if (event.finalize) body['finalize'] = true;
    final r = await repository.patchManualGrade(attemptId, body);
    r.fold(
      (f) => emit(state.copyWith(errorMessage: f.message)),
      (_) {
        emit(state.copyWith(successMessage: event.finalize ? 'finalized' : 'saved'));
        add(const TeacherExamAttemptGradeRefreshRequested());
      },
    );
  }

  Future<void> _onSaveSkillScore(
    TeacherExamAttemptGradeSaveSkillScoreRequested event,
    Emitter<TeacherExamAttemptGradeState> emit,
  ) async {
    final body = <String, dynamic>{
      'skillScores': {
        event.sectionId: {'score': event.score, 'note': event.note},
      },
    };
    final r = await repository.patchManualGrade(attemptId, body);
    r.fold(
      (f) => emit(state.copyWith(errorMessage: f.message)),
      (_) {
        emit(state.copyWith(successMessage: 'skill_saved'));
        add(const TeacherExamAttemptGradeRefreshRequested());
      },
    );
  }
}
