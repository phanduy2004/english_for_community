import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/student/exams/exam_answer_review_widgets.dart';
import 'package:flutter/material.dart';

/// Localized label for a grammar / objective item [kind] string.
String grammarItemKindLabel(BuildContext context, String kind) {
  final t = context.l10n;
  switch (kind) {
    case 'mcq_single':
      return t.teacherExamGrammarKindMcqSingle;
    case 'mcq_multi':
      return t.teacherExamGrammarKindMcqMulti;
    case 'grammar_cloze':
      return t.teacherExamGrammarKindCloze;
    case 'grammar_gap':
      return t.teacherExamGrammarKindGap;
    case 'grammar_matching':
      return t.teacherExamGrammarKindMatching;
    case 'grammar_reorder':
      return t.teacherExamGrammarKindReorder;
    default:
      return kind;
  }
}

/// Teacher grading: shows the keyed correct answer (MCQ indexes, cloze keys, etc.).
class GrammarCorrectAnswerReviewPanel extends StatelessWidget {
  const GrammarCorrectAnswerReviewPanel({super.key, required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final lines = _lines(context);
    if (lines.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.teacherAttemptGradeCorrectAnswer,
            style: ExamSystemUi.captionMuted.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 8),
          ...lines,
        ],
      ),
    );
  }

  List<Widget> _lines(BuildContext context) {
    final kind = '${item['kind'] ?? ''}';
    final style = ExamSystemUi.captionSecondary;

    if (kind == 'mcq_single' || kind == 'mcq_multi') {
      final options = (item['options'] as List?)?.map((e) => '$e').toList() ?? <String>[];
      final raw = item['correctOptionIndexes'];
      if (raw is! List || raw.isEmpty) return [];
      final idxs = raw.map((e) => int.tryParse('$e') ?? -1).where((i) => i >= 0).toList()..sort();
      final texts = idxs.map((i) => (i < options.length) ? options[i] : '#$i').toList();
      return [
        Text(texts.join(kind == 'mcq_multi' ? '; ' : ' — '), style: style),
      ];
    }

    if (kind == 'grammar_cloze' || kind == 'grammar_gap') {
      final defs = item['blanks'] as List? ?? [];
      final out = <Widget>[];
      for (var i = 0; i < defs.length; i++) {
        if (defs[i] is! Map) continue;
        final d = defs[i] as Map;
        final id = '${d['blankId'] ?? i}';
        final accepted = (d['acceptedAnswers'] as List?)?.map((e) => '$e').where((s) => s.isNotEmpty).toList() ?? [];
        if (accepted.isEmpty) continue;
        out.add(
          Padding(
            padding: EdgeInsets.only(bottom: i < defs.length - 1 ? 6 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$id: ', style: ExamSystemUi.captionMuted),
                Expanded(child: Text(accepted.join(' / '), style: style)),
              ],
            ),
          ),
        );
      }
      return out;
    }

    if (kind == 'grammar_matching') {
      final left = (item['leftItems'] ?? item['leftColumn']) as List? ?? [];
      final right = (item['rightItems'] ?? item['rightColumn']) as List? ?? [];
      final corr = item['correctPairs'];
      if (corr is! List || corr.isEmpty) return [];
      String? rightText(String id) {
        for (final r in right) {
          if (r is Map && '${r['id']}' == id) return '${r['text'] ?? ''}'.trim();
        }
        return id;
      }

      String? leftText(String id) {
        for (final r in left) {
          if (r is Map && '${r['id']}' == id) return '${r['text'] ?? ''}'.trim();
        }
        return id;
      }

      final out = <Widget>[];
      for (final p in corr) {
        if (p is! List || p.length < 2) continue;
        final lt = leftText('${p[0]}');
        final rt = rightText('${p[1]}');
        out.add(Text('• $lt → $rt', style: style));
      }
      return out;
    }

    if (kind == 'grammar_reorder') {
      final fr = (item['fragments'] as List?)?.map((e) => '$e').toList() ?? <String>[];
      final cor = (item['correctOrder'] as List?)?.map((e) => int.tryParse('$e') ?? 0).toList() ?? <int>[];
      if (fr.isEmpty || cor.length != fr.length) return [];
      final ordered = cor.map((i) => (i >= 0 && i < fr.length) ? fr[i] : '').where((s) => s.isNotEmpty).toList();
      return [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < ordered.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${i + 1}. ${ordered[i]}', style: style),
              ),
          ],
        ),
      ];
    }

    return [];
  }
}

