import 'dart:convert';
import 'dart:math' as math;

import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle, Clipboard, ClipboardData;
import 'package:english_for_community/core/repository/listening_repository.dart';
import 'package:english_for_community/core/repository/reading_repository.dart';
import 'package:english_for_community/core/repository/speaking_repository.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/repository/writing_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/feature/speaking/speaking_hub_page.dart';
import 'package:english_for_community/feature/teacher/teacher_skills_exam_grammar_editor_panel.dart';
import 'package:english_for_community/core/ui/workspace_layout_scope.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_page_scaffold.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/teacher_dashboard_page.dart';
import 'package:english_for_community/feature/teacher/teacher_exams_list_page.dart';
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
class TeacherIntegratedExamEditorPage extends StatefulWidget {
  const TeacherIntegratedExamEditorPage({super.key, required this.examId});

  final String examId;

  static const String routePathPrefix = '/teacher/exams';

  static const List<String> skillOrder = ['reading', 'listening', 'writing', 'speaking'];
  static const Map<String, String> sectionIdsForSkill = {
    'listening': 'sec_listening',
    'speaking': 'sec_speaking',
    'reading': 'sec_reading',
    'writing': 'sec_writing',
  };

  @override
  State<TeacherIntegratedExamEditorPage> createState() => _TeacherIntegratedExamEditorPageState();
}

class _TeacherIntegratedExamEditorPageState extends State<TeacherIntegratedExamEditorPage> {
  bool _loading = true;
  String? _error;
  String _status = 'draft';
  final _title = TextEditingController();
  final Map<String, bool> _skillIncluded = {};
  final Map<String, Map<String, dynamic>> _skillSection = {};
  List<Map<String, dynamic>> _grammarItems = [];
  bool _grammarIncluded = false;

  bool _writingPromptGenerating = false;

  /// Web: `null` = closed, `-1` = new question, `>= 0` = edit index.
  int? _grammarEditorIndex;

  String _displayTitle(AppLocalizations l10n) {
    final t = _title.text.trim();
    return t.isNotEmpty ? t : l10n.teacherExamUntitled;
  }

