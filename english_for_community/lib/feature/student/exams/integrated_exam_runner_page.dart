import 'dart:async';

import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/socket/socket_service.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/student/exams/exam_embedded_skill_panel.dart';
import 'package:english_for_community/feature/student/exams/exam_section_resources.dart';
import 'package:english_for_community/feature/student/exams/exam_integrity_tracker.dart';
import 'package:english_for_community/feature/student/exams/exam_live_session_guard.dart';
import 'package:english_for_community/feature/student/exams/integrated_exam_grammar_widgets.dart';
import 'package:english_for_community/feature/student/exams/integrated_exam_score_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// In-app hub for exams that link CMS skill exercises + optional Grammar (mixed item types).
class IntegratedExamRunnerPage extends StatefulWidget {
  const IntegratedExamRunnerPage({super.key, required this.attemptId});

  final String attemptId;

  @override
  State<IntegratedExamRunnerPage> createState() => _IntegratedExamRunnerPageState();
}

class _IntegratedExamRunnerPageState extends State<IntegratedExamRunnerPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _attempt;
  int _grammarNavIndex = 0;
  int _selectedPartIndex = 0;
  final Set<int> _visitedPartIndices = {};
  bool _detailsExpanded = false;
  Timer? _clock;
  Timer? _liveViewDebounce;
  late final ExamLiveSessionGuard _liveGuard;
  bool _abandonBusy = false;

  @override
  void initState() {
    super.initState();
    _liveGuard = ExamLiveSessionGuard(context);
    _load();
  }

  @override
  void dispose() {
    _liveGuard.dispose();
    _clock?.cancel();
    _liveViewDebounce?.cancel();
    super.dispose();
  }

  void _applyAttemptMap(dynamic raw) {
    final next = Map<String, dynamic>.from(raw as Map);
    final prevCtx = _attempt?['runtimeContext'];
    if (prevCtx is Map && next['runtimeContext'] == null) {
      next['runtimeContext'] = prevCtx;
    }
    setState(() => _attempt = next);
    _restartClock();
    _clampGrammarIndex();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleSyncLiveView();
    });
  }

  void _restartClock() {
    _clock?.cancel();
    final st = _attempt?['status'] as String? ?? '';
    if (st != 'in_progress') return;
    if (_deadline() == null && _parseIso(_runtimeContext()?['closesAt']) == null && _parseIso(_runtimeContext()?['dueAt']) == null) {
      return;
    }
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final d = _deadline();
      if (d != null && DateTime.now().isAfter(d)) {
        _load();
        return;
      }
      setState(() {});
    });
  }

  void _clampGrammarIndex() {
    final n = _grammarItems().length;
    if (n == 0) {
      _grammarNavIndex = 0;
      return;
    }
    if (_grammarNavIndex >= n) {
      setState(() => _grammarNavIndex = n - 1);
    }
  }

  void _clampSelectedPart() {
    final n = _examParts().length;
    if (n == 0) {
      _selectedPartIndex = 0;
      return;
    }
    if (_selectedPartIndex >= n) {
      setState(() => _selectedPartIndex = n - 1);
    }
  }

  /// Ordered parts: Grammar (if any) then each enabled skill section.
  List<_IntegratedExamPart> _examParts() {
    final l10n = context.l10n;
    final parts = <_IntegratedExamPart>[];
    final grammar = _grammarItems();
    if (grammar.isNotEmpty) {
      final allGrammarDone = grammar.every(_grammarAnswered);
      parts.add(_IntegratedExamPart(
        key: '__grammar__',
        title: l10n.integratedExamGrammarSectionTitle,
        isGrammar: true,
        done: allGrammarDone,
      ));
    }
    for (final s in _sections()) {
      final sid = s['sectionId'] as String? ?? '';
      final skill = s['skill'] as String? ?? '';
      parts.add(_IntegratedExamPart(
        key: sid,
        title: _skillTitle(skill),
        isGrammar: false,
        section: s,
        done: _isSectionDone(sid),
      ));
    }
    return parts;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await getIt<TeacherExamRepository>().getExamAttempt(widget.attemptId);
    if (!mounted) return;
    r.fold(
      (f) => setState(() {
        _error = f.message;
        _loading = false;
        _clock?.cancel();
      }),
      (d) {
        _attempt = Map<String, dynamic>.from(d as Map);
        _loading = false;
        _error = null;
        _liveGuard.bindFromAttempt(_attempt);
        _restartClock();
        _clampGrammarIndex();
        _clampSelectedPart();
        _visitedPartIndices.add(_selectedPartIndex);
        setState(() {});
        unawaited(_flushLiveViewToServer());
      },
    );
  }

  void _scheduleSyncLiveView() {
    if ((_runtimeContext()?['assignmentMode'] as String?) != 'realtime') return;
    _liveViewDebounce?.cancel();
    _liveViewDebounce = Timer(const Duration(milliseconds: 80), () {
      _liveViewDebounce = null;
      if (mounted) unawaited(_flushLiveViewToServer());
    });
  }

  Future<void> _flushLiveViewToServer() async {
    final sessionId = (_attempt?['sessionId'] ?? _runtimeContext()?['sessionId'])?.toString();
    if (sessionId == null || sessionId.isEmpty) return;
    if ((_attempt?['status'] as String?) != 'in_progress') return;
    if ((_runtimeContext()?['assignmentMode'] as String?) != 'realtime') return;

    final parts = _examParts();
    if (parts.isEmpty) return;
    final idx = _selectedPartIndex.clamp(0, parts.length - 1);
    final part = parts[idx];
    final grammar = _grammarItems();
    final gi = grammar.isEmpty ? 0 : _grammarNavIndex.clamp(0, grammar.length - 1);
    final currentGrammarItemId = grammar.isNotEmpty ? grammar[gi]['itemId']?.toString() : null;

    final r = await getIt<TeacherExamRepository>().syncExamAttemptLiveView(
      widget.attemptId,
      {
        'activePartIndex': idx,
        'grammarNavIndex': gi,
        'activePartKey': part.key,
        if (currentGrammarItemId != null) 'currentGrammarItemId': currentGrammarItemId,
      },
    );
    if (!mounted) return;
    r.fold((_) {}, (_) {});
  }

  void _setGrammarNavIndex(int index) {
    final grammar = _grammarItems();
    if (grammar.isEmpty) return;
    final next = index.clamp(0, grammar.length - 1);
    if (next == _grammarNavIndex) return;
    setState(() => _grammarNavIndex = next);
    _scheduleSyncLiveView();
  }

  Map<String, dynamic>? _runtimeContext() {
    final c = _attempt?['runtimeContext'];
    if (c is! Map) return null;
    return Map<String, dynamic>.from(c);
  }

  DateTime? _parseIso(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  /// Hard stop from server: per-attempt deadline (time limit merged with window).
  DateTime? _deadline() {
    final top = _parseIso(_attempt?['attemptDeadlineAt']);
    if (top != null) return top;
    return _parseIso(_runtimeContext()?['attemptDeadlineAt']);
  }

  Map<String, dynamic>? _snapshot() {
    final snap = _attempt?['examSnapshot'];
    if (snap is! Map) return null;
    return Map<String, dynamic>.from(snap);
  }

  List<Map<String, dynamic>> _sections() {
    final snap = _snapshot();
    if (snap == null) return [];
    final raw = snap['sections'] as List?;
    if (raw == null) return [];
    final secs = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    secs.sort((a, b) => (a['order'] as num?)?.compareTo((b['order'] as num?) ?? 0) ?? 0);
    return secs;
  }

  List<Map<String, dynamic>> _grammarItems() {
    final snap = _snapshot();
    if (snap == null) return [];
    final settings = snap['settings'] as Map?;
    final raw = settings?['grammarItems'] as List?;
    if (raw == null) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  bool _isSectionDone(String sectionId) {
    final ans = _attempt?['answers'];
    if (ans is! Map) return false;
    final a = ans[sectionId];
    if (a is! Map) return false;
    return a['completed'] == true;
  }

  bool _grammarAnswered(Map<String, dynamic> item) {
    final id = item['itemId'] as String? ?? '';
    if (id.isEmpty) return false;
    final ans = _attempt?['answers'];
    if (ans is! Map) return false;
    final a = ans[id];
    if (a is! Map) return false;
    return grammarAnswerLooksComplete(item, Map<String, dynamic>.from(a));
  }

  Map<String, dynamic> _mergeGrammarAnswer(String itemId, Map<String, dynamic> partial) {
    final ans = _attempt?['answers'];
    final existing = (ans is Map && ans[itemId] is Map)
        ? Map<String, dynamic>.from(ans[itemId] as Map)
        : <String, dynamic>{};
    partial.forEach((key, value) {
      if (key == 'blanks' && value is Map) {
        final prev = (existing['blanks'] is Map)
            ? Map<String, dynamic>.from(existing['blanks'] as Map)
            : <String, dynamic>{};
        prev.addAll(Map<String, dynamic>.from(value));
        existing['blanks'] = prev;
      } else if (key == 'matching' && value is Map) {
        final prev = (existing['matching'] is Map)
            ? Map<String, dynamic>.from(existing['matching'] as Map)
            : <String, dynamic>{};
        prev.addAll(Map<String, dynamic>.from(value));
        existing['matching'] = prev;
      } else {
        existing[key] = value;
      }
    });
    return existing;
  }

  Future<void> _patchSection(String sectionId, bool completed) async {
    final r = await getIt<TeacherExamRepository>().patchExamAttempt(widget.attemptId, {
      sectionId: {'completed': completed},
    });
    if (!mounted) return;
    r.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
      (d) => _applyAttemptMap(d),
    );
  }

  Future<void> _patchGrammarPartial(String itemId, Map<String, dynamic> partial) async {
    final merged = _mergeGrammarAnswer(itemId, partial);
    final r = await getIt<TeacherExamRepository>().patchExamAttempt(widget.attemptId, {
      itemId: merged,
    });
    if (!mounted) return;
    r.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
      (d) {
        _applyAttemptMap(d);
        _scheduleSyncLiveView();
      },
    );
  }

  Future<void> _patchSectionDraft(String sectionId, Map<String, dynamic> body) async {
    final r = await getIt<TeacherExamRepository>().patchExamAttempt(widget.attemptId, {
      sectionId: body,
    });
    if (!mounted) return;
    r.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
      (d) {
        _applyAttemptMap(d);
        _scheduleSyncLiveView();
      },
    );
  }

  void _onWritingDraftChanged(String sectionId, String text) {
    final ans = _attempt?['answers'];
    final existing = (ans is Map && ans[sectionId] is Map)
        ? Map<String, dynamic>.from(ans[sectionId] as Map)
        : <String, dynamic>{};
    final words = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    _patchSectionDraft(sectionId, {
      ...existing,
      'writingDraft': text,
      'wordCount': words,
    });
  }

  void _onSkillPartComplete(String sectionId) {
    _patchSection(sectionId, true);
  }

  Map<String, int>? _readingInitialAnswers(String sectionId) {
    final ans = _attempt?['answers'];
    if (ans is! Map || ans[sectionId] is! Map) return null;
    final raw = (ans[sectionId] as Map)['readingAnswers'];
    if (raw is! Map) return null;
    final out = <String, int>{};
    raw.forEach((k, v) {
      if (v is num) out['$k'] = v.toInt();
    });
    return out.isEmpty ? null : out;
  }

  void _onReadingAnswersChanged(String sectionId, Map<String, int> answers, int totalQuestions) {
    final allAnswered = totalQuestions > 0 && answers.length >= totalQuestions;
    final ans = _attempt?['answers'];
    final existing = (ans is Map && ans[sectionId] is Map)
        ? Map<String, dynamic>.from(ans[sectionId] as Map)
        : <String, dynamic>{};
    _patchSectionDraft(sectionId, {
      ...existing,
      'readingAnswers': answers.map((k, v) => MapEntry(k, v)),
      if (allAnswered) 'completed': true,
    });
  }

  String? _writingInitialDraft(String sectionId) {
    final ans = _attempt?['answers'];
    if (ans is! Map || ans[sectionId] is! Map) return null;
    final draft = (ans[sectionId] as Map)['writingDraft'];
    if (draft is! String || draft.trim().isEmpty) return null;
    return draft;
  }

  Map<String, String>? _listeningInitialCueTexts(String sectionId) {
    final ans = _attempt?['answers'];
    if (ans is! Map || ans[sectionId] is! Map) return null;
    final raw = (ans[sectionId] as Map)['listeningCues'];
    if (raw is! Map) return null;
    final out = <String, String>{};
    raw.forEach((k, v) {
      if (v is String && v.trim().isNotEmpty) out['$k'] = v.trim();
    });
    return out.isEmpty ? null : out;
  }

  void _onListeningProgress(
    String sectionId,
    Map<String, String> cueTextsByIndex,
    int saved,
    int total,
  ) {
    final allSaved = total > 0 && saved >= total;
    final ans = _attempt?['answers'];
    final existing = (ans is Map && ans[sectionId] is Map)
        ? Map<String, dynamic>.from(ans[sectionId] as Map)
        : <String, dynamic>{};
    _patchSectionDraft(sectionId, {
      ...existing,
      'listeningCues': cueTextsByIndex,
      'listeningSaved': saved,
      'listeningTotal': total,
      if (allSaved) 'completed': true,
    });
  }

  String _skillTitle(String skill) {
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

  bool _allowPartialSubmit() {
    final ctx = _runtimeContext();
    if (ctx?['allowPartialSubmit'] == false) return false;
    return true;
  }

  List<String> _incompletePartLabels() {
    final l10n = context.l10n;
    final missing = <String>[];
    final grammar = _grammarItems();
    for (var i = 0; i < grammar.length; i++) {
      if (!_grammarAnswered(grammar[i])) {
        missing.add('${l10n.integratedExamGrammarSectionTitle} — ${l10n.integratedExamGrammarQuestionLabel(i + 1, grammar.length)}');
      }
    }
    for (final s in _sections()) {
      final sid = s['sectionId'] as String? ?? '';
      if (!_isSectionDone(sid)) {
        missing.add(_skillTitle(s['skill'] as String? ?? ''));
      }
    }
    return missing;
  }

  int _doneCount(List<Map<String, dynamic>> secs, List<Map<String, dynamic>> grammar) {
    var n = 0;
    for (final s in secs) {
      final sid = s['sectionId'] as String? ?? '';
      if (_isSectionDone(sid)) n++;
    }
    for (final g in grammar) {
      if (_grammarAnswered(g)) n++;
    }
    return n;
  }

  String _deliveryLabel(Map<String, dynamic>? ctx) {
    final l10n = context.l10n;
    if (ctx == null) return l10n.integratedExamRunnerTitle;
    final mode = ctx['assignmentMode'] as String?;
    final aud = ctx['audience'] as String?;
    if (aud == 'public_link') return l10n.integratedExamMetaPublic;
    switch (mode) {
      case 'self_paced':
        return l10n.integratedExamMetaModeHomework;
      case 'scheduled':
        return l10n.integratedExamMetaModeScheduled;
      case 'realtime':
        return l10n.integratedExamMetaModeLive;
      default:
        return l10n.integratedExamRunnerTitle;
    }
  }

  String _formatShortDate(DateTime d) {
    return DateFormat.yMMMd().add_jm().format(d);
  }

  String _formatRemaining(Duration d, String expiredLabel) {
    if (d.isNegative) return expiredLabel;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  bool _canSubmitExam(int doneCount, int total) {
    return total > 0 && (doneCount == total || _allowPartialSubmit());
  }

  Widget _buildSubmitChip({required bool enabled}) {
    return FilledButton.tonal(
      onPressed: enabled ? _submit : null,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(context.l10n.integratedExamSubmitShort, style: ExamSystemUi.embeddedButtonLabelStyle),
    );
  }

  Widget _buildCompactSummary(
    Map<String, dynamic>? ctx,
    String examTitleFallback, {
    required int doneCount,
    required int total,
    required bool submitted,
    required bool expired,
  }) {
    final l10n = context.l10n;
    final title = (ctx?['examTitle'] as String?)?.trim();
    final displayTitle = (title != null && title.isNotEmpty) ? title : examTitleFallback;
    final deadline = _deadline();
    final now = DateTime.now();
    String? urgencyLine;
    Color urgencyColor = AppColors.textSecondary;
    if (deadline != null && _attempt?['status'] == 'in_progress') {
      final left = deadline.difference(now);
      urgencyLine = '${l10n.integratedExamMetaDeadline}: ${_formatRemaining(left, l10n.integratedExamTimeUpShort)}';
      if (left.inMinutes < 5 && !left.isNegative) urgencyColor = AppColors.warning;
      if (left.isNegative) urgencyColor = AppColors.chartTrend;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(displayTitle, style: ExamSystemUi.sectionTitle(context), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            _MetaChip(icon: Icons.label_outline, label: _deliveryLabel(ctx)),
          ],
        ),
        if (urgencyLine != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: urgencyColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  urgencyLine,
                  style: ExamSystemUi.captionSecondary.copyWith(color: urgencyColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
        if (!submitted && !expired && total > 0) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: doneCount / total,
              minHeight: 8,
              backgroundColor: AppColors.outlineMuted,
              color: AppSkillColors.listening.color,
            ),
          ),
          const SizedBox(height: 6),
          Text(l10n.integratedExamProgress(doneCount, total), style: ExamSystemUi.captionSecondary),
        ],
      ],
    );
  }

  Widget _buildDetailsExpansion(Map<String, dynamic>? ctx, String examTitleFallback) {
    final l10n = context.l10n;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _detailsExpanded = !_detailsExpanded),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineMuted, width: 0.75),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(child: Text(l10n.integratedExamDetailsTitle, style: ExamSystemUi.listTitle(context))),
                    Icon(_detailsExpanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textMuted),
                  ],
                ),
              ),
              if (_detailsExpanded) ...[
                const Divider(height: 1, thickness: 0.5),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: _buildMetaDetailsBody(ctx, examTitleFallback),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaDetailsBody(Map<String, dynamic>? ctx, String examTitleFallback) {
    final l10n = context.l10n;
    final subject = (ctx?['subject'] as String?)?.trim();
    final subjectLine = (subject != null && subject.isNotEmpty) ? subject : l10n.integratedExamSubjectDefault;
    final classroom = (ctx?['classroomName'] as String?)?.trim();
    final teacher = (ctx?['teacherName'] as String?)?.trim();
    final student = (ctx?['studentName'] as String?)?.trim();
    final tlSec = ctx?['timeLimitSeconds'];
    final limitMin = tlSec != null ? (int.tryParse('$tlSec') ?? 0) : 0;
    final due = _parseIso(ctx?['dueAt']);
    final closes = _parseIso(ctx?['closesAt']);
    final opens = _parseIso(ctx?['opensAt']);
    final started = _parseIso(ctx?['startedAt']) ?? _parseIso(_attempt?['startedAt']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _metaRow(Icons.menu_book_outlined, l10n.integratedExamMetaSubject, subjectLine),
        _metaRow(Icons.class_outlined, l10n.integratedExamMetaClass,
              (classroom != null && classroom.isNotEmpty) ? classroom : l10n.integratedExamNoClassName),
          _metaRow(Icons.person_outline, l10n.integratedExamMetaTeacher, teacher ?? '—'),
          _metaRow(Icons.school_outlined, l10n.integratedExamMetaStudent, student ?? '—'),
          if (limitMin > 0)
            _metaRow(
              Icons.hourglass_top_outlined,
              l10n.integratedExamMetaTimeLimit,
              l10n.integratedExamMetaTimeLimitMinutes(limitMin),
            )
          else
            _metaRow(Icons.hourglass_disabled_outlined, l10n.integratedExamMetaTimeLimit, l10n.integratedExamMetaNoTimeLimit),
          if (due != null)
            _metaRow(Icons.event_available_outlined, l10n.integratedExamMetaDue, _formatShortDate(due)),
          if (opens != null) _metaRow(Icons.lock_open_outlined, l10n.integratedExamMetaOpens, _formatShortDate(opens)),
          if (closes != null) _metaRow(Icons.event_busy_outlined, l10n.integratedExamMetaWindow, _formatShortDate(closes)),
          if (started != null) _metaRow(Icons.play_circle_outline, l10n.integratedExamMetaStarted, _formatShortDate(started)),
      ],
    );
  }

  Widget _buildPartSelector(List<_IntegratedExamPart> parts, bool locked) {
    if (parts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: parts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final p = parts[i];
              final selected = i == _selectedPartIndex;
              return _PartTabChip(
                label: p.title,
                selected: selected,
                done: p.done,
                locked: locked,
                onTap: locked
                    ? null
                    : () {
                          setState(() {
                            _selectedPartIndex = i;
                            _visitedPartIndices.add(i);
                          });
                          unawaited(_flushLiveViewToServer());
                        },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGrammarPanel(List<Map<String, dynamic>> grammar, bool locked) {
    final l10n = context.l10n;
    if (grammar.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.integratedExamGrammarSectionTitle, style: ExamSystemUi.sectionTitle(context)),
            ),
            if (grammar.length > 1)
              IconButton(
                tooltip: l10n.integratedExamGrammarPrevious,
                onPressed: _grammarNavIndex <= 0 ? null : () => _setGrammarNavIndex(_grammarNavIndex - 1),
                icon: const Icon(Icons.chevron_left),
              ),
            if (grammar.length > 1)
              IconButton(
                tooltip: l10n.integratedExamGrammarNext,
                onPressed:
                    _grammarNavIndex >= grammar.length - 1 ? null : () => _setGrammarNavIndex(_grammarNavIndex + 1),
                icon: const Icon(Icons.chevron_right),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(l10n.integratedExamGrammarNavHint, style: ExamSystemUi.captionMuted),
        const SizedBox(height: 10),
        _grammarNumberStrip(grammar),
        const SizedBox(height: 6),
        Text(
          l10n.integratedExamGrammarQuestionLabel(_grammarNavIndex + 1, grammar.length),
          style: ExamSystemUi.captionSecondary,
        ),
        const SizedBox(height: ExamSystemUi.cardGap),
        IntegratedExamGrammarQuestionCard(
          key: ValueKey<String>('${grammar[_grammarNavIndex]['itemId']}_$_grammarNavIndex'),
          displayIndex: _grammarNavIndex + 1,
          item: grammar[_grammarNavIndex],
          answer: () {
            final ans = _attempt?['answers'];
            if (ans is! Map) return null;
            final a = ans[grammar[_grammarNavIndex]['itemId']];
            if (a is! Map) return null;
            return Map<String, dynamic>.from(a);
          }(),
          locked: locked,
          onPartialPatch: (p) => _patchGrammarPartial('${grammar[_grammarNavIndex]['itemId']}', p),
        ),
      ],
    );
  }

  /// Renders all parts using Offstage so state (WritingTaskBloc, etc.) is preserved
  /// when the student switches between tabs.
  Widget _buildPartsStack(List<_IntegratedExamPart> parts, bool locked) {
    if (parts.isEmpty) {
      return Center(child: Text(context.l10n.integratedExamGrammarUnsupported, style: ExamSystemUi.captionSecondary));
    }
    final activeIdx = _selectedPartIndex.clamp(0, parts.length - 1);
    return Stack(
      children: parts.asMap().entries.map((entry) {
        final i = entry.key;
        final part = entry.value;
        final isActive = i == activeIdx;
        // Lazy: only build parts that have been visited at least once
        if (!_visitedPartIndices.contains(i)) {
          return Offstage(offstage: true, child: const SizedBox.shrink());
        }
        final Widget pane;
        if (part.isGrammar) {
          pane = SingleChildScrollView(
            padding: ExamSystemUi.pagePadding.copyWith(top: ExamSystemUi.cardGap, bottom: 24),
            child: _buildGrammarPanel(_grammarItems(), locked),
          );
        } else {
          pane = Padding(
            padding: ExamSystemUi.pagePadding.copyWith(top: ExamSystemUi.cardGap, bottom: 8),
            child: _buildSkillPartContent(part.section!, locked),
          );
        }

        return Offstage(
          offstage: !isActive,
          child: TickerMode(
            enabled: isActive,
            child: part.isGrammar
                ? pane
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [Expanded(child: pane)],
                  ),
          ),
        );
      }).toList(),
    );
  }

  Map<String, dynamic>? _fixedWritingPrompt(Map<String, dynamic> section) {
    final raw = section['fixedWritingPrompt'];
    if (raw is Map && (raw['text'] as String?)?.isNotEmpty == true) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  Widget _buildSkillPartContent(Map<String, dynamic> section, bool locked) {
    final skill = section['skill'] as String? ?? '';
    final sectionId = section['sectionId'] as String? ?? '';
    final resources = _getSectionResources(section);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ExamEmbeddedSkillPanel(
            key: ValueKey<String>('panel_$sectionId'),
            skill: skill,
            resources: resources,
            locked: locked,
            sectionId: sectionId,
            initialReadingAnswers: skill == 'reading' ? _readingInitialAnswers(sectionId) : null,
            onReadingAnswersChanged: skill == 'reading'
                ? (answers, total) => _onReadingAnswersChanged(sectionId, answers, total)
                : null,
            initialListeningCueTexts:
                skill == 'listening' ? _listeningInitialCueTexts(sectionId) : null,
            onListeningProgress: skill == 'listening'
                ? (cues, saved, total) => _onListeningProgress(sectionId, cues, saved, total)
                : null,
            initialWritingDraft: skill == 'writing' ? _writingInitialDraft(sectionId) : null,
            fixedWritingPrompt: skill == 'writing' ? _fixedWritingPrompt(section) : null,
            onPartComplete: () => _onSkillPartComplete(sectionId),
            onWritingDraftChanged: skill == 'writing'
                ? (text) => _onWritingDraftChanged(sectionId, text)
                : null,
            examPracticeMode: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmittedSummary(List<_IntegratedExamPart> parts, List<Map<String, dynamic>> grammar, List<Map<String, dynamic>> secs) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (grammar.isNotEmpty) ...[
          Text(l10n.integratedExamGrammarSectionTitle, style: ExamSystemUi.sectionTitle(context)),
          const SizedBox(height: ExamSystemUi.cardGap),
          for (var i = 0; i < grammar.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: ExamSystemUi.cardGap),
              child: IntegratedExamGrammarQuestionCard(
                displayIndex: i + 1,
                item: grammar[i],
                answer: () {
                  final ans = _attempt?['answers'];
                  if (ans is! Map) return null;
                  final a = ans[grammar[i]['itemId']];
                  if (a is! Map) return null;
                  return Map<String, dynamic>.from(a);
                }(),
                locked: true,
                onPartialPatch: (_) {},
              ),
            ),
        ],
        if (secs.isNotEmpty) ...[
          Text(l10n.integratedExamSkillsSectionTitle, style: ExamSystemUi.sectionTitle(context)),
          const SizedBox(height: ExamSystemUi.cardGap),
          for (final s in secs) _buildSectionTile(s, true, expanded: false),
        ],
      ],
    );
  }

  Widget _metaRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(label, style: ExamSystemUi.captionMuted),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: ExamSystemUi.captionSecondary, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _grammarNumberStrip(List<Map<String, dynamic>> grammar) {
    final n = grammar.length;
    if (n == 0) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < n; i++)
          _GrammarNavPill(
            index: i + 1,
            selected: i == _grammarNavIndex,
            answered: _grammarAnswered(grammar[i]),
            onTap: () => _setGrammarNavIndex(i),
          ),
      ],
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final secs = _sections();
    final grammar = _grammarItems();
    final total = secs.length + grammar.length;
    final doneCount = _doneCount(secs, grammar);
    if (total > 0 && doneCount < total) {
      if (!_allowPartialSubmit()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.integratedExamSubmitBlockedAll)));
        }
        return;
      }
      final incomplete = _incompletePartLabels();
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(l10n.examPartialSubmitTitle),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.examPartialSubmitMessage),
                  if (incomplete.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(l10n.examPartialSubmitIncompleteHeader, style: ExamSystemUi.captionMuted),
                    const SizedBox(height: 6),
                    ...incomplete.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(line)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.examPartialSubmitConfirm)),
            ],
          );
        },
      );
      if (confirm != true || !mounted) return;
    }
    final r = await getIt<TeacherExamRepository>().submitExamAttempt(widget.attemptId);
    if (!mounted) return;
    r.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.studentExamSubmitted)));
        _load();
      },
    );
  }

  bool _isRealtimeInProgress() {
    final rt = _attempt?['runtimeContext'];
    if (rt is! Map || rt['assignmentMode'] != 'realtime') return false;
    return (_attempt?['status'] as String? ?? '') == 'in_progress';
  }

  Future<bool> _confirmLeaveRealtimeExam() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.studentExamLeaveRealtimeTitle),
        content: Text(l10n.studentExamLeaveRealtimeMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.studentExamLeaveRealtimeCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.studentExamLeaveRealtimeConfirm),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _abandonRealtimeAndExit() async {
    if (_abandonBusy) return;
    setState(() => _abandonBusy = true);
    final l10n = context.l10n;
    final r = await getIt<TeacherExamRepository>().abandonExamAttempt(widget.attemptId);
    if (!mounted) return;
    await r.fold(
      (f) async {
        setState(() => _abandonBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message)));
      },
      (_) async {
        getIt<SocketService>().clearExamRealtimeContext();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.studentExamVoluntaryExitBlocked)),
        );
        exitLiveExamFlow(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = _attempt?['status'] as String? ?? '';
    final submitted = status == 'submitted';
    final expired = status == 'expired';
    final secs = _sections();
    final grammar = _grammarItems();
    final total = secs.length + grammar.length;
    final doneCount = _doneCount(secs, grammar);
    final ctx = _runtimeContext();
    final barTitle = (ctx?['examTitle'] as String?)?.trim();
    final appTitle = (barTitle != null && barTitle.isNotEmpty) ? barTitle : l10n.integratedExamRunnerTitle;

    final shell = PopScope<Object?>(
      canPop: !_isRealtimeInProgress(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          final rt = _attempt?['runtimeContext'];
          if (rt is Map && rt['assignmentMode'] == 'realtime') {
            getIt<SocketService>().clearExamRealtimeContext();
          }
          return;
        }
        if (!_isRealtimeInProgress()) return;
        _confirmLeaveRealtimeExam().then((leave) {
          if (!leave || !mounted) return;
          _abandonRealtimeAndExit();
        });
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: StudentMobileUi.appBar(
          context,
          title: appTitle,
          actions: (!submitted && !expired && !_loading && _error == null)
              ? [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Center(
                      child: _buildSubmitChip(enabled: _canSubmitExam(doneCount, total)),
                    ),
                  ),
                ]
              : null,
        ),
        body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: ExamSystemUi.pagePadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center, style: ExamSystemUi.captionSecondary),
                        const SizedBox(height: ExamSystemUi.blockGap),
                        FilledButton(onPressed: _load, child: Text(l10n.retry)),
                      ],
                    ),
                  ),
                )
              : _buildRunnerBody(
                  ctx: ctx,
                  examTitleFallback: l10n.integratedExamRunnerTitle,
                  submitted: submitted,
                  expired: expired,
                  secs: secs,
                  grammar: grammar,
                  total: total,
                  doneCount: doneCount,
                ),
      ),
    );
    if (!submitted && !expired) {
      return ExamIntegrityTracker(attemptId: widget.attemptId, child: shell);
    }
    return shell;
  }

  Widget _buildRunnerBody({
    required Map<String, dynamic>? ctx,
    required String examTitleFallback,
    required bool submitted,
    required bool expired,
    required List<Map<String, dynamic>> secs,
    required List<Map<String, dynamic>> grammar,
    required int total,
    required int doneCount,
  }) {
    final l10n = context.l10n;
    final parts = _examParts();
    final locked = submitted || expired;
    final headerPad = ExamSystemUi.pagePadding.copyWith(bottom: 0);

    if (submitted || expired) {
      return ListView(
        padding: ExamSystemUi.pagePadding,
        children: [
          _buildCompactSummary(
            ctx,
            examTitleFallback,
            doneCount: doneCount,
            total: total,
            submitted: submitted,
            expired: expired,
          ),
          const SizedBox(height: ExamSystemUi.blockGap),
          _buildDetailsExpansion(ctx, examTitleFallback),
          if (expired) ...[
            const SizedBox(height: ExamSystemUi.blockGap),
            AppCard(
              variant: AppCardVariant.outline,
              child: Text(l10n.studentExamExpired, style: ExamSystemUi.captionSecondary),
            ),
          ],
          const SizedBox(height: ExamSystemUi.sectionGap),
          _buildSubmittedSummary(parts, grammar, secs),
          if (submitted && _attempt?['scores'] is Map) ...[
            const SizedBox(height: ExamSystemUi.sectionGap),
            IntegratedScoreSummaryCard(
              attempt: Map<String, dynamic>.from(_attempt!),
              scores: Map<String, dynamic>.from(_attempt!['scores'] as Map),
              title: context.l10n.teacherAttemptGradeTotalScore,
            ),
          ],
          const SizedBox(height: 80),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: headerPad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCompactSummary(
                ctx,
                examTitleFallback,
                doneCount: doneCount,
                total: total,
                submitted: submitted,
                expired: expired,
              ),
              const SizedBox(height: ExamSystemUi.blockGap),
              _buildDetailsExpansion(ctx, examTitleFallback),
              const SizedBox(height: ExamSystemUi.sectionGap),
              _buildPartSelector(parts, locked),
            ],
          ),
        ),
        Expanded(
          child: _buildPartsStack(parts, locked),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getSectionResources(Map<String, dynamic> s) =>
      sectionResourcesFrom(s);

  Widget _buildSectionTile(Map<String, dynamic> s, bool locked, {bool expanded = false}) {
    final skill = s['skill'] as String? ?? '';
    final sectionId = s['sectionId'] as String? ?? '';
    final resources = _getSectionResources(s);
    final done = _isSectionDone(sectionId);
    final statusLabel = done ? context.l10n.integratedExamPartDone : context.l10n.integratedExamPartNotStarted;

    return Padding(
      padding: EdgeInsets.only(bottom: expanded ? 0 : ExamSystemUi.cardGap),
      child: AppCard(
        variant: AppCardVariant.outline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Row(
                  children: [
                    Icon(
                      done ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                      size: ExamSystemUi.iconSm,
                      color: done ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_skillTitle(skill), style: ExamSystemUi.sectionTitle(context))),
                    Text(statusLabel, style: ExamSystemUi.captionMuted),
                  ],
                ),
              )
            else
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: Icon(
                  done ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                  size: ExamSystemUi.iconSm,
                  color: done ? AppColors.primary : AppColors.textSecondary,
                ),
                title: Text(_skillTitle(skill), style: ExamSystemUi.listTitle(context)),
                subtitle: resources.isEmpty
                    ? null
                    : Text(
                        resources.length == 1
                            ? (resources.first['title'] as String? ?? '')
                            : '${resources.length} exercises',
                        style: ExamSystemUi.captionSecondary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            if (expanded && resources.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  resources.length == 1
                      ? (resources.first['title'] as String? ?? '')
                      : '${resources.length} exercises',
                  style: ExamSystemUi.captionSecondary,
                ),
              ),
            if (resources.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
                child: ExamEmbeddedSkillPanel(
                  skill: skill,
                  resources: resources,
                  locked: locked,
                  fixedWritingPrompt: skill == 'writing' ? _fixedWritingPrompt(s) : null,
                  onPartComplete: locked ? () {} : () => _onSkillPartComplete(sectionId),
                  examPracticeMode: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IntegratedExamPart {
  const _IntegratedExamPart({
    required this.key,
    required this.title,
    required this.isGrammar,
    required this.done,
    this.section,
  });

  final String key;
  final String title;
  final bool isGrammar;
  final bool done;
  final Map<String, dynamic>? section;
}

class _PartTabChip extends StatelessWidget {
  const _PartTabChip({
    required this.label,
    required this.selected,
    required this.done,
    this.locked = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool done;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.primary : AppColors.outlineMuted;
    final bg = done
        ? AppColors.primary.withValues(alpha: 0.12)
        : selected
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.surfaceCard;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 0.75),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (done)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.check, size: 14, color: AppColors.primary),
                ),
              Text(
                label,
                style: TextStyle(
              fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              fontSize: 12,
              color: selected || done ? AppColors.primaryDark : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineMuted, width: 0.75),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              label,
              style: ExamSystemUi.captionMuted,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _GrammarNavPill extends StatelessWidget {
  const _GrammarNavPill({
    required this.index,
    required this.selected,
    required this.answered,
    this.onTap,
  });

  final int index;
  final bool selected;
  final bool answered;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.primary : AppColors.outlineMuted;
    final bg = answered
        ? AppColors.primary.withValues(alpha: 0.12)
        : selected
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.surfaceCard;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 0.75),
          ),
          child: Text(
            '$index',
            style: TextStyle(
              fontWeight: selected || answered ? FontWeight.w500 : FontWeight.w400,
              fontSize: 12,
              color: answered ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
