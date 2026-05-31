import 'package:english_for_community/core/entity/listening_entity.dart';
import 'package:english_for_community/core/entity/writing_topic_entity.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/entity/speaking/speaking_set_entity.dart';
import 'package:english_for_community/core/repository/listening_repository.dart';
import 'package:english_for_community/core/repository/reading_repository.dart';
import 'package:english_for_community/core/repository/speaking_repository.dart';
import 'package:english_for_community/core/repository/writing_repository.dart';
import 'package:english_for_community/core/ui/e4c_scroll_behavior.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/listening/listening_skill/bloc/cue_bloc.dart';
import 'package:english_for_community/feature/listening/listening_skill/bloc/cue_event.dart';
import 'package:english_for_community/feature/listening/listening_skill/listening_skills_page.dart';
import 'package:english_for_community/feature/reading/reading_detail_page.dart';
import 'package:english_for_community/feature/speaking/speaking_skills_page.dart';
import 'package:english_for_community/feature/student/exams/exam_embedded_fixed_writing_panel.dart';
import 'package:english_for_community/feature/student/exams/exam_embedded_listening_comp_panel.dart';
import 'package:english_for_community/feature/student/exams/exam_embedded_listening_dictation_review_panel.dart';
import 'package:english_for_community/feature/student/exams/exam_embedded_speaking_review_panel.dart';
import 'package:english_for_community/feature/student/exams/exam_embedded_skill_scope.dart';
import 'package:english_for_community/feature/student/exams/exam_embedded_writing_review_panel.dart';
import 'package:english_for_community/feature/writing/writing_task_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// In-exam host for CMS-linked skill exercises (no route navigation, no per-skill timer).
class ExamEmbeddedSkillPanel extends StatefulWidget {
  const ExamEmbeddedSkillPanel({
    super.key,
    required this.skill,
    required this.resources,
    required this.locked,
    this.onPartComplete,
    this.onWritingDraftChanged,
    this.sectionId,
    this.initialReadingAnswers,
    this.onReadingAnswersChanged,
    this.onListeningProgress,
    this.initialListeningCueTexts,
    this.initialWritingDraft,
    this.fixedWritingPrompt,
    this.examPracticeMode = true,
    this.listeningType = 'dictation',
    this.onListeningCompProgress,
    this.initialListeningCompAnswers,
    this.onSpeakingProgress,
    this.reviewMode = false,
    this.reviewFeedback,
    this.reviewScore,
  });

  final String skill;
  final List<Map<String, dynamic>> resources;
  final bool locked;
  final VoidCallback? onPartComplete;
  final void Function(String text)? onWritingDraftChanged;
  final String? sectionId;
  final Map<String, int>? initialReadingAnswers;
  final void Function(Map<String, int> answers, int totalQuestions)? onReadingAnswersChanged;
  final void Function(Map<String, String> cueTextsByIndex, int savedCount, int totalCount)?
      onListeningProgress;
  final Map<String, String>? initialListeningCueTexts;
  final String? initialWritingDraft;
  /// Teacher-assigned fixed writing prompt. All students get the same question.
  final Map<String, dynamic>? fixedWritingPrompt;
  final bool examPracticeMode;
  /// 'dictation' (default) or 'comprehension' — controls which panel is shown for listening.
  final String listeningType;
  final void Function(Map<String, int> answers, int savedCount, int totalCount)? onListeningCompProgress;
  final Map<String, int>? initialListeningCompAnswers;
  final void Function(int sentenceIndex, int totalSentences, int savedCount)? onSpeakingProgress;
  /// Post-submit graded review — show answers with correct/incorrect feedback (read-only).
  final bool reviewMode;
  final String? reviewFeedback;
  final dynamic reviewScore;

  @override
  State<ExamEmbeddedSkillPanel> createState() => _ExamEmbeddedSkillPanelState();
}

