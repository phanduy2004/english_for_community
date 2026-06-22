import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_dialog_shell.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_realtime_schedule_section.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_widgets.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/feature/teacher/teacher_grading_hub_labels.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Dialog to edit schedule, time limit and rules for an existing assignment.
///
/// Returns `true` when saved so the caller can reload the grading hub.
///
/// Design: `docs/ui-ux-system/14-teacher-dialogs.md` — form dialog, width 560.
class TeacherEditAssignmentDialog extends StatefulWidget {
  const TeacherEditAssignmentDialog({
    super.key,
    required this.assignmentId,
    required this.assignment,
  });

  final String assignmentId;

  /// Full assignment map from `state.assignment` (grading hub BLoC).
  final Map<String, dynamic> assignment;

  static Future<bool?> show(
    BuildContext context, {
    required String assignmentId,
    required Map<String, dynamic> assignment,
  }) =>
      TeacherDialogShell.show<bool>(
        context,
        child: TeacherEditAssignmentDialog(
          assignmentId: assignmentId,
          assignment: assignment,
        ),
      );

  @override
  State<TeacherEditAssignmentDialog> createState() =>
      _TeacherEditAssignmentDialogState();
}

class _TeacherEditAssignmentDialogState
    extends State<TeacherEditAssignmentDialog> {
  bool _saving = false;

  late String _mode;

  // Schedule fields — populated from assignment config
  DateTime? _dueAt;
  DateTime? _opensAt;
  DateTime? _closesAt;
  String _realtimeScheduleMode = 'manual';
  DateTime? _lobbyOpensAt;
  DateTime? _scheduledStartAt;

  final _timeLimitCtrl = TextEditingController();

  // Rules
  String _attemptPolicy = 'single';
  int _maxAttempts = 2;
  String _showResultsPolicy = 'after_release';
  String _resultsDetailLevel = 'full_detail';
  bool _allowPartialSubmit = true;

  static const _maxAttemptChoices = [2, 3, 5, 10];
  static const _timeLimitPresets = [30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _loadFromAssignment();
  }

  @override
  void dispose() {
    _timeLimitCtrl.dispose();
    super.dispose();
  }

  void _loadFromAssignment() {
    final a = widget.assignment;
    _mode = (a['mode'] as String?) ?? 'self_paced';
    final cfg = (a['config'] as Map?)?.cast<String, dynamic>() ?? {};

    _dueAt = _tryParseDate(cfg['dueAt']);
    _opensAt = _tryParseDate(cfg['opensAt']);
    _closesAt = _tryParseDate(cfg['closesAt']);
    _lobbyOpensAt = _tryParseDate(cfg['lobbyOpensAt']);
    _scheduledStartAt = _tryParseDate(cfg['scheduledStartAt']);
    final rsm = cfg['realtimeScheduleMode'] as String?;
    if (rsm == 'scheduled' || rsm == 'manual') {
      _realtimeScheduleMode = rsm!;
    } else {
      _realtimeScheduleMode = _scheduledStartAt != null ? 'scheduled' : 'manual';
    }

    final tls = cfg['timeLimitSeconds'];
    if (tls is num && tls > 0) {
      _timeLimitCtrl.text = (tls / 60).round().toString();
    }

    _attemptPolicy = (cfg['attemptPolicy'] as String?) ?? 'single';
    final ma = cfg['maxAttempts'];
    if (ma is num) _maxAttempts = ma.toInt().clamp(2, 10);
    _showResultsPolicy =
        (cfg['showResultsPolicy'] as String?) ?? 'after_release';
    final rd = cfg['resultsDetailLevel'] as String?;
    if (rd == 'score_only' || rd == 'full_detail') _resultsDetailLevel = rd!;
    _allowPartialSubmit = cfg['allowPartialSubmit'] != false;
  }

  DateTime? _tryParseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  String _fmtDateTime(DateTime? dt) {
    if (dt == null) return context.l10n.teacherAssignmentOptional;
    return DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .add_Hm()
        .format(dt.toLocal());
  }

  Future<void> _pickDateTime({
    required DateTime? current,
    required void Function(DateTime picked) onPicked,
    DateTime? firstDate,
  }) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate:
          firstDate ?? now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: current != null ? TimeOfDay.fromDateTime(current) : TimeOfDay.now(),
    );
    if (t == null || !mounted) return;
    onPicked(DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _save() async {
    final l10n = context.l10n;
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

    setState(() => _saving = true);

    final patchCfg = <String, dynamic>{};

    switch (_mode) {
      case 'self_paced':
        patchCfg['dueAt'] = _dueAt?.toUtc().toIso8601String();
      case 'scheduled':
        if (_opensAt != null) {
          patchCfg['opensAt'] = _opensAt!.toUtc().toIso8601String();
        }
        if (_closesAt != null) {
          patchCfg['closesAt'] = _closesAt!.toUtc().toIso8601String();
        }
      case 'realtime':
        patchCfg['realtimeScheduleMode'] = _realtimeScheduleMode;
        if (_realtimeScheduleMode == 'scheduled') {
          patchCfg['scheduledStartAt'] =
              _scheduledStartAt!.toUtc().toIso8601String();
          patchCfg['lobbyOpensAt'] = _lobbyOpensAt?.toUtc().toIso8601String();
        } else {
          patchCfg['scheduledStartAt'] = null;
          patchCfg['lobbyOpensAt'] = null;
        }
    }

    if (_mode != 'practice') {
      final mins = int.tryParse(_timeLimitCtrl.text.trim());
      patchCfg['timeLimitSeconds'] =
          (mins != null && mins > 0) ? mins * 60 : null;
    }

    patchCfg['attemptPolicy'] = _attemptPolicy;
    if (_attemptPolicy == 'limited') patchCfg['maxAttempts'] = _maxAttempts;
    patchCfg['showResultsPolicy'] = _showResultsPolicy;
    patchCfg['resultsDetailLevel'] = _resultsDetailLevel;
    patchCfg['allowPartialSubmit'] = _allowPartialSubmit;

    final result = await getIt<TeacherExamRepository>()
        .patchAssignment(widget.assignmentId, {'config': patchCfg});

    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (f) => AppCornerToast.show(context, f.message, error: true),
      (_) {
        AppCornerToast.show(context, context.l10n.teacherAssignmentEditSaved);
        Navigator.of(context).pop(true);
      },
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _formGroup({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TeacherWebUi.formFieldLabel(context, label),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required void Function(DateTime) onPicked,
    required VoidCallback onClear,
    bool optional = true,
    DateTime? firstDate,
  }) {
    return _formGroup(
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _pickDateTime(
            current: value,
            onPicked: (d) => setState(() => onPicked(d)),
            firstDate: firstDate,
          ),
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              border: Border.all(color: AppColors.outline),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Padding(
              padding: TeacherWebUi.formInputContentPadding,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _fmtDateTime(value),
                      style: TeacherWebUi.webBody(context).copyWith(
                        fontSize: 15,
                        height: 1.35,
                        color: value == null
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(Icons.calendar_today_outlined,
                      size: 18, color: AppColors.textMuted),
                  if (optional && value != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      color: AppColors.textMuted,
                      onPressed: onClear,
                      tooltip:
                          MaterialLocalizations.of(context).clearButtonTooltip,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
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

  Widget _timeLimitSection() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _formGroup(
          label: l10n.teacherAssignmentTimeLimitMinutes,
          child: TextField(
            controller: _timeLimitCtrl,
            keyboardType: TextInputType.number,
            style: TeacherWebUi.webBody(context)
                .copyWith(fontSize: 15, color: AppColors.textPrimary),
            decoration: TeacherWebUi.formInputDecoration(context,
                hintText: l10n.teacherAssignmentTimeLimitMinutesHint),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _timeLimitPresets.map((m) {
            final selected = _timeLimitCtrl.text.trim() == '$m';
            return FilterChip(
              label: Text(l10n.teacherAssignmentTimeLimitPresetMinutes(m)),
              selected: selected,
              onSelected: (_) =>
                  setState(() => _timeLimitCtrl.text = '$m'),
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          l10n.teacherAssignmentTimeLimitHelp,
          style: TeacherWebUi.metaMuted.copyWith(height: 1.45),
        ),
      ],
    );
  }

  Widget _segmented<T>({
    required T selected,
    required ValueChanged<T> onChanged,
    required List<TeacherSegmentOption<T>> options,
  }) {
    return TeacherSegmentTileRow<T>(
      selected: selected,
      onChanged: onChanged,
      options: options,
    );
  }

  Widget _rulesSection() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _formGroup(
          label: l10n.teacherAssignmentAttemptPolicy,
          child: _segmented<String>(
            selected: _attemptPolicy,
            onChanged: (v) => setState(() => _attemptPolicy = v),
            options: [
              TeacherSegmentOption(
                value: 'single',
                label: l10n.teacherAssignmentAttemptSingle,
                icon: Icons.looks_one_outlined,
              ),
              TeacherSegmentOption(
                value: 'unlimited',
                label: l10n.teacherAssignmentAttemptUnlimited,
                icon: Icons.all_inclusive_rounded,
              ),
              TeacherSegmentOption(
                value: 'limited',
                label: l10n.teacherAssignmentAttemptLimited,
                icon: Icons.format_list_numbered_rounded,
              ),
            ],
          ),
        ),
        if (_attemptPolicy == 'limited') ...[
          const SizedBox(height: AppSpacing.s5),
          _formGroup(
            label: l10n.teacherAssignmentMaxAttempts,
            child: DropdownButtonFormField<int>(
              initialValue: _maxAttempts,
              isExpanded: true,
              decoration: TeacherWebUi.formInputDecoration(context),
              icon: const Icon(Icons.expand_more_rounded,
                  color: AppColors.textMuted),
              items: _maxAttemptChoices
                  .map((n) =>
                      DropdownMenuItem(value: n, child: Text('$n')))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _maxAttempts = v);
              },
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s5),
        _formGroup(
          label: l10n.teacherAssignmentShowResults,
          child: DropdownButtonFormField<String>(
            initialValue: _showResultsPolicy,
            isExpanded: true,
            decoration: TeacherWebUi.formInputDecoration(context),
            icon: const Icon(Icons.expand_more_rounded,
                color: AppColors.textMuted),
            items: [
              DropdownMenuItem(
                  value: 'after_submit',
                  child: Text(l10n.teacherExamPolicyAfterSubmit)),
              DropdownMenuItem(
                  value: 'after_release',
                  child: Text(l10n.teacherExamPolicyAfterRelease)),
              DropdownMenuItem(
                  value: 'never',
                  child: Text(l10n.teacherExamPolicyNever)),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _showResultsPolicy = v);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.s5),
        _formGroup(
          label: l10n.teacherAssignmentResultsDetailLabel,
          child: DropdownButtonFormField<String>(
            key: ValueKey(_resultsDetailLevel),
            initialValue: _resultsDetailLevel,
            isExpanded: true,
            decoration: TeacherWebUi.formInputDecoration(context),
            icon: const Icon(Icons.expand_more_rounded, color: AppColors.textMuted),
            items: [
              DropdownMenuItem(
                value: 'score_only',
                child: Text(l10n.teacherResultsDetailScoreOnly),
              ),
              DropdownMenuItem(
                value: 'full_detail',
                child: Text(l10n.teacherResultsDetailFull),
              ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _resultsDetailLevel = v);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.s5),
        Container(
          padding: const EdgeInsets.only(top: AppSpacing.s3),
          decoration: const BoxDecoration(
            border: Border(
                top: BorderSide(color: AppColors.outlineMuted)),
          ),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.teacherAssignmentAllowPartialSubmit,
              style: TeacherWebUi.webBody(context)
                  .copyWith(fontWeight: FontWeight.w500),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: Text(
                l10n.teacherAssignmentAllowPartialSubmitHint,
                style: TeacherWebUi.metaMuted.copyWith(height: 1.45),
              ),
            ),
            value: _allowPartialSubmit,
            onChanged: (v) => setState(() => _allowPartialSubmit = v),
          ),
        ),
      ],
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final modeLabel =
        TeacherGradingHubLabels.modeLabel(l10n, _mode);
    final formatLabel = TeacherGradingHubLabels.examFormatLabel(
        l10n, widget.assignment['examFormat'] as String?);

    return TeacherDialogShell(
      title: l10n.teacherAssignmentEditTitle,
      subtitle: l10n.teacherAssignmentEditSubtitle,
      icon: Icons.edit_calendar_outlined,
      width: 560,
      maxBodyHeight: 520,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Mode context (read-only) ────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ModeChip(label: modeLabel),
              if (formatLabel != null) _ModeChip(label: formatLabel),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.teacherAssignmentModeFixed,
            style: TeacherWebUi.metaMuted,
          ),
          const SizedBox(height: AppSpacing.s5),
          const Divider(height: 1, color: AppColors.outlineMuted),
          const SizedBox(height: AppSpacing.s5),

          // ── Schedule ───────────────────────────────────────────────────
          TeacherDialogSectionLabel(
              l10n.teacherAssignmentEditScheduleSection),

          if (_mode == 'self_paced') ...[
            _dateField(
              label: l10n.teacherAssignmentDueDate,
              value: _dueAt,
              onPicked: (d) => _dueAt = d,
              onClear: () => setState(() => _dueAt = null),
              optional: true,
            ),
            const SizedBox(height: AppSpacing.s5),
          ],

          if (_mode == 'scheduled') ...[
            _dateField(
              label: l10n.teacherAssignmentOpensAt,
              value: _opensAt,
              onPicked: (d) => _opensAt = d,
              onClear: () => setState(() => _opensAt = null),
              optional: false,
            ),
            const SizedBox(height: AppSpacing.s5),
            _dateField(
              label: l10n.teacherAssignmentClosesAt,
              value: _closesAt,
              onPicked: (d) => _closesAt = d,
              onClear: () => setState(() => _closesAt = null),
              optional: false,
            ),
            const SizedBox(height: AppSpacing.s5),
          ],

          if (_mode == 'realtime') ...[
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
              onScheduledStartChanged: (d) =>
                  setState(() => _scheduledStartAt = d),
              onLobbyOpensChanged: (d) => setState(() => _lobbyOpensAt = d),
              formatDateTime: _fmtDateTime,
              onPickDateTime: ({
                required initial,
                required onPicked,
                firstDate,
              }) =>
                  _pickDateTime(
                    current: initial,
                    onPicked: (d) => setState(() => onPicked(d)),
                    firstDate: firstDate,
                  ),
            ),
            const SizedBox(height: AppSpacing.s5),
          ],

          if (_mode != 'practice') ...[
            _timeLimitSection(),
            const SizedBox(height: AppSpacing.s5),
          ],

          if (_mode == 'practice') ...[
            Text(
              l10n.teacherAssignmentEditPracticeNote,
              style: TeacherWebUi.metaMuted.copyWith(height: 1.45),
            ),
            const SizedBox(height: AppSpacing.s5),
          ],

          const Divider(height: 1, color: AppColors.outlineMuted),
          const SizedBox(height: AppSpacing.s5),

          // ── Attempts & Results ─────────────────────────────────────────
          TeacherDialogSectionLabel(
              l10n.teacherAssignmentEditRulesSection),
          _rulesSection(),
          const SizedBox(height: AppSpacing.s2),
        ],
      ),
      footer: TeacherDialogFooterActions(
        cancelLabel: l10n.cancel,
        primaryLabel: l10n.save,
        primaryLoading: _saving,
        onPrimary: _save,
      ),
    );
  }
}

/// Read-only mode/format badge inside the dialog.
class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline),
      ),
      child: Text(
        label,
        style: TeacherWebUi.webLabel(context).copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
