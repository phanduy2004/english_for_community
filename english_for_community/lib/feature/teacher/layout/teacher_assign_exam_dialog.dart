import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_corner_toast.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_dialog_shell.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  DateTime? _publicExpiresAt;
  final _timeLimitMinutes = TextEditingController();
  final _publicMaxUses = TextEditingController();
  bool _allowPartialSubmit = true;
  String _attemptPolicy = 'single';
  int _maxAttempts = 2;
  String _showResultsPolicy = 'after_release';
  List<dynamic> _presets = [];

  static const _maxAttemptChoices = [2, 3, 5, 10];

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
          if (id == wanted) {
            pickId = id;
            break;
          }
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
      'allowPartialSubmit': _allowPartialSubmit,
    };
    _applyTimeLimitToConfig(presetCfg);
    final r = await getIt<TeacherExamRepository>().createAssignmentPreset({
      'name': name,
      'config': presetCfg,
    });
    if (!mounted) return;
    r.fold(
      (f) => TeacherCornerToast.show(context, f.message, error: true),
      (_) {
        TeacherCornerToast.show(context, l10n.teacherAssignmentPresetSaved);
        _bootstrap();
      },
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_examStatus != 'published') {
      TeacherCornerToast.show(context, l10n.teacherAssignmentExamNotPublished, error: true);
      return;
    }
    if (_audience == 'classroom' && (_classroomId == null || _classroomId!.isEmpty)) {
      TeacherCornerToast.show(context, l10n.teacherAssignmentPickClass, error: true);
      return;
    }
    setState(() => _submitting = true);
    final config = <String, dynamic>{
      'allowPartialSubmit': _allowPartialSubmit,
      'partialSubmitConfirm': true,
      'attemptPolicy': _attemptPolicy,
      'showResultsPolicy': _showResultsPolicy,
      if (_attemptPolicy == 'limited') 'maxAttempts': _maxAttempts,
    };
    if (_mode == 'self_paced' && _dueAt != null) {
      config['dueAt'] = _dueAt!.toUtc().toIso8601String();
    }
    if (_mode == 'scheduled') {
      if (_opensAt != null) config['opensAt'] = _opensAt!.toUtc().toIso8601String();
      if (_closesAt != null) config['closesAt'] = _closesAt!.toUtc().toIso8601String();
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
      (f) => TeacherCornerToast.show(context, f.message, error: true),
      (d) async {
        TeacherCornerToast.show(context, l10n.teacherAssignmentCreated);
        if (_audience == 'public_link' && d is Map) {
          final pj = d['publicJoin'];
          if (pj is Map && (pj['token'] as String?)?.isNotEmpty == true) {
            final tok = pj['token'] as String;
            await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.teacherAssignmentPublicTokenTitle),
                content: SelectableText('${l10n.teacherAssignmentPublicTokenBody}\n\n$tok'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: tok));
                      Navigator.pop(ctx);
                      TeacherCornerToast.show(context, l10n.dashboardPublicTokenCopied);
                    },
                    child: Text(l10n.dashboardPublicCopyToken),
                  ),
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

  Future<void> _pickDateTime(void Function(DateTime) onPicked, {DateTime? initial}) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
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
        final wide = c.maxWidth >= 400;
        return GridView.count(
          crossAxisCount: wide ? 2 : 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: wide ? 2.4 : 3.2,
          children: options.map((o) {
            final selected = _mode == o.value;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _mode = o.value),
                borderRadius: BorderRadius.circular(10),
                child: Ink(
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryTint : AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.outlineMuted,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(o.icon, size: 18, color: selected ? AppColors.primaryDark : AppColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.title,
                              style: TeacherWebUi.webLabel(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: selected ? AppColors.primaryDark : AppColors.textPrimary,
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
                        const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _scheduleBlock(AppLocalizations l10n) {
    if (_mode == 'practice') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.outlineMuted),
        ),
        child: Text(
          l10n.teacherAssignExamModeHintPractice,
          style: TeacherWebUi.metaMuted.copyWith(height: 1.4),
        ),
      );
    }

    if (_mode == 'realtime') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.infoBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, size: 18, color: AppColors.info),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.teacherAssignExamRealtimeNote,
                style: TeacherWebUi.webBody(context).copyWith(fontSize: 12, height: 1.45),
              ),
            ),
          ],
        ),
      );
    }

    final children = <Widget>[];
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
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [30, 45, 60, 90, 120].map((m) {
            return FilterChip(
              label: Text(l10n.teacherAssignmentTimeLimitPresetMinutes(m), style: const TextStyle(fontSize: 11)),
              selected: _timeLimitMinutes.text.trim() == '$m',
              onSelected: (_) => setState(() => _timeLimitMinutes.text = '$m'),
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            );
          }).toList(),
        ),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _rulesPanel(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'single', label: Text(l10n.teacherAssignmentAttemptSingle)),
            ButtonSegment(value: 'unlimited', label: Text(l10n.teacherAssignmentAttemptUnlimited)),
            ButtonSegment(value: 'limited', label: Text(l10n.teacherAssignmentAttemptLimited)),
          ],
          selected: {_attemptPolicy},
          onSelectionChanged: (s) {
            if (s.isEmpty) return;
            setState(() => _attemptPolicy = s.first);
          },
          showSelectedIcon: false,
          style: TeacherWebUi.segmentedControlStyle(context),
        ),
        if (_attemptPolicy == 'limited') ...[
          const SizedBox(height: AppSpacing.s4),
          _formGroup(
            label: l10n.teacherAssignmentMaxAttempts,
            child: DropdownButtonFormField<int>(
              value: _maxAttempts,
              isExpanded: true,
              decoration: _textDec(),
              items: _maxAttemptChoices.map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _maxAttempts = v);
              },
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s4),
        _formGroup(
          label: l10n.teacherAssignmentShowResults,
          child: DropdownButtonFormField<String>(
            value: _showResultsPolicy,
            isExpanded: true,
            decoration: _textDec(),
            items: [
              DropdownMenuItem(value: 'after_submit', child: Text(l10n.teacherExamPolicyAfterSubmit)),
              DropdownMenuItem(value: 'after_release', child: Text(l10n.teacherExamPolicyAfterRelease)),
              DropdownMenuItem(value: 'never', child: Text(l10n.teacherExamPolicyNever)),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _showResultsPolicy = v);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.outlineMuted),
          ),
          child: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text(
              l10n.teacherAssignmentAllowPartialSubmit,
              style: TeacherWebUi.webBody(context).copyWith(fontWeight: FontWeight.w500, fontSize: 13),
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
        body: const Center(child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(strokeWidth: 2),
        )),
      );
    }

    return TeacherDialogShell(
      title: l10n.teacherAssignmentWizardTitle,
      subtitle: subtitle,
      icon: Icons.assignment_add,
      width: 560,
      maxBodyHeight: 520,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_examStatus != 'published')
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.s5),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
              ),
              child: Text(
                l10n.teacherAssignmentExamNotPublished,
                style: TeacherWebUi.webBody(context).copyWith(color: AppColors.warning, fontSize: 13),
              ),
            ),
          TeacherDialogSectionLabel(l10n.teacherAssignmentSectionAudience),
          const SizedBox(height: AppSpacing.s3),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'classroom', label: Text(l10n.teacherAssignmentAudienceClassroom)),
              ButtonSegment(value: 'public_link', label: Text(l10n.teacherAssignmentAudiencePublic)),
            ],
            selected: {_audience},
            onSelectionChanged: (s) {
              if (s.isEmpty) return;
              setState(() => _audience = s.first);
            },
            showSelectedIcon: false,
            style: TeacherWebUi.segmentedControlStyle(context),
          ),
          const SizedBox(height: AppSpacing.s4),
          if (_audience == 'classroom')
            _formGroup(
              label: l10n.teacherAssignmentClassroom,
              child: DropdownButtonFormField<String>(
                value: _classrooms.isEmpty ? null : _classroomId,
                isExpanded: true,
                decoration: _textDec(),
                items: _classrooms.map((raw) {
                  final m = Map<String, dynamic>.from(raw as Map);
                  final id = (m['id'] ?? m['_id'])?.toString() ?? '';
                  final name = (m['name'] as String?) ?? id;
                  return DropdownMenuItem(value: id, child: Text(name));
                }).toList(),
                onChanged: (v) => setState(() => _classroomId = v),
              ),
            )
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
              onTap: () => _pickDateTime((d) => setState(() => _publicExpiresAt = d), initial: _publicExpiresAt),
              onClear: () => setState(() => _publicExpiresAt = null),
            ),
          ],
          const SizedBox(height: AppSpacing.s5),
          const Divider(height: 1, color: AppColors.outlineMuted),
          const SizedBox(height: AppSpacing.s5),
          TeacherDialogSectionLabel(l10n.teacherAssignmentSectionDelivery),
          const SizedBox(height: AppSpacing.s3),
          _modeGrid(l10n),
          const SizedBox(height: AppSpacing.s4),
          _scheduleBlock(l10n),
          if (_presets.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s4),
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
          const SizedBox(height: AppSpacing.s4),
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
