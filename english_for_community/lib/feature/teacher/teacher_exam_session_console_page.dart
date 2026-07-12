import 'package:english_for_community/feature/teacher/layout/teacher_skeleton.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/socket/socket_service.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
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
import 'package:english_for_community/feature/teacher/layout/teacher_dialog_shell.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/core/ui/widget/web_data_table.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_widgets.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_session_compact_strip.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_session_timing.dart';
import 'package:english_for_community/feature/teacher/teacher_student_live_screen_page.dart';
import 'package:english_for_community/feature/teacher/widgets/teacher_exam_participant_status_chip.dart';
import 'package:english_for_community/feature/teacher/widgets/teacher_exam_question_strip.dart';
import 'package:english_for_community/feature/teacher/widgets/teacher_exam_session_student_share_card.dart';
import 'package:flutter/material.dart';
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

  Widget _studentShareCard(
    TeacherExamSessionConsoleState state,
    String roomCode,
  ) {
    final ctx = state.assignmentContext ?? {};
    return TeacherExamSessionStudentShareCard(
      audience: ctx['audience'] as String?,
      publicJoinToken: ctx['publicJoinToken'] as String?,
      roomCode: roomCode,
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
              _rosterTable(context, state, monitorByUserId),
          ],
        ),
      ),
    );
  }

  // Roster rendered as a table (matches the other management screens). Live
  // per-student progress bars stay in the dedicated Live monitor tab.
  Widget _rosterTable(
    BuildContext context,
    TeacherExamSessionConsoleState state,
    Map<String, Map<String, dynamic>> monitorByUserId,
  ) {
    final l10n = context.l10n;
    final entries = [
      for (final p in state.participants)
        _rosterEntry(state, p, monitorByUserId),
    ];
    return WebDataTable(
      columns: [
        WebTableColumn(label: l10n.teacherGradebookStudent, flex: 4),
        WebTableColumn(label: l10n.teacherClassColStatus, width: 130),
        const WebTableColumn(label: '', width: 56, align: Alignment.center),
      ],
      rowCount: entries.length,
      decoration: const BoxDecoration(),
      headStyle: TeacherWebUi.webTableHead(context),
      cellBuilder: (context, row, col) {
        final e = entries[row];
        return switch (col) {
          0 => _studentCell(context, e),
          1 => TeacherExamParticipantStatusChip(status: e.chipStatus),
          2 => e.showKick
              ? _kickMenu(context, state, e.participant)
              : const SizedBox.shrink(),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  _RosterEntry _rosterEntry(
    TeacherExamSessionConsoleState state,
    Map<String, dynamic> p,
    Map<String, Map<String, dynamic>> monitorByUserId,
  ) {
    final uid = p['userId']?.toString() ?? '';
    final monitorRow = uid.isEmpty ? null : monitorByUserId[uid];
    final name = _participantDisplayName(p);
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
    return _RosterEntry(
      participant: p,
      name: name,
      sub: _participantSubtitle(p),
      avatarUrl: (p['avatarUrl'] as String?)?.trim(),
      chipStatus: chipStatus,
      showKick: showKick,
    );
  }

  Widget _studentCell(BuildContext context, _RosterEntry e) {
    final l10n = context.l10n;
    return Row(
      children: [
        TeacherWebUi.userAvatarCircle(
          avatarUrl: e.avatarUrl,
          displayName: e.name,
          radius: 14,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.name.isEmpty ? l10n.teacherDashboardStudentUnknown : e.name,
                style: TeacherWebUi.webBody(context)
                    .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (e.sub.isNotEmpty)
                Text(
                  e.sub,
                  style: TeacherWebUi.metaMuted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kickMenu(
    BuildContext context,
    TeacherExamSessionConsoleState state,
    Map<String, dynamic> p,
  ) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      tooltip: l10n.examSessionKickStudentAction,
      enabled: !state.busy,
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_horiz, size: 18, color: AppColors.textSecondary),
      onSelected: (_) => _confirmKick(context, p),
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'kick',
          child: Row(
            children: [
              const Icon(Icons.person_remove_outlined, size: 18, color: AppColors.danger),
              const SizedBox(width: 8),
              Text(
                l10n.examSessionKickStudentAction,
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Confirm hành động không thu hồi: kết thúc & nộp tất cả (`docs/ui-ux-system/18` §5.8).
  Future<bool> _confirmEndSession(BuildContext context, int affectedCount) async {
    final ok = await TeacherDialogShell.show<bool>(
      context,
      child: _EndSessionConfirmDialog(affectedCount: affectedCount),
    );
    return ok ?? false;
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
                : () async {
                    final count = context.read<TeacherExamSessionConsoleBloc>().state.participants.length;
                    final ok = await _confirmEndSession(context, count);
                    if (ok && context.mounted) {
                      context
                          .read<TeacherExamSessionConsoleBloc>()
                          .add(const TeacherExamSessionConsoleEndRequested());
                    }
                  },
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

  /// Live: single session-control screen (tabs merged) — compact strip + KPI +
  /// filters + a tappable roster; per-student detail opens on row tap, actions
  /// live in the ⋮ menu. Replaces the old Control / Live-monitor two-tab body.
  Widget _buildLiveControlBody(
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
      child: ListView(
        padding: TeacherWebUi.pageScrollPadding(context),
        children: [
          _sessionCompactStrip(context, state, roomCode, createdLabel),
          const SizedBox(height: ExamSystemUi.cardGap),
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
          _liveSummaryCard(context),
          const SizedBox(height: ExamSystemUi.cardGap),
          BlocBuilder<TeacherLiveMonitorBloc, TeacherLiveMonitorState>(
            buildWhen: teacherLiveMonitorListBuildWhen,
            builder: (context, ms) {
              if (ms.visibleStudents.isEmpty) {
                return DecoratedBox(
                  decoration: ExamSystemUi.softCard(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text(l10n.teacherLiveMonitorNoStudents, style: ExamSystemUi.captionSecondary),
                    ),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final s in ms.visibleStudents)
                    Padding(
                      padding: const EdgeInsets.only(bottom: ExamSystemUi.cardGap),
                      child: _liveStudentCard(context, s),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _liveSummaryCard(BuildContext context) {
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: ExamSystemUi.softCard(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.teacherExamSessionLiveRosterTitleLive, style: ExamSystemUi.listTitle(context)),
            const SizedBox(height: 12),
            BlocBuilder<TeacherLiveMonitorBloc, TeacherLiveMonitorState>(
              buildWhen: teacherLiveMonitorSummaryBuildWhen,
              builder: (context, ms) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _liveKpiRow(context, ms.summary),
                  const SizedBox(height: 12),
                  _liveFilterChips(context, ms.filter),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liveKpiRow(BuildContext context, Map<String, dynamic> summary) {
    final l10n = context.l10n;
    final inProgress = (summary['inProgress'] as num?)?.toInt() ?? 0;
    final submitted = (summary['submitted'] as num?)?.toInt() ?? 0;
    final flagged = (summary['flagged'] as num?)?.toInt() ?? 0;
    final avg = (summary['avgProgressPercent'] as num?)?.toDouble() ?? 0;
    final avgLabel = avg == avg.roundToDouble() ? '${avg.toInt()}' : avg.toStringAsFixed(1);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        TeacherLiveMonitorMetricChip(value: '$inProgress', label: l10n.teacherLiveMonitorFilterInProgress, accent: AppColors.info),
        TeacherLiveMonitorMetricChip(value: '$submitted', label: l10n.teacherLiveMonitorFilterSubmitted, accent: AppColors.primary),
        TeacherLiveMonitorMetricChip(value: '$flagged', label: l10n.teacherLiveMonitorFilterFlagged, accent: AppColors.warning),
        TeacherLiveMonitorMetricChip(value: '$avgLabel%', label: l10n.teacherLiveMonitorDetailProgress, accent: AppColors.accentDark),
      ],
    );
  }

  Widget _liveFilterChips(BuildContext context, TeacherLiveMonitorFilter selected) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: TeacherLiveMonitorFilter.values.map((f) {
        final label = switch (f) {
          TeacherLiveMonitorFilter.all => l10n.teacherLiveMonitorFilterAll,
          TeacherLiveMonitorFilter.inProgress => l10n.teacherLiveMonitorFilterInProgress,
          TeacherLiveMonitorFilter.submitted => l10n.teacherLiveMonitorFilterSubmitted,
          TeacherLiveMonitorFilter.flagged => l10n.teacherLiveMonitorFilterFlagged,
        };
        return TeacherFilterChip(
          label: label,
          selected: selected == f,
          onSelected: () => context.read<TeacherLiveMonitorBloc>().add(TeacherLiveMonitorFilterChanged(f)),
        );
      }).toList(),
    );
  }

  /// Per-student live card — header (name + status + risk + ⋮), progress,
  /// proctoring, and the colour-graded question map (green = correct, red =
  /// wrong, gray = unanswered). Tapping the card opens the mirror screen.
  Widget _liveStudentCard(BuildContext context, Map<String, dynamic> s) {
    final l10n = context.l10n;
    final name = _participantDisplayName(s);
    final sub = _participantSubtitle(s);
    final avatarUrl = (s['avatarUrl'] as String?)?.trim();
    final status = s['status']?.toString() ?? '';
    final chipStatus = TeacherExamParticipantStatusResolver.fromAttemptStatus(status);
    final inProgress = chipStatus == TeacherExamParticipantStatus.inProgress;
    final risk = s['integrityRiskLevel']?.toString();
    final attemptId = s['attemptId']?.toString() ?? '';
    final proctor = _proctoringLine(context, s);
    final strips = TeacherExamQuestionStripSection.parseStrips(s['skillStrips']);
    final pct = ((s['progressPercent'] as num?)?.toDouble() ?? 0) / 100;

    // Tappable summary header — NO horizontal scrollables inside, so the tap that
    // opens the mirror screen is reliable. The question map (whose horizontal
    // strips otherwise swallow taps) is rendered BELOW as display-only.
    final header = Padding(
      padding: EdgeInsets.fromLTRB(12, 10, 6, strips.isNotEmpty ? 6 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TeacherWebUi.userAvatarCircle(avatarUrl: avatarUrl, displayName: name, radius: 14),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? l10n.teacherDashboardStudentUnknown : name,
                      style: TeacherWebUi.webBody(context).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sub.isNotEmpty)
                      Text(sub, style: TeacherWebUi.metaMuted, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TeacherExamParticipantStatusChip(status: chipStatus),
              if (risk == 'high' || risk == 'medium') ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: risk == 'high'
                      ? l10n.teacherLiveMonitorIntegrityHigh
                      : l10n.teacherLiveMonitorIntegrityMedium,
                  child: Icon(Icons.flag_outlined, size: 15, color: _riskColor(risk)),
                ),
              ],
              if (attemptId.isNotEmpty) ...[
                const SizedBox(width: 2),
                Tooltip(
                  message: l10n.teacherLiveMonitorWatchScreen,
                  child: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                ),
              ],
              _studentActionsMenu(context, s),
            ],
          ),
          if (inProgress) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: LinearProgressIndicator(
                value: pct.clamp(0, 1),
                minHeight: 4,
                backgroundColor: AppColors.outlineMuted.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.teacherLiveMonitorProgressLabel(
                (s['answeredCount'] as num?)?.toInt() ?? 0,
                (s['totalItems'] as num?)?.toInt() ?? 0,
                (s['progressPercent'] as num?)?.toDouble() ?? 0,
              ),
              style: ExamSystemUi.captionMuted.copyWith(fontSize: 11),
            ),
          ],
          if (proctor != null) ...[
            const SizedBox(height: 4),
            Text(
              proctor,
              style: ExamSystemUi.captionMuted.copyWith(fontSize: 11, color: AppColors.warning),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: attemptId.isEmpty ? null : () => _openStudentLiveScreen(context, s),
              hoverColor: AppColors.surfaceSubtle,
              child: header,
            ),
          ),
          if (strips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TeacherQuestionStatusLegend(
                    correctLabel: l10n.teacherLiveMonitorGrammarCorrect,
                    wrongLabel: l10n.teacherLiveMonitorGrammarWrong,
                    unansweredLabel: l10n.teacherLiveMonitorGrammarNotAnswered,
                  ),
                  const SizedBox(height: 8),
                  TeacherExamSkillStripsPanel(
                    skillStrips: strips,
                    compact: true,
                    showLegend: false,
                    singleSectionMode: false,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _riskColor(String? level) {
    switch (level) {
      case 'high':
        return AppColors.chartTrend;
      case 'medium':
        return Colors.orange.shade700;
      default:
        return AppColors.textMuted;
    }
  }

  String? _proctoringLine(BuildContext context, Map<String, dynamic> s) {
    final l10n = context.l10n;
    final tabs = (s['tabSwitchCount'] as num?)?.toInt() ?? 0;
    final focus = (s['focusLossSeconds'] as num?)?.toInt() ?? 0;
    final paste = (s['copyPasteAttempts'] as num?)?.toInt() ?? 0;
    if (tabs == 0 && focus == 0 && paste == 0) return null;
    final parts = <String>[
      if (tabs > 0) '${l10n.teacherLiveMonitorTabSwitches}: $tabs',
      if (focus > 0) '${l10n.teacherLiveMonitorFocusLoss}: ${focus}s',
      if (paste > 0) '${l10n.teacherLiveMonitorCopyPaste}: $paste',
    ];
    return parts.join('  ·  ');
  }

  void _openStudentLiveScreen(BuildContext context, Map<String, dynamic> s) {
    final l10n = context.l10n;
    final attemptId = s['attemptId']?.toString() ?? '';
    if (attemptId.isEmpty) return;
    final name = _participantDisplayName(s);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeacherStudentLiveScreenPage(
          attemptId: attemptId,
          studentName: name.isEmpty ? l10n.teacherDashboardStudentUnknown : name,
          initialLiveScreen: s,
        ),
      ),
    );
  }

  Widget _studentActionsMenu(BuildContext context, Map<String, dynamic> s) {
    final l10n = context.l10n;
    final busy = context.read<TeacherExamSessionConsoleBloc>().state.busy;
    final attemptId = s['attemptId']?.toString() ?? '';
    final status = s['status']?.toString() ?? '';
    final canWatch = attemptId.isNotEmpty;
    final canRemind = status == 'in_progress';
    final canKick = status == 'in_progress';
    final items = <PopupMenuEntry<String>>[
      if (canWatch)
        PopupMenuItem<String>(
          value: 'watch',
          child: Row(
            children: [
              const Icon(Icons.monitor_outlined, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(l10n.teacherLiveMonitorWatchScreen),
            ],
          ),
        ),
      if (canRemind)
        PopupMenuItem<String>(
          value: 'remind',
          child: Row(
            children: [
              const Icon(Icons.notifications_active_outlined, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(l10n.teacherExamWarnStudentAction),
            ],
          ),
        ),
      if (canKick)
        PopupMenuItem<String>(
          value: 'kick',
          child: Row(
            children: [
              const Icon(Icons.person_remove_outlined, size: 18, color: AppColors.danger),
              const SizedBox(width: 8),
              Text(l10n.examSessionKickStudentAction, style: const TextStyle(color: AppColors.danger)),
            ],
          ),
        ),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      enabled: !busy,
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_horiz, size: 18, color: AppColors.textSecondary),
      onSelected: (v) {
        switch (v) {
          case 'watch':
            _openStudentLiveScreen(context, s);
          case 'remind':
            _openWarnDialog(context, s);
          case 'kick':
            _confirmKick(context, s);
        }
      },
      itemBuilder: (_) => items,
    );
  }

  Future<void> _openWarnDialog(BuildContext context, Map<String, dynamic> s) async {
    final sessionId = context.read<TeacherExamSessionConsoleBloc>().state.sessionId ?? '';
    final studentUserId = s['userId']?.toString() ?? '';
    if (sessionId.isEmpty || studentUserId.isEmpty) return;
    final name = _participantDisplayName(s);
    final message = await TeacherDialogShell.show<String>(
      context,
      child: _WarnStudentDialog(studentName: name),
    );
    if (message == null || message.trim().isEmpty || !context.mounted) return;
    getIt<SocketService>().emitTeacherExamWarnStudent(
      sessionId: sessionId,
      studentUserId: studentUserId,
      message: message.trim(),
    );
    AppCornerToast.show(context, context.l10n.teacherExamWarnStudentSent);
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
              ? TeacherSkeleton.page(TeacherSkeleton.table(rows: 10))
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
                      ? _buildLiveControlBody(context, state, sid, roomCode, createdLabel)
                      : ListView(
                          padding: TeacherWebUi.pageScrollPadding(context),
                          children: [
                            _sessionCompactStrip(context, state, roomCode, createdLabel),
                            const SizedBox(height: ExamSystemUi.cardGap),
                            if (sid.isNotEmpty && state.isLobby) ...[
                              _studentShareCard(state, roomCode),
                              const SizedBox(height: ExamSystemUi.cardGap),
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

/// Type-to-confirm dialog for irreversible end-session (`18` §5.8).
class _EndSessionConfirmDialog extends StatefulWidget {
  const _EndSessionConfirmDialog({required this.affectedCount});

  final int affectedCount;

  @override
  State<_EndSessionConfirmDialog> createState() => _EndSessionConfirmDialogState();
}

class _EndSessionConfirmDialogState extends State<_EndSessionConfirmDialog> {
  final _confirmCtrl = TextEditingController();
  String? _fieldError;

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _tryConfirm() {
    final expected = '${widget.affectedCount}';
    if (_confirmCtrl.text.trim() != expected) {
      setState(() => _fieldError = context.l10n.teacherExamEndSessionTypePrompt(widget.affectedCount));
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TeacherDialogShell(
      title: l10n.teacherExamEndSession,
      icon: Icons.stop_circle_outlined,
      width: 480,
      maxBodyHeight: 280,
      footer: TeacherDialogFooterActions(
        cancelLabel: l10n.cancel,
        primaryLabel: l10n.teacherExamEndSession,
        destructive: true,
        onCancel: () => Navigator.pop(context, false),
        onPrimary: _tryConfirm,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
            decoration: BoxDecoration(
              color: AppColors.dangerBg,
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.danger),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Text(
                    l10n.teacherExamEndSessionConfirm,
                    style: TeacherWebUi.webBody(context).copyWith(height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            l10n.teacherExamEndSessionTypePrompt(widget.affectedCount),
            style: TeacherWebUi.webBody(context),
          ),
          const SizedBox(height: AppSpacing.s3),
          TextField(
            controller: _confirmCtrl,
            keyboardType: TextInputType.number,
            decoration: TeacherWebUi.formInputDecoration(context),
            onChanged: (_) {
              if (_fieldError != null) setState(() => _fieldError = null);
            },
            onSubmitted: (_) => _tryConfirm(),
          ),
          TeacherWebUi.formFieldError(context, _fieldError),
        ],
      ),
    );
  }
}

class _RosterEntry {
  const _RosterEntry({
    required this.participant,
    required this.name,
    required this.sub,
    required this.avatarUrl,
    required this.chipStatus,
    required this.showKick,
  });

  final Map<String, dynamic> participant;
  final String name;
  final String sub;
  final String? avatarUrl;
  final TeacherExamParticipantStatus chipStatus;
  final bool showKick;
}

/// Compose a live reminder pushed to one student's exam screen. Presets quick-fill
/// the editable message; returns the trimmed text on send (null on cancel).
class _WarnStudentDialog extends StatefulWidget {
  const _WarnStudentDialog({required this.studentName});

  final String studentName;

  @override
  State<_WarnStudentDialog> createState() => _WarnStudentDialogState();
}

class _WarnStudentDialogState extends State<_WarnStudentDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _fill(String text) {
    _ctrl.text = text;
    _ctrl.selection = TextSelection.collapsed(offset: text.length);
    setState(() {});
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final presets = <(String, String)>[
      (l10n.teacherExamWarnChipTabSwitch, l10n.teacherExamWarnPresetTabSwitch),
      (l10n.teacherExamWarnChipCopyPaste, l10n.teacherExamWarnPresetCopyPaste),
      (l10n.teacherExamWarnChipFocus, l10n.teacherExamWarnPresetFocus),
    ];
    final subtitle = widget.studentName.isEmpty
        ? l10n.teacherExamWarnStudentSubtitle
        : '${widget.studentName} · ${l10n.teacherExamWarnStudentSubtitle}';
    return TeacherDialogShell(
      title: l10n.teacherExamWarnStudentTitle,
      icon: Icons.notifications_active_outlined,
      width: 460,
      maxBodyHeight: 360,
      footer: TeacherDialogFooterActions(
        cancelLabel: l10n.cancel,
        primaryLabel: l10n.teacherExamWarnStudentSend,
        onCancel: () => Navigator.pop(context),
        onPrimary: _send,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(subtitle, style: ExamSystemUi.captionSecondary),
          const SizedBox(height: AppSpacing.s4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in presets)
                ActionChip(
                  label: Text(p.$1, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _fill(p.$2),
                  backgroundColor: AppColors.surfaceCard,
                  side: const BorderSide(color: AppColors.outline),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(l10n.teacherExamWarnStudentMessageLabel, style: TeacherWebUi.webBody(context)),
          const SizedBox(height: AppSpacing.s2),
          TextField(
            controller: _ctrl,
            minLines: 2,
            maxLines: 4,
            maxLength: 500,
            style: TeacherWebUi.webBody(context),
            decoration: TeacherWebUi.formInputDecoration(context),
          ),
        ],
      ),
    );
  }
}
