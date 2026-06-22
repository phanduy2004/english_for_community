import 'package:english_for_community/core/entity/writing_submission_entity.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/entity/writing_topic_entity.dart';
import 'package:english_for_community/feature/writing/bloc/writing_bloc.dart';
import 'package:english_for_community/feature/writing/bloc/writing_state.dart';
import 'package:english_for_community/feature/writing/writing_feedback_page.dart';
import 'package:english_for_community/feature/writing/writing_task_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/locale/l10n_context.dart';
import '../../../core/theme/app_color.dart';
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
    final t = context.l10n;
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        children: [
          // Header Modal
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.history, color: AppColors.textPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.submissionHistoryTitle, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      Text(topicName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
          const Divider(height: 1, color: AppColors.outline),

          // Body: BlocBuilder lắng nghe History State
          Expanded(
            child: BlocBuilder<WritingBloc, WritingState>(
              buildWhen: (previous, current) =>
              previous.historyStatus != current.historyStatus ||
                  previous.historyList != current.historyList,
              builder: (context, state) {
                if (state.historyStatus == WritingStatus.loading) {
                  return StudentMobileUi.runnerLoading();
                }
                if (state.historyStatus == WritingStatus.error) {
                  return WritingErrorView(message: state.historyErrorMessage ?? t.writingHistoryLoadFailed);
                }

                final list = state.historyList;
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox_outlined, size: 48, color: AppColors.outline),
                        const SizedBox(height: 12),
                        Text(t.writingNoHistoryForTopic, style: const TextStyle(color: AppColors.textSecondary)),
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
    final t = context.l10n;
    final dateStr = submission.createdAt != null
        ? "${submission.createdAt!.day}/${submission.createdAt!.month}/${submission.createdAt!.year}"
        : t.dateUnknown;

    final score = submission.score ?? 0;
    final isDraft = submission.status.toLowerCase() == 'draft';
    // Màu sắc theo điểm số
    final color = score >= 7.0 ? AppColors.success : (score >= 5.0 ? AppColors.warning : AppColors.danger);
    final bg = score >= 7.0 ? AppColors.successBg : (score >= 5.0 ? AppColors.warningBg : AppColors.dangerBg);

    return GestureDetector(
      onTap: () {
        // Đóng modal rồi mở trang chi tiết
        Navigator.pop(context);
        final isDraft = submission.status.toLowerCase() == 'draft';
        if (isDraft) {
          final topic = WritingTopicEntity(
            id: submission.topicId,
            name: submission.generatedPrompt?.title ?? t.writingTaskDefaultTitle,
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WritingTaskPage(
                topic: topic,
                selectedTaskType: submission.generatedPrompt?.taskType ?? 'Discussion',
                userId: submission.userId,
              ),
            ),
          );
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WritingFeedbackPage(submission: submission),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.card)),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          submission.generatedPrompt?.title ?? t.writingTaskDefaultTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDraft ? AppColors.warningBg : AppColors.successBg,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                          border: Border.all(
                            color: isDraft ? AppColors.warningBg : AppColors.success,
                          ),
                        ),
                        child: Text(
                          isDraft ? 'Draft' : 'Reviewed',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDraft ? AppColors.warning : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(width: 12),
                      const Icon(Icons.short_text, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(t.wordCountN(submission.wordCount ?? 0), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  )
                ],
              ),
            ),
            Icon(
              isDraft ? Icons.play_arrow_rounded : Icons.chevron_right,
              color: AppColors.outline,
            ),
          ],
        ),
      ),
    );
  }
}