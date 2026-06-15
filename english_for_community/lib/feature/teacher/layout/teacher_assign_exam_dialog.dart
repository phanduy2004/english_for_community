import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_content_label.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_dialog_shell.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_realtime_schedule_section.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_session_console_page.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Assign a published exam to a class or public link — `docs/ui-ux-system/14-teacher-dialogs.md`.
class TeacherAssignExamDialog extends StatefulWidget {
  const TeacherAssignExamDialog({
    super.key,
    required this.examId,
    this.initialClassroomId,
  });

  final String examId;
  final String? initialClassroomId;

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String examId,
    String? initialClassroomId,
  }) =>
      TeacherDialogShell.show<Map<String, dynamic>>(
        context,
        child: TeacherAssignExamDialog(
          examId: examId,
          initialClassroomId: initialClassroomId,
        ),
      );

  @override
  State<TeacherAssignExamDialog> createState() => _TeacherAssignExamDialogState();
}

class _TeacherAssignExamDialogState extends State<TeacherAssignExamDialog> {
  bool _loading = true;
  bool _submitting = false;
  String? _examTitle;
  String? _examStatus;
  List<dynamic> _classrooms = [];
  String? _classroomId;
  String _mode = 'self_paced';
  String _audience = 'classroom';
  DateTime? _dueAt;
  DateTime? _opensAt;
  DateTime? _closesAt;
  String _realtimeScheduleMode = 'manual';
  DateTime? _lobbyOpensAt;
  DateTime? _scheduledStartAt;
  DateTime? _publicExpiresAt;
  final _timeLimitMinutes = TextEditingController();
  final _publicMaxUses = TextEditingController();
  bool _allowPartialSubmit = true;
  String _attemptPolicy = 'single';
  int _maxAttempts = 2;
  String _showResultsPolicy = 'after_release';
  String _resultsDetailLevel = 'full_detail';
  List<dynamic> _presets = [];

  static const _maxAttemptChoices = [2, 3, 5, 10];

  // ─── Per-mode accent colours (info callouts only — not selection tiles) ───
  static const _modeInfoColors = {
    'practice': (fg: Color(0xFF7C3AED), bg: Color(0xFFF5F3FF)),
  };

  // ─── Policy colours ────────────────────────────────────────────────────────
  static const _policyColors = {
    'after_submit':  (fg: Color(0xFF15803D), bg: Color(0xFFECFDF5), border: Color(0xFF86EFAC)),
    'after_release': (fg: Color(0xFFD97706), bg: Color(0xFFFFFBEB), border: Color(0xFFFCD34D)),
    'never':         (fg: Color(0xFFDC2626), bg: Color(0xFFFEF2F2), border: Color(0xFFFCA5A5)),
  };

  @override
  void dispose() {
    _timeLimitMinutes.dispose();
    _publicMaxUses.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final repo = getIt<TeacherExamRepository>();
    final ex = await repo.getExam(widget.examId);
    final cr = await repo.listMyClassroomsAsTeacher();
    if (!mounted) return;
    ex.fold((_) {}, (d) {
      final m = Map<String, dynamic>.from(d as Map);
      _examStatus = m['status'] as String?;
      final t = (m['title'] as String?)?.trim();
      if (t != null && t.isNotEmpty) _examTitle = t;
    });
    final pr = await repo.listAssignmentPresets();
    pr.fold((_) {}, (list) => _presets = list);
    cr.fold((_) {}, (list) {
      _classrooms = list;
      String? pickId;
      final wanted = widget.initialClassroomId;
      if (wanted != null && wanted.isNotEmpty) {
        for (final raw in list) {
          final m = Map<String, dynamic>.from(raw as Map);
          final id = (m['id'] ?? m['_id'])?.toString() ?? '';
          if (id == wanted) { pickId = id; break; }
        }
      }
      if (pickId == null && list.isNotEmpty) {
        final first = Map<String, dynamic>.from(list.first as Map);
        pickId = (first['id'] ?? first['_id'])?.toString();
      }
      _classroomId = pickId;
    });
    setState(() => _loading = false);
  }

