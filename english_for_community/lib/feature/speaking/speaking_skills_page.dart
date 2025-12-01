import 'dart:async';
import 'dart:math';
import 'package:english_for_community/core/entity/speaking/sentence_entity.dart';
import 'package:english_for_community/core/entity/speaking/speaking_set_entity.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/entity/speaking/speaking_attempt_entity.dart';
import 'package:english_for_community/feature/speaking/speaking_lesson_bloc/speaking_lesson_bloc.dart';
import 'package:english_for_community/feature/speaking/speaking_lesson_bloc/speaking_lesson_event.dart';
import 'package:english_for_community/feature/speaking/speaking_lesson_bloc/speaking_lesson_state.dart';
import 'package:english_for_community/feature/speaking/widget/word_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeakingSkillsPage extends StatelessWidget {
  final String setId;

  const SpeakingSkillsPage({
    super.key,
    required this.setId,
  });

  static const routeName = 'SpeakingSkillsPage';
  static const routePath = '/speaking-skills/:setId';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SpeakingLessonBloc>()
        ..add(FetchLessonDetailsEvent(setId: setId)),
      child: const _SpeakingSkillsView(),
    );
  }
}

class _SpeakingSkillsView extends StatefulWidget {
  const _SpeakingSkillsView();

  @override
  State<_SpeakingSkillsView> createState() => _SpeakingSkillsViewState();
}

class _SpeakingSkillsViewState extends State<_SpeakingSkillsView> {
  // --- SERVICES ---
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  // --- STATE ---
  bool _hasSpeech = false;
  bool _isPlaying = false;
  bool _isRecording = false;
  bool _isSubmitting = false;
  bool _isDisposed = false;

  // --- DATA ---
  String _liveTranscript = '';
  String _finalTranscript = '';

  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  // Stopwatch để tính thời gian nói (để hiển thị hoặc gửi lên server)
  final Stopwatch _recordingStopwatch = Stopwatch();

