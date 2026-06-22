import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:english_for_community/core/entity/reading/reading_attempt_entity.dart';
import 'package:english_for_community/core/entity/reading/reading_entity.dart';

class ReadingDetailView extends StatelessWidget {
  final ReadingAttemptEntity data;

  const ReadingDetailView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // L?y th�ng tin b�i d?c & c�u h?i t? readingDetail
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
            Text(readingTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("PASSAGE CONTENT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    readingContent,
                    style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary),
                    maxLines: 10, // Gi?i h?n d�ng ban d?u
                    overflow: TextOverflow.ellipsis,
                  ),
                  // C� th? th�m n�t "Read more" n?u mu?n
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 3. DETAILED ANSWERS REVIEW
          const Text("Detailed Review", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
                // T�m c�u tr? l?i c?a user cho c�u h?i n�y
                // (Gi? s? answers map theo questionId ho?c index)
                final userAnswer = data.answers.firstWhere(
                      (a) => a.questionId == q.id, // C?n d?m b?o QuestionEntity c� id
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
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: isCorrect ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
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
                  borderRadius: BorderRadius.circular(AppRadius.chip),
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
              bgColor = Colors.green.withValues(alpha: 0.1);
              borderColor = Colors.green;
              icon = Icons.check_circle;
              iconColor = Colors.green;
            } else if (isSelected && !isAnswerKey) {
              bgColor = Colors.red.withValues(alpha: 0.1);
              borderColor = Colors.red;
              icon = Icons.cancel;
              iconColor = Colors.red;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppRadius.input),
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
                color: AppColors.infoBg, // Light Blue
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(color: AppColors.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: AppColors.info),
                      SizedBox(width: 6),
                      Text("Explanation", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.info)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(q.feedback?.reasoning ?? '', style: const TextStyle(fontSize: 13, color: AppColors.info)),
                  if (q.feedback?.keySentence != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text("Key: \"${q.feedback!.keySentence}\"", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.info)),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
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


