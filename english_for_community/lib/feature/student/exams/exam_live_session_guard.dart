import 'package:english_for_community/core/api/token_storage.dart';
import 'package:english_for_community/core/ui/feedback/app_feedback.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/feature/auth/bloc/user_bloc.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/socket/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pops all student live-exam routes (lobby + runner) from the navigation stack.
void exitLiveExamFlow(BuildContext context) {
  final go = GoRouter.of(context);
  while (go.canPop()) {
    final path = go.routerDelegate.state.uri.path;
    if (!path.contains('/student/exam-run') && !path.contains('/student/exam-session')) {
      break;
    }
    go.pop();
  }
}

/// Listens for teacher end-of-session and forces the student out of lobby / exam UI.
class ExamLiveSessionGuard {
  ExamLiveSessionGuard(this.context, {this.onSessionState});

  final BuildContext context;
  final void Function(Map<String, dynamic> payload)? onSessionState;
  String? _sessionId;
  bool _handled = false;
  Future<void>? _binding;

  /// Ensures exam socket is registered + joined before live-view sync emits.
  Future<void> ensureBound(String sessionId) async {
    if (_sessionId == sessionId && _binding != null) {
      await _binding;
      return;
    }
    bindSession(sessionId);
    if (_binding != null) await _binding;
  }

  void bindFromAttempt(Map<String, dynamic>? attempt) {
    final ctx = attempt?['runtimeContext'];
    if (ctx is! Map || ctx['assignmentMode'] != 'realtime') return;
    final sessionId = ctx['sessionId']?.toString();
    if (sessionId == null || sessionId.isEmpty) return;
    bindSession(sessionId);
  }

  void bindSession(String sessionId) {
    if (_sessionId == sessionId && _binding != null) return;
    _sessionId = sessionId;
    _handled = false;
    unbind();
    _binding = _wireSocket(sessionId);
  }

  Future<void> _wireSocket(String sessionId) async {
    final token = await TokenStorage.readAccessToken() ?? '';
    if (token.isEmpty || !context.mounted) return;
    final socket = getIt<SocketService>();
    socket.setExamRealtimeContext(accessToken: token, sessionId: sessionId);
    socket.listenExamSessionState(_onSessionState);
    socket.listenExamSessionEnded(_onSessionEnded);
    socket.listenExamSessionKicked(_onKicked);
  }

  void _onKicked(Map<String, dynamic> payload) {
    final sid = payload['sessionId']?.toString();
    if (_sessionId != null && sid != null && sid != _sessionId) return;
    final myId = getIt<UserBloc>().state.userEntity?.id;
    final kickedId = payload['userId']?.toString();
    if (myId == null || kickedId == null || myId != kickedId) return;
    _exitKicked();
  }

  Future<void> _exitKicked() async {
    if (_handled || !context.mounted) return;
    _handled = true;
    unbind();
    getIt<SocketService>().clearExamRealtimeContext();
    AppFeedback.error(context, context.l10n.examSessionKickedByTeacher, blocking: true);
    exitLiveExamFlow(context);
  }

  void _onSessionState(Map<String, dynamic> payload) {
    final sid = payload['sessionId']?.toString();
    if (_sessionId != null && sid != null && sid != _sessionId) return;
    onSessionState?.call(payload);
    final st = payload['status']?.toString();
    if (st == 'closed' || st == 'grading') {
      _exit();
    }
  }

  void _onSessionEnded(Map<String, dynamic> payload) {
    final sid = payload['sessionId']?.toString();
    if (_sessionId != null && sid != null && sid != _sessionId) return;
    _exit();
  }

  Future<void> _exit() async {
    if (_handled || !context.mounted) return;
    _handled = true;
    unbind();
    getIt<SocketService>().clearExamRealtimeContext();
    AppFeedback.error(context, context.l10n.examSessionEndedByTeacher, blocking: true);
    exitLiveExamFlow(context);
  }

  void unbind() {
    final socket = getIt<SocketService>();
    socket.offExamSessionState();
    socket.offExamSessionEnded();
    socket.offExamSessionKicked();
  }

  void dispose() {
    unbind();
  }
}
