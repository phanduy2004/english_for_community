import 'dart:async';

import 'package:flutter/material.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import các file trong project của bạn
import 'package:english_for_community/feature/reading/reading_attempt_bloc/reading_attempt_bloc.dart';
import 'package:english_for_community/feature/reading/reading_attempt_bloc/reading_attempt_event.dart';
import 'package:english_for_community/feature/reading/reading_attempt_bloc/reading_attempt_payload.dart';
import 'package:english_for_community/feature/reading/reading_attempt_bloc/reading_attempt_state.dart';
import '../../core/entity/reading/reading_entity.dart';
import '../../core/entity/reading/reading_feedback_entity.dart';
import '../../core/entity/reading/reading_progress_entity.dart';
import '../../core/get_it/get_it.dart';
import '../../core/locale/l10n_context.dart';
import '../../core/ui/feedback/app_feedback.dart';
import '../../core/repository/reading_repository.dart';
import '../../core/theme/app_color.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/util/app_haptics.dart';
import '../../core/ui/exam_system_ui.dart';
import '../../core/ui/student_mobile_ui.dart';
import '../../core/ui/widget/app_card.dart';
import '../student/exams/exam_embedded_skill_scope.dart';

// =============================================================================
// 1. WIDGET CHA
// =============================================================================
class ReadingDetailPage extends StatelessWidget {
  final ReadingEntity reading;
  final bool isRetake;
  final bool embedded;
  final bool disableTimer;
  final VoidCallback? onPartComplete;
  final Map<String, int>? initialSelectedAnswers;
  final void Function(Map<String, int> answers, int totalQuestions)? onExamAnswersChanged;
  final bool examReviewMode;

  const ReadingDetailPage({
    super.key,
    required this.reading,
    this.isRetake = false,
    this.embedded = false,
    this.disableTimer = false,
    this.onPartComplete,
    this.initialSelectedAnswers,
    this.onExamAnswersChanged,
    this.examReviewMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = ReadingAttemptBloc(
          readingRepository: getIt<ReadingRepository>(),
        );
        // 🔥 NẾU KHÔNG PHẢI RETAKE THÌ MỚI GỌI API LẤY LỊCH SỬ
        if (reading.progress?.status == ProgressStatus.completed && !isRetake) {
          bloc.add(FetchLastAttemptEvent(readingId: reading.id));
        }
        return bloc;
      },
      // Truyền isRetake xuống View con
      child: _ReadingDetailView(
        reading: reading,
        isRetake: isRetake,
        embedded: embedded,
        disableTimer: disableTimer,
        onPartComplete: onPartComplete,
        initialSelectedAnswers: initialSelectedAnswers,
        onExamAnswersChanged: onExamAnswersChanged,
        examReviewMode: examReviewMode,
      ),
    );
  }
}

// =============================================================================
// 2. WIDGET CON
// =============================================================================
class _ReadingDetailView extends StatefulWidget {
  final ReadingEntity reading;
  final bool isRetake;
  final bool embedded;
  final bool disableTimer;
  final VoidCallback? onPartComplete;
  final Map<String, int>? initialSelectedAnswers;
  final void Function(Map<String, int> answers, int totalQuestions)? onExamAnswersChanged;
  final bool examReviewMode;

  const _ReadingDetailView({
    required this.reading,
    this.isRetake = false,
    this.embedded = false,
    this.disableTimer = false,
    this.onPartComplete,
    this.initialSelectedAnswers,
    this.onExamAnswersChanged,
    this.examReviewMode = false,
  });

  @override
  State<_ReadingDetailView> createState() => _ReadingDetailViewState();
}

