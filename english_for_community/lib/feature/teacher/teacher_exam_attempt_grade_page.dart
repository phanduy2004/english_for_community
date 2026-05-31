import 'dart:convert';

import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/e4c_scroll_behavior.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_mobile_ui.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_page_scaffold.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/teacher_dashboard_page.dart';
import 'package:english_for_community/feature/student/exams/exam_answer_review_widgets.dart';
import 'package:english_for_community/feature/student/exams/integrated_exam_grammar_widgets.dart';
import 'package:english_for_community/feature/student/exams/integrated_exam_score_widgets.dart';
import 'package:english_for_community/feature/teacher/integrated_writing_grading_panel.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_skill_work_panel.dart';
import 'package:english_for_community/feature/teacher/bloc/exam_attempt_grade/teacher_exam_attempt_grade_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/exam_attempt_grade/teacher_exam_attempt_grade_event.dart';
import 'package:english_for_community/feature/teacher/bloc/exam_attempt_grade/teacher_exam_attempt_grade_state.dart';
import 'package:english_for_community/feature/teacher/teacher_grading_hub_labels.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_release_results_dialog.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Per-attempt grading: full student summary + section scores + item rubric.
class TeacherExamAttemptGradePage extends StatelessWidget {
  const TeacherExamAttemptGradePage({
    super.key,
    required this.assignmentId,
    required this.attemptId,
  });

  final String assignmentId;
  final String attemptId;

  static const String routeName = 'TeacherExamAttemptGradePage';

  static String location(String assignmentId, String attemptId) =>
      '/teacher/exam-grading/$assignmentId/attempt/$attemptId';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TeacherExamAttemptGradeBloc>(param1: attemptId)
        ..add(const TeacherExamAttemptGradeLoadRequested()),
      child: _TeacherExamAttemptGradeView(
        assignmentId: assignmentId,
        attemptId: attemptId,
      ),
    );
  }
}

class _TeacherExamAttemptGradeView extends StatefulWidget {
  const _TeacherExamAttemptGradeView({
    required this.assignmentId,
    required this.attemptId,
  });

  final String assignmentId;
  final String attemptId;

  @override
  State<_TeacherExamAttemptGradeView> createState() => _TeacherExamAttemptGradeViewState();
}

class _TeacherExamAttemptGradeViewState extends State<_TeacherExamAttemptGradeView> {
  final Map<String, TextEditingController> _pointsCtr = {};
  final Map<String, TextEditingController> _noteCtr = {};
  // Skill score controllers for Speaking/Writing in integrated exams
  final Map<String, TextEditingController> _skillScoreCtr = {};
  final Map<String, TextEditingController> _skillNoteCtr = {};
  final ScrollController _bodyScrollController = ScrollController();

  TeacherExamAttemptGradeBloc get _bloc => context.read<TeacherExamAttemptGradeBloc>();

  Map<String, dynamic>? get _attempt => _bloc.state.attempt;

