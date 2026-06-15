import 'dart:convert';
import 'dart:math' as math;

import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle, Clipboard, ClipboardData;
import 'package:english_for_community/core/repository/listening_comp_repository.dart';
import 'package:english_for_community/core/repository/listening_repository.dart';
import 'package:english_for_community/core/repository/reading_repository.dart';
import 'package:english_for_community/core/repository/speaking_repository.dart';
import 'package:english_for_community/core/repository/writing_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/feature/speaking/speaking_hub_page.dart';
import 'package:english_for_community/feature/teacher/bloc/integrated_exam_editor/teacher_integrated_exam_editor_constants.dart';
import 'package:english_for_community/feature/teacher/bloc/integrated_exam_editor/teacher_integrated_exam_editor_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/integrated_exam_editor/teacher_integrated_exam_editor_event.dart';
import 'package:english_for_community/feature/teacher/bloc/integrated_exam_editor/teacher_integrated_exam_editor_payload.dart';
import 'package:english_for_community/feature/teacher/bloc/integrated_exam_editor/teacher_integrated_exam_editor_state.dart';
import 'package:english_for_community/feature/teacher/teacher_skills_exam_grammar_editor_panel.dart';
import 'package:english_for_community/core/ui/workspace_layout_scope.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_page_scaffold.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/teacher_dashboard_page.dart';
import 'package:english_for_community/feature/teacher/teacher_exams_list_page.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Minimal JSON example if the bundled asset is missing (e.g. hot reload without `flutter pub get`).
const String _grammarImportSampleFallback = r'''
[
  {
    "kind": "mcq_single",
    "prompt": "She _____ to school every morning.",
    "options": ["go", "goes", "going", "gone"],
    "correctOptionIndexes": [1],
    "points": 1
  },
  {
    "kind": "grammar_cloze",
    "passage": "English {{0}} a useful language.",
    "blanks": [{"blankId": "0", "acceptedAnswers": ["is", "was"]}],
    "points": 1
  }
]
''';

/// Draft editor: **skills exam** — vertical paper layout (Grammar then skills), web split view for grammar authoring.
class TeacherIntegratedExamEditorPage extends StatelessWidget {
  const TeacherIntegratedExamEditorPage({super.key, required this.examId});

  final String examId;

  static const String routePathPrefix = '/teacher/exams';

  static const List<String> skillOrder = teacherIntegratedExamSkillOrder;
  static const Map<String, String> sectionIdsForSkill = teacherIntegratedExamSectionIdsForSkill;

  @override
  Widget build(BuildContext context) {
    final legacyUntitled = context.l10n.teacherExamIntegratedUntitled;
    return BlocProvider(
      create: (_) => TeacherIntegratedExamEditorBloc(
        repository: getIt(),
        examId: examId,
      )..add(TeacherIntegratedExamEditorLoadRequested(legacyUntitledLabel: legacyUntitled)),
      child: BlocListener<TeacherIntegratedExamEditorBloc, TeacherIntegratedExamEditorState>(
        listenWhen: (prev, curr) =>
            (curr.errorMessage != null && prev.errorMessage != curr.errorMessage) ||
            (curr.successMessage != null && prev.successMessage != curr.successMessage) ||
            (curr.publishFailure != null && prev.publishFailure != curr.publishFailure) ||
            (curr.writingPromptOptions != null && prev.writingPromptOptions != curr.writingPromptOptions),
        listener: (context, state) {
          final l10n = context.l10n;
          if (state.errorMessage != null) {
            AppCornerToast.show(context, state.errorMessage!, error: true);
          }
          if (state.successMessage == 'draft_saved') {
            AppCornerToast.show(context, l10n.teacherExamDraftSaved);
          } else if (state.successMessage == 'published') {
            AppCornerToast.show(context, l10n.teacherExamPublished);
            context.pop();
          }
          final failure = state.publishFailure;
          if (failure != null) {
            final msg = switch (failure) {
              TeacherIntegratedExamEditorPublishFailure.writingNeedPrompt =>
                l10n.teacherExamWritingPublishNeedPrompt,
              TeacherIntegratedExamEditorPublishFailure.speakingRequired =>
                l10n.teacherExamSpeakingExerciseRequired,
              TeacherIntegratedExamEditorPublishFailure.skillResourceRequired =>
                l10n.teacherExamPublishPickEachIncludedSkill,
              TeacherIntegratedExamEditorPublishFailure.grammarEnabledNoItems =>
                l10n.teacherExamGrammarEnabledNoItems,
              TeacherIntegratedExamEditorPublishFailure.needSelection => l10n.teacherExamPublishNeedSelection,
              TeacherIntegratedExamEditorPublishFailure.grammarPointsCap100 =>
                l10n.teacherExamGrammarPointsCap100,
            };
            AppCornerToast.show(context, msg, error: true);
          }
          final options = state.writingPromptOptions;
          if (options != null) {
            _TeacherIntegratedExamEditorViewState._showWritingPromptPickDialog(context, options);
            context.read<TeacherIntegratedExamEditorBloc>().add(
                  const TeacherIntegratedExamEditorWritingPromptOptionsDismissed(),
                );
          }
        },
        child: _TeacherIntegratedExamEditorView(examId: examId),
      ),
    );
  }
}

class _TeacherIntegratedExamEditorView extends StatefulWidget {
  const _TeacherIntegratedExamEditorView({required this.examId});

  final String examId;

  @override
  State<_TeacherIntegratedExamEditorView> createState() => _TeacherIntegratedExamEditorViewState();
}

class _TeacherIntegratedExamEditorViewState extends State<_TeacherIntegratedExamEditorView> {
  final TextEditingController _titleController = TextEditingController();

  TeacherIntegratedExamEditorBloc get _bloc => context.read<TeacherIntegratedExamEditorBloc>();

  TeacherIntegratedExamEditorState get _s => _bloc.state;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _displayTitle(AppLocalizations l10n) {
    final t = _s.title.trim();
    return t.isNotEmpty ? t : l10n.teacherExamUntitled;
  }

  bool _useWebLayout() => WorkspaceLayoutScope.isWebWorkspace(context);

  List<Map<String, dynamic>> _getResources(Map<String, dynamic> sec) =>
      teacherIntegratedExamEditorGetResources(sec);