  void _onTitleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _title.removeListener(_onTitleChanged);
    _title.dispose();
    super.dispose();
  }

  bool _useWebLayout() => WorkspaceLayoutScope.isWebWorkspace(context);

  static Map<String, dynamic> _emptySkillSection(String skill, int order) {
    return {
      'sectionId': TeacherIntegratedExamEditorPage.sectionIdsForSkill[skill]!,
      'sectionKind': 'skill_content',
      'skill': skill,
      'order': order,
      'title': '',
      'instructions': '',
      'resources': <Map<String, dynamic>>[],
      'items': <dynamic>[],
    };
  }

  void _initSkillMapsDefaults() {
    for (var i = 0; i < TeacherIntegratedExamEditorPage.skillOrder.length; i++) {
      final sk = TeacherIntegratedExamEditorPage.skillOrder[i];
      _skillIncluded[sk] = true;
      _skillSection[sk] = _emptySkillSection(sk, i);
    }
  }

  /// Returns the resources list for a skill section, with legacy fallback for
  /// old single-resource format (resourceId / resourceTitle).
  List<Map<String, dynamic>> _getResources(Map<String, dynamic> sec) {
    final raw = sec['resources'];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    final id = (sec['resourceId'] as String?)?.trim() ?? '';
    final title = (sec['resourceTitle'] as String?)?.trim() ?? '';
    if (id.isNotEmpty) return [{'id': id, 'title': title}];
    return [];
  }

  void _removeResource(String skill, int idx) {
    setState(() {
      final sec = _skillSection[skill];
      if (sec == null) return;
      final resources = _getResources(sec);
      resources.removeAt(idx);
      _skillSection[skill] = {...sec, 'resources': resources};
    });
  }

  @override
  void initState() {
    super.initState();
    _title.addListener(_onTitleChanged);
    _initSkillMapsDefaults();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await getIt<TeacherExamRepository>().getExam(widget.examId);
    if (!mounted) return;
    r.fold(
      (f) => setState(() {
        _error = f.message;
        _loading = false;
      }),
      (d) {
        final m = Map<String, dynamic>.from(d as Map);
        _status = (m['status'] as String?) ?? 'draft';
        var loadedTitle = (m['title'] as String?)?.trim() ?? '';
        // Legacy drafts used a fixed template title — treat as empty so GV can name the exam.
        if (loadedTitle == context.l10n.teacherExamIntegratedUntitled) {
          loadedTitle = '';
        }
        _title.text = loadedTitle;
        final raw = m['sections'] as List?;
        final settings = Map<String, dynamic>.from((m['settings'] as Map?) ?? {});

        for (final sk in TeacherIntegratedExamEditorPage.skillOrder) {
          _skillIncluded[sk] = false;
        }
        if (raw != null) {
          for (final e in raw) {
            final sec = Map<String, dynamic>.from(e as Map);
            final sk = sec['skill'] as String? ?? '';
            if (TeacherIntegratedExamEditorPage.skillOrder.contains(sk)) {
              _skillIncluded[sk] = true;
              // Legacy compat: convert single resourceId/resourceTitle → resources list
              if (!sec.containsKey('resources') || sec['resources'] == null) {
                final id = (sec['resourceId'] as String?)?.trim() ?? '';
                final title = (sec['resourceTitle'] as String?)?.trim() ?? '';
                sec['resources'] = id.isNotEmpty
                    ? [{'id': id, 'title': title}]
                    : <Map<String, dynamic>>[];
              }
              _skillSection[sk] = sec;
            }
          }
        }
        final fmt = settings['examFormat'] as String? ?? '';
        final gRaw = settings['grammarItems'];
        final hasGrammar = gRaw is List && gRaw.isNotEmpty;
        if (fmt == 'integrated_four_skills' || ((raw == null || raw.isEmpty) && !hasGrammar)) {
          for (final sk in TeacherIntegratedExamEditorPage.skillOrder) {
            _skillIncluded[sk] = true;
            _skillSection[sk] = _skillSection[sk] ?? _emptySkillSection(sk, TeacherIntegratedExamEditorPage.skillOrder.indexOf(sk));
          }
        }

        final g = settings['grammarItems'];
        if (g is List) {
          _grammarItems = g.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else {
          _grammarItems = [];
        }
        final grammarEnabled = settings['grammarEnabled'];
        _grammarIncluded = grammarEnabled == true || (grammarEnabled != false && _grammarItems.isNotEmpty);
        setState(() => _loading = false);
      },
    );
  }

  List<Map<String, dynamic>> _buildSectionsForSave() {
    var order = 0;
    final out = <Map<String, dynamic>>[];
    for (final sk in TeacherIntegratedExamEditorPage.skillOrder) {
      if (_skillIncluded[sk] != true) continue;
      final base = Map<String, dynamic>.from(_skillSection[sk] ?? _emptySkillSection(sk, order));
      final resources = _getResources(base);
      if (resources.isNotEmpty) {
        base['resources'] = resources;
        base['resourceId'] = resources.first['id']?.toString() ?? '';
        base['resourceTitle'] = resources.first['title']?.toString() ?? '';
      } else if (sk != 'writing') {
        base.remove('resourceId');
        base.remove('resourceTitle');
        base['resources'] = <Map<String, dynamic>>[];
      }
      if (sk == 'writing') {
        final prompt = _getWritingFixedPrompt();
        if (prompt != null) {
          base['fixedWritingPrompt'] = prompt;
        } else {
          base.remove('fixedWritingPrompt');
        }
      }
      base['order'] = order;
      out.add(base);
      order++;
    }
    return out;
  }

  Map<String, dynamic> _settingsForSave() {
    return {
      'examFormat': 'skills_exam',
      'showResultsPolicy': 'after_submit',
      'allowMultipleSubmissions': false,
      'grammarEnabled': _grammarIncluded,
      'grammarItems': _grammarIncluded ? _grammarItems : <Map<String, dynamic>>[],
    };
  }

  bool get _canEditSkillContent => _status == 'draft' || _status == 'published';

  bool _writingSkillReady() => _getWritingFixedPrompt() != null;

  bool _skillMeetsPublishRequirement(String sk) {
    if (_skillIncluded[sk] != true) return true;
    if (sk == 'writing') return _writingSkillReady();
    return _getResources(_skillSection[sk] ?? {}).isNotEmpty;
  }

  Future<bool> _saveDraft() async {
    if (!_canEditSkillContent) return false;
    final r = await getIt<TeacherExamRepository>().updateExamDraft(widget.examId, {
      'title': _title.text.trim(),
      'description': '',
      'settings': _settingsForSave(),
      'sections': _buildSectionsForSave(),
    });
    if (!mounted) return false;
    var ok = false;
    r.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.teacherExamDraftSaved)));
        ok = true;
      },
    );
    if (ok) await _load();
    return ok;
  }

  bool _publishValidation(BuildContext context) {
    final l10n = context.l10n;
    var anySkill = false;
    for (final sk in TeacherIntegratedExamEditorPage.skillOrder) {
      if (_skillIncluded[sk] != true) continue;
      if (!_skillMeetsPublishRequirement(sk)) {
        if (sk == 'writing') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.teacherExamWritingPublishNeedPrompt)),
          );
        } else if (sk == 'speaking') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.teacherExamSpeakingExerciseRequired)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.teacherExamPublishPickEachIncludedSkill)),
          );
        }
        return false;
      }
      anySkill = true;
    }
    if (_grammarIncluded && _grammarItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.teacherExamGrammarEnabledNoItems)),
      );
      return false;
    }
    final anyGrammar = _grammarIncluded && _grammarItems.isNotEmpty;
    if (!anySkill && !anyGrammar) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.teacherExamPublishNeedSelection)));
      return false;
    }
    if (anyGrammar) {
      var sum = 0;
      for (final it in _grammarItems) {
        sum += int.tryParse('${it['points'] ?? 1}') ?? 1;
      }
      if (anySkill && sum > 100) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.teacherExamGrammarPointsCap100)));
        return false;
      }
    }
    return true;
  }

  Future<void> _publish() async {
    if (!_publishValidation(context)) return;
    final saved = await _saveDraft();
    if (!saved || !mounted || _status != 'draft') return;
    final r = await getIt<TeacherExamRepository>().publishExam(widget.examId);
    if (!mounted) return;
    final l10n = context.l10n;
    r.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.teacherExamPublished)));
        context.pop();
      },
    );
  }

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

  Future<void> _pickAt(String skill) async {
    final l10n = context.l10n;
    Map<String, String>? picked;

    final currentIds = _getResources(_skillSection[skill] ?? {}).map((r) => r['id'] as String? ?? '').toSet();

    void navigateCreateNew(BuildContext dialogCtx) {
      Navigator.of(dialogCtx).pop();
      context.push('/teacher/content/$skill/new');
    }

    if (_useWebLayout()) {
      picked = await showDialog<Map<String, String>>(
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
                        skill: skill,
                        alreadySelectedIds: currentIds,
                        useWebListLayout: true,
                        onPick: (id, title) => Navigator.pop(ctx, {'id': id, 'title': title}),
                        onCreateNew: () => navigateCreateNew(ctx),
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
      picked = await showModalBottomSheet<Map<String, String>>(
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
                      skill: skill,
                      alreadySelectedIds: currentIds,
                      useWebListLayout: false,
                      scrollController: scroll,
                      onPick: (id, title) => Navigator.pop(ctx, {'id': id, 'title': title}),
                      onCreateNew: () => navigateCreateNew(ctx),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    if (picked == null || !mounted) return;
    final id = picked['id'];
    final title = picked['title'];
    if (id == null || title == null) return;
    setState(() {
      final sec = _skillSection[skill] ?? _emptySkillSection(skill, 0);
      final resources = _getResources(sec);
      if (!resources.any((r) => r['id'] == id)) {
        resources.add({'id': id, 'title': title});
        _skillSection[skill] = {...sec, 'resources': resources};
      }
    });
  }

  void _closeGrammarEditor() {
    setState(() => _grammarEditorIndex = null);
  }

  void _onGrammarSaved(Map<String, dynamic> m) {
    setState(() {
      if (_grammarEditorIndex == -1) {
        _grammarItems = [..._grammarItems, m];
      } else if (_grammarEditorIndex != null && _grammarEditorIndex! >= 0) {
        final next = [..._grammarItems];
        next[_grammarEditorIndex!] = m;
        _grammarItems = next;
      }
      _grammarEditorIndex = null;
    });
  }

  Future<void> _openGrammarEditor({int? editIndex}) async {
    if (_status != 'draft') return;
    if (_useWebLayout()) {
      setState(() => _grammarEditorIndex = editIndex ?? -1);
      return;
    }
    Map<String, dynamic>? initial;
    if (editIndex != null) initial = Map<String, dynamic>.from(_grammarItems[editIndex]);
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
              setState(() {
                if (editIndex == null) {
                  _grammarItems = [..._grammarItems, item];
                } else {
                  final n = [..._grammarItems];
                  n[editIndex] = item;
                  _grammarItems = n;
                }
              });
              Navigator.pop(ctx);
            },
            onClose: () => Navigator.pop(ctx),
          ),
        );
      },
    );
  }

  void _removeGrammarAt(int i) {
    setState(() {
      _grammarItems = [..._grammarItems]..removeAt(i);
      if (_grammarEditorIndex == i) {
        _grammarEditorIndex = null;
      } else if (_grammarEditorIndex != null && _grammarEditorIndex! > i) {
        _grammarEditorIndex = _grammarEditorIndex! - 1;
      }
    });
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
    if (!_useWebLayout() || !_canEditSkillContent || _loading || _error != null) return null;
    final l10n = context.l10n;
    return Material(
      elevation: 6,
      color: AppColors.surfaceCard,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _displayTitle(l10n),
                  style: ExamSystemUi.captionSecondary,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              OutlinedButton(
                onPressed: _saveDraft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(l10n.teacherExamSaveDraft),
                ),
              ),
              if (_status == 'draft') ...[
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _publish,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(l10n.teacherExamPublish),
                  ),
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
            padding: EdgeInsets.only(bottom: i == children.length - 1 ? 0 : 12),
            child: children[i],
          ),
      ],
    );
  }

  Map<String, dynamic>? _getWritingFixedPrompt() {
    final sec = _skillSection['writing'];
    if (sec == null) return null;
    final raw = sec['fixedWritingPrompt'];
    if (raw is Map && (raw['text'] as String?)?.isNotEmpty == true) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  void _setWritingFixedPrompt(Map<String, dynamic>? prompt) {
    setState(() {
      final sec = _skillSection['writing'] ?? _emptySkillSection('writing', 2);
      _skillSection['writing'] = {...sec, 'fixedWritingPrompt': prompt};
    });
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
    final resources = _getResources(_skillSection['writing'] ?? {});
    final topicId = resources.isNotEmpty ? resources.first['id'] as String? : null;
    final topicName = (topicId == null || topicId.isEmpty)
        ? (_title.text.trim().isNotEmpty ? _title.text.trim() : null)
        : null;
    if ((topicId == null || topicId.isEmpty) && (topicName == null || topicName.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.teacherExamWritingAiNeedTopicOrTitle)),
      );
      return;
    }
    final taskType = await _pickWritingAiTaskType();
    if (!mounted) return;

    setState(() => _writingPromptGenerating = true);
    final r = await getIt<TeacherExamRepository>().generateWritingPromptOptions(
      topicId: topicId,
      topicName: topicName,
      taskType: taskType,
    );
    if (!mounted) return;
    setState(() => _writingPromptGenerating = false);
    r.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
      (options) => _showWritingPromptPickDialog(options),
    );
  }

  void _showWritingPromptPickDialog(List<Map<String, dynamic>> options) {
    final l10n = context.l10n;
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
                          _buildPromptOptionTile(ctx, options[i], i + 1),
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
      if (picked != null) _setWritingFixedPrompt(picked);
    });
  }

  Widget _buildPromptOptionTile(BuildContext ctx, Map<String, dynamic> prompt, int index) {
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
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$index',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
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
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pop(ctx, prompt),
                  child: Text(context.l10n.teacherExamWritingSelectThisPrompt),
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
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text(l10n.teacherExamWritingPromptTextRequired)),
                              );
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
    final resources = _getResources(_skillSection['writing'] ?? {});
    final hasResources = resources.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.assignment_outlined, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(l10n.teacherExamWritingPromptSectionTitle, style: ExamSystemUi.captionMuted.copyWith(fontWeight: FontWeight.w600)),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primaryDark),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title.isNotEmpty ? title : context.l10n.teacherExamWritingCustomPrompt,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                ),
              ),
              if (taskType.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Text(taskType, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ),
            ],
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.outlineMuted),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.info),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.teacherExamWritingPromptEmptyHint,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _writingPromptGenerating == true
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: (hasResources || _title.text.trim().isNotEmpty)
                          ? _generateWritingPromptOptions
                          : null,
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
        if (!hasResources && _title.text.trim().isEmpty)
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
  }

  Widget _buildPromptMissingWarning(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.teacherExamWritingPromptNotSet,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCard(String skill) {
    final on = _skillIncluded[skill] == true;
    final sec = _skillSection[skill] ?? _emptySkillSection(skill, 0);
    final resources = _getResources(sec);
    final canEdit = _canEditSkillContent;
    final l10n = context.l10n;

    return Material(
      color: AppColors.surfaceCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: on ? AppColors.outline : AppColors.outlineMuted),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_skillIcon(skill), size: 26, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_skillLabel(skill), style: ExamSystemUi.listTitle(context)),
                      const SizedBox(height: 2),
                      if (on && resources.isNotEmpty)
                        Text(
                          '${resources.length} ${l10n.teacherExamSkillsExercisesSelected}',
                          style: ExamSystemUi.captionMuted,
                        ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: on,
                  onChanged: _status == 'draft' ? (v) => setState(() => _skillIncluded[skill] = v) : null,
                ),
              ],
            ),
            if (on) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              if (!_skillMeetsPublishRequirement(skill))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    skill == 'writing'
                        ? l10n.teacherExamWritingPublishNeedPrompt
                        : skill == 'speaking'
                            ? l10n.teacherExamSpeakingExerciseRequired
                            : l10n.teacherExamPublishPickEachIncludedSkill,
                    style: ExamSystemUi.captionSecondary.copyWith(color: AppColors.chartTrend),
                  ),
                ),
              // Exercise list
              for (var i = 0; i < resources.length; i++) ...[
                if (i > 0) const SizedBox(height: 4),
                _buildResourceRow(skill: skill, idx: i, res: resources[i], draft: canEdit),
              ],
              if (canEdit) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _pickAt(skill),
                  icon: const Icon(Icons.add_outlined, size: 18),
                  label: Text(l10n.teacherExamSkillsAddExercise),
                ),
              ],
              if (skill == 'writing') _buildWritingPromptSubSection(canEdit),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResourceRow({
    required String skill,
    required int idx,
    required Map<String, dynamic> res,
    required bool draft,
  }) {
    final title = res['title'] as String? ?? '';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineMuted),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: AppColors.outline),
            ),
            child: Text(
              '${idx + 1}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title.isEmpty ? '—' : title,
              style: ExamSystemUi.captionSecondary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (draft) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: () => _removeResource(skill, idx),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16, color: AppColors.textSecondary),
              ),
            ),
          ],
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
    if (_status != 'draft') return;
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.teacherExamGrammarImportError)));
      return;
    }

    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.teacherExamGrammarImportError)));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.teacherExamGrammarImportEmpty)));
        return;
      }

      setState(() => _grammarItems = [..._grammarItems, ...imported]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.teacherExamGrammarImportSuccess(imported.length))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.teacherExamGrammarImportError)));
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
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(l10n.teacherExamGrammarDownloadSample)),
                        );
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
    final on = _grammarIncluded;
    return Material(
      color: AppColors.surfaceCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: on ? AppColors.outline : AppColors.outlineMuted),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.spellcheck_outlined, size: 26, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.teacherExamGrammarTitle, style: ExamSystemUi.listTitle(context)),
                      const SizedBox(height: 2),
                      Text(
                        on && _grammarItems.isNotEmpty
                            ? l10n.teacherExamGrammarQuestionCount(_grammarItems.length)
                            : l10n.teacherExamGrammarIncludeSubtitle,
                        style: ExamSystemUi.captionMuted,
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: on,
                  onChanged: _canEditSkillContent
                      ? (v) => setState(() {
                            _grammarIncluded = v;
                            if (!v) _grammarEditorIndex = null;
                          })
                      : null,
                ),
              ],
            ),
            if (on) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.teacherExamGrammarHint, style: ExamSystemUi.captionSecondary),
                  ),
                  if (_canEditSkillContent) ...[
                    IconButton(
                      onPressed: _showImportFormatDialog,
                      icon: const Icon(Icons.upload_file_outlined, size: 20),
                      tooltip: l10n.teacherExamGrammarImport,
                      color: AppColors.textSecondary,
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _openGrammarEditor(),
                      icon: const Icon(Icons.add_outlined, size: 20),
                      label: Text(l10n.teacherExamGrammarAdd),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (!on)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 6, 16),
                child: Text(l10n.teacherExamGrammarIncludeSubtitle, style: ExamSystemUi.captionMuted),
              )
            else if (_grammarItems.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 20),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(child: Text(l10n.teacherExamSkillsNoGrammarYet, style: ExamSystemUi.captionSecondary)),
                  ],
                ),
              )
            else if (on)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _grammarItems.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final it = _grammarItems[index];
                  final kind = '${it['kind'] ?? ''}';
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _status == 'draft' ? () => _openGrammarEditor(editIndex: index) : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${index + 1}.',
                                style: ExamSystemUi.captionMuted,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Chip(
                                      label: Text(_grammarKindLabel(kind), style: const TextStyle(fontSize: 12)),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      side: const BorderSide(color: AppColors.outlineMuted),
                                      backgroundColor: AppColors.surface,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _grammarPreview(it),
                                    style: ExamSystemUi.captionSecondary,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text('${it['points'] ?? 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              side: const BorderSide(color: AppColors.outline),
                              backgroundColor: AppColors.surface,
                            ),
                            if (_status == 'draft')
                              IconButton(
                                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                                onPressed: () => _removeGrammarAt(index),
                                icon: const Icon(Icons.delete_outline, size: 22),
                                color: AppColors.textSecondary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sticky = _webStickyActions(context);
    final pageTitle = _displayTitle(l10n);
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
        if (!_useWebLayout() && _canEditSkillContent) ...[
          TextButton(
            onPressed: _saveDraft,
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            child: Text(l10n.teacherExamSaveDraft),
          ),
          if (_status == 'draft')
            TeacherFilledButton(label: l10n.teacherExamPublish, onPressed: _publish),
        ],
        IconButton(
          onPressed: _load,
          icon: const Icon(Icons.refresh_outlined),
          iconSize: ExamSystemUi.iconSm,
          color: AppColors.textSecondary,
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Padding(padding: ExamSystemUi.pagePadding, child: Text(_error!, style: ExamSystemUi.captionSecondary)))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final maxW = math.min(constraints.maxWidth, _useWebLayout() ? ExamSystemUi.webTeacherContentMaxWidth : constraints.maxWidth);
                          final hPad = _useWebLayout() ? 32.0 : ExamSystemUi.hPadding.toDouble();
                          final showEditor = _useWebLayout() && _status == 'draft' && _grammarEditorIndex != null;

                          Widget mainColumn() {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_status != 'draft')
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        child: Text(l10n.teacherExamReadOnlyPublished, style: ExamSystemUi.captionSecondary),
                                      ),
                                    ),
                                  ),
                                Text(
                                  l10n.teacherExamTitleLabel,
                                  style: ExamSystemUi.captionMuted,
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _title,
                                  enabled: _status == 'draft',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                                  decoration: InputDecoration(
                                    hintText: l10n.teacherExamTitleHint,
                                    filled: true,
                                    fillColor: AppColors.surfaceCard,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: AppColors.outline),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                _grammarPanel(),
                                const SizedBox(height: 36),
                                Text(l10n.teacherExamSkillsPartsTitle, style: ExamSystemUi.sectionTitle(context)),
                                const SizedBox(height: 20),
                                _skillsRegion(),
                              ],
                            );
                          }

                          final scroll = SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(hPad, 24, hPad, _useWebLayout() ? 100 : 28),
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
                                                  initial: _grammarEditorIndex == -1 ? null : _grammarItems[_grammarEditorIndex!],
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
    required this.onPick,
    required this.alreadySelectedIds,
    this.useWebListLayout = false,
    this.onCreateNew,
    this.scrollController,
  });

  final String skill;
  final void Function(String id, String title) onPick;
  final Set<String> alreadySelectedIds;
  /// Tách list tile (web/dialog) vs builder (mobile sheet).
  final bool useWebListLayout;
  final VoidCallback? onCreateNew;
  final ScrollController? scrollController;

  @override
  State<_SkillPickPanel> createState() => _SkillPickPanelState();
}