/// Whether the stored answer object satisfies backend [grammarAnswerComplete].
bool grammarAnswerLooksComplete(Map<String, dynamic> item, Map<String, dynamic>? answer) {
  if (answer == null) return false;
  final k = '${item['kind'] ?? ''}';
  if (k == 'mcq_single' || k == 'mcq_multi') {
    final sel = answer['selectedIndexes'];
    if (sel is! List || sel.isEmpty) return false;
    if (k == 'mcq_single' && sel.length != 1) return false;
    return true;
  }
  if (k == 'grammar_cloze' || k == 'grammar_gap') {
    final bl = answer['blanks'];
    if (bl is! Map) return false;
    final defs = item['blanks'];
    if (defs is! List || defs.isEmpty) return false;
    for (final d in defs) {
      if (d is! Map) return false;
      final id = '${d['blankId']}';
      final v = bl[id];
      if (v == null || '$v'.trim().isEmpty) return false;
    }
    return true;
  }
  if (k == 'grammar_matching') {
    final m = answer['matching'];
    if (m is! Map) return false;
    final left = (item['leftItems'] ?? item['leftColumn']) as List?;
    if (left == null) return false;
    for (final row in left) {
      if (row is! Map) return false;
      final id = '${row['id']}';
      final v = m[id];
      if (v == null || '$v'.trim().isEmpty) return false;
    }
    return true;
  }
  if (k == 'grammar_reorder') {
    final ord = answer['order'];
    final fr = item['fragments'];
    if (ord is! List || fr is! List) return false;
    return ord.length == fr.length;
  }
  return false;
}

List<int> _initialReorderDisplay(List<dynamic> correctOrderRaw) {
  final cor = correctOrderRaw.map((e) => int.tryParse('$e') ?? 0).toList();
  final n = cor.length;
  if (n < 2) return List<int>.generate(n, (i) => i);
  var perm = List<int>.generate(n, (i) => i);
  var same = perm.length == cor.length;
  if (same) {
    for (var i = 0; i < n; i++) {
      if (perm[i] != cor[i]) {
        same = false;
        break;
      }
    }
  }
  if (same) {
    perm = perm.reversed.toList();
  }
  return perm;
}

/// One Grammar question — MCQ, cloze, gap, matching, or reorder.
class IntegratedExamGrammarQuestionCard extends StatelessWidget {
  const IntegratedExamGrammarQuestionCard({
    super.key,
    required this.item,
    required this.answer,
    required this.locked,
    required this.onPartialPatch,
    this.displayIndex = 1,
    this.wrapInCard = true,
    this.reviewFooter,
    this.gradingReviewMode = false,
  });

  final Map<String, dynamic> item;
  final Map<String, dynamic>? answer;
  final bool locked;
  final void Function(Map<String, dynamic> partial) onPartialPatch;
  final int displayIndex;
  /// When false, only the inner column is returned (for embedding in a parent card).
  final bool wrapInCard;
  /// Optional block below the interactive body (e.g. correct-answer callout for teachers).
  final Widget? reviewFooter;
  /// Teacher grading: colored MCQ options (green correct / red wrong).
  final bool gradingReviewMode;

  @override
  Widget build(BuildContext context) {
    final kind = '${item['kind'] ?? ''}';
    final prompt = '${item['prompt'] ?? ''}'.trim();
    final idx = displayIndex;

    Widget inner;
    switch (kind) {
      case 'mcq_single':
      case 'mcq_multi':
        inner = gradingReviewMode
            ? McqGradingReviewList.fromMaps(item: item, answer: answer)
            : _McqBody(
                item: item,
                answer: answer,
                locked: locked,
                onPartialPatch: onPartialPatch,
              );
        break;
      case 'grammar_cloze':
        inner = _ClozeBody(
          item: item,
          answer: answer,
          locked: locked,
          onPartialPatch: onPartialPatch,
        );
        break;
      case 'grammar_gap':
        inner = _GapBody(
          item: item,
          answer: answer,
          locked: locked,
          onPartialPatch: onPartialPatch,
        );
        break;
      case 'grammar_matching':
        inner = _MatchingBody(
          item: item,
          answer: answer,
          locked: locked,
          onPartialPatch: onPartialPatch,
        );
        break;
      case 'grammar_reorder':
        inner = _ReorderBody(
          item: item,
          answer: answer,
          locked: locked,
          onPartialPatch: onPartialPatch,
        );
        break;
      default:
        inner = Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            context.l10n.integratedExamGrammarUnsupported,
            style: ExamSystemUi.captionSecondary,
          ),
        );
    }

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  Text(
                    '$idx.',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (prompt.isNotEmpty) Text(prompt, style: ExamSystemUi.questionStem(context)),
                        if (prompt.isNotEmpty) const SizedBox(height: 4),
                        Text(
                          grammarItemKindLabel(context, kind),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        inner,
        if (reviewFooter != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: reviewFooter!,
          ),
        ],
      ],
    );

    if (!wrapInCard) {
      return column;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: ExamSystemUi.cardGap),
      child: AppCard(
        variant: AppCardVariant.outline,
        child: column,
      ),
    );
  }
}

