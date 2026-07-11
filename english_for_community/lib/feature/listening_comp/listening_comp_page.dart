import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:translator/translator.dart';

import '../../../../core/api/api_config.dart';
import '../../../../core/locale/l10n_context.dart';
import '../../../../core/util/app_haptics.dart';
import '../../../../core/ui/feedback/app_feedback.dart';
import '../../../../core/entity/listening_comp_entity.dart';
import '../../../../core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/ui/motion/confetti_celebration.dart';
import '../../../../core/ui/widget/app_card.dart';
import '../../core/get_it/get_it.dart';
import '../listening/widget/listening_common_widgets.dart';

// Import các file Event/State đã tách
import 'bloc/listening_comp_bloc.dart';
import 'bloc/listening_comp_event.dart';
import 'bloc/listening_comp_state.dart';

// =============================================================================
// 1. WIDGET CHA
// =============================================================================
class ListeningCompPage extends StatelessWidget {
  final String id;
  // 🔥 KHAI BÁO THÊM BIẾN NÀY ĐỂ NHẬN TỪ ROUTER
  final bool isRetake;

  // Cập nhật Constructor
  const ListeningCompPage({
    super.key,
    required this.id,
    this.isRetake = false,
  });

  @override
  Widget build(BuildContext context) {
    // 🔥 Xóa đoạn dùng GoRouterState.of(context).extra đi

    return BlocProvider(
      create: (context) =>
      // 🔥 TRUYỀN THẲNG VÀO ĐÂY
      getIt<ListeningCompBloc>()..add(FetchListeningCompDetail(id, isRetake: isRetake)),
      child: _ListeningCompView(compId: id, isRetake: isRetake),
    );
  }
}
// =============================================================================
// 2. WIDGET CON
// =============================================================================
class _ListeningCompView extends StatefulWidget {
  const _ListeningCompView({required this.compId, required this.isRetake});

  final String compId;
  final bool isRetake;

  @override
  State<_ListeningCompView> createState() => _ListeningCompViewState();
}

