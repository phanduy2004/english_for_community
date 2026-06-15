import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/socket/socket_service.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/feature/student/exams/exam_live_session_guard.dart';
import 'package:english_for_community/feature/student/exams/integrated_exam_runner_page.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ExamRunnerPage extends StatefulWidget {
  const ExamRunnerPage({super.key, required this.attemptId});

  final String attemptId;

  static const String routePath = '/student/exam-run';
  static const String routeName = 'ExamRunnerPage';

  @override
  State<ExamRunnerPage> createState() => _ExamRunnerPageState();
}

/// Flattens exam items for answering (matches backend `walkItems` for nested reading/listening).
List<Map<String, dynamic>> walkAnswerableExamItems(Map<String, dynamic> snap) {
  final out = <Map<String, dynamic>>[];
  final sections = snap['sections'] as List? ?? [];
  for (final sec in sections) {
    if (sec is! Map) continue;
    final items = sec['items'] as List? ?? [];
    for (final raw in items) {
      if (raw is! Map) continue;
      final it = Map<String, dynamic>.from(raw);
      final k = it['kind'] as String? ?? '';
      if (k == 'reading' || k == 'listening') {
        for (final n in it['nestedItems'] as List? ?? []) {
          if (n is Map) out.add(Map<String, dynamic>.from(n));
        }
      } else {
        out.add(it);
      }
    }
  }
  return out;
}

String? examFormatFromExamSnapshot(dynamic snap) {
  if (snap is! Map) return null;
  final m = Map<String, dynamic>.from(snap);
  final st = m['settings'];
  if (st is! Map) return null;
  return Map<String, dynamic>.from(st)['examFormat'] as String?;
}

