import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/feature/teacher/bloc/apply/teacher_apply_event.dart';
import 'package:english_for_community/feature/teacher/bloc/apply/teacher_apply_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherApplyBloc extends Bloc<TeacherApplyEvent, TeacherApplyState> {
  TeacherApplyBloc({required this.repository}) : super(TeacherApplyState.initial()) {
    on<TeacherApplyLoadRequested>(_onLoad);
    on<TeacherApplySubmitRequested>(_onSubmit);
    on<TeacherApplyWithdrawRequested>(_onWithdraw);
  }

  final TeacherExamRepository repository;

  Future<void> _onLoad(
    TeacherApplyLoadRequested event,
    Emitter<TeacherApplyState> emit,
  ) async {
    emit(state.copyWith(status: TeacherApplyStatus.loading, clearError: true));
    final r = await repository.getMyTeacherApplication();
    r.fold(
      (f) => emit(state.copyWith(
        status: TeacherApplyStatus.error,
        errorMessage: f.message,
      )),
      (app) {
        if (app != null && app.isNotEmpty) {
          emit(state.copyWith(
            status: TeacherApplyStatus.success,
            existingApplication: Map<String, dynamic>.from(app as Map),
          ));
        } else {
          emit(state.copyWith(status: TeacherApplyStatus.success));
        }
      },
    );
  }

  Future<void> _onSubmit(
    TeacherApplySubmitRequested event,
    Emitter<TeacherApplyState> emit,
  ) async {
    emit(state.copyWith(submitting: true, clearError: true));
    final r = await repository.submitTeacherApplication(
      bio: event.bio,
      organization: event.organization,
    );
    r.fold(
      (f) => emit(state.copyWith(submitting: false, errorMessage: f.message)),
      (_) {
        emit(state.copyWith(submitting: false, status: TeacherApplyStatus.submitted));
        add(const TeacherApplyLoadRequested());
      },
    );
  }

  Future<void> _onWithdraw(
    TeacherApplyWithdrawRequested event,
    Emitter<TeacherApplyState> emit,
  ) async {
    emit(state.copyWith(submitting: true, clearError: true));
    final r = await repository.withdrawTeacherApplication();
    r.fold(
      (f) => emit(state.copyWith(submitting: false, errorMessage: f.message)),
      (_) {
        emit(state.copyWith(submitting: false));
        add(const TeacherApplyLoadRequested());
      },
    );
  }
}