class _McqBody extends StatelessWidget {
  const _McqBody({
    required this.item,
    required this.answer,
    required this.locked,
    required this.onPartialPatch,
  });

  final Map<String, dynamic> item;
  final Map<String, dynamic>? answer;
  final bool locked;
  final void Function(Map<String, dynamic> partial) onPartialPatch;

  @override
  Widget build(BuildContext context) {
    final options = (item['options'] as List?)?.map((e) => '$e').toList() ?? <String>[];
    final kind = '${item['kind'] ?? ''}';
    final sel = (answer?['selectedIndexes'] as List?)?.map((e) => int.tryParse('$e') ?? 0).toSet() ?? <int>{};

    if (kind == 'mcq_single') {
      final group = sel.isEmpty ? null : sel.first;
      return Column(
        children: [
          for (var i = 0; i < options.length; i++)
            RadioListTile<int>(
              dense: true,
              value: i,
              groupValue: group,
              onChanged: locked
                  ? null
                  : (v) {
                      if (v != null) onPartialPatch({'selectedIndexes': [v]});
                    },
              title: Text(options[i], style: ExamSystemUi.captionSecondary),
            ),
        ],
      );
    }

    return Column(
      children: [
        for (var i = 0; i < options.length; i++)
          CheckboxListTile(
            dense: true,
            value: sel.contains(i),
            onChanged: locked
                ? null
                : (on) {
                    final next = {...sel};
                    if (on == true) {
                      next.add(i);
                    } else {
                      next.remove(i);
                    }
                    final list = List<int>.from(next)..sort();
                    onPartialPatch({'selectedIndexes': list});
                  },
            title: Text(options[i], style: ExamSystemUi.captionSecondary),
            controlAffinity: ListTileControlAffinity.leading,
          ),
      ],
    );
  }
}

class _ClozeBody extends StatefulWidget {
  const _ClozeBody({
    required this.item,
    required this.answer,
    required this.locked,
    required this.onPartialPatch,
  });

  final Map<String, dynamic> item;
  final Map<String, dynamic>? answer;
  final bool locked;
  final void Function(Map<String, dynamic> partial) onPartialPatch;

  @override
  State<_ClozeBody> createState() => _ClozeBodyState();
}