  Map<String, dynamic>? _getWritingFixedPrompt() =>
      teacherIntegratedExamEditorGetWritingFixedPrompt(_s.skillSection);

  void _removeResource(String skill, int idx, {String? listeningSubType}) {
    _bloc.add(TeacherIntegratedExamEditorRemoveResource(
      skill: skill,
      index: idx,
      listeningSubType: listeningSubType,
    ));
  }

  void _reload() {
    _bloc.add(TeacherIntegratedExamEditorLoadRequested(legacyUntitledLabel: context.l10n.teacherExamIntegratedUntitled));
  }

  void _saveDraft() => _bloc.add(const TeacherIntegratedExamEditorSaveDraftRequested());

  void _publish() => _bloc.add(const TeacherIntegratedExamEditorPublishRequested());

  bool _skillMeetsPublishRequirement(String skill) =>
      teacherIntegratedExamEditorSkillMeetsPublishRequirement(
        skill: skill,
        included: _s.skillIncluded[skill] ?? false,
        skillSection: _s.skillSection,
      );

  String _skillLabel(String skill) {
    final t = context.l10n;
    switch (skill) {
      case 'listening':
        return t.teacherExamIntegratedSkillListening;
      case 'speaking':
        return t.teacherExamIntegratedSkillSpeaking;
      case 'reading':
        return t.teacherExamIntegratedSkillReading;
      case 'writing':
        return t.teacherExamIntegratedSkillWriting;
      default:
        return skill;
    }
  }

  IconData _skillIcon(String skill) {
    switch (skill) {
      case 'listening':
        return Icons.headphones_outlined;
      case 'speaking':
        return Icons.record_voice_over_outlined;
      case 'reading':
        return Icons.menu_book_outlined;
      case 'writing':
        return Icons.edit_note_outlined;
      default:
        return Icons.widgets_outlined;
    }
  }

