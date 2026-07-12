import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/entity/reading/reading_entity.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/reading_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/core/ui/e4c_scroll_behavior.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/student/exams/exam_section_resources.dart';
import 'package:english_for_community/feature/student/exams/integrated_exam_grammar_widgets.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_widgets.dart';
import 'package:english_for_community/feature/teacher/widgets/teacher_exam_question_strip.dart';
import 'package:flutter/material.dart';

/// Read-only replica of the student's integrated exam screen for teacher live view.
class StudentExamLiveMirrorView extends StatefulWidget {
  const StudentExamLiveMirrorView({
    super.key,
    required this.liveScreen,
    this.showLiveBadge = true,
  });

  final Map<String, dynamic> liveScreen;
  final bool showLiveBadge;

  @override
  State<StudentExamLiveMirrorView> createState() => _StudentExamLiveMirrorViewState();
}

class _StudentExamLiveMirrorViewState extends State<StudentExamLiveMirrorView> {
  /// When set, teacher browses parts locally; resets when student changes part.
  int? _teacherPartOverride;
  int? _lastStudentPartIndex;
  bool _questionMapExpanded = true;

  int _resolveGrammarNavIndex(
    List<Map<String, dynamic>> grammar,
    Map<String, dynamic> liveView,
  ) {
    if (grammar.isEmpty) return 0;
    final itemId = (liveView['currentGrammarItemId'] as String?)?.trim();
    if (itemId != null && itemId.isNotEmpty) {
      final i = grammar.indexWhere((g) => (g['itemId'] as String?) == itemId);
      if (i >= 0) return i;
    }
    final fromNav = (liveView['grammarNavIndex'] as num?)?.toInt();
    if (fromNav != null) return fromNav.clamp(0, grammar.length - 1);
    return 0;
  }

