import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/feature/student/bloc/classes_hub/student_classes_hub_event.dart';
import 'package:english_for_community/feature/student/bloc/classes_hub/student_classes_hub_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentClassesHubBloc extends Bloc<StudentClassesHubEvent, StudentClassesHubState> {
  StudentClassesHubBloc({required this.repository}) : super(StudentClassesHubState.initial()) {
    on<StudentClassesHubLoadRequested>(_onLoad);
    on<StudentClassesHubJoinByCodeRequested>(_onJoinByCode);
    on<StudentClassesHubJoinByTokenRequested>(_onJoinByToken);
  }

  final TeacherExamRepository repository;

  Future<void> _onLoad(
    StudentClassesHubLoadRequested event,
    Emitter<StudentClassesHubState> emit,
  ) async {
    emit(state.copyWith(
      status: StudentClassesHubStatus.loading,
      clearError: true,
      clearJoinSuccess: true,
    ));
    final r = await repository.listEnrolledClassrooms();
    r.fold(
      (f) => emit(state.copyWith(
        status: StudentClassesHubStatus.error,
        errorMessage: f.message,
      )),
      (list) => emit(state.copyWith(
        status: StudentClassesHubStatus.success,
        classes: list,
      )),
    );
  }

  Future<void> _onJoinByCode(
    StudentClassesHubJoinByCodeRequested event,
    Emitter<StudentClassesHubState> emit,
  ) async {
    emit(state.copyWith(joiningByCode: true, clearError: true));
    final r = await repository.joinClassByCode(event.code);
    r.fold(
      (f) => emit(state.copyWith(joiningByCode: false, errorMessage: f.message)),
      (_) {
        emit(state.copyWith(joiningByCode: false, joinSuccess: true));
        add(const StudentClassesHubLoadRequested());
      },
    );
  }

  Future<void> _onJoinByToken(
    StudentClassesHubJoinByTokenRequested event,
    Emitter<StudentClassesHubState> emit,
  ) async {
    emit(state.copyWith(joiningByToken: true, clearError: true));
    final r = await repository.joinClassByToken(event.token);
    r.fold(
      (f) => emit(state.copyWith(joiningByToken: false, errorMessage: f.message)),
      (_) {
        emit(state.copyWith(joiningByToken: false, joinSuccess: true));
        add(const StudentClassesHubLoadRequested());
      },
    );
  }
}
