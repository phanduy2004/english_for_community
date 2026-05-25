import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_page_scaffold.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Edit a draft exam (title, results policy, MCQ / essay items in one section).
class TeacherExamEditorPage extends StatefulWidget {
  const TeacherExamEditorPage({super.key, required this.examId});

  final String examId;

  static const String routePathPrefix = '/teacher/exams';
  static const String routeName = 'TeacherExamEditorPage';

  @override
  State<TeacherExamEditorPage> createState() => _TeacherExamEditorPageState();
}

class _TeacherExamEditorPageState extends State<TeacherExamEditorPage> {
  bool _loading = true;
  String? _error;
  String _status = 'draft';
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _showResultsPolicy = 'after_submit';
  List<Map<String, dynamic>> _items = [];

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await getIt<TeacherExamRepository>().getExam(widget.examId);
    r.fold(
      (f) => setState(() => _error = f.message),
      (d) {
        final m = Map<String, dynamic>.from(d as Map);
        _status = (m['status'] as String?) ?? 'draft';
        _title.text = (m['title'] as String?) ?? '';
        _description.text = (m['description'] as String?) ?? '';
        final settings = m['settings'];
        if (settings is Map) {
          _showResultsPolicy = (settings['showResultsPolicy'] as String?) ?? 'after_submit';
        }
        final sections = m['sections'] as List?;
        if (sections != null && sections.isNotEmpty) {
          final sec = Map<String, dynamic>.from(sections.first as Map);
          final raw = sec['items'] as List? ?? [];
          _items = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else {
          _items = [];
        }
      },
    );
    if (mounted) setState(() => _loading = false);
  }

  Map<String, dynamic> _buildSectionsPayload() {
    return {
      'sections': [
        {
          'sectionId': 'sec_1',
          'title': '',
          'order': 0,
          'instructions': '',
          'items': _items,
        },
      ],
    };
  }