class _ListeningCompViewState extends State<_ListeningCompView>
    with SingleTickerProviderStateMixin {
  late final ja.AudioPlayer _player;
  late final TabController _tabController;

  final ScrollController _questionsScrollController = ScrollController();
  late final PageController _questionPageController;
  int _questionPageIndex = 0;
  final Map<String, int> _selectedAnswers = {};

  Timer? _timer;
  late final ValueNotifier<int> _remainingSecondsNotifier;
  int _totalSeconds = 0;

  bool _isReviewMode = false;
  final Set<String> _expandedFeedback = {};
  bool _audioInitialized = false;

  // -------------------------------------------------------------------------
  // Biến trạng thái cho phần Dịch Toàn Cục (Global Translation)
  // -------------------------------------------------------------------------
  bool _showTranslation = false;
  bool _isTranslatingAll = false;

  // Lưu trữ kết quả dịch cho từng thành phần
  String? _translatedTranscript;
  final Map<String, String> _translatedQuestions = {};
  final Map<String, List<String>> _translatedOptions = {};
  final Map<String, String> _translatedFeedback = {};

  final GoogleTranslator _translator = GoogleTranslator();

  @override
  void initState() {
    super.initState();
    _player = ja.AudioPlayer();
    _tabController = TabController(length: 2, vsync: this);
    _questionPageController = PageController();
    _remainingSecondsNotifier = ValueNotifier<int>(0);

    _tabController.addListener(() {
      setState(() {});
    });
  }

  // -------------------------------------------------------------------------
  // Hàm Dịch Toàn Bộ (Câu hỏi, Đáp án, Giải thích, Transcript)
  // -------------------------------------------------------------------------
  Future<void> _translateAllContent(ListeningCompEntity entity) async {
    // Nếu đã dịch rồi thì không gọi lại API nữa
    if (_translatedTranscript != null) return;

    setState(() {
      _isTranslatingAll = true;
    });

    try {
      final futures = <Future>[];

      // 1. Dịch Transcript
      futures.add(_translator.translate(entity.transcript, from: 'en', to: 'vi').then((res) {
        _translatedTranscript = res.text;
      }));

      // 2. Dịch toàn bộ Câu hỏi, Đáp án và Lời giải thích
      for (var q in entity.questions) {
        // Dịch câu hỏi chính
        futures.add(_translator.translate(q.questionText, from: 'en', to: 'vi').then((res) {
          _translatedQuestions[q.id] = res.text;
        }));

        // Khởi tạo mảng lưu đáp án dịch
        _translatedOptions[q.id] = List.filled(q.options.length, '');
        for (int i = 0; i < q.options.length; i++) {
          futures.add(_translator.translate(q.options[i], from: 'en', to: 'vi').then((res) {
            _translatedOptions[q.id]![i] = res.text;
          }));
        }

        // Dịch lời giải thích (nếu có)
        if (q.feedback != null) {
          futures.add(_translator.translate(q.feedback!.reasoning, from: 'en', to: 'vi').then((res) {
            _translatedFeedback[q.id] = res.text;
          }));
        }
      }

      // Chờ tất cả tiến trình dịch chạy xong cùng lúc
      await Future.wait(futures);

    } catch (e) {
      debugPrint("Translation Error: $e");
      // Bạn có thể xử lý hiển thị lỗi (SnackBar) ở đây nếu cần
    } finally {
      if (mounted) {
        setState(() {
          _isTranslatingAll = false;
        });
      }
    }
  }

  // -------------------------------------------------------------------------
  // AUDIO & TIMER & SUBMIT
  // -------------------------------------------------------------------------
  Future<void> _initAudio(String url) async {
    final fullUrl =
    url.startsWith('http') ? url : '${ApiConfig.Base_URL}/$url';
    try {
      await _player.stop();
      await _player.setUrl(fullUrl);
      _audioInitialized = true;
    } catch (e) {
      debugPrint('Error loading audio: $e');
    }
  }

  void _startTimer(int minutes) {
    if (_timer != null) return;
    _totalSeconds = minutes * 60;
    _remainingSecondsNotifier.value = _totalSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSecondsNotifier.value > 0) {
        _remainingSecondsNotifier.value--;
      } else {
        timer.cancel();
        if (mounted) {
          final currentState = context.read<ListeningCompBloc>().state;
          if (currentState.status == CompStatus.success) {
            AppFeedback.error(context, context.l10n.quizTimeUpSubmitting);
            _submitQuiz(context);
          }
        }
      }
    });
  }

  void _submitQuiz(BuildContext context) {
    _timer?.cancel();
    final state = context.read<ListeningCompBloc>().state;
    if (state.data == null) return;

    final durationInSeconds = _totalSeconds - _remainingSecondsNotifier.value;
    final answersPayload = state.data!.questions.map((q) {
      return {'questionId': q.id, 'chosenIndex': _selectedAnswers[q.id] ?? -1};
    }).toList();

    context.read<ListeningCompBloc>().add(
      SubmitListeningCompAttempt(
        listeningId: state.data!.id,
        answers: answersPayload,
        durationInSeconds: durationInSeconds,
      ),
    );
  }

  Future<void> _seekAndPlay(int timestampSeconds) async {
    await _player.seek(Duration(seconds: timestampSeconds));
    _player.play();

    if (_questionsScrollController.hasClients) {
      _questionsScrollController.animateTo(
        0,
        duration: AppMotion.base,
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _tabController.dispose();
    _questionPageController.dispose();
    _questionsScrollController.dispose();
    _timer?.cancel();
    _remainingSecondsNotifier.dispose();
    super.dispose();
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  bool _shouldBlockExit() =>
      !_isReviewMode && (_selectedAnswers.isNotEmpty || _remainingSecondsNotifier.value < _totalSeconds);

  void _reloadComp() {
    context.read<ListeningCompBloc>().add(
          FetchListeningCompDetail(widget.compId, isRetake: widget.isRetake),
        );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primary;

    return BlocConsumer<ListeningCompBloc, ListeningCompState>(
      listener: (context, state) {
        if (state.status == CompStatus.loading || state.status == CompStatus.initial) {
          setState(() {
            _isReviewMode = false;
            _selectedAnswers.clear();
          });
        }
        if (state.status == CompStatus.success &&
            !_audioInitialized &&
            state.data != null) {
          _initAudio(state.data!.audioUrl);
          if (!_isReviewMode) _startTimer(state.data!.minutesToComplete);
        }

        if (state.status == CompStatus.submitted &&
            state.attemptResult != null) {
          final result = state.attemptResult!;
          _timer?.cancel();

          setState(() {
            _isReviewMode = true;
            _selectedAnswers.clear(); // Dọn sạch rác cũ

            for (var ans in result.answers) {
              // 🔥 FIX CHUẨN XÁC: ans chắc chắn là Map nên chỉ dùng ngoặc vuông
              final String qId = ans['questionId']?.toString() ?? '';
              final int cIdx = ans['chosenIndex'] ?? -1;

              if (qId.isNotEmpty) {
                _selectedAnswers[qId] = cIdx;
              }
            }
          });

          if (state.data != null) {
            _audioInitialized = false;
            _initAudio(state.data!.audioUrl);
          }

          if (!state.isInitialLoadReview) {
            CompletionCelebration.fireForScore(
              context,
              score: result.correctCount.toDouble(),
              maxScore: result.totalQuestions.toDouble(),
            );
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) {
                final d = ctx.l10n;
                return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card)),
                title: Text(d.readingQuizResultTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                content: Text(
                  d.readingQuizResultSummary(
                    result.correctCount,
                    result.totalQuestions,
                    result.score.round(),
                  ),
                  style: const TextStyle(fontSize: AppTypography.mobileH1),
                ),
                actions: [
                  TextButton(
                    child: Text(d.listeningCompReview),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      context.pop();
                    },
                    child: Text(d.commonDone),
                  ),
                ],
              );
              },
            );
          }
        }

        if (state.status == CompStatus.error) {
          AppFeedback.error(context, state.errorMessage ?? context.l10n.commonError, blocking: true);
        }
      },
      builder: (context, state) {
        final bool isLoading = state.status == CompStatus.loading ||
            state.status == CompStatus.initial;
        final bool isSubmitting = state.status == CompStatus.submitting;

        if (isLoading) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            body: StudentMobileUi.runnerLoading(),
          );
        }

        if (state.data == null) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            body: StudentMobileUi.errorRetry(
              context,
              title: context.l10n.listeningCompTitle,
              message: context.l10n.listeningCompLoadError,
              onRetry: _reloadComp,
              retryLabel: context.l10n.commonRetry,
            ),
          );
        }

        final entity = state.data!;
        final t = context.l10n;

        return StudentMobileUi.runnerPopScope(
          context: context,
          blockExit: _shouldBlockExit(),
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
              onPressed: () => context.pop(),
            ),
            title: Text(t.listeningCompTitle, style: StudentMobileUi.sectionTitle(context)),
          ),
          body: Column(
            children: [
              // --------------------------------------------------------------
              // Header: Timer / Review Header (Có nút Dịch Toàn Bộ)
              // --------------------------------------------------------------
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: AppColors.outline)),
                ),
                child: Column(
                  children: [
                    if (!_isReviewMode)
                      _buildTimerDisplay(context)
                    else
                      _buildReviewHeader(context, state, entity), // Truyền entity vào để dịch

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          _buildSeekButton(
                            icon: Icons.replay_5,
                            onTap: () async {
                              final current = _player.position;
                              final target = current - const Duration(seconds: 5);
                              await _player.seek(
                                target < Duration.zero ? Duration.zero : target,
                              );
                            },
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ListeningPlayer(
                              player: _player,
                              onTogglePlay: () {
                                if (_player.playing) {
                                  _player.pause();
                                } else {
                                  _player.play();
                                }
                              },
                              onSeek: (position) => _player.seek(position),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildSeekButton(
                            icon: Icons.forward_5,
                            onTap: () async {
                              final current = _player.position;
                              final duration = _player.duration ?? Duration.zero;
                              final target = current + const Duration(seconds: 5);
                              await _player.seek(
                                target > duration ? duration : target,
                              );
                            },
                            primaryColor: primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --------------------------------------------------------------
              // TabBar
              // --------------------------------------------------------------
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: primaryColor,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: primaryColor,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  tabs: [
                    Tab(text: t.readingTabQuestionsCount(entity.questions.length)),
                    Tab(text: t.listeningCompTabTranscript),
                  ],
                ),
              ),

              // --------------------------------------------------------------
              // TabBarView
              // --------------------------------------------------------------
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildQuestionsTab(entity, _isReviewMode, primaryColor),
                    _buildTranscriptTab(entity, _isReviewMode, primaryColor),
                  ],
                ),
              ),

              // --------------------------------------------------------------
              // Bottom bar (Chỉ hiện khi chưa nộp bài)
              // --------------------------------------------------------------
              if (_tabController.index == 0 && !_isReviewMode)
                _buildBottomActionBar(context, isSubmitting),
            ],
          ),
        ),
        );
      },
    );
  }

  // =========================================================================
  // HELPER WIDGETS
  // =========================================================================
  Widget _buildSeekButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    return Material(
      color: primaryColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 24, color: primaryColor),
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildTimerDisplay(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ValueListenableBuilder<int>(
        valueListenable: _remainingSecondsNotifier,
        builder: (context, remainingSeconds, child) {
          final bool isTimeRunningOut = remainingSeconds <= 60;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 18,
                color: isTimeRunningOut ? Colors.red : primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                '${_formatDuration(remainingSeconds)} / ${_formatDuration(_totalSeconds)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: AppTypography.mobileKpi,
                  color: isTimeRunningOut ? Colors.red : AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Cập nhật: Thêm nút Bật/Tắt Dịch Toàn Cục vào Header Review
  Widget _buildReviewHeader(BuildContext context, ListeningCompState state, ListeningCompEntity entity) {
    final t = context.l10n;
    final score = state.attemptResult?.score ?? 0;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(color: AppColors.successBg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              Text(
                t.readingReviewingWithScore(score.round()),
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                    fontSize: AppTypography.mobileH2),
              ),
            ],
          ),
          // Khu vực Toggle Dịch
          Row(
            children: [
              if (_isTranslatingAll)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: AppLoadingIndicator(strokeWidth: 2, color: AppColors.success),
                  ),
                ),
              Text(
                t.listeningCompTranslateToggle,
                style: TextStyle(fontSize: AppTypography.mobileBody, fontWeight: FontWeight.w600, color: primaryColor),
              ),
              const SizedBox(width: 4),
              Switch.adaptive(
                value: _showTranslation,
                activeThumbColor: primaryColor,
                onChanged: (value) {
                  setState(() => _showTranslation = value);
                  if (value) {
                    _translateAllContent(entity); // Gọi dịch toàn bộ khi bật
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, bool isSubmitting) {
    final t = context.l10n;
    final answered = _selectedAnswers.length;
    final total = context.read<ListeningCompBloc>().state.data?.questions.length ?? 0;
    return StudentMobileUi.bottomActionBar(
      context: context,
      progressLabel: '$answered/$total',
      progress: total > 0 ? answered / total : 0,
      skill: SkillType.listening,
      ctaLabel: t.readingSubmitAnswers,
      onCta: () => _submitQuiz(context),
      loading: isSubmitting,
      ctaEnabled: !isSubmitting,
    );
  }

  // =========================================================================
  // TAB CÂU HỎI (Áp dụng bản dịch song song)
  // =========================================================================
  Widget _buildQuestionsTab(
      ListeningCompEntity entity, bool isSubmitted, Color primaryColor) {
    Widget questionAt(int index) {
      final q = entity.questions[index];
      final isExpanded = _expandedFeedback.contains(q.id);
      final t = context.l10n;

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
                    t.listeningCompQuestionNumber(index + 1),
                    style: StudentMobileUi.caption(context),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(q.questionText, style: StudentMobileUi.cardTitle(context)),
                  if (_showTranslation && _translatedQuestions.containsKey(q.id)) ...[
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      _translatedQuestions[q.id]!,
                      style: StudentMobileUi.body(context).copyWith(color: AppColors.success),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                children: List.generate(q.options.length, (optIdx) {
                  final isSelected = _selectedAnswers[q.id.toString()] == optIdx;
                  final isCorrect = optIdx == q.correctAnswerIndex;
                  String? sub;
                  if (_showTranslation && _translatedOptions.containsKey(q.id)) {
                    sub = _translatedOptions[q.id]![optIdx];
                  }
                  return StudentMobileUi.mcqOption(
                    context: context,
                    index: optIdx,
                    text: q.options[optIdx],
                    subtitle: sub,
                    skill: SkillType.listening,
                    selected: !isSubmitted && isSelected,
                    showReviewCorrect: isSubmitted && isCorrect,
                    showReviewWrong: isSubmitted && isSelected && !isCorrect,
                    onTap: isSubmitted
                        ? null
                        : () => setState(() => _selectedAnswers[q.id] = optIdx),
                  );
                }),
              ),
            ),
            if (isSubmitted && q.feedback != null)
              InkWell(
                onTap: () => setState(() => isExpanded
                    ? _expandedFeedback.remove(q.id)
                    : _expandedFeedback.add(q.id)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.card)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.accent),
                          const SizedBox(width: 6),
                          Text(
                            t.readingFeedbackExplanation,
                            style: TextStyle(
                                fontSize: AppTypography.mobileBody, fontWeight: FontWeight.w600, color: primaryColor),
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
                        const SizedBox(height: 8),
                        Text(
                          q.feedback!.reasoning,
                          style: const TextStyle(fontSize: AppTypography.mobileH2, color: AppColors.textSecondary, height: 1.5),
                        ),
                        if (_showTranslation && _translatedFeedback.containsKey(q.id)) ...[
                          const SizedBox(height: 4),
                          Text(
                            _translatedFeedback[q.id]!,
                            style: const TextStyle(
                                fontSize: AppTypography.mobileH2, color: AppColors.successDark, height: 1.5),
                          ),
                        ],
                        if (q.feedback!.hintTimestampSeconds != null) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(height: 1, color: AppColors.outline),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.play_circle_fill, size: 18, color: Colors.white),
                            label: Text(
                              t.listeningCompHintSeekSeconds(q.feedback!.hintTimestampSeconds!),
                            ),
                            backgroundColor: primaryColor.withValues(alpha: 0.8),
                            labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            onPressed: () => _seekAndPlay(q.feedback!.hintTimestampSeconds!),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (!isSubmitted && entity.questions.length > 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudentMobileUi.mcqPagerHeader(
            context,
            current: _questionPageIndex + 1,
            total: entity.questions.length,
          ),
          Expanded(
            child: StudentMobileUi.mcqQuestionPager(
              context: context,
              controller: _questionPageController,
              itemCount: entity.questions.length,
              onPageChanged: (index) {
                AppHaptics.select(context);
                setState(() => _questionPageIndex = index);
              },
              itemBuilder: (context, index) {
                return SingleChildScrollView(
                  padding: StudentMobileUi.pagePadding,
                  child: questionAt(index),
                );
              },
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _questionsScrollController,
      padding: StudentMobileUi.pagePadding,
      itemCount: entity.questions.length,
      separatorBuilder: (_, __) => const SizedBox(height: StudentMobileUi.exerciseSectionGap),
      itemBuilder: (context, index) => questionAt(index),
    );
  }

  // =========================================================================
  // TAB TRANSCRIPT (Áp dụng bản dịch từ Global State)
  // =========================================================================
  Widget _buildTranscriptTab(
      ListeningCompEntity entity, bool isSubmitted, Color primaryColor) {
    final t = context.l10n;
    if (!isSubmitted) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, color: AppColors.outline, size: 48),
              const SizedBox(height: 16),
              Text(
                t.listeningCompTranscriptLocked,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: AppTypography.mobileH1,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                t.listeningCompTranscriptLockedHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: AppTypography.mobileH2, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Bản Gốc
          Text(
            t.listeningCompTranscriptOriginal,
            style: const TextStyle(
              fontSize: AppTypography.mobileH2,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            entity.transcript,
            style: const TextStyle(
              fontSize: AppTypography.mobileH1,
              height: 1.6,
              color: AppColors.textPrimary,
              fontFamily: 'Serif',
            ),
          ),

          // 2. Bản Dịch (Hiện nếu _showTranslation = true)
          if (_showTranslation) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Divider(color: AppColors.outline, thickness: 1.5),
            ),
            Text(
              t.listeningCompTranscriptTranslation,
              style: const TextStyle(
                fontSize: AppTypography.mobileH2,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Hiện Text khi API trả về thành công/thất bại
            if (_translatedTranscript != null)
              SelectableText(
                _translatedTranscript!,
                style: const TextStyle(
                  fontSize: AppTypography.mobileH1,
                  height: 1.6,
                  color: AppColors.successDark, // Màu xanh phân biệt
                  fontFamily: 'Serif',
                ),
              ),
          ],
        ],
      ),
    );
  }
}