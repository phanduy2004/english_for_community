import 'dart:async';

import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:english_for_community/core/api/token_storage.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/socket/socket_service.dart';
import 'package:english_for_community/feature/teacher/bloc/exam_session_console/teacher_exam_session_console_event.dart';
import 'package:english_for_community/feature/teacher/bloc/exam_session_console/teacher_exam_session_console_lobby.dart';
import 'package:english_for_community/feature/teacher/bloc/exam_session_console/teacher_exam_session_console_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherExamSessionConsoleBloc
    extends Bloc<TeacherExamSessionConsoleEvent, TeacherExamSessionConsoleState> {
  TeacherExamSessionConsoleBloc({
    required this.repository,
    required this.socketService,
    required this.assignmentId,
  }) : super(TeacherExamSessionConsoleState.initial()) {
    on<TeacherExamSessionConsoleStarted>(_onStarted);
    on<TeacherExamSessionConsoleLobbyPayloadReceived>(_onLobbyPayloadReceived);
    on<TeacherExamSessionConsoleLobbyApplied>(_onLobbyApplied);
    on<TeacherExamSessionConsoleCreateRequested>(_onCreate);
    on<TeacherExamSessionConsoleStartRequested>(_onStart);
    on<TeacherExamSessionConsoleEndRequested>(_onEnd);
    on<TeacherExamSessionConsoleKickRequested>(_onKick);
    on<TeacherExamSessionConsoleReloadRequested>(_onReload);
    on<TeacherExamSessionConsoleStopped>(_onStopped);
  }

  final TeacherExamRepository repository;
  final SocketService socketService;
  final String assignmentId;

  void Function(Map<String, dynamic>)? _onSocketLobby;
  Timer? _lobbyDebounce;

  Future<void> _onStarted(
    TeacherExamSessionConsoleStarted event,
    Emitter<TeacherExamSessionConsoleState> emit,
  ) async {
    emit(state.copyWith(
      status: TeacherExamSessionConsoleStatus.loading,
      clearError: true,
    ));
    final r = await repository.getSessionConsole(assignmentId);
    await r.fold(
      (f) async {
        emit(state.copyWith(
          status: TeacherExamSessionConsoleStatus.error,
          errorMessage: f.message,
        ));
      },
      (data) async {
        final m = Map<String, dynamic>.from(data as Map);
        Map<String, dynamic>? assignmentContext;
        final ctx = m['assignment'];
        if (ctx is Map) assignmentContext = Map<String, dynamic>.from(ctx);

        Map<String, dynamic>? session;
        final sessionDoc = m['session'];
        if (sessionDoc is Map) session = Map<String, dynamic>.from(sessionDoc);

        var next = TeacherExamSessionConsoleState(
          status: TeacherExamSessionConsoleStatus.success,
          assignmentContext: assignmentContext,
          session: session,
          boundSessionId: state.boundSessionId,
        );

        final live = m['liveState'];
        if (live is Map) {
          next = applyLobbyPayload(next, Map<String, dynamic>.from(live));
        }

        Map<String, dynamic>? liveMonitor;
        final lm = m['liveMonitor'];
        if (lm is Map) {
          liveMonitor = Map<String, dynamic>.from(lm);
        } else if (next.sessionStatus != 'live' && next.sessionStatus != 'grading') {
          liveMonitor = null;
        }

        final sid = next.sessionId ?? '';
        if (sid.isNotEmpty && next.sessionStatus == 'live' && liveMonitor == null) {
          final lmR = await repository.getSessionLiveMonitor(sid);
          lmR.fold((_) {}, (d) {
            if (d is Map) liveMonitor = Map<String, dynamic>.from(d);
          });
        }

        emit(next.copyWith(
          liveMonitor: liveMonitor,
          clearLiveMonitor: liveMonitor == null,
        ));
        if (sid.isNotEmpty && (next.isLobby || next.isLive)) {
          await _bindLiveSocket(sid, emit);
        }
      },
    );
  }

  Future<void> _onReload(
    TeacherExamSessionConsoleReloadRequested event,
    Emitter<TeacherExamSessionConsoleState> emit,
  ) async {
    add(TeacherExamSessionConsoleStarted(assignmentId));
  }

  void _onLobbyPayloadReceived(
    TeacherExamSessionConsoleLobbyPayloadReceived event,
    Emitter<TeacherExamSessionConsoleState> emit,
  ) {
    if (event.payload['sessionId']?.toString() != state.boundSessionId) return;
    _lobbyDebounce?.cancel();
    _lobbyDebounce = Timer(AppMotion.fast, () {
      if (isClosed) return;
      add(TeacherExamSessionConsoleLobbyApplied(event.payload));
    });
  }

  void _onLobbyApplied(
    TeacherExamSessionConsoleLobbyApplied event,
    Emitter<TeacherExamSessionConsoleState> emit,
  ) {
    emit(applyLobbyPayload(state, event.payload));
  }

  Future<void> _bindLiveSocket(
    String sessionId,
    Emitter<TeacherExamSessionConsoleState> emit,
  ) async {
    if (sessionId.isEmpty) return;
    if (state.boundSessionId == sessionId && _onSocketLobby != null) return;

    _detachSocket();
    emit(state.copyWith(boundSessionId: sessionId));

    await _refreshLobbySnapshot(sessionId, emit);

    final token = await TokenStorage.readAccessToken() ?? '';
    if (token.isEmpty) return;

    socketService.setExamRealtimeContext(accessToken: token, sessionId: sessionId);
    _onSocketLobby = (payload) {
      add(TeacherExamSessionConsoleLobbyPayloadReceived(payload));
    };
    socketService.listenExamSessionState(_onSocketLobby!);
  }

  Future<void> _refreshLobbySnapshot(
    String sessionId,
    Emitter<TeacherExamSessionConsoleState> emit,
  ) async {
    final r = await repository.getExamSessionLobby(sessionId);
    r.fold((_) {}, (data) {
      if (data is Map) {
        emit(applyLobbyPayload(state, Map<String, dynamic>.from(data)));
      }
    });
  }

  Future<void> _onCreate(
    TeacherExamSessionConsoleCreateRequested event,
    Emitter<TeacherExamSessionConsoleState> emit,
  ) async {
    emit(state.copyWith(busy: true));
    final r = await repository.createExamSession(assignmentId);
    emit(state.copyWith(busy: false));
    await r.fold(
      (_) async {},
      (d) async {
        final m = Map<String, dynamic>.from(d as Map);
        emit(state.copyWith(session: m));
        final id = state.sessionId ?? m['id']?.toString() ?? m['_id']?.toString() ?? '';
        if (id.isNotEmpty) await _bindLiveSocket(id, emit);
        add(TeacherExamSessionConsoleStarted(assignmentId));
      },
    );
  }

  Future<void> _onStart(
    TeacherExamSessionConsoleStartRequested event,
    Emitter<TeacherExamSessionConsoleState> emit,
  ) async {
    final id = state.sessionId ?? '';
    if (id.isEmpty) return;
    emit(state.copyWith(busy: true));
    final r = await repository.startExamSession(id);
    emit(state.copyWith(busy: false));
    await r.fold(
      (_) async {},
      (d) async {
        emit(state.copyWith(session: Map<String, dynamic>.from(d as Map)));
        add(TeacherExamSessionConsoleStarted(assignmentId));
      },
    );
  }

  Future<void> _onEnd(
    TeacherExamSessionConsoleEndRequested event,
    Emitter<TeacherExamSessionConsoleState> emit,
  ) async {
    final id = state.sessionId ?? '';
    if (id.isEmpty) return;
    emit(state.copyWith(busy: true));
    final r = await repository.endExamSession(id);
    emit(state.copyWith(busy: false));
    await r.fold(
      (_) async {},
      (d) async {
        emit(state.copyWith(session: Map<String, dynamic>.from(d as Map)));
        await _refreshLobbySnapshot(id, emit);
      },
    );
  }

  Future<void> _onKick(
    TeacherExamSessionConsoleKickRequested event,
    Emitter<TeacherExamSessionConsoleState> emit,
  ) async {
    final sid = state.sessionId ?? '';
    if (sid.isEmpty || event.userId.isEmpty) return;
    emit(state.copyWith(busy: true));
    final r = await repository.kickExamSessionParticipant(sid, event.userId);
    emit(state.copyWith(busy: false));
    r.fold((_) {}, (data) {
      if (data is Map) {
        emit(applyLobbyPayload(state, Map<String, dynamic>.from(data)));
      }
    });
  }

  void _onStopped(
    TeacherExamSessionConsoleStopped event,
    Emitter<TeacherExamSessionConsoleState> emit,
  ) {
    _detachSocket();
  }

  void _detachSocket() {
    _lobbyDebounce?.cancel();
    _lobbyDebounce = null;
    if (_onSocketLobby != null) {
      socketService.offExamSessionState();
      socketService.clearExamRealtimeContext();
      _onSocketLobby = null;
    }
  }

  @override
  Future<void> close() {
    _detachSocket();
    return super.close();
  }
}