  SpeakingSetEntity? _set;
  SentenceEntity? _currentSentence;
  final Map<String, List<SpeakingAttemptEntity>> _historyMap = {};

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    _initSpeech();
    _initTts();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _tts.stop();
    _speech.stop();
    _pageController.dispose();
    _recordingStopwatch.stop();
    super.dispose();
  }

  // --- INIT ---

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      if (!_isDisposed && mounted) setState(() => _isPlaying = false);
    });
    _tts.setCancelHandler(() {
      if (!_isDisposed && mounted) setState(() => _isPlaying = false);
    });
  }

  Future<void> _initSpeech() async {
    final micStatus = await Permission.microphone.request();
    if (micStatus != PermissionStatus.granted) return;

    try {
      _hasSpeech = await _speech.initialize(
        onError: (e) {
          if (_isDisposed || !mounted) return;
          print("Speech Error: ${e.errorMsg}");
          // Nếu lỗi xảy ra (ví dụ mất mạng), tắt trạng thái recording để user biết bấm lại
          if (_isRecording) {
            setState(() => _isRecording = false);
          }
        },
        onStatus: (status) {
          // Chỉ log để debug, không can thiệp logic tắt bật ở đây nữa
          print("Speech Status: $status");
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      print("Init Speech Exception: $e");
    }
  }

  // --- LOGIC GHI ÂM ĐƠN GIẢN (MANUAL STOP) ---

  Future<void> _toggleRecord() async {
    if (!_hasSpeech) await _initSpeech();
    if (!_hasSpeech) return;

    // 1. NẾU ĐANG GHI ÂM -> BẤM ĐỂ DỪNG (STOP)
    if (_isRecording) {
      // Dừng stopwatch
      _recordingStopwatch.stop();

      // Dừng speech plugin
      await _speech.stop();

      // Update UI
      if (mounted) setState(() => _isRecording = false);

      // Nộp bài
      _submitAttempt();
      return;
    }

    // 2. NẾU CHƯA GHI ÂM -> BẮT ĐẦU (START)

    // Tắt loa nếu đang đọc mẫu
    if (_isPlaying) {
      await _tts.stop();
      setState(() => _isPlaying = false);
    }

    // Reset text cũ
    setState(() {
      _liveTranscript = '';
      _finalTranscript = '';
      _isRecording = true;
      _isSubmitting = false;
    });

    _recordingStopwatch.reset();
    _recordingStopwatch.start();

    await _speech.listen(
      localeId: 'en_US',
      onResult: (result) {
        if (_isDisposed || !mounted) return;
        setState(() {
          // Cập nhật text liên tục
          _liveTranscript = result.recognizedWords;
          // Lưu lại bản final (nếu có) nhưng chưa submit vội
          if (result.finalResult) {
            _finalTranscript = result.recognizedWords;
          }
        });
      },
      // ⭐️ CẤU HÌNH QUAN TRỌNG: 5 PHÚT (300s) MỚI TỰ TẮT
      // Điều này đảm bảo mic luôn mở cho đến khi bạn bấm dừng
      listenFor: const Duration(seconds: 300),
      pauseFor: const Duration(seconds: 300),
      partialResults: true,
      cancelOnError: true,
      listenMode: stt.ListenMode.dictation,
    );
  }

  // --- SUBMIT LOGIC ---

  void _submitAttempt() {
    // Ưu tiên lấy text đang chạy nếu final chưa kịp chốt
    String textToSubmit = _liveTranscript.trim();
    if (textToSubmit.isEmpty) {
      textToSubmit = _finalTranscript.trim();
    }

    if (textToSubmit.isEmpty || _currentSentence == null) return;

    setState(() => _isSubmitting = true);

    final ref = _normalizeText(_currentSentence!.script);
    final hyp = _normalizeText(textToSubmit);
    final wer = _calculateWer(ref, hyp);
    final durationSeconds = _recordingStopwatch.elapsed.inSeconds;

    const fakeAudioUrl = 'https://fake.url/audio.mp3';

    context.read<SpeakingLessonBloc>().add(SubmitLessonAttemptEvent(
      speakingSetId: _set!.id,
      sentenceId: _currentSentence!.id,
      userTranscript: textToSubmit,
      userAudioUrl: fakeAudioUrl,
      score: SpeakingScoreEntity(wer: wer, confidence: 0.9),
      audioDurationSeconds: durationSeconds,
    ));
  }

  // --- MEDIA CONTROL ---

  Future<void> _togglePlay() async {
    if (_currentSentence == null) return;
    if (_isPlaying) {
      await _tts.stop();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      // Nếu đang ghi âm thì tắt ghi âm trước
      if (_isRecording) {
        await _toggleRecord(); // Gọi hàm toggle để dừng đúng quy trình
      }

      await _tts.stop();
      await _tts.speak(_currentSentence!.script);
      if (mounted) setState(() => _isPlaying = true);
    }
  }

  // --- NAVIGATION ---

  void _onPageChanged(int index) {
    if (_set == null) return;

    // Chuyển trang -> Reset hết
    if (_isRecording) {
      _speech.stop();
      _recordingStopwatch.stop();
    }
    _tts.stop();

    setState(() {
      _currentPageIndex = index;
      _currentSentence = _set!.sentences[index];
      _liveTranscript = '';
      _finalTranscript = '';
      _isRecording = false;
      _isSubmitting = false;
      _isPlaying = false;
    });
  }

  void _goToNextSentence() {
    if (_set == null || _currentPageIndex >= _set!.sentences.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showWordDialog(String word) {
    _tts.stop();
    showDialog(
      context: context,
      builder: (context) => WordDetailsDialog(
        word: word,
        tts: _tts,
      ),
    );
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    const bgPage = Color(0xFFF9FAFB);
    const borderCol = Color(0xFFE4E4E7);
    const textMain = Color(0xFF09090B);

    return Scaffold(
      backgroundColor: bgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderCol, height: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textMain),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _set?.title ?? 'Practice',
          style: const TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<SpeakingLessonBloc, SpeakingLessonState>(
          listener: (context, state) {
            if (state.status == LessonStatus.success && state.set != null && _set == null) {
              setState(() {
                _set = state.set;
                _currentSentence = state.set!.sentences.firstOrNull;
                _historyMap.clear();
                for (var s in _set!.sentences) {
                  _historyMap[s.id] = List.from(s.history);
                }
              });
            }
            if (state.status == LessonStatus.success && state.lastAttempt != null) {
              final attempt = state.lastAttempt!;
              setState(() {
                _isSubmitting = false;
                final list = _historyMap[attempt.sentenceId] ?? [];
                if (list.isEmpty || list.first.id != attempt.id) {
                  list.insert(0, attempt);
                  _historyMap[attempt.sentenceId] = list;
                }
              });
            }
          },
          builder: (context, state) {
            if (state.status == LessonStatus.loading || _set == null) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            }

            return Column(
              children: [
                // HEADER PROGRESS
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Sentence ${_currentPageIndex + 1} of ${_set!.sentences.length}',
                              style: const TextStyle(color: Color(0xFF71717A), fontSize: 13, fontWeight: FontWeight.w500)),
                          Text('${((_currentPageIndex + 1) / _set!.sentences.length * 100).toInt()}%',
                              style: const TextStyle(color: Color(0xFF09090B), fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: (_currentPageIndex + 1) / _set!.sentences.length,
                          minHeight: 4,
                          backgroundColor: const Color(0xFFF4F4F5),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: borderCol),

                // MAIN CONTENT
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _set!.sentences.length,
                    onPageChanged: _onPageChanged,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final sentence = _set!.sentences[index];
                      final history = _historyMap[sentence.id] ?? [];
                      final latestAttempt = history.firstOrNull;

                      // Logic hiển thị transcript
                      String displayTranscript = "";
                      if (_currentPageIndex == index) {
                        // Hiển thị những gì đang nói
                        displayTranscript = _liveTranscript.isNotEmpty ? _liveTranscript : _finalTranscript;
                      }
                      if (displayTranscript.isEmpty && latestAttempt != null) {
                        displayTranscript = latestAttempt.userTranscript ?? "";
                      }

                      final score = (latestAttempt != null) ? _scoreFromWer(latestAttempt.score?.wer ?? 1.0) : null;

                      return _buildSentenceCard(
                        context,
                        sentence: sentence,
                        transcript: displayTranscript,
                        score: score,
                        isRecording: _isRecording && (_currentPageIndex == index),
                        isSubmitting: _isSubmitting && (_currentPageIndex == index),
                      );
                    },
                  ),
                ),

                // BOTTOM BUTTON
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: borderCol)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      onPressed: (_isRecording || _isSubmitting) ? null : _goToNextSentence,
                      child: Text(_currentPageIndex == _set!.sentences.length - 1 ? 'Finish' : 'Next Sentence'),
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSentenceCard(
      BuildContext context, {
        required SentenceEntity sentence,
        required String transcript,
        int? score,
        required bool isRecording,
        required bool isSubmitting,
      }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _ShadcnCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: textMuted),
                        const SizedBox(width: 4),
                        Text(sentence.speaker, style: const TextStyle(fontSize: 13, color: textMuted, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    _LevelPill(label: _set?.level ?? 'Beginner', color: primaryColor),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTappableScript(context, sentence.script),
                const SizedBox(height: 12),
                Text(
                  sentence.phoneticScript,
                  style: const TextStyle(color: textMuted, fontSize: 14, fontFamily: 'NotoSans'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Play Button
                    InkWell(
                      onTap: (isRecording || isSubmitting) ? null : _togglePlay,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE4E4E7)),
                        ),
                        child: Icon(_isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded, color: textMain),
                      ),
                    ),
                    const SizedBox(width: 24),

                    // RECORD BUTTON (LOGIC CHÍNH)
                    InkWell(
                      onTap: isSubmitting ? null : _toggleRecord,
                      borderRadius: BorderRadius.circular(32),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          // Màu đỏ khi đang ghi âm, Màu chính khi chờ
                          color: isRecording ? const Color(0xFFEF4444) : primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isRecording ? const Color(0xFFEF4444) : primaryColor).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: isSubmitting
                            ? const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        // Icon vuông khi đang ghi âm (để bấm Stop)
                            : Icon(isRecording ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(width: 24),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isRecording ? 'Tap to stop' : (isSubmitting ? 'Analyzing...' : 'Tap mic to record'),
                  style: TextStyle(fontSize: 12, color: isRecording ? const Color(0xFFEF4444) : textMuted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ShadcnCard(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('YOUR TRANSCRIPT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textMuted, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Text(
                    transcript.isEmpty ? '...' : transcript,
                    style: TextStyle(fontSize: 16, color: transcript.isEmpty ? textMuted : textMain, height: 1.5),
                  ),
                  if (score != null) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFF4F4F5)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Accuracy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textMain)),
                        _ScorePill(
                          scoreText: '$score%',
                          bg: (score) >= 80 ? const Color(0xFFDCFCE7) : const Color(0xFFFFEDD5),
                          fg: (score) >= 80 ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
                        )
                      ],
                    )
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTappableScript(BuildContext context, String script) {
    final words = script.split(' ');
    final List<Widget> wordWidgets = [];
    final textStyle = TextStyle(
      fontSize: 22,
      height: 1.4,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurface,
    );

    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r"[.,!?]"), "");
      wordWidgets.add(
        InkWell(
          onTap: () {
            if (cleanWord.isNotEmpty) _showWordDialog(cleanWord);
          },
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
            child: Text(word, style: textStyle),
          ),
        ),
      );
    }
    return Wrap(spacing: 4.0, runSpacing: 4.0, alignment: WrapAlignment.center, children: wordWidgets);
  }
}

