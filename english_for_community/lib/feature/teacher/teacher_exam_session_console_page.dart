import 'package:english_for_community/core/api/token_storage.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/socket/socket_service.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/feature/student/exams/exam_assignment_card.dart';
import 'package:english_for_community/feature/teacher/bloc/live_monitor/teacher_live_monitor_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/live_monitor/teacher_live_monitor_event.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_mobile_ui.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_page_scaffold.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_session_compact_strip.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_session_timing.dart';
import 'package:english_for_community/feature/teacher/bloc/live_monitor/teacher_live_monitor_state.dart';
import 'package:english_for_community/feature/teacher/widgets/teacher_exam_participant_status_chip.dart';
import 'package:english_for_community/feature/teacher/widgets/teacher_live_monitor_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherExamSessionConsolePage extends StatefulWidget {
  const TeacherExamSessionConsolePage({super.key, required this.assignmentId});

  final String assignmentId;

  static const String routePath = '/teacher/exam-console';
  static const String routeName = 'TeacherExamSessionConsolePage';

  @override
  State<TeacherExamSessionConsolePage> createState() => _TeacherExamSessionConsolePageState();
}

String _participantDisplayName(Map<String, dynamic> p) {
  final n = (p['fullName'] as String?)?.trim();
  if (n != null && n.isNotEmpty) return n;
  final u = (p['username'] as String?)?.trim();
  if (u != null && u.isNotEmpty) return u;
  final e = (p['email'] as String?)?.trim();
  if (e != null && e.isNotEmpty) return e;
  return '';
}

String _participantSubtitle(Map<String, dynamic> p) {
  final e = (p['email'] as String?)?.trim();
  if (e != null && e.isNotEmpty) return e;
  return (p['userId'] as String?)?.trim() ?? '';
}

class _TeacherExamSessionConsolePageState extends State<TeacherExamSessionConsolePage> {
  Map<String, dynamic>? _assignmentContext;
  Map<String, dynamic>? _session;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _boundSessionId;
  List<Map<String, dynamic>> _participants = [];
  int _joinedCount = 0;
  int _readyCount = 0;
  Map<String, dynamic>? _liveMonitor;

  String? get _sessionId => _session?['id'] as String? ?? _session?['_id']?.toString();
  String get _status => (_session?['status'] as String?) ?? 'lobby';

  @override
  void initState() {
    super.initState();
    _loadConsole();
  }

  @override
  void dispose() {
    if (_boundSessionId != null) {
      getIt<SocketService>().offExamSessionState();
      getIt<SocketService>().clearExamRealtimeContext();
    }
    super.dispose();
  }

