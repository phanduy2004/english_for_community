import 'package:flutter/material.dart';
import '../../../../../../core/entity/speaking/speaking_set_entity.dart';
import '../../../../../../core/entity/speaking/sentence_entity.dart';

class SpeakingDetailView extends StatelessWidget {
  final SpeakingSetEntity data;

  const SpeakingDetailView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Tính điểm trung bình toàn bài
    double totalScore = 0;
    int attemptedCount = 0;

    for (var s in data.sentences) {
      if (s.history.isNotEmpty) {
        // Lấy attempt mới nhất
        final latest = s.history.last;
        if (latest.score != null) {
          // WER càng thấp càng tốt. Score = (1 - WER) * 100
          double wer = latest.score!.wer;
          double accuracy = (1.0 - wer).clamp(0.0, 1.0) * 100;
          totalScore += accuracy;
          attemptedCount++;
        }
      }
    }

    int avgScore = attemptedCount > 0 ? (totalScore / attemptedCount).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header Stats
          Row(
            children: [
              Expanded(child: _buildStatBox("Sentences", "${data.sentences.length}", Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatBox("Attempted", "$attemptedCount", Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatBox("Avg Score", "$avgScore%", Colors.green)),
            ],
          ),
          const SizedBox(height: 24),

          // List Sentences
          ...data.sentences.map((s) => _buildSentenceItem(s)),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _buildSentenceItem(SentenceEntity sentence) {
    // Tìm attempt mới nhất của câu này
    final attempt = sentence.history.isNotEmpty ? sentence.history.last : null;
    final scoreVal = attempt?.score?.wer != null
        ? ((1.0 - attempt!.score!.wer) * 100).round()
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.blue.shade100,
                child: Text("${sentence.order}", style: const TextStyle(fontSize: 12, color: Colors.blue)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(sentence.script, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
              if (scoreVal != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getScoreColor(scoreVal).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text("$scoreVal%", style: TextStyle(fontWeight: FontWeight.bold, color: _getScoreColor(scoreVal))),
                )
            ],
          ),
          if (attempt != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.mic, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    attempt.userTranscript ?? "No transcript",
                    style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
            // Nếu có audioUrl thì hiện nút Play (giả lập UI)
            if (attempt.userAudioUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.volume_up, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text("Audio recorded (${attempt.audioDurationSeconds ?? 0}s)", style: TextStyle(fontSize: 12, color: Colors.blue[700])),
                  ],
                ),
              )
          ] else
            const Padding(padding: EdgeInsets.only(top: 12), child: Text("Not attempted yet", style: TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}