// --- STYLED WIDGETS (Giữ nguyên UI của bạn) ---

class _ShadcnCard extends StatelessWidget {
  final Widget child;
  const _ShadcnCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class _LevelPill extends StatelessWidget {
  final String label;
  final Color color;
  const _LevelPill({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.2))),
      child: Text(label.toUpperCase(), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String scoreText;
  final Color bg;
  final Color fg;
  const _ScorePill({required this.scoreText, required this.bg, required this.fg});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(scoreText, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}

// --- LOGIC HELPER ---

String _normalizeText(String s) => s.toLowerCase().replaceAll(RegExp(r"[.,!?]"), "").trim();

double _calculateWer(String ref, String hyp) {
  final r = _normalizeText(ref).split(RegExp(r"\s+")).where((e) => e.isNotEmpty).toList();
  final h = _normalizeText(hyp).split(RegExp(r"\s+")).where((e) => e.isNotEmpty).toList();
  if (r.isEmpty) return h.isEmpty ? 0.0 : 1.0;
  final dp = List.generate(r.length + 1, (_) => List<int>.filled(h.length + 1, 0));
  for (int i = 0; i < r.length + 1; i++) dp[i][0] = i;
  for (int j = 0; j < h.length + 1; j++) dp[0][j] = j;
  for (int i = 1; i < r.length + 1; i++) {
    for (int j = 1; j < h.length + 1; j++) {
      final cost = r[i - 1] == h[j - 1] ? 0 : 1;
      dp[i][j] = min(dp[i - 1][j] + 1, min(dp[i][j - 1] + 1, dp[i - 1][j - 1] + cost));
    }
  }
  return dp[r.length][h.length] / r.length;
}

int _scoreFromWer(double wer) => (100.0 * (1.0 - wer)).clamp(0.0, 100.0).round();