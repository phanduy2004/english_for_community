import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/socket/socket_service.dart';
import 'package:english_for_community/feature/teacher/bloc/live_monitor/teacher_live_monitor_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/student_live_screen/teacher_student_live_screen_event.dart';
import 'package:english_for_community/feature/teacher/bloc/student_live_screen/teacher_student_live_screen_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherStudentLiveScreenBloc
    extends Bloc<TeacherStudentLiveScreenEvent, TeacherStudentLiveScreenState> {
  TeacherStudentLiveScreenBloc({
    required this.repository,
    required this.socketService,
    required this.attemptId,
  }) : super(TeacherStudentLiveScreenState.initial()) {
    on<TeacherStudentLiveScreenStarted>(_onStarted);
    on<TeacherStudentLiveScreenPayloadReceived>(_onPayload);
    on<TeacherStudentLiveScreenStopped>(_onStopped);
  }

  final TeacherExamRepository repository;
  final SocketService socketService;
  final String attemptId;

  void Function(Map<String, dynamic>)? _onLiveScreen;
  void Function(Map<String, dynamic>)? _onLiveProgress;

  Future<void> _onStarted(
    TeacherStudentLiveScreenStarted event,
    Emitter<TeacherStudentLiveScreenState> emit,
  ) async {
    if (event.initialLiveScreen != null && event.initialLiveScreen!.isNotEmpty) {
      emit(state.copyWith(
        status: TeacherStudentLiveScreenStatus.success,
        liveScreen: Map<String, dynamic>.from(event.initialLiveScreen!),
      ));
    } else {
      emit(state.copyWith(status: TeacherStudentLiveScreenStatus.loading, clearError: true));
    }

    // Gỡ listener cũ trước khi đăng ký lại — nếu _onStarted chạy lại (retry sau lỗi),
    // closure cũ sẽ kẹt vĩnh viễn trên socket dùng chung → rò + xử lý trùng.
    _detach();
    _onLiveScreen = (p) => add(TeacherStudentLiveScreenPayloadReceived(p));
    _onLiveProgress = (p) => add(TeacherStudentLiveScreenPayloadReceived(p));
    socketService.listenExamSessionLiveScreen(_onLiveScreen!);
    socketService.listenExamSessionLiveProgress(_onLiveProgress!);

    final r = await repository.getAttemptLiveScreen(attemptId);
    r.fold(
      (f) => emit(state.copyWith(
        status: TeacherStudentLiveScreenStatus.error,
        errorMessage: f.message,
      )),
      (data) {
        if (data is Map) {
          emit(state.copyWith(
            status: TeacherStudentLiveScreenStatus.success,
            liveScreen: Map<String, dynamic>.from(data),
          ));
        } else if (state.liveScreen == null) {
          emit(state.copyWith(status: TeacherStudentLiveScreenStatus.success));
        }
      },
    );
  }

  void _onPayload(
    TeacherStudentLiveScreenPayloadReceived event,
    Emitter<TeacherStudentLiveScreenState> emit,
  ) {
    if (event.payload['attemptId']?.toString() != attemptId) return;
    final prev = state.liveScreen;
    if (prev == null || prev.isEmpty) {
      emit(state.copyWith(
        status: TeacherStudentLiveScreenStatus.success,
        liveScreen: Map<String, dynamic>.from(event.payload),
      ));
    } else {
      emit(state.copyWith(
        status: TeacherStudentLiveScreenStatus.success,
        liveScreen: mergeTeacherLivePayload(prev, event.payload),
      ));
    }
  }

  void _onStopped(
    TeacherStudentLiveScreenStopped event,
    Emitter<TeacherStudentLiveScreenState> emit,
  ) {
    _detach();
  }

  void _detach() {
    if (_onLiveScreen != null) {
      socketService.offExamSessionLiveScreen(_onLiveScreen);
      _onLiveScreen = null;
    }
    if (_onLiveProgress != null) {
      socketService.offExamSessionLiveProgress(_onLiveProgress);
      _onLiveProgress = null;
    }
  }

  @override
  Future<void> close() {
    _detach();
    return super.close();
  }
}