  @override
  void dispose() {
    _bodyScrollController.dispose();
    for (final c in _pointsCtr.values) {
      c.dispose();
    }
    for (final c in _noteCtr.values) {
      c.dispose();
    }
    for (final c in _skillScoreCtr.values) {
      c.dispose();
    }
    for (final c in _skillNoteCtr.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<Map<String, dynamic>> _flattenItems(Map<String, dynamic> snap) {
    final out = <Map<String, dynamic>>[];
    final sections = snap['sections'] as List? ?? [];
    for (final sec in sections) {
      final sm = Map<String, dynamic>.from(sec as Map);
      final items = sm['items'] as List? ?? [];
      for (final it in items) {
        final m = Map<String, dynamic>.from(it as Map);
        out.add(m);
        final nested = m['nestedItems'] as List?;
        if (nested != null) {
          for (final n in nested) {
            out.add(Map<String, dynamic>.from(n as Map));
          }
        }
      }
    }
    return out;
  }

  void _syncControllersFromAttempt(Map<String, dynamic> m) {
    for (final c in _pointsCtr.values) {
      c.dispose();
    }
    for (final c in _noteCtr.values) {
      c.dispose();
    }
    for (final c in _skillScoreCtr.values) {
      c.dispose();
    }
    for (final c in _skillNoteCtr.values) {
      c.dispose();
    }
    _pointsCtr.clear();
    _noteCtr.clear();
    _skillScoreCtr.clear();
    _skillNoteCtr.clear();

    final snap = m['examSnapshot'];
    final scores = m['scores'];
    final integrated = isIntegratedExamFromAttempt(m);
    final skillScoresRaw = scores is Map ? scores['skillScores'] as Map? : null;
    if (skillScoresRaw != null) {
      for (final entry in skillScoresRaw.entries) {
        final sid = entry.key.toString();
        final se = entry.value;
        if (se is! Map) continue;
        final skill = '${se['skill'] ?? ''}';
        if (skill != 'speaking' && skill != 'writing') continue;
        final existing = se['score'];
        final aiDraft = se['aiDraftScore'];
        final note = '${se['note'] ?? ''}';
        _skillScoreCtr[sid] = TextEditingController(
          text: existing != null
              ? '$existing'
              : (aiDraft != null ? formatIntegratedScore(aiDraft) : ''),
        );
        _skillNoteCtr[sid] = TextEditingController(text: note);
      }
    }
    final itemsScores = scores is Map ? scores['items'] as Map? : null;
    if (!integrated && snap is Map) {
      final flat = _flattenItems(Map<String, dynamic>.from(snap));
      for (final it in flat) {
        final kind = it['kind'] as String? ?? '';
        if (['reading', 'listening'].contains(kind)) continue;
        final id = it['itemId'] as String? ?? '';
        if (id.isEmpty) continue;
        final ir = itemsScores?[id] as Map?;
        final ap = ir?['awardedPoints'];
        final note = (ir?['manual'] as Map?)?['note'] as String? ?? '';
        _pointsCtr[id] = TextEditingController(text: '${ap ?? 0}');
        _noteCtr[id] = TextEditingController(text: note);
      }
    }
    if (!integrated && itemsScores != null) {
      for (final entry in itemsScores.entries) {
        final id = entry.key.toString();
        if (_pointsCtr.containsKey(id)) continue;
        final ir = entry.value;
        if (ir is! Map) continue;
        final ap = ir['awardedPoints'];
        final note = (ir['manual'] as Map?)?['note'] as String? ?? '';
        _pointsCtr[id] = TextEditingController(text: '${ap ?? 0}');
        _noteCtr[id] = TextEditingController(text: note);
      }
    }
  }

  String? _completenessLabel(AppLocalizations l10n) {
    final meta = _attempt?['meta'];
    if (meta is! Map) return null;
    final c = meta['submitCompleteness'] as String?;
    switch (c) {
      case 'partial':
        return l10n.teacherGradingCompletenessPartial;
      case 'force_end':
        return l10n.teacherGradingCompletenessForceEnd;
      case 'complete':
        return l10n.teacherGradingCompletenessComplete;
      default:
        return null;
    }
  }

  bool get _isIntegratedFormat => isIntegratedExamFromAttempt(_attempt);

  Set<String> _integratedScoreKeys() {
    final scores = _attempt?['scores'];
    if (!_isIntegratedFormat || scores is! Map) return {};
    final result = <String>{};
    // Collect sectionIds from skillScores
    final skillScores = scores['skillScores'];
    if (skillScores is Map) result.addAll(skillScores.keys.map((e) => e.toString()));
    // Collect itemIds from grammarScore.items
    final grammarItems = (scores['grammarScore'] as Map?)?['items'];
    if (grammarItems is Map) result.addAll(grammarItems.keys.map((e) => e.toString()));
    // Legacy fallback
    final items = scores['items'];
    if (items is Map) result.addAll(items.keys.map((e) => e.toString()));
    return result;
  }

  String _studentName(AppLocalizations l10n) {
    final u = _attempt?['userId'];
    if (u is Map) {
      final name = (u['fullName'] as String?)?.trim();
      if (name != null && name.isNotEmpty) return name;
      final un = (u['username'] as String?)?.trim();
      if (un != null && un.isNotEmpty) return un;
    }
    return l10n.teacherAttemptGradeStudentFallback;
  }

  String? _studentEmail() {
    final u = _attempt?['userId'];
    if (u is Map) {
      final e = (u['email'] as String?)?.trim();
      if (e != null && e.isNotEmpty) return e;
    }
    return null;
  }

  String _examTitle(AppLocalizations l10n) {
    final snap = _attempt?['examSnapshot'];
    if (snap is Map) {
      final t = (snap['title'] as String?)?.trim();
      if (t != null && t.isNotEmpty) return t;
    }
    return l10n.teacherExamIntegratedUntitled;
  }

  String? _formatTs(dynamic raw) {
    if (raw == null) return null;
    try {
      final d = DateTime.parse(raw.toString()).toLocal();
      return DateFormat.yMMMd().add_jm().format(d);
    } catch (_) {
      return raw.toString();
    }
  }

  String _skillSectionLabel(AppLocalizations l10n, String? skill, String? kind) {
    switch (skill) {
      case 'listening':
        return l10n.teacherExamIntegratedSkillListening;
      case 'speaking':
        return l10n.teacherExamIntegratedSkillSpeaking;
      case 'reading':
        return l10n.teacherExamIntegratedSkillReading;
      case 'writing':
        return l10n.teacherExamIntegratedSkillWriting;
      default:
        break;
    }
    if (kind != null && kind.isNotEmpty) return kind;
    return l10n.teacherAttemptGradeSkillOther;
  }

  IconData _skillIcon(String? skill) {
    switch (skill) {
      case 'listening':
        return Icons.headphones_outlined;
      case 'speaking':
        return Icons.mic_none_outlined;
      case 'reading':
        return Icons.menu_book_outlined;
      case 'writing':
        return Icons.edit_outlined;
      default:
        return Icons.school_outlined;
    }
  }

  List<Map<String, dynamic>> _grammarItemsFromSnapshot(Map<String, dynamic> snap) {
    final settings = snap['settings'] as Map?;
    final raw = settings?['grammarItems'] as List? ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  List<Map<String, dynamic>> _skillSectionsOrdered(Map<String, dynamic> snap) {
    final raw = snap['sections'] as List? ?? [];
    final out = <Map<String, dynamic>>[];
    for (final e in raw) {
      final m = Map<String, dynamic>.from(e as Map);
      final sk = '${m['skill'] ?? ''}';
      final skc = '${m['sectionKind'] ?? ''}';
      final isSkill = skc == 'skill_content' ||
          ['listening', 'speaking', 'reading', 'writing'].contains(sk);
      if (isSkill) out.add(m);
    }
    out.sort((a, b) => (a['order'] as num?)?.compareTo((b['order'] as num?) ?? 0) ?? 0);
    return out;
  }

  List<String> _resourceTitlesFromSection(Map<String, dynamic> sec) {
    final raw = sec['resources'];
    if (raw is List) {
      final out = <String>[];
      for (final e in raw) {
        if (e is Map) {
          final t = (e['title'] as String?)?.trim() ?? '';
          if (t.isNotEmpty) {
            out.add(t);
            continue;
          }
          final id = e['id'];
          if (id != null && '$id'.isNotEmpty) out.add('$id');
        }
      }
      return out;
    }
    final legacyId = (sec['resourceId'] as String?)?.trim() ?? '';
    final legacyTitle = (sec['resourceTitle'] as String?)?.trim() ?? '';
    if (legacyTitle.isNotEmpty) return [legacyTitle];
    if (legacyId.isNotEmpty) return [legacyId];
    return [];
  }

  String _listeningTypeFromSection(Map<String, dynamic> sec) {
    final sc = sec['sectionConfig'];
    if (sc is Map) return (sc['listeningType'] as String?) ?? 'dictation';
    return 'dictation';
  }

  String _listeningSectionLabel(AppLocalizations l10n, Map<String, dynamic> sec) {
    final base = _skillSectionLabel(l10n, 'listening', null);
    final lt = _listeningTypeFromSection(sec);
    final typeLabel = lt == 'comprehension'
        ? l10n.teacherExamListeningTypeComprehension
        : l10n.teacherExamListeningTypeDictation;
    return '$base · $typeLabel';
  }

  bool _sectionHasPartialSkillWork(String sectionId, Map<String, dynamic> section) {
    final answers = _attempt?['answers'];
    if (answers is! Map || answers[sectionId] is! Map) return false;
    final a = Map<String, dynamic>.from(answers[sectionId] as Map);
    final skill = section['skill'] as String? ?? '';
    if (skill == 'listening') {
      final lt = _listeningTypeFromSection(section);
      if (lt == 'comprehension') {
        final comp = a['listeningCompAnswers'];
        return comp is Map && comp.isNotEmpty;
      }
      final cues = a['listeningCues'];
      if (cues is Map) {
        for (final v in cues.values) {
          if (v is String && v.trim().isNotEmpty) return true;
        }
      }
      return false;
    }
    if (skill == 'reading') {
      final ra = a['readingAnswers'];
      return ra is Map && ra.isNotEmpty;
    }
    if (skill == 'writing') {
      final draft = a['writingDraft'];
      return draft is String && draft.trim().isNotEmpty;
    }
    if (skill == 'speaking') {
      return a['completed'] == true ||
          (a['speakingSaved'] is num && (a['speakingSaved'] as num) > 0);
    }
    return false;
  }

  bool _skillWorkResourceHasContent(Map<String, dynamic> resource) {
    final rec = resource['records'];
    if (rec == null) return false;
    if (rec is List) {
      return rec.any((row) {
        if (row is! Map) return false;
        final text = '${row['userText'] ?? ''}'.trim();
        return text.isNotEmpty;
      });
    }
    if (rec is Map) {
      final content = '${rec['content'] ?? ''}'.trim();
      if (content.isNotEmpty) return true;
      final answers = rec['answers'];
      if (answers is Map && answers.isNotEmpty) return true;
      if (answers is List && answers.isNotEmpty) return true;
      final gp = rec['generatedPrompt'];
      if (gp is Map) {
        final t = '${gp['text'] ?? ''}'.trim();
        final ti = '${gp['title'] ?? ''}'.trim();
        if (t.isNotEmpty || ti.isNotEmpty) return true;
      }
    }
    return false;
  }

  String _localizedItemKindLabel(BuildContext context, String kind) {
    const grammarKinds = {
      'mcq_single',
      'mcq_multi',
      'grammar_cloze',
      'grammar_gap',
      'grammar_matching',
      'grammar_reorder',
    };
    if (grammarKinds.contains(kind)) return grammarItemKindLabel(context, kind);
    return context.l10n.teacherAttemptGradeItemKind(kind);
  }

  String _answerPreview(dynamic ans) {
    if (ans == null) return '—';
    if (ans is Map || ans is List) {
      try {
        return const JsonEncoder.withIndent('  ').convert(ans);
      } catch (_) {}
    }
    return ans.toString();
  }

  void _runAi() => _bloc.add(const TeacherExamAttemptGradeRunAiRequested());

  Future<void> _finalize() async {
    final r = await getIt<TeacherExamRepository>().finalizeExamAttempt(widget.attemptId);
    if (!mounted) return;
    r.fold(
      (f) => AppCornerToast.show(context, f.message, error: true),
      (_) {
        AppCornerToast.show(context, context.l10n.teacherGradingFinalized);
        _bloc.add(const TeacherExamAttemptGradeLoadRequested());
      },
    );
  }

  Future<void> _release() async {
    final rt = _attempt?['runtimeContext'];
    final cfgLevel = rt is Map ? rt['resultsDetailLevel'] as String? : null;
    final initial = cfgLevel == 'score_only' ? 'score_only' : 'full_detail';
    final detail = await TeacherReleaseResultsDialog.show(
      context,
      initialDetailLevel: initial,
    );
    if (detail == null || !mounted) return;
    final r = await getIt<TeacherExamRepository>().releaseExamResults(
      widget.attemptId,
      resultsDetailLevel: detail,
    );
    if (!mounted) return;
    r.fold(
      (f) => AppCornerToast.show(context, f.message, error: true),
      (_) {
        AppCornerToast.show(context, context.l10n.teacherExamReleaseResults);
        _bloc.add(const TeacherExamAttemptGradeLoadRequested());
      },
    );
  }

  void _saveSkillScore(String sid) {
    final ctr = _skillScoreCtr[sid];
    if (ctr == null) return;
    final score = double.tryParse(ctr.text.trim());
    if (score == null) return;
    final note = _skillNoteCtr[sid]?.text ?? '';
    _bloc.add(TeacherExamAttemptGradeSaveSkillScoreRequested(
      sectionId: sid,
      score: score,
      note: note,
    ));
  }

  void _save({bool finalize = false}) {
    final items = <String, dynamic>{};
    for (final e in _pointsCtr.entries) {
      final id = e.key;
      final pts = double.tryParse(e.value.text.trim());
      final note = _noteCtr[id]?.text ?? '';
      if (pts != null) {
        items[id] = {'awardedPoints': pts, 'note': note};
      }
    }
    if (items.isEmpty && !finalize) return;
    _bloc.add(TeacherExamAttemptGradeSaveRequested(items: items, finalize: finalize));
  }

  Widget _summaryHeader(BuildContext context, AppLocalizations l10n) {
    final name = _studentName(l10n);
    final email = _studentEmail();
    final exam = _examTitle(l10n);
    final initials = TeacherGradingHubLabels.studentInitials(name);

    return AppCard(
      variant: AppCardVariant.outline,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              initials,
              style: TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: ExamSystemUi.listTitle(context)),
                if (email != null) ...[
                  const SizedBox(height: 2),
                  Text(email, style: ExamSystemUi.captionMuted),
                ],
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.description_outlined, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${l10n.teacherAttemptGradeExamLabel}: $exam',
                        style: ExamSystemUi.captionSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChips(BuildContext context, AppLocalizations l10n) {
    final st = _attempt?['status'] as String? ?? '';
    final gs = _attempt?['gradingState'] as String? ?? '';
    final released = _attempt?['resultsReleased'] == true;
    final completeness = _completenessLabel(l10n);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _GradeChip(
          label: TeacherGradingHubLabels.attemptStatus(l10n, st),
          color: st == 'submitted' ? AppColors.primary : AppColors.textSecondary,
        ),
        _GradeChip(
          label: TeacherGradingHubLabels.gradingState(l10n, gs),
          color: gs == 'finalized' ? AppColors.success : AppColors.warning,
        ),
        _GradeChip(
          label: released ? l10n.teacherAttemptGradeReleasedYes : l10n.teacherAttemptGradeReleasedNo,
          color: released ? AppColors.success : AppColors.textMuted,
        ),
        if (completeness != null) _GradeChip(label: completeness, color: AppColors.textSecondary),
      ],
    );
  }

  Widget _totalScoreCard(BuildContext context, AppLocalizations l10n) {
    final scores = _attempt?['scores'];
    if (scores is! Map) return const SizedBox.shrink();

    // Integrated exam: per-skill 0–10 + arithmetic mean (no pts)
    if (_isIntegratedFormat) {
      return IntegratedGradingScorePanel(
        attempt: Map<String, dynamic>.from(_attempt!),
        title: l10n.teacherAttemptGradeTotalScore,
      );
    }

    // Non-integrated: legacy X/Y pts display
    final awarded = num.tryParse('${scores['totalAwarded'] ?? 0}') ?? 0;
    final max = num.tryParse('${scores['totalMax'] ?? 0}') ?? 0;
    final ratio = max > 0 ? (awarded / max).clamp(0.0, 1.0).toDouble() : 0.0;

    return AppCard(
      variant: AppCardVariant.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.teacherAttemptGradeTotalScore, style: ExamSystemUi.sectionTitle(context)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.teacherAttemptGradePointsShort('$awarded', '$max'),
                style: ExamSystemUi.listTitle(context).copyWith(fontSize: 16),
              ),
              const Spacer(),
              Text('${(ratio * 100).round()}%', style: ExamSystemUi.captionMuted),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: max > 0 ? ratio : 0,
              minHeight: 8,
              backgroundColor: AppColors.outlineMuted,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Compact inline score badge for skill section header row.
  Widget _buildSectionScoreBadge(BuildContext context, AppLocalizations l10n, Map? secScore) {
    final status = '${secScore?['status'] ?? ''}';
    final score = secScore?['score'];
    if (status == 'pending_manual' || status == 'pending_ai') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          l10n.integratedSkillScorePending,
          style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600),
        ),
      );
    }
    if (score != null || status == 'finalized' || status == 'no_content') {
      final display = score ?? 0;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${_formatScore(display)} / 10',
          style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w700),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  String _formatScore(dynamic score) {
    final n = num.tryParse('$score');
    if (n == null) return '—';
    if (n == n.truncate()) return '${n.toInt()}';
    return n.toStringAsFixed(1);
  }