  Future<void> _saveDraft() async {
    if (_status != 'draft') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.teacherExamOnlyDraftEditable)));
      return;
    }
    final r = await getIt<TeacherExamRepository>().updateExamDraft(widget.examId, {
      'title': _title.text.trim(),
      'description': _description.text,
      'settings': {
        'showResultsPolicy': _showResultsPolicy,
        'allowMultipleSubmissions': false,
      },
      ..._buildSectionsPayload(),
    });
    if (!mounted) return;
    r.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.teacherExamDraftSaved)));
        _load();
      },
    );
  }

  Future<void> _publish() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.teacherExamPublishNeedItems)));
      return;
    }
    for (final it in _items) {
      final k = it['kind'] as String? ?? '';
      if (k == 'essay' && (it['prompt'] as String? ?? '').trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.teacherExamEssayNeedsPrompt)));
        return;
      }
      if ((k == 'mcq_single' || k == 'mcq_multi') && (it['stem'] as String? ?? '').trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.teacherExamMcqNeedsStem)));
        return;
      }
    }
    await _saveDraft();
    if (!mounted) return;
    final r = await getIt<TeacherExamRepository>().publishExam(widget.examId);
    if (!mounted) return;
    r.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.teacherExamPublished)));
        context.pop();
      },
    );
  }

  void _addMcq() {
    final n = _items.length + 1;
    final id = 'q_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _items.add({
        'kind': 'mcq_single',
        'itemId': id,
        'order': n,
        'points': 1,
        'stem': '',
        'options': <String>['Option A', 'Option B'],
        'correctOptionIndexes': <int>[0],
        'shuffleOptions': false,
      });
    });
  }

  void _addEssay() {
    final n = _items.length + 1;
    final id = 'e_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _items.add({
        'kind': 'essay',
        'itemId': id,
        'order': n,
        'points': 5,
        'prompt': '',
      });
    });
  }

  void _removeAt(int i) {
    setState(() => _items.removeAt(i));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TeacherPageScaffold(
      title: l10n.teacherExamEditorTitle,
      maxWidth: TeacherWebUi.contentMaxEditor,
      scrollable: false,
      showBack: true,
      actions: [
        if (_status == 'draft') ...[
          TextButton(
            onPressed: _saveDraft,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(l10n.teacherExamSaveDraft),
          ),
          TeacherFilledButton(label: l10n.teacherExamPublish, onPressed: _publish),
        ],
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: ExamSystemUi.captionSecondary))
              : ListView(
                  padding: TeacherWebUi.pageScrollPadding(context),
                  children: [
                    if (_status != 'draft')
                      Padding(
                        padding: const EdgeInsets.only(bottom: ExamSystemUi.blockGap),
                        child: Text(
                          l10n.teacherExamReadOnlyPublished,
                          style: ExamSystemUi.captionSecondary,
                        ),
                      ),
                    TextField(
                      controller: _title,
                      enabled: _status == 'draft',
                      decoration: InputDecoration(labelText: l10n.teacherExamTitleLabel),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _description,
                      enabled: _status == 'draft',
                      maxLines: 2,
                      decoration: InputDecoration(labelText: l10n.teacherExamDescriptionLabel),
                    ),
                    const SizedBox(height: ExamSystemUi.blockGap),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_showResultsPolicy),
                      initialValue: _showResultsPolicy,
                      decoration: InputDecoration(labelText: l10n.teacherExamResultsPolicy),
                      items: [
                        DropdownMenuItem(value: 'after_submit', child: Text(l10n.teacherExamPolicyAfterSubmit)),
                        DropdownMenuItem(value: 'after_release', child: Text(l10n.teacherExamPolicyAfterRelease)),
                        DropdownMenuItem(value: 'never', child: Text(l10n.teacherExamPolicyNever)),
                      ],
                      onChanged: _status == 'draft'
                          ? (v) {
                              if (v != null) setState(() => _showResultsPolicy = v);
                            }
                          : null,
                    ),
                    const SizedBox(height: ExamSystemUi.sectionGap),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        Text(l10n.teacherExamItemsTitle, style: ExamSystemUi.sectionTitle(context)),
                        if (_status == 'draft')
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              TeacherOutlinedButton(
                                label: l10n.teacherExamAddMcq,
                                icon: Icons.radio_button_off_outlined,
                                onPressed: _addMcq,
                              ),
                              TeacherOutlinedButton(
                                label: l10n.teacherExamAddEssay,
                                icon: Icons.article_outlined,
                                onPressed: _addEssay,
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: ExamSystemUi.cardGap),
                    if (_items.isEmpty)
                      AppCard(
                        variant: AppCardVariant.outline,
                        child: Text(l10n.teacherExamNoItemsHint),
                      )
                    else
                      ...List.generate(_items.length, (i) {
                        final it = _items[i];
                        final kind = it['kind'] as String? ?? '';
                        final id = it['itemId']?.toString() ?? '$i';
                        return Padding(
                          key: ValueKey(id),
                          padding: const EdgeInsets.only(bottom: ExamSystemUi.cardGap),
                          child: AppCard(
                            variant: AppCardVariant.outline,
                            child: _ItemEditorTile(
                              key: ValueKey(id),
                              index: i,
                              item: it,
                              kind: kind,
                              readOnly: _status != 'draft',
                              onChanged: (next) => setState(() => _items[i] = next),
                              onRemove: _status == 'draft' ? () => _removeAt(i) : null,
                            ),
                          ),
                        );
                      }),
                  ],
                ),
    );
  }
}

class _ItemEditorTile extends StatefulWidget {
  const _ItemEditorTile({
    super.key,
    required this.index,
    required this.item,
    required this.kind,
    required this.readOnly,
    required this.onChanged,
    this.onRemove,
  });

  final int index;
  final Map<String, dynamic> item;
  final String kind;
  final bool readOnly;
  final void Function(Map<String, dynamic> next) onChanged;
  final VoidCallback? onRemove;

  @override
  State<_ItemEditorTile> createState() => _ItemEditorTileState();
}

class _ItemEditorTileState extends State<_ItemEditorTile> {
  late TextEditingController _stemOrPrompt;
  late TextEditingController _options;
  late TextEditingController _correct;
  late TextEditingController _points;

