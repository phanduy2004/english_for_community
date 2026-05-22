import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/feature/teacher/bloc/classroom/teacher_classroom_event.dart';
import 'package:english_for_community/feature/teacher/bloc/classroom/teacher_classroom_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherClassroomBloc extends Bloc<TeacherClassroomEvent, TeacherClassroomState> {
  TeacherClassroomBloc({
    required this.repository,
    required this.classroomId,
  }) : super(TeacherClassroomState.initial()) {
    on<TeacherClassroomLoadRequested>(_onLoad);
    on<TeacherClassroomSaveSettingsRequested>(_onSaveSettings);
    on<TeacherClassroomApproveMemberRequested>(_onApprove);
    on<TeacherClassroomRejectMemberRequested>(_onReject);
    on<TeacherClassroomRemoveMemberRequested>(_onRemove);
    on<TeacherClassroomRotateInviteRequested>(_onRotateInvite);
    on<TeacherClassroomArchiveRequested>(_onArchive);
    on<TeacherClassroomDeleteAssignmentRequested>(_onDeleteAssignment);
    on<TeacherClassroomCloseAssignmentRequested>(_onCloseAssignment);
  }

  final TeacherExamRepository repository;
  final String classroomId;

  Future<void> _onLoad(
    TeacherClassroomLoadRequested event,
    Emitter<TeacherClassroomState> emit,
  ) async {
    if (!event.silent) {
      emit(state.copyWith(
        status: TeacherClassroomStatus.loading,
        clearError: true,
      ));
    } else {
      emit(state.copyWith(clearError: true));
    }

    String? err;
    Map<String, dynamic>? room;
    List<dynamic> items = [];
    List<dynamic> members = [];

    final cr = await repository.getClassroom(classroomId);
    cr.fold((f) => err = f.message, (d) => room = Map<String, dynamic>.from(d as Map));

    if (err == null) {
      final ar = await repository.listClassroomAssignments(classroomId);
      ar.fold((f) => err = f.message, (list) => items = list);
    }

    if (err == null) {
      final mr = await repository.listClassroomMembers(classroomId);
      mr.fold((f) => err ??= f.message, (list) => members = list);
    }

    if (err != null) {
      emit(state.copyWith(
        status: TeacherClassroomStatus.error,
        errorMessage: err,
      ));
      return;
    }

    emit(state.copyWith(
      status: TeacherClassroomStatus.success,
      classroom: room,
      assignments: items,
      members: members,
    ));
  }

  Future<void> _onSaveSettings(
    TeacherClassroomSaveSettingsRequested event,
    Emitter<TeacherClassroomState> emit,
  ) async {
    emit(state.copyWith(settingsSaving: true));
    final r = await repository.patchClassroom(classroomId, {
      'name': event.name,
      'description': event.description,
    });
    r.fold(
      (f) => emit(state.copyWith(settingsSaving: false, errorMessage: f.message)),
      (_) {
        emit(state.copyWith(settingsSaving: false));
        add(const TeacherClassroomLoadRequested());
      },
    );
  }

  Future<void> _onApprove(
    TeacherClassroomApproveMemberRequested event,
    Emitter<TeacherClassroomState> emit,
  ) async {
    emit(state.copyWith(mutationInProgress: true));
    final r = await repository.approveClassroomMember(classroomId, event.userId);
    r.fold(
      (f) => emit(state.copyWith(mutationInProgress: false, errorMessage: f.message)),
      (_) {
        emit(state.copyWith(mutationInProgress: false));
        add(const TeacherClassroomLoadRequested());
      },
    );
  }

  Future<void> _onReject(
    TeacherClassroomRejectMemberRequested event,
    Emitter<TeacherClassroomState> emit,
  ) async {
    emit(state.copyWith(mutationInProgress: true));
    final r = await repository.rejectClassroomMember(classroomId, event.userId);
    r.fold(
      (f) => emit(state.copyWith(mutationInProgress: false, errorMessage: f.message)),
      (_) {
        emit(state.copyWith(mutationInProgress: false));
        add(const TeacherClassroomLoadRequested());
      },
    );
  }

  Future<void> _onRemove(
    TeacherClassroomRemoveMemberRequested event,
    Emitter<TeacherClassroomState> emit,
  ) async {
    emit(state.copyWith(mutationInProgress: true));
    final r = await repository.removeClassroomMember(classroomId, event.userId);
    r.fold(
      (f) => emit(state.copyWith(mutationInProgress: false, errorMessage: f.message)),
      (_) {
        emit(state.copyWith(mutationInProgress: false));
        add(const TeacherClassroomLoadRequested());
      },
    );
  }

  Future<void> _onRotateInvite(
    TeacherClassroomRotateInviteRequested event,
    Emitter<TeacherClassroomState> emit,
  ) async {
    emit(state.copyWith(mutationInProgress: true));
    final r = await repository.rotateClassroomInvite(classroomId);
    r.fold(
      (f) => emit(state.copyWith(mutationInProgress: false, errorMessage: f.message)),
      (_) {
        emit(state.copyWith(mutationInProgress: false));
        add(const TeacherClassroomLoadRequested());
      },
    );
  }

  Future<void> _onArchive(
    TeacherClassroomArchiveRequested event,
    Emitter<TeacherClassroomState> emit,
  ) async {
    emit(state.copyWith(mutationInProgress: true));
    final r = await repository.archiveClassroom(classroomId);
    r.fold(
      (f) => emit(state.copyWith(mutationInProgress: false, errorMessage: f.message)),
      (_) => emit(state.copyWith(mutationInProgress: false, archived: true)),
    );
  }

  Future<void> _onDeleteAssignment(
    TeacherClassroomDeleteAssignmentRequested event,
    Emitter<TeacherClassroomState> emit,
  ) async {
    emit(state.copyWith(mutationInProgress: true, clearError: true));
    final r = await repository.deleteExamAssignment(event.assignmentId);
    r.fold(
      (f) => emit(state.copyWith(mutationInProgress: false, errorMessage: f.message)),
      (_) {
        emit(state.copyWith(mutationInProgress: false));
        add(const TeacherClassroomLoadRequested());
      },
    );
  }

  Future<void> _onCloseAssignment(
    TeacherClassroomCloseAssignmentRequested event,
    Emitter<TeacherClassroomState> emit,
  ) async {
    emit(state.copyWith(mutationInProgress: true, clearError: true));
    final r = await repository.closeExamAssignment(event.assignmentId);
    r.fold(
      (f) => emit(state.copyWith(mutationInProgress: false, errorMessage: f.message)),
      (_) {
        emit(state.copyWith(mutationInProgress: false));
        add(const TeacherClassroomLoadRequested());
      },
    );
  }
}
