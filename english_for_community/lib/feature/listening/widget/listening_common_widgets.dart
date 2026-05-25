import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/feature/student/exams/exam_embedded_skill_scope.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

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
          borderRadius: BorderRadius.circular(12),
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
              borderRadius: BorderRadius.circular(4),
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
        borderRadius: BorderRadius.circular(16),
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
                    fontSize: 18,
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
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.onPrimary.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        levelText!.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.onPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.listeningCueProgress(doneCount, totalCount),
                  style: TextStyle(color: AppColors.onPrimary.withValues(alpha: 0.7), fontSize: 13),
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
                  fontSize: 11,
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
  final VoidCallback onTogglePlay;
  final Function(Duration) onSeek;

  const ListeningPlayer({
    super.key,
    required this.player,
    required this.onTogglePlay,
    required this.onSeek,
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: StreamBuilder<PlayerState>(
        stream: player.playerStateStream,
        builder: (_, s) {
          final isPlaying = s.data?.playing ?? false;
          return Row(
            children: [
              // Play/Pause Button
              Material(
                color: primary,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onTogglePlay,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: AppColors.onPrimary,
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Slider & Time
              Expanded(
                child: StreamBuilder<Duration>(
                  stream: player.positionStream,
                  builder: (_, p) {
                    final pos = p.data ?? Duration.zero;
                    final dur = player.duration ?? const Duration(milliseconds: 1);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            activeTrackColor: primary,
                            inactiveTrackColor: primary.withValues(alpha: 0.1),
                            thumbColor: primary,
                          ),
                          child: Slider(
                            value: (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0),
                            onChanged: (v) {
                              onSeek(Duration(milliseconds: (dur.inMilliseconds * v).round()));
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(pos), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              Text(_formatDuration(dur), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        )
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
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

  const CueSelector({
    super.key,
    required this.count,
    required this.selectedIndex,
    required this.completedIdx,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemBuilder: (context, i) {
          final isSel = i == selectedIndex;
          final isDone = completedIdx.contains(i);

          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: 40,
              decoration: BoxDecoration(
                color: isSel
                    ? Theme.of(context).primaryColor
                    : (isDone ? AppColors.successBg : AppColors.surfaceCard),
                border: Border.all(
                  color: isSel
                      ? Theme.of(context).primaryColor
                      : (isDone ? AppColors.success.withValues(alpha: 0.5) : AppColors.outline),
                  width: isSel ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: isSel ? [
                  BoxShadow(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2)
                  )
                ] : null,
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: isSel
                        ? AppColors.onPrimary
                        : (isDone ? AppColors.success : AppColors.textPrimary),
                    fontWeight: isSel || isDone ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}