import 'package:english_for_community/core/entity/listening_comp_entity.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/listening_comp_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// In-exam panel for Listening Comprehension (MCQ + audio).
/// Does NOT submit to backend — all progress is reported via [onProgress].
/// The exam runner stores answers inline in ExamAttempt.answers[sectionId].
class ExamEmbeddedListeningCompPanel extends StatefulWidget {
  const ExamEmbeddedListeningCompPanel({
    super.key,
    required this.resourceId,
    required this.locked,
    this.reviewMode = false,
    this.initialAnswers = const {},
    this.onProgress,
  });

  final String resourceId;
  final bool locked;
  final bool reviewMode;

  /// QuestionId → chosen option index (0-based). Used to restore state.
  final Map<String, int> initialAnswers;

  /// Called whenever the student selects/changes an answer.
  /// Provides: answers map, number of answered questions, total questions.
  final void Function(Map<String, int> answers, int savedCount, int totalCount)? onProgress;

  @override
  State<ExamEmbeddedListeningCompPanel> createState() => _ExamEmbeddedListeningCompPanelState();
}

class _ExamEmbeddedListeningCompPanelState extends State<ExamEmbeddedListeningCompPanel> {
  bool _loading = true;
  String? _error;
  ListeningCompEntity? _entity;

  /// QuestionId → chosen index.
  late Map<String, int> _answers;

  late AudioPlayer _player;
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  /// Tracks how many times the audio has been fully played.
  bool _hasPlayed = false;

  @override
  void initState() {
    super.initState();
    _answers = Map<String, int>.from(widget.initialAnswers);
    _player = AudioPlayer();
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playerState = s);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _hasPlayed = true);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _load();
  }

  @override
  void didUpdateWidget(covariant ExamEmbeddedListeningCompPanel old) {
    super.didUpdateWidget(old);
    if (old.resourceId != widget.resourceId) {
      _player.stop();
      _hasPlayed = false;
      _answers = Map<String, int>.from(widget.initialAnswers);
      _load();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; _entity = null; });
    if (widget.resourceId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final r = await getIt<ListeningCompRepository>().getListeningById(widget.resourceId);
    if (!mounted) return;
    r.fold(
      (f) => setState(() { _error = f.message; _loading = false; }),
      (e) => setState(() { _entity = e; _loading = false; }),
    );
  }

  void _onAnswerSelected(String questionId, int chosenIndex) {
    if (widget.locked) return;
    setState(() => _answers[questionId] = chosenIndex);
    final total = _entity?.questions.length ?? 0;
    widget.onProgress?.call(Map<String, int>.from(_answers), _answers.length, total);
  }

  Future<void> _togglePlay() async {
    final url = _entity?.audioUrl;
    if (url == null || url.isEmpty) return;
    if (_hasPlayed) return;
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else {
      if (_playerState == PlayerState.paused) {
        await _player.resume();
      } else {
        await _player.play(UrlSource(url));
      }
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return AppCard(
        variant: AppCardVariant.outline,
        child: Column(
          children: [
            Text(_error!, style: ExamSystemUi.captionSecondary),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: Text(l10n.retry)),
          ],
        ),
      );
    }

    if (_entity == null || widget.resourceId.isEmpty) {
      return AppCard(
        variant: AppCardVariant.outline,
        child: Text(l10n.integratedExamEmbeddedNoResource, style: ExamSystemUi.captionSecondary),
      );
    }

    final entity = _entity!;
    final isPlaying = _playerState == PlayerState.playing;
    final audioDisabled = widget.locked || _hasPlayed;
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.reviewMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (entity.title.isNotEmpty) ...[
                  Text(entity.title, style: ExamSystemUi.sectionTitle(context), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    IconButton(
                      onPressed: audioDisabled ? null : _togglePlay,
                      icon: Icon(
                        _hasPlayed
                            ? Icons.play_disabled
                            : isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                        size: 40,
                        color: audioDisabled ? AppColors.textMuted : AppColors.primary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: _hasPlayed ? 1.0 : progress,
                              minHeight: 4,
                              backgroundColor: AppColors.outlineMuted,
                              color: audioDisabled ? AppColors.textMuted : AppColors.primary,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(_hasPlayed ? _duration : _position), style: ExamSystemUi.captionMuted),
                              if (_hasPlayed)
                                Text(
                                  l10n.listeningCompPlayedOnce,
                                  style: ExamSystemUi.captionMuted.copyWith(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              else
                                Text(_formatDuration(_duration), style: ExamSystemUi.captionMuted),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else if (entity.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(entity.title, style: ExamSystemUi.sectionTitle(context), maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        if (!widget.reviewMode) const SizedBox(height: 16),
        // Questions
        for (var qi = 0; qi < entity.questions.length; qi++) ...[
          if (qi > 0) const SizedBox(height: 12),
          _buildQuestion(context, qi, entity.questions[qi]),
        ],
      ],
    );
  }

  Widget _buildQuestion(BuildContext context, int index, ListeningCompQuestionEntity q) {
    final chosen = _answers[q.id];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. ${q.questionText}',
            style: ExamSystemUi.questionStem(context),
          ),
          const SizedBox(height: 10),
          if (widget.reviewMode) ...[
            Text(
              context.l10n.teacherAttemptGradeChoicesLabel,
              style: ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
          ],
          for (var oi = 0; oi < q.options.length; oi++)
            _buildOption(q, oi, q.options[oi], chosen),
        ],
      ),
    );
  }

  Widget _buildOption(ListeningCompQuestionEntity q, int optionIndex, String text, int? chosen) {
    if (widget.reviewMode) {
      final isCorrect = q.correctAnswerIndex == optionIndex;
      final isSelected = chosen == optionIndex;
      return StudentMobileUi.mcqOption(
        context: context,
        index: optionIndex,
        text: text,
        showReviewCorrect: isCorrect,
        showReviewWrong: isSelected && !isCorrect,
        margin: const EdgeInsets.only(bottom: 6),
      );
    }

    final isSelected = chosen == optionIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSelected ? AppColors.primaryTint : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.locked ? null : () => _onAnswerSelected(q.id, optionIndex),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.outlineMuted,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                      width: isSelected ? 2 : 1,
                    ),
                    color: isSelected ? AppColors.primary : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(text, style: ExamSystemUi.captionSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
