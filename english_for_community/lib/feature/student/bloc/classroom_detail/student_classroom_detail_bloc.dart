import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/feature/student/bloc/classroom_detail/student_classroom_detail_event.dart';
import 'package:english_for_community/feature/student/bloc/classroom_detail/student_classroom_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentClassroomDetailBloc
    extends Bloc<StudentClassroomDetailEvent, StudentClassroomDetailState> {
  StudentClassroomDetailBloc({
    required this.repository,
    required this.classroomId,
  }) : super(StudentClassroomDetailState.initial()) {
    on<StudentClassroomDetailLoadRequested>(_onLoad);
  }

  final TeacherExamRepository repository;
  final String classroomId;

  Future<void> _onLoad(
    StudentClassroomDetailLoadRequested event,
    Emitter<StudentClassroomDetailState> emit,
  ) async {
    emit(state.copyWith(status: StudentClassroomDetailStatus.loading, clearError: true));

    String? err;
    Map<String, dynamic>? room;
    List<dynamic> items = [];

    final cr = await repository.getClassroom(classroomId);
    cr.fold((f) => err = f.message, (d) => room = Map<String, dynamic>.from(d as Map));

    if (err == null) {
      final ar = await repository.listAvailableExamAssignmentsForClassroom(classroomId);
      ar.fold((f) => err = f.message, (list) => items = list);
    }

    if (err != null) {
      emit(state.copyWith(
        status: StudentClassroomDetailStatus.error,
        errorMessage: err,
      ));
      return;
    }

    emit(state.copyWith(
      status: StudentClassroomDetailStatus.success,
      classroom: room,
      assignments: items,
    ));
  }
}
