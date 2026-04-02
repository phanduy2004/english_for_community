import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:translator/translator.dart';

import '../../../../core/api/api_config.dart';
import '../../../../core/entity/listening_comp_entity.dart';
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
  const ListeningCompPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
      getIt<ListeningCompBloc>()..add(FetchListeningCompDetail(id)),
      child: const _ListeningCompView(),
    );
  }
}

// =============================================================================
// 2. WIDGET CON
// =============================================================================
class _ListeningCompView extends StatefulWidget {
  const _ListeningCompView();

  @override
  State<_ListeningCompView> createState() => _ListeningCompViewState();
}

class _ListeningCompViewState extends State<_ListeningCompView>
    with SingleTickerProviderStateMixin {
  late final ja.AudioPlayer _player;
  late final TabController _tabController;

  final ScrollController _questionsScrollController = ScrollController();
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _tabController.dispose();
    _questionsScrollController.dispose();
    _timer?.cancel();
    _remainingSecondsNotifier.dispose();
    super.dispose();
  }

  // =========================================================================
  // BUILD
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    const bgPage = Color(0xFFF9FAFB);
    const textMain = Color(0xFF09090B);
    const borderCol = Color(0xFFE4E4E7);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return BlocConsumer<ListeningCompBloc, ListeningCompState>(
      listener: (context, state) {
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
            for (var ans in result.answers) {
              _selectedAnswers[ans['questionId']] = ans['chosenIndex'];
            }
          });

          if (state.data != null) {
            _audioInitialized = false;
            _initAudio(state.data!.audioUrl);
          }

          if (!state.isInitialLoadReview) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                title: const Text('Result',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                content: Text(
                  'Correct: ${result.correctCount} / ${result.totalQuestions}\n'
                      'Score: ${result.score.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 16),
                ),
                actions: [
                  TextButton(
                    child: const Text('Review'),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      context.pop();
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            );
          }
        }

        if (state.status == CompStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final bool isLoading = state.status == CompStatus.loading ||
            state.status == CompStatus.initial;
        final bool isSubmitting = state.status == CompStatus.submitting;

        if (isLoading) {
          return const Scaffold(
            backgroundColor: bgPage,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.data == null) {
          return const Scaffold(
            backgroundColor: bgPage,
            body: Center(child: Text('Error loading lesson')),
          );
        }

        final entity = state.data!;

        return Scaffold(
          backgroundColor: bgPage,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: textMain),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Comprehension',
              style: TextStyle(
                  color: textMain,
                  fontWeight: FontWeight.w600,
                  fontSize: 16),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // --------------------------------------------------------------
              // Header: Timer / Review Header (Có nút Dịch Toàn Bộ)
              // --------------------------------------------------------------
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: borderCol)),
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
                  unselectedLabelColor: const Color(0xFF71717A),
                  indicatorColor: primaryColor,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  tabs: [
                    Tab(text: 'Questions (${entity.questions.length})'),
                    const Tab(text: 'Transcript'),
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
      color: primaryColor.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
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
                  fontSize: 15,
                  color: isTimeRunningOut ? Colors.red : const Color(0xFF09090B),
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
    final score = state.attemptResult?.score ?? 0;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(color: Color(0xFFF0FDF4)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFF15803D), size: 18),
              const SizedBox(width: 8),
              Text(
                'Reviewing (Score: ${score.toStringAsFixed(0)}%)',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF15803D),
                    fontSize: 14),
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF15803D)),
                  ),
                ),
              Text(
                'Dịch',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primaryColor),
              ),
              const SizedBox(width: 4),
              Switch.adaptive(
                value: _showTranslation,
                activeColor: primaryColor,
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            child: isSubmitting
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
                : const Text('Submit Answers'),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB CÂU HỎI (Áp dụng bản dịch song song)
  // =========================================================================
  Widget _buildQuestionsTab(
      ListeningCompEntity entity, bool isSubmitted, Color primaryColor) {
    return ListView.separated(
      controller: _questionsScrollController,
      padding: const EdgeInsets.all(20.0),
      itemCount: entity.questions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final q = entity.questions[index];
        final isExpanded = _expandedFeedback.contains(q.id);

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
                      'Question ${index + 1}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF71717A),
                          letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    // Câu hỏi gốc
                    Text(
                      q.questionText,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF09090B),
                          height: 1.4),
                    ),
                    // Hiển thị câu hỏi dịch bên dưới
                    if (_showTranslation && _translatedQuestions.containsKey(q.id)) ...[
                      const SizedBox(height: 4),
                      Text(
                        _translatedQuestions[q.id]!,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF166534), // Màu xanh phân biệt
                            height: 1.4),
                      ),
                    ]
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF4F4F5)),
              Column(
                children: List.generate(q.options.length, (optIdx) {
                  final isSelected = _selectedAnswers[q.id] == optIdx;

                  Color bgColor = Colors.transparent;
                  Color textColor = const Color(0xFF09090B);
                  IconData? icon;
                  Color iconColor = Colors.transparent;
                  Color leftBorderColor = Colors.transparent;

                  if (isSubmitted) {
                    final bool isCorrectAnswer = optIdx == q.correctAnswerIndex;
                    if (isCorrectAnswer) {
                      bgColor = const Color(0xFFECFDF5);
                      textColor = const Color(0xFF14532D);
                      icon = Icons.check_circle;
                      iconColor = leftBorderColor = const Color(0xFF16A34A);
                    } else if (isSelected) {
                      bgColor = const Color(0xFFFEF2F2);
                      textColor = const Color(0xFF7F1D1D);
                      icon = Icons.cancel;
                      iconColor = leftBorderColor = const Color(0xFFDC2626);
                    }
                  } else if (isSelected) {
                    bgColor = primaryColor.withOpacity(0.05);
                    leftBorderColor = primaryColor;
                  }

                  return InkWell(
                    onTap: isSubmitted
                        ? null
                        : () => setState(() => _selectedAnswers[q.id] = optIdx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: bgColor,
                        border: Border(
                          left: BorderSide(color: leftBorderColor, width: 4),
                          bottom: const BorderSide(color: Color(0xFFF4F4F5)),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${String.fromCharCode(65 + optIdx)}. ',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isSelected || isSubmitted ? textColor : const Color(0xFF71717A)),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Option gốc
                                Text(
                                  q.options[optIdx],
                                  style: TextStyle(fontSize: 15, color: textColor, height: 1.4),
                                ),
                                // Hiển thị Option dịch bên dưới
                                if (_showTranslation && _translatedOptions.containsKey(q.id)) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _translatedOptions[q.id]![optIdx],
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: isSubmitted && (isSelected || optIdx == q.correctAnswerIndex)
                                            ? textColor.withOpacity(0.8)
                                            : const Color(0xFF166534),
                                        height: 1.4),
                                  ),
                                ]
                              ],
                            ),
                          ),
                          if (icon != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Icon(icon, color: iconColor, size: 20),
                            ),
                          if (!isSubmitted)
                            Container(
                              margin: const EdgeInsets.only(left: 8.0),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? primaryColor : const Color(0xFFA1A1AA),
                                  width: 2,
                                ),
                                color: isSelected ? primaryColor : Colors.transparent,
                              ),
                              child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
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
                            Text(
                              'Explanation',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600, color: primaryColor),
                            ),
                            const Spacer(),
                            Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                              size: 18,
                              color: const Color(0xFFA1A1AA),
                            ),
                          ],
                        ),
                        if (isExpanded) ...[
                          const SizedBox(height: 8),
                          // Explanation Gốc
                          Text(
                            q.feedback!.reasoning,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF52525B), height: 1.5),
                          ),
                          // Explanation Dịch
                          if (_showTranslation && _translatedFeedback.containsKey(q.id)) ...[
                            const SizedBox(height: 4),
                            Text(
                              _translatedFeedback[q.id]!,
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFF166534), height: 1.5),
                            ),
                          ],

                          if (q.feedback!.hintTimestampSeconds != null) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Divider(height: 1, color: Color(0xFFE4E4E7)),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.play_circle_fill, size: 18, color: Colors.white),
                              label: Text(
                                'Nghe đoạn chứa đáp án (${q.feedback!.hintTimestampSeconds}s)',
                              ),
                              backgroundColor: primaryColor.withOpacity(0.8),
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
      },
    );
  }

  // =========================================================================
  // TAB TRANSCRIPT (Áp dụng bản dịch từ Global State)
  // =========================================================================
  Widget _buildTranscriptTab(
      ListeningCompEntity entity, bool isSubmitted, Color primaryColor) {
    if (!isSubmitted) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE4E4E7)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, color: Color(0xFFE4E4E7), size: 48),
              SizedBox(height: 16),
              Text(
                'Transcript Locked',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF09090B)),
              ),
              SizedBox(height: 8),
              Text(
                'Submit your answers first to unlock the full audio transcript.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFF71717A), fontSize: 14, height: 1.4),
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
          const Text(
            'Bản gốc (Tiếng Anh):',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF71717A),
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            entity.transcript,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Color(0xFF09090B),
              fontFamily: 'Serif',
            ),
          ),

          // 2. Bản Dịch (Hiện nếu _showTranslation = true)
          if (_showTranslation) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Divider(color: Color(0xFFE4E4E7), thickness: 1.5),
            ),
            const Text(
              'Bản dịch (Tiếng Việt):',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF71717A),
              ),
            ),
            const SizedBox(height: 12),

            // Hiện Text khi API trả về thành công/thất bại
            if (_translatedTranscript != null)
              SelectableText(
                _translatedTranscript!,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Color(0xFF166534), // Màu xanh phân biệt
                  fontFamily: 'Serif',
                ),
              ),
          ],
        ],
      ),
    );
  }
}