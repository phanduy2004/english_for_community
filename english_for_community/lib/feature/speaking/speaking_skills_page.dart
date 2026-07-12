import 'dart:async';
import 'dart:math';
import 'package:english_for_community/core/entity/speaking/sentence_entity.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/core/theme/app_motion.dart'
    as theme_motion;
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/entity/speaking/speaking_set_entity.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/entity/speaking/speaking_attempt_entity.dart';
import 'package:english_for_community/feature/speaking/speaking_lesson_bloc/speaking_lesson_bloc.dart';
import 'package:english_for_community/feature/speaking/speaking_lesson_bloc/speaking_lesson_event.dart';
import 'package:english_for_community/feature/speaking/speaking_lesson_bloc/speaking_lesson_state.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/ui/feedback/app_feedback.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/speaking/widget/word_details_dialog.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

String _localizedLevelLabel(AppLocalizations t, String level) {
  switch (level.toLowerCase()) {
    case 'beginner':
      return t.difficultyBeginner;
    case 'intermediate':
      return t.difficultyIntermediate;
    case 'advanced':
      return t.difficultyAdvanced;
    default:
      return level;
  }
}

class SpeakingSkillsPage extends StatelessWidget {
  final String setId;
  final bool isRetake;
  final bool embedded;
  final bool examPracticeMode;
  final bool readOnlyReview;
  final VoidCallback? onPartComplete;
  final void Function(int sentenceIndex, int totalSentences, int savedCount)?
      onExamSpeakingProgress;
  /// Resume trong bài thi: bản ghi speaking đã làm (backend gửi qua attempt.speakingHistory)
  /// để dựng lại lịch sử — chỉ áp dụng khi examPracticeMode.
  final List<Map<String, dynamic>>? initialExamHistory;

  const SpeakingSkillsPage({
    super.key,
    required this.setId,
    this.isRetake = false,
    this.embedded = false,
    this.examPracticeMode = false,
    this.readOnlyReview = false,
    this.onPartComplete,
    this.onExamSpeakingProgress,
    this.initialExamHistory,
  });

  static const routeName = 'SpeakingSkillsPage';
  static const routePath = '/speaking-skills/:setId';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SpeakingLessonBloc>()
        // 🔥 TRUYỀN isRetake XUỐNG EVENT CỦA BLOC
        ..add(FetchLessonDetailsEvent(setId: setId, isRetake: isRetake)),
      child: _SpeakingSkillsView(
        embedded: embedded,
        examPracticeMode: examPracticeMode,
        readOnlyReview: readOnlyReview,
        onPartComplete: onPartComplete,
        onExamSpeakingProgress: onExamSpeakingProgress,
        initialExamHistory: initialExamHistory,
      ),
    );
  }
}

class _SpeakingSkillsView extends StatefulWidget {
  const _SpeakingSkillsView({
    this.embedded = false,
    this.examPracticeMode = false,
    this.readOnlyReview = false,
    this.onPartComplete,
    this.onExamSpeakingProgress,
    this.initialExamHistory,
  });

  final bool embedded;
  final bool examPracticeMode;
  final bool readOnlyReview;
  final VoidCallback? onPartComplete;
  final void Function(int sentenceIndex, int totalSentences, int savedCount)?
      onExamSpeakingProgress;
  final List<Map<String, dynamic>>? initialExamHistory;

  @override
  State<_SpeakingSkillsView> createState() => _SpeakingSkillsViewState();
}