  Widget _buildSkillHeaderIcon(String skill) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineMuted),
      ),
      child: Icon(_skillIcon(skill), size: 18, color: AppColors.textSecondary),
    );
  }

  Widget _neutralHintBox(String message, {IconData icon = Icons.info_outline}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineMuted),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TeacherWebUi.webCaption(context)),
          ),
        ],
      ),
    );
  }

  Widget _compactSectionSwitch({
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Transform.scale(
      scale: 0.88,
      child: Switch.adaptive(value: value, onChanged: onChanged),
    );
  }

  Widget? _publishHintBanner(String message) => _neutralHintBox(message);

  /// Neutral add-exercise CTA (no per-skill tint).
  Widget _buildAddExerciseAction({
    required VoidCallback onPressed,
  }) {
    final l10n = context.l10n;
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        style: TeacherWebUi.compactOutlinedStyle(context),
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded, size: 16),
        label: Text(l10n.teacherExamSkillsAddExercise),
      ),
    );
  }

  Future<void> _pickAt(String skill) async {
    final l10n = context.l10n;
    List<({String id, String title})>? picks;

    final pickSkill = skill;
    final currentIds = _getResources(_s.skillSection[skill] ?? {}).map((r) => r['id'] as String? ?? '').toSet();

    void navigateCreateNew(BuildContext dialogCtx) {
      Navigator.of(dialogCtx).pop();
      context.push('/teacher/content/$skill/new');
    }

    if (_useWebLayout()) {
      picks = await showDialog<List<({String id, String title})>>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          return Dialog(
            backgroundColor: AppColors.surfaceCard,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 560,
                maxHeight: math.min(MediaQuery.sizeOf(ctx).height * 0.85, 640),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.teacherExamIntegratedChooseExercise,
                            style: ExamSystemUi.sectionTitle(context),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_outlined),
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _SkillPickPanel(
                        skill: pickSkill,
                        alreadySelectedIds: currentIds,
                        useWebListLayout: true,
                        onConfirmMulti: (items) => Navigator.pop(ctx, items),
                        onCreateNew: pickSkill == 'listening_comp' ? null : () => navigateCreateNew(ctx),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else {
      picks = await showModalBottomSheet<List<({String id, String title})>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (context, scroll) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outlineMuted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.teacherExamIntegratedChooseExercise, style: ExamSystemUi.sectionTitle(context)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _SkillPickPanel(
                      skill: pickSkill,
                      alreadySelectedIds: currentIds,
                      useWebListLayout: false,
                      scrollController: scroll,
                      onConfirmMulti: (items) => Navigator.pop(ctx, items),
                      onCreateNew: pickSkill == 'listening_comp' ? null : () => navigateCreateNew(ctx),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    if (picks == null || picks.isEmpty || !mounted) return;
    for (final item in picks) {
      _bloc.add(TeacherIntegratedExamEditorSkillResourceAdded(
        skill: skill,
        resourceId: item.id,
        resourceTitle: item.title,
      ));
    }
  }

  void _closeGrammarEditor() {
    _bloc.add(const TeacherIntegratedExamEditorGrammarEditorIndexChanged(null));
  }

  void _onGrammarSaved(Map<String, dynamic> m) {
    _bloc.add(TeacherIntegratedExamEditorGrammarSaved(m));
  }

  Future<void> _openGrammarEditor({int? editIndex}) async {
    if (_s.examStatus != 'draft') return;
    if (_useWebLayout()) {
      _bloc.add(TeacherIntegratedExamEditorGrammarEditorIndexChanged(editIndex ?? -1));
      return;
    }
    Map<String, dynamic>? initial;
    if (editIndex != null) initial = Map<String, dynamic>.from(_s.grammarItems[editIndex]);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final h = MediaQuery.sizeOf(ctx).height * 0.92;
        return SizedBox(
          height: h,
          child: TeacherSkillsExamGrammarEditorPanel(
            initial: initial,
            onSave: (item) {
              if (!mounted) return;
              _bloc.add(TeacherIntegratedExamEditorGrammarSaved(item));
              Navigator.pop(ctx);
            },
            onClose: () => Navigator.pop(ctx),
          ),
        );
      },
    );
  }

  void _removeGrammarAt(int i) {
    final next = [..._s.grammarItems]..removeAt(i);
    var editorIndex = _s.grammarEditorIndex;
    if (editorIndex == i) {
      editorIndex = null;
    } else if (editorIndex != null && editorIndex > i) {
      editorIndex = editorIndex - 1;
    }
    _bloc.add(TeacherIntegratedExamEditorGrammarItemsUpdated(next));
    if (editorIndex != _s.grammarEditorIndex) {
      _bloc.add(TeacherIntegratedExamEditorGrammarEditorIndexChanged(editorIndex));
    }
  }

  String _grammarKindLabel(String kind) {
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

  String _grammarPreview(Map<String, dynamic> it) {
    final k = '${it['kind'] ?? ''}';
    String raw;
    switch (k) {
      case 'grammar_cloze':
        raw = '${it['passage'] ?? ''}'.trim().replaceAll('\n', ' ');
        break;
      case 'grammar_gap':
        raw = '${it['textBefore'] ?? ''} … ${it['textAfter'] ?? ''}';
        break;
      case 'grammar_matching':
        final n = (it['leftItems'] as List?)?.length ?? 0;
        raw = '$n × $n';
        break;
      case 'grammar_reorder':
        raw = (it['fragments'] as List?)?.map((e) => '$e').join(' / ') ?? '';
        break;
      default:
        raw = '${it['prompt'] ?? ''}'.trim();
    }
    if (raw.length > 120) return '${raw.substring(0, 117)}...';
    return raw;
  }

  Widget? _webStickyActions(BuildContext context) {
    if (!_useWebLayout() || !_s.canEditSkillContent || _s.status == TeacherIntegratedExamEditorStatus.loading || _s.errorMessage != null) {
      return null;
    }
    final l10n = context.l10n;
    return Material(
      elevation: 4,
      color: AppColors.surfaceCard,
      shadowColor: Colors.black12,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s3),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _displayTitle(l10n),
                  style: TeacherWebUi.webCaption(context),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              OutlinedButton(
                style: TeacherWebUi.compactOutlinedStyle(context),
                onPressed: _saveDraft,
                child: Text(l10n.teacherExamSaveDraft),
              ),
              if (_s.examStatus == 'draft') ...[
                const SizedBox(width: AppSpacing.s2),
                FilledButton(
                  style: TeacherWebUi.compactFilledStyle(context),
                  onPressed: _publish,
                  child: Text(l10n.teacherExamPublish),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _skillsRegion() {
    final children = TeacherIntegratedExamEditorPage.skillOrder.map(_buildSkillCard).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == children.length - 1 ? 0 : AppSpacing.s3),
            child: children[i],
          ),
      ],
    );
  }

  void _setWritingFixedPrompt(Map<String, dynamic>? prompt) {
    _bloc.add(TeacherIntegratedExamEditorWritingFixedPromptChanged(prompt));
  }

  static const _writingAiTaskTypes = [
    'Essay',
    'Agree or Disagree',
    'Discuss both views',
    'Problem and Solution',
    'Advantages and Disadvantages',
    'Report',
  ];

  static const _writingAiTaskTypeAny = '__any__';

  Future<String?> _pickWritingAiTaskType() async {
    final l10n = context.l10n;
    var selected = _writingAiTaskTypeAny;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(l10n.teacherExamWritingAiPickTaskTypeTitle),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.teacherExamWritingAiPickTaskTypeHint, style: ExamSystemUi.captionSecondary),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selected,
                      items: [
                        DropdownMenuItem(
                          value: _writingAiTaskTypeAny,
                          child: Text(l10n.teacherExamWritingAiTaskTypeAny),
                        ),
                        ..._writingAiTaskTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setLocal(() => selected = v);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx, selected == _writingAiTaskTypeAny ? null : selected);
              },
              child: Text(l10n.teacherExamWritingGenerateWithAI),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateWritingPromptOptions() async {
    final l10n = context.l10n;
    final resources = _getResources(_s.skillSection['writing'] ?? {});
    final topicId = resources.isNotEmpty ? resources.first['id'] as String? : null;
    final topicName = (topicId == null || topicId.isEmpty)
        ? (_s.title.trim().isNotEmpty ? _s.title.trim() : null)
        : null;
    if ((topicId == null || topicId.isEmpty) && (topicName == null || topicName.isEmpty)) {
      AppCornerToast.show(context, l10n.teacherExamWritingAiNeedTopicOrTitle, error: true);
      return;
    }
    final taskType = await _pickWritingAiTaskType();
    if (!mounted) return;
    _bloc.add(TeacherIntegratedExamEditorWritingGenerateRequested(
      topicId: topicId,
      topicName: topicName,
      taskType: taskType,
    ));
  }

  static void _showWritingPromptPickDialog(BuildContext context, List<Map<String, dynamic>> options) {
    final l10n = context.l10n;
    final bloc = context.read<TeacherIntegratedExamEditorBloc>();
    showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_outlined, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(l10n.teacherExamWritingPickPromptTitle, style: ExamSystemUi.sectionTitle(ctx)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_outlined),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: Text(l10n.teacherExamWritingPickPromptSubtitle, style: ExamSystemUi.captionSecondary),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: [
                        for (var i = 0; i < options.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          _TeacherIntegratedExamEditorViewState._buildPromptOptionTile(ctx, options[i], i + 1),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((picked) {
      if (picked != null) {
        bloc.add(TeacherIntegratedExamEditorWritingFixedPromptChanged(picked));
      }
    });
  }

  static Widget _buildPromptOptionTile(BuildContext ctx, Map<String, dynamic> prompt, int index) {
    final title = (prompt['title'] as String?)?.trim() ?? '';
    final text = (prompt['text'] as String?)?.trim() ?? '';
    final taskType = (prompt['taskType'] as String?)?.trim() ?? '';
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.pop(ctx, prompt),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.outlineMuted),
                    ),
                    child: Text(
                      '$index',
                      style: TeacherWebUi.webCaption(ctx).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title.isNotEmpty ? title : 'Option $index', style: ExamSystemUi.listTitle(ctx)),
                  ),
                  if (taskType.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.outlineMuted),
                      ),
                      child: Text(taskType, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ),
                ],
              ),
              if (text.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(text, style: ExamSystemUi.captionSecondary.copyWith(height: 1.5), maxLines: 6, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  style: TeacherWebUi.compactOutlinedStyle(ctx),
                  onPressed: () => Navigator.pop(ctx, prompt),
                  child: Text(ctx.l10n.teacherExamWritingSelectThisPrompt),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showWritingPromptManualDialog() async {
    final l10n = context.l10n;
    final titleCtrl = TextEditingController();
    final textCtrl = TextEditingController();
    final existing = _getWritingFixedPrompt();
    if (existing != null) {
      titleCtrl.text = (existing['title'] as String?) ?? '';
      textCtrl.text = (existing['text'] as String?) ?? '';
    }
    Map<String, dynamic>? picked;
    try {
      picked = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        String selectedTaskType = (existing?['taskType'] as String?)?.trim() ?? 'Essay';
        if (!['Essay', 'Agree or Disagree', 'Discuss both views', 'Problem and Solution', 'Advantages and Disadvantages', 'Report'].contains(selectedTaskType)) {
          selectedTaskType = 'Essay';
        }
        return StatefulBuilder(
          builder: (ctx, setLocal) => Dialog(
            backgroundColor: AppColors.surfaceCard,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 560,
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(l10n.teacherExamWritingManualPromptTitle, style: ExamSystemUi.sectionTitle(ctx)),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_outlined),
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.teacherExamWritingPromptTitleLabel, style: ExamSystemUi.captionMuted),
                            const SizedBox(height: 6),
                            TextField(
                              controller: titleCtrl,
                              decoration: InputDecoration(
                                hintText: l10n.teacherExamWritingPromptTitleHint,
                                filled: true,
                                fillColor: AppColors.surface,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: AppColors.outline),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(l10n.teacherExamWritingPromptTaskTypeLabel, style: ExamSystemUi.captionMuted),
                            const SizedBox(height: 6),
                            InputDecorator(
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.surface,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: AppColors.outline),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: selectedTaskType,
                                  items: const [
                                    DropdownMenuItem(value: 'Essay', child: Text('Essay')),
                                    DropdownMenuItem(value: 'Agree or Disagree', child: Text('Agree or Disagree')),
                                    DropdownMenuItem(value: 'Discuss both views', child: Text('Discuss both views')),
                                    DropdownMenuItem(value: 'Problem and Solution', child: Text('Problem and Solution')),
                                    DropdownMenuItem(value: 'Advantages and Disadvantages', child: Text('Advantages and Disadvantages')),
                                    DropdownMenuItem(value: 'Report', child: Text('Report')),
                                  ],
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setLocal(() => selectedTaskType = v);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(l10n.teacherExamWritingPromptTextLabel, style: ExamSystemUi.captionMuted),
                            const SizedBox(height: 6),
                            TextField(
                              controller: textCtrl,
                              minLines: 5,
                              maxLines: 12,
                              decoration: InputDecoration(
                                hintText: l10n.teacherExamWritingPromptTextHint,
                                filled: true,
                                fillColor: AppColors.surface,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: AppColors.outline),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                alignLabelWithHint: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(l10n.cancel),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: () {
                            final text = textCtrl.text.trim();
                            if (text.isEmpty) {
                              AppCornerToast.show(ctx, l10n.teacherExamWritingPromptTextRequired, error: true);
                              return;
                            }
                            Navigator.pop(ctx, {
                              'title': titleCtrl.text.trim().isNotEmpty
                                  ? titleCtrl.text.trim()
                                  : l10n.teacherExamWritingCustomPrompt,
                              'text': text,
                              'taskType': selectedTaskType,
                              'level': (existing?['level'] as String?) ?? 'Intermediate',
                            });
                          },
                          child: Text(l10n.save),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    } finally {
      titleCtrl.dispose();
      textCtrl.dispose();
    }
    if (picked != null && mounted) _setWritingFixedPrompt(picked);
  }

  Widget _buildWritingPromptSubSection(bool draft) {
    final l10n = context.l10n;
    final prompt = _getWritingFixedPrompt();
    final resources = _getResources(_s.skillSection['writing'] ?? {});
    final hasResources = resources.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.s3),
        Row(
          children: [
            const Icon(Icons.assignment_outlined, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.teacherExamWritingPromptSectionTitle,
                style: TeacherWebUi.webCaption(context).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (prompt != null && draft)
              IconButton(
                onPressed: _showWritingPromptManualDialog,
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppColors.textSecondary,
                tooltip: l10n.edit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            if (prompt != null && draft)
              IconButton(
                onPressed: () => _setWritingFixedPrompt(null),
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.textSecondary,
                tooltip: l10n.delete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (prompt != null)
          _buildPromptPreviewCard(prompt)
        else if (draft)
          _buildPromptEmptyState(l10n, hasResources)
        else
          _buildPromptMissingWarning(l10n),
      ],
    );
  }

  Widget _buildPromptPreviewCard(Map<String, dynamic> prompt) {
    final title = (prompt['title'] as String?)?.trim() ?? '';
    final text = (prompt['text'] as String?)?.trim() ?? '';
    final taskType = (prompt['taskType'] as String?)?.trim() ?? '';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.article_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title.isNotEmpty ? title : context.l10n.teacherExamWritingCustomPrompt,
                  style: TeacherWebUi.listTitle(context),
                ),
              ),
              if (taskType.isNotEmpty)
                Text(taskType, style: TeacherWebUi.webCaption(context)),
            ],
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              text,
              style: TeacherWebUi.webBody(context),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPromptEmptyState(AppLocalizations l10n, bool hasResources) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _neutralHintBox(l10n.teacherExamWritingPromptEmptyHint),
        const SizedBox(height: AppSpacing.s3),
        Builder(
          builder: (context) {
            final titleReady = _s.title.trim().isNotEmpty;
            final canGenerate = hasResources || titleReady;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _s.writingPromptGenerating == true
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: AppLoadingIndicator(strokeWidth: 2),
                                ),
                              ),
                            )
                          : OutlinedButton.icon(
                              onPressed: canGenerate ? _generateWritingPromptOptions : null,
                              icon: const Icon(Icons.auto_awesome_outlined, size: 16),
                              label: Text(l10n.teacherExamWritingGenerateWithAI),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showWritingPromptManualDialog,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text(l10n.teacherExamWritingWriteManually),
                      ),
                    ),
                  ],
                ),
                if (!hasResources && !titleReady)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      l10n.teacherExamWritingAiNeedTopicOrTitle,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPromptMissingWarning(AppLocalizations l10n) {
    return _neutralHintBox(l10n.teacherExamWritingPromptNotSet);
  }

  Widget _buildSkillCard(String skill) {
    final on = _s.skillIncluded[skill] == true;
    final sec = _s.skillSection[skill] ?? teacherIntegratedExamEditorEmptySkillSection(skill, 0);
    final resources = _getResources(sec);
    final canEdit = _s.canEditSkillContent;
    final l10n = context.l10n;

    // For listening, count across both sub-types for the subtitle.
    final listeningCompRes = skill == 'listening'
        ? teacherIntegratedExamEditorGetCompResources(sec)
        : <Map<String, dynamic>>[];
    final totalListeningCount = resources.length + listeningCompRes.length;

    return DecoratedBox(
      decoration: TeacherWebUi.cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildSkillHeaderIcon(skill),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_skillLabel(skill), style: TeacherWebUi.listTitle(context)),
                      if (on && (skill != 'listening' ? resources.isNotEmpty : totalListeningCount > 0))
                        Text(
                          '${skill == 'listening' ? totalListeningCount : resources.length} ${l10n.teacherExamSkillsExercisesSelected}',
                          style: TeacherWebUi.webCaption(context),
                        ),
                    ],
                  ),
                ),
                _compactSectionSwitch(
                  value: on,
                  onChanged: _s.examStatus == 'draft'
                      ? (v) => _bloc.add(TeacherIntegratedExamEditorSkillIncludedChanged(skill: skill, included: v))
                      : null,
                ),
              ],
            ),
            if (on) ...[
              const SizedBox(height: AppSpacing.s3),
              if (!_skillMeetsPublishRequirement(skill))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                  child: _publishHintBanner(
                    skill == 'writing'
                        ? l10n.teacherExamWritingPublishNeedPrompt
                        : skill == 'speaking'
                            ? l10n.teacherExamSpeakingExerciseRequired
                            : l10n.teacherExamPublishPickEachIncludedSkill,
                  ),
                ),
              if (skill == 'listening')
                _buildListeningBody(sec, canEdit)
              else ...[
                for (var i = 0; i < resources.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.s2),
                  _buildResourceRow(skill: skill, idx: i, res: resources[i], draft: canEdit),
                ],
                if (canEdit) ...[
                  const SizedBox(height: AppSpacing.s3),
                  _buildAddExerciseAction(onPressed: () => _pickAt(skill)),
                ],
              ],
              if (skill == 'writing') _buildWritingPromptSubSection(canEdit),
            ],
          ],
        ),
      ),
    );
  }

  /// Two parallel sub-sections for Dictation and Comprehension.
  Widget _buildListeningBody(Map<String, dynamic> sec, bool canEdit) {
    final l10n = context.l10n;
    final dictRes = _getResources(sec);
    final compRes = teacherIntegratedExamEditorGetCompResources(sec);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildListeningSubTypeSection(
          label: l10n.teacherExamListeningTypeDictation,
          icon: Icons.text_fields_outlined,
          hint: l10n.teacherExamListeningTypeDictationHint,
          resources: dictRes,
          canEdit: canEdit,
          subType: 'dictation',
        ),
        const SizedBox(height: AppSpacing.s3),
        _buildListeningSubTypeSection(
          label: l10n.teacherExamListeningTypeComprehension,
          icon: Icons.headphones_outlined,
          hint: l10n.teacherExamListeningTypeComprehensionHint,
          resources: compRes,
          canEdit: canEdit,
          subType: 'comprehension',
        ),
      ],
    );
  }

  Widget _buildListeningSubTypeSection({
    required String label,
    required IconData icon,
    required String hint,
    required List<Map<String, dynamic>> resources,
    required bool canEdit,
    required String subType,
  }) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: TeacherWebUi.webCaption(context).copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 2),
        Text(hint, style: TeacherWebUi.webCaption(context)),
        if (resources.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s2),
          for (var i = 0; i < resources.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.s2),
            _buildResourceRow(
              skill: 'listening',
              idx: i,
              res: resources[i],
              draft: canEdit,
              listeningSubType: subType,
            ),
          ],
        ],
        if (canEdit) ...[
          const SizedBox(height: AppSpacing.s2),
          _buildAddExerciseAction(onPressed: () => _pickListeningSubType(subType)),
        ],
      ],
    );
  }

  Future<void> _pickListeningSubType(String subType) async {
    final l10n = context.l10n;
    List<({String id, String title})>? picks;

    final pickSkill = subType == 'comprehension' ? 'listening_comp' : 'listening';
    final sec = _s.skillSection['listening'] ?? {};
    final currentIds = subType == 'comprehension'
        ? teacherIntegratedExamEditorGetCompResources(sec).map((r) => r['id'] as String? ?? '').toSet()
        : _getResources(sec).map((r) => r['id'] as String? ?? '').toSet();

    void navigateCreateNew(BuildContext dialogCtx) {
      Navigator.of(dialogCtx).pop();
      context.push('/teacher/content/listening/new');
    }

    if (_useWebLayout()) {
      picks = await showDialog<List<({String id, String title})>>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.surfaceCard,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: math.min(MediaQuery.sizeOf(ctx).height * 0.85, 640),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(l10n.teacherExamIntegratedChooseExercise,
                            style: ExamSystemUi.sectionTitle(context)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_outlined),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _SkillPickPanel(
                      skill: pickSkill,
                      alreadySelectedIds: currentIds,
                      useWebListLayout: true,
                      onConfirmMulti: (items) => Navigator.pop(ctx, items),
                      onCreateNew: pickSkill == 'listening_comp' ? null : () => navigateCreateNew(ctx),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      picks = await showModalBottomSheet<List<({String id, String title})>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surfaceCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (_, sc) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.outlineMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(l10n.teacherExamIntegratedChooseExercise,
                    style: ExamSystemUi.sectionTitle(context)),
                const SizedBox(height: 8),
                Expanded(
                  child: _SkillPickPanel(
                    skill: pickSkill,
                    alreadySelectedIds: currentIds,
                    useWebListLayout: false,
                    scrollController: sc,
                    onConfirmMulti: (items) => Navigator.pop(ctx, items),
                    onCreateNew: pickSkill == 'listening_comp' ? null : () => navigateCreateNew(ctx),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (picks != null && picks.isNotEmpty && mounted) {
      for (final item in picks) {
        _bloc.add(TeacherIntegratedExamEditorSkillResourceAdded(
          skill: 'listening',
          resourceId: item.id,
          resourceTitle: item.title,
          listeningSubType: subType,
        ));
      }
    }
  }

  Widget _buildResourceRow({
    required String skill,
    required int idx,
    required Map<String, dynamic> res,
    required bool draft,
    String? listeningSubType,
  }) {
    final title = res['title'] as String? ?? '';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineMuted),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.outlineMuted),
            ),
            child: Text(
              '${idx + 1}',
              style: TeacherWebUi.webCaption(context).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title.isEmpty ? '—' : title,
              style: TeacherWebUi.webBody(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (draft)
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => _removeResource(skill, idx, listeningSubType: listeningSubType),
              icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }

  // ── Grammar Import ──────────────────────────────────────────────────────

  /// Validates one raw JSON object and returns a clean grammar item map,
  /// or null if the object is invalid / missing required fields.
  Map<String, dynamic>? _validateImportedItem(Map<String, dynamic> m, int idx) {
    final kind = m['kind'] as String?;
    final pts = int.tryParse('${m['points'] ?? 1}') ?? 1;
    final id = 'gram_import_${DateTime.now().millisecondsSinceEpoch}_$idx';

    switch (kind) {
      case 'mcq_single':
      case 'mcq_multi':
        final opts = (m['options'] as List?)?.map((e) => '$e').where((s) => s.isNotEmpty).toList();
        final correct = (m['correctOptionIndexes'] as List?)?.map((e) => int.tryParse('$e') ?? 0).toList();
        final prompt = '${m['prompt'] ?? ''}'.trim();
        if (prompt.isEmpty || opts == null || opts.length < 2 || correct == null || correct.isEmpty) return null;
        return {
          ...m,
          'itemId': id,
          'kind': kind,
          'prompt': prompt,
          'options': opts,
          'correctOptionIndexes': correct,
          'points': pts,
        };

      case 'grammar_cloze':
        final passage = '${m['passage'] ?? ''}'.trim();
        final blanks = m['blanks'] as List?;
        if (passage.isEmpty || blanks == null || blanks.isEmpty) return null;
        if (!RegExp(r'\{\{[0-9]+\}\}').hasMatch(passage)) return null;
        return {...m, 'itemId': id, 'points': pts};

      case 'grammar_gap':
        final before = '${m['textBefore'] ?? ''}'.trim();
        final after = '${m['textAfter'] ?? ''}'.trim();
        final blanks = m['blanks'] as List?;
        if (before.isEmpty || after.isEmpty || blanks == null || blanks.isEmpty) return null;
        return {...m, 'itemId': id, 'points': pts};

      case 'grammar_matching':
        final left = m['leftItems'] as List?;
        final right = m['rightItems'] as List?;
        final pairs = m['correctPairs'] as List?;
        if (left == null || left.length < 2 || right == null || right.isEmpty || pairs == null) return null;
        return {...m, 'itemId': id, 'points': pts};

      case 'grammar_reorder':
        final fragments = m['fragments'] as List?;
        final order = m['correctOrder'] as List?;
        if (fragments == null || fragments.length < 2 || order == null || order.length != fragments.length) return null;
        return {...m, 'itemId': id, 'points': pts};

      default:
        return null;
    }
  }

  Future<void> _importGrammarQuestions() async {
    if (_s.examStatus != 'draft') return;
    final l10n = context.l10n;

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
        withData: true,
      );
    } catch (_) {
      if (!mounted) return;
      AppCornerToast.show(context, l10n.teacherExamGrammarImportError, error: true);
      return;
    }

    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) {
      if (!mounted) return;
      AppCornerToast.show(context, l10n.teacherExamGrammarImportError, error: true);
      return;
    }

    try {
      final jsonStr = utf8.decode(bytes);
      final dynamic parsed = jsonDecode(jsonStr);
      if (parsed is! List) throw const FormatException('Root must be a JSON array');

      final imported = <Map<String, dynamic>>[];
      for (var i = 0; i < parsed.length; i++) {
        final item = parsed[i];
        if (item is! Map) continue;
        final validated = _validateImportedItem(Map<String, dynamic>.from(item), i);
        if (validated != null) imported.add(validated);
      }

      if (!mounted) return;
      if (imported.isEmpty) {
        AppCornerToast.show(context, l10n.teacherExamGrammarImportEmpty, error: true);
        return;
      }

      _bloc.add(TeacherIntegratedExamEditorGrammarImportAppended(imported));
      AppCornerToast.show(context, l10n.teacherExamGrammarImportSuccess(imported.length));
    } catch (_) {
      if (!mounted) return;
      AppCornerToast.show(context, l10n.teacherExamGrammarImportError, error: true);
    }
  }

  Future<void> _showImportFormatDialog() async {
    final l10n = context.l10n;
    String sampleJson;
    try {
      sampleJson = await rootBundle.loadString('assets/samples/grammar_import_sample.json');
    } catch (_) {
      // Stale web build or missing asset — still show a minimal valid example.
      sampleJson = _grammarImportSampleFallback;
    }
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: math.min(MediaQuery.sizeOf(ctx).height * 0.88, 760),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(l10n.teacherExamGrammarImportFormatTitle, style: ExamSystemUi.sectionTitle(ctx)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_outlined),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final kind in ['mcq_single', 'mcq_multi', 'grammar_cloze', 'grammar_gap', 'grammar_matching', 'grammar_reorder'])
                      Chip(
                        label: Text(kind, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.outlineMuted),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineMuted),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        sampleJson,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace', height: 1.5, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: sampleJson));
                        if (!ctx.mounted) return;
                        AppCornerToast.show(ctx, l10n.teacherExamGrammarDownloadSample);
                      },
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      label: Text(l10n.teacherExamGrammarDownloadSample),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _importGrammarQuestions();
                      },
                      icon: const Icon(Icons.upload_file_outlined, size: 18),
                      label: Text(l10n.teacherExamGrammarImportPickFile),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── End Grammar Import ───────────────────────────────────────────────────

  Widget _grammarPanel() {
    final l10n = context.l10n;
    final on = _s.grammarIncluded;
    final subtitle = on && _s.grammarItems.isNotEmpty
        ? l10n.teacherExamGrammarQuestionCount(_s.grammarItems.length)
        : (on ? l10n.teacherExamGrammarHint : null);

    return DecoratedBox(
      decoration: TeacherWebUi.cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outlineMuted),
                  ),
                  child: const Icon(Icons.spellcheck_outlined, size: 18, color: AppColors.textSecondary),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.teacherExamGrammarTitle, style: TeacherWebUi.listTitle(context)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle, style: TeacherWebUi.webCaption(context), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                _compactSectionSwitch(
                  value: on,
                  onChanged: _s.canEditSkillContent
                      ? (v) {
                          _bloc.add(TeacherIntegratedExamEditorGrammarIncludedChanged(v));
                          if (!v) {
                            _bloc.add(const TeacherIntegratedExamEditorGrammarEditorIndexChanged(null));
                          }
                        }
                      : null,
                ),
              ],
            ),
            if (on) ...[
              const SizedBox(height: AppSpacing.s3),
              Row(
                children: [
                  if (_s.canEditSkillContent) ...[
                    OutlinedButton.icon(
                      style: TeacherWebUi.compactOutlinedStyle(context),
                      onPressed: _showImportFormatDialog,
                      icon: const Icon(Icons.upload_file_outlined, size: 16),
                      label: Text(l10n.teacherExamGrammarImport),
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    FilledButton.icon(
                      style: TeacherWebUi.compactFilledStyle(context),
                      onPressed: () => _openGrammarEditor(),
                      icon: const Icon(Icons.add_outlined, size: 16),
                      label: Text(l10n.teacherExamGrammarAdd),
                    ),
                  ],
                ],
              ),
              if (_s.grammarItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s3),
                  child: _neutralHintBox(l10n.teacherExamSkillsNoGrammarYet),
                )
              else ...[
                const SizedBox(height: AppSpacing.s3),
                ...List.generate(_s.grammarItems.length, (index) {
                  final it = _s.grammarItems[index];
                  final kind = '${it['kind'] ?? ''}';
                  return Column(
                    children: [
                      if (index > 0) const Divider(height: 1, color: AppColors.outlineMuted),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _s.examStatus == 'draft' ? () => _openGrammarEditor(editIndex: index) : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 24,
                                  child: Text('${index + 1}.', style: TeacherWebUi.webCaption(context)),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_grammarKindLabel(kind), style: TeacherWebUi.webCaption(context).copyWith(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(
                                        _grammarPreview(it),
                                        style: TeacherWebUi.webBody(context),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Text('${it['points'] ?? 1}pt', style: TeacherWebUi.webCaption(context)),
                                if (_s.examStatus == 'draft')
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                                    onPressed: () => _removeGrammarAt(index),
                                    icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TeacherIntegratedExamEditorBloc, TeacherIntegratedExamEditorState>(
      listenWhen: (prev, curr) =>
          prev.title != curr.title &&
          curr.status == TeacherIntegratedExamEditorStatus.success &&
          _titleController.text != curr.title,
      listener: (_, state) {
        _titleController.value = TextEditingValue(
          text: state.title,
          selection: TextSelection.collapsed(offset: state.title.length),
        );
      },
      child: BlocBuilder<TeacherIntegratedExamEditorBloc, TeacherIntegratedExamEditorState>(
        builder: (context, state) => _buildScaffold(context, state),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, TeacherIntegratedExamEditorState state) {
    final l10n = context.l10n;
    final sticky = _webStickyActions(context);
    final pageTitle = _displayTitle(l10n);
    final loading = state.status == TeacherIntegratedExamEditorStatus.loading ||
        state.status == TeacherIntegratedExamEditorStatus.initial;
    return TeacherPageScaffold(
      title: pageTitle,
      showBack: true,
      scrollable: false,
      maxWidth: TeacherWebUi.contentMaxTable,
      breadcrumbs: [
        TeacherBreadcrumb(label: l10n.teacherNavDashboard, location: TeacherDashboardPage.routePath),
        TeacherBreadcrumb(label: l10n.teacherNavExams, location: TeacherExamsListPage.routePath),
        TeacherBreadcrumb(label: pageTitle),
      ],
      actions: [
        if (!_useWebLayout() && _s.canEditSkillContent) ...[
          TextButton(
            onPressed: _saveDraft,
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            child: Text(l10n.teacherExamSaveDraft),
          ),
          if (_s.examStatus == 'draft')
            TeacherFilledButton(label: l10n.teacherExamPublish, onPressed: _publish),
        ],
        IconButton(
          onPressed: _reload,
          icon: const Icon(Icons.refresh_outlined),
          iconSize: ExamSystemUi.iconSm,
          color: AppColors.textSecondary,
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: loading
                ? const Center(child: AppLoadingIndicator.center())
                : state.errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: ExamSystemUi.pagePadding,
                          child: Text(state.errorMessage!, style: ExamSystemUi.captionSecondary),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final maxW = math.min(constraints.maxWidth, _useWebLayout() ? ExamSystemUi.webTeacherContentMaxWidth : constraints.maxWidth);
                          final hPad = _useWebLayout() ? 32.0 : ExamSystemUi.hPadding.toDouble();
                          final showEditor = _useWebLayout() && state.examStatus == 'draft' && state.grammarEditorIndex != null;

                          Widget mainColumn() {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (state.examStatus != 'draft')
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                                    child: _neutralHintBox(l10n.teacherExamReadOnlyPublished),
                                  ),
                                Text(
                                  l10n.teacherExamTitleLabel,
                                  style: TeacherWebUi.webTableHead(context),
                                ),
                                const SizedBox(height: AppSpacing.s2),
                                TextField(
                                  controller: _titleController,
                                  onChanged: (v) => _bloc.add(TeacherIntegratedExamEditorTitleChanged(v)),
                                  enabled: state.examStatus == 'draft',
                                  style: TeacherWebUi.webBody(context).copyWith(fontWeight: FontWeight.w600),
                                  decoration: TeacherWebUi.formInputDecoration(
                                    context,
                                    hintText: l10n.teacherExamTitleHint,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s5),
                                _grammarPanel(),
                                const SizedBox(height: AppSpacing.s5),
                                Text(l10n.teacherExamSkillsPartsTitle, style: TeacherWebUi.sectionTitle(context)),
                                const SizedBox(height: AppSpacing.s2),
                                Text(
                                  l10n.teacherExamPublishPickEachIncludedSkill,
                                  style: TeacherWebUi.webCaption(context),
                                ),
                                const SizedBox(height: AppSpacing.s3),
                                _skillsRegion(),
                              ],
                            );
                          }

                          final scroll = SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(hPad, AppSpacing.s4, hPad, _useWebLayout() ? 88 : AppSpacing.s5),
                            child: showEditor ? mainColumn() : SizedBox(width: maxW, child: mainColumn()),
                          );

                          return Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: math.min(constraints.maxWidth, showEditor ? 1180 : maxW)),
                              child: showEditor
                                  ? Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 5,
                                          child: scroll,
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Padding(
                                            padding: const EdgeInsets.only(top: 24, right: 8, bottom: 100),
                                            child: SizedBox(
                                              height: math.max(480.0, constraints.maxHeight - 48),
                                              child: Material(
                                                elevation: 2,
                                                shadowColor: Colors.black12,
                                                color: AppColors.surfaceCard,
                                                clipBehavior: Clip.antiAlias,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  side: const BorderSide(color: AppColors.outline),
                                                ),
                                                child: TeacherSkillsExamGrammarEditorPanel(
                                                  initial: _s.grammarEditorIndex == -1 ? null : _s.grammarItems[_s.grammarEditorIndex!],
                                                  onSave: _onGrammarSaved,
                                                  onClose: _closeGrammarEditor,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : SizedBox(width: maxW, child: scroll),
                            ),
                          );
                        },
                      ),
          ),
          if (sticky != null) sticky,
        ],
      ),
    );
  }
}

/// Picks one CMS item for a skill — list scroll; used in web dialog or mobile sheet.
class _SkillPickPanel extends StatefulWidget {
  const _SkillPickPanel({
    required this.skill,
    required this.alreadySelectedIds,
    this.useWebListLayout = false,
    this.onCreateNew,
    this.scrollController,
    this.onConfirmMulti,
  });

  final String skill;
  final Set<String> alreadySelectedIds;
  final bool useWebListLayout;
  final VoidCallback? onCreateNew;
  final ScrollController? scrollController;
  /// Called with the list of selected items when confirmed.
  final void Function(List<({String id, String title})> items)? onConfirmMulti;

  @override
  State<_SkillPickPanel> createState() => _SkillPickPanelState();
}

class _SkillPickPanelState extends State<_SkillPickPanel> {
  late Future<List<({String id, String title})>> _future;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<({String id, String title})>> _load() async {
    switch (widget.skill) {
      case 'listening':
        final r = await getIt<ListeningRepository>().getListenings(page: 1, limit: 100);
        return r.fold((_) => [], (page) {
          return page.data.map((e) => (id: e.id, title: e.title)).toList();
        });
      case 'listening_comp':
        final r = await getIt<ListeningCompRepository>().getListenings(page: 1, limit: 100);
        return r.fold((_) => [], (page) {
          return page.data.map((e) => (id: e.id, title: e.title)).toList();
        });
      case 'speaking':
        final repo = getIt<SpeakingRepository>();
        final levels = ['Beginner', 'Intermediate', 'Advanced'];
        final seen = <String>{};
        final out = <({String id, String title})>[];
        for (final mode in SpeakingMode.values) {
          for (final lv in levels) {
            final r = await repo.getSpeakingSets(mode: mode, level: lv, page: 1, limit: 40);
            r.fold((_) {}, (page) {
              for (final s in page.data) {
                if (seen.add(s.id)) out.add((id: s.id, title: s.title));
              }
            });
          }
        }
        return out;
      case 'reading':
        final seen = <String>{};
        final out = <({String id, String title})>[];
        for (final diff in ['easy', 'medium', 'hard']) {
          final r = await getIt<ReadingRepository>().getReadingListWithProgress(difficulty: diff, page: 1, limit: 60);
          r.fold((_) {}, (page) {
            for (final e in page.data) {
              if (seen.add(e.id)) out.add((id: e.id, title: e.title));
            }
          });
        }
        return out;
      case 'writing':
        final r = await getIt<WritingRepository>().getWritingTopics();
        return r.fold((_) => [], (list) {
          return list.map((e) => (id: e.id, title: e.name)).toList();
        });
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<List<({String id, String title})>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: AppLoadingIndicator.center());
        }
        final allItems = snap.data ?? [];
        final available = allItems.where((it) => !widget.alreadySelectedIds.contains(it.id)).toList();
        final allAlreadyAdded = allItems.isNotEmpty && available.isEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.onCreateNew != null) ...[
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: widget.onCreateNew,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.add_circle_outline, size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.teacherExamSkillsCreateNew,
                            style: ExamSystemUi.captionSecondary,
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 13, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 20),
            ],
            if (widget.alreadySelectedIds.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final id in widget.alreadySelectedIds)
                      Builder(builder: (ctx) {
                        final match = allItems.where((it) => it.id == id).firstOrNull;
                        if (match == null) return const SizedBox.shrink();
                        return Chip(
                          avatar: const Icon(Icons.check_circle, size: 14, color: AppColors.textSecondary),
                          label: Text(
                            match.title,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          visualDensity: VisualDensity.compact,
                          side: const BorderSide(color: AppColors.outlineMuted),
                          backgroundColor: AppColors.surface,
                        );
                      }),
                  ],
                ),
              ),
            ],
            if (allAlreadyAdded)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(l10n.teacherExamSkillsAllAdded, style: ExamSystemUi.captionMuted),
                ),
              )
            else if (available.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(l10n.teacherExamIntegratedEmptyList, style: ExamSystemUi.captionSecondary),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: widget.scrollController,
                  itemCount: available.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final it = available[i];
                    final isChecked = _selected.contains(it.id);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: Checkbox(
                        value: isChecked,
                        onChanged: (_) => _toggleItem(it.id),
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        visualDensity: VisualDensity.compact,
                      ),
                      title: Text(it.title, style: ExamSystemUi.listTitle(context)),
                      onTap: () => _toggleItem(it.id),
                    );
                  },
                ),
              ),
            if (_selected.isNotEmpty && available.isNotEmpty) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  final items = available.where((it) => _selected.contains(it.id)).toList();
                  widget.onConfirmMulti?.call(items);
                },
                style: TeacherWebUi.compactFilledStyle(context),
                icon: const Icon(Icons.check, size: 16),
                label: Text(l10n.teacherExamPickerAddSelected(_selected.length)),
              ),
            ],
          ],
        );
      },
    );
  }

  void _toggleItem(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }
}
