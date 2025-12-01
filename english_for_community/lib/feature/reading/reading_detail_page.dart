import 'dart:async';
import 'dart:ui'; // Để dùng FontFeature

import 'package:flutter/material.dart';
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
import '../../core/repository/reading_repository.dart';

// =============================================================================
// 1. WIDGET CHA: Chỉ tạo BlocProvider
// =============================================================================
class ReadingDetailPage extends StatelessWidget {
  final ReadingEntity reading;
  const ReadingDetailPage({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = ReadingAttemptBloc(
          readingRepository: getIt<ReadingRepository>(),
        );
        // Kiểm tra xem bài này đã hoàn thành chưa để load lại lịch sử
        if (reading.progress?.status == ProgressStatus.completed) {
          bloc.add(FetchLastAttemptEvent(readingId: reading.id));
        }
        return bloc;
      },
      // Truyền xuống View con, lúc này View con sẽ nằm TRONG BlocProvider
      child: _ReadingDetailView(reading: reading),
    );
  }
}

// =============================================================================
// 2. WIDGET CON: Xử lý UI và Timer
// =============================================================================
class _ReadingDetailView extends StatefulWidget {
  final ReadingEntity reading;
  const _ReadingDetailView({required this.reading});

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Lấy thông tin từ widget.reading
    _totalSeconds = widget.reading.minutesToRead * 60;
    _remainingSeconds = _totalSeconds;
    _isReviewMode = widget.reading.progress?.status == ProgressStatus.completed;