  List<Map<String, dynamic>> _grammarItems(Map<String, dynamic> snap) {
    final settings = snap['settings'];
    if (settings is! Map) return [];
    final raw = settings['grammarItems'];
    if (raw is! List) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  List<Map<String, dynamic>> _sections(Map<String, dynamic> snap) {
    final raw = snap['sections'];
    if (raw is! List) return [];
    final secs = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    secs.sort((a, b) => (a['order'] as num?)?.compareTo((b['order'] as num?) ?? 0) ?? 0);
    return secs.where((s) => s['skill'] != null).toList();
  }

  List<_MirrorPart> _parts(BuildContext context, Map<String, dynamic> snap, Map answers) {
    final l10n = context.l10n;
    final list = <_MirrorPart>[];
    final grammar = _grammarItems(snap);
    if (grammar.isNotEmpty) {
      list.add(_MirrorPart(
        key: '__grammar__',
        title: l10n.integratedExamGrammarSectionTitle,
        isGrammar: true,
      ));
    }

    final allSections = _sections(snap);
    final listeningSections = allSections.where((s) => s['skill'] == 'listening').toList();
    bool listeningAdded = false;

    for (final s in allSections) {
      final sid = s['sectionId'] as String? ?? '';
      final skill = s['skill'] as String? ?? '';

      if (skill == 'listening') {
        if (listeningAdded) continue;
        listeningAdded = true;
        if (listeningSections.length == 1) {
          list.add(_MirrorPart(
            key: sid,
            title: _skillTitle(context, 'listening'),
            isGrammar: false,
            section: s,
            done: answers[sid] is Map && (answers[sid] as Map)['completed'] == true,
          ));
        } else {
          list.add(_MirrorPart(
            key: '__listening_merged__',
            title: _skillTitle(context, 'listening'),
            isGrammar: false,
            mergedSections: listeningSections,
            done: listeningSections.every((ls) {
              final lsId = ls['sectionId'] as String? ?? '';
              return answers[lsId] is Map && (answers[lsId] as Map)['completed'] == true;
            }),
          ));
        }
      } else {
        list.add(_MirrorPart(
          key: sid,
          title: _skillTitle(context, skill),
          isGrammar: false,
          section: s,
          done: answers[sid] is Map && (answers[sid] as Map)['completed'] == true,
        ));
      }
    }
    return list;
  }

  String _skillTitle(BuildContext context, String skill) {
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

  void _syncStudentPartIndex(int studentIdx) {
    if (_lastStudentPartIndex != studentIdx) {
      _lastStudentPartIndex = studentIdx;
      _teacherPartOverride = null;
      _questionMapExpanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final snap = widget.liveScreen['examSnapshot'] is Map
        ? Map<String, dynamic>.from(widget.liveScreen['examSnapshot'] as Map)
        : <String, dynamic>{};
    final answers = widget.liveScreen['answers'] is Map
        ? Map<String, dynamic>.from(widget.liveScreen['answers'] as Map)
        : <String, dynamic>{};
    final liveView = widget.liveScreen['liveView'] is Map
        ? Map<String, dynamic>.from(widget.liveScreen['liveView'] as Map)
        : <String, dynamic>{};
    final studentIdx = (liveView['activePartIndex'] as num?)?.toInt() ?? 0;
    _syncStudentPartIndex(studentIdx);

    final grammar = _grammarItems(snap);
    final grammarIdx = _resolveGrammarNavIndex(grammar, liveView);

    final parts = _parts(context, snap, answers);
    if (parts.isEmpty) {
      return Center(
        child: Text(l10n.teacherLiveMirrorNoContent, style: ExamSystemUi.captionSecondary),
      );
    }
    final idx = (_teacherPartOverride ?? studentIdx).clamp(0, parts.length - 1);
    final active = parts[idx];
    final followingStudent = _teacherPartOverride == null || _teacherPartOverride == studentIdx;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showLiveBadge)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TeacherLiveMirrorStatusBanner(
              followingStudent: followingStudent,
              message: followingStudent
                  ? l10n.teacherLiveMirrorLiveBadge
                  : l10n.teacherLiveMirrorBrowsingPart(active.title),
              followActionLabel: l10n.teacherLiveMirrorFollowStudent,
              onFollowStudent: followingStudent ? null : () => setState(() => _teacherPartOverride = null),
            ),
          ),
        SizedBox(
          height: 44,
          child: e4cHorizontalScroll(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: parts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final p = parts[i];
                return TeacherExamPartTabChip(
                  label: p.title,
                  selected: i == idx,
                  done: p.done,
                  studentHere: i == studentIdx,
                  onTap: () => setState(() {
                    _teacherPartOverride = i;
                  }),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Question map + mirrored content share ONE scroll so the full all-skills
        // map (Grammar…Speaking) displays completely instead of clipping.
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (TeacherExamQuestionStripSection.parseStrips(widget.liveScreen['skillStrips']).isNotEmpty) ...[
                  _buildQuestionMapPanel(context),
                  const SizedBox(height: 12),
                ],
                active.isGrammar
                    ? _buildGrammarMirror(context, grammar, grammarIdx, answers)
                    : active.isMergedListening
                        ? _buildMergedListeningMirror(context, active.mergedSections!, answers)
                        : _buildSkillMirror(context, active.section!, answers),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionMapPanel(BuildContext context) {
    final l10n = context.l10n;
    final allStrips = TeacherExamQuestionStripSection.parseStrips(widget.liveScreen['skillStrips']);
    if (allStrips.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: ExamSystemUi.softCard(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _questionMapExpanded = !_questionMapExpanded),
                borderRadius: BorderRadius.circular(AppSpacing.s2),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.grid_view_rounded, size: 15, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.teacherLiveMirrorQuestionMap,
                          style: ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Icon(
                        _questionMapExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Auto-grading legend stays visible so box colours are always readable.
            const SizedBox(height: 8),
            TeacherQuestionStatusLegend(
              correctLabel: l10n.teacherLiveMonitorGrammarCorrect,
              wrongLabel: l10n.teacherLiveMonitorGrammarWrong,
              unansweredLabel: l10n.teacherLiveMonitorGrammarNotAnswered,
            ),
            if (_questionMapExpanded) ...[
              const SizedBox(height: 10),
              // Full all-skills map — no height clip; the page scroll handles overflow.
              TeacherExamSkillStripsPanel(
                skillStrips: allStrips,
                compact: true,
                showLegend: false,
                singleSectionMode: false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGrammarMirror(
    BuildContext context,
    List<Map<String, dynamic>> grammar,
    int navIndex,
    Map<String, dynamic> answers,
  ) {
    final l10n = context.l10n;
    if (grammar.isEmpty) return const SizedBox.shrink();
    final i = navIndex.clamp(0, grammar.length - 1);
    final item = grammar[i];
    final itemId = item['itemId'] as String? ?? '';
    Map<String, dynamic>? ans;
    if (answers[itemId] is Map) {
      ans = Map<String, dynamic>.from(answers[itemId] as Map);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.integratedExamGrammarQuestionLabel(i + 1, grammar.length),
          style: ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: ExamSystemUi.cardGap),
        IntegratedExamGrammarQuestionCard(
          displayIndex: i + 1,
          item: item,
          answer: ans,
          locked: true,
          onPartialPatch: (_) {},
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _sectionResources(Map<String, dynamic> section) =>
      sectionResourcesFrom(section);

  Widget _buildMergedListeningMirror(
    BuildContext context,
    List<Map<String, dynamic>> sections,
    Map<String, dynamic> answers,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          variant: AppCardVariant.outline,
          child: Row(
            children: [
              Icon(_skillIcon('listening'), size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_skillTitle(context, 'listening'), style: ExamSystemUi.sectionTitle(context)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const Divider(height: 20),
          _buildListeningSubMirror(context, sections[i], answers),
        ],
      ],
    );
  }

  Widget _buildListeningSubMirror(
    BuildContext context,
    Map<String, dynamic> section,
    Map<String, dynamic> answers,
  ) {
    final sid = section['sectionId'] as String? ?? '';
    final sc = section['sectionConfig'];
    final lt = (sc is Map ? (sc['listeningType'] as String?) : null) ?? 'dictation';
    final label = lt == 'comprehension'
        ? context.l10n.teacherExamListeningTypeComprehension
        : context.l10n.teacherExamListeningTypeDictation;
    final icon = lt == 'comprehension' ? Icons.headphones_outlined : Icons.text_fields_outlined;
    final ans = answers[sid] is Map
        ? Map<String, dynamic>.from(answers[sid] as Map)
        : <String, dynamic>{};
    final resources = _sectionResources(section);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w600)),
            if (resources.isNotEmpty) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '• ${resources.first['title'] ?? ''}',
                  style: ExamSystemUi.captionMuted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (lt == 'comprehension')
          _buildListeningCompMirror(context, ans)
        else
          _buildListeningMirror(context, ans),
      ],
    );
  }

  Widget _buildListeningCompMirror(BuildContext context, Map<String, dynamic> ans) {
    final l10n = context.l10n;
    final compAnswers = ans['listeningCompAnswers'];
    final saved = (ans['listeningCompSaved'] as num?)?.toInt();
    final total = (ans['listeningCompTotal'] as num?)?.toInt();

    if (compAnswers is! Map || compAnswers.isEmpty) {
      return Text(l10n.teacherLiveMirrorListeningEmpty, style: ExamSystemUi.captionSecondary);
    }

    final progressLabel = saved != null && total != null
        ? '$saved / $total'
        : '${compAnswers.length} answered';

    final entries = compAnswers.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('MCQ progress: $progressLabel', style: ExamSystemUi.captionMuted),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < entries.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Q${i + 1}: ${String.fromCharCode(65 + (entries[i].value as num).toInt())}',
                  style: ExamSystemUi.captionSecondary.copyWith(fontSize: AppTypography.mobileLabel),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillMirror(
    BuildContext context,
    Map<String, dynamic> section,
    Map<String, dynamic> answers,
  ) {
    final skill = section['skill'] as String? ?? '';
    final sid = section['sectionId'] as String? ?? '';
    final ans = answers[sid] is Map ? Map<String, dynamic>.from(answers[sid] as Map) : <String, dynamic>{};
    final completed = ans['completed'] == true;
    final resources = _sectionResources(section);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          variant: AppCardVariant.outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_skillIcon(skill), size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_skillTitle(context, skill), style: ExamSystemUi.sectionTitle(context)),
                  ),
                  if (completed)
                    const Icon(Icons.check_circle, size: 18, color: AppColors.primary),
                ],
              ),
              if (resources.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...resources.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${r['title'] ?? r['id'] ?? ''}',
                      style: ExamSystemUi.captionSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        switch (skill) {
          'writing' => _buildWritingMirror(context, section, ans),
          'reading' => _buildReadingMirror(context, resources, ans),
          'listening' => _buildListeningMirror(context, ans),
          'speaking' => _buildSpeakingMirror(context, ans, completed),
          _ => _buildGenericSkillMirror(context, skill, completed),
        },
      ],
    );
  }

  Widget _buildWritingMirror(BuildContext context, Map<String, dynamic> section, Map<String, dynamic> ans) {
    final l10n = context.l10n;
    final draft = (ans['writingDraft'] as String?)?.trim() ?? '';
    final wordCount = (ans['wordCount'] as num?)?.toInt() ?? 0;
    final fixed = section['fixedWritingPrompt'];
    final promptText = fixed is Map ? (fixed['text'] as String?)?.trim() ?? '' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (promptText.isNotEmpty) ...[
          Text(l10n.teacherLiveMirrorWritingPrompt, style: ExamSystemUi.captionMuted),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.outlineMuted),
            ),
            child: Text(promptText, style: ExamSystemUi.captionSecondary.copyWith(height: 1.45)),
          ),
          const SizedBox(height: 12),
        ],
        if (draft.isNotEmpty) ...[
          Text(l10n.teacherLiveMirrorWritingDraft, style: ExamSystemUi.captionMuted),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.outlineMuted),
            ),
            child: Text(draft, style: ExamSystemUi.captionSecondary.copyWith(height: 1.5)),
          ),
          const SizedBox(height: 6),
          Text(l10n.teacherLiveMirrorWordCount(wordCount), style: ExamSystemUi.captionMuted),
        ] else
          Text(l10n.teacherLiveMirrorWritingEmpty, style: ExamSystemUi.captionSecondary),
      ],
    );
  }

  Widget _buildReadingMirror(
    BuildContext context,
    List<Map<String, dynamic>> resources,
    Map<String, dynamic> ans,
  ) {
    final raw = ans['readingAnswers'];
    final selected = <String, int>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is num) selected['$k'] = v.toInt();
      });
    }

    final readingResources = resources
        .where((r) => ((r['id'] as String?)?.trim().isNotEmpty ?? false))
        .toList();
    if (readingResources.isEmpty) {
      return _buildGenericSkillMirror(context, 'reading', ans['completed'] == true);
    }
    if (readingResources.length == 1) {
      return _ReadingLiveMirrorBody(
        readingId: (readingResources.first['id'] as String).trim(),
        selectedAnswers: selected,
      );
    }

    // Multi-resource: render từng bài để teacher thấy bài làm dù học sinh đang ở bài nào.
    // `selectedAnswers` là map gộp toàn section; mỗi body tự lọc theo q.id của bài đó.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < readingResources.length; i++) ...[
          if (i > 0) const Divider(height: 24),
          _ReadingResourceHeader(
            index: i + 1,
            total: readingResources.length,
            title: (readingResources[i]['title'] as String?)?.trim() ?? '',
          ),
          const SizedBox(height: 8),
          _ReadingLiveMirrorBody(
            key: ValueKey('reading_mirror_${readingResources[i]['id']}'),
            readingId: (readingResources[i]['id'] as String).trim(),
            selectedAnswers: selected,
          ),
        ],
      ],
    );
  }

  Widget _buildListeningMirror(BuildContext context, Map<String, dynamic> ans) {
    final l10n = context.l10n;
    final raw = ans['listeningCues'];
    final saved = (ans['listeningSaved'] as num?)?.toInt();
    final total = (ans['listeningTotal'] as num?)?.toInt();

    final cues = <int, String>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        final idx = int.tryParse('$k');
        final text = v is String ? v.trim() : '';
        if (idx != null && text.isNotEmpty) cues[idx] = text;
      });
    }

    if (cues.isEmpty && saved == null) {
      return Text(l10n.teacherLiveMirrorListeningEmpty, style: ExamSystemUi.captionSecondary);
    }

    final sortedKeys = cues.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (saved != null && total != null && total > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              l10n.teacherLiveMirrorListeningProgress(saved, total),
              style: ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ...sortedKeys.map((i) {
          final text = cues[i]!;
          final preview = text.length > 200 ? '${text.substring(0, 197)}…' : text;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.outlineMuted),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.teacherLiveMirrorListeningCue(i + 1),
                    style: ExamSystemUi.captionMuted.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(preview, style: ExamSystemUi.captionSecondary.copyWith(height: 1.45)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSpeakingMirror(BuildContext context, Map<String, dynamic> ans, bool completed) {
    final l10n = context.l10n;
    if (completed) {
      return Text(
        l10n.teacherLiveMirrorSkillCompleted,
        style: ExamSystemUi.captionSecondary,
      );
    }
    final idx = (ans['speakingSentenceIndex'] as num?)?.toInt();
    final total = (ans['speakingTotal'] as num?)?.toInt();
    if (idx != null && total != null && total > 0) {
      return Text(
        l10n.sentenceIndex(idx + 1, total),
        style: ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w600),
      );
    }
    return Text(
      l10n.teacherLiveMirrorSpeakingInProgress,
      style: ExamSystemUi.captionSecondary,
    );
  }

  Widget _buildGenericSkillMirror(BuildContext context, String skill, bool completed) {
    final l10n = context.l10n;
    return AppCard(
      variant: AppCardVariant.outline,
      child: Row(
        children: [
          if (!completed) ...[
            const SizedBox(
              width: 20,
              height: 20,
              child: AppLoadingIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              completed
                  ? l10n.teacherLiveMirrorSkillCompleted
                  : l10n.teacherLiveMirrorSkillInProgress(_skillTitle(context, skill)),
              style: ExamSystemUi.captionSecondary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _skillIcon(String skill) {
    switch (skill) {
      case 'listening':
        return Icons.headphones_outlined;
      case 'speaking':
        return Icons.mic_outlined;
      case 'reading':
        return Icons.menu_book_outlined;
      case 'writing':
        return Icons.edit_outlined;
      default:
        return Icons.school_outlined;
    }
  }
}

/// Loads reading passage and shows student's MCQ choices (live).
class _ReadingLiveMirrorBody extends StatefulWidget {
  const _ReadingLiveMirrorBody({
    super.key,
    required this.readingId,
    required this.selectedAnswers,
  });

  final String readingId;
  final Map<String, int> selectedAnswers;

  @override
  State<_ReadingLiveMirrorBody> createState() => _ReadingLiveMirrorBodyState();
}

class _ReadingLiveMirrorBodyState extends State<_ReadingLiveMirrorBody> {
  ReadingEntity? _reading;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _ReadingLiveMirrorBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readingId != widget.readingId) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await getIt<ReadingRepository>().getReadingDetail(widget.readingId);
    if (!mounted) return;
    r.fold(
      (f) => setState(() {
        _error = f.message;
        _loading = false;
      }),
      (entity) => setState(() {
        _reading = entity;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: StudentMobileUi.runnerLoading(),
      );
    }
    if (_error != null) {
      return Text(_error!, style: ExamSystemUi.captionSecondary);
    }
    final reading = _reading;
    if (reading == null) return const SizedBox.shrink();

    // Đáp án thuộc về bài này (lọc theo q.id của chính reading doc này) —
    // `selectedAnswers` là map gộp toàn section nên có thể chứa đáp án của bài khác.
    final questionIds = reading.questions.map((q) => q.id).toSet();
    final answeredHere = widget.selectedAnswers.keys.any(questionIds.contains);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (reading.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(reading.title, style: ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w600)),
          ),
        if (!answeredHere)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(l10n.teacherLiveMirrorReadingEmpty, style: ExamSystemUi.captionMuted),
          ),
        ...reading.questions.asMap().entries.map((entry) {
          final qi = entry.key;
          final q = entry.value;
          final chosen = widget.selectedAnswers[q.id];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.outlineMuted),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.teacherLiveMirrorReadingQuestion(qi + 1),
                    style: ExamSystemUi.captionMuted.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(q.questionText, style: ExamSystemUi.captionSecondary.copyWith(height: 1.4)),
                  const SizedBox(height: 8),
                  ...q.options.asMap().entries.map((opt) {
                    final selected = chosen == opt.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${String.fromCharCode(65 + opt.key)}.',
                            style: ExamSystemUi.captionMuted.copyWith(
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                              color: selected ? AppColors.primaryDark : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              opt.value,
                              style: ExamSystemUi.captionSecondary.copyWith(
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                color: selected ? AppColors.primaryDark : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          if (selected)
                            const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

/// Header phân tách các bài (resource) trong cùng một skill section ở mirror.
class _ReadingResourceHeader extends StatelessWidget {
  const _ReadingResourceHeader({
    required this.index,
    required this.total,
    required this.title,
  });

  final int index;
  final int total;
  final String title;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.teacherLiveMirrorExerciseLabel(index, total);
    return Row(
      children: [
        const Icon(Icons.menu_book_outlined, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w600),
        ),
        if (title.isNotEmpty) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '• $title',
              style: ExamSystemUi.captionMuted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class _MirrorPart {
  const _MirrorPart({
    required this.key,
    required this.title,
    required this.isGrammar,
    this.section,
    this.mergedSections,
    this.done = false,
  });

  final String key;
  final String title;
  final bool isGrammar;
  final Map<String, dynamic>? section;
  final List<Map<String, dynamic>>? mergedSections;
  final bool done;

  bool get isMergedListening => mergedSections != null && mergedSections!.isNotEmpty;
}
