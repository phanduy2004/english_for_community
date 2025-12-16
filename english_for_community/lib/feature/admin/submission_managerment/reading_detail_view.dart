import 'package:flutter/material.dart';
import '../../../../../../core/entity/reading/reading_attempt_entity.dart';
import '../../../../../../core/entity/reading/reading_entity.dart'; // Import để dùng QuestionEntity

class ReadingDetailView extends StatelessWidget {
  final ReadingAttemptEntity data;

  const ReadingDetailView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Lấy thông tin bài đọc & câu hỏi từ readingDetail
    final readingTitle = data.readingDetail?.title ?? 'Reading Passage';
    final readingContent = data.readingDetail?.content ?? '';
    final questions = data.readingDetail?.questions ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. STATS HEADER
          Row(
            children: [
              Expanded(child: _buildStatCard("Score", "${data.score.toInt()}", Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard("Correct", "${data.correctCount}/${data.totalQuestions}", Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard("Time", _formatDuration(data.durationInSeconds ?? 0), Colors.blue)),
            ],
          ),
          const SizedBox(height: 24),

          // 2. READING PASSAGE (Expandable)
          if (readingContent.isNotEmpty) ...[
            Text(readingTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("PASSAGE CONTENT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    readingContent,
                    style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF334155)),
                    maxLines: 10, // Giới hạn dòng ban đầu
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Có thể thêm nút "Read more" nếu muốn
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 3. DETAILED ANSWERS REVIEW
          const Text("Detailed Review", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),

          if (questions.isEmpty)
            const Text("Question details not available.", style: TextStyle(color: Colors.grey))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                final q = questions[index];
                // Tìm câu trả lời của user cho câu hỏi này
                // (Giả sử answers map theo questionId hoặc index)
                final userAnswer = data.answers.firstWhere(
                      (a) => a.questionId == q.id, // Cần đảm bảo QuestionEntity có id
                  orElse: () => const AnswerDetailEntity(questionId: '', chosenIndex: -1, isCorrect: false),
                );

                return _buildQuestionReviewItem(index + 1, q, userAnswer);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionReviewItem(int index, ReadingQuestionEntity q, AnswerDetailEntity userAnswer) {
    bool isCorrect = userAnswer.isCorrect;
    bool isSkipped = userAnswer.chosenIndex == -1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCorrect ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Text
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green : (isSkipped ? Colors.grey : Colors.red),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text("Q$index", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(q.questionText, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
            ],
          ),
          const SizedBox(height: 16),

          // Options List
          ...List.generate(q.options.length, (optIndex) {
            bool isSelected = userAnswer.chosenIndex == optIndex;
            bool isAnswerKey = q.correctAnswerIndex == optIndex;

            Color bgColor = Colors.transparent;
            Color borderColor = Colors.grey.shade200;
            IconData? icon;
            Color iconColor = Colors.transparent;

            if (isAnswerKey) {
              bgColor = Colors.green.withOpacity(0.1);
              borderColor = Colors.green;
              icon = Icons.check_circle;
              iconColor = Colors.green;
            } else if (isSelected && !isAnswerKey) {
              bgColor = Colors.red.withOpacity(0.1);
              borderColor = Colors.red;
              icon = Icons.cancel;
              iconColor = Colors.red;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Text("${String.fromCharCode(65 + optIndex)}.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                  const SizedBox(width: 12),
                  Expanded(child: Text(q.options[optIndex], style: const TextStyle(fontSize: 14))),
                  if (icon != null) Icon(icon, size: 18, color: iconColor),
                ],
              ),
            );
          }),

          // Feedback / Explanation
          if (q.feedback != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF), // Light Blue
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFF0284C7)),
                      SizedBox(width: 6),
                      Text("Explanation", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(q.feedback?.reasoning ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF0369A1))),
                  if (q.feedback?.keySentence != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text("Key: \"${q.feedback!.keySentence}\"", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF0284C7))),
                    ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatDuration(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m}m ${s}s';
  }
}