import 'dart:math' as math;

import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
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
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.initial == null ? l10n.teacherExamGrammarNewItem : l10n.teacherExamGrammarPanelTitle,
                      style: ExamSystemUi.sectionTitle(context),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_outlined),
                    color: AppColors.textSecondary,
                    tooltip: l10n.teacherExamGrammarCloseEditor,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey(_kind),
                    initialValue: _kind,
                    decoration: InputDecoration(
                      labelText: l10n.teacherExamGrammarQuestionType,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: [
                      DropdownMenuItem(value: 'mcq_single', child: Text(l10n.teacherExamGrammarKindMcqSingle)),
                      DropdownMenuItem(value: 'mcq_multi', child: Text(l10n.teacherExamGrammarKindMcqMulti)),
                      DropdownMenuItem(value: 'grammar_cloze', child: Text(l10n.teacherExamGrammarKindCloze)),
                      DropdownMenuItem(value: 'grammar_gap', child: Text(l10n.teacherExamGrammarKindGap)),
                      DropdownMenuItem(value: 'grammar_matching', child: Text(l10n.teacherExamGrammarKindMatching)),
                      DropdownMenuItem(value: 'grammar_reorder', child: Text(l10n.teacherExamGrammarKindReorder)),
                    ],
                    onChanged: (v) {
                      if (v != null) _setKind(v);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _points,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.teacherExamPoints,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_kind == 'mcq_single' || _kind == 'mcq_multi') ..._buildMcq(l10n),
                  if (_kind == 'grammar_cloze') ..._buildCloze(l10n),
                  if (_kind == 'grammar_gap') ..._buildGap(l10n),
                  if (_kind == 'grammar_matching') ..._buildMatch(l10n),
                  if (_kind == 'grammar_reorder') ..._buildReorder(l10n),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: TeacherInlineActions(
                children: [
                  TeacherFilledButton(
                    label: l10n.teacherExamGrammarSaveItem,
                    onPressed: _onSavePressed,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMcq(AppLocalizations l10n) {
    return [
      TextField(
        controller: _prompt,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: l10n.teacherExamStemLabel,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() => _mcqOptions.add(TextEditingController())),
          icon: const Icon(Icons.add, size: 18),
          label: Text(l10n.teacherExamGrammarAddOption),
        ),
      ),
      if (_kind == 'mcq_multi')
        for (var i = 0; i < _mcqOptions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _mcqCorrect.contains(i),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _mcqCorrect.add(i);
                    } else {
                      _mcqCorrect.remove(i);
                    }
                  }),
                ),
                Expanded(
                  child: TextField(
                    controller: _mcqOptions[i],
                    decoration: InputDecoration(
                      labelText: '${l10n.teacherExamOptionsHint} $i',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
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
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Radio<int>(value: i),
                      Expanded(
                        child: TextField(
                          controller: _mcqOptions[i],
                          decoration: InputDecoration(
                            labelText: '${l10n.teacherExamOptionsHint} $i',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _buildCloze(AppLocalizations l10n) {
    return [
      TextField(
        controller: _clozePassage,
        maxLines: 6,
        onChanged: (_) => setState(_syncClozeBlankFields),
        decoration: InputDecoration(
          labelText: l10n.teacherExamGrammarPassageLabel,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      const SizedBox(height: 16),
      Text(l10n.teacherExamGrammarAcceptedAnswers, style: ExamSystemUi.captionMuted),
      const SizedBox(height: 8),
      for (final e in _clozeAccepted.entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
            controller: e.value,
            decoration: InputDecoration(
              labelText: '${l10n.teacherExamGrammarBlankId} ${e.key}',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildGap(AppLocalizations l10n) {
    return [
      TextField(
        controller: _gapBefore,
        decoration: InputDecoration(
          labelText: l10n.teacherExamGrammarTextBefore,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _gapAfter,
        decoration: InputDecoration(
          labelText: l10n.teacherExamGrammarTextAfter,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _gapAccepted,
        decoration: InputDecoration(
          labelText: l10n.teacherExamGrammarAcceptedAnswers,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    ];
  }

  List<Widget> _buildMatch(AppLocalizations l10n) {
    final rows = <Widget>[];
    for (var i = 0; i < _matchLeft.length; i++) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.teacherExamGrammarPairCorrect(i + 1), style: ExamSystemUi.captionMuted),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _matchLeft[i],
                      decoration: InputDecoration(
                        labelText: l10n.teacherExamGrammarLeftColumn,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _matchRight[i],
                      decoration: InputDecoration(
                        labelText: l10n.teacherExamGrammarRightColumn,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                key: ValueKey('match_$i${_matchPick[i]}'),
                initialValue: _matchPick[i].clamp(0, _matchLeft.length - 1),
                decoration: InputDecoration(
                  labelText: l10n.integratedExamMatchPick,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: [
                  for (var j = 0; j < _matchLeft.length; j++)
                    DropdownMenuItem(value: j, child: Text('${l10n.teacherExamGrammarRightColumn} ${j + 1}')),
                ],
                onChanged: (v) => setState(() => _matchPick[i] = v ?? 0),
              ),
            ],
          ),
        ),
      );
    }
    rows.add(
      TextButton.icon(
        onPressed: () => setState(() {
          _matchLeft.add(TextEditingController());
          _matchRight.add(TextEditingController());
          _matchPick.add(_matchLeft.length - 1);
        }),
        icon: const Icon(Icons.add, size: 18),
        label: Text(l10n.teacherExamGrammarAddOption),
      ),
    );
    return rows;
  }

  List<Widget> _buildReorder(AppLocalizations l10n) {
    final lines = _reorderLines.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (_reorderCorrectPerm.length != lines.length && lines.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _reorderCorrectPerm = List.generate(lines.length, (i) => i));
      });
    }
    return [
      TextField(
        controller: _reorderLines,
        maxLines: 8,
        onChanged: (_) => setState(() {
          final ln = _reorderLines.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).length;
          if (ln < 2) return;
          _reorderCorrectPerm = List.generate(ln, (i) => i);
        }),
        decoration: InputDecoration(
          labelText: l10n.teacherExamGrammarFragments,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      const SizedBox(height: 12),
      if (lines.length >= 2)
        ReorderableListView.builder(
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
              leading: ReorderableDragStartListener(
                index: i,
                child: const Icon(Icons.drag_handle, color: AppColors.textSecondary),
              ),
              title: Text(text, style: ExamSystemUi.captionSecondary),
            );
          },
        ),
    ];
  }
}
