import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/teacher/bloc/exam_editor/teacher_exam_editor_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/exam_editor/teacher_exam_editor_event.dart';
import 'package:english_for_community/feature/teacher/bloc/exam_editor/teacher_exam_editor_state.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_page_scaffold.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Edit a draft exam (title, results policy, MCQ / essay items in one section).
class TeacherExamEditorPage extends StatelessWidget {
  const TeacherExamEditorPage({super.key, required this.examId});

  final String examId;

  static const String routePathPrefix = '/teacher/exams';
  static const String routeName = 'TeacherExamEditorPage';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TeacherExamEditorBloc>(param1: examId)
        ..add(const TeacherExamEditorLoadRequested()),
      child: const _TeacherExamEditorView(),
    );
  }
}

class _TeacherExamEditorView extends StatelessWidget {
  const _TeacherExamEditorView();

  void _addMcq(BuildContext context, List<Map<String, dynamic>> items) {
    final n = items.length + 1;
    final id = 'q_${DateTime.now().millisecondsSinceEpoch}';
    context.read<TeacherExamEditorBloc>().add(TeacherExamEditorItemsChanged([
      ...items,
      {
        'kind': 'mcq_single',
        'itemId': id,
        'order': n,
        'points': 1,
        'stem': '',
        'options': <String>['Option A', 'Option B'],
        'correctOptionIndexes': <int>[0],
        'shuffleOptions': false,
      },
    ]));
  }

  void _addEssay(BuildContext context, List<Map<String, dynamic>> items) {
    final n = items.length + 1;
    final id = 'e_${DateTime.now().millisecondsSinceEpoch}';
    context.read<TeacherExamEditorBloc>().add(TeacherExamEditorItemsChanged([
      ...items,
      {
        'kind': 'essay',
        'itemId': id,
        'order': n,
        'points': 5,
        'prompt': '',
      },
    ]));
  }

  void _removeAt(BuildContext context, List<Map<String, dynamic>> items, int i) {
    final next = List<Map<String, dynamic>>.from(items)..removeAt(i);
    context.read<TeacherExamEditorBloc>().add(TeacherExamEditorItemsChanged(next));
  }