    // Chỉ chạy timer nếu chưa làm xong
    if (!_isReviewMode) {
      _startTimer();
    }
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
        // Kiểm tra mounted để đảm bảo widget còn tồn tại
        if (mounted) {
          // 🔥 LÚC NÀY GỌI CONTEXT SẼ KHÔNG BỊ LỖI NỮA
          final currentState = context.read<ReadingAttemptBloc>().state;

          // Chỉ nộp nếu chưa nộp (status vẫn là initial hoặc đang làm)
          if (currentState.status == AttemptStatus.initial || currentState.status == AttemptStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Time's up! Submitting your answers..."),
                backgroundColor: Colors.orange,
              ),
            );
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
    _tabController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _submitQuiz(BuildContext context) {
    _timer?.cancel();
    final questions = widget.reading.questions;
    final List<AnswerPayload> answerPayloads = [];
    int correctCount = 0;

    // Tính thời gian làm bài thực tế
    final int durationInSeconds = _totalSeconds - _remainingSeconds;

    for (final question in questions) {
      final chosenIndex = _selectedAnswers[question.id];
      if (chosenIndex == null) {
        // Chưa chọn đáp án
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

  @override
  Widget build(BuildContext context) {
    const bgPage = Color(0xFFF9FAFB);
    const textMain = Color(0xFF09090B);
    const borderCol = Color(0xFFE4E4E7);
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Sử dụng BlocConsumer để lắng nghe và xây dựng giao diện
    return BlocConsumer<ReadingAttemptBloc, ReadingAttemptState>(
      listener: (context, state) {
        // 1. Chế độ xem lại (Lịch sử)
        if (state.status == AttemptStatus.review) {
          if (state.attemptResult == null) return;
          final Map<String, int> oldAnswers = {};
          for (final answer in state.attemptResult!.answers) {
            oldAnswers[answer.questionId] = answer.chosenIndex;
          }
          setState(() {
            _selectedAnswers.addAll(oldAnswers);
            _isReviewMode = true; // Đảm bảo UI chuyển sang chế độ review
            _timer?.cancel(); // Dừng timer nếu lỡ chạy
          });
        }

        // 2. Nộp bài thành công
        if (state.status == AttemptStatus.success) {
          final result = state.attemptResult;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text('Result', style: TextStyle(fontWeight: FontWeight.w700)),
              content: Text(
                  'Correct: ${result?.correctCount ?? 0} / ${result?.totalQuestions ?? 0}\nScore: ${result?.score.toStringAsFixed(0) ?? 0}%',
                  style: const TextStyle(fontSize: 16)
              ),
              actions: [
                TextButton(
                  child: const Text('Retry', style: TextStyle(color: Color(0xFF71717A))),
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
                    _startTimer();
                  },
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        // 3. Lỗi
        else if (state.status == AttemptStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Submission failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final bool isLoading = state.status == AttemptStatus.loading;
        final bool isSubmitted =
            state.status == AttemptStatus.review ||
                state.status == AttemptStatus.success ||
                _isReviewMode;

        final bool isSubmitting = isLoading && !_isReviewMode;

        return Scaffold(
          backgroundColor: bgPage,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: textMain),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(widget.reading.title, style: const TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 16)),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderCol, width: 1)),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: primaryColor,
                  unselectedLabelColor: const Color(0xFF71717A),
                  indicatorColor: primaryColor,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  tabs: [
                    const Tab(text: 'Article'),
                    Tab(text: 'Questions (${widget.reading.questions.length})'),
                  ],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              // Header: Timer hoặc Review Info
              if (!_isReviewMode && state.status != AttemptStatus.success)
                _buildTimerDisplay(context)
              else
                _buildReviewHeader(context, state),

              // Content: Tabs
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildReadingTab(context, isSubmitted),
                    _buildQuestionsTab(context, isSubmitted, isLoading && _isReviewMode),
                  ],
                ),
              ),

              // Bottom Bar: Nút nộp bài (Chỉ hiện khi chưa nộp và đang ở tab câu hỏi)
              if (_tabController.index == 1 && widget.reading.questions.isNotEmpty && !isSubmitted)
                _buildBottomActionBar(context, isSubmitting),
            ],
          ),
        );
      },
    );
  }

  // --- CÁC WIDGET PHỤ TRỢ (Copy nguyên từ code cũ của bạn) ---

  Widget _buildTimerDisplay(BuildContext context) {
    final bool isTimeRunningOut = _remainingSeconds <= 30;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E4E7))),
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
              color: isTimeRunningOut ? Colors.red : const Color(0xFF09090B),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewHeader(BuildContext context, ReadingAttemptState state) {
    String textToShow = 'Review Mode';
    IconData icon = Icons.remove_red_eye_outlined;
    Color color = const Color(0xFF09090B);
    Color bgColor = Colors.white;
    final score = state.attemptResult?.score ?? widget.reading.progress?.highScore;

    if (score != null) {
      textToShow = 'Reviewing (Score: ${score.toStringAsFixed(0)}%)';
      icon = Icons.check_circle_outline;
      color = const Color(0xFF15803D);
      bgColor = const Color(0xFFF0FDF4);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: const Border(bottom: BorderSide(color: Color(0xFFE4E4E7))),
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E4E7))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isSubmitting ? null : () => _submitQuiz(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            child: isSubmitting
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Submit Answers'),
          ),
        ),
      ),
    );
  }

  Widget _buildReadingTab(BuildContext context, bool isSubmitted) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final translation = widget.reading.translation;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
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
                label: Text(_showReadingTranslation ? 'Hide Translation' : 'Show Translation', style: TextStyle(color: primaryColor)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryColor.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),

          SelectableText(
            widget.reading.content,
            style: const TextStyle(
              fontSize: 17,
              height: 1.6,
              color: Color(0xFF09090B),
              fontFamily: 'Serif',
            ),
          ),

          if (isSubmitted && _showReadingTranslation && translation != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(color: Color(0xFFE4E4E7)),
            ),
            Text(
              translation.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF09090B)),
            ),
            const SizedBox(height: 12),
            SelectableText(
              translation.content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Color(0xFF52525B),
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
      return const Center(child: CircularProgressIndicator());
    }
    final questions = widget.reading.questions;
    if (questions.isEmpty) {
      return const Center(child: Text('No questions available.', style: TextStyle(color: Color(0xFF71717A))));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20.0),
      itemCount: questions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        return _buildQuestionCard(questions[index], index, isSubmitted);
      },
    );
  }

  Widget _buildQuestionCard(ReadingQuestionEntity question, int questionIndex, bool isSubmitted) {
    final theme = Theme.of(context);
    final bool isExpanded = _expandedFeedback.contains(question.id);
    final translation = question.translation;
    final primaryColor = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${questionIndex + 1}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF71717A), letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  question.questionText,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF09090B), height: 1.4),
                ),
                if (isSubmitted && translation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      translation.questionText,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF71717A), fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF4F4F5)),
          Column(
            children: List.generate(question.options.length, (optionIndex) {
              final optionText = question.options[optionIndex];
              final isSelected = _selectedAnswers[question.id] == optionIndex;

              Color bgColor = Colors.transparent;
              // Color borderColor = Colors.transparent; // Không dùng biến này nếu không cần thiết
              Color textColor = const Color(0xFF09090B);
              IconData? icon;
              Color iconColor = Colors.transparent;

              if (isSubmitted) {
                final bool isCorrectAnswer = optionIndex == question.correctAnswerIndex;
                if (isCorrectAnswer) {
                  bgColor = const Color(0xFFECFDF5);
                  // borderColor = const Color(0xFF86EFAC);
                  textColor = const Color(0xFF14532D);
                  icon = Icons.check_circle;
                  iconColor = const Color(0xFF16A34A);
                } else if (isSelected) {
                  bgColor = const Color(0xFFFEF2F2);
                  // borderColor = const Color(0xFFFECACA);
                  textColor = const Color(0xFF7F1D1D);
                  icon = Icons.cancel;
                  iconColor = const Color(0xFFDC2626);
                }
              } else {
                if (isSelected) {
                  bgColor = primaryColor.withOpacity(0.05);
                  // borderColor = primaryColor;
                }
              }

              return InkWell(
                onTap: isSubmitted ? null : () {
                  setState(() {
                    _selectedAnswers[question.id] = optionIndex;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border(
                      left: BorderSide(
                          color: isSelected || (isSubmitted && optionIndex == question.correctAnswerIndex) ? (isSubmitted && optionIndex == question.correctAnswerIndex ? const Color(0xFF16A34A) : (isSelected && isSubmitted ? const Color(0xFFDC2626) : primaryColor)) : Colors.transparent,
                          width: 4
                      ),
                      bottom: const BorderSide(color: Color(0xFFF4F4F5)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(optionText, style: TextStyle(fontSize: 15, color: textColor, height: 1.4)),
                            if (isSubmitted && translation != null && translation.options.length > optionIndex)
                              Text(translation.options[optionIndex], style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.7), fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                      if (icon != null) Icon(icon, color: iconColor, size: 20),
                      if (!isSubmitted)
                        Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? primaryColor : const Color(0xFFA1A1AA), width: 2),
                            color: isSelected ? primaryColor : Colors.transparent,
                          ),
                          child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                        )
                    ],
                  ),
                ),
              );
            }),
          ),

          if (isSubmitted && question.feedback != null)
            InkWell(
              onTap: () => setState(() {
                if (isExpanded) _expandedFeedback.remove(question.id);
                else _expandedFeedback.add(question.id);
              }),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 6),
                        Text('Explanation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.primaryColor)),
                        const Spacer(),
                        Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 18, color: const Color(0xFFA1A1AA)),
                      ],
                    ),
                    if (isExpanded) ...[
                      const SizedBox(height: 8),
                      _buildFeedbackBox(context, question.feedback!),
                    ]
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
        Text(
          feedback.reasoning,
          style: const TextStyle(fontSize: 14, color: Color(0xFF52525B), height: 1.5),
        ),
        if (feedback.paragraphIndex != null || feedback.keySentence != null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1, color: Color(0xFFE4E4E7)),
          ),
        if (feedback.paragraphIndex != null)
          Text('• Location: Paragraph ${feedback.paragraphIndex! + 1}', style: const TextStyle(fontSize: 13, color: Color(0xFF71717A), fontStyle: FontStyle.italic)),
        if (feedback.keySentence != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text('• Key sentence: "${feedback.keySentence}"', style: const TextStyle(fontSize: 13, color: Color(0xFF71717A), fontStyle: FontStyle.italic)),
          ),
      ],
    );
  }
}