class _ExamRunnerPageState extends State<ExamRunnerPage> with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _attempt;
  int _itemIndex = 0;
  int? _mcqSingle;
  final Set<int> _mcqMulti = {};
  final Map<String, String> _blankDraft = {};
  final TextEditingController _essayCtrl = TextEditingController();
  Ticker? _ticker;
  DateTime? _deadlineLocal;
  int _tick = 0;

  final Map<String, TextEditingController> _blankControllers = {};
  late final ExamLiveSessionGuard _liveGuard;

  @override
  void dispose() {
    _liveGuard.dispose();
    _disposeBlankControllers();
    _ticker?.dispose();
    _essayCtrl.dispose();
    super.dispose();
  }

  void _disposeBlankControllers() {
    for (final c in _blankControllers.values) {
      c.dispose();
    }
    _blankControllers.clear();
  }

  @override
  void initState() {
    super.initState();
    _liveGuard = ExamLiveSessionGuard(context);
    _load();
  }

  void _stopTicker() {
    _ticker?.dispose();
    _ticker = null;
  }

  void _maybeStartTicker() {
    _stopTicker();
    final ad = _attempt?['attemptDeadlineAt'];
    final st = _attempt?['status'] as String? ?? '';
    if (ad == null || st != 'in_progress') return;
    DateTime? d;
    if (ad is String) {
      d = DateTime.tryParse(ad);
    } else if (ad is DateTime) {
      d = ad;
    }
    d = d?.toLocal();
    if (d == null) return;
    _deadlineLocal = d;
    _ticker = createTicker((_) {
      _tick++;
      if (!mounted) return;
      if (DateTime.now().isAfter(_deadlineLocal!)) {
        _stopTicker();
        _autoSubmitOnDeadline();
      } else {
        setState(() {});
      }
    })..start();
  }

  Future<void> _autoSubmitOnDeadline() async {
    if (!mounted) return;
    final r = await getIt<TeacherExamRepository>().submitExamAttempt(widget.attemptId, force: true);
    if (!mounted) return;
    r.fold(
      (_) {
        _load(silent: true);
      },
      (d) {
        setState(() => _attempt = Map<String, dynamic>.from(d as Map));
        AppCornerToast.show(context, context.l10n.studentExamSubmitted);
      },
    );
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final r = await getIt<TeacherExamRepository>().getExamAttempt(widget.attemptId);
    r.fold(
      (f) {
        if (!silent && mounted) setState(() => _error = f.message);
      },
      (d) {
        final m = Map<String, dynamic>.from(d as Map);
        if (mounted) {
          setState(() {
            _attempt = m;
            _clampItemIndex();
            _hydrateCurrentItem();
          });
          if ((m['status'] as String?) == 'in_progress') {
            _liveGuard.bindFromAttempt(m);
          } else {
            _liveGuard.unbind();
          }
          _maybeStartTicker();
        }
      },
    );
    if (mounted && !silent) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _flatItems() {
    final snap = _attempt?['examSnapshot'];
    if (snap is! Map<String, dynamic>) return [];
    return walkAnswerableExamItems(snap);
  }

  void _clampItemIndex() {
    final n = _flatItems().length;
    if (n == 0) {
      _itemIndex = 0;
      return;
    }
    if (_itemIndex >= n) _itemIndex = n - 1;
  }

  Map<String, dynamic>? _currentItem() {
    final list = _flatItems();
    if (list.isEmpty || _itemIndex < 0 || _itemIndex >= list.length) return null;
    return list[_itemIndex];
  }

  void _hydrateCurrentItem() {
    _mcqSingle = null;
    _mcqMulti.clear();
    _blankDraft.clear();
    _disposeBlankControllers();
    final item = _currentItem();
    if (item == null) {
      _essayCtrl.clear();
      return;
    }
    final id = item['itemId'] as String? ?? '';
    final kind = item['kind'] as String? ?? '';
    if (id.isEmpty) {
      _essayCtrl.clear();
      return;
    }
    final ans = _attempt?['answers'];
    final raw = ans is Map ? ans[id] : null;
    Map<String, dynamic> a = {};
    if (raw is Map) {
      a = Map<String, dynamic>.from(raw);
    }

    if (kind == 'mcq_single') {
      final sel = a['selectedIndexes'];
      if (sel is List && sel.isNotEmpty) {
        _mcqSingle = (sel.first as num).toInt();
      }
    } else if (kind == 'mcq_multi') {
      final sel = a['selectedIndexes'];
      if (sel is List) {
        for (final x in sel) {
          _mcqMulti.add((x as num).toInt());
        }
      }
    } else if (kind == 'fill_blank') {
      final blanks = a['blanks'];
      if (blanks is Map) {
        blanks.forEach((k, v) {
          _blankDraft[k.toString()] = v?.toString() ?? '';
        });
      }
      for (final b in item['blanks'] as List? ?? []) {
        if (b is! Map) continue;
        final bid = b['blankId'] as String? ?? '';
        _blankDraft.putIfAbsent(bid, () => '');
      }
      for (final b in item['blanks'] as List? ?? []) {
        if (b is! Map) continue;
        final bid = b['blankId'] as String? ?? '';
        if (bid.isEmpty) continue;
        _blankControllers[bid] = TextEditingController(text: _blankDraft[bid] ?? '');
      }
    } else if (kind == 'essay') {
      _essayCtrl.text = (a['text'] as String?) ?? '';
    } else {
      _essayCtrl.clear();
    }
  }

  Future<void> _persistCurrentAnswer() async {
    final item = _currentItem();
    if (item == null) return;
    final st = _attempt?['status'] as String? ?? '';
    if (st != 'in_progress') return;
    final id = item['itemId'] as String? ?? '';
    final kind = item['kind'] as String? ?? '';
    if (id.isEmpty) return;

    Map<String, dynamic>? entry;
    if (kind == 'mcq_single' && _mcqSingle != null) {
      entry = {id: <String, dynamic>{'selectedIndexes': [_mcqSingle!]}};
    } else if (kind == 'mcq_multi') {
      final sorted = _mcqMulti.toList()..sort();
      entry = {id: <String, dynamic>{'selectedIndexes': sorted}};
    } else if (kind == 'fill_blank') {
      for (final e in _blankControllers.entries) {
        _blankDraft[e.key] = e.value.text;
      }
      final blanks = <String, String>{};
      for (final b in item['blanks'] as List? ?? []) {
        if (b is! Map) continue;
        final bid = b['blankId'] as String? ?? '';
        blanks[bid] = _blankDraft[bid] ?? '';
      }
      entry = {id: <String, dynamic>{'blanks': blanks}};
    } else if (kind == 'essay') {
      entry = {id: <String, dynamic>{'text': _essayCtrl.text}};
    }

    if (entry == null) return;
    final r = await getIt<TeacherExamRepository>().patchExamAttempt(widget.attemptId, entry);
    if (!mounted) return;
    r.fold(
      (f) => AppCornerToast.show(context, f.message, error: true),
      (d) => setState(() => _attempt = Map<String, dynamic>.from(d as Map)),
    );
  }

  Future<void> _goToIndex(int next) async {
    final list = _flatItems();
    if (list.isEmpty) return;
    final clamped = next.clamp(0, list.length - 1);
    if (clamped == _itemIndex) return;
    await _persistCurrentAnswer();
    if (!mounted) return;
    setState(() {
      _itemIndex = clamped;
      _hydrateCurrentItem();
    });
  }

  String? _remainingLabel(AppLocalizations l10n) {
    if (_deadlineLocal == null) return null;
    final d = _deadlineLocal!.difference(DateTime.now());
    if (d.isNegative) return l10n.studentExamExpired;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return l10n.studentExamTimeRemainingHM(h, m);
    if (m > 0) return l10n.studentExamTimeRemainingMS(m, s);
    return l10n.studentExamTimeRemainingS(s);
  }

  Future<void> _submit() async {
    await _persistCurrentAnswer();
    if (!mounted) return;
    final r = await getIt<TeacherExamRepository>().submitExamAttempt(widget.attemptId);
    r.fold(
      (f) => AppCornerToast.show(context, f.message, error: true),
      (d) {
        _stopTicker();
        final m = Map<String, dynamic>.from(d as Map);
        setState(() {
          _attempt = m;
          _itemIndex = 0;
          _hydrateCurrentItem();
        });
        _liveGuard.unbind();
        AppCornerToast.show(context, context.l10n.studentExamSubmitted);
      },
    );
  }

  Map<String, dynamic> _answerMapForItem(String itemId) {
    final ans = _attempt?['answers'];
    if (ans is! Map || ans[itemId] is! Map) return {};
    return Map<String, dynamic>.from(ans[itemId] as Map);
  }

  Widget _buildReviewItemCard(Map<String, dynamic> item) {
    final l10n = context.l10n;
    final id = item['itemId'] as String? ?? '';
    final a = _answerMapForItem(id);
    final kind = item['kind'] as String? ?? '';

    if (kind == 'mcq_single') {
      final opts = (item['options'] as List?) ?? [];
      final sel = a['selectedIndexes'];
      final selected = sel is List && sel.isNotEmpty ? (sel.first as num).toInt() : null;
      return AppCard(
        variant: AppCardVariant.outline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['stem'] as String? ?? '', style: StudentMobileUi.cardTitle(context)),
            const SizedBox(height: StudentMobileUi.cardGap),
            ...List.generate(opts.length, (i) {
              return StudentMobileUi.mcqOption(
                context: context,
                index: i,
                text: opts[i] as String,
                selected: selected == i,
                onTap: null,
              );
            }),
          ],
        ),
      );
    }

    if (kind == 'mcq_multi') {
      final opts = (item['options'] as List?) ?? [];
      final sel = a['selectedIndexes'];
      final selected = <int>{};
      if (sel is List) {
        for (final x in sel) {
          if (x is num) selected.add(x.toInt());
        }
      }
      return AppCard(
        variant: AppCardVariant.outline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['stem'] as String? ?? '', style: StudentMobileUi.cardTitle(context)),
            const SizedBox(height: StudentMobileUi.cardGap),
            ...List.generate(opts.length, (i) {
              return StudentMobileUi.mcqOption(
                context: context,
                index: i,
                text: opts[i] as String,
                multiSelect: true,
                checked: selected.contains(i),
                onTap: null,
              );
            }),
          ],
        ),
      );
    }

    if (kind == 'fill_blank') {
      final defs = item['blanks'] as List? ?? [];
      final blanks = a['blanks'];
      final blankMap = blanks is Map ? Map<String, dynamic>.from(blanks) : <String, dynamic>{};
      return AppCard(
        variant: AppCardVariant.outline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((item['template'] as String?)?.trim().isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(bottom: StudentMobileUi.sectionGap),
                child: Text(item['template'] as String, style: StudentMobileUi.caption(context)),
              ),
            for (final b in defs)
              if (b is Map) ...[
                Text(b['blankId'] as String? ?? '', style: StudentMobileUi.caption(context)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.outlineMuted),
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.surfaceSubtle,
                  ),
                  child: Text(
                    blankMap[b['blankId'] as String? ?? '']?.toString() ?? '—',
                    style: StudentMobileUi.body(context),
                  ),
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      );
    }

    if (kind == 'essay') {
      final text = a['text'] as String? ?? '';
      return AppCard(
        variant: AppCardVariant.outline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['prompt'] as String? ?? '', style: StudentMobileUi.cardTitle(context)),
            const SizedBox(height: StudentMobileUi.cardGap),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.outlineMuted),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.surfaceSubtle,
              ),
              child: Text(
                text.trim().isEmpty ? '—' : text,
                style: StudentMobileUi.body(context),
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      variant: AppCardVariant.outline,
      child: Text(l10n.studentExamItemUnsupported, style: StudentMobileUi.body(context)),
    );
  }

  String _scoreSummaryText() {
    final l10n = context.l10n;
    final s = _attempt?['scores'];
    if (s is! Map) return '${l10n.studentExamScore}: $s';
    final earned = s['totalAwarded'];
    final max = s['totalMax'];
    if (earned != null && max != null) {
      return l10n.studentExamScoreTotals('$earned', '$max');
    }
    return '${l10n.studentExamScore}: $s';
  }

  Widget _buildItemCard(Map<String, dynamic> item, bool locked) {
    final l10n = context.l10n;
    final kind = item['kind'] as String? ?? '';

    if (kind == 'mcq_single') {
      final opts = (item['options'] as List?) ?? [];
      return AppCard(
        variant: AppCardVariant.outline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['stem'] as String? ?? '', style: StudentMobileUi.cardTitle(context)),
            const SizedBox(height: StudentMobileUi.cardGap),
            ...List.generate(opts.length, (i) {
              final opt = opts[i] as String;
              return StudentMobileUi.mcqOption(
                context: context,
                index: i,
                text: opt,
                selected: _mcqSingle == i,
                onTap: locked
                    ? null
                    : () {
                        setState(() => _mcqSingle = i);
                        _persistCurrentAnswer();
                      },
              );
            }),
          ],
        ),
      );
    }

    if (kind == 'mcq_multi') {
      final opts = (item['options'] as List?) ?? [];
      return AppCard(
        variant: AppCardVariant.outline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['stem'] as String? ?? '', style: StudentMobileUi.cardTitle(context)),
            const SizedBox(height: StudentMobileUi.cardGap),
            ...List.generate(opts.length, (i) {
              final opt = opts[i] as String;
              return StudentMobileUi.mcqOption(
                context: context,
                index: i,
                text: opt,
                multiSelect: true,
                checked: _mcqMulti.contains(i),
                onTap: locked
                    ? null
                    : () {
                        setState(() {
                          if (_mcqMulti.contains(i)) {
                            _mcqMulti.remove(i);
                          } else {
                            _mcqMulti.add(i);
                          }
                        });
                        _persistCurrentAnswer();
                      },
              );
            }),
          ],
        ),
      );
    }

    if (kind == 'fill_blank') {
      final defs = item['blanks'] as List? ?? [];
      return AppCard(
        variant: AppCardVariant.outline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((item['template'] as String?)?.trim().isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(bottom: StudentMobileUi.sectionGap),
                child: Text(item['template'] as String, style: StudentMobileUi.caption(context)),
              ),
            for (final b in defs)
              if (b is Map) ...[
                TextField(
                  enabled: !locked,
                  decoration: InputDecoration(
                    labelText: b['blankId'] as String? ?? '',
                  ),
                  controller: _blankControllers[b['blankId'] as String? ?? ''],
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      );
    }

    if (kind == 'essay') {
      return AppCard(
        variant: AppCardVariant.outline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['prompt'] as String? ?? '', style: StudentMobileUi.cardTitle(context)),
            const SizedBox(height: StudentMobileUi.cardGap),
            TextField(
              controller: _essayCtrl,
              enabled: !locked,
              minLines: 4,
              maxLines: 12,
              decoration: InputDecoration(
                hintText: l10n.studentExamEssayPlaceholder,
                border: const OutlineInputBorder(),
              ),
              onChanged: locked ? null : (_) => setState(() {}),
            ),
          ],
        ),
      );
    }

    return AppCard(
      variant: AppCardVariant.outline,
      child: Text(l10n.studentExamItemUnsupported, style: StudentMobileUi.body(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!_loading && _error == null && _attempt != null) {
      final snap = _attempt!['examSnapshot'];
      final fmt = examFormatFromExamSnapshot(snap);
      if (fmt == 'integrated_four_skills' || fmt == 'skills_exam') {
        return IntegratedExamRunnerPage(attemptId: widget.attemptId);
      }
    }

    final flat = _flatItems();
    final item = _currentItem();
    final status = _attempt?['status'] as String? ?? '';
    final submitted = status == 'submitted';
    final expired = status == 'expired';
    final remaining = _remainingLabel(l10n);
    final locked = submitted || expired;
    final lastIndex = flat.isEmpty ? 0 : flat.length - 1;

    return PopScope<Object?>(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        final rt = _attempt?['runtimeContext'];
        final isRealtime = rt is Map && rt['assignmentMode'] == 'realtime';
        if (isRealtime) {
          // Ensure teacher roster is updated immediately when the student exits the live attempt.
          getIt<SocketService>().clearExamRealtimeContext();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: StudentMobileUi.appBar(
          context,
          title: l10n.studentExamRunnerTitle,
          actions: [
            if (remaining != null && status == 'in_progress')
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.s4),
                  child: Text(
                    '${l10n.teacherExamTimeRemaining}: $remaining',
                    key: ValueKey(_tick),
                    style: StudentMobileUi.caption(context),
                  ),
                ),
              ),
          ],
        ),
        body: _loading
            ? const Center(child: AppLoadingIndicator.center())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: StudentMobileUi.pagePadding,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.studentExamRunnerLoadFailed,
                            style: StudentMobileUi.sectionTitle(context),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(_error!, style: StudentMobileUi.body(context), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: () => _load(), child: Text(l10n.commonRetry)),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      if (flat.length > 1 && !locked)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.studentExamQuestionProgress(_itemIndex + 1, flat.length),
                                style: StudentMobileUi.caption(context),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: (_itemIndex + 1) / flat.length,
                                borderRadius: BorderRadius.circular(4),
                                backgroundColor: AppColors.outlineMuted,
                                color: AppSkillColors.listening.color,
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView(
                          padding: StudentMobileUi.pagePadding,
                          children: [
                            if (expired)
                              AppCard(
                                variant: AppCardVariant.outline,
                                child: Text(l10n.studentExamExpired, style: StudentMobileUi.body(context)),
                              ),
                            if (locked && flat.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              for (var i = 0; i < flat.length; i++) ...[
                                if (flat.length > 1)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      l10n.studentExamQuestionProgress(i + 1, flat.length),
                                      style: StudentMobileUi.caption(context),
                                    ),
                                  ),
                                _buildReviewItemCard(flat[i]),
                                if (i < flat.length - 1) const SizedBox(height: StudentMobileUi.sectionGap),
                              ],
                            ] else if (item != null) ...[
                              const SizedBox(height: 8),
                              _buildItemCard(item, locked),
                            ] else if (!locked)
                              AppCard(
                                variant: AppCardVariant.outline,
                                child: Text(l10n.studentExamNoQuestions, style: StudentMobileUi.body(context)),
                              ),
                            if (submitted && _attempt?['scores'] != null) ...[
                              const SizedBox(height: StudentMobileUi.sectionGap),
                              AppCard(
                                variant: AppCardVariant.outline,
                                child: Text(_scoreSummaryText(), style: StudentMobileUi.body(context)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!locked && flat.isNotEmpty)
                        Container(
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceCard,
                            border: Border(top: BorderSide(color: AppColors.outlineMuted)),
                          ),
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.s5,
                            AppSpacing.s4,
                            AppSpacing.s5,
                            AppSpacing.s4 + MediaQuery.paddingOf(context).bottom,
                          ),
                          child: Row(
                            children: [
                              Text(
                                l10n.studentExamQuestionProgress(_itemIndex + 1, flat.length),
                                style: StudentMobileUi.cardTitle(context),
                              ),
                              const Spacer(),
                              if (_itemIndex > 0) ...[
                                OutlinedButton(
                                  onPressed: () => _goToIndex(_itemIndex - 1),
                                  child: Text(l10n.studentExamPrevious),
                                ),
                                const SizedBox(width: AppSpacing.s3),
                              ],
                              FilledButton(
                                onPressed: _itemIndex < lastIndex
                                    ? () => _goToIndex(_itemIndex + 1)
                                    : _submit,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(88, 44),
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.onPrimary,
                                ),
                                child: Text(
                                  _itemIndex < lastIndex
                                      ? l10n.studentExamNext
                                      : l10n.studentExamSubmit,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
