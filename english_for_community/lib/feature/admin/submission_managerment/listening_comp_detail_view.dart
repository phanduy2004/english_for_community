import 'package:flutter/material.dart';
import '../../../../../../core/entity/listening_comp_entity.dart';

class ListeningCompDetailView extends StatelessWidget {
  final ListeningCompAttemptResult data;
  final ListeningCompEntity? listeningDetail;

  // Cần truyền cả kết quả làm bài (data) và chi tiết bài nghe gốc (listeningDetail)
  // để lấy danh sách câu hỏi, options và feedback giải thích.
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
            "Chi tiết bài tập không có sẵn.",
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
          // 1. HEADER STATS CARD (Giống style của Dictation)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF), // Violet Pastel
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem("Score", "${data.score.toInt()}%", const Color(0xFF7C3AED)),
                _buildVerticalLine(),
                _buildStatItem("Correct", "${data.correctCount}/${data.totalQuestions}", const Color(0xFF5B21B6)),
                _buildVerticalLine(),
                // Vì API submit hiện tại lưu durationInSeconds ở gốc Attempt, giả định data có trường này.
                // Nếu chưa có, bạn có thể truyền thêm vào từ ViewModel
                _buildStatItem("Time", _formatDuration(0), const Color(0xFF4C1D95)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. DETAILED ANSWERS REVIEW (Giống style của Reading)
          const Text(
              "Detailed Review",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              final q = questions[index];

              // 🔥 SỬA DÙNG NGOẶC VUÔNG ['questionId'] VÀ TRẢ VỀ MAP MẶC ĐỊNH
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
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withOpacity(0.7))),
      ],
    );
  }

  Widget _buildVerticalLine() {
    return Container(height: 30, width: 1, color: const Color(0xFFDDD6FE));
  }

  Widget _buildQuestionReviewItem(int index, ListeningCompQuestionEntity q, Map<String, dynamic> userAnswer) {
    // 1. Trích xuất dữ liệu an toàn từ Map
    int chosenIdx = userAnswer['chosenIndex'] ?? -1;
    bool isSkipped = chosenIdx == -1;
    bool isCorrectOverall = userAnswer['isCorrect'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // Viền tổng thể của Box: Xanh nếu đúng, Đỏ nếu sai/bỏ qua
        border: Border.all(
            color: isCorrectOverall ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2. HEADER: Số thứ tự câu hỏi và text câu hỏi
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCorrectOverall ? Colors.green : (isSkipped ? Colors.grey : Colors.red),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text("Q$index", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      q.questionText,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E293B))
                  )
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. DANH SÁCH LỰA CHỌN (A, B, C, D)
          ...List.generate(q.options.length, (optIndex) {
            bool isSelected = chosenIdx == optIndex; // Câu user đã chọn
            bool isAnswerKey = q.correctAnswerIndex == optIndex; // Câu đáp án đúng của hệ thống

            Color bgColor = Colors.transparent;
            Color borderColor = Colors.grey.shade200;
            IconData? icon;
            Color iconColor = Colors.transparent;

            // 🔥 LOGIC ĐỔ MÀU LỰA CHỌN
            if (isSelected && isAnswerKey) {
              // User chọn ĐÚNG
              bgColor = Colors.green.withOpacity(0.15);
              borderColor = Colors.green;
              icon = Icons.check_circle;
              iconColor = Colors.green;
            } else if (isSelected && !isAnswerKey) {
              // User chọn SAI (Hiển thị màu đỏ ở câu user đã đánh dấu)
              bgColor = Colors.red.withOpacity(0.1);
              borderColor = Colors.red;
              icon = Icons.cancel;
              iconColor = Colors.red;
            } else if (!isSelected && isAnswerKey) {
              // Hiển thị đáp án đúng (Khi user chọn sai câu khác hoặc bỏ trống)
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
                borderRadius: BorderRadius.circular(8),
                // Viền đậm hơn một chút nếu là câu user chọn
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
                          style: const TextStyle(fontSize: 14, color: Color(0xFF334155))
                      )
                  ),
                  if (icon != null) Icon(icon, size: 18, color: iconColor),
                ],
              ),
            );
          }),

          // 4. GIẢI THÍCH (FEEDBACK & AUDIO HINT)
          if (q.feedback != null && (q.feedback!.reasoning.isNotEmpty || q.feedback!.hintTimestampSeconds != null)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF), // Xanh nhạt
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

                  // Text giải thích
                  if (q.feedback!.reasoning.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                        q.feedback!.reasoning,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF0369A1))
                    ),
                  ],

                  // Vị trí thời gian trong Audio chứa đáp án
                  if (q.feedback!.hintTimestampSeconds != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.headphones_outlined, size: 14, color: Color(0xFF0284C7)),
                        const SizedBox(width: 4),
                        Text(
                            "Hint at: ${_formatDuration(q.feedback!.hintTimestampSeconds!)}",
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF0284C7), fontWeight: FontWeight.w600)
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

  // Hàm helper định dạng thời gian giây -> phút:giây
  String _formatDuration(int sec) {
    if (sec <= 0) return '0s';
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }
}