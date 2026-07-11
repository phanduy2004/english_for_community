import 'dart:async';

import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/socket/socket_service.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/ui/e4c_scroll_behavior.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/ui/motion/confetti_celebration.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/core/ui/feedback/app_feedback.dart';
import 'package:english_for_community/feature/student/exams/exam_embedded_skill_panel.dart';
import 'package:english_for_community/feature/student/exams/exam_section_tag.dart';
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
  int _selectedListeningSubIndex = 0;
  final Set<int> _visitedPartIndices = {};
  final Set<int> _visitedListeningSubIndices = {0};
  bool _detailsExpanded = false;
  Timer? _clock;
  Timer? _liveViewDebounce;
  late final ExamLiveSessionGuard _liveGuard;
  bool _abandonBusy = false;
  bool _autoSubmitting = false;

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
    final deadline = _deadline();
    if (deadline == null &&
        _parseIso(_runtimeContext()?['closesAt']) == null &&
        _parseIso(_runtimeContext()?['dueAt']) == null) {
      return;
    }
    // Timer only drives auto-submit — display is handled by _CountdownText widget.
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final d = _deadline();
      if (d != null && DateTime.now().isAfter(d)) {
        _clock?.cancel();
        _autoSubmitOnDeadline();
      }
    });
  }

  Future<void> _autoSubmitOnDeadline() async {
    if (_autoSubmitting || !mounted) return;
    final st = _attempt?['status'] as String? ?? '';
    if (st != 'in_progress') return;
    _autoSubmitting = true;
    final r = await getIt<TeacherExamRepository>().submitExamAttempt(widget.attemptId, force: true);
    if (!mounted) return;
    _autoSubmitting = false;
    r.fold(
      (_) => _load(),
      (d) {
        setState(() {
          _attempt = Map<String, dynamic>.from(d as Map);
          _loading = false;
          _error = null;
        });
        _syncLiveGuardBinding();
        _restartClock();
        AppFeedback.success(context, context.l10n.studentExamSubmitted);
      },
    );
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
    _clampListeningSubIndex();
  }

  void _clampListeningSubIndex() {
    final parts = _examParts();
    final idx = _selectedPartIndex.clamp(0, parts.isEmpty ? 0 : parts.length - 1);
    if (idx >= parts.length || !parts[idx].isMergedListening) return;
    final n = parts[idx].mergedSections!.length;
    if (n == 0) return;
    if (_selectedListeningSubIndex >= n) {
      setState(() => _selectedListeningSubIndex = n - 1);
    }
  }

  /// Mount skill panels that already have saved answers so work is visible when opened.
  void _seedVisitedPartsFromSavedWork() {
    final parts = _examParts();
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isGrammar) {
        if (_grammarItems().any(_grammarAnswered)) {
          _visitedPartIndices.add(i);
        }
      } else if (part.isMergedListening) {
        if (part.mergedSections!.any((ls) =>
            _sectionHasWork(ls['sectionId'] as String? ?? '', 'listening'))) {
          _visitedPartIndices.add(i);
        }
        for (var j = 0; j < part.mergedSections!.length; j++) {
          final ls = part.mergedSections![j];
          if (_sectionHasWork(ls['sectionId'] as String? ?? '', 'listening')) {
            _visitedListeningSubIndices.add(j);
          }
        }
      } else {
        final sec = part.section;
        final sid = sec?['sectionId'] as String? ?? '';
        final skill = sec?['skill'] as String? ?? '';
        if (_sectionHasWork(sid, skill)) {
          _visitedPartIndices.add(i);
        }
      }
    }
    _visitedPartIndices.add(_selectedPartIndex);
  }

  /// Ordered parts: Grammar (if any) then each enabled skill section.
  /// Multiple listening sections are merged into a single tab.
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

    final allSections = _sections();
    final listeningSections = allSections.where((s) => s['skill'] == 'listening').toList();
    bool listeningAdded = false;

    for (final s in allSections) {
      final sid = s['sectionId'] as String? ?? '';
      final skill = s['skill'] as String? ?? '';

      if (skill == 'listening') {
        if (listeningAdded) continue;
        listeningAdded = true;
        if (listeningSections.length == 1) {
          parts.add(_IntegratedExamPart(
            key: sid,
            title: _skillTitle('listening'),
            isGrammar: false,
            section: s,
            done: _sectionHasWork(sid, skill),
          ));
        } else {
          final allDone = listeningSections.every((ls) =>
              _sectionHasWork(ls['sectionId'] as String? ?? '', 'listening'));
          parts.add(_IntegratedExamPart(
            key: '__listening_merged__',
            title: _skillTitle('listening'),
            isGrammar: false,
            mergedSections: listeningSections,
            done: allDone,
          ));
        }
      } else {
        parts.add(_IntegratedExamPart(
          key: sid,
          title: _skillTitle(skill),
          isGrammar: false,
          section: s,
          done: _sectionHasWork(sid, skill),
        ));
      }
    }
    return parts;
  }

  void _syncLiveGuardBinding() {
    if ((_attempt?['status'] as String?) == 'in_progress') {
      _liveGuard.bindFromAttempt(_attempt);
    } else {
      _liveGuard.unbind();
    }
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
        _syncLiveGuardBinding();
        _restartClock();
        _clampGrammarIndex();
        _clampSelectedPart();
        _seedVisitedPartsFromSavedWork();
        setState(() {});
        unawaited(_flushLiveViewToServer());
      },
    );
  }

  void _scheduleSyncLiveView() {
    if ((_runtimeContext()?['assignmentMode'] as String?) != 'realtime') return;
    _liveViewDebounce?.cancel();
    _liveViewDebounce = Timer(AppMotion.micro, () {
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

  String _showResultsPolicy() {
    final rt = _runtimeContext();
    final fromRt = rt?['showResultsPolicy'] as String?;
    if (fromRt == 'after_submit' || fromRt == 'after_release' || fromRt == 'never') {
      return fromRt!;
    }
    final settings = _snapshot()?['settings'];
    if (settings is Map) {
      final fromExam = settings['showResultsPolicy'] as String?;
      if (fromExam == 'after_submit' || fromExam == 'after_release' || fromExam == 'never') {
        return fromExam!;
      }
    }
    return 'after_release';
  }

  bool _resultsReleased() {
    if (_attempt?['resultsReleased'] == true) return true;
    return _runtimeContext()?['resultsReleased'] == true;
  }

  bool _canViewScores() {
    final status = _attempt?['status'] as String? ?? '';
    if (status != 'submitted') return false;
    final policy = _showResultsPolicy();
    if (policy == 'never') return false;
    if (policy == 'after_submit') return true;
    return _resultsReleased();
  }

  String _resultsDetailLevel() {
    final rt = _runtimeContext();
    final fromRt = rt?['resultsDetailLevel'] as String?;
    if (fromRt == 'score_only' || fromRt == 'full_detail') return fromRt!;
    return 'full_detail';
  }

  /// Full answer review (grammar, skill panels) only after teacher releases results.
  bool _canViewFullGradedResults() {
    if (!_resultsReleased()) return false;
    return _resultsDetailLevel() == 'full_detail';
  }

  String _resultsReviewBlockedMessage() {
    final l10n = context.l10n;
    if (_showResultsPolicy() == 'never') {
      return l10n.integratedExamResultsNeverShown;
    }
    return l10n.integratedExamResultsAwaitingRelease;
  }

  String _skillReviewBlockedMessage() {
    if (!_resultsReleased()) return _resultsReviewBlockedMessage();
    if (_resultsDetailLevel() != 'full_detail') {
      return context.l10n.integratedExamResultsScoreOnly;
    }
    return _resultsReviewBlockedMessage();
  }

  Map<String, dynamic>? _skillScoreEntry(String sectionId) {
    final scores = _attempt?['scores'];
    if (scores is! Map) return null;
    final skillScores = scores['skillScores'];
    if (skillScores is! Map) return null;
    final raw = skillScores[sectionId];
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  String? _skillFeedback(String sectionId) {
    final note = _skillScoreEntry(sectionId)?['note'];
    if (note is String && note.trim().isNotEmpty) return note.trim();
    return null;
  }

  dynamic _skillScoreValue(String sectionId) => _skillScoreEntry(sectionId)?['score'];

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

  /// True when the student has saved work for a skill section (not manual "mark done").
  bool _sectionHasWork(String sectionId, String skill) {
    final ans = _attempt?['answers'];
    if (ans is! Map || ans[sectionId] is! Map) return false;
    final a = Map<String, dynamic>.from(ans[sectionId] as Map);
    switch (skill) {
      case 'reading':
        final ra = a['readingAnswers'];
        if (ra is Map && ra.isNotEmpty) return true;
        return false;
      case 'listening':
        final listeningType = _listeningTypeForSectionId(sectionId);
        if (listeningType == 'comprehension') {
          final lca = a['listeningCompAnswers'];
          if (lca is Map) {
            for (final v in lca.values) {
              if (v is int && v >= 0) return true;
            }
          }
          return false;
        }
        final lc = a['listeningCues'];
        if (lc is Map) {
          for (final v in lc.values) {
            if (v is String && v.trim().isNotEmpty) return true;
          }
        }
        return false;
      case 'writing':
        final draft = a['writingDraft'];
        return draft is String && draft.trim().isNotEmpty;
      case 'speaking':
        if (a['completed'] == true) return true;
        final saved = a['speakingSaved'];
        if (saved is num && saved > 0) return true;
        final idx = a['speakingSentenceIndex'];
        return idx is num && idx > 0;
      default:
        return false;
    }
  }

  String _listeningTypeForSectionId(String sectionId) {
    final snap = _attempt?['examSnapshot'];
    if (snap is! Map) return 'dictation';
    final sections = snap['sections'];
    if (sections is! List) return 'dictation';
    for (final s in sections) {
      if (s is Map && s['sectionId'] == sectionId) {
        final sc = s['sectionConfig'];
        if (sc is Map) return (sc['listeningType'] as String?) ?? 'dictation';
      }
    }
    return 'dictation';
  }

  String _listeningTypeFromSection(Map<String, dynamic> section) {
    final sc = section['sectionConfig'];
    if (sc is Map) return (sc['listeningType'] as String?) ?? 'dictation';
    return 'dictation';
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

  Future<void> _patchGrammarPartial(String itemId, Map<String, dynamic> partial) async {
    final merged = _mergeGrammarAnswer(itemId, partial);
    final r = await getIt<TeacherExamRepository>().patchExamAttempt(widget.attemptId, {
      itemId: merged,
    });
    if (!mounted) return;
    r.fold(
      (f) => AppFeedback.error(context, f.message, blocking: true),
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
      (f) => AppFeedback.error(context, f.message, blocking: true),
      (d) {
        _applyAttemptMap(d);
        _scheduleSyncLiveView();
      },
    );
  }

  VoidCallback? _speakingFinishedCallback(String sectionId) {
    return () {
      final ans = _attempt?['answers'];
      final existing = (ans is Map && ans[sectionId] is Map)
          ? Map<String, dynamic>.from(ans[sectionId] as Map)
          : <String, dynamic>{};
      _patchSectionDraft(sectionId, {...existing, 'completed': true});
    };
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
    final ans = _attempt?['answers'];
    final existing = (ans is Map && ans[sectionId] is Map)
        ? Map<String, dynamic>.from(ans[sectionId] as Map)
        : <String, dynamic>{};
    final prev = (existing['readingAnswers'] is Map)
        ? Map<String, dynamic>.from(existing['readingAnswers'] as Map)
        : <String, dynamic>{};
    answers.forEach((k, v) => prev[k] = v);
    _patchSectionDraft(sectionId, {
      ...existing,
      'readingAnswers': prev,
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
    final ans = _attempt?['answers'];
    final existing = (ans is Map && ans[sectionId] is Map)
        ? Map<String, dynamic>.from(ans[sectionId] as Map)
        : <String, dynamic>{};
    final prevCues = (existing['listeningCues'] is Map)
        ? Map<String, dynamic>.from(existing['listeningCues'] as Map)
        : <String, dynamic>{};
    cueTextsByIndex.forEach((k, v) {
      if (v.trim().isNotEmpty) prevCues[k] = v.trim();
    });
    _patchSectionDraft(sectionId, {
      ...existing,
      'listeningCues': prevCues,
      'listeningSaved': saved,
      'listeningTotal': total,
    });
  }

  void _onSpeakingProgress(
    String sectionId,
    int sentenceIndex,
    int totalSentences,
    int savedCount,
  ) {
    final ans = _attempt?['answers'];
    final existing = (ans is Map && ans[sectionId] is Map)
        ? Map<String, dynamic>.from(ans[sectionId] as Map)
        : <String, dynamic>{};
    _patchSectionDraft(sectionId, {
      ...existing,
      'speakingSentenceIndex': sentenceIndex,
      'speakingTotal': totalSentences,
      'speakingSaved': savedCount,
    });
  }

  Map<String, int>? _listeningCompInitialAnswers(String sectionId) {
    final ans = _attempt?['answers'];
    if (ans is! Map || ans[sectionId] is! Map) return null;
    final raw = (ans[sectionId] as Map)['listeningCompAnswers'];
    if (raw is! Map) return null;
    final out = <String, int>{};
    raw.forEach((k, v) {
      final idx = v is int ? v : int.tryParse('$v') ?? -1;
      if (idx >= 0) out['$k'] = idx;
    });
    return out.isEmpty ? null : out;
  }

  void _onListeningCompProgress(
    String sectionId,
    Map<String, int> answers,
    int saved,
    int total,
  ) {
    final ans = _attempt?['answers'];
    final existing = (ans is Map && ans[sectionId] is Map)
        ? Map<String, dynamic>.from(ans[sectionId] as Map)
        : <String, dynamic>{};
    final prev = (existing['listeningCompAnswers'] is Map)
        ? Map<String, dynamic>.from(existing['listeningCompAnswers'] as Map)
        : <String, dynamic>{};
    answers.forEach((k, v) => prev[k] = v);
    _patchSectionDraft(sectionId, {
      ...existing,
      'listeningCompAnswers': prev,
      'listeningCompSaved': saved,
      'listeningCompTotal': total,
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

  /// Returns a display title for incomplete part labels (differentiates sub-types
  /// only when both listening types are present).
  String _sectionDisplayTitle(Map<String, dynamic> section) {
    final skill = section['skill'] as String? ?? '';
    if (skill != 'listening') return _skillTitle(skill);

    final listeningCount =
        _sections().where((s) => s['skill'] == 'listening').length;
    if (listeningCount <= 1) return _skillTitle('listening');

    final lt = _listeningTypeFromSection(section);
    final sub = lt == 'comprehension'
        ? context.l10n.teacherExamListeningTypeComprehension
        : context.l10n.teacherExamListeningTypeDictation;
    return '${_skillTitle('listening')} ($sub)';
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
      final skill = s['skill'] as String? ?? '';
      if (!_sectionHasWork(sid, skill)) {
        missing.add(_sectionDisplayTitle(s));
      }
    }
    return missing;
  }

  int _doneCount(List<Map<String, dynamic>> secs, List<Map<String, dynamic>> grammar) {
    var n = 0;
    for (final s in secs) {
      final sid = s['sectionId'] as String? ?? '';
      final skill = s['skill'] as String? ?? '';
      if (_sectionHasWork(sid, skill)) n++;
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
    bool slim = false,
  }) {
    final l10n = context.l10n;
    final title = (ctx?['examTitle'] as String?)?.trim();
    final displayTitle = (title != null && title.isNotEmpty) ? title : examTitleFallback;
    final deadline = _deadline();
    final showCountdown = deadline != null && _attempt?['status'] == 'in_progress';

    if (slim && !submitted && !expired) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showCountdown) ...[
            _CountdownText(
              deadline: deadline!,
              deadlineLabel: l10n.integratedExamMetaDeadline,
              expiredLabel: l10n.integratedExamTimeUpShort,
              compact: true,
            ),
            if (total > 0) const SizedBox(height: 6),
          ],
          if (!submitted && !expired && total > 0)
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    child: LinearProgressIndicator(
                      value: doneCount / total,
                      minHeight: 4,
                      backgroundColor: AppColors.outlineMuted,
                      color: AppSkillColors.listening.color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.integratedExamProgress(doneCount, total),
                  style: ExamSystemUi.captionSecondary.copyWith(fontSize: AppTypography.mobileCaption),
                ),
              ],
            ),
        ],
      );
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
        if (showCountdown) ...[
          const SizedBox(height: 8),
          _CountdownText(
            deadline: deadline!,
            deadlineLabel: l10n.integratedExamMetaDeadline,
            expiredLabel: l10n.integratedExamTimeUpShort,
          ),
        ],
        if (!submitted && !expired && total > 0) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.input),
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

  Widget _buildDetailsExpansion(Map<String, dynamic>? ctx, String examTitleFallback, {bool compact = false}) {
    final l10n = context.l10n;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _detailsExpanded = !_detailsExpanded),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: AnimatedContainer(
          duration: AppMotion.base,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.outlineMuted, width: 0.75),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(12, compact ? 7 : 10, 8, compact ? 7 : 10),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: compact ? 16 : 18, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.integratedExamDetailsTitle,
                        style: compact
                            ? ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w500)
                            : ExamSystemUi.listTitle(context),
                      ),
                    ),
                    Icon(_detailsExpanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textMuted, size: 20),
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

  Widget _buildPartSelector(
    List<_IntegratedExamPart> parts,
    bool locked, {
    List<Map<String, dynamic>>? listeningSubSections,
  }) {
    if (parts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        e4cHorizontalScroll(
          child: ExamSectionTagRow(
            tags: [
              for (var i = 0; i < parts.length; i++)
                ExamSectionTag(
                  label: parts[i].title,
                  selected: i == _selectedPartIndex,
                  done: parts[i].done,
                  enabled: !locked,
                  skillAccent: _skillAccentForPart(parts[i]),
                  onTap: () {
                    setState(() {
                      _selectedPartIndex = i;
                      _visitedPartIndices.add(i);
                      if (parts[i].isMergedListening) {
                        _visitedListeningSubIndices.add(_selectedListeningSubIndex);
                      }
                    });
                    unawaited(_flushLiveViewToServer());
                  },
                ),
            ],
          ),
        ),
        if (listeningSubSections != null && listeningSubSections.length > 1) ...[
          const SizedBox(height: 6),
          _buildListeningSubSelector(listeningSubSections, locked),
        ],
      ],
    );
  }

  SkillColorSet? _skillAccentForPart(_IntegratedExamPart part) {
    if (part.isGrammar) return null;
    if (part.isMergedListening) return AppSkillColors.listening;
    return ExamNavTokens.accentForSkill(part.section?['skill'] as String?);
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
        if (!_visitedPartIndices.contains(i)) {
          return Offstage(offstage: true, child: const SizedBox.shrink());
        }
        final Widget pane;
        if (part.isGrammar) {
          pane = SingleChildScrollView(
            primary: false,
            padding: ExamSystemUi.pagePadding.copyWith(top: ExamSystemUi.cardGap, bottom: 24),
            child: _buildGrammarPanel(_grammarItems(), locked),
          );
        } else if (part.isMergedListening) {
          pane = Padding(
            padding: ExamSystemUi.pagePadding.copyWith(top: ExamSystemUi.cardGap, bottom: 8),
            child: _buildMergedListeningContent(part.mergedSections!, locked),
          );
        } else {
          pane = Padding(
            padding: ExamSystemUi.pagePadding.copyWith(top: 4, bottom: 4),
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
    final listeningType = _listeningTypeFromSection(section);
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
            listeningType: skill == 'listening' ? listeningType : 'dictation',
            initialListeningCueTexts:
                skill == 'listening' && listeningType != 'comprehension'
                    ? _listeningInitialCueTexts(sectionId)
                    : null,
            onListeningProgress: skill == 'listening' && listeningType != 'comprehension'
                ? (cues, saved, total) => _onListeningProgress(sectionId, cues, saved, total)
                : null,
            initialListeningCompAnswers:
                skill == 'listening' && listeningType == 'comprehension'
                    ? _listeningCompInitialAnswers(sectionId)
                    : null,
            onListeningCompProgress: skill == 'listening' && listeningType == 'comprehension'
                ? (answers, saved, total) =>
                    _onListeningCompProgress(sectionId, answers, saved, total)
                : null,
            initialWritingDraft: skill == 'writing' ? _writingInitialDraft(sectionId) : null,
            fixedWritingPrompt: skill == 'writing' ? _fixedWritingPrompt(section) : null,
            onWritingDraftChanged: skill == 'writing'
                ? (text) => _onWritingDraftChanged(sectionId, text)
                : null,
            onSpeakingProgress: skill == 'speaking'
                ? (index, total, saved) => _onSpeakingProgress(sectionId, index, total, saved)
                : null,
            onPartComplete:
                skill == 'speaking' ? _speakingFinishedCallback(sectionId) : null,
            examPracticeMode: true,
          ),
        ),
      ],
    );
  }

  /// Dictation + comprehension sub-tabs; one panel visible at a time (no nested scroll).
  Widget _buildMergedListeningContent(List<Map<String, dynamic>> sections, bool locked) {
    if (sections.isEmpty) return const SizedBox.shrink();
    final subIdx = _selectedListeningSubIndex.clamp(0, sections.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            children: sections.asMap().entries.map((entry) {
              final i = entry.key;
              final sec = entry.value;
              if (!_visitedListeningSubIndices.contains(i)) {
                return Offstage(offstage: true, child: const SizedBox.shrink());
              }
              return Offstage(
                offstage: i != subIdx,
                child: TickerMode(
                  enabled: i == subIdx,
                  child: _buildEmbeddedListeningPanel(sec, locked),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildListeningSubSelector(List<Map<String, dynamic>> sections, bool locked) {
    final l10n = context.l10n;
    final subIdx = _selectedListeningSubIndex.clamp(0, sections.length - 1);
    return ExamListeningSubNavGroup(
      sectionTitle: l10n.integratedExamListeningSubNavTitle,
      hint: l10n.integratedExamListeningSubNavHint,
      tags: [
        for (var i = 0; i < sections.length; i++)
          ExamSectionTag(
            variant: ExamSectionTagVariant.sub,
            skillAccent: AppSkillColors.listening,
            label: _listeningTypeFromSection(sections[i]) == 'comprehension'
                ? l10n.teacherExamListeningTypeComprehension
                : l10n.teacherExamListeningTypeDictation,
            selected: i == subIdx,
            done: _sectionHasWork(sections[i]['sectionId'] as String? ?? '', 'listening'),
            enabled: !locked,
            onTap: () {
              setState(() {
                _selectedListeningSubIndex = i;
                _visitedListeningSubIndices.add(i);
              });
              unawaited(_flushLiveViewToServer());
            },
          ),
      ],
    );
  }

  Widget _buildEmbeddedListeningPanel(Map<String, dynamic> section, bool locked) {
    final sectionId = section['sectionId'] as String? ?? '';
    final resources = _getSectionResources(section);
    final listeningType = _listeningTypeFromSection(section);
    return ExamEmbeddedSkillPanel(
      key: ValueKey<String>('panel_$sectionId'),
      skill: 'listening',
      resources: resources,
      locked: locked,
      sectionId: sectionId,
      listeningType: listeningType,
      initialListeningCueTexts: listeningType != 'comprehension'
          ? _listeningInitialCueTexts(sectionId)
          : null,
      onListeningProgress: listeningType != 'comprehension'
          ? (cues, saved, total) => _onListeningProgress(sectionId, cues, saved, total)
          : null,
      initialListeningCompAnswers: listeningType == 'comprehension'
          ? _listeningCompInitialAnswers(sectionId)
          : null,
      onListeningCompProgress: listeningType == 'comprehension'
          ? (answers, saved, total) =>
              _onListeningCompProgress(sectionId, answers, saved, total)
          : null,
      examPracticeMode: true,
    );
  }

  Widget _buildSubmittedCompletionNotice() {
    final l10n = context.l10n;
    return AppCard(
      variant: AppCardVariant.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_outline, size: 22, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.studentExamSubmitted,
                  style: ExamSystemUi.listTitle(context).copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_skillReviewBlockedMessage(), style: ExamSystemUi.captionSecondary),
        ],
      ),
    );
  }

  Widget _buildSubmittedSummary(List<_IntegratedExamPart> parts, List<Map<String, dynamic>> grammar, List<Map<String, dynamic>> secs) {
    final l10n = context.l10n;
    final canReview = _canViewFullGradedResults();
    if (!canReview) {
      return _buildSubmittedCompletionNotice();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (grammar.isNotEmpty) _buildSubmittedGrammarTile(grammar, canReview),
        if (secs.isNotEmpty) ...[
          if (grammar.isNotEmpty) const SizedBox(height: ExamSystemUi.cardGap),
          Text(l10n.integratedExamSkillsSectionTitle, style: ExamSystemUi.sectionTitle(context)),
          const SizedBox(height: ExamSystemUi.cardGap),
          ..._buildSubmittedSectionTiles(secs),
        ],
      ],
    );
  }

  Widget _buildSubmittedGrammarTile(List<Map<String, dynamic>> grammar, bool canReview) {
    return _SubmittedGrammarReviewTile(
      grammar: grammar,
      canReview: canReview,
      getAnswer: (itemId) {
        final ans = _attempt?['answers'];
        if (ans is! Map) return null;
        final a = ans[itemId];
        if (a is! Map) return null;
        return Map<String, dynamic>.from(a);
      },
      isAnswered: _grammarAnswered,
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
          ExamNavNumberChip(
            number: i + 1,
            selected: i == _grammarNavIndex,
            done: _grammarAnswered(grammar[i]) && i != _grammarNavIndex,
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
          AppFeedback.error(context, l10n.integratedExamSubmitBlockedAll, blocking: true);
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
      (f) => AppFeedback.error(context, f.message, blocking: true),
      (_) {
        AppFeedback.success(context, context.l10n.studentExamSubmitted);
        _load().then((_) => _celebrateSubmit());
      },
    );
  }

  /// Tung hoa sau khi nộp bài: festive khi đã xem được điểm tổng đạt ngưỡng,
  /// còn lại (chưa chấm / chưa mở điểm) chỉ reward nhẹ chúc mừng đã hoàn thành.
  void _celebrateSubmit() {
    if (!mounted) return;
    if (_canViewScores() && _attempt?['scores'] is Map) {
      final scores = _attempt!['scores'] as Map;
      final finalScore = num.tryParse('${scores['finalScore'] ?? ''}');
      final isPartial = '${scores['finalStatus'] ?? ''}' == 'partial';
      if (finalScore != null && !isPartial) {
        CompletionCelebration.fireForScore(
          context,
          score: finalScore.toDouble(),
          maxScore: 10,
        );
        return;
      }
    }
    CompletionCelebration.fire(context, level: CelebrationLevel.gentle);
  }

  bool _blocksExitConfirm() {
    if (_loading || _error != null) return false;
    return (_attempt?['status'] as String? ?? '') == 'in_progress';
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
        AppFeedback.error(context, f.message, blocking: true);
      },
      (_) async {
        getIt<SocketService>().clearExamRealtimeContext();
        if (!mounted) return;
        AppFeedback.success(context, l10n.studentExamVoluntaryExitBlocked);
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
      canPop: !_blocksExitConfirm(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          final rt = _attempt?['runtimeContext'];
          if (rt is Map && rt['assignmentMode'] == 'realtime') {
            getIt<SocketService>().clearExamRealtimeContext();
          }
          return;
        }
        if (!_blocksExitConfirm()) return;
        final confirmFuture = _isRealtimeInProgress()
            ? _confirmLeaveRealtimeExam()
            : StudentMobileUi.confirmRunnerExit(context);
        confirmFuture.then((leave) {
          if (!leave || !mounted) return;
          if (_isRealtimeInProgress()) {
            _abandonRealtimeAndExit();
          } else {
            Navigator.of(context).pop();
          }
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
          ? StudentMobileUi.runnerLoading()
          : _error != null
              ? StudentMobileUi.errorRetry(
                  context,
                  message: _error!,
                  onRetry: _load,
                  retryLabel: l10n.retry,
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
    final headerPad = ExamSystemUi.pagePadding.copyWith(bottom: 0, top: 8);
    final activeSlim = !submitted && !expired;
    final activeIdx = parts.isEmpty ? 0 : _selectedPartIndex.clamp(0, parts.length - 1);
    final activePart = parts.isEmpty ? null : parts[activeIdx];
    final listeningSubSections = activePart != null && activePart.isMergedListening
        ? activePart.mergedSections
        : null;

    if (submitted || expired) {
      return e4cNoScrollbarScroll(
        child: ListView(
          primary: false,
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
          if (submitted && _canViewScores() && _attempt?['scores'] is Map) ...[
            const SizedBox(height: ExamSystemUi.sectionGap),
            IntegratedScoreSummaryCard(
              attempt: Map<String, dynamic>.from(_attempt!),
              scores: Map<String, dynamic>.from(_attempt!['scores'] as Map),
              title: context.l10n.teacherAttemptGradeTotalScore,
            ),
          ],
          const SizedBox(height: 80),
        ],
        ),
      );
    }

    return e4cNoScrollbarScroll(
      child: Column(
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
                slim: activeSlim,
              ),
              SizedBox(height: activeSlim ? 6 : ExamSystemUi.blockGap),
              _buildDetailsExpansion(ctx, examTitleFallback, compact: activeSlim),
              SizedBox(height: activeSlim ? 8 : ExamSystemUi.sectionGap),
              _buildPartSelector(
                parts,
                locked,
                listeningSubSections: listeningSubSections,
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildPartsStack(parts, locked),
        ),
      ],
      ),
    );
  }

  List<Map<String, dynamic>> _getSectionResources(Map<String, dynamic> s) =>
      sectionResourcesFrom(s);

  /// Builds submitted tiles, merging listening sections into one tile.
  List<Widget> _buildSubmittedSectionTiles(List<Map<String, dynamic>> secs) {
    final out = <Widget>[];
    final listeningSecs = secs.where((s) => s['skill'] == 'listening').toList();
    bool listeningAdded = false;
    for (final s in secs) {
      final skill = s['skill'] as String? ?? '';
      if (skill == 'listening') {
        if (listeningAdded) continue;
        listeningAdded = true;
        if (listeningSecs.length == 1) {
          out.add(_buildSubmittedSectionTile(s));
        } else {
          out.add(_buildSubmittedMergedListeningTile(listeningSecs));
        }
      } else {
        out.add(_buildSubmittedSectionTile(s));
      }
    }
    return out;
  }

  Widget _buildSubmittedMergedListeningTile(List<Map<String, dynamic>> sections) {
    final allDone = sections.every((s) =>
        _sectionHasWork(s['sectionId'] as String? ?? '', 'listening'));
    return _SubmittedMergedListeningTile(
      title: _skillTitle('listening'),
      done: allDone,
      sections: sections,
      reviewMode: _canViewFullGradedResults(),
      resultsBlockedMessage: _skillReviewBlockedMessage(),
      getSectionResources: _getSectionResources,
      listeningTypeFromSection: _listeningTypeFromSection,
      listeningInitialCueTexts: _listeningInitialCueTexts,
      listeningCompInitialAnswers: _listeningCompInitialAnswers,
      sectionHasWork: (sid) => _sectionHasWork(sid, 'listening'),
    );
  }

  /// Collapsible review row — loads skill CMS only when expanded (avoids N API calls after submit).
  Widget _buildSubmittedSectionTile(Map<String, dynamic> s) {
    final skill = s['skill'] as String? ?? '';
    final sectionId = s['sectionId'] as String? ?? '';
    final resources = _getSectionResources(s);
    if (resources.isEmpty && !(skill == 'writing' && _fixedWritingPrompt(s) != null)) {
      return const SizedBox.shrink();
    }
    return _SubmittedSectionReviewTile(
      skill: skill,
      sectionId: sectionId,
      section: s,
      title: _skillTitle(skill),
      done: _sectionHasWork(sectionId, skill),
      reviewMode: _canViewFullGradedResults(),
      resultsBlockedMessage: _skillReviewBlockedMessage(),
      resources: resources,
      fixedWritingPrompt: _fixedWritingPrompt(s),
      readingInitial: _readingInitialAnswers(sectionId),
      listeningInitial: _listeningInitialCueTexts(sectionId),
      writingInitial: _writingInitialDraft(sectionId),
      reviewFeedback: _skillFeedback(sectionId),
      reviewScore: _skillScoreValue(sectionId),
    );
  }
}

/// Collapsible grammar review — one tile, questions inside when expanded.
class _SubmittedGrammarReviewTile extends StatefulWidget {
  const _SubmittedGrammarReviewTile({
    required this.grammar,
    required this.canReview,
    required this.getAnswer,
    required this.isAnswered,
  });

  final List<Map<String, dynamic>> grammar;
  final bool canReview;
  final Map<String, dynamic>? Function(String itemId) getAnswer;
  final bool Function(Map<String, dynamic> item) isAnswered;

  @override
  State<_SubmittedGrammarReviewTile> createState() => _SubmittedGrammarReviewTileState();
}

class _SubmittedGrammarReviewTileState extends State<_SubmittedGrammarReviewTile> {
  bool _expanded = false;

  bool get _done => widget.grammar.isNotEmpty && widget.grammar.every(widget.isAnswered);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final statusLabel =
        _done ? l10n.integratedExamPartDone : l10n.integratedExamPartNotStarted;
    final reviewHeight = (MediaQuery.sizeOf(context).height * 0.55).clamp(280.0, 560.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: ExamSystemUi.cardGap),
      child: AppCard(
        variant: AppCardVariant.outline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: Icon(
                _done ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                size: ExamSystemUi.iconSm,
                color: _done ? AppColors.primary : AppColors.textSecondary,
              ),
              title: Text(l10n.integratedExamGrammarSectionTitle, style: ExamSystemUi.listTitle(context)),
              subtitle: Text(
                l10n.questionsCount(widget.grammar.length),
                style: ExamSystemUi.captionSecondary,
              ),
              trailing: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: AppColors.textMuted,
              ),
              onTap: () => setState(() => _expanded = !_expanded),
            ),
            if (_expanded) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(statusLabel, style: ExamSystemUi.captionMuted),
                ),
              ),
              const Divider(height: 1),
              SizedBox(
                height: reviewHeight,
                child: SingleChildScrollView(
                  primary: false,
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < widget.grammar.length; i++)
                        IntegratedExamGrammarQuestionCard(
                          displayIndex: i + 1,
                          item: widget.grammar[i],
                          answer: widget.getAnswer('${widget.grammar[i]['itemId'] ?? ''}'),
                          locked: true,
                          onPartialPatch: (_) {},
                          gradingReviewMode: widget.canReview,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Merged listening review tile — shows both dictation and comprehension in one collapsible.
class _SubmittedMergedListeningTile extends StatefulWidget {
  const _SubmittedMergedListeningTile({
    required this.title,
    required this.done,
    required this.sections,
    required this.reviewMode,
    required this.resultsBlockedMessage,
    required this.getSectionResources,
    required this.listeningTypeFromSection,
    required this.listeningInitialCueTexts,
    required this.listeningCompInitialAnswers,
    required this.sectionHasWork,
  });

  final String title;
  final bool done;
  final List<Map<String, dynamic>> sections;
  final bool reviewMode;
  final String resultsBlockedMessage;
  final List<Map<String, dynamic>> Function(Map<String, dynamic>) getSectionResources;
  final String Function(Map<String, dynamic>) listeningTypeFromSection;
  final Map<String, String>? Function(String) listeningInitialCueTexts;
  final Map<String, int>? Function(String) listeningCompInitialAnswers;
  final bool Function(String) sectionHasWork;

  @override
  State<_SubmittedMergedListeningTile> createState() => _SubmittedMergedListeningTileState();
}

class _SubmittedMergedListeningTileState extends State<_SubmittedMergedListeningTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final statusLabel =
        widget.done ? l10n.integratedExamPartDone : l10n.integratedExamPartNotStarted;

    return Padding(
      padding: const EdgeInsets.only(bottom: ExamSystemUi.cardGap),
      child: AppCard(
        variant: AppCardVariant.outline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: Icon(
                widget.done ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                size: ExamSystemUi.iconSm,
                color: widget.done ? AppColors.primary : AppColors.textSecondary,
              ),
              title: Text(widget.title, style: ExamSystemUi.listTitle(context)),
              subtitle: Text(
                '${widget.sections.length} exercises',
                style: ExamSystemUi.captionSecondary,
              ),
              trailing: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: AppColors.textMuted,
              ),
              onTap: () => setState(() => _expanded = !_expanded),
            ),
            if (_expanded) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(statusLabel, style: ExamSystemUi.captionMuted),
                ),
              ),
              const Divider(height: 1),
              for (var i = 0; i < widget.sections.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: _subHeader(widget.sections[i]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                  child: _buildPanel(widget.sections[i]),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _subHeader(Map<String, dynamic> section) {
    final lt = widget.listeningTypeFromSection(section);
    final label = lt == 'comprehension'
        ? context.l10n.teacherExamListeningTypeComprehension
        : context.l10n.teacherExamListeningTypeDictation;
    final icon = lt == 'comprehension' ? Icons.headphones_outlined : Icons.text_fields_outlined;
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(label, style: ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w600, fontSize: AppTypography.mobileCaption)),
      ],
    );
  }

  Widget _buildPanel(Map<String, dynamic> section) {
    if (!widget.reviewMode) {
      return AppCard(
        variant: AppCardVariant.outline,
        child: Text(widget.resultsBlockedMessage, style: ExamSystemUi.captionSecondary),
      );
    }
    final sectionId = section['sectionId'] as String? ?? '';
    final resources = widget.getSectionResources(section);
    final lt = widget.listeningTypeFromSection(section);
    return ExamEmbeddedSkillPanel(
      key: ValueKey<String>('review_merged_$sectionId'),
      skill: 'listening',
      resources: resources,
      locked: true,
      reviewMode: true,
      sectionId: sectionId,
      listeningType: lt,
      initialListeningCueTexts: lt != 'comprehension' ? widget.listeningInitialCueTexts(sectionId) : null,
      initialListeningCompAnswers: lt == 'comprehension' ? widget.listeningCompInitialAnswers(sectionId) : null,
      examPracticeMode: true,
    );
  }
}

