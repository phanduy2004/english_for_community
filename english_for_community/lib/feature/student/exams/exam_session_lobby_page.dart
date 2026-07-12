import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/ui/feedback/app_feedback.dart';
import 'package:english_for_community/core/util/app_haptics.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/socket/socket_service.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/core/ui/avatar_url.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:english_for_community/feature/auth/bloc/user_bloc.dart';
import 'package:english_for_community/feature/student/exams/exam_live_session_guard.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        AppFeedback.error(context, context.l10n.examSessionEndedByTeacher, blocking: true);
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

  // ─── Button styles (full-width CTA) ───────────────────────────────────
  ButtonStyle _primaryButtonStyle() => FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        textStyle: AppTypography.body(large: true).copyWith(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      );

  ButtonStyle _outlinedButtonStyle() => OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.outlineStrong),
        textStyle: AppTypography.body(large: true).copyWith(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      );

  Future<void> _copyRoomCode() async {
    final code = _roomCode?.trim();
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    AppFeedback.success(context, context.l10n.copiedToClipboard);
  }

  // ─── Hero: waiting / live status (softens the "waiting" peak, §5) ──────
  Widget _buildHero(
    BuildContext context,
    String st,
    AppLocalizations l10n, {
    String? examTitle,
    String? className,
    String? teacherName,
  }) {
    final bool waiting =
        st != 'live' && st != 'closed' && st != 'grading' && st != 'canceled';
    final (Color accent, IconData icon, String label) = switch (st) {
      'live' => (AppColors.primary, Icons.play_circle_fill_rounded, l10n.examSessionStatusLive),
      'grading' => (AppColors.warning, Icons.hourglass_top_rounded, l10n.teacherDashboardLiveStatusGrading),
      'closed' => (AppColors.textMuted, Icons.check_circle_rounded, l10n.examSessionStatusClosed),
      'canceled' => (AppColors.danger, Icons.cancel_rounded, l10n.examSessionStatusCanceled),
      _ => (AppColors.primary, Icons.meeting_room_rounded, l10n.examSessionStatusLobby),
    };
    final String? subtitle = waiting ? l10n.examWaitingForTeacher : null;

    final bool hasTitle = examTitle != null && examTitle.isNotEmpty;
    final bool hasClass = className != null && className.isNotEmpty;
    final bool hasTeacher = teacherName != null && teacherName.isNotEmpty;
    final bool hasMeta = hasTitle || hasClass || hasTeacher;

    return AppCard(
      variant: AppCardVariant.outline,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.s8,
        horizontal: AppSpacing.s5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _PulsingIcon(icon: icon, color: accent, animate: waiting)),
          const SizedBox(height: AppSpacing.s5),
          Text(label, textAlign: TextAlign.center, style: AppTypography.displaySm()),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: StudentMobileUi.body(context).copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (hasMeta) ...[
            const SizedBox(height: AppSpacing.s5),
            const Divider(height: 1, color: AppColors.outlineMuted),
            const SizedBox(height: AppSpacing.s4),
            if (hasTitle)
              Text(
                examTitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: StudentMobileUi.cardTitle(context),
              ),
            if (hasClass) ...[
              const SizedBox(height: AppSpacing.s1),
              Text(
                l10n.teacherDashboardClassLabel(className),
                textAlign: TextAlign.center,
                style: StudentMobileUi.caption(context),
              ),
            ],
            if (hasTeacher) ...[
              const SizedBox(height: AppSpacing.s1),
              Text(
                l10n.studentClassTeacher(teacherName),
                textAlign: TextAlign.center,
                style: StudentMobileUi.caption(context),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ─── Room code (prominent, copyable anchor) ───────────────────────────
  Widget _buildRoomCodeCard(BuildContext context, AppLocalizations l10n) {
    final code = _roomCode?.trim();
    final bool has = code != null && code.isNotEmpty;
    return AppCard(
      variant: AppCardVariant.outline,
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: Row(
        children: [
          StudentMobileUi.roundIconBox(Icons.tag_rounded, size: 44),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.examSessionRoomCode.toUpperCase(),
                  style: StudentMobileUi.caption(context).copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  has ? code : '—',
                  style: AppTypography.displaySm()
                      .copyWith(letterSpacing: 3, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (has)
            StudentMobileUi.tappable(
              context: context,
              onTap: _copyRoomCode,
              minSize: 44,
              tooltip: MaterialLocalizations.of(context).copyButtonLabel,
              child: const Icon(Icons.copy_rounded, size: 20, color: AppColors.primary),
            ),
        ],
      ),
    );
  }

  // ─── Participants ─────────────────────────────────────────────────────
  Widget _buildParticipantsCard(BuildContext context, String st, AppLocalizations l10n) {
    return AppCard(
      variant: AppCardVariant.outline,
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.examSessionLobbyParticipantsTitle,
                  style: StudentMobileUi.sectionTitle(context),
                ),
              ),
              _countPill(context),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            l10n.teacherExamSessionJoinedCount(_joinedCount),
            style: StudentMobileUi.body(context).copyWith(fontWeight: FontWeight.w600),
          ),
          if (st == 'lobby' && _joinedCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s1),
              child: Text(
                l10n.examSessionReadyCount(_readyCount, _joinedCount),
                style: StudentMobileUi.caption(context),
              ),
            ),
          if (_participants.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s3),
            const Divider(height: 1, color: AppColors.outlineMuted),
            ..._participants.map((p) => _participantRow(context, p, st, l10n)),
          ],
        ],
      ),
    );
  }

  Widget _countPill(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.group_rounded, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            '$_joinedCount',
            style: StudentMobileUi.caption(context)
                .copyWith(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _participantRow(BuildContext context, Map<String, dynamic> p, String st, AppLocalizations l10n) {
    final name = _lobbyName(p);
    final sub = _lobbySubtitle(p);
    final bool ready = p['ready'] == true;
    final myId = getIt<UserBloc>().state.userEntity?.id;
    final bool isMe = myId != null && p['userId']?.toString() == myId;
    final displayName = name.isEmpty ? l10n.teacherDashboardStudentUnknown : name;
    final letter = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    final avatarUrl = (p['avatarUrl'] as String?)?.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ready ? AppColors.success.withValues(alpha: 0.4) : AppColors.outline,
              ),
            ),
            child: ClipOval(
              child: isUsableAvatarUrl(avatarUrl)
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _lobbyAvatarFallback(context, letter, ready),
                      errorWidget: (_, __, ___) => _lobbyAvatarFallback(context, letter, ready),
                    )
                  : _lobbyAvatarFallback(context, letter, ready),
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: StudentMobileUi.cardTitle(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: AppSpacing.s2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          l10n.examSessionYouTag,
                          style: AppTypography.label(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ],
                ),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    sub,
                    style: StudentMobileUi.caption(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (st == 'lobby') ...[
            const SizedBox(width: AppSpacing.s3),
            _readyChip(context, ready, l10n),
          ],
        ],
      ),
    );
  }

  Widget _lobbyAvatarFallback(BuildContext context, String letter, bool ready) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      color: ready ? AppColors.successBg : AppColors.surfaceSubtle,
      child: Text(
        letter,
        style: StudentMobileUi.cardTitle(context).copyWith(
          fontWeight: FontWeight.w700,
          color: ready ? AppColors.successDark : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _readyChip(BuildContext context, bool ready, AppLocalizations l10n) {
    final Color fg = ready ? AppColors.success : AppColors.textSecondary;
    final Color bg = ready ? AppColors.successBg : AppColors.surfaceSubtle;
    final Color border = ready ? AppColors.success.withValues(alpha: 0.4) : AppColors.outline;
    final IconData icon = ready ? Icons.check_circle_rounded : Icons.schedule_rounded;
    final String text = ready ? l10n.examSessionStudentReady : l10n.examSessionStudentNotReady;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(text, style: AppTypography.label(color: fg)),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, String st, AppLocalizations l10n) {
    final bool showReady = st == 'lobby';
    final bool showOpen = st == 'live' && _error == null;
    if (!showReady && !showOpen) return const SizedBox.shrink();

    final Widget action = showOpen
        ? FilledButton.icon(
            style: _primaryButtonStyle(),
            onPressed: _tryOpenAttemptIfReady,
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: Text(l10n.examSessionGo),
          )
        : (_myReady
            ? OutlinedButton.icon(
                style: _outlinedButtonStyle(),
                onPressed: () {
                  AppHaptics.select(context);
                  _setReady(false);
                },
                icon: const Icon(Icons.close_rounded, size: 18),
                label: Text(l10n.examSessionCancelReady),
              )
            : FilledButton.icon(
                style: _primaryButtonStyle(),
                onPressed: () {
                  AppHaptics.confirm(context);
                  _setReady(true);
                },
                icon: const Icon(Icons.check_rounded, size: 20),
                label: Text(l10n.examSessionMarkReady),
              ));

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showReady && _myReady) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.success),
                const SizedBox(width: AppSpacing.s2),
                Flexible(
                  child: Text(
                    l10n.examWaitingForTeacher,
                    style: StudentMobileUi.caption(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s3),
          ],
          SizedBox(width: double.infinity, child: action),
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
          ? StudentMobileUi.lobbyLoading()
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
                      _buildHero(
                        context,
                        st,
                        l10n,
                        examTitle: examTitle,
                        className: className,
                        teacherName: teacherName,
                      ),
                      const SizedBox(height: StudentMobileUi.sectionGap),
                      _buildRoomCodeCard(context, l10n),
                      const SizedBox(height: StudentMobileUi.sectionGap),
                      _buildParticipantsCard(context, st, l10n),
                    ],
                  ),
                ),
                _buildBottomActions(context, st, l10n),
              ],
            ),
    );
  }
}

/// Breathing pulse behind the lobby status icon — softens the "waiting"
/// moment (peak-end rule, SKILL §5). Respects reduce-motion.
class _PulsingIcon extends StatefulWidget {
  const _PulsingIcon({
    required this.icon,
    required this.color,
    this.animate = true,
  });

  final IconData icon;
  final Color color;
  final bool animate;

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  static const double _size = 72;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _PulsingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _ring(double t) {
    final scale = 1.0 + 0.75 * t;
    final opacity = ((1.0 - t) * 0.28).clamp(0.0, 1.0);
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: widget.color, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final core = Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(widget.icon, size: _size * 0.44, color: widget.color),
    );

    final bool reduce = MediaQuery.disableAnimationsOf(context);
    if (!widget.animate || reduce) return core;

    final double box = _size * 1.85;
    return RepaintBoundary(
      child: SizedBox(
        width: box,
        height: box,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t1 = _controller.value;
            final t2 = (_controller.value + 0.5) % 1.0;
            return Stack(
              alignment: Alignment.center,
              children: [
                _ring(t2),
                _ring(t1),
                if (child != null) child,
              ],
            );
          },
          child: core,
        ),
      ),
    );
  }
}