class _SpeakingSkillsViewState extends State<_SpeakingSkillsView>
    with SingleTickerProviderStateMixin {
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

  /// True trong lúc đang bật micro (trước khi `_isRecording` = true). Tránh spam click gọi `listen()` nhiều lần (web: InvalidStateError).
  bool _micStartInProgress = false;
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

  bool get _examCompact => widget.embedded && widget.examPracticeMode;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    _micPulseController = AnimationController(
        vsync: this, duration: theme_motion.AppMotion.pulse);
    _initSpeech();
    _initTts();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _micStartInProgress = false;
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
    if (!kIsWeb) {
      final micStatus = await Permission.microphone.request();
      if (micStatus != PermissionStatus.granted) {
        if (mounted) setState(() => _hasSpeech = false);
        return;
      }
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
      const preferred = [
        'en_US',
        'en_GB',
        'en_AU',
        'en_IN',
        'en_CA',
        'en_NZ',
        'en_IE'
      ];
      for (final id in preferred) {
        if (locales.any((l) => l.localeId == id)) {
          _speechLocaleId = id;
          return;
        }
      }
      final en = locales
          .where((l) => l.localeId.toLowerCase().startsWith('en'))
          .toList();
      if (en.isNotEmpty) {
        _speechLocaleId = en.first.localeId;
      }
    } catch (e) {
      debugPrint('pickEnglishLocale: $e');
    }
  }

  void _showMicSnack(String message) {
    if (!mounted) return;
    AppFeedback.error(context, message);
  }

  // --- LOGIC GHI ÂM ĐƠN GIẢN (MANUAL STOP) ---

  Future<void> _toggleRecord() async {
    if (widget.readOnlyReview) return;
    if (!_hasSpeech) await _initSpeech();
    if (!mounted) return;
    if (!_hasSpeech) {
      _showMicSnack(context.l10n.speechNotAvailableSnack);
      return;
    }

    if (_isRecording) {
      _micStartInProgress = false;
      _micPulseController.stop();
      _micPulseController.reset();
      _recordingStopwatch.stop();
      await _speech.stop();
      if (mounted) setState(() => _isRecording = false);
      HapticFeedback.lightImpact();
      _submitAttempt();
      return;
    }

    if (_micStartInProgress) return;

    // Platform đã listen (ví dụ web) nhưng UI chưa kịp cập nhật — không gọi listen() lần nữa.
    if (_speech.isListening) {
      if (mounted) {
        setState(() => _isRecording = true);
        HapticFeedback.mediumImpact();
        _micPulseController.repeat(reverse: true);
        _recordingStopwatch.reset();
        _recordingStopwatch.start();
      }
      return;
    }

    _micStartInProgress = true;
    if (mounted) setState(() {});

    try {
      if (_isPlaying) {
        await _tts.stop();
        if (mounted) setState(() => _isPlaying = false);
      }
      // Tránh xung đột audio session (đặc biệt iOS) giữa TTS và STT.
      await Future<void>.delayed(theme_motion.AppMotion.debounce);
      if (!mounted) return;

      setState(() {
        _liveTranscript = '';
        _finalTranscript = '';
        _isSubmitting = false;
      });

      if (_speech.isListening) {
        if (mounted) {
          setState(() => _isRecording = true);
          HapticFeedback.mediumImpact();
          _micPulseController.repeat(reverse: true);
          _recordingStopwatch.reset();
          _recordingStopwatch.start();
        }
        return;
      }

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
        await Future<void>.delayed(theme_motion.AppMotion.enter);
        if (!mounted) return;
        if (!_speech.isListening) {
          _showMicSnack(context.l10n.micOpenFailedSnack);
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
          _showMicSnack(context.l10n.micStartError('$e'));
        }
      }
    } finally {
      _micStartInProgress = false;
      if (mounted) setState(() {});
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

  int _speakingSavedCount() {
    return _historyMap.values.where((attempts) => attempts.isNotEmpty).length;
  }

  /// Resume: dựng lại lịch sử speaking đã làm TRONG bài thi (server gửi qua initialExamHistory),
  /// gom theo sentenceId, mới nhất trước. Chỉ dùng ở exam mode.
  Map<String, List<SpeakingAttemptEntity>> _groupExamHistoryBySentence() {
    final raw = widget.initialExamHistory;
    if (raw == null || raw.isEmpty) return const {};
    final out = <String, List<SpeakingAttemptEntity>>{};
    for (final j in raw) {
      try {
        final att = SpeakingAttemptEntity.fromJson(j);
        (out[att.sentenceId] ??= <SpeakingAttemptEntity>[]).add(att);
      } catch (_) {
        // bỏ qua bản ghi lỗi shape, không chặn resume
      }
    }
    for (final list in out.values) {
      list.sort((a, b) => (b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    }
    return out;
  }

  void _notifyExamSpeakingProgress() {
    if (_set == null || widget.onExamSpeakingProgress == null) return;
    widget.onExamSpeakingProgress!(
      _currentPageIndex,
      _set!.sentences.length,
      _speakingSavedCount(),
    );
  }

  void _onPageChanged(int index) {
    if (_set == null) return;

    // Chuyển trang -> Reset hết
    if (_isRecording || _micStartInProgress) {
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
      _micStartInProgress = false;
      _isSubmitting = false;
      _isPlaying = false;
    });
    _notifyExamSpeakingProgress();
  }

  void _goToNextSentence() {
    if (_set == null || _currentPageIndex >= _set!.sentences.length - 1) {
      if (widget.embedded && widget.onPartComplete != null) {
        widget.onPartComplete!();
      } else {
        Navigator.of(context).pop();
      }
      return;
    }
    _pageController.nextPage(
      duration: theme_motion.AppMotion.effective(
          context, theme_motion.AppMotion.base),
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

  Widget _buildLessonBody() {
    return BlocConsumer<SpeakingLessonBloc, SpeakingLessonState>(
      listener: (context, state) {
        if (state.status == LessonStatus.success &&
            state.set != null &&
            _set == null) {
          setState(() {
            _set = state.set;
            _currentSentence = state.set!.sentences.firstOrNull;
            _historyMap.clear();
            final examHist = _groupExamHistoryBySentence();
            for (var s in _set!.sentences) {
              _historyMap[s.id] = widget.examPracticeMode
                  ? (examHist[s.id] ?? <SpeakingAttemptEntity>[])
                  : List.from(s.history);
            }
          });
          _notifyExamSpeakingProgress();
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
          _notifyExamSpeakingProgress();
        }
      },
      builder: (context, state) {
        final t = context.l10n;
        final compact = widget.embedded;
        final examCompact = _examCompact;
        if (state.status == LessonStatus.loading || _set == null) {
          return StudentMobileUi.runnerLoading();
        }

        return Column(
          children: [
            Container(
              color: AppColors.surfaceCard,
              padding: EdgeInsets.symmetric(
                horizontal: examCompact ? 10 : (compact ? 14 : 20),
                vertical: examCompact ? 6 : (compact ? 10 : 12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.sentenceIndex(
                            _currentPageIndex + 1, _set!.sentences.length),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: examCompact ? 11 : 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${((_currentPageIndex + 1) / _set!.sentences.length * 100).toInt()}%',
                        style: ExamSystemUi.embeddedProgressLabel(context)
                            .copyWith(
                          color: AppColors.textPrimary,
                          fontSize: examCompact ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: examCompact ? 4 : 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    child: LinearProgressIndicator(
                      value: (_currentPageIndex + 1) / _set!.sentences.length,
                      minHeight: examCompact ? 4 : 6,
                      backgroundColor: AppColors.outlineMuted,
                      color: AppSkillColors.speaking.color,
                    ),
                  ),
                ],
              ),
            ),
            if (!examCompact) Container(height: 1, color: AppColors.outline),
            if (!_hasSpeech)
              Material(
                color: AppColors.tertiary.withValues(alpha: 0.12),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: examCompact ? 10 : 16,
                    vertical: examCompact ? 6 : 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.warning,
                        size: examCompact ? 18 : 22,
                      ),
                      SizedBox(width: examCompact ? 6 : 10),
                      Expanded(
                        child: Text(
                          t.microInfoBanner,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: examCompact ? 11 : 13,
                            height: 1.3,
                          ),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          visualDensity: examCompact
                              ? VisualDensity.compact
                              : VisualDensity.standard,
                          padding: examCompact
                              ? const EdgeInsets.symmetric(horizontal: 8)
                              : null,
                        ),
                        onPressed: () => _initSpeech(),
                        child: Text(t.tryAgain,
                            style: TextStyle(fontSize: examCompact ? 11 : 14)),
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
                    displayTranscript = _liveTranscript.isNotEmpty
                        ? _liveTranscript
                        : _finalTranscript;
                  }
                  if (!widget.examPracticeMode &&
                      displayTranscript.isEmpty &&
                      latestAttempt != null) {
                    displayTranscript = latestAttempt.userTranscript ?? "";
                  }

                  final score = widget.examPracticeMode
                      ? null
                      : (latestAttempt != null)
                          ? _scoreFromWer(latestAttempt.score?.wer ?? 1.0)
                          : null;

                  return _buildSentenceCard(
                    context,
                    t: t,
                    sentence: sentence,
                    transcript: displayTranscript,
                    score: score,
                    isRecording: _isRecording && (_currentPageIndex == index),
                    isSubmitting: _isSubmitting && (_currentPageIndex == index),
                    micBusy:
                        _micStartInProgress && (_currentPageIndex == index),
                  );
                },
              ),
            ),

            Container(
              padding: EdgeInsets.fromLTRB(
                examCompact ? 10 : (compact ? 14 : 20),
                examCompact ? 8 : (compact ? 12 : 16),
                examCompact ? 10 : (compact ? 14 : 20),
                examCompact ? 8 : (compact ? 14 : 20),
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                border: Border(top: BorderSide(color: AppColors.outline)),
                boxShadow: compact && !examCompact
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, -4),
                        ),
                      ]
                    : null,
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: examCompact ? 40 : (compact ? 44 : 50),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(examCompact ? 10 : 12),
                      ),
                      textStyle: examCompact || compact
                          ? ExamSystemUi.embeddedButtonLabelStyle
                          : const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: AppTypography.mobileH1),
                    ),
                    onPressed: (_isRecording || _isSubmitting)
                        ? null
                        : _goToNextSentence,
                    child: Text(
                      _currentPageIndex == _set!.sentences.length - 1
                          ? t.finishPractice
                          : t.nextSentence,
                    ),
                  ),
                ),
              ),
            )
          ],
        );
      },
    );
  }

  bool _shouldBlockExit() {
    if (widget.embedded) return false;
    if (_currentPageIndex > 0) return true;
    return _historyMap.values.any((attempts) => attempts.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final body = _buildLessonBody();
    if (widget.embedded) {
      return body;
    }
    return StudentMobileUi.runnerPopScope(
      context: context,
      blockExit: _shouldBlockExit(),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: StudentMobileUi.skillAppBar(
          context,
          title: _set?.title ?? t.practiceFallbackTitle,
          skill: SkillType.speaking,
        ),
        body: SafeArea(child: body),
      ),
    );
  }

  Widget _buildSentenceCard(
    BuildContext context, {
    required AppLocalizations t,
    required SentenceEntity sentence,
    required String transcript,
    int? score,
    required bool isRecording,
    required bool isSubmitting,
    required bool micBusy,
  }) {
    final compact = widget.embedded;
    final examCompact = _examCompact;
    final textMain = AppColors.textPrimary;
    final textMuted = AppColors.textMuted;
    final recordRed = AppColors.danger;
    // Idle = màu kỹ năng Speaking (emerald); đang ghi = danger. KHÔNG glow.
    final micColor = isRecording ? recordRed : AppSkillColors.speaking.color;
    final micSize = examCompact ? 48.0 : (compact ? 56.0 : 64.0);
    final playSize = examCompact ? 40.0 : 52.0;

    final micCore = AnimatedContainer(
      duration: theme_motion.AppMotion.effective(
          context, theme_motion.AppMotion.page),
      width: micSize,
      height: micSize,
      decoration: BoxDecoration(
        color: micColor,
        shape: BoxShape.circle,
        // Nút ghi âm nổi (floating) — bóng nhẹ trung tính, KHÔNG glow màu.
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: (isSubmitting || micBusy)
          ? Padding(
              padding: EdgeInsets.all(micSize * 0.32),
              child: const AppLoadingIndicator.button(color: Colors.white),
            )
          : Icon(
              isRecording ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: examCompact ? 22 : 28,
            ),
    );

    final micButton = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (isSubmitting || micBusy || widget.readOnlyReview)
            ? null
            : _toggleRecord,
        customBorder: const CircleBorder(),
        child: isRecording
            ? ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 1.06).animate(
                  CurvedAnimation(
                      parent: _micPulseController, curve: Curves.easeInOut),
                ),
                child: micCore,
              )
            : micCore,
      ),
    );

    if (examCompact) {
      return SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: _ShadcnCard(
          padding: const EdgeInsets.all(12),
          radius: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTappableScript(context, sentence.script),
              if (sentence.phoneticScript.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  sentence.phoneticScript,
                  style: TextStyle(
                      color: textMuted,
                      fontSize: AppTypography.mobileCaption,
                      fontFamily: 'NotoSans',
                      height: 1.25),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.outlineMuted,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: AppColors.surfaceCard,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: (isRecording || isSubmitting)
                                ? null
                                : _togglePlay,
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: playSize,
                              height: playSize,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.outline),
                              ),
                              child: Icon(
                                _isPlaying
                                    ? Icons.stop_rounded
                                    : Icons.volume_up_rounded,
                                color: textMain,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(t.sampleListen,
                            style: TextStyle(
                                fontSize: AppTypography.mobileCaption,
                                fontWeight: FontWeight.w600,
                                color: textMuted)),
                      ],
                    ),
                    const SizedBox(width: 28),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        micButton,
                        const SizedBox(height: 4),
                        Text(
                          t.yourTurn,
                          style: TextStyle(
                            fontSize: AppTypography.mobileCaption,
                            fontWeight: FontWeight.w600,
                            color: isRecording ? recordRed : textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isRecording
                    ? t.listeningForSpeech
                    : isSubmitting
                        ? t.submittingAnalysis
                        : t.tapMicToRecord,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTypography.mobileCaption,
                  height: 1.3,
                  color: isRecording ? recordRed : textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Divider(height: 1, color: AppColors.outlineMuted),
              const SizedBox(height: 6),
              Text(
                t.yourSpeechSection,
                style: ExamSystemUi.embeddedCaptionStyle
                    .copyWith(fontWeight: FontWeight.w500, letterSpacing: 0.3),
              ),
              const SizedBox(height: 4),
              Text(
                transcript.isEmpty ? t.transcriptPlaceholder : transcript,
                style: TextStyle(
                  fontSize: AppTypography.mobileBody,
                  color: transcript.isEmpty ? textMuted : textMain,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? AppSpacing.s3 : AppSpacing.s5),
      child: Column(
        children: [
          // 1) Câu cần đọc to
          AppCard(
            variant: AppCardVariant.outline,
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 16, color: AppColors.textMuted),
                    const SizedBox(width: AppSpacing.s2),
                    Expanded(
                      child: Text(sentence.speaker,
                          style: StudentMobileUi.caption(context)),
                    ),
                    _LevelPill(
                      label: _localizedLevelLabel(t, _set?.level ?? 'Beginner'),
                      color: AppSkillColors.speaking.color,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s5),
                _buildTappableScript(context, sentence.script),
                if (sentence.phoneticScript.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s3),
                  Text(
                    sentence.phoneticScript,
                    style: StudentMobileUi.body(context).copyWith(
                        color: AppColors.textMuted, fontFamily: 'NotoSans'),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s4),

          // 2) Điều khiển luyện tập — nghe mẫu + ghi âm (§12 audio)
          AppCard(
            variant: AppCardVariant.outline,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: AppColors.surfaceCard,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: (isRecording || isSubmitting)
                                ? null
                                : _togglePlay,
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: playSize,
                              height: playSize,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.outline),
                              ),
                              child: Icon(
                                _isPlaying
                                    ? Icons.stop_rounded
                                    : Icons.volume_up_rounded,
                                color: AppColors.textPrimary,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s2),
                        Text(t.sampleListen,
                            style: StudentMobileUi.caption(context)
                                .copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        micButton,
                        const SizedBox(height: AppSpacing.s2),
                        Text(
                          t.yourTurn,
                          style: StudentMobileUi.caption(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: isRecording
                                ? recordRed
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  isRecording
                      ? t.listeningForSpeech
                      : isSubmitting
                          ? t.submittingAnalysis
                          : t.tapMicToRecord,
                  textAlign: TextAlign.center,
                  style: StudentMobileUi.body(context).copyWith(
                    color: isRecording ? recordRed : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          // 3) Bài nói của bạn + điểm
          AppCard(
            variant: AppCardVariant.outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.yourSpeechSection,
                  style: StudentMobileUi.caption(context).copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  transcript.isEmpty ? t.transcriptPlaceholder : transcript,
                  style: StudentMobileUi.bodyLg(context).copyWith(
                    color: transcript.isEmpty
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
                if (score != null) ...[
                  const SizedBox(height: AppSpacing.s4),
                  const Divider(height: 1, color: AppColors.outlineMuted),
                  const SizedBox(height: AppSpacing.s4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.accuracyLabel,
                          style: StudentMobileUi.cardTitle(context)),
                      _ScorePill(
                        scoreText: '$score%',
                        bg: score >= 80
                            ? AppColors.successBg
                            : AppColors.warningBg,
                        fg: score >= 80
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTappableScript(BuildContext context, String script) {
    final compact = widget.embedded;
    final examCompact = _examCompact;
    final words = script.split(' ');
    final List<Widget> wordWidgets = [];
    final textStyle = TextStyle(
      fontSize: examCompact
          ? AppTypography.mobileBodyLg
          : (compact ? AppTypography.mobileH1 : AppTypography.mobileDisplay),
      height: 1.4,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    );

    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r"[.,!?]"), "");
      wordWidgets.add(
        InkWell(
          onTap: () {
            if (cleanWord.isNotEmpty) _showWordDialog(cleanWord);
          },
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
            child: Text(word, style: textStyle),
          ),
        ),
      );
    }
    return Wrap(
        spacing: 4.0,
        runSpacing: 4.0,
        alignment: WrapAlignment.center,
        children: wordWidgets);
  }
}

// --- STYLED WIDGETS (Giữ nguyên UI của bạn) ---

class _ShadcnCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  const _ShadcnCard({required this.child, this.padding, this.radius = 12});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.outline),
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
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: AppTypography.mobileCaption, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String scoreText;
  final Color bg;
  final Color fg;
  const _ScorePill(
      {required this.scoreText, required this.bg, required this.fg});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(AppRadius.input)),
      child: Text(scoreText,
          style:
              TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: AppTypography.mobileBody)),
    );
  }
}

// --- LOGIC HELPER ---

String _normalizeText(String s) =>
    s.toLowerCase().replaceAll(RegExp(r"[.,!?]"), "").trim();

double _calculateWer(String ref, String hyp) {
  final r = _normalizeText(ref)
      .split(RegExp(r"\s+"))
      .where((e) => e.isNotEmpty)
      .toList();
  final h = _normalizeText(hyp)
      .split(RegExp(r"\s+"))
      .where((e) => e.isNotEmpty)
      .toList();
  if (r.isEmpty) return h.isEmpty ? 0.0 : 1.0;
  final dp =
      List.generate(r.length + 1, (_) => List<int>.filled(h.length + 1, 0));
  for (int i = 0; i < r.length + 1; i++) {
    dp[i][0] = i;
  }
  for (int j = 0; j < h.length + 1; j++) {
    dp[0][j] = j;
  }
  for (int i = 1; i < r.length + 1; i++) {
    for (int j = 1; j < h.length + 1; j++) {
      final cost = r[i - 1] == h[j - 1] ? 0 : 1;
      dp[i][j] =
          min(dp[i - 1][j] + 1, min(dp[i][j - 1] + 1, dp[i - 1][j - 1] + cost));
    }
  }
  return dp[r.length][h.length] / r.length;
}

int _scoreFromWer(double wer) =>
    (100.0 * (1.0 - wer)).clamp(0.0, 100.0).round();