class _ReadingDetailViewState extends State<_ReadingDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Map<String, int> _selectedAnswers = {};

  Timer? _timer;
  late int _remainingSeconds;
  late final int _totalSeconds;

  bool _isReviewMode = false;
  final Set<String> _expandedFeedback = {};
  bool _showReadingTranslation = false;
  late final PageController _questionPageController;
  int _questionPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _questionPageController = PageController();

    _totalSeconds = widget.reading.minutesToRead * 60;
    _remainingSeconds = _totalSeconds;

    final examPractice = widget.onExamAnswersChanged != null;
    // Exam: never show practice review UI; retake also resets review.
    _isReviewMode = !examPractice &&
        (widget.reading.progress?.status == ProgressStatus.completed) &&
        !widget.isRetake;
    if (widget.initialSelectedAnswers != null) {
      _selectedAnswers.addAll(widget.initialSelectedAnswers!);
    }

    if (!_isReviewMode && !widget.disableTimer) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(covariant _ReadingDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.initialSelectedAnswers;
    if (next == null || next == oldWidget.initialSelectedAnswers) return;
    setState(() {
      _selectedAnswers
        ..clear()
        ..addAll(next);
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        if (mounted) {
          final currentState = context.read<ReadingAttemptBloc>().state;
          if (currentState.status == AttemptStatus.initial || currentState.status == AttemptStatus.error) {
            AppFeedback.error(context, context.l10n.quizTimeUpSubmitting);
            _submitQuiz(context);
          }
        }
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _questionPageController.dispose();
    _tabController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _submitQuiz(BuildContext context) {
    _timer?.cancel();
    final questions = widget.reading.questions;
    final List<AnswerPayload> answerPayloads = [];
    int correctCount = 0;

    final int durationInSeconds = _totalSeconds - _remainingSeconds;

    for (final question in questions) {
      final chosenIndex = _selectedAnswers[question.id];
      if (chosenIndex == null) {
        answerPayloads.add(AnswerPayload(questionId: question.id, chosenIndex: -1, isCorrect: false));
        continue;
      }
      final bool isCorrect = chosenIndex == question.correctAnswerIndex;
      if (isCorrect) correctCount++;
      answerPayloads.add(AnswerPayload(questionId: question.id, chosenIndex: chosenIndex, isCorrect: isCorrect));
    }
    final double score = (questions.isNotEmpty ? (correctCount / questions.length) : 0) * 100;

    final attemptPayload = ReadingAttemptPayload(
      readingId: widget.reading.id,
      answers: answerPayloads,
      score: score,
      correctCount: correctCount,
      totalQuestions: questions.length,
      durationInSeconds: durationInSeconds,
    );

    context.read<ReadingAttemptBloc>().add(SubmitAttemptEvent(payload: attemptPayload));
  }

  bool _shouldBlockExit(AttemptStatus status) {
    if (widget.embedded || _isReviewMode || widget.examReviewMode) return false;
    if (status == AttemptStatus.success || status == AttemptStatus.review) return false;
    return _selectedAnswers.isNotEmpty || _remainingSeconds < _totalSeconds;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primary;

    return BlocConsumer<ReadingAttemptBloc, ReadingAttemptState>(
      listener: (context, state) {
        if (state.status == AttemptStatus.review) {
          if (state.attemptResult == null) return;
          final Map<String, int> oldAnswers = {};
          for (final answer in state.attemptResult!.answers) {
            oldAnswers[answer.questionId] = answer.chosenIndex;
          }
          setState(() {
            _selectedAnswers.addAll(oldAnswers);
            _isReviewMode = true;
            _timer?.cancel();
          });
        }

        if (state.status == AttemptStatus.success) {
          final result = state.attemptResult;
          if (widget.embedded && widget.onExamAnswersChanged != null) {
            return;
          }
          if (widget.embedded) {
            widget.onPartComplete?.call();
            AppFeedback.success(
              context,
              context.l10n.readingQuizResultSummary(
                result?.correctCount ?? 0,
                result?.totalQuestions ?? 0,
                (result?.score ?? 0).round(),
              ),
            );
          } else {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) {
                final d = ctx.l10n;
                return AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
                  title: Text(d.readingQuizResultTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                  content: Text(
                    d.readingQuizResultSummary(
                      result?.correctCount ?? 0,
                      result?.totalQuestions ?? 0,
                      (result?.score ?? 0).round(),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                  actions: [
                    TextButton(
                      child: Text(d.commonRetry, style: const TextStyle(color: AppColors.textSecondary)),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        context.read<ReadingAttemptBloc>().add(ResetAttemptEvent());
                        setState(() {
                          _selectedAnswers.clear();
                          _remainingSeconds = _totalSeconds;
                          _expandedFeedback.clear();
                          _isReviewMode = false;
                          _showReadingTranslation = false;
                        });
                        if (!widget.disableTimer) _startTimer();
                      },
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(d.commonOk),
                    ),
                  ],
                );
              },
            );
          }
        }
        else if (state.status == AttemptStatus.error) {
          AppFeedback.error(context, state.errorMessage ?? context.l10n.readingSubmissionFailed, blocking: true);
        }
      },
      builder: (context, state) {
        final bool isLoading = state.status == AttemptStatus.loading;
        final bool examPractice = widget.embedded && widget.onExamAnswersChanged != null;
        final bool isSubmitted = widget.examReviewMode
            ? true
            : examPractice
                ? false
                : state.status == AttemptStatus.review ||
                    state.status == AttemptStatus.success ||
                    _isReviewMode;

        final bool isSubmitting = isLoading && !_isReviewMode;
        final t = context.l10n;

        final tabBar = TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: primaryColor,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: t.readingTabArticle),
            Tab(text: t.readingTabQuestionsCount(widget.reading.questions.length)),
          ],
        );

        final body = Column(
          children: [
            if (widget.embedded)
              Material(color: Colors.white, child: tabBar)
            else if (!widget.disableTimer && !_isReviewMode && state.status != AttemptStatus.success)
              _buildTimerDisplay(context)
            else if (_isReviewMode || state.status == AttemptStatus.success)
              _buildReviewHeader(context, state),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReadingTab(context, isSubmitted),
                  _buildQuestionsTab(context, isSubmitted, isLoading && _isReviewMode),
                ],
              ),
            ),
            if (!examPractice &&
                _tabController.index == 1 &&
                widget.reading.questions.isNotEmpty &&
                !isSubmitted)
              _buildBottomActionBar(context, isSubmitting),
          ],
        );

        if (widget.embedded) {
          return body;
        }

        return StudentMobileUi.runnerPopScope(
          context: context,
          blockExit: _shouldBlockExit(state.status),
          child: Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            toolbarHeight: StudentMobileUi.appBarHeight,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              // maybePop đi qua PopScope guard (runnerPopScope) → bật dialog xác nhận
              // thoát khi đang làm bài, giống Listening/Speaking. pop() trực tiếp sẽ
              // force-pop, bỏ qua PopScope.
              onPressed: () => Navigator.maybePop(context),
            ),
            title: Text(
              widget.reading.title,
              style: StudentMobileUi.sectionTitle(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 2,
                    color: primaryColor.withValues(alpha: 0.55),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.outline)),
                    ),
                    child: tabBar,
                  ),
                ],
              ),
            ),
          ),
          body: body,
        ),
        );
      },
    );
  }

  Widget _buildTimerDisplay(BuildContext context) {
    final bool isTimeRunningOut = _remainingSeconds <= 30;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 18,
            color: isTimeRunningOut ? Colors.red : primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            '${_formatDuration(_remainingSeconds)} / ${_formatDuration(_totalSeconds)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: isTimeRunningOut ? Colors.red : AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewHeader(BuildContext context, ReadingAttemptState state) {
    final t = context.l10n;
    String textToShow = t.readingReviewMode;
    IconData icon = Icons.remove_red_eye_outlined;
    Color color = AppColors.textPrimary;
    Color bgColor = Colors.white;
    final score = state.attemptResult?.score ?? widget.reading.progress?.highScore;

    if (score != null) {
      textToShow = t.readingReviewingWithScore(score.round());
      icon = Icons.check_circle_outline;
      color = AppColors.success;
      bgColor = AppColors.successBg;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: const Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            textToShow,
            style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, bool isSubmitting) {
    final t = context.l10n;
    final answered = _selectedAnswers.length;
    final total = widget.reading.questions.length;
    return StudentMobileUi.bottomActionBar(
      context: context,
      progressLabel: '$answered/$total',
      ctaLabel: t.readingSubmitAnswers,
      onCta: () => _submitQuiz(context),
      loading: isSubmitting,
      ctaEnabled: !isSubmitting,
    );
  }

  Widget _buildReadingTab(BuildContext context, bool isSubmitted) {
    final t = context.l10n;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final translation = widget.reading.translation;

    return SingleChildScrollView(
      padding: StudentMobileUi.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSubmitted && translation != null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _showReadingTranslation = !_showReadingTranslation),
                icon: Icon(_showReadingTranslation ? Icons.visibility_off_outlined : Icons.translate, size: 18, color: primaryColor),
                label: Text(_showReadingTranslation ? t.readingHideTranslation : t.readingShowTranslation, style: TextStyle(color: primaryColor)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
                ),
              ),
            ),

          SelectableText(
            widget.reading.content,
            style: ExamEmbeddedSkillScope.compactOf(context)
                ? ExamSystemUi.embeddedBodyStyle.copyWith(
                    fontSize: 14,
                    height: 1.55,
                    color: AppColors.textSecondary,
                  )
                : const TextStyle(
                    fontSize: 17,
                    height: 1.6,
                    color: AppColors.textPrimary,
                    fontFamily: 'Serif',
                  ),
          ),

          if (isSubmitted && _showReadingTranslation && translation != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(color: AppColors.outline),
            ),
            Text(
              translation.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            SelectableText(
              translation.content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildQuestionsTab(BuildContext context, bool isSubmitted, bool isLoadingHistory) {
    if (isLoadingHistory) {
      return StudentMobileUi.runnerLoading();
    }
    final questions = widget.reading.questions;
    if (questions.isEmpty) {
      return Center(child: Text(context.l10n.readingNoQuestionsAvailable, style: const TextStyle(color: AppColors.textSecondary)));
    }

    if (isSubmitted || questions.length <= 1) {
      return ListView.separated(
        padding: StudentMobileUi.pagePadding,
        itemCount: questions.length,
        separatorBuilder: (_, __) => const SizedBox(height: StudentMobileUi.exerciseSectionGap),
        itemBuilder: (context, index) {
          return _buildQuestionCard(questions[index], index, isSubmitted);
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudentMobileUi.mcqPagerHeader(
          context,
          current: _questionPageIndex + 1,
          total: questions.length,
        ),
        Expanded(
          child: StudentMobileUi.mcqQuestionPager(
            context: context,
            controller: _questionPageController,
            itemCount: questions.length,
            onPageChanged: (index) {
              AppHaptics.select(context);
              setState(() => _questionPageIndex = index);
            },
            itemBuilder: (context, index) {
              return SingleChildScrollView(
                padding: StudentMobileUi.pagePadding,
                child: _buildQuestionCard(questions[index], index, isSubmitted),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(ReadingQuestionEntity question, int questionIndex, bool isSubmitted) {
    final compact = ExamEmbeddedSkillScope.compactOf(context);
    final bool isExpanded = _expandedFeedback.contains(question.id);
    final translation = question.translation;

    return AppCard(
      variant: AppCardVariant.outline,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: StudentMobileUi.exerciseCardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${questionIndex + 1}',
                  style: compact
                      ? ExamSystemUi.embeddedCaptionStyle.copyWith(fontWeight: FontWeight.w500)
                      : StudentMobileUi.caption(context),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  question.questionText,
                  style: compact
                      ? ExamSystemUi.embeddedListTitle(context).copyWith(height: 1.4)
                      : StudentMobileUi.cardTitle(context),
                ),
                if (isSubmitted && translation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.s3),
                    child: Text(
                      translation.questionText,
                      style: StudentMobileUi.body(context).copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Column(
              children: List.generate(question.options.length, (optionIndex) {
                final optionText = question.options[optionIndex];
                final isSelected = _selectedAnswers[question.id] == optionIndex;
                final isCorrect = optionIndex == question.correctAnswerIndex;
                String? sub;
                if (isSubmitted &&
                    translation != null &&
                    translation.options.length > optionIndex) {
                  sub = translation.options[optionIndex];
                }
                return StudentMobileUi.mcqOption(
                  context: context,
                  index: optionIndex,
                  text: optionText,
                  subtitle: sub,
                  selected: isSelected,
                  showReviewCorrect: isSubmitted && isCorrect,
                  showReviewWrong: isSubmitted && isSelected && !isCorrect,
                  onTap: isSubmitted
                      ? null
                      : () {
                          setState(() => _selectedAnswers[question.id] = optionIndex);
                          widget.onExamAnswersChanged?.call(
                            Map<String, int>.from(_selectedAnswers),
                            widget.reading.questions.length,
                          );
                        },
                );
              }),
            ),
          ),
          if (isSubmitted && question.feedback != null)
            InkWell(
              onTap: () => setState(() {
                if (isExpanded) {
                  _expandedFeedback.remove(question.id);
                } else {
                  _expandedFeedback.add(question.id);
                }
              }),
              child: AppCard(
                variant: AppCardVariant.filled,
                margin: const EdgeInsets.fromLTRB(AppSpacing.s5, 0, AppSpacing.s5, AppSpacing.s5),
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.accent),
                        const SizedBox(width: AppSpacing.s3),
                        Text(
                          context.l10n.readingFeedbackExplanation,
                          style: StudentMobileUi.cardTitle(context),
                        ),
                        const Spacer(),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                    if (isExpanded) ...[
                      const SizedBox(height: AppSpacing.s3),
                      _buildFeedbackBox(context, question.feedback!),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeedbackBox(BuildContext context, ReadingFeedbackEntity feedback) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(feedback.reasoning, style: StudentMobileUi.body(context)),
        if (feedback.paragraphIndex != null || feedback.keySentence != null) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s3),
            child: Divider(height: 1, color: AppColors.outline),
          ),
          if (feedback.paragraphIndex != null)
            Text(
              context.l10n.readingFeedbackLocationParagraph(feedback.paragraphIndex! + 1),
              style: StudentMobileUi.caption(context).copyWith(fontStyle: FontStyle.italic),
            ),
          if (feedback.keySentence != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s2),
              child: Text(
                context.l10n.readingFeedbackKeySentence(feedback.keySentence!),
                style: StudentMobileUi.caption(context).copyWith(fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ],
    );
  }
}