  @override
  void initState() {
    super.initState();
    _syncFromItem();
  }

  @override
  void didUpdateWidget(covariant _ItemEditorTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item['itemId'] != widget.item['itemId'] || oldWidget.kind != widget.kind) {
      _stemOrPrompt.dispose();
      _options.dispose();
      _correct.dispose();
      _points.dispose();
      _syncFromItem();
    }
  }

  void _syncFromItem() {
    if (widget.kind == 'essay') {
      _stemOrPrompt = TextEditingController(text: widget.item['prompt'] as String? ?? '');
    } else {
      _stemOrPrompt = TextEditingController(text: widget.item['stem'] as String? ?? '');
    }
    final opts = (widget.item['options'] as List?)?.map((e) => e.toString()).toList() ?? <String>['A', 'B'];
    _options = TextEditingController(text: opts.join('|'));
    final ci = (widget.item['correctOptionIndexes'] as List?)?.isNotEmpty == true
        ? (widget.item['correctOptionIndexes'] as List).first
        : 0;
    _correct = TextEditingController(text: '$ci');
    _points = TextEditingController(text: '${widget.item['points'] ?? 1}');
  }

  @override
  void dispose() {
    _stemOrPrompt.dispose();
    _options.dispose();
    _correct.dispose();
    _points.dispose();
    super.dispose();
  }

  void _emitMcq() {
    final parts = _options.text.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final ci = int.tryParse(_correct.text.trim()) ?? 0;
    final p = int.tryParse(_points.text.trim()) ?? 1;
    widget.onChanged({
      ...widget.item,
      'stem': _stemOrPrompt.text,
      'options': parts.isEmpty ? ['A', 'B'] : parts,
      'correctOptionIndexes': [ci],
      'points': p,
    });
  }

  void _emitEssay() {
    final p = int.tryParse(_points.text.trim()) ?? 1;
    widget.onChanged({
      ...widget.item,
      'prompt': _stemOrPrompt.text,
      'points': p,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (widget.kind == 'essay') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.teacherExamAddEssay} #${widget.index + 1}',
                  style: ExamSystemUi.listTitle(context),
                ),
              ),
              if (widget.onRemove != null)
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                  iconSize: ExamSystemUi.iconSm,
                  color: AppColors.textMuted,
                ),
            ],
          ),
          TextField(
            controller: _stemOrPrompt,
            readOnly: widget.readOnly,
            maxLines: 3,
            decoration: InputDecoration(labelText: l10n.teacherExamEssayPrompt),
            onChanged: widget.readOnly ? null : (_) => _emitEssay(),
          ),
          TextField(
            controller: _points,
            readOnly: widget.readOnly,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.teacherExamPoints),
            onChanged: widget.readOnly ? null : (_) => _emitEssay(),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${l10n.teacherExamAddMcq} #${widget.index + 1}',
                style: ExamSystemUi.listTitle(context),
              ),
            ),
            if (widget.onRemove != null)
              IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.delete_outline),
                iconSize: ExamSystemUi.iconSm,
                color: AppColors.textMuted,
              ),
          ],
        ),
        TextField(
          controller: _stemOrPrompt,
          readOnly: widget.readOnly,
          maxLines: 2,
          decoration: InputDecoration(labelText: l10n.teacherExamStemLabel),
          onChanged: widget.readOnly ? null : (_) => _emitMcq(),
        ),
        TextField(
          controller: _options,
          readOnly: widget.readOnly,
          decoration: InputDecoration(
            labelText: l10n.teacherExamOptionsHint,
            helperText: l10n.teacherExamOptionsPipeHint,
          ),
          onChanged: widget.readOnly ? null : (_) => _emitMcq(),
        ),
        TextField(
          controller: _correct,
          readOnly: widget.readOnly,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.teacherExamCorrectIndex),
          onChanged: widget.readOnly ? null : (_) => _emitMcq(),
        ),
        TextField(
          controller: _points,
          readOnly: widget.readOnly,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.teacherExamPoints),
          onChanged: widget.readOnly ? null : (_) => _emitMcq(),
        ),
      ],
    );
  }
}