class _ClozeBodyState extends State<_ClozeBody> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant _ClozeBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.answer != widget.answer || oldWidget.item['passage'] != widget.item['passage']) {
      _syncControllers();
    }
  }

  void _syncControllers() {
    final passage = '${widget.item['passage'] ?? ''}';
    final reg = RegExp(r'\{\{([0-9]+)\}\}');
    final ids = reg.allMatches(passage).map((m) => m.group(1) ?? '0').toSet();
    for (final k in _controllers.keys.toList()) {
      if (!ids.contains(k)) {
        _controllers.remove(k)?.dispose();
      }
    }
    final blanks = (widget.answer?['blanks'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? {};
    for (final id in ids) {
      final t = blanks[id] ?? '';
      _controllers.putIfAbsent(id, () => TextEditingController());
      if (_controllers[id]!.text != t) {
        _controllers[id]!.text = t;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passage = '${widget.item['passage'] ?? ''}';
    final reg = RegExp(r'\{\{([0-9]+)\}\}');
    final pieces = <Widget>[];
    var start = 0;
    for (final m in reg.allMatches(passage)) {
      if (m.start > start) {
        pieces.add(Text(passage.substring(start, m.start), style: ExamSystemUi.captionSecondary));
      }
      final id = m.group(1) ?? '0';
      final ctl = _controllers[id]!;
      pieces.add(
        SizedBox(
          width: 100,
          child: TextField(
            enabled: !widget.locked,
            controller: ctl,
            onChanged: widget.locked ? null : (v) => widget.onPartialPatch({'blanks': {id: v}}),
            style: ExamSystemUi.captionSecondary,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      );
      start = m.end;
    }
    if (start < passage.length) {
      pieces.add(Text(passage.substring(start), style: ExamSystemUi.captionSecondary));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 8,
        children: pieces,
      ),
    );
  }
}

class _GapBody extends StatefulWidget {
  const _GapBody({
    required this.item,
    required this.answer,
    required this.locked,
    required this.onPartialPatch,
  });

  final Map<String, dynamic> item;
  final Map<String, dynamic>? answer;
  final bool locked;
  final void Function(Map<String, dynamic> partial) onPartialPatch;

  @override
  State<_GapBody> createState() => _GapBodyState();
}

class _GapBodyState extends State<_GapBody> {
  late final TextEditingController _ctl = TextEditingController();

  String get _blankId {
    final defs = widget.item['blanks'] as List?;
    if (defs != null && defs.isNotEmpty && defs.first is Map) {
      return '${(defs.first as Map)['blankId']}';
    }
    return '0';
  }

  @override
  void initState() {
    super.initState();
    _applyAnswer();
  }

  @override
  void didUpdateWidget(covariant _GapBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.answer != widget.answer) _applyAnswer();
  }

  void _applyAnswer() {
    final blanks = (widget.answer?['blanks'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? {};
    final t = blanks[_blankId] ?? '';
    if (_ctl.text != t) _ctl.text = t;
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final before = '${widget.item['textBefore'] ?? ''}';
    final after = '${widget.item['textAfter'] ?? ''}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Text(before, style: ExamSystemUi.captionSecondary),
          SizedBox(
            width: 120,
            child: TextField(
              enabled: !widget.locked,
              controller: _ctl,
              onChanged: widget.locked ? null : (v) => widget.onPartialPatch({'blanks': {_blankId: v}}),
              style: ExamSystemUi.captionSecondary,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Text(after, style: ExamSystemUi.captionSecondary),
        ],
      ),
    );
  }
}

class _MatchingBody extends StatelessWidget {
  const _MatchingBody({
    required this.item,
    required this.answer,
    required this.locked,
    required this.onPartialPatch,
  });

  final Map<String, dynamic> item;
  final Map<String, dynamic>? answer;
  final bool locked;
  final void Function(Map<String, dynamic> partial) onPartialPatch;

  @override
  Widget build(BuildContext context) {
    final left = (item['leftItems'] ?? item['leftColumn']) as List? ?? [];
    final right = (item['rightItems'] ?? item['rightColumn']) as List? ?? [];
    final m = (answer?['matching'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? <String, String>{};

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        children: [
          for (final row in left)
            if (row is Map)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text('${row['text'] ?? ''}', style: ExamSystemUi.captionSecondary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: m['${row['id']}']?.isNotEmpty == true ? m['${row['id']}'] : null,
                        decoration: InputDecoration(
                          labelText: context.l10n.integratedExamMatchPick,
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: [
                          for (final r in right)
                            if (r is Map)
                              DropdownMenuItem(
                                value: '${r['id']}',
                                child: Text('${r['text'] ?? ''}', overflow: TextOverflow.ellipsis),
                              ),
                        ],
                        onChanged: locked
                            ? null
                            : (v) {
                                if (v == null) return;
                                onPartialPatch({
                                  'matching': {'${row['id']}': v},
                                });
                              },
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _ReorderBody extends StatefulWidget {
  const _ReorderBody({
    required this.item,
    required this.answer,
    required this.locked,
    required this.onPartialPatch,
  });

  final Map<String, dynamic> item;
  final Map<String, dynamic>? answer;
  final bool locked;
  final void Function(Map<String, dynamic> partial) onPartialPatch;

  @override
  State<_ReorderBody> createState() => _ReorderBodyState();
}

class _ReorderBodyState extends State<_ReorderBody> {
  late List<int> _order;
  late List<String> _fragments;

  @override
  void initState() {
    super.initState();
    final fr = (widget.item['fragments'] as List?)?.map((e) => '$e').toList() ?? <String>[];
    _fragments = fr;
    final cor = (widget.item['correctOrder'] as List?) ?? [];
    final saved = widget.answer?['order'] as List?;
    if (saved != null && saved.length == fr.length) {
      _order = saved.map((e) => int.tryParse('$e') ?? 0).toList();
    } else {
      _order = _initialReorderDisplay(cor);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onPartialPatch({'order': List<int>.from(_order)});
      });
    }
  }

  @override
  void didUpdateWidget(covariant _ReorderBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item['fragments'] != widget.item['fragments']) {
      final fr = (widget.item['fragments'] as List?)?.map((e) => '$e').toList() ?? <String>[];
      _fragments = fr;
      final cor = (widget.item['correctOrder'] as List?) ?? [];
      final saved = widget.answer?['order'] as List?;
      if (saved != null && saved.length == fr.length) {
        _order = saved.map((e) => int.tryParse('$e') ?? 0).toList();
      } else {
        _order = _initialReorderDisplay(cor);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.locked) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < _order.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text(
                      _fragments.isNotEmpty && _order[i] < _fragments.length ? _fragments[_order[i]] : '',
                      style: ExamSystemUi.captionSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _order.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final x = _order.removeAt(oldIndex);
                _order.insert(newIndex, x);
              });
              widget.onPartialPatch({'order': List<int>.from(_order)});
            },
            itemBuilder: (context, i) {
              final fi = _order[i];
              final text = fi < _fragments.length ? _fragments[fi] : '';
              return Material(
                key: ValueKey('${widget.item['itemId']}_${_order[i]}_$i'),
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  leading: ReorderableDragStartListener(
                    index: i,
                    child: const Icon(Icons.drag_handle, color: AppColors.textSecondary),
                  ),
                  title: Text(text, style: ExamSystemUi.captionSecondary),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
