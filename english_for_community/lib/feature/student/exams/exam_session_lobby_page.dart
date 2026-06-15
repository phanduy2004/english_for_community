import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/socket/socket_service.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/auth/bloc/user_bloc.dart';
import 'package:english_for_community/feature/student/exams/exam_live_session_guard.dart';
import 'package:english_for_community/feature/student/exams/exam_session_status_banner.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Realtime exam: REST join lobby + Socket.IO `exam_session_state` for go-live.
class ExamSessionLobbyPage extends StatefulWidget {
  const ExamSessionLobbyPage({super.key, required this.sessionId});

  final String sessionId;

  static const String routePath = '/student/exam-session';
  static const String routeName = 'ExamSessionLobbyPage';

  @override
  State<ExamSessionLobbyPage> createState() => _ExamSessionLobbyPageState();
}

class _ExamSessionLobbyPageState extends State<ExamSessionLobbyPage> {
  String? _status;
  String? _roomCode;
  String? _error;
  bool _loading = true;
  List<Map<String, dynamic>> _participants = [];
  int _joinedCount = 0;
  int _readyCount = 0;
  bool _myReady = false;
  Map<String, dynamic>? _sessionContext;
  ExamLiveSessionGuard? _liveGuard;
  bool _bootstrapStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _liveGuard ??= ExamLiveSessionGuard(context, onSessionState: _onSocketState);
    if (!_bootstrapStarted) {
      _bootstrapStarted = true;
      _bootstrap();
    }
  }

  String? _blockedMessageFromAttempt(dynamic att) {
    if (att is! Map) return null;
    if (att['blocked'] == true) {
      return (att['message'] as String?)?.trim();
    }
    return null;
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final l10n = context.l10n;
    final myAttempt = await getIt<TeacherExamRepository>().getSessionMyAttempt(widget.sessionId);
    myAttempt.fold((_) {}, (att) {
      final blocked = _blockedMessageFromAttempt(att);
      if (blocked != null && blocked.isNotEmpty) {
        _error = blocked;
      } else if (att is Map && att['blocked'] == true) {
        _error = l10n.studentExamVoluntaryExitBlocked;
      }
    });
    if (_error != null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final join = await getIt<TeacherExamRepository>().joinExamSession(widget.sessionId);
    await join.fold(
      (f) async {
        final resume = await getIt<TeacherExamRepository>().getSessionMyAttempt(widget.sessionId);
        resume.fold((_) {
          if (mounted) setState(() => _error = f.message);
        }, (att) async {
          if (_blockedMessageFromAttempt(att) != null || (att is Map && att['blocked'] == true)) {
            if (mounted) {
              setState(() => _error = l10n.studentExamVoluntaryExitBlocked);
            }
            return;
          }
          final id = att is Map ? (att['id'] as String? ?? '') : '';
          if (id.isNotEmpty && att is Map && att['status'] == 'in_progress') {
            final retry = await getIt<TeacherExamRepository>().joinExamSession(widget.sessionId);
            await retry.fold(
              (f2) {
                if (mounted) setState(() => _error = f2.message);
              },
              (session) {
                final m = Map<String, dynamic>.from(session as Map);
                if (mounted) {
                  setState(() {
                    _status = m['status'] as String?;
                    _roomCode = m['roomCode'] as String?;
                    _error = null;
                  });
                }
              },
            );
            return;
          }
          if (mounted) {
            final msg = f.message.toLowerCase();
            if (msg.contains('cannot rejoin') || msg.contains('after leaving')) {
              setState(() => _error = l10n.studentExamCannotRejoinAfterLeave);
            } else {
              setState(() => _error = f.message);
            }
          }
        });
      },
      (session) async {
        final m = Map<String, dynamic>.from(session as Map);
        if (mounted) {
          setState(() {
            _status = m['status'] as String?;
            _roomCode = m['roomCode'] as String?;
            _error = null;
          });
        }
      },
    );

    _liveGuard?.bindSession(widget.sessionId);

    if (mounted) setState(() => _loading = false);
    if (_status == 'closed' || _status == 'grading') {
      if (mounted) {
        AppCornerToast.show(context, context.l10n.examSessionEndedByTeacher, error: true);
        exitLiveExamFlow(context);
      }
      return;
    }
    await _tryOpenAttemptIfReady();
  }

  void _onSocketState(Map<String, dynamic> payload) {
    final sid = payload['sessionId']?.toString();
    if (sid != widget.sessionId) return;
    final st = payload['status']?.toString();
    if (mounted) {
      setState(() {
        if (st != null) _status = st;
        _ingestLobbyPayload(payload);
      });
    }
    if (st != 'closed' && st != 'grading') {
      _tryOpenAttemptIfReady();
    }
  }

  void _ingestLobbyPayload(Map<String, dynamic> p) {
    final raw = p['participants'];
    if (raw is List) {
      _participants = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    final jc = p['joinedCount'];
    if (jc is num) {
      _joinedCount = jc.toInt();
    } else {
      _joinedCount = _participants.length;
    }
    final rc = p['roomCode'];
    if (rc is String && rc.isNotEmpty) _roomCode = rc;
    final rdy = p['readyCount'];
    if (rdy is num) {
      _readyCount = rdy.toInt();
    } else {
      _readyCount = _participants.where((x) => x['ready'] == true).length;
    }
    final ctx = p['context'];
    if (ctx is Map) _sessionContext = Map<String, dynamic>.from(ctx);
    _syncMyReady();
  }

  void _syncMyReady() {
    final myId = getIt<UserBloc>().state.userEntity?.id;
    if (myId == null) return;
    for (final p in _participants) {
      if (p['userId']?.toString() == myId) {
        _myReady = p['ready'] == true;
        return;
      }
    }
  }

  void _setReady(bool ready) {
    getIt<SocketService>().emitExamSessionSetReady(sessionId: widget.sessionId, ready: ready);
    setState(() => _myReady = ready);
  }

  String _lobbyName(Map<String, dynamic> p) {
    final n = (p['fullName'] as String?)?.trim();
    if (n != null && n.isNotEmpty) return n;
    final u = (p['username'] as String?)?.trim();
    if (u != null && u.isNotEmpty) return u;
    final e = (p['email'] as String?)?.trim();
    if (e != null && e.isNotEmpty) return e;
    return '';
  }

  String _lobbySubtitle(Map<String, dynamic> p) {
    final e = (p['email'] as String?)?.trim();
    if (e != null && e.isNotEmpty) return e;
    return '';
  }

  Future<void> _tryOpenAttemptIfReady() async {
    if (_status != 'live') return;
    if (_error != null) return;
    final r = await getIt<TeacherExamRepository>().getSessionMyAttempt(widget.sessionId);
    await r.fold((_) async {}, (att) async {
      if (att == null) return;
      if (att is Map && att['blocked'] == true) {
        if (mounted) {
          setState(() {
            _error = (att['message'] as String?) ?? context.l10n.studentExamVoluntaryExitBlocked;
          });
        }
        return;
      }
      final m = Map<String, dynamic>.from(att as Map);
      final id = m['id'] as String? ?? '';
      if (id.isEmpty || !mounted) return;
      if ((m['status'] as String?) != 'in_progress') return;
      await context.push('/student/exam-run/$id');
    });
  }

  @override
  void dispose() {
    _liveGuard?.dispose();
    getIt<SocketService>().clearExamRealtimeContext();
    super.dispose();
  }

  ButtonStyle _compactFilledStyle() => FilledButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );

  ButtonStyle _compactOutlinedStyle() => OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        side: const BorderSide(color: AppColors.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );

  Widget _buildBottomActions(BuildContext context, String st, AppLocalizations l10n) {
    final canOpen = st == 'live' && _error == null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s4,
        AppSpacing.s5,
        AppSpacing.s4 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(top: BorderSide(color: AppColors.outlineMuted)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.s3,
        runSpacing: AppSpacing.s3,
        children: [
          if (st == 'lobby')
            _myReady
                ? OutlinedButton(
                    style: _compactOutlinedStyle(),
                    onPressed: () => _setReady(false),
                    child: Text(l10n.examSessionCancelReady),
                  )
                : FilledButton(
                    style: _compactFilledStyle(),
                    onPressed: () => _setReady(true),
                    child: Text(l10n.examSessionMarkReady),
                  ),
          FilledButton(
            style: _compactFilledStyle(),
            onPressed: canOpen ? _tryOpenAttemptIfReady : null,
            child: Text(l10n.examSessionGo),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final st = _status ?? 'lobby';
    final ctx = _sessionContext;
    final examTitle = (ctx?['examTitle'] as String?)?.trim();
    final className = (ctx?['classroomName'] as String?)?.trim();
    final teacherName = (ctx?['teacherName'] as String?)?.trim();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: StudentMobileUi.appBar(context, title: l10n.examModeRealtime),
      body: _loading
          ? const Center(child: AppLoadingIndicator.center(color: AppColors.primary))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    padding: StudentMobileUi.pagePadding,
                    children: [
                      if (_error != null) ...[
                        StudentMobileUi.errorBanner(
                          message: _error!,
                          onRetry: _bootstrap,
                          retryLabel: l10n.retry,
                        ),
                        const SizedBox(height: StudentMobileUi.cardGap),
                      ],
                      AppCard(
                        variant: AppCardVariant.outline,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ExamSessionStatusBanner(status: st),
                            if (examTitle != null && examTitle.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(examTitle, style: StudentMobileUi.sectionTitle(context)),
                            ],
                            if (className != null && className.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(l10n.teacherDashboardClassLabel(className), style: StudentMobileUi.body(context)),
                            ],
                            if (teacherName != null && teacherName.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(l10n.studentClassTeacher(teacherName), style: StudentMobileUi.caption(context)),
                            ],
                            const SizedBox(height: 10),
                            Text(
                              '${l10n.examSessionRoomCode}: ${_roomCode ?? '—'}',
                              style: StudentMobileUi.cardTitle(context),
                            ),
                            const SizedBox(height: AppSpacing.s4),
                            Text(l10n.examSessionLobbyParticipantsTitle, style: StudentMobileUi.sectionTitle(context)),
                            const SizedBox(height: 8),
                            Text(
                              l10n.teacherExamSessionJoinedCount(_joinedCount),
                              style: StudentMobileUi.body(context).copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (st == 'lobby' && _joinedCount > 0)
                              Text(
                                l10n.examSessionReadyCount(_readyCount, _joinedCount),
                                style: StudentMobileUi.caption(context),
                              ),
                            if (_participants.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              ..._participants.map((p) {
                                final name = _lobbyName(p);
                                final sub = _lobbySubtitle(p);
                                final ready = p['ready'] == true;
                                final letter = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                        child: Text(
                                          letter,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name.isEmpty ? l10n.teacherDashboardStudentUnknown : name,
                                              style: StudentMobileUi.cardTitle(context),
                                            ),
                                            if (sub.isNotEmpty)
                                              Text(
                                                sub,
                                                style: StudentMobileUi.caption(context),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (st == 'lobby')
                                        Text(
                                          ready ? l10n.examSessionStudentReady : l10n.examSessionStudentNotReady,
                                          style: StudentMobileUi.caption(context).copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: ready ? AppColors.primary : AppColors.textMuted,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            const SizedBox(height: StudentMobileUi.cardGap),
                            Text(
                              st == 'live'
                                  ? l10n.examSessionGo
                                  : st == 'closed' || st == 'grading'
                                      ? l10n.examSessionStatusClosed
                                      : l10n.examWaitingForTeacher,
                              style: StudentMobileUi.body(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildBottomActions(context, st, l10n),
              ],
            ),
    );
  }
}
