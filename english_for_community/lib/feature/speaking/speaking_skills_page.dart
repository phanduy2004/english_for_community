import 'dart:async';
import 'dart:math';
import 'package:english_for_community/core/entity/speaking/sentence_entity.dart';
import 'package:english_for_community/core/entity/speaking/speaking_set_entity.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/entity/speaking/speaking_attempt_entity.dart';
import 'package:english_for_community/feature/speaking/speaking_lesson_bloc/speaking_lesson_bloc.dart';
import 'package:english_for_community/feature/speaking/speaking_lesson_bloc/speaking_lesson_event.dart';
import 'package:english_for_community/feature/speaking/speaking_lesson_bloc/speaking_lesson_state.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/feature/speaking/widget/word_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeakingSkillsPage extends StatelessWidget {
  final String setId;
  final bool isRetake; // 🔥 THÊM BIẾN NÀY

  const SpeakingSkillsPage({
    super.key,
    required this.setId,
    this.isRetake = false, // Mặc định false
  });

  static const routeName = 'SpeakingSkillsPage';
  static const routePath = '/speaking-skills/:setId';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SpeakingLessonBloc>()
      // 🔥 TRUYỀN isRetake XUỐNG EVENT CỦA BLOC
        ..add(FetchLessonDetailsEvent(setId: setId, isRetake: isRetake)),
      child: const _SpeakingSkillsView(),
    );
  }
}

class _SpeakingSkillsView extends StatefulWidget {
  const _SpeakingSkillsView();

  @override
  State<_SpeakingSkillsView> createState() => _SpeakingSkillsViewState();
}

class _SpeakingSkillsViewState extends State<_SpeakingSkillsView> with SingleTickerProviderStateMixin {
  // --- SERVICES ---
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  late final AnimationController _micPulseController;

  // --- STATE ---
  bool _hasSpeech = false;
  /// Locale thực tế trên máy (tránh truyền en_US khi máy không có).
  String? _speechLocaleId;
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
    _micPulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _initSpeech();
    _initTts();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _micPulseController.dispose();
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
    if (micStatus != PermissionStatus.granted) {
      if (mounted) setState(() => _hasSpeech = false);
      return;
    }

    try {
      _hasSpeech = await _speech.initialize(
        onError: (e) {
          if (_isDisposed || !mounted) return;
          debugPrint('Speech Error: ${e.errorMsg}');
          _micPulseController.stop();
          _micPulseController.reset();
          if (_isRecording) {
            setState(() => _isRecording = false);
          }
        },
        onStatus: (status) {
          if (_isDisposed || !mounted) return;
          debugPrint('Speech Status: $status');
        },
      );
      if (_hasSpeech) {
        await _pickEnglishLocale();
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Init Speech Exception: $e');
      if (mounted) setState(() => _hasSpeech = false);
    }
  }

  Future<void> _pickEnglishLocale() async {
    try {
      final locales = await _speech.locales();
      if (locales.isEmpty) return;
      const preferred = ['en_US', 'en_GB', 'en_AU', 'en_IN', 'en_CA', 'en_NZ', 'en_IE'];
      for (final id in preferred) {
        if (locales.any((l) => l.localeId == id)) {
          _speechLocaleId = id;
          return;
        }
      }
      final en = locales.where((l) => l.localeId.toLowerCase().startsWith('en')).toList();
      if (en.isNotEmpty) {
        _speechLocaleId = en.first.localeId;
      }
    } catch (e) {
      debugPrint('pickEnglishLocale: $e');
    }
  }