  bool _validatePublish(BuildContext context, TeacherExamEditorState state) {
    final l10n = context.l10n;
    if (state.items.isEmpty) {
      AppCornerToast.show(context, l10n.teacherExamPublishNeedItems, error: true);
      return false;
    }
    for (final it in state.items) {
      final k = it['kind'] as String? ?? '';
      if (k == 'essay' && (it['prompt'] as String? ?? '').trim().isEmpty) {
        AppCornerToast.show(context, l10n.teacherExamEssayNeedsPrompt, error: true);
        return false;
      }
      if ((k == 'mcq_single' || k == 'mcq_multi') && (it['stem'] as String? ?? '').trim().isEmpty) {
        AppCornerToast.show(context, l10n.teacherExamMcqNeedsStem, error: true);
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<TeacherExamEditorBloc, TeacherExamEditorState>(
      listenWhen: (prev, curr) =>
          (curr.errorMessage != null && prev.errorMessage != curr.errorMessage) ||
          (curr.successMessage != null && prev.successMessage != curr.successMessage),
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppCornerToast.show(context, state.errorMessage!, error: true);
        }
        final success = state.successMessage;
        if (success == 'draft_saved') {
          AppCornerToast.show(context, l10n.teacherExamDraftSaved);
        } else if (success == 'published') {
          AppCornerToast.show(context, l10n.teacherExamPublished);
          context.pop();
        }
      },
      builder: (context, state) {
        final loading = state.status == TeacherExamEditorStatus.loading;
        final error = state.status == TeacherExamEditorStatus.error ? state.errorMessage : null;
        final isDraft = state.isDraft;

        return TeacherPageScaffold(
          title: l10n.teacherExamEditorTitle,
          maxWidth: TeacherWebUi.contentMaxEditor,
          scrollable: false,
          showBack: true,
          actions: [
            if (isDraft) ...[
              TextButton(
                onPressed: state.saving
                    ? null
                    : () {
                        if (!isDraft) {
                          AppCornerToast.show(context, l10n.teacherExamOnlyDraftEditable, error: true);
                          return;
                        }
                        context.read<TeacherExamEditorBloc>().add(const TeacherExamEditorSaveDraftRequested());
                      },
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(l10n.teacherExamSaveDraft),
              ),
              TeacherFilledButton(
                label: l10n.teacherExamPublish,
                onPressed: state.saving
                    ? null
                    : () {
                        if (!_validatePublish(context, state)) return;
                        context.read<TeacherExamEditorBloc>().add(const TeacherExamEditorPublishRequested());
                      },
              ),
            ],
          ],
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? Center(child: Text(error, style: ExamSystemUi.captionSecondary))
                  : ListView(
                      padding: TeacherWebUi.pageScrollPadding(context),
                      children: [
                        if (!isDraft)
                          Padding(
                            padding: const EdgeInsets.only(bottom: ExamSystemUi.blockGap),
                            child: Text(
                              l10n.teacherExamReadOnlyPublished,
                              style: ExamSystemUi.captionSecondary,
                            ),
                          ),
                        _SyncedTextField(
                          value: state.title,
                          enabled: isDraft,
                          decoration: InputDecoration(labelText: l10n.teacherExamTitleLabel),
                          onChanged: (v) => context.read<TeacherExamEditorBloc>().add(TeacherExamEditorTitleChanged(v)),
                        ),
                        const SizedBox(height: 12),
                        _SyncedTextField(
                          value: state.description,
                          enabled: isDraft,
                          maxLines: 2,
                          decoration: InputDecoration(labelText: l10n.teacherExamDescriptionLabel),
                          onChanged: (v) =>
                              context.read<TeacherExamEditorBloc>().add(TeacherExamEditorDescriptionChanged(v)),
                        ),
                        const SizedBox(height: ExamSystemUi.blockGap),
                        DropdownButtonFormField<String>(
                          key: ValueKey(state.showResultsPolicy),
                          initialValue: state.showResultsPolicy,
                          decoration: InputDecoration(labelText: l10n.teacherExamResultsPolicy),
                          items: [
                            DropdownMenuItem(value: 'after_submit', child: Text(l10n.teacherExamPolicyAfterSubmit)),
                            DropdownMenuItem(value: 'after_release', child: Text(l10n.teacherExamPolicyAfterRelease)),
                            DropdownMenuItem(value: 'never', child: Text(l10n.teacherExamPolicyNever)),
                          ],
                          onChanged: isDraft
                              ? (v) {
                                  if (v != null) {
                                    context.read<TeacherExamEditorBloc>().add(TeacherExamEditorResultsPolicyChanged(v));
                                  }
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
                            if (isDraft)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  TeacherOutlinedButton(
                                    label: l10n.teacherExamAddMcq,
                                    icon: Icons.radio_button_off_outlined,
                                    onPressed: () => _addMcq(context, state.items),
                                  ),
                                  TeacherOutlinedButton(
                                    label: l10n.teacherExamAddEssay,
                                    icon: Icons.article_outlined,
                                    onPressed: () => _addEssay(context, state.items),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: ExamSystemUi.cardGap),
                        if (state.items.isEmpty)
                          AppCard(
                            variant: AppCardVariant.outline,
                            child: Text(l10n.teacherExamNoItemsHint),
                          )
                        else
                          ...List.generate(state.items.length, (i) {
                            final it = state.items[i];
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
                                  readOnly: !isDraft,
                                  onChanged: (next) {
                                    final nextItems = List<Map<String, dynamic>>.from(state.items);
                                    nextItems[i] = next;
                                    context.read<TeacherExamEditorBloc>().add(TeacherExamEditorItemsChanged(nextItems));
                                  },
                                  onRemove: isDraft ? () => _removeAt(context, state.items, i) : null,
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
        );
      },
    );
  }
}

/// Text field synced from BLoC when external loads change the value.
class _SyncedTextField extends StatefulWidget {
  const _SyncedTextField({
    required this.value,
    required this.onChanged,
    required this.decoration,
    this.enabled = true,
    this.maxLines = 1,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final InputDecoration decoration;
  final bool enabled;
  final int maxLines;

  @override
  State<_SyncedTextField> createState() => _SyncedTextFieldState();
}

class _SyncedTextFieldState extends State<_SyncedTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _SyncedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      decoration: widget.decoration,
      onChanged: widget.onChanged,
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
