import 'dart:math' as math;

import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Side / full-screen form: builds one `grammarItems[]` entry for skills exam.
class TeacherSkillsExamGrammarEditorPanel extends StatefulWidget {
  const TeacherSkillsExamGrammarEditorPanel({
    super.key,
    this.initial,
    required this.onSave,
    required this.onClose,
  });

  /// Full item map when editing; null when creating new.
  final Map<String, dynamic>? initial;
  final ValueChanged<Map<String, dynamic>> onSave;
  final VoidCallback onClose;

  @override
  State<TeacherSkillsExamGrammarEditorPanel> createState() => _TeacherSkillsExamGrammarEditorPanelState();
}

class _GrammarKindOption {
  const _GrammarKindOption({
    required this.kind,
    required this.icon,
    required this.label,
  });

  final String kind;
  final IconData icon;
  final String label;
}

class _TeacherSkillsExamGrammarEditorPanelState extends State<TeacherSkillsExamGrammarEditorPanel> {
  late String _kind;
  late final TextEditingController _points = TextEditingController(text: '1');
  late final TextEditingController _prompt = TextEditingController();
  final List<TextEditingController> _mcqOptions = [];

  late final TextEditingController _clozePassage = TextEditingController();
  final Map<String, TextEditingController> _clozeAccepted = {};

  late final TextEditingController _gapBefore = TextEditingController();
  late final TextEditingController _gapAfter = TextEditingController();
  late final TextEditingController _gapAccepted = TextEditingController();

  final List<TextEditingController> _matchLeft = [];
  final List<TextEditingController> _matchRight = [];
  List<int> _matchPick = [0, 1, 2];

  late final TextEditingController _reorderLines = TextEditingController();
  List<int> _reorderCorrectPerm = [0, 1];

  final Set<int> _mcqCorrect = {};

  List<_GrammarKindOption> _kindOptions(AppLocalizations l10n) => [
        _GrammarKindOption(kind: 'mcq_single', icon: Icons.radio_button_checked_outlined, label: l10n.teacherExamGrammarKindMcqSingle),
        _GrammarKindOption(kind: 'mcq_multi', icon: Icons.check_box_outlined, label: l10n.teacherExamGrammarKindMcqMulti),
        _GrammarKindOption(kind: 'grammar_cloze', icon: Icons.notes_outlined, label: l10n.teacherExamGrammarKindCloze),
        _GrammarKindOption(kind: 'grammar_gap', icon: Icons.space_bar_outlined, label: l10n.teacherExamGrammarKindGap),
        _GrammarKindOption(kind: 'grammar_matching', icon: Icons.swap_horiz_outlined, label: l10n.teacherExamGrammarKindMatching),
        _GrammarKindOption(kind: 'grammar_reorder', icon: Icons.reorder_outlined, label: l10n.teacherExamGrammarKindReorder),
      ];

  @override
  void initState() {
    super.initState();
    final it = widget.initial;
    _kind = '${it?['kind'] ?? 'mcq_single'}';
    _points.text = '${it?['points'] ?? 1}';
    _prompt.text = '${it?['prompt'] ?? ''}';

    if (it != null) {
      _hydrateFrom(it);
    } else {
      _kind = 'mcq_single';
      for (var i = 0; i < 4; i++) {
        _mcqOptions.add(TextEditingController());
      }
      _mcqCorrect.add(0);
      _matchLeft.addAll(List.generate(3, (_) => TextEditingController()));
      _matchRight.addAll(List.generate(3, (_) => TextEditingController()));
      _matchPick = List.generate(3, (i) => i);
      _reorderLines.text = 'First part.\nSecond part.';
      _reorderCorrectPerm = [0, 1];
    }
  }