  void _showMicSnack(String message, {bool openSettings = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
        action: openSettings
            ? SnackBarAction(label: 'Cài đặt', onPressed: openAppSettings)
            : null,
      ),
    );
  }

  // --- LOGIC GHI ÂM ĐƠN GIẢN (MANUAL STOP) ---

  Future<void> _toggleRecord() async {
    if (!_hasSpeech) await _initSpeech();
    if (!_hasSpeech) {
      _showMicSnack(
        'Chưa bật được nhận dạng giọng nói. Hãy cấp quyền micro và (iOS) quyền Speech Recognition.',
        openSettings: true,
      );
      return;
    }

    if (_isRecording) {
      _micPulseController.stop();
      _micPulseController.reset();
      _recordingStopwatch.stop();
      await _speech.stop();
      if (mounted) setState(() => _isRecording = false);
      HapticFeedback.lightImpact();
      _submitAttempt();
      return;
    }

    if (_isPlaying) {
      await _tts.stop();
      if (mounted) setState(() => _isPlaying = false);
    }
    // Tránh xung đột audio session (đặc biệt iOS) giữa TTS và STT.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    setState(() {
      _liveTranscript = '';
      _finalTranscript = '';
      _isSubmitting = false;
    });

    try {
      await _speech.listen(
        onResult: (result) {
          if (_isDisposed || !mounted) return;
          setState(() {
            _liveTranscript = result.recognizedWords;
            if (result.finalResult) {
              _finalTranscript = result.recognizedWords;
            }
          });
        },
        localeId: _speechLocaleId,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
        ),
      );
      // listen() trả về trước khi platform báo "listening" — đợi ngắn rồi kiểm tra.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      if (!_speech.isListening) {
        _showMicSnack(
          'Không mở được micro. Trên Android cần dịch vụ nhận dạng của Google; hãy thử cài/cập nhật Google app và ngôn ngữ tiếng Anh.',
          openSettings: true,
        );
        return;
      }
      if (mounted) {
        setState(() => _isRecording = true);
        HapticFeedback.mediumImpact();
        _micPulseController.repeat(reverse: true);
        _recordingStopwatch.reset();
        _recordingStopwatch.start();
      }
    } catch (e) {
      if (mounted) {
        _showMicSnack('Lỗi khi bật micro: $e');
      }
    }
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
      _micPulseController.stop();
      _micPulseController.reset();
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
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCard,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.outline, height: 1),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _set?.title ?? 'Practice',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
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
                Container(
                  color: AppColors.surfaceCard,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Câu ${_currentPageIndex + 1} / ${_set!.sentences.length}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${((_currentPageIndex + 1) / _set!.sentences.length * 100).toInt()}%',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_currentPageIndex + 1) / _set!.sentences.length,
                          minHeight: 6,
                          backgroundColor: AppColors.outlineMuted,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: AppColors.outline),
                if (!_hasSpeech)
                  Material(
                    color: AppColors.tertiary.withValues(alpha: 0.12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Micro / nhận dạng giọng nói chưa sẵn sàng. Cấp quyền và thử lại.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.35),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _initSpeech(),
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  ),

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

                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    border: Border(top: BorderSide(color: AppColors.outline)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        onPressed: (_isRecording || _isSubmitting) ? null : _goToNextSentence,
                        child: Text(
                          _currentPageIndex == _set!.sentences.length - 1 ? 'Hoàn thành' : 'Câu tiếp theo',
                        ),
                      ),
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
    final primaryColor = AppColors.primary;
    final textMain = AppColors.textPrimary;
    final textMuted = AppColors.textMuted;
    final recordRed = AppColors.chartTrend;

    final micCore = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: isRecording ? recordRed : primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isRecording ? recordRed : primaryColor).withValues(alpha: 0.35),
            blurRadius: isRecording ? 20 : 14,
            spreadRadius: isRecording ? 1 : 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: isSubmitting
          ? const Padding(
              padding: EdgeInsets.all(22),
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            )
          : Icon(
              isRecording ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 34,
            ),
    );

    final micButton = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isSubmitting ? null : _toggleRecord,
        customBorder: const CircleBorder(),
        child: isRecording
            ? ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 1.06).animate(
                  CurvedAnimation(parent: _micPulseController, curve: Curves.easeInOut),
                ),
                child: micCore,
              )
            : micCore,
      ),
    );

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
                        Icon(Icons.person_outline, size: 16, color: textMuted),
                        const SizedBox(width: 4),
                        Text(
                          sentence.speaker,
                          style: TextStyle(fontSize: 13, color: textMuted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    _LevelPill(label: _set?.level ?? 'Beginner', color: primaryColor),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTappableScript(context, sentence.script),
                const SizedBox(height: 10),
                Text(
                  sentence.phoneticScript,
                  style: TextStyle(color: textMuted, fontSize: 14, fontFamily: 'NotoSans'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
                  decoration: BoxDecoration(
                    color: AppColors.outlineMuted,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Material(
                                color: AppColors.surfaceCard,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  onTap: (isRecording || isSubmitting) ? null : _togglePlay,
                                  customBorder: const CircleBorder(),
                                  child: Container(
                                    width: 52,
                                    height: 52,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.outline),
                                    ),
                                    child: Icon(
                                      _isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
                                      color: textMain,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Nghe mẫu',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted),
                              ),
                              Text(
                                'Sample',
                                style: TextStyle(fontSize: 11, color: textMuted.withValues(alpha: 0.85)),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              micButton,
                              const SizedBox(height: 8),
                              Text(
                                'Nói của bạn',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isRecording ? recordRed : textMuted,
                                ),
                              ),
                              Text(
                                'Your turn',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: (isRecording ? recordRed : textMuted).withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isRecording
                            ? 'Đang nghe… Chạm nút đỏ để dừng và chấm điểm.'
                            : isSubmitting
                                ? 'Đang gửi và phân tích…'
                                : 'Chạm micro, đọc to cả câu rồi chạm lại để dừng.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isRecording ? recordRed : textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
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
                  Text(
                    'LỜI BẠN NÓI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textMuted,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    transcript.isEmpty ? 'Sẽ hiện ở đây khi bạn nói…' : transcript,
                    style: TextStyle(
                      fontSize: 17,
                      color: transcript.isEmpty ? textMuted : textMain,
                      height: 1.5,
                      fontWeight: transcript.isEmpty ? FontWeight.w400 : FontWeight.w500,
                    ),
                  ),
                  if (score != null) ...[
                    const SizedBox(height: 16),
                    Divider(height: 1, color: AppColors.outlineMuted),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Độ chính xác',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textMain),
                        ),
                        _ScorePill(
                          scoreText: '$score%',
                          bg: (score) >= 80 ? const Color(0xFFDCFCE7) : const Color(0xFFFFEDD5),
                          fg: (score) >= 80 ? AppColors.success : const Color(0xFFEA580C),
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
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
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