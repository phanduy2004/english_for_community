import 'package:english_for_community/core/repository/classroom_chat_repository.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/feature/student/bloc/classroom_detail/student_classroom_detail_event.dart';
import 'package:english_for_community/feature/student/bloc/classroom_detail/student_classroom_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentClassroomDetailBloc
    extends Bloc<StudentClassroomDetailEvent, StudentClassroomDetailState> {
  StudentClassroomDetailBloc({
    required this.repository,
    required this.chatRepository,
    required this.classroomId,
  }) : super(StudentClassroomDetailState.initial()) {
    on<StudentClassroomDetailLoadRequested>(_onLoad);
    on<StudentClassroomDetailSegmentChanged>(_onSegmentChanged);
    on<StudentClassroomDetailSortChanged>(_onSortChanged);
    on<StudentClassroomDetailLeaveRequested>(_onLeave);
  }

  final TeacherExamRepository repository;
  final ClassroomChatRepository chatRepository;
  final String classroomId;

  void _onSegmentChanged(
    StudentClassroomDetailSegmentChanged event,
    Emitter<StudentClassroomDetailState> emit,
  ) {
    emit(state.copyWith(assignmentSegment: event.segment));
  }

  void _onSortChanged(
    StudentClassroomDetailSortChanged event,
    Emitter<StudentClassroomDetailState> emit,
  ) {
    emit(state.copyWith(assignmentSort: event.sort));
  }

  Future<void> _onLoad(
    StudentClassroomDetailLoadRequested event,
    Emitter<StudentClassroomDetailState> emit,
  ) async {
    final silent = event.silent && state.classroom != null;
    if (silent) {
      emit(state.copyWith(isRefreshing: true, clearError: true));
    } else {
      emit(state.copyWith(
        status: StudentClassroomDetailStatus.loading,
        membersStatus: StudentClassroomMembersStatus.loading,
        clearError: true,
      ));
    }

    String? err;
    Map<String, dynamic>? room;
    List<dynamic> items = [];
    var members = state.members;
    var settings = state.chatSettings;

    final cr = await repository.getClassroom(classroomId);
    cr.fold((f) => err = f.message, (d) => room = Map<String, dynamic>.from(d as Map));

    if (err == null) {
      final ar = await repository.listAvailableExamAssignmentsForClassroom(classroomId);
      ar.fold((f) => err = f.message, (list) => items = list);
    }

    if (err == null) {
      final mr = await chatRepository.getChatMembers(classroomId);
      mr.fold(
        (_) => members = const [],
        (list) => members = list,
      );
    }

    if (err == null) {
      final sr = await chatRepository.getChatSettings(classroomId);
      sr.fold((_) {}, (s) => settings = s);
    }

    if (err != null) {
      emit(state.copyWith(
        status: silent ? state.status : StudentClassroomDetailStatus.error,
        errorMessage: err,
        membersStatus: silent
            ? state.membersStatus
            : StudentClassroomMembersStatus.error,
        isRefreshing: false,
      ));
      return;
    }

    emit(state.copyWith(
      status: StudentClassroomDetailStatus.success,
      classroom: room,
      assignments: items,
      members: members,
      membersStatus: StudentClassroomMembersStatus.success,
      chatSettings: settings,
      isRefreshing: false,
    ));
  }

  Future<void> _onLeave(
    StudentClassroomDetailLeaveRequested event,
    Emitter<StudentClassroomDetailState> emit,
  ) async {
    emit(state.copyWith(
      leaveStatus: StudentClassroomLeaveStatus.leaving,
      clearLeaveError: true,
    ));
    final result = await repository.leaveClassroom(classroomId);
    result.fold(
      (f) => emit(state.copyWith(
        leaveStatus: StudentClassroomLeaveStatus.error,
        leaveError: f.message,
      )),
      (_) => emit(state.copyWith(leaveStatus: StudentClassroomLeaveStatus.success)),
    );
  }
}