  void _hydrateFrom(Map<String, dynamic> it) {
    final k = '${it['kind']}';
    if (k == 'mcq_single' || k == 'mcq_multi') {
      final opts = (it['options'] as List?)?.map((e) => '$e').toList() ?? [];
      for (final c in _mcqOptions) {
        c.dispose();
      }
      _mcqOptions.clear();
      for (final o in opts.isEmpty ? ['', ''] : opts) {
        _mcqOptions.add(TextEditingController(text: o));
      }
      _mcqCorrect.clear();
      final cor = (it['correctOptionIndexes'] as List?)?.map((e) => int.tryParse('$e') ?? 0) ?? [0];
      _mcqCorrect.addAll(cor);
      return;
    }
    if (k == 'grammar_cloze') {
      _clozePassage.text = '${it['passage'] ?? ''}';
      _syncClozeBlankFields();
      final blanks = it['blanks'] as List? ?? [];
      for (final b in blanks) {
        if (b is! Map) continue;
        final id = '${b['blankId']}';
        final acc = (b['acceptedAnswers'] as List?)?.map((e) => '$e').join(', ') ?? '';
        _clozeAccepted[id]?.text = acc;
      }
      return;
    }
    if (k == 'grammar_gap') {
      _gapBefore.text = '${it['textBefore'] ?? ''}';
      _gapAfter.text = '${it['textAfter'] ?? ''}';
      final blanks = it['blanks'] as List? ?? [];
      if (blanks.isNotEmpty && blanks.first is Map) {
        final acc = (blanks.first['acceptedAnswers'] as List?)?.map((e) => '$e').join(', ') ?? '';
        _gapAccepted.text = acc;
      }
      return;
    }
    if (k == 'grammar_matching') {
      for (final c in _matchLeft) {
        c.dispose();
      }
      for (final c in _matchRight) {
        c.dispose();
      }
      _matchLeft.clear();
      _matchRight.clear();
      final left = (it['leftItems'] ?? it['leftColumn']) as List? ?? [];
      final right = (it['rightItems'] ?? it['rightColumn']) as List? ?? [];
      final n = math.max(left.length, right.length);
      for (var i = 0; i < n; i++) {
        _matchLeft.add(TextEditingController(text: i < left.length && left[i] is Map ? '${(left[i] as Map)['text'] ?? ''}' : ''));
        _matchRight.add(TextEditingController(text: i < right.length && right[i] is Map ? '${(right[i] as Map)['text'] ?? ''}' : ''));
      }
      if (_matchLeft.isEmpty) {
        _matchLeft.addAll(List.generate(3, (_) => TextEditingController()));
        _matchRight.addAll(List.generate(3, (_) => TextEditingController()));
      }
      _matchPick = List.generate(_matchLeft.length, (i) => i);
      final pairs = it['correctPairs'] as List? ?? [];
      final ridToIdx = <String, int>{};
      for (var j = 0; j < right.length; j++) {
        if (right[j] is Map) ridToIdx['${(right[j] as Map)['id']}'] = j;
      }
      for (var i = 0; i < pairs.length && i < _matchPick.length; i++) {
        final p = pairs[i];
        if (p is List && p.length == 2) {
          final ri = ridToIdx['${p[1]}'];
          if (ri != null) _matchPick[i] = ri;
        }
      }
      return;
    }
    if (k == 'grammar_reorder') {
      final fr = (it['fragments'] as List?)?.map((e) => '$e').toList() ?? [];
      _reorderLines.text = fr.join('\n');
      final cor = (it['correctOrder'] as List?)?.map((e) => int.tryParse('$e') ?? 0).toList() ?? [];
      _reorderCorrectPerm = cor.isEmpty ? List.generate(fr.length, (i) => i) : cor;
    }
  }

  void _syncClozeBlankFields() {
    final reg = RegExp(r'\{\{([0-9]+)\}\}');
    final ids = reg.allMatches(_clozePassage.text).map((m) => m.group(1) ?? '0').toSet();
    for (final k in _clozeAccepted.keys.toList()) {
      if (!ids.contains(k)) {
        _clozeAccepted.remove(k)?.dispose();
      }
    }
    for (final id in ids) {
      _clozeAccepted.putIfAbsent(id, () => TextEditingController());
    }
  }

  @override
  void dispose() {
    _points.dispose();
    _prompt.dispose();
    for (final c in _mcqOptions) {
      c.dispose();
    }
    _clozePassage.dispose();
    for (final c in _clozeAccepted.values) {
      c.dispose();
    }
    _gapBefore.dispose();
    _gapAfter.dispose();
    _gapAccepted.dispose();
    for (final c in _matchLeft) {
      c.dispose();
    }
    for (final c in _matchRight) {
      c.dispose();
    }
    _reorderLines.dispose();
    super.dispose();
  }

