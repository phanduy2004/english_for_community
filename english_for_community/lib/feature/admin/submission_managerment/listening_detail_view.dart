import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:english_for_community/core/entity/dictation_attempt_entity.dart';

class ListeningDetailView extends StatelessWidget {
  final List<DictationAttemptEntity> data;

  const ListeningDetailView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text("No data available"));

    // 1. T�nh to�n th?ng k� t?ng quan
    int totalCues = data.length;
    int correctCues = data.where((e) => e.score?.passed == true).length;
    double avgAccuracy = 0;
    int totalDuration = 0;

    for (var item in data) {
      // WER c�ng th?p c�ng t?t. Accuracy = 1 - WER
      double wer = item.score?.wer ?? 1.0;
      double acc = (1.0 - wer).clamp(0.0, 1.0);
      avgAccuracy += acc;
      totalDuration += (item.durationInSeconds ?? 0);
    }

    // Trung b�nh % d? ch�nh x�c
    int finalAccuracy = totalCues > 0 ? ((avgAccuracy / totalCues) * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2. HEADER STATS CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.infoBg, // Violet Pastel
              borderRadius: BorderRadius.circular(AppRadius.sheet),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem("Accuracy", "$finalAccuracy%", AppColors.info),
                _buildVerticalLine(),
                _buildStatItem("Completed", "$correctCues/$totalCues", AppColors.info),
                _buildVerticalLine(),
                _buildStatItem("Duration", _formatDuration(totalDuration), AppColors.info),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. TITLE LIST
          const Text("Transcript Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),

          // 4. LIST CHI TI?T C�C C�U (CUES)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = data[index];
              return _buildCueItem(index + 1, item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.7))),
      ],
    );
  }

  Widget _buildVerticalLine() {
    return Container(height: 30, width: 1, color: AppColors.outline);
  }

  Widget _buildCueItem(int index, DictationAttemptEntity item) {
    bool isPerfect = (item.score?.wer ?? 1) == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: isPerfect ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Cue Index & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Cue #$index", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPerfect ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  isPerfect ? "Perfect" : "Needs Review",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isPerfect ? Colors.green : Colors.orange),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),

          // User Input
          const Text("You wrote:", style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(item.userText ?? "---", style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),

          const SizedBox(height: 12),

          // Correct Answer (Normalized)
          const Text("Correct text:", style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(item.userTextNorm ?? "---", style: const TextStyle(fontSize: 15, color: AppColors.success, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDuration(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }
}


