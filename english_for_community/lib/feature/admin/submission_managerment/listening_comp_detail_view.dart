import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:english_for_community/core/entity/listening_comp_entity.dart';

class ListeningCompDetailView extends StatelessWidget {
  final ListeningCompAttemptResult data;
  final ListeningCompEntity? listeningDetail;

  // C?n truy?n c? k?t qu? l�m b�i (data) v� chi ti?t b�i nghe g?c (listeningDetail)
  // d? l?y danh s�ch c�u h?i, options v� feedback gi?i th�ch.
  const ListeningCompDetailView({
    super.key,
    required this.data,
    this.listeningDetail,
  });

  @override
  Widget build(BuildContext context) {
    if (listeningDetail == null || listeningDetail!.questions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "Chi ti?t b�i t?p kh�ng c� s?n.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final questions = listeningDetail!.questions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER STATS CARD (Gi?ng style c?a Dictation)
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
                _buildStatItem("Score", "${data.score.toInt()}%", AppColors.info),
                _buildVerticalLine(),
                _buildStatItem("Correct", "${data.correctCount}/${data.totalQuestions}", AppColors.info),
                _buildVerticalLine(),
                // V� API submit hi?n t?i luu durationInSeconds ? g?c Attempt, gi? d?nh data c� tru?ng n�y.
                // N?u chua c�, b?n c� th? truy?n th�m v�o t? ViewModel
                _buildStatItem("Time", _formatDuration(0), AppColors.info),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. DETAILED ANSWERS REVIEW (Gi?ng style c?a Reading)
          const Text(
              "Detailed Review",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              final q = questions[index];

              // ?? S?A D�NG NGO?C VU�NG ['questionId'] V� TR? V? MAP M?C �?NH
              final userAnswer = data.answers.firstWhere(
                    (a) => a['questionId']?.toString() == q.id.toString(),
                orElse: () => {
                  'questionId': q.id,
                  'chosenIndex': -1,
                  'isCorrect': false
                },
              );

              return _buildQuestionReviewItem(index + 1, q, userAnswer);
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

  Widget _buildQuestionReviewItem(int index, ListeningCompQuestionEntity q, Map<String, dynamic> userAnswer) {
    // 1. Tr�ch xu?t d? li?u an to�n t? Map
    int chosenIdx = userAnswer['chosenIndex'] ?? -1;
    bool isSkipped = chosenIdx == -1;
    bool isCorrectOverall = userAnswer['isCorrect'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        // Vi?n t?ng th? c?a Box: Xanh n?u d�ng, �? n?u sai/b? qua
        border: Border.all(
            color: isCorrectOverall ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2. HEADER: S? th? t? c�u h?i v� text c�u h?i
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCorrectOverall ? Colors.green : (isSkipped ? Colors.grey : Colors.red),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text("Q$index", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      q.questionText,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)
                  )
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. DANH S�CH L?A CH?N (A, B, C, D)
          ...List.generate(q.options.length, (optIndex) {
            bool isSelected = chosenIdx == optIndex; // C�u user d� ch?n
            bool isAnswerKey = q.correctAnswerIndex == optIndex; // C�u d�p �n d�ng c?a h? th?ng

            Color bgColor = Colors.transparent;
            Color borderColor = Colors.grey.shade200;
            IconData? icon;
            Color iconColor = Colors.transparent;

            // ?? LOGIC �? M�U L?A CH?N
            if (isSelected && isAnswerKey) {
              // User ch?n ��NG
              bgColor = Colors.green.withValues(alpha: 0.15);
              borderColor = Colors.green;
              icon = Icons.check_circle;
              iconColor = Colors.green;
            } else if (isSelected && !isAnswerKey) {
              // User ch?n SAI (Hi?n th? m�u d? ? c�u user d� d�nh d?u)
              bgColor = Colors.red.withValues(alpha: 0.1);
              borderColor = Colors.red;
              icon = Icons.cancel;
              iconColor = Colors.red;
            } else if (!isSelected && isAnswerKey) {
              // Hi?n th? d�p �n d�ng (Khi user ch?n sai c�u kh�c ho?c b? tr?ng)
              bgColor = Colors.transparent;
              borderColor = Colors.green;
              icon = Icons.check_circle_outline;
              iconColor = Colors.green;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppRadius.input),
                // Vi?n d?m hon m?t ch�t n?u l� c�u user ch?n
                border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
              ),
              child: Row(
                children: [
                  Text(
                      "${String.fromCharCode(65 + optIndex)}.",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(
                          q.options[optIndex],
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)
                      )
                  ),
                  if (icon != null) Icon(icon, size: 18, color: iconColor),
                ],
              ),
            );
          }),

          // 4. GI?I TH�CH (FEEDBACK & AUDIO HINT)
          if (q.feedback != null && (q.feedback!.reasoning.isNotEmpty || q.feedback!.hintTimestampSeconds != null)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.infoBg, // Xanh nh?t
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

                  // Text gi?i th�ch
                  if (q.feedback!.reasoning.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                        q.feedback!.reasoning,
                        style: const TextStyle(fontSize: 13, color: AppColors.info)
                    ),
                  ],

                  // V? tr� th?i gian trong Audio ch?a d�p �n
                  if (q.feedback!.hintTimestampSeconds != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.headphones_outlined, size: 14, color: AppColors.info),
                        const SizedBox(width: 4),
                        Text(
                            "Hint at: ${_formatDuration(q.feedback!.hintTimestampSeconds!)}",
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.info, fontWeight: FontWeight.w600)
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  // H�m helper d?nh d?ng th?i gian gi�y -> ph�t:gi�y
  String _formatDuration(int sec) {
    if (sec <= 0) return '0s';
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }
}


