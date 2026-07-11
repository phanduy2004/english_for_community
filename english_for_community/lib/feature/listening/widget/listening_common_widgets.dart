import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/core/ui/e4c_scroll_behavior.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/feature/student/exams/exam_embedded_skill_scope.dart';
import 'package:english_for_community/feature/student/exams/exam_section_tag.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/ui/student_mobile_ui.dart';
import '../../../core/locale/l10n_context.dart';

// =============================================================================
// 1. HEADER: Hiển thị tiêu đề, độ khó và tiến độ tổng quát
// =============================================================================
class ListeningHeader extends StatelessWidget {
  final String title;
  final String? levelText;
  final int doneCount;
  final int totalCount;

  const ListeningHeader({
    super.key,
    required this.title,
    this.levelText,
    required this.doneCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : (doneCount / totalCount).clamp(0.0, 1.0);
    final compact = ExamEmbeddedSkillScope.compactOf(context);

    if (compact) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.outlineMuted, width: 0.75),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: ExamSystemUi.embeddedListTitle(context), maxLines: 2, overflow: TextOverflow.ellipsis),
            if (levelText != null && levelText!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(levelText!, style: ExamSystemUi.embeddedCaptionStyle),
            ],
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppColors.outlineMuted,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.listeningCueProgress(doneCount, totalCount),
              style: ExamSystemUi.embeddedProgressLabel(context),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: AppTypography.mobileDisplay,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                if (levelText != null && levelText!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.onPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        border: Border.all(color: AppColors.onPrimary.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        levelText!.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.onPrimary,
                          fontSize: AppTypography.mobileCaption,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.listeningCueProgress(doneCount, totalCount),
                  style: TextStyle(color: AppColors.onPrimary.withValues(alpha: 0.7), fontSize: AppTypography.mobileBody),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Progress Circle
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.onPrimary.withValues(alpha: 0.15),
                  color: AppColors.success,
                  strokeWidth: 5,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: AppColors.onPrimary,
                  fontSize: AppTypography.mobileCaption,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// =============================================================================
// 2. PLAYER: Thanh điều khiển nhạc (Play/Pause & Seek)
// =============================================================================
class ListeningPlayer extends StatelessWidget {
  final AudioPlayer player;
  final VoidCallback? onTogglePlay;
  final Function(Duration)? onSeek;
  final bool disabled;
  /// When false, shows a read-only progress bar (exam anti-cheat).
  final bool allowSeek;

  const ListeningPlayer({
    super.key,
    required this.player,
    this.onTogglePlay,
    this.onSeek,
    this.disabled = false,
    this.allowSeek = true,
  });

  // Helper để format duration (00:00)
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDisabled = disabled || onTogglePlay == null;
    final canSeek = allowSeek && !isDisabled && onSeek != null;

    return Opacity(
      opacity: isDisabled ? 0.55 : 1.0,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        border: Border.all(color: AppColors.outline),
        boxShadow: const [BoxShadow(color: AppColors.shadowCard, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: StreamBuilder<PlayerState>(
        stream: player.playerStateStream,
        builder: (_, s) {
          final isPlaying = s.data?.playing ?? false;
          final l10n = context.l10n;
          final playLabel = isPlaying ? l10n.studentAudioPause : l10n.studentAudioPlay;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: playLabel,
                    enabled: !isDisabled,
                    child: Material(
                      color: isDisabled ? AppColors.textMuted : primary,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      child: InkWell(
                        onTap: isDisabled ? null : onTogglePlay,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        child: Tooltip(
                          message: playLabel,
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            child: Icon(
                              isDisabled
                                  ? Icons.play_disabled_rounded
                                  : isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                              color: AppColors.onPrimary,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StreamBuilder<Duration>(
                      stream: player.positionStream,
                      builder: (_, p) {
                        final pos = p.data ?? Duration.zero;
                        final dur = player.duration ?? const Duration(milliseconds: 1); // audit-ignore: audio fallback divisor

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (canSeek)
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                  activeTrackColor: isDisabled ? AppColors.textMuted : primary,
                                  inactiveTrackColor: primary.withValues(alpha: 0.1),
                                  thumbColor: isDisabled ? AppColors.textMuted : primary,
                                ),
                                child: Slider(
                                  value: (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0),
                                  onChanged: (v) {
                                    onSeek?.call(Duration(milliseconds: (dur.inMilliseconds * v).round()));
                                  },
                                ),
                              )
                            else
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.xs),
                                child: LinearProgressIndicator(
                                  value: isDisabled
                                      ? 1.0
                                      : (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0),
                                  minHeight: 4,
                                  backgroundColor: primary.withValues(alpha: 0.1),
                                  color: isDisabled ? AppColors.textMuted : primary,
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(isDisabled ? dur : pos),
                                    style: StudentMobileUi.caption(context),
                                  ),
                                  if (isDisabled)
                                    Text(
                                      context.l10n.listeningCompPlayedOnce,
                                      style: StudentMobileUi.caption(context).copyWith(
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  else
                                    Text(
                                      _formatDuration(dur),
                                      style: StudentMobileUi.caption(context),
                                    ),
                                ],
                              ),
                            )
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ),
    );
  }
}

// =============================================================================
// 3. SELECTOR: Danh sách các câu (Cues) dạng số để chọn nhanh
// =============================================================================
class CueSelector extends StatelessWidget {
  final int count;
  final int selectedIndex;
  final Set<int> completedIdx;
  final Function(int) onSelect;
  final SkillColorSet? skillAccent;

  const CueSelector({
    super.key,
    required this.count,
    required this.selectedIndex,
    required this.completedIdx,
    required this.onSelect,
    this.skillAccent,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: e4cHorizontalScroll(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          primary: false,
          itemCount: count,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemBuilder: (context, i) {
            return ExamNavNumberChip(
              number: i + 1,
              selected: i == selectedIndex,
              done: completedIdx.contains(i),
              skillAccent: skillAccent,
              size: 36,
              radius: 8,
              onTap: () => onSelect(i),
            );
          },
        ),
      ),
    );
  }
}