  Future<void> _loadConsole() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await getIt<TeacherExamRepository>().getSessionConsole(widget.assignmentId);
    if (!mounted) return;
    r.fold(
      (f) => setState(() {
        _error = f.message;
        _loading = false;
      }),
      (data) async {
        final m = Map<String, dynamic>.from(data as Map);
        final ctx = m['assignment'];
        if (ctx is Map) _assignmentContext = Map<String, dynamic>.from(ctx);
        final sessionDoc = m['session'];
        if (sessionDoc is Map) _session = Map<String, dynamic>.from(sessionDoc);
        final live = m['liveState'];
        if (live is Map) _ingestLobbyPayload(Map<String, dynamic>.from(live));
        final lm = m['liveMonitor'];
        if (lm is Map) {
          _liveMonitor = Map<String, dynamic>.from(lm);
        } else if (_status != 'live' && _status != 'grading') {
          _liveMonitor = null;
        }
        final sid = _sessionId ?? '';
        if (sid.isNotEmpty && _status == 'live' && _liveMonitor == null) {
          final lmR = await getIt<TeacherExamRepository>().getSessionLiveMonitor(sid);
          lmR.fold((_) {}, (data) {
            if (data is Map) _liveMonitor = Map<String, dynamic>.from(data);
          });
        }
        setState(() => _loading = false);
        if (sid.isNotEmpty && (_status == 'lobby' || _status == 'live')) {
          await _bindLiveSocket(sid);
        }
      },
    );
  }

  Future<void> _bindLiveSocket(String sessionId) async {
    if (sessionId.isEmpty) return;
    if (_boundSessionId == sessionId) return;
    if (_boundSessionId != null) {
      getIt<SocketService>().offExamSessionState();
      getIt<SocketService>().clearExamRealtimeContext();
    }
    _boundSessionId = sessionId;
    await _refreshLobbySnapshot(sessionId);
    final token = await TokenStorage.readAccessToken() ?? '';
    if (!mounted || token.isEmpty) return;
    getIt<SocketService>().setExamRealtimeContext(accessToken: token, sessionId: sessionId);
    getIt<SocketService>().listenExamSessionState(_onSocketLobby);
  }

  void _onSocketLobby(Map<String, dynamic> payload) {
    if (payload['sessionId']?.toString() != _boundSessionId) return;
    if (!mounted) return;
    setState(() => _ingestLobbyPayload(payload));
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
    final rc = p['readyCount'];
    if (rc is num) {
      _readyCount = rc.toInt();
    } else {
      _readyCount = _participants.where((x) => x['ready'] == true).length;
    }
    final st = p['status']?.toString();
    if (st != null) {
      _session = Map<String, dynamic>.from(_session ?? {});
      _session!['status'] = st;
    }
    final room = p['roomCode'];
    if (room is String && room.isNotEmpty) {
      _session = Map<String, dynamic>.from(_session ?? {});
      _session!['roomCode'] = room;
    }
    final ctx = p['context'];
    if (ctx is Map) {
      _assignmentContext = Map<String, dynamic>.from(ctx);
    }
    final created = p['createdAt'];
    if (created != null && _session != null) {
      _session = Map<String, dynamic>.from(_session!);
      _session!['createdAt'] = created;
    }
    _mergeSessionTimingFromPayload(p);
  }

  void _mergeSessionTimingFromPayload(Map<String, dynamic> p) {
    _session = Map<String, dynamic>.from(_session ?? {});
    for (final key in ['startedAt', 'endedAt', 'scheduledEndAt', 'hardEndAt', 'timeLimitSeconds']) {
      final v = p[key];
      if (v != null) _session![key] = v;
    }
  }

  Future<void> _refreshLobbySnapshot(String sessionId) async {
    final r = await getIt<TeacherExamRepository>().getExamSessionLobby(sessionId);
    if (!mounted) return;
    r.fold((_) {}, (data) {
      if (data is Map) setState(() => _ingestLobbyPayload(Map<String, dynamic>.from(data)));
    });
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    final r = await getIt<TeacherExamRepository>().createExamSession(widget.assignmentId);
    if (!mounted) return;
    setState(() => _busy = false);
    await r.fold(
      (f) async {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message)));
      },
      (d) async {
        final m = Map<String, dynamic>.from(d as Map);
        setState(() => _session = m);
        final id = _sessionId ?? '';
        if (id.isNotEmpty) await _bindLiveSocket(id);
        if (mounted) await _loadConsole();
      },
    );
  }

  Future<void> _start() async {
    final id = _sessionId ?? '';
    if (id.isEmpty) return;
    setState(() => _busy = true);
    final r = await getIt<TeacherExamRepository>().startExamSession(id);
    if (!mounted) return;
    setState(() => _busy = false);
    await r.fold(
      (f) async {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message)));
      },
      (d) async {
        setState(() => _session = Map<String, dynamic>.from(d as Map));
        await _loadConsole();
      },
    );
  }

  Future<void> _kickStudentFromMonitor(Map<String, dynamic> student) async {
    await _kickStudent({
      'userId': student['userId'],
      'fullName': student['fullName'],
      'email': student['email'],
      'username': student['username'],
    });
  }

  Future<void> _kickStudent(Map<String, dynamic> participant) async {
    final sid = _sessionId ?? '';
    final userId = participant['userId']?.toString() ?? '';
    if (sid.isEmpty || userId.isEmpty) return;
    final l10n = context.l10n;
    final name = _participantDisplayName(participant);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.examSessionKickStudentTitle),
        content: Text(l10n.examSessionKickStudentConfirm(name.isEmpty ? l10n.teacherDashboardStudentUnknown : name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.chartTrend),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.examSessionKickStudentAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final r = await getIt<TeacherExamRepository>().kickExamSessionParticipant(sid, userId);
    if (!mounted) return;
    setState(() => _busy = false);
    r.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
      (data) {
        if (data is Map) setState(() => _ingestLobbyPayload(Map<String, dynamic>.from(data)));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.examSessionKickStudentDone)));
      },
    );
  }

  Future<void> _end() async {
    final id = _sessionId ?? '';
    if (id.isEmpty) return;
    setState(() => _busy = true);
    final r = await getIt<TeacherExamRepository>().endExamSession(id);
    if (!mounted) return;
    setState(() => _busy = false);
    await r.fold(
      (f) async {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message)));
      },
      (d) async {
        setState(() => _session = Map<String, dynamic>.from(d as Map));
        await _refreshLobbySnapshot(id);
      },
    );
  }

  bool get _isLobby => _status == 'lobby';
  bool get _isLive => _status == 'live';

  TeacherExamSessionTimingLabels? _sessionTiming(BuildContext context) {
    return TeacherExamSessionTimingLabels.fromMaps(
      context,
      sessionStatus: _status,
      session: _session,
      assignmentContext: _assignmentContext,
    );
  }

  Widget _sessionCompactStrip(BuildContext context, String roomCode, String createdLabel) {
    return TeacherExamSessionCompactStrip(
      contextData: _assignmentContext ?? {},
      sessionStatus: _status,
      roomCode: roomCode,
      sessionCreatedAt: createdLabel,
      timing: _sessionTiming(context),
    );
  }

  String _liveSummaryLine(BuildContext context, Map<String, dynamic> summary) {
    final l10n = context.l10n;
    final inProgress = (summary['inProgress'] as num?)?.toInt() ?? 0;
    final submitted = (summary['submitted'] as num?)?.toInt() ?? 0;
    final flagged = (summary['flagged'] as num?)?.toInt() ?? 0;
    final avg = (summary['avgProgressPercent'] as num?)?.toDouble() ?? 0;
    final avgLabel = avg == avg.roundToDouble() ? '${avg.toInt()}' : avg.toStringAsFixed(1);
    return l10n.teacherLiveMonitorSummaryLine(inProgress, submitted, flagged, avgLabel);
  }

  List<Widget> _rosterSection(BuildContext context) {
    if (_isLive) {
      return [
        BlocBuilder<TeacherLiveMonitorBloc, TeacherLiveMonitorState>(
          builder: (context, monitorState) => _rosterCard(
            context,
            monitorByUserId: TeacherExamParticipantStatusResolver.indexByUserId(monitorState.students),
            summary: monitorState.summary,
          ),
        ),
      ];
    }
    return [_rosterCard(context)];
  }

  Widget _rosterCard(
    BuildContext context, {
    Map<String, Map<String, dynamic>> monitorByUserId = const {},
    Map<String, dynamic> summary = const {},
  }) {
    final l10n = context.l10n;
    final rosterTitle = _isLive
        ? l10n.teacherExamSessionLiveRosterTitleLive
        : l10n.teacherExamSessionLiveRosterTitle;

    return DecoratedBox(
      decoration: ExamSystemUi.softCard(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rosterTitle, style: ExamSystemUi.listTitle(context)),
            const SizedBox(height: 12),
            if (_isLive && summary.isNotEmpty) ...[
              Text(
                _liveSummaryLine(context, summary),
                style: ExamSystemUi.captionMuted.copyWith(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              l10n.teacherExamSessionJoinedCount(_joinedCount),
              style: ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w600),
            ),
            if (_isLobby && _joinedCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                l10n.examSessionReadyCount(_readyCount, _joinedCount),
                style: ExamSystemUi.captionSecondary.copyWith(color: AppColors.primary),
              ),
            ],
            const SizedBox(height: 12),
            if (_participants.isEmpty)
              Text(l10n.teacherExamSessionNoParticipantsYet, style: ExamSystemUi.captionSecondary)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _participants.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final p = _participants[i];
                  final uid = p['userId']?.toString() ?? '';
                  return _participantTile(
                    context,
                    p,
                    monitorRow: uid.isEmpty ? null : monitorByUserId[uid],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _participantTile(
    BuildContext context,
    Map<String, dynamic> p, {
    Map<String, dynamic>? monitorRow,
  }) {
    final l10n = context.l10n;
    final name = _participantDisplayName(p);
    final sub = _participantSubtitle(p);
    final letter = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    final phase = _isLobby
        ? TeacherExamSessionPhase.lobby
        : (_isLive ? TeacherExamSessionPhase.live : TeacherExamSessionPhase.ended);
    final chipStatus = TeacherExamParticipantStatusResolver.resolve(
      phase: phase,
      participant: p,
      monitorRow: monitorRow,
    );
    final attemptStatus = monitorRow?['status']?.toString() ?? '';
    final showKick = _isLobby || (_isLive && attemptStatus == 'in_progress');
    final inProgressLive = _isLive && chipStatus == TeacherExamParticipantStatus.inProgress;
    final pct = ((monitorRow?['progressPercent'] as num?)?.toDouble() ?? 0) / 100;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              letter,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? l10n.teacherDashboardStudentUnknown : name,
                  style: ExamSystemUi.captionSecondary.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (inProgressLive) ...[
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0, 1),
                      minHeight: 4,
                      backgroundColor: AppColors.outlineMuted.withValues(alpha: 0.25),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.teacherLiveMonitorProgressLabel(
                      (monitorRow?['answeredCount'] as num?)?.toInt() ?? 0,
                      (monitorRow?['totalItems'] as num?)?.toInt() ?? 0,
                      (monitorRow?['progressPercent'] as num?)?.toDouble() ?? 0,
                    ),
                    style: ExamSystemUi.captionMuted.copyWith(fontSize: 11),
                  ),
                ] else if (sub.isNotEmpty)
                  Text(sub, style: ExamSystemUi.captionMuted, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          TeacherExamParticipantStatusChip(status: chipStatus),
          if (showKick) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: l10n.examSessionKickStudentAction,
              onPressed: _busy ? null : () => _kickStudent(p),
              icon: Icon(Icons.person_remove_outlined, size: 20, color: AppColors.chartTrend),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ],
      ),
    );
  }

  /// Primary session controls — top-right header (dashboard "New exam" pattern).
  List<Widget> _sessionHeaderActions(BuildContext context) {
    final l10n = context.l10n;
    final sid = _sessionId ?? '';
    if (sid.isEmpty) {
      return [
        TeacherOutlinedButton(
          label: l10n.teacherExamCreateSession,
          onPressed: _busy ? null : _create,
        ),
      ];
    }
    return [
      if (_isLobby)
        TeacherFilledButton(
          label: l10n.teacherExamStartSession,
          onPressed: _busy ? null : _start,
        ),
      if (_isLive || _isLobby)
        TeacherDangerOutlinedButton(
          label: l10n.teacherExamEndSession,
          onPressed: _busy ? null : _end,
        ),
    ];
  }

  Widget _buildControlTab(
    BuildContext context,
    String sharePath, {
    required String roomCode,
    required String createdLabel,
  }) {
    final l10n = context.l10n;
    return ListView(
      padding: TeacherWebUi.pageScrollPadding(context),
      children: [
        _sessionCompactStrip(context, roomCode, createdLabel),
        const SizedBox(height: ExamSystemUi.cardGap),
        if (_isLive) ...[
          DecoratedBox(
            decoration: ExamSystemUi.softCard(),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                l10n.teacherExamSessionLeavePageHint,
                style: ExamSystemUi.captionSecondary,
              ),
            ),
          ),
          const SizedBox(height: ExamSystemUi.cardGap),
        ],
        if (sharePath.isNotEmpty && _isLobby) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: sharePath));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.copiedToClipboard)));
                }
              },
              icon: const Icon(Icons.link, size: 18),
              label: Text(l10n.copyInviteCode),
            ),
          ),
          const SizedBox(height: 10),
        ],
        ..._rosterSection(context),
      ],
    );
  }

  Widget _buildLiveTabbedBody(BuildContext context, String sid, String roomCode, String createdLabel) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (_) => getIt<TeacherLiveMonitorBloc>(param1: sid)
        ..add(TeacherLiveMonitorStarted(initialSnapshot: _liveMonitor)),
      child: DefaultTabController(
        length: 2,
        initialIndex: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: AppColors.surfaceCard,
              child: TabBar(
                labelColor: AppColors.primaryDark,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: l10n.teacherExamSessionTabControl),
                  Tab(text: l10n.teacherExamSessionTabLiveMonitor),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildControlTab(
                    context,
                    sid.isEmpty ? '' : '/student/exam-session/$sid',
                    roomCode: roomCode,
                    createdLabel: createdLabel,
                  ),
                  TeacherLiveMonitorPanel(onKickStudent: _kickStudentFromMonitor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sid = _sessionId ?? '';
    final sharePath = sid.isEmpty ? '' : '/student/exam-session/$sid';
    final roomCode = (_session?['roomCode'] as String?) ?? '';
    final createdIso = _session?['createdAt']?.toString();
    final createdLabel = ExamAssignmentCard.formatIso(context, createdIso) ?? '';

    final mobile = TeacherMobileUi.isMobileWorkspace(context);
    final sessionActions = _loading || _error != null ? const <Widget>[] : _sessionHeaderActions(context);

    return TeacherPageScaffold(
      title: l10n.teacherExamConsoleTitle,
      maxWidth: TeacherWebUi.contentMaxTable,
      scrollable: false,
      showBack: true,
      actions: mobile ? const [] : sessionActions,
      bottomActions: mobile ? sessionActions : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: TeacherWebUi.pageScrollPadding(context),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center, style: ExamSystemUi.captionSecondary),
                        const SizedBox(height: 16),
                        TeacherRetryButton(onPressed: _loadConsole),
                      ],
                    ),
                  ),
                )
              : _isLive && sid.isNotEmpty
                  ? _buildLiveTabbedBody(context, sid, roomCode, createdLabel)
                  : ListView(
                      padding: TeacherWebUi.pageScrollPadding(context),
                      children: [
                        _sessionCompactStrip(context, roomCode, createdLabel),
                        const SizedBox(height: ExamSystemUi.cardGap),
                        if (sharePath.isNotEmpty && _isLobby) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: sharePath));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.copiedToClipboard)),
                                  );
                                }
                              },
                              icon: const Icon(Icons.link, size: 18),
                              label: Text(l10n.copyInviteCode),
                            ),
                          ),
                        ],
                        const SizedBox(height: ExamSystemUi.sectionGap),
                        ..._rosterSection(context),
                      ],
                    ),
    );
  }
}