/// Lazy-loaded skill review after submit (one CMS fetch per section when opened).
class _SubmittedSectionReviewTile extends StatefulWidget {
  const _SubmittedSectionReviewTile({
    required this.skill,
    required this.sectionId,
    required this.section,
    required this.title,
    required this.done,
    required this.reviewMode,
    required this.resultsBlockedMessage,
    required this.resources,
    this.fixedWritingPrompt,
    this.readingInitial,
    this.listeningInitial,
    this.writingInitial,
    this.reviewFeedback,
    this.reviewScore,
  });

  final String skill;
  final String sectionId;
  final Map<String, dynamic> section;
  final String title;
  final bool done;
  final bool reviewMode;
  final String resultsBlockedMessage;
  final List<Map<String, dynamic>> resources;
  final Map<String, dynamic>? fixedWritingPrompt;
  final Map<String, int>? readingInitial;
  final Map<String, String>? listeningInitial;
  final String? writingInitial;
  final String? reviewFeedback;
  final dynamic reviewScore;

  @override
  State<_SubmittedSectionReviewTile> createState() => _SubmittedSectionReviewTileState();
}

class _SubmittedSectionReviewTileState extends State<_SubmittedSectionReviewTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final statusLabel =
        widget.done ? l10n.integratedExamPartDone : l10n.integratedExamPartNotStarted;

    return Padding(
      padding: const EdgeInsets.only(bottom: ExamSystemUi.cardGap),
      child: AppCard(
        variant: AppCardVariant.outline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: Icon(
                widget.done ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                size: ExamSystemUi.iconSm,
                color: widget.done ? AppColors.primary : AppColors.textSecondary,
              ),
              title: Text(widget.title, style: ExamSystemUi.listTitle(context)),
              subtitle: widget.resources.length == 1
                  ? Text(
                      widget.resources.first['title'] as String? ?? '',
                      style: ExamSystemUi.captionSecondary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text(
                      '${widget.resources.length} exercises',
                      style: ExamSystemUi.captionSecondary,
                    ),
              trailing: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: AppColors.textMuted,
              ),
              onTap: () => setState(() => _expanded = !_expanded),
            ),
            if (_expanded) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(statusLabel, style: ExamSystemUi.captionMuted),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
                child: widget.reviewMode
                    ? ExamEmbeddedSkillPanel(
                        key: ValueKey<String>('review_${widget.sectionId}'),
                        skill: widget.skill,
                        resources: widget.resources,
                        locked: true,
                        reviewMode: true,
                        sectionId: widget.sectionId,
                        initialReadingAnswers: widget.readingInitial,
                        initialListeningCueTexts: widget.listeningInitial,
                        initialWritingDraft: widget.writingInitial,
                        fixedWritingPrompt: widget.fixedWritingPrompt,
                        reviewFeedback: widget.reviewFeedback,
                        reviewScore: widget.reviewScore,
                        examPracticeMode: true,
                      )
                    : AppCard(
                        variant: AppCardVariant.outline,
                        child: Text(
                          widget.resultsBlockedMessage,
                          style: ExamSystemUi.captionSecondary,
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Self-contained countdown that rebuilds only itself each second.
/// Prevents the root page from calling setState every second.
class _CountdownText extends StatefulWidget {
  const _CountdownText({
    required this.deadline,
    required this.deadlineLabel,
    required this.expiredLabel,
    this.compact = false,
  });

  final DateTime deadline;
  final String deadlineLabel;
  final String expiredLabel;
  final bool compact;

  @override
  State<_CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<_CountdownText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    if (d.isNegative) return widget.expiredLabel;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.deadline.difference(DateTime.now());
    final expired = left.isNegative;
    final urgency = !expired && left.inMinutes < 5;
    final color = expired
        ? AppColors.chartTrend
        : urgency
            ? AppColors.warning
            : AppColors.textSecondary;

    return Row(
      children: [
        Icon(Icons.timer_outlined, size: widget.compact ? 14 : 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${widget.deadlineLabel}: ${_format(left)}',
            style: ExamSystemUi.captionSecondary.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: widget.compact ? 11 : 12,
            ),
          ),
        ),
      ],
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
    this.mergedSections,
  });

  final String key;
  final String title;
  final bool isGrammar;
  final bool done;
  final Map<String, dynamic>? section;
  /// When multiple listening sections are merged into one tab.
  final List<Map<String, dynamic>>? mergedSections;

  bool get isMergedListening => mergedSections != null && mergedSections!.isNotEmpty;
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
        borderRadius: BorderRadius.circular(AppRadius.sheet),
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