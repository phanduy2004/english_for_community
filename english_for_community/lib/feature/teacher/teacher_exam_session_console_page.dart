import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/feature/student/exams/exam_assignment_card.dart';
import 'package:english_for_community/feature/teacher/bloc/exam_session_console/teacher_exam_session_console_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/exam_session_console/teacher_exam_session_console_event.dart';
import 'package:english_for_community/feature/teacher/bloc/exam_session_console/teacher_exam_session_console_state.dart';
import 'package:english_for_community/feature/teacher/bloc/live_monitor/teacher_live_monitor_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/live_monitor/teacher_live_monitor_event.dart';
import 'package:english_for_community/feature/teacher/bloc/live_monitor/teacher_live_monitor_state.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_mobile_ui.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_page_scaffold.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_session_compact_strip.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_session_timing.dart';
import 'package:english_for_community/feature/teacher/widgets/teacher_exam_participant_status_chip.dart';
import 'package:english_for_community/feature/teacher/widgets/teacher_live_monitor_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherExamSessionConsolePage extends StatelessWidget {
  const TeacherExamSessionConsolePage({super.key, required this.assignmentId});

  final String assignmentId;

  static const String routePath = '/teacher/exam-console';
  static const String routeName = 'TeacherExamSessionConsolePage';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TeacherExamSessionConsoleBloc>(param1: assignmentId)
        ..add(TeacherExamSessionConsoleStarted(assignmentId)),
      child: _TeacherExamSessionConsoleDisposeScope(
        child: _TeacherExamSessionConsoleView(assignmentId: assignmentId),
      ),
    );
  }
}

class _TeacherExamSessionConsoleDisposeScope extends StatefulWidget {
  const _TeacherExamSessionConsoleDisposeScope({required this.child});

  final Widget child;

  @override
  State<_TeacherExamSessionConsoleDisposeScope> createState() =>
      _TeacherExamSessionConsoleDisposeScopeState();
}

