import 'package:english_for_community/core/entity/writing_submission_entity.dart';
import 'package:english_for_community/feature/writing/bloc/writing_bloc.dart';
import 'package:english_for_community/feature/writing/bloc/writing_state.dart';
import 'package:english_for_community/feature/writing/writing_feedback_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Tái sử dụng ErrorView từ common widgets nếu cần, hoặc import
import 'writing_common_widgets.dart';

class HistoryModal extends StatelessWidget {
  final String topicName;
  final Color primaryColor;

  const HistoryModal({
    super.key,
    required this.topicName,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header Modal
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.history, color: Color(0xFF09090B)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Submission History', style: TextStyle(fontSize: 14, color: Color(0xFF71717A))),
                      Text(topicName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF09090B))),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE4E4E7)),

          // Body: BlocBuilder lắng nghe History State
          Expanded(
            child: BlocBuilder<WritingBloc, WritingState>(
              buildWhen: (previous, current) =>
              previous.historyStatus != current.historyStatus ||
                  previous.historyList != current.historyList,
              builder: (context, state) {
                if (state.historyStatus == WritingStatus.loading) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }
                if (state.historyStatus == WritingStatus.error) {
                  return WritingErrorView(message: state.historyErrorMessage ?? 'Failed to load history');
                }

                final list = state.historyList;
                if (list.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 48, color: Color(0xFFE4E4E7)),
                        SizedBox(height: 12),
                        Text('No history found for this topic.', style: TextStyle(color: Color(0xFF71717A))),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final sub = list[index];
                    return HistoryItemCard(
                      submission: sub,
                      primaryColor: primaryColor,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryItemCard extends StatelessWidget {
  final WritingSubmissionEntity submission;
  final Color primaryColor;

  const HistoryItemCard({super.key, required this.submission, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final dateStr = submission.createdAt != null
        ? "${submission.createdAt!.day}/${submission.createdAt!.month}/${submission.createdAt!.year}"
        : "Unknown date";

    final score = submission.score ?? 0;
    // Màu sắc theo điểm số
    final color = score >= 7.0 ? const Color(0xFF16A34A) : (score >= 5.0 ? const Color(0xFFEA580C) : const Color(0xFFDC2626));
    final bg = score >= 7.0 ? const Color(0xFFDCFCE7) : (score >= 5.0 ? const Color(0xFFFFEDD5) : const Color(0xFFFEE2E2));

    return GestureDetector(
      onTap: () {
        // Đóng modal rồi mở trang chi tiết
        Navigator.pop(context);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WritingFeedbackPage(submission: submission),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE4E4E7)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: Text(
                  score.toStringAsFixed(1),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    submission.generatedPrompt?.title ?? "Writing Task",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF09090B)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: Color(0xFF71717A)),
                      const SizedBox(width: 4),
                      Text(dateStr, style: const TextStyle(fontSize: 12, color: Color(0xFF71717A))),
                      const SizedBox(width: 12),
                      const Icon(Icons.short_text, size: 14, color: Color(0xFF71717A)),
                      const SizedBox(width: 4),
                      Text("${submission.wordCount ?? 0} words", style: const TextStyle(fontSize: 12, color: Color(0xFF71717A))),
                    ],
                  )
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFE4E4E7)),
          ],
        ),
      ),
    );
  }
}