  List<String> _splitAccepted(String raw) {
    return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  String _optionLetter(int index) => String.fromCharCode(65 + index);

  void _onSavePressed() {
    final l10n = context.l10n;
    final pts = int.tryParse(_points.text.trim()) ?? 1;
    final id = widget.initial?['itemId'] as String? ?? 'gram_${DateTime.now().millisecondsSinceEpoch}';

    Map<String, dynamic>? out;
    switch (_kind) {
      case 'mcq_single':
      case 'mcq_multi':
        final opts = _mcqOptions.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
        final stem = _prompt.text.trim();
        if (stem.isEmpty || opts.length < 2) {
          AppCornerToast.show(context, l10n.teacherExamMcqNeedsStem, error: true);
          return;
        }
        if (_mcqCorrect.isEmpty) {
          AppCornerToast.show(context, l10n.teacherExamGrammarCorrectOptions, error: true);
          return;
        }
        if (_kind == 'mcq_single' && _mcqCorrect.length != 1) {
          AppCornerToast.show(context, l10n.teacherExamGrammarCorrectOptions, error: true);
          return;
        }
        out = {
          'itemId': id,
          'kind': _kind,
          'prompt': stem,
          'options': opts,
          'correctOptionIndexes': (_mcqCorrect.toList()..sort()),
          'points': pts,
        };
        break;
      case 'grammar_cloze':
        _syncClozeBlankFields();
        final passage = _clozePassage.text.trim();
        if (!RegExp(r'\{\{[0-9]+\}\}').hasMatch(passage)) {
          AppCornerToast.show(context, l10n.teacherExamGrammarPassageLabel, error: true);
          return;
        }
        final blanks = <Map<String, dynamic>>[];
        for (final e in _clozeAccepted.entries) {
          final acc = _splitAccepted(e.value.text);
          if (acc.isEmpty) {
            AppCornerToast.show(context, l10n.teacherExamGrammarAcceptedAnswers, error: true);
            return;
          }
          blanks.add({'blankId': e.key, 'acceptedAnswers': acc});
        }
        if (blanks.isEmpty) {
          AppCornerToast.show(context, l10n.teacherExamGrammarPassageLabel, error: true);
          return;
        }
        out = {
          'itemId': id,
          'kind': 'grammar_cloze',
          'passage': passage,
          'blanks': blanks,
          'points': pts,
        };
        break;
      case 'grammar_gap':
        final acc = _splitAccepted(_gapAccepted.text);
        if (_gapBefore.text.trim().isEmpty || _gapAfter.text.trim().isEmpty || acc.isEmpty) {
          AppCornerToast.show(context, l10n.teacherExamPublishNeedItems, error: true);
          return;
        }
        out = {
          'itemId': id,
          'kind': 'grammar_gap',
          'textBefore': _gapBefore.text.trim(),
          'textAfter': _gapAfter.text.trim(),
          'blanks': [
            {'blankId': '0', 'acceptedAnswers': acc},
          ],
          'points': pts,
        };
        break;
      case 'grammar_matching':
        final n = _matchLeft.length;
        if (n < 2) {
          AppCornerToast.show(context, l10n.teacherExamPublishNeedItems, error: true);
          return;
        }
        final leftItems = <Map<String, dynamic>>[];
        final rightItems = <Map<String, dynamic>>[];
        for (var i = 0; i < n; i++) {
          final lt = _matchLeft[i].text.trim();
          final rt = _matchRight[i].text.trim();
          if (lt.isEmpty || rt.isEmpty) {
            AppCornerToast.show(context, l10n.teacherExamPublishNeedItems, error: true);
            return;
          }
          leftItems.add({'id': 'l$i', 'text': lt});
          rightItems.add({'id': 'r$i', 'text': rt});
        }
        final pairs = <List<String>>[];
        for (var i = 0; i < n; i++) {
          final j = _matchPick[i].clamp(0, n - 1);
          pairs.add(['l$i', 'r$j']);
        }
        out = {
          'itemId': id,
          'kind': 'grammar_matching',
          'leftItems': leftItems,
          'rightItems': rightItems,
          'correctPairs': pairs,
          'points': pts,
        };
        break;
      case 'grammar_reorder':
        final lines = _reorderLines.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        if (lines.length < 2) {
          AppCornerToast.show(context, l10n.teacherExamPublishNeedItems, error: true);
          return;
        }
        if (_reorderCorrectPerm.length != lines.length) {
          AppCornerToast.show(context, l10n.teacherExamGrammarReorderInstruction, error: true);
          return;
        }
        final sorted = [..._reorderCorrectPerm]..sort();
        for (var i = 0; i < lines.length; i++) {
          if (sorted[i] != i) {
            AppCornerToast.show(context, l10n.teacherExamGrammarReorderInstruction, error: true);
            return;
          }
        }
        out = {
          'itemId': id,
          'kind': 'grammar_reorder',
          'fragments': lines,
          'correctOrder': _reorderCorrectPerm,
          'points': pts,
        };
        break;
    }

    if (out != null) widget.onSave(out);
  }

  void _setKind(String k) {
    setState(() {
      _kind = k;
      if ((k == 'mcq_single' || k == 'mcq_multi') && _mcqOptions.isEmpty) {
        for (var i = 0; i < 4; i++) {
          _mcqOptions.add(TextEditingController());
        }
        _mcqCorrect
          ..clear()
          ..add(0);
      }
      if (k == 'grammar_matching' && _matchLeft.isEmpty) {
        _matchLeft.addAll(List.generate(3, (_) => TextEditingController()));
        _matchRight.addAll(List.generate(3, (_) => TextEditingController()));
        _matchPick = List.generate(3, (i) => i);
      }
      if (k == 'grammar_reorder') {
        final lines = _reorderLines.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        _reorderCorrectPerm = List.generate(math.max(2, lines.length), (i) => i);
      }
    });
  }

  Widget _formField(BuildContext context, {required String label, required Widget field, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TeacherWebUi.formFieldLabel(context, label),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(hint, style: TeacherWebUi.metaMuted),
        ],
        const SizedBox(height: AppSpacing.s1),
        field,
      ],
    );
  }

  Widget _textField(
    BuildContext context, {
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: TeacherWebUi.webBody(context),
      decoration: TeacherWebUi.formInputDecoration(context, hintText: hint),
    );
  }

  Widget _buildKindPicker(BuildContext context, AppLocalizations l10n) {
    final options = _kindOptions(l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _formField(
          context,
          label: l10n.teacherExamGrammarQuestionType,
          field: DropdownButtonFormField<String>(
            key: ValueKey(_kind),
            initialValue: _kind,
            isExpanded: true,
            isDense: true,
            decoration: TeacherWebUi.formInputDecoration(context),
            style: TeacherWebUi.webBody(context),
            icon: const Icon(Icons.expand_more_rounded, color: AppColors.textMuted),
            menuMaxHeight: 280,
            borderRadius: BorderRadius.circular(10),
            dropdownColor: AppColors.surfaceCard,
            selectedItemBuilder: (ctx) => [
              for (final opt in options)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    opt.label,
                    style: TeacherWebUi.webBody(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            items: [
              for (final opt in options)
                DropdownMenuItem(
                  value: opt.kind,
                  child: Row(
                    children: [
                      Icon(opt.icon, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.s2),
                      Expanded(
                        child: Text(
                          opt.label,
                          style: TeacherWebUi.webBody(context),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            onChanged: (v) {
              if (v != null) _setKind(v);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        SizedBox(
          width: 88,
          child: _formField(
            context,
            label: l10n.teacherExamPoints,
            field: _textField(context, controller: _points, keyboardType: TextInputType.number),
          ),
        ),
      ],
    );
  }

  Widget _optionLetterBadge(BuildContext context, int index) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.outlineMuted),
      ),
      child: Text(
        _optionLetter(index),
        style: TeacherWebUi.webCaption(context).copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _compactAddButton(BuildContext context, {required String label, required VoidCallback onPressed}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        style: TeacherWebUi.compactOutlinedStyle(context),
        onPressed: onPressed,
        icon: const Icon(Icons.add_outlined, size: 16),
        label: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: AppColors.surfaceCard,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s3, AppSpacing.s2, AppSpacing.s2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.initial == null ? l10n.teacherExamGrammarNewItem : l10n.teacherExamGrammarPanelTitle,
                      style: TeacherWebUi.webH3(context),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    style: TeacherWebUi.compactHeaderIconStyle(),
                    icon: const Icon(Icons.close_outlined, size: 18),
                    color: AppColors.textSecondary,
                    tooltip: l10n.teacherExamGrammarCloseEditor,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.outlineMuted),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s4, AppSpacing.s4, AppSpacing.s6),
                children: [
                  _buildKindPicker(context, l10n),
                  const SizedBox(height: AppSpacing.s5),
                  if (_kind == 'mcq_single' || _kind == 'mcq_multi') ..._buildMcq(context, l10n),
                  if (_kind == 'grammar_cloze') ..._buildCloze(context, l10n),
                  if (_kind == 'grammar_gap') ..._buildGap(context, l10n),
                  if (_kind == 'grammar_matching') ..._buildMatch(context, l10n),
                  if (_kind == 'grammar_reorder') ..._buildReorder(context, l10n),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.outlineMuted),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s3, AppSpacing.s4, AppSpacing.s4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  style: TeacherWebUi.compactFilledStyle(context),
                  onPressed: _onSavePressed,
                  child: Text(l10n.teacherExamGrammarSaveItem),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMcq(BuildContext context, AppLocalizations l10n) {
    final isMulti = _kind == 'mcq_multi';
    return [
      _formField(
        context,
        label: l10n.teacherExamStemLabel,
        field: _textField(context, controller: _prompt, maxLines: 3),
      ),
      const SizedBox(height: AppSpacing.s3),
      Text(
        l10n.teacherExamOptionsHint,
        style: TeacherWebUi.sectionTitle(context),
      ),
      const SizedBox(height: AppSpacing.s2),
      if (isMulti)
        for (var i = 0; i < _mcqOptions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 36,
                  child: Checkbox(
                    value: _mcqCorrect.contains(i),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _mcqCorrect.add(i);
                      } else {
                        _mcqCorrect.remove(i);
                      }
                    }),
                  ),
                ),
                _optionLetterBadge(context, i),
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: _textField(
                    context,
                    controller: _mcqOptions[i],
                    hint: '${l10n.teacherExamOptionsHint} ${_optionLetter(i)}',
                  ),
                ),
              ],
            ),
          )
      else
        RadioGroup<int>(
          groupValue: _mcqCorrect.isEmpty ? null : _mcqCorrect.first,
          onChanged: (v) => setState(() {
            _mcqCorrect
              ..clear()
              ..add(v ?? 0);
          }),
          child: Column(
            children: [
              for (var i = 0; i < _mcqOptions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 36,
                        child: Radio<int>(
                          value: i,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      _optionLetterBadge(context, i),
                      const SizedBox(width: AppSpacing.s2),
                      Expanded(
                        child: _textField(
                          context,
                          controller: _mcqOptions[i],
                          hint: '${l10n.teacherExamOptionsHint} ${_optionLetter(i)}',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      const SizedBox(height: AppSpacing.s1),
      _compactAddButton(
        context,
        label: l10n.teacherExamGrammarAddOption,
        onPressed: () => setState(() => _mcqOptions.add(TextEditingController())),
      ),
    ];
  }

  List<Widget> _buildCloze(BuildContext context, AppLocalizations l10n) {
    return [
      _formField(
        context,
        label: l10n.teacherExamGrammarPassageLabel,
        field: _textField(
          context,
          controller: _clozePassage,
          maxLines: 6,
          onChanged: (_) => setState(_syncClozeBlankFields),
        ),
      ),
      if (_clozeAccepted.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.s4),
        Text(l10n.teacherExamGrammarAcceptedAnswers, style: TeacherWebUi.sectionTitle(context)),
        const SizedBox(height: AppSpacing.s2),
        for (final e in _clozeAccepted.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s2),
            child: _formField(
              context,
              label: '${l10n.teacherExamGrammarBlankId} ${e.key}',
              field: _textField(context, controller: e.value),
            ),
          ),
      ],
    ];
  }

  List<Widget> _buildGap(BuildContext context, AppLocalizations l10n) {
    return [
      _formField(
        context,
        label: l10n.teacherExamGrammarTextBefore,
        field: _textField(context, controller: _gapBefore),
      ),
      const SizedBox(height: AppSpacing.s3),
      _formField(
        context,
        label: l10n.teacherExamGrammarTextAfter,
        field: _textField(context, controller: _gapAfter),
      ),
      const SizedBox(height: AppSpacing.s3),
      _formField(
        context,
        label: l10n.teacherExamGrammarAcceptedAnswers,
        field: _textField(context, controller: _gapAccepted),
      ),
    ];
  }

  Widget _matchPickMenu(BuildContext context, AppLocalizations l10n, int rowIndex) {
    final pick = _matchPick[rowIndex].clamp(0, _matchLeft.length - 1);
    final label = '${l10n.teacherExamGrammarRightColumn} ${pick + 1}';
    return PopupMenuButton<int>(
      initialValue: pick,
      tooltip: l10n.integratedExamMatchPick,
      onSelected: (v) => setState(() => _matchPick[rowIndex] = v),
      itemBuilder: (ctx) => [
        for (var j = 0; j < _matchLeft.length; j++)
          PopupMenuItem(
            value: j,
            child: Text('${l10n.teacherExamGrammarRightColumn} ${j + 1}'),
          ),
      ],
      child: Container(
        height: TeacherWebUi.buttonHeightPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${l10n.integratedExamMatchPick}: $label',
              style: TeacherWebUi.webLabel(context).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMatch(BuildContext context, AppLocalizations l10n) {
    final rows = <Widget>[];
    for (var i = 0; i < _matchLeft.length; i++) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s4),
          child: DecoratedBox(
            decoration: TeacherWebUi.panelDecoration(bg: AppColors.surfaceSubtle),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.teacherExamGrammarPairCorrect(i + 1),
                    style: TeacherWebUi.sectionTitle(context),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Row(
                    children: [
                      Expanded(
                        child: _formField(
                          context,
                          label: l10n.teacherExamGrammarLeftColumn,
                          field: _textField(context, controller: _matchLeft[i]),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s2),
                      Expanded(
                        child: _formField(
                          context,
                          label: l10n.teacherExamGrammarRightColumn,
                          field: _textField(context, controller: _matchRight[i]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _matchPickMenu(context, l10n, i),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    rows.add(
      _compactAddButton(
        context,
        label: l10n.teacherExamGrammarAddOption,
        onPressed: () => setState(() {
          _matchLeft.add(TextEditingController());
          _matchRight.add(TextEditingController());
          _matchPick.add(_matchLeft.length - 1);
        }),
      ),
    );
    return rows;
  }

  List<Widget> _buildReorder(BuildContext context, AppLocalizations l10n) {
    final lines = _reorderLines.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (_reorderCorrectPerm.length != lines.length && lines.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _reorderCorrectPerm = List.generate(lines.length, (i) => i));
      });
    }
    return [
      _formField(
        context,
        label: l10n.teacherExamGrammarFragments,
        field: _textField(
          context,
          controller: _reorderLines,
          maxLines: 8,
          onChanged: (_) => setState(() {
            final ln = _reorderLines.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).length;
            if (ln < 2) return;
            _reorderCorrectPerm = List.generate(ln, (i) => i);
          }),
        ),
      ),
      if (lines.length >= 2) ...[
        const SizedBox(height: AppSpacing.s3),
        Text(l10n.teacherExamGrammarReorderInstruction, style: TeacherWebUi.metaMuted),
        const SizedBox(height: AppSpacing.s2),
        DecoratedBox(
          decoration: TeacherWebUi.panelDecoration(),
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _reorderCorrectPerm.length,
            onReorder: (a, b) {
              setState(() {
                if (b > a) b -= 1;
                final x = _reorderCorrectPerm.removeAt(a);
                _reorderCorrectPerm.insert(b, x);
              });
            },
            itemBuilder: (ctx, i) {
              final idx = _reorderCorrectPerm[i];
              final text = idx < lines.length ? lines[idx] : '';
              return ListTile(
                key: ValueKey('ord_${i}_$idx'),
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
                leading: ReorderableDragStartListener(
                  index: i,
                  child: const Icon(Icons.drag_handle, size: 18, color: AppColors.textSecondary),
                ),
                title: Text(text, style: TeacherWebUi.webBody(context), maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Text(
                  '${i + 1}',
                  style: TeacherWebUi.webCaption(context),
                ),
              );
            },
          ),
        ),
      ],
    ];
  }
}