class _TeacherExamSessionConsoleDisposeScopeState extends State<_TeacherExamSessionConsoleDisposeScope> {
  @override
  void dispose() {
    context.read<TeacherExamSessionConsoleBloc>().add(const TeacherExamSessionConsoleStopped());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
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

Future<void> _confirmKick(BuildContext context, Map<String, dynamic> participant) async {
  final l10n = context.l10n;
  final userId = participant['userId']?.toString() ?? '';
  if (userId.isEmpty) return;
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
  if (confirmed != true || !context.mounted) return;
  context.read<TeacherExamSessionConsoleBloc>().add(TeacherExamSessionConsoleKickRequested(userId));
  AppCornerToast.show(context, l10n.examSessionKickStudentDone);
}

class _TeacherExamSessionConsoleView extends StatelessWidget {
  const _TeacherExamSessionConsoleView({required this.assignmentId});

  final String assignmentId;

  TeacherExamSessionTimingLabels? _sessionTiming(
    BuildContext context,
    TeacherExamSessionConsoleState state,
  ) {
    return TeacherExamSessionTimingLabels.fromMaps(
      context,
      sessionStatus: state.sessionStatus,
      session: state.session,
      assignmentContext: state.assignmentContext,
    );
  }

  Widget _sessionCompactStrip(
    BuildContext context,
    TeacherExamSessionConsoleState state,
    String roomCode,
    String createdLabel,
  ) {
    return TeacherExamSessionCompactStrip(
      contextData: state.assignmentContext ?? {},
      sessionStatus: state.sessionStatus,
      roomCode: roomCode,
      sessionCreatedAt: createdLabel,
      timing: _sessionTiming(context, state),
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

  List<Widget> _rosterSection(BuildContext context, TeacherExamSessionConsoleState state) {
    if (state.isLive) {
      return [
        BlocBuilder<TeacherLiveMonitorBloc, TeacherLiveMonitorState>(
          buildWhen: teacherLiveMonitorSummaryBuildWhen,
          builder: (context, monitorState) => _rosterCard(
            context,
            state,
            monitorByUserId: monitorState.studentsByUserId,
            summary: monitorState.summary,
          ),
        ),
      ];
    }
    return [_rosterCard(context, state)];
  }

  Widget _rosterCard(
    BuildContext context,
    TeacherExamSessionConsoleState state, {
    Map<String, Map<String, dynamic>> monitorByUserId = const {},
    Map<String, dynamic> summary = const {},
  }) {
    final l10n = context.l10n;
    final rosterTitle = state.isLive
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
            if (state.isLive && summary.isNotEmpty) ...[
              Text(
                _liveSummaryLine(context, summary),
                style: ExamSystemUi.captionMuted.copyWith(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              l10n.teacherExamSessionJoinedCount(state.joinedCount),
              style: ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w600),
            ),
            if (state.isLobby && state.joinedCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                l10n.examSessionReadyCount(state.readyCount, state.joinedCount),
                style: ExamSystemUi.captionSecondary.copyWith(color: AppColors.primary),
              ),
            ],
            const SizedBox(height: 12),
            if (state.participants.isEmpty)
              Text(l10n.teacherExamSessionNoParticipantsYet, style: ExamSystemUi.captionSecondary)
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < state.participants.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    Builder(
                      builder: (context) {
                        final p = state.participants[i];
                        final uid = p['userId']?.toString() ?? '';
                        return RepaintBoundary(
                          child: _participantTile(
                            context,
                            state,
                            p,
                            monitorRow: uid.isEmpty ? null : monitorByUserId[uid],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _participantTile(
    BuildContext context,
    TeacherExamSessionConsoleState state,
    Map<String, dynamic> p, {
    Map<String, dynamic>? monitorRow,
  }) {
    final l10n = context.l10n;
    final name = _participantDisplayName(p);
    final sub = _participantSubtitle(p);
    final letter = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    final phase = state.isLobby
        ? TeacherExamSessionPhase.lobby
        : (state.isLive ? TeacherExamSessionPhase.live : TeacherExamSessionPhase.ended);
    final chipStatus = TeacherExamParticipantStatusResolver.resolve(
      phase: phase,
      participant: p,
      monitorRow: monitorRow,
    );
    final attemptStatus = monitorRow?['status']?.toString() ?? '';
    final showKick = state.isLobby || (state.isLive && attemptStatus == 'in_progress');
    final inProgressLive = state.isLive && chipStatus == TeacherExamParticipantStatus.inProgress;
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
              onPressed: state.busy ? null : () => _confirmKick(context, p),
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

  List<Widget> _sessionHeaderActions(BuildContext context, TeacherExamSessionConsoleState state) {
    final l10n = context.l10n;
    final sid = state.sessionId ?? '';
    if (sid.isEmpty) {
      return [
        TeacherOutlinedButton(
          label: l10n.teacherExamCreateSession,
          onPressed: state.busy
              ? null
              : () => context.read<TeacherExamSessionConsoleBloc>().add(const TeacherExamSessionConsoleCreateRequested()),
        ),
      ];
    }
    final startBtn = state.isLobby
        ? TeacherFilledButton(
            label: l10n.teacherExamStartSession,
            onPressed: state.busy
                ? null
                : () => context
                    .read<TeacherExamSessionConsoleBloc>()
                    .add(const TeacherExamSessionConsoleStartRequested()),
          )
        : null;
    final endBtn = (state.isLive || state.isLobby)
        ? TeacherDangerOutlinedButton(
            label: l10n.teacherExamEndSession,
            onPressed: state.busy
                ? null
                : () => context
                    .read<TeacherExamSessionConsoleBloc>()
                    .add(const TeacherExamSessionConsoleEndRequested()),
          )
        : null;

    if (startBtn == null && endBtn == null) return const [];

    if (TeacherMobileUi.isMobileWorkspace(context)) {
      return [if (startBtn != null) startBtn, if (endBtn != null) endBtn];
    }

    return [
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (startBtn != null) ...[startBtn, const SizedBox(width: 8)],
          if (endBtn != null) endBtn,
        ],
      ),
    ];
  }

  Widget _buildControlTab(
    BuildContext context,
    TeacherExamSessionConsoleState state,
    String sharePath, {
    required String roomCode,
    required String createdLabel,
  }) {
    final l10n = context.l10n;
    return ListView(
      padding: TeacherWebUi.pageScrollPadding(context),
      children: [
        _sessionCompactStrip(context, state, roomCode, createdLabel),
        const SizedBox(height: ExamSystemUi.cardGap),
        if (state.isLive) ...[
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
        if (sharePath.isNotEmpty && state.isLobby) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: sharePath));
                if (context.mounted) {
                  AppCornerToast.show(context, l10n.copiedToClipboard);
                }
              },
              icon: const Icon(Icons.link, size: 18),
              label: Text(l10n.copyInviteCode),
            ),
          ),
          const SizedBox(height: 10),
        ],
        ..._rosterSection(context, state),
      ],
    );
  }

  Widget _buildLiveTabbedBody(
    BuildContext context,
    TeacherExamSessionConsoleState state,
    String sid,
    String roomCode,
    String createdLabel,
  ) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (_) => getIt<TeacherLiveMonitorBloc>(param1: sid)
        ..add(TeacherLiveMonitorStarted(initialSnapshot: state.liveMonitor)),
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
                    state,
                    sid.isEmpty ? '' : '/student/exam-session/$sid',
                    roomCode: roomCode,
                    createdLabel: createdLabel,
                  ),
                  TeacherLiveMonitorPanel(
                    onKickStudent: (student) => _confirmKick(context, {
                      'userId': student['userId'],
                      'fullName': student['fullName'],
                      'email': student['email'],
                      'username': student['username'],
                    }),
                  ),
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

    return BlocConsumer<TeacherExamSessionConsoleBloc, TeacherExamSessionConsoleState>(
      listenWhen: (prev, curr) =>
          curr.errorMessage != null && prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        final msg = state.errorMessage;
        if (msg != null) {
          AppCornerToast.show(context, msg, error: true);
        }
      },
      builder: (context, state) {
        final sid = state.sessionId ?? '';
        final roomCode = (state.session?['roomCode'] as String?) ?? '';
        final createdIso = state.session?['createdAt']?.toString();
        final createdLabel = ExamAssignmentCard.formatIso(context, createdIso) ?? '';

        final loading = state.status == TeacherExamSessionConsoleStatus.loading;
        final error = state.status == TeacherExamSessionConsoleStatus.error ? state.errorMessage : null;
        final mobile = TeacherMobileUi.isMobileWorkspace(context);
        final sessionActions = loading || error != null ? const <Widget>[] : _sessionHeaderActions(context, state);

        return TeacherPageScaffold(
          title: l10n.teacherExamConsoleTitle,
          maxWidth: TeacherWebUi.contentMaxTable,
          scrollable: false,
          showBack: true,
          actions: mobile ? const [] : sessionActions,
          bottomActions: mobile ? sessionActions : null,
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? Center(
                      child: Padding(
                        padding: TeacherWebUi.pageScrollPadding(context),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(error, textAlign: TextAlign.center, style: ExamSystemUi.captionSecondary),
                            const SizedBox(height: 16),
                            TeacherRetryButton(
                              onPressed: () => context
                                  .read<TeacherExamSessionConsoleBloc>()
                                  .add(TeacherExamSessionConsoleStarted(assignmentId)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : state.isLive && sid.isNotEmpty
                      ? _buildLiveTabbedBody(context, state, sid, roomCode, createdLabel)
                      : ListView(
                          padding: TeacherWebUi.pageScrollPadding(context),
                          children: [
                            _sessionCompactStrip(context, state, roomCode, createdLabel),
                            const SizedBox(height: ExamSystemUi.cardGap),
                            if (sid.isNotEmpty && state.isLobby) ...[
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () async {
                                    await Clipboard.setData(ClipboardData(text: '/student/exam-session/$sid'));
                                    if (context.mounted) {
                                      AppCornerToast.show(context, l10n.copiedToClipboard);
                                    }
                                  },
                                  icon: const Icon(Icons.link, size: 18),
                                  label: Text(l10n.copyInviteCode),
                                ),
                              ),
                            ],
                            const SizedBox(height: ExamSystemUi.sectionGap),
                            ..._rosterSection(context, state),
                          ],
                        ),
        );
      },
    );
  }
}