class _ExamEmbeddedSkillPanelState extends State<ExamEmbeddedSkillPanel> {
  bool _loading = true;
  String? _error;
  int _resourceIndex = 0;
  dynamic _payload;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  @override
  void didUpdateWidget(covariant ExamEmbeddedSkillPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.skill != widget.skill ||
        oldWidget.resources.length != widget.resources.length ||
        oldWidget.listeningType != widget.listeningType ||
        _currentResourceId(oldWidget) != _currentResourceId(widget)) {
      _resourceIndex = 0;
      _loadCurrent();
    }
  }

  String _currentResourceId([ExamEmbeddedSkillPanel? w]) {
    final panel = w ?? widget;
    if (panel.resources.isEmpty) return '';
    final idx = _resourceIndex.clamp(0, panel.resources.length - 1);
    final raw = panel.resources[idx]['id'] ?? panel.resources[idx]['_id'];
    return raw?.toString().trim() ?? '';
  }

  Future<void> _loadCurrent() async {
    final id = _currentResourceId();
    if (id.isEmpty) {
      setState(() {
        _loading = false;
        _error = null;
        _payload = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _payload = null;
    });

    switch (widget.skill) {
      case 'listening':
        // Comprehension panel loads its own data internally — skip loading here.
        if (widget.listeningType == 'comprehension') {
          if (mounted) setState(() { _loading = false; _payload = null; });
          return;
        }
        final r = await getIt<ListeningRepository>().getListeningById(id);
        if (!mounted) return;
        r.fold(
          (f) => setState(() {
            _error = f.message;
            _loading = false;
          }),
          (entity) => setState(() {
            _payload = entity;
            _loading = false;
          }),
        );
      case 'speaking':
        final r = await getIt<SpeakingRepository>().getSpeakingSetDetails(id);
        if (!mounted) return;
        r.fold(
          (f) => setState(() {
            _error = f.message;
            _loading = false;
          }),
          (set) => setState(() {
            _payload = set;
            _loading = false;
          }),
        );
      case 'reading':
        final r = await getIt<ReadingRepository>().getReadingDetail(id);
        if (!mounted) return;
        r.fold(
          (f) => setState(() {
            _error = f.message;
            _loading = false;
          }),
          (reading) => setState(() {
            _payload = reading;
            _loading = false;
          }),
        );
      case 'writing':
        final r = await getIt<WritingRepository>().getWritingTopicDetail(id);
        if (!mounted) return;
        r.fold(
          (f) => setState(() {
            _error = f.message;
            _loading = false;
          }),
          (topic) => setState(() {
            _payload = topic;
            _loading = false;
          }),
        );
      default:
        if (mounted) {
          setState(() {
            _error = 'Unsupported skill';
            _loading = false;
          });
        }
    }
  }

  void _onExerciseFinished() {
    if (widget.resources.length > 1 && _resourceIndex < widget.resources.length - 1) {
      setState(() => _resourceIndex++);
      _loadCurrent();
      return;
    }
    widget.onPartComplete?.call();
  }

  String _taskTypeForWriting(dynamic topic) {
    final types = topic.aiConfig?.taskTypes;
    if (types != null && types.isNotEmpty) return types.first;
    return topic.aiConfig?.defaultTaskType ?? 'Discussion';
  }

  Widget _buildEmbeddedExercise() {
    if (widget.locked && !widget.reviewMode) {
      return AppCard(
        variant: AppCardVariant.outline,
        child: Text(
          context.l10n.integratedExamEmbeddedLocked,
          style: ExamSystemUi.captionSecondary,
        ),
      );
    }

    final readOnly = widget.locked && widget.reviewMode;

    switch (widget.skill) {
      case 'listening':
        final entity = _payload;
        final listenId = _currentResourceId();
        if (widget.listeningType == 'comprehension') {
          return ExamEmbeddedListeningCompPanel(
            key: ValueKey('exam_listen_comp_$listenId'),
            resourceId: listenId,
            locked: widget.locked,
            reviewMode: widget.reviewMode,
            initialAnswers: widget.initialListeningCompAnswers ?? {},
            onProgress: widget.onListeningCompProgress,
          );
        }
        if (readOnly && entity is ListeningEntity) {
          return ExamEmbeddedListeningDictationReviewPanel(
            key: ValueKey('exam_listen_review_$listenId'),
            listening: entity,
            userCueTextsByIndex: widget.initialListeningCueTexts ?? {},
          );
        }
        final initialCueTexts = <int, String>{};
        widget.initialListeningCueTexts?.forEach((k, v) {
          final idx = int.tryParse(k);
          if (idx != null && v.trim().isNotEmpty) initialCueTexts[idx] = v.trim();
        });
        return BlocProvider(
          key: ValueKey('exam_listen_$listenId'),
          create: (_) => getIt<CueBloc>()
            ..add(LoadCuesAndAttempts(
              listeningId: listenId,
              examPracticeMode: true,
              isRetake: true,
              initialCueTexts: initialCueTexts.isEmpty ? null : initialCueTexts,
            )),
          child: ListeningSkillsPage(
            listeningId: listenId,
            audioUrl: entity.audioUrl as String,
            title: entity.title as String?,
            embedded: true,
            examPracticeMode: true,
            readOnlyReview: readOnly,
            onPartComplete: _onExerciseFinished,
            onExamListeningProgress: widget.onListeningProgress,
          ),
        );
      case 'speaking':
        if (readOnly && _payload is SpeakingSetEntity) {
          return ExamEmbeddedSpeakingReviewPanel(
            key: ValueKey('exam_speak_review_${_currentResourceId()}'),
            speakingSet: _payload as SpeakingSetEntity,
          );
        }
        return SpeakingSkillsPage(
          key: ValueKey('exam_speak_${_currentResourceId()}'),
          setId: _currentResourceId(),
          isRetake: true,
          embedded: true,
          examPracticeMode: widget.examPracticeMode,
          readOnlyReview: readOnly,
          onPartComplete: _onExerciseFinished,
          onExamSpeakingProgress: widget.onSpeakingProgress,
        );
      case 'reading':
        return ReadingDetailPage(
          key: ValueKey('exam_read_${_currentResourceId()}'),
          reading: _payload,
          isRetake: true,
          embedded: true,
          disableTimer: true,
          initialSelectedAnswers: widget.initialReadingAnswers,
          onExamAnswersChanged: widget.onReadingAnswersChanged,
          examReviewMode: widget.reviewMode,
        );
      case 'writing':
        if (readOnly) {
          final prompt = widget.fixedWritingPrompt;
          final topicTitle =
              _payload is WritingTopicEntity ? (_payload as WritingTopicEntity).name : null;
          return ExamEmbeddedWritingReviewPanel(
            key: ValueKey('exam_write_review_${_currentResourceId()}'),
            promptTitle: prompt?['title'] as String? ?? topicTitle,
            promptText: prompt?['text'] as String?,
            studentDraft: widget.initialWritingDraft ?? '',
            feedback: widget.reviewFeedback,
            score: widget.reviewScore,
          );
        }
        final topic = _payload;
        return WritingTaskPage(
          key: ValueKey('exam_write_${_currentResourceId()}'),
          topic: topic,
          selectedTaskType: widget.fixedWritingPrompt?['taskType'] as String? ?? _taskTypeForWriting(topic),
          embedded: true,
          examPracticeMode: widget.examPracticeMode,
          readOnlyReview: readOnly,
          initialExamDraft: widget.initialWritingDraft,
          onPartComplete: _onExerciseFinished,
          onEmbeddedDraftChanged: widget.onWritingDraftChanged,
          fixedPrompt: widget.fixedWritingPrompt,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// Height when embedded in a scroll view (e.g. post-submit review) — [Expanded] needs bounded max height.
  static double _scrollEmbeddedHeight(BuildContext context) {
    return (MediaQuery.sizeOf(context).height * 0.55).clamp(320.0, 720.0);
  }

  Widget _exerciseHost() {
    final body = _buildEmbeddedExercise();
    final readOnlyReview = widget.locked && widget.reviewMode;
    // Reading uses TabBarView+Expanded; writing review scrolls internally — neither
    // can sit inside an outer SingleChildScrollView (unbounded height → layout crash).
    final scrollable = (widget.skill == 'listening' ||
            (widget.reviewMode &&
                widget.skill != 'reading' &&
                widget.skill != 'writing') ||
            (widget.skill == 'writing' && widget.locked && !readOnlyReview));
    return ExamEmbeddedSkillTheme(
      child: scrollable ? SingleChildScrollView(primary: false, child: body) : body,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final resources = widget.resources;

    if (widget.skill == 'writing' &&
        widget.reviewMode &&
        resources.isEmpty &&
        widget.fixedWritingPrompt != null &&
        (widget.fixedWritingPrompt!['text'] as String?)?.trim().isNotEmpty == true) {
      return SizedBox(
        height: _scrollEmbeddedHeight(context),
        child: ExamEmbeddedWritingReviewPanel(
          promptTitle: widget.fixedWritingPrompt!['title'] as String?,
          promptText: widget.fixedWritingPrompt!['text'] as String?,
          studentDraft: widget.initialWritingDraft ?? '',
          feedback: widget.reviewFeedback,
          score: widget.reviewScore,
        ),
      );
    }

    if (widget.skill == 'writing' &&
        resources.isEmpty &&
        widget.fixedWritingPrompt != null &&
        (widget.fixedWritingPrompt!['text'] as String?)?.trim().isNotEmpty == true) {
      return ExamEmbeddedFixedWritingPanel(
        fixedWritingPrompt: widget.fixedWritingPrompt!,
        locked: widget.locked,
        initialDraft: widget.initialWritingDraft,
        onDraftChanged: widget.onWritingDraftChanged,
        onPartComplete: widget.locked ? null : widget.onPartComplete,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedHeight = constraints.hasBoundedHeight;

        return Column(
          mainAxisSize: boundedHeight ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (resources.length > 1) ...[
              const SizedBox(height: 10),
              e4cHorizontalScroll(
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: resources.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final title = resources[i]['title'] as String? ?? '${i + 1}';
                      final selected = i == _resourceIndex;
                      return ChoiceChip(
                        label: Text(title, overflow: TextOverflow.ellipsis, style: ExamSystemUi.embeddedCaptionStyle),
                        labelStyle: ExamSystemUi.embeddedCaptionStyle,
                        selected: selected,
                        onSelected: widget.locked
                            ? null
                            : (v) {
                                if (!v || i == _resourceIndex) return;
                                setState(() => _resourceIndex = i);
                                _loadCurrent();
                              },
                      );
                    },
                  ),
                ),
              ),
            ],
            if (widget.skill != 'speaking' && resources.length <= 1)
              const SizedBox(height: ExamSystemUi.cardGap),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              AppCard(
                variant: AppCardVariant.outline,
                child: Column(
                  children: [
                    Text(_error!, style: ExamSystemUi.captionSecondary),
                    const SizedBox(height: 8),
                    TextButton(onPressed: _loadCurrent, child: Text(l10n.retry)),
                  ],
                ),
              )
            else if (resources.isEmpty)
              AppCard(
                variant: AppCardVariant.outline,
                child: Text(
                  widget.skill == 'speaking'
                      ? l10n.integratedExamEmbeddedNoSpeakingResource
                      : l10n.integratedExamEmbeddedNoResource,
                  style: ExamSystemUi.captionSecondary,
                ),
              )
            else if (boundedHeight)
              Expanded(child: _exerciseHost())
            else
              SizedBox(
                height: _scrollEmbeddedHeight(context),
                child: _exerciseHost(),
              ),
          ],
        );
      },
    );
  }
}
