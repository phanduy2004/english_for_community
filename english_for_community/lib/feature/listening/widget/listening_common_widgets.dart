import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class ListeningHeader extends StatelessWidget {
  final String title;
  final String? levelText; // 🔥 Đã thêm lại trường này
  final int doneCount;
  final int totalCount;

  const ListeningHeader({
    super.key,
    required this.title,
    this.levelText, // 🔥
    required this.doneCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : doneCount / totalCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [Color(0xFF18181B), Color(0xFF27272A)]),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),

          // 🔥 HIỂN THỊ LEVEL NẾU CÓ
          if (levelText != null && levelText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Text(
                    levelText!,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)
                ),
              ),
            ),

          const SizedBox(height: 6),
          Text('Completed $doneCount / $totalCount sentences', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ])),
        Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 44, height: 44,
            child: CircularProgressIndicator(value: progress, backgroundColor: Colors.white24, color: Colors.greenAccent, strokeWidth: 4),
          ),
          Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ])
      ]),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: StreamBuilder<PlayerState>(
        stream: player.playerStateStream,
        builder: (_, s) {
          final isPlaying = s.data?.playing ?? false;
          return Row(children: [
            GestureDetector(
              onTap: onTogglePlay,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(10)),
                child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (_, p) {
                final pos = p.data?.inMilliseconds ?? 0;
                final dur = player.duration?.inMilliseconds ?? 1;
                return SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: (pos / dur).clamp(0.0, 1.0),
                    activeColor: primary,
                    onChanged: (v) => onSeek(Duration(milliseconds: (dur * v).round())),
                  ),
                );
              },
            )),
          ]);
        },
      ),
    );
  }
}

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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(count, (i) {
          final isSel = i == selectedIndex;
          final isDone = completedIdx.contains(i);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: isSel ? Theme.of(context).primaryColor : (isDone ? const Color(0xFFECFDF5) : Colors.white),
                  border: Border.all(color: isSel ? Theme.of(context).primaryColor : (isDone ? const Color(0xFF86EFAC) : const Color(0xFFE4E4E7))),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text('${i + 1}', style: TextStyle(color: isSel ? Colors.white : (isDone ? const Color(0xFF15803D) : Colors.black54), fontWeight: FontWeight.bold))),
              ),
            ),
          );
        }),
      ),
    );
  }
}