class _SkillPickPanelState extends State<_SkillPickPanel> {
  late Future<List<({String id, String title})>> _future;

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
          return const Center(child: CircularProgressIndicator());
        }
        final allItems = snap.data ?? [];
        final available = allItems.where((it) => !widget.alreadySelectedIds.contains(it.id)).toList();
        final allAlreadyAdded = allItems.isNotEmpty && available.isEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // "Create New" action bar
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
            // Already-added indicator
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
                child: widget.useWebListLayout
                    ? ListView.separated(
                        controller: widget.scrollController,
                        itemCount: available.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final it = available[i];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            leading: Icon(Icons.article_outlined, size: 20, color: AppColors.textSecondary),
                            title: Text(it.title, style: ExamSystemUi.listTitle(context)),
                            trailing: const Icon(Icons.add, size: 18, color: AppColors.textSecondary),
                            onTap: () => widget.onPick(it.id, it.title),
                          );
                        },
                      )
                    : ListView.builder(
                        controller: widget.scrollController,
                        itemCount: available.length,
                        itemBuilder: (context, i) {
                          final it = available[i];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                            leading: Icon(Icons.article_outlined, size: 20, color: AppColors.textSecondary),
                            title: Text(it.title, style: ExamSystemUi.listTitle(context)),
                            trailing: const Icon(Icons.add, size: 18, color: AppColors.textSecondary),
                            onTap: () => widget.onPick(it.id, it.title),
                          );
                        },
                      ),
              ),
          ],
        );
      },
    );
  }
}