  /// Footer shown inside each skill section card in integrated exams.
  Widget _buildSkillScoreFooter(
      BuildContext context, AppLocalizations l10n, String sid, String skill) {
    final scores = _attempt?['scores'];
    final skillScoresRaw = scores is Map ? scores['skillScores'] as Map? : null;
    final se = skillScoresRaw?[sid] as Map?;
    final seScore = se?['score'];
    final seStatus = '${se?['status'] ?? ''}';
    final seDetail = se?['detail'] as String?;
    final isPending =
        seStatus == 'pending_ai' || (seStatus == 'pending_manual' && seScore == null);
    // Speaking is auto-graded via WER; only writing requires teacher/AI manual grading.
    final isEditable = skill == 'writing';
    final canEdit = _attempt?['status'] == 'submitted' && isEditable && _skillScoreCtr.containsKey(sid);

    if (skill == 'writing' && canEdit) {
      final answers = _attempt?['answers'];
      final secAns = answers is Map && answers[sid] is Map
          ? Map<String, dynamic>.from(answers[sid] as Map)
          : null;
      return IntegratedWritingGradingPanel(
        sectionId: sid,
        sectionAnswers: secAns,
        skillEntry: se != null ? Map<String, dynamic>.from(se) : null,
        scoreController: _skillScoreCtr[sid]!,
        noteController: _skillNoteCtr[sid]!,
        onSave: () => _saveSkillScore(sid),
        onRunAi: _runAi,
        aiLoading: _bloc.state.aiGrading,
        canEdit: canEdit == true,
      );
    }

    if (isEditable && canEdit) {
      // Speaking: manual score 0–10
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (seScore != null) ...[
              Text(
                l10n.integratedSkillScoreLabel(formatIntegratedScore(seScore)),
                style: ExamSystemUi.listTitle(context).copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _skillScoreCtr[sid],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: const OutlineInputBorder(),
                      labelText: l10n.integratedSkillEnterScore,
                      labelStyle: const TextStyle(fontSize: 11),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _skillNoteCtr[sid],
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: const OutlineInputBorder(),
                      hintText: l10n.teacherGradingNotesHint,
                      hintStyle: const TextStyle(fontSize: 11),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _saveSkillScore(sid),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: const Size(0, 36),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: Text(l10n.integratedSkillSaveScore),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Listening/Reading (auto-graded) or finalized speaking/writing
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Row(
        children: [
          if (isPending) ...[
            Icon(Icons.hourglass_empty, size: 14, color: AppColors.warning),
            const SizedBox(width: 6),
            Text(l10n.integratedSkillScorePending, style: ExamSystemUi.captionMuted.copyWith(color: AppColors.warning)),
          ] else ...[
            Text(
              seScore != null ? l10n.integratedSkillScoreLabel(formatIntegratedScore(seScore)) : '—',
              style: ExamSystemUi.listTitle(context).copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            if (seDetail != null && seDetail.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                '· $seDetail',
                style: ExamSystemUi.captionMuted.copyWith(fontSize: 12),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _metaLines(AppLocalizations l10n) {
    final started = _formatTs(_attempt?['startedAt']);
    final submitted = _formatTs(_attempt?['submittedAt']);
    final lines = <String>[];
    if (started != null) lines.add(l10n.teacherAttemptGradeStartedLine(started));
    if (submitted != null) lines.add(l10n.teacherAttemptGradeSubmittedLine(submitted));
    if (lines.isEmpty) return const SizedBox.shrink();

    return AppCard(
      variant: AppCardVariant.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.schedule_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(child: Text(lines[i], style: ExamSystemUi.captionSecondary)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildIntegratedWorkSection(BuildContext context, AppLocalizations l10n) {
    if (!_isIntegratedFormat) return [];

    final snap = _attempt?['examSnapshot'];
    if (snap is! Map) return [];
    final sm = Map<String, dynamic>.from(snap);
    final grammar = _grammarItemsFromSnapshot(sm);
    final skillSecs = _skillSectionsOrdered(sm);
    if (grammar.isEmpty && skillSecs.isEmpty) return [];

    final answersRaw = _attempt?['answers'];
    final answers = answersRaw is Map ? Map<String, dynamic>.from(answersRaw) : <String, dynamic>{};
    final scores = _attempt?['scores'];
    // For integrated exams grammar scores live in scores.grammarScore.items
    final grammarScoreItems = scores is Map
        ? ((scores['grammarScore'] as Map?)?['items'] as Map?)
        : null;
    // Legacy path for non-integrated
    final itemsScores = scores is Map ? scores['items'] as Map? : null;
    Map? effectiveGrammarItems(String id) =>
        (grammarScoreItems?[id] as Map?) ?? (itemsScores?[id] as Map?);

    final out = <Widget>[
      const SizedBox(height: ExamSystemUi.sectionGap),
      Text(l10n.teacherAttemptGradeWorkAndScores, style: ExamSystemUi.sectionTitle(context)),
      const SizedBox(height: ExamSystemUi.cardGap),
    ];

    if (grammar.isNotEmpty) {
      out.add(
        Padding(
          padding: const EdgeInsets.only(bottom: ExamSystemUi.cardGap),
          child: Row(
            children: [
              Icon(Icons.spellcheck_outlined, size: ExamSystemUi.iconSm, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.integratedExamGrammarSectionTitle,
                  style: ExamSystemUi.listTitle(context),
                ),
              ),
            ],
          ),
        ),
      );
      for (var i = 0; i < grammar.length; i++) {
        final it = Map<String, dynamic>.from(grammar[i]);
        final id = '${it['itemId'] ?? ''}';
        final ans = id.isNotEmpty ? answers[id] : null;
        final amap = ans is Map ? Map<String, dynamic>.from(ans) : null;
        final ir = id.isNotEmpty ? effectiveGrammarItems(id) : null;
        final kind = '${it['kind'] ?? ''}';
        final isMcq = kind == 'mcq_single' || kind == 'mcq_multi';
        Widget? grammarFooter;
        if (!isMcq) {
          grammarFooter = GrammarCorrectAnswerReviewPanel(item: it);
        }

        out.add(
          Padding(
            padding: const EdgeInsets.only(bottom: ExamSystemUi.cardGap),
            child: AppCard(
              variant: AppCardVariant.outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IntegratedExamGrammarQuestionCard(
                    item: it,
                    answer: amap,
                    locked: true,
                    onPartialPatch: (_) {},
                    displayIndex: i + 1,
                    wrapInCard: false,
                    gradingReviewMode: isMcq,
                    reviewFooter: grammarFooter,
                  ),
                  const Divider(height: 1),
                  IntegratedGrammarItemResultFooter(
                    itemResult: ir is Map ? Map<String, dynamic>.from(ir) : null,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    if (skillSecs.isNotEmpty) {
      out.add(
        Padding(
          padding: EdgeInsets.only(bottom: grammar.isEmpty ? 0 : ExamSystemUi.blockGap),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.hub_outlined, size: ExamSystemUi.iconSm, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.teacherAttemptGradeSkillLinkedWork, style: ExamSystemUi.listTitle(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      for (final sec in skillSecs) {
        final m = Map<String, dynamic>.from(sec);
        final sid = '${m['sectionId'] ?? ''}';
        if (sid.isEmpty) continue;
        final skill = m['skill'] as String? ?? '';
        final secTitle = (m['title'] as String?)?.trim() ?? '';
        final instr = (m['instructions'] as String?)?.trim() ?? '';
        final titles = _resourceTitlesFromSection(m);
        final skillWorkRaw = _attempt?['skillWork'];
        final skillWorkMap = skillWorkRaw is Map ? Map<String, dynamic>.from(skillWorkRaw) : <String, dynamic>{};
        final workEntry = skillWorkMap[sid] is Map ? Map<String, dynamic>.from(skillWorkMap[sid] as Map) : null;
        final workResources = (workEntry?['resources'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            <Map<String, dynamic>>[];
        final hasWork = workResources.any(_skillWorkResourceHasContent) ||
            _sectionHasPartialSkillWork(sid, m);
        final expanded = _bloc.state.expandedSkillSections.contains(sid);

        // Score entry for this section
        final scoresMap = _attempt?['scores'] as Map?;
        final skillScoresMap = scoresMap?['skillScores'] as Map?;
        final secScore = skillScoresMap?[sid] as Map?;
        final secStatus = '${secScore?['status'] ?? ''}';
        final isNoContent = secStatus == 'no_content' && !hasWork;

        out.add(
          Padding(
            padding: const EdgeInsets.only(bottom: ExamSystemUi.cardGap),
            child: AppCard(
              variant: AppCardVariant.outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(_skillIcon(skill), size: 20, color: isNoContent ? AppColors.textMuted : AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                skill == 'listening'
                                    ? _listeningSectionLabel(l10n, m)
                                    : _skillSectionLabel(l10n, skill, null),
                                style: ExamSystemUi.questionStem(context).copyWith(
                                  color: isNoContent ? AppColors.textMuted : null,
                                ),
                              ),
                              if (secTitle.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(secTitle, style: ExamSystemUi.captionSecondary),
                              ],
                              if (titles.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  titles.join(' · '),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isNoContent ? AppColors.textMuted : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Inline score badge
                        _buildSectionScoreBadge(context, l10n, secScore),
                      ],
                    ),
                  ),
                  if (instr.isNotEmpty) ...[
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: Divider(height: 20)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                      child: Text(
                        instr,
                        style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                  if (isNoContent) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                      child: Row(
                        children: [
                          Icon(Icons.do_not_disturb_alt_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            l10n.teacherAttemptGradeNoSkillWork,
                            style: ExamSystemUi.captionMuted,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: hasWork
                              ? () => _bloc.add(TeacherExamAttemptGradeSectionExpandedToggled(sid))
                              : null,
                          icon: Icon(expanded ? Icons.expand_less : Icons.visibility_outlined, size: 18),
                          label: Text(
                            expanded
                                ? l10n.teacherAttemptGradeHideSkillWork
                                : l10n.teacherAttemptGradeViewSkillWork,
                            style: TextStyle(
                              color: hasWork ? AppColors.primaryDark : AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (expanded && hasWork) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Divider(height: 12),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                        child: TeacherExamSkillWorkPanel(
                          skill: skill,
                          resources: workResources,
                          integratedScoreScale: true,
                        ),
                      ),
                    ],
                    const Divider(height: 1),
                    _buildSkillScoreFooter(context, l10n, sid, skill),
                  ],
                ],
              ),
            ),
          ),
        );
      }
    }

    return out;
  }

  List<Widget> _classicItemsSection(BuildContext context, AppLocalizations l10n) {
    final snap = _attempt?['examSnapshot'];
    if (snap is! Map) return [];
    final flat = _flattenItems(Map<String, dynamic>.from(snap));
    final answers = _attempt?['answers'] as Map? ?? {};
    final integratedKeys = _integratedScoreKeys();
    final scores = _attempt?['scores'];
    final itemsScores = scores is Map ? scores['items'] as Map? : null;

    final cards = <Widget>[];
    var index = 0;
    for (final it in flat) {
      final kind = it['kind'] as String? ?? '';
      if (['reading', 'listening'].contains(kind)) continue;
      final id = it['itemId'] as String? ?? '';
      if (id.isEmpty) continue;
      if (integratedKeys.contains(id)) continue;

      index++;
      final max = num.tryParse('${it['points'] ?? 1}') ?? 1;
      final stemRaw = ((it['stem'] ?? it['prompt']) as String?)?.trim() ?? '';
      final titleText = stemRaw.isNotEmpty ? stemRaw : l10n.teacherAttemptGradeQuestionN(index);
      final ans = answers[id];
      final ir = itemsScores?[id] as Map?;
      final ai = ir?['ai'] as Map?;
      final rationale = ai?['rationale'] as String?;
      final canEdit = _attempt?['status'] == 'submitted' && _pointsCtr.containsKey(id);
      final isMcq = kind == 'mcq_single' || kind == 'mcq_multi';
      final ap = num.tryParse('${ir?['awardedPoints'] ?? 0}') ?? 0;

      cards.add(
        Padding(
          padding: const EdgeInsets.only(bottom: ExamSystemUi.cardGap),
          child: AppCard(
            variant: AppCardVariant.outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(titleText, style: ExamSystemUi.questionStem(context)),
                            const SizedBox(height: 4),
                            Text(
                              _localizedItemKindLabel(context, kind),
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            Text(
                              l10n.teacherAttemptGradeMaxPts(max.toInt()),
                              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (isMcq)
                  McqGradingReviewList.fromMaps(
                    item: it,
                    answer: ans is Map ? Map<String, dynamic>.from(ans) : null,
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      l10n.teacherAttemptGradeAnswerLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: SelectableText(
                        _answerPreview(ans),
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: AppColors.textPrimary,
                          fontFamily: ans is Map || ans is List ? 'monospace' : null,
                        ),
                      ),
                    ),
                  ),
                ],
                const Divider(height: 1),
                if (_pointsCtr.containsKey(id) && _noteCtr.containsKey(id))
                  TeacherAttemptGradingFooter(
                    awarded: ap,
                    max: max,
                    pointsController: _pointsCtr[id]!,
                    noteController: _noteCtr[id]!,
                    canEdit: canEdit,
                    rationale: rationale,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    if (cards.isEmpty) return [];

    return [
      const SizedBox(height: ExamSystemUi.sectionGap),
      Text(l10n.teacherAttemptGradeSectionBreakdown, style: ExamSystemUi.sectionTitle(context)),
      const SizedBox(height: ExamSystemUi.cardGap),
      ...cards,
    ];
  }

  Widget _bottomActions(BuildContext context, AppLocalizations l10n) {
    final st = _attempt?['status'] as String? ?? '';
    final gs = _attempt?['gradingState'] as String? ?? '';
    final released = _attempt?['resultsReleased'] == true;
    if (st != 'submitted') {
      return SafeArea(
        top: false,
        child: Material(
          elevation: 8,
          color: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(ExamSystemUi.hPadding, 10, ExamSystemUi.hPadding, 12),
            child: Text(l10n.teacherGradingOnlySubmitted, style: ExamSystemUi.captionSecondary),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Material(
        elevation: 12,
        shadowColor: Colors.black26,
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(ExamSystemUi.hPadding, 10, ExamSystemUi.hPadding, 12),
          child: LayoutBuilder(
            builder: (context, c) {
              final narrow = c.maxWidth < 520;
              final mobile = TeacherMobileUi.isMobileWorkspace(context);
              final runAi = OutlinedButton.icon(
                style: mobile
                    ? TeacherMobileUi.mobileOutlinedCompactStyle(context)
                    : TeacherWebUi.compactOutlinedStyle(context),
                onPressed: _bloc.state.aiGrading ? null : _runAi,
                icon: _bloc.state.aiGrading
                    ? SizedBox(
                        width: mobile ? 18 : 16,
                        height: mobile ? 18 : 16,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.smart_toy_outlined, size: mobile ? 18 : 16),
                label: Text(
                  _isIntegratedFormat
                      ? l10n.integratedWritingGradingRunAi
                      : l10n.teacherExamRunAi,
                ),
              );
              final save = FilledButton.tonal(
                style: mobile
                    ? TeacherMobileUi.mobileFilledCompactStyle(context)
                    : TeacherWebUi.compactFilledStyle(context),
                onPressed: () => _save(finalize: false),
                child: Text(l10n.teacherGradingSaveScores),
              );
              final finalize = FilledButton(
                style: mobile
                    ? TeacherMobileUi.mobileFilledCompactStyle(context)
                    : TeacherWebUi.compactFilledStyle(context),
                onPressed: gs == 'finalized' ? null : _finalize,
                child: Text(l10n.teacherGradingFinalize),
              );
              final release = OutlinedButton(
                style: mobile
                    ? TeacherMobileUi.mobileOutlinedCompactStyle(context)
                    : TeacherWebUi.compactOutlinedStyle(context),
                onPressed: (gs == 'finalized' && !released) ? _release : null,
                child: Text(l10n.teacherExamReleaseResults),
              );

              if (narrow || mobile) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      runAi,
                      const SizedBox(width: 8),
                      save,
                      const SizedBox(width: 8),
                      finalize,
                      const SizedBox(width: 8),
                      release,
                    ],
                  ),
                );
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    runAi,
                    const SizedBox(width: 8),
                    save,
                    const SizedBox(width: 8),
                    finalize,
                    const SizedBox(width: 8),
                    release,
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<TeacherExamAttemptGradeBloc, TeacherExamAttemptGradeState>(
      listenWhen: (prev, curr) =>
          (curr.attempt != null && prev.attempt != curr.attempt) ||
          (curr.errorMessage != null && prev.errorMessage != curr.errorMessage) ||
          (curr.successMessage != null && prev.successMessage != curr.successMessage),
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppCornerToast.show(context, state.errorMessage!, error: true);
        }
        final success = state.successMessage;
        if (success == 'ai_done') {
          final msg = _isIntegratedFormat
              ? context.l10n.integratedWritingGradingRunAi
              : context.l10n.teacherExamRunAi;
          AppCornerToast.show(context, msg);
        } else if (success == 'saved') {
          AppCornerToast.show(context, l10n.teacherGradingSaved);
        } else if (success == 'skill_saved') {
          AppCornerToast.show(context, l10n.integratedSkillScoreSaved);
        }
        if (state.attempt != null) {
          _syncControllersFromAttempt(state.attempt!);
        }
      },
      builder: (context, state) {
        final loading = state.status == TeacherExamAttemptGradeStatus.loading;
        final error = state.status == TeacherExamAttemptGradeStatus.error ? state.errorMessage : null;

        return TeacherPageScaffold(
          title: l10n.teacherGradingDetailTitle,
          showBack: true,
          scrollable: false,
          maxWidth: TeacherWebUi.contentMaxEditor,
          breadcrumbs: [
            TeacherBreadcrumb(label: l10n.teacherNavDashboard, location: TeacherDashboardPage.routePath),
            TeacherBreadcrumb(label: l10n.teacherDashboardSectionGrading),
            TeacherBreadcrumb(label: l10n.teacherGradingDetailTitle),
          ],
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.s7),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(error, textAlign: TextAlign.center, style: TeacherWebUi.webBody(context)),
                            const SizedBox(height: AppSpacing.s5),
                            TeacherRetryButton(
                              onPressed: () => _bloc.add(const TeacherExamAttemptGradeLoadRequested()),
                            ),
                          ],
                        ),
                      ),
                    )
                  : state.attempt == null
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            Expanded(
                              child: E4cScrollableColumn(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: ExamSystemUi.webTeacherContentMaxWidth),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        _summaryHeader(context, l10n),
                                        const SizedBox(height: ExamSystemUi.cardGap),
                                        _statusChips(context, l10n),
                                        const SizedBox(height: ExamSystemUi.blockGap),
                                        _metaLines(l10n),
                                        const SizedBox(height: ExamSystemUi.blockGap),
                                        _totalScoreCard(context, l10n),
                                        ..._buildIntegratedWorkSection(context, l10n),
                                        ..._classicItemsSection(context, l10n),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _bottomActions(context, l10n),
                          ],
                        ),
        );
      },
    );
  }
}

class _GradeChip extends StatelessWidget {
  const _GradeChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: ExamSystemUi.captionSecondary.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