  String _formatDateTime(DateTime? dt) {
    final l10n = context.l10n;
    if (dt == null) return l10n.teacherAssignmentOptional;
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).add_Hm().format(dt.toLocal());
  }

  void _applyPreset(Map<String, dynamic> cfg) {
    setState(() {
      final mode = cfg['mode'] as String?;
      if (mode != null) _mode = mode;
      final ap = cfg['attemptPolicy'] as String?;
      if (ap != null) _attemptPolicy = ap;
      final ma = cfg['maxAttempts'];
      if (ma is num) _maxAttempts = ma.toInt();
      final sr = cfg['showResultsPolicy'] as String?;
      if (sr != null) _showResultsPolicy = sr;
      final rd = cfg['resultsDetailLevel'] as String?;
      if (rd == 'score_only' || rd == 'full_detail') _resultsDetailLevel = rd!;
      if (cfg.containsKey('allowPartialSubmit')) {
        _allowPartialSubmit = cfg['allowPartialSubmit'] == true;
      }
      final tl = cfg['timeLimitSeconds'];
      if (tl is num && tl > 0) {
        _timeLimitMinutes.text = (tl / 60).round().toString();
      }
    });
  }

  void _applyTimeLimitToConfig(Map<String, dynamic> config) {
    if (_mode == 'practice') return;
    final mins = int.tryParse(_timeLimitMinutes.text.trim());
    if (mins != null && mins > 0) {
      config['timeLimitSeconds'] = mins * 60;
    }
  }

  Future<void> _savePreset() async {
    final l10n = context.l10n;
    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.teacherAssignmentPresetSave),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(labelText: l10n.teacherAssignmentPresetLabel),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.save)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final name = nameCtrl.text.trim();
    nameCtrl.dispose();
    if (name.isEmpty) return;
    final presetCfg = <String, dynamic>{
      'mode': _mode,
      'attemptPolicy': _attemptPolicy,
      if (_attemptPolicy == 'limited') 'maxAttempts': _maxAttempts,
      'showResultsPolicy': _showResultsPolicy,
      'resultsDetailLevel': _resultsDetailLevel,
      'allowPartialSubmit': _allowPartialSubmit,
    };
    _applyTimeLimitToConfig(presetCfg);
    final r = await getIt<TeacherExamRepository>().createAssignmentPreset({
      'name': name,
      'config': presetCfg,
    });
    if (!mounted) return;
    r.fold(
      (f) => AppCornerToast.show(context, f.message, error: true),
      (_) {
        AppCornerToast.show(context, l10n.teacherAssignmentPresetSaved);
        _bootstrap();
      },
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_examStatus != 'published') {
      AppCornerToast.show(context, l10n.teacherAssignmentExamNotPublished, error: true);
      return;
    }
    if (_audience == 'classroom' && (_classroomId == null || _classroomId!.isEmpty)) {
      AppCornerToast.show(context, l10n.teacherAssignmentPickClass, error: true);
      return;
    }
    if (_mode == 'realtime' &&
        _realtimeScheduleMode == 'scheduled' &&
        _scheduledStartAt == null) {
      AppCornerToast.show(
        context,
        l10n.teacherAssignmentRealtimeScheduledStartRequired,
        error: true,
      );
      return;
    }
    setState(() => _submitting = true);
    final config = <String, dynamic>{
      'allowPartialSubmit': _allowPartialSubmit,
      'partialSubmitConfirm': true,
      'attemptPolicy': _attemptPolicy,
      'showResultsPolicy': _showResultsPolicy,
      'resultsDetailLevel': _resultsDetailLevel,
      if (_attemptPolicy == 'limited') 'maxAttempts': _maxAttempts,
    };
    if (_mode == 'self_paced' && _dueAt != null) {
      config['dueAt'] = _dueAt!.toUtc().toIso8601String();
    }
    if (_mode == 'scheduled') {
      if (_opensAt != null) config['opensAt'] = _opensAt!.toUtc().toIso8601String();
      if (_closesAt != null) config['closesAt'] = _closesAt!.toUtc().toIso8601String();
    }
    if (_mode == 'realtime') {
      config['realtimeScheduleMode'] = _realtimeScheduleMode;
      if (_realtimeScheduleMode == 'scheduled') {
        config['scheduledStartAt'] = _scheduledStartAt!.toUtc().toIso8601String();
        if (_lobbyOpensAt != null) {
          config['lobbyOpensAt'] = _lobbyOpensAt!.toUtc().toIso8601String();
        }
      }
    }
    _applyTimeLimitToConfig(config);

    final body = <String, dynamic>{
      'examId': widget.examId,
      'audience': _audience,
      'mode': _mode,
      'config': config,
    };
    if (_audience == 'classroom') {
      body['classroomId'] = _classroomId;
    } else {
      final mu = int.tryParse(_publicMaxUses.text.trim());
      body['publicJoin'] = {
        if (mu != null && mu > 0) 'maxUses': mu,
        if (_publicExpiresAt != null) 'expiresAt': _publicExpiresAt!.toUtc().toIso8601String(),
      };
    }

    final r = await getIt<TeacherExamRepository>().createAssignmentBody(body);
    if (!mounted) return;
    setState(() => _submitting = false);
    r.fold(
      (f) => AppCornerToast.show(context, f.message, error: true),
      (d) async {
        AppCornerToast.show(context, l10n.teacherAssignmentCreated);
        if (_audience == 'public_link' && d is Map) {
          final pj = d['publicJoin'];
          final assignmentId = (d['id'] ?? d['_id'])?.toString() ?? '';
          final isRealtime = _mode == 'realtime';
          if (pj is Map && (pj['token'] as String?)?.isNotEmpty == true) {
            final tok = pj['token'] as String;
            await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.teacherAssignmentPublicTokenTitle),
                content: SelectableText(
                  '${l10n.teacherAssignmentPublicTokenBody}\n\n$tok'
                  '${isRealtime ? '\n\n${l10n.teacherAssignmentPublicRealtimeNextSteps}' : ''}',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: tok));
                      Navigator.pop(ctx);
                      AppCornerToast.show(context, l10n.dashboardPublicTokenCopied);
                    },
                    child: Text(l10n.dashboardPublicCopyToken),
                  ),
                  if (isRealtime && assignmentId.isNotEmpty)
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('${TeacherExamSessionConsolePage.routePath}/$assignmentId');
                      },
                      child: Text(l10n.teacherAssignmentOpenLiveConsole),
                    )
                  else
                    FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.ok)),
                ],
              ),
            );
          }
        }
        if (mounted) {
          Navigator.of(context).pop(d is Map ? Map<String, dynamic>.from(d) : null);
        }
      },
    );
  }

  Future<void> _pickDateTime(
    void Function(DateTime) onPicked, {
    DateTime? initial,
    DateTime? firstDate,
  }) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: firstDate ?? now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: initial != null ? TimeOfDay.fromDateTime(initial) : TimeOfDay.now(),
    );
    if (t == null || !mounted) return;
    onPicked(DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  InputDecoration _textDec({String? hint}) =>
      TeacherWebUi.formInputDecoration(context, hintText: hint);

  Widget _formGroup({required String label, required Widget child}) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TeacherWebUi.formFieldLabel(context, label),
          const SizedBox(height: 6),
          child,
        ],
      );

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return _formGroup(
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              border: Border.all(color: AppColors.outline),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: TeacherWebUi.formInputContentPadding,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDateTime(value),
                      style: TeacherWebUi.webBody(context).copyWith(
                        fontSize: 14,
                        color: value == null ? AppColors.textMuted : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textMuted),
                  if (onClear != null && value != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: onClear,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Section header with coloured icon ────────────────────────────────────
  Widget _sectionHeader(String label, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 13, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: TeacherWebUi.sectionTitle(context).copyWith(
            letterSpacing: 0.5,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }

  // ─── Audience tiles ────────────────────────────────────────────────────────
  Widget _audienceSection(AppLocalizations l10n) {
    final options = [
      (
        value: 'classroom',
        icon: Icons.groups_2_outlined,
        title: l10n.teacherAssignmentAudienceClassroom,
        hint: l10n.teacherAssignmentAudienceClassroomHint,
      ),
      (
        value: 'public_link',
        icon: Icons.link_rounded,
        title: l10n.teacherAssignmentAudiencePublic,
        hint: l10n.teacherAssignmentAudiencePublicHint,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _audienceTile(options[i])),
        ],
      ],
    );
  }

  Widget _audienceTile(dynamic opt) {
    final selected = _audience == opt.value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _audience = opt.value),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: TeacherWebUi.choiceTileDecoration(selected: selected),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: TeacherWebUi.choiceTileIconBoxColor(selected: selected),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  opt.icon as IconData,
                  size: 16,
                  color: TeacherWebUi.choiceTileIconColor(selected: selected),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opt.title as String,
                      style: TeacherWebUi.webLabel(context).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: TeacherWebUi.choiceTileTitleColor(selected: selected),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      opt.hint as String,
                      style: TeacherWebUi.metaMuted.copyWith(fontSize: 10.5, height: 1.3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Mode grid (2×2 with per-mode accent) ─────────────────────────────────
  Widget _modeGrid(AppLocalizations l10n) {
    final options = [
      _ModeOption(
        value: 'self_paced',
        icon: Icons.menu_book_outlined,
        title: l10n.examModeSelfPaced,
        hint: l10n.teacherAssignExamModeHintSelfPaced,
      ),
      _ModeOption(
        value: 'scheduled',
        icon: Icons.event_outlined,
        title: l10n.examModeScheduled,
        hint: l10n.teacherAssignExamModeHintScheduled,
      ),
      _ModeOption(
        value: 'realtime',
        icon: Icons.sensors,
        title: l10n.examModeRealtime,
        hint: l10n.teacherAssignExamModeHintRealtime,
      ),
      _ModeOption(
        value: 'practice',
        icon: Icons.fitness_center_outlined,
        title: l10n.examModePractice,
        hint: l10n.teacherAssignExamModeHintPractice,
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 380;
        return GridView.count(
          crossAxisCount: wide ? 2 : 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: wide ? 2.6 : 3.5,
          children: options.map((o) => _modeCard(o)).toList(),
        );
      },
    );
  }

  Widget _modeCard(_ModeOption o) {
    final selected = _mode == o.value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _mode = o.value),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
          decoration: TeacherWebUi.choiceTileDecoration(selected: selected),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: TeacherWebUi.choiceTileIconBoxColor(selected: selected),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  o.icon,
                  size: 15,
                  color: TeacherWebUi.choiceTileIconColor(selected: selected),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      o.title,
                      style: TeacherWebUi.webLabel(context).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: TeacherWebUi.choiceTileTitleColor(selected: selected),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      o.hint,
                      style: TeacherWebUi.metaMuted.copyWith(fontSize: 10, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Schedule block ────────────────────────────────────────────────────────
  Widget _scheduleBlock(AppLocalizations l10n) {
    if (_mode == 'practice') {
      final pc = _modeInfoColors['practice']!;
      return _infoBox(
        icon: Icons.info_outline_rounded,
        text: l10n.teacherAssignExamModeHintPractice,
        color: pc.fg,
        bg: pc.bg,
      );
    }

    final children = <Widget>[];
    if (_mode == 'realtime') {
      children.add(
        TeacherRealtimeScheduleSection(
          scheduleMode: _realtimeScheduleMode,
          scheduledStartAt: _scheduledStartAt,
          lobbyOpensAt: _lobbyOpensAt,
          onScheduleModeChanged: (m) => setState(() {
            _realtimeScheduleMode = m;
            if (m == 'manual') {
              _scheduledStartAt = null;
              _lobbyOpensAt = null;
            }
          }),
          onScheduledStartChanged: (d) => setState(() => _scheduledStartAt = d),
          onLobbyOpensChanged: (d) => setState(() => _lobbyOpensAt = d),
          formatDateTime: _formatDateTime,
          onPickDateTime: ({required initial, required onPicked, firstDate}) =>
              _pickDateTime(onPicked, initial: initial, firstDate: firstDate),
        ),
      );
      children.add(const SizedBox(height: AppSpacing.s4));
    }

    if (_mode == 'self_paced') {
      children.add(
        _dateField(
          label: l10n.teacherAssignmentDueDate,
          value: _dueAt,
          onTap: () => _pickDateTime((d) => setState(() => _dueAt = d), initial: _dueAt),
          onClear: () => setState(() => _dueAt = null),
        ),
      );
    }
    if (_mode == 'scheduled') {
      children.addAll([
        _dateField(
          label: l10n.teacherAssignmentOpensAt,
          value: _opensAt,
          onTap: () => _pickDateTime((d) => setState(() => _opensAt = d), initial: _opensAt),
          onClear: () => setState(() => _opensAt = null),
        ),
        const SizedBox(height: AppSpacing.s4),
        _dateField(
          label: l10n.teacherAssignmentClosesAt,
          value: _closesAt,
          onTap: () => _pickDateTime((d) => setState(() => _closesAt = d), initial: _closesAt),
          onClear: () => setState(() => _closesAt = null),
        ),
        const SizedBox(height: AppSpacing.s3),
        Text(
          l10n.teacherAssignExamCalendarNote,
          style: TeacherWebUi.metaMuted.copyWith(fontSize: 11, height: 1.4),
        ),
      ]);
    }

    if (_mode != 'practice') {
      children.addAll([
        const SizedBox(height: AppSpacing.s4),
        _formGroup(
          label: l10n.teacherAssignmentTimeLimitMinutes,
          child: TextField(
            controller: _timeLimitMinutes,
            keyboardType: TextInputType.number,
            style: TeacherWebUi.webBody(context).copyWith(fontSize: 14),
            decoration: _textDec(hint: l10n.teacherAssignmentTimeLimitMinutesHint),
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        // Quick-pick chips with accent
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [30, 45, 60, 90, 120].map((m) {
            final active = _timeLimitMinutes.text.trim() == '$m';
            return GestureDetector(
              onTap: () => setState(() => _timeLimitMinutes.text = '$m'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: active ? AppColors.primaryTint : AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.outlineStrong,
                    width: active ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  l10n.teacherAssignmentTimeLimitPresetMinutes(m),
                  style: TeacherWebUi.webLabel(context).copyWith(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }

  // ─── Rules panel ──────────────────────────────────────────────────────────
  Widget _rulesPanel(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Attempt policy row
        TeacherWebUi.formFieldLabel(context, l10n.teacherAssignmentSectionRules),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final ap in ['single', 'unlimited', 'limited']) ...[
              if (ap != 'single') const SizedBox(width: 8),
              Expanded(child: _attemptTile(ap, l10n)),
            ],
          ],
        ),
        if (_attemptPolicy == 'limited') ...[
          const SizedBox(height: AppSpacing.s4),
          _formGroup(
            label: l10n.teacherAssignmentMaxAttempts,
            child: DropdownButtonFormField<int>(
              key: ValueKey(_maxAttempts),
              initialValue: _maxAttempts,
              isExpanded: true,
              decoration: _textDec(),
              items: _maxAttemptChoices
                  .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _maxAttempts = v);
              },
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s5),
        // When students see results — 3 coloured tiles
        TeacherWebUi.formFieldLabel(context, l10n.teacherAssignmentShowResults),
        const SizedBox(height: 8),
        _policyTiles(l10n),
        const SizedBox(height: AppSpacing.s5),
        TeacherWebUi.formFieldLabel(context, l10n.teacherAssignmentResultsDetailLabel),
        const SizedBox(height: 8),
        _detailLevelTiles(l10n),
        const SizedBox(height: AppSpacing.s4),
        // Partial submit toggle
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.outline),
          ),
          child: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            title: Text(
              l10n.teacherAssignmentAllowPartialSubmit,
              style: TeacherWebUi.webBody(context).copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            subtitle: Text(
              l10n.teacherAssignmentAllowPartialSubmitHint,
              style: TeacherWebUi.metaMuted.copyWith(fontSize: 11, height: 1.35),
            ),
            value: _allowPartialSubmit,
            onChanged: (v) => setState(() => _allowPartialSubmit = v),
          ),
        ),
      ],
    );
  }

  Widget _attemptTile(String value, AppLocalizations l10n) {
    final selected = _attemptPolicy == value;
    final label = switch (value) {
      'single'    => l10n.teacherAssignmentAttemptSingle,
      'unlimited' => l10n.teacherAssignmentAttemptUnlimited,
      _           => l10n.teacherAssignmentAttemptLimited,
    };
    final icon = switch (value) {
      'single'    => Icons.looks_one_outlined,
      'unlimited' => Icons.all_inclusive_rounded,
      _           => Icons.format_list_numbered_rounded,
    };
    return GestureDetector(
      onTap: () => setState(() => _attemptPolicy = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: TeacherWebUi.choiceTileDecoration(selected: selected),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: TeacherWebUi.choiceTileIconColor(selected: selected),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TeacherWebUi.webLabel(context).copyWith(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: TeacherWebUi.choiceTileTitleColor(selected: selected),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailLevelTiles(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _detailLevelTile(
            value: 'score_only',
            icon: Icons.leaderboard_outlined,
            label: l10n.teacherResultsDetailScoreOnly,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _detailLevelTile(
            value: 'full_detail',
            icon: Icons.fact_check_outlined,
            label: l10n.teacherResultsDetailFull,
          ),
        ),
      ],
    );
  }

  Widget _detailLevelTile({
    required String value,
    required IconData icon,
    required String label,
  }) {
    final selected = _resultsDetailLevel == value;
    return GestureDetector(
      onTap: () => setState(() => _resultsDetailLevel = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: TeacherWebUi.choiceTileDecoration(selected: selected),
        child: Column(
          children: [
            Icon(icon, size: 18, color: TeacherWebUi.choiceTileIconColor(selected: selected)),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TeacherWebUi.webLabel(context).copyWith(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: TeacherWebUi.choiceTileTitleColor(selected: selected),
                height: 1.25,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _policyTiles(AppLocalizations l10n) {
    final options = [
      (
        value: 'after_submit',
        icon: Icons.check_circle_outline_rounded,
        label: l10n.teacherExamPolicyAfterSubmit,
      ),
      (
        value: 'after_release',
        icon: Icons.lock_open_outlined,
        label: l10n.teacherExamPolicyAfterRelease,
      ),
      (
        value: 'never',
        icon: Icons.visibility_off_outlined,
        label: l10n.teacherExamPolicyNever,
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _policyTile(options[i])),
        ],
      ],
    );
  }

  Widget _policyTile(dynamic opt) {
    final selected = _showResultsPolicy == opt.value;
    final pc = _policyColors[opt.value]!;
    return GestureDetector(
      onTap: () => setState(() => _showResultsPolicy = opt.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? pc.bg : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? pc.border : AppColors.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              opt.icon as IconData,
              size: 16,
              color: selected ? pc.fg : AppColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              opt.label as String,
              textAlign: TextAlign.center,
              style: TeacherWebUi.metaMuted.copyWith(
                fontSize: 10,
                height: 1.3,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? pc.fg : AppColors.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String text,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TeacherWebUi.metaMuted.copyWith(
                color: color.withValues(alpha: 0.85),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subtitle = _examTitle != null
        ? l10n.teacherAssignExamDialogSubtitleExam(_examTitle!)
        : l10n.teacherAssignExamDialogSubtitle;

    if (_loading) {
      return TeacherDialogShell(
        title: l10n.teacherAssignmentWizardTitle,
        subtitle: subtitle,
        icon: Icons.assignment_add,
        width: 560,
        maxBodyHeight: 200,
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: AppLoadingIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return TeacherDialogShell(
      title: l10n.teacherAssignmentWizardTitle,
      subtitle: subtitle,
      icon: Icons.assignment_add,
      width: 560,
      maxBodyHeight: 540,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Exam not published warning ───────────────────────────────
          if (_examStatus != 'published')
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s5),
              child: _infoBox(
                icon: Icons.warning_amber_rounded,
                text: l10n.teacherAssignmentExamNotPublished,
                color: AppColors.warning,
                bg: AppColors.warningBg,
              ),
            ),

          // ── Section: Audience ────────────────────────────────────────
          _sectionHeader(l10n.teacherAssignmentSectionAudience, Icons.people_outline_rounded, AppColors.primary),
          const SizedBox(height: 10),
          _audienceSection(l10n),
          const SizedBox(height: 14),

          if (_audience == 'classroom') ...[
            TeacherWebUi.formFieldLabel(context, l10n.teacherAssignmentClassroom),
            const SizedBox(height: 8),
            if (_classrooms.isEmpty)
              _infoBox(
                icon: Icons.info_outline_rounded,
                text: l10n.teacherAssignmentPickClass,
                color: AppColors.textSecondary,
                bg: AppColors.surfaceSubtle,
              )
            else
              ..._classrooms.map((raw) {
                final m = Map<String, dynamic>.from(raw as Map);
                final id = (m['id'] ?? m['_id'])?.toString() ?? '';
                final name = (m['name'] as String?) ?? id;
                return TeacherClassroomSelectTile(
                  key: ValueKey(id),
                  name: name,
                  selected: _classroomId == id,
                  onTap: () => setState(() => _classroomId = id),
                );
              }),
          ]
          else ...[
            _formGroup(
              label: l10n.teacherAssignmentPublicMaxUsesHint,
              child: TextField(
                controller: _publicMaxUses,
                keyboardType: TextInputType.number,
                decoration: _textDec(),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            _dateField(
              label: l10n.teacherAssignmentPublicExpiresHint,
              value: _publicExpiresAt,
              onTap: () => _pickDateTime(
                (d) => setState(() => _publicExpiresAt = d),
                initial: _publicExpiresAt,
              ),
              onClear: () => setState(() => _publicExpiresAt = null),
            ),
          ],

          // ── Divider ──────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Divider(height: 1, color: AppColors.outlineMuted),
          ),

          // ── Section: Delivery mode ───────────────────────────────────
          _sectionHeader(
            l10n.teacherAssignmentSectionDelivery,
            Icons.send_outlined,
            AppColors.primary,
          ),
          const SizedBox(height: 10),
          _modeGrid(l10n),
          const SizedBox(height: 14),
          _scheduleBlock(l10n),

          // ── Preset picker ────────────────────────────────────────────
          if (_presets.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: AppColors.outlineMuted),
            ),
            _formGroup(
              label: l10n.teacherAssignmentPresetLabel,
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: _textDec(),
                      items: _presets.map((raw) {
                        final p = Map<String, dynamic>.from(raw as Map);
                        final id = (p['id'] ?? p['_id'])?.toString() ?? '';
                        final name = (p['name'] as String?) ?? id;
                        return DropdownMenuItem(value: id, child: Text(name));
                      }).toList(),
                      onChanged: (id) {
                        if (id == null) return;
                        for (final raw in _presets) {
                          final p = Map<String, dynamic>.from(raw as Map);
                          final pid = (p['id'] ?? p['_id'])?.toString() ?? '';
                          if (pid == id && p['config'] is Map) {
                            _applyPreset(Map<String, dynamic>.from(p['config'] as Map));
                            break;
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _savePreset,
                    child: Text(l10n.teacherAssignmentPresetSave),
                  ),
                ],
              ),
            ),
          ],

          // ── Section: Rules (expandable) ──────────────────────────────
          const Padding(
            padding: EdgeInsets.only(top: 18, bottom: 4),
            child: Divider(height: 1, color: AppColors.outlineMuted),
          ),
          TeacherDialogExpandableSection(
            icon: Icons.tune_rounded,
            title: l10n.teacherAssignExamAdvancedRules,
            subtitle: l10n.teacherAssignExamAdvancedRulesHint,
            expandLabel: l10n.teacherAssignExamRulesShow,
            collapseLabel: l10n.teacherAssignExamRulesHide,
            child: _rulesPanel(l10n),
          ),
        ],
      ),
      footer: TeacherDialogFooterActions(
        cancelLabel: l10n.cancel,
        primaryLabel: l10n.teacherAssignmentCreate,
        primaryLoading: _submitting,
        onPrimary: _submit,
      ),
    );
  }
}

class _ModeOption {
  const _ModeOption({
    required this.value,
    required this.icon,
    required this.title,
    required this.hint,
  });

  final String value;
  final IconData icon;
  final String title;
  final String hint;
}
