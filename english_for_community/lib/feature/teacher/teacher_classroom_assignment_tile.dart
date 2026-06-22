import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/feature/student/exams/exam_assignment_card.dart';
import 'package:english_for_community/feature/teacher/teacher_assignment_grading_hub_view.dart';
import 'package:flutter/material.dart';

/// Classroom assignment row: tap opens student submissions sheet; optional live session action.
class TeacherClassroomAssignmentTile extends StatelessWidget {
  const TeacherClassroomAssignmentTile({
    super.key,
    required this.assignment,
    required this.onViewAttempts,
    this.onManageSession,
    this.onClose,
    this.onDelete,
  });

  final Map<String, dynamic> assignment;
  final VoidCallback onViewAttempts;
  final VoidCallback? onManageSession;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;

  int get _submittedCount {
    final stats = assignment['attemptStats'];
    if (stats is Map) return (stats['submitted'] as num?)?.toInt() ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final aid = assignment['id'] as String? ?? '';
    final isRealtime = (assignment['mode'] as String?) == 'realtime';
    final hasAttempts = _submittedCount > 0 || (assignment['attemptStats'] is Map);
    final isActive = (assignment['status'] as String?) != 'closed';
    final canDelete = _submittedCount == 0 && onDelete != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: ExamSystemUi.cardGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: aid.isEmpty ? null : onViewAttempts,
              borderRadius: BorderRadius.circular(ExamSystemUi.cardRadius),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ExamAssignmentCard(
                    assignment: assignment,
                    isTeacherView: true,
                    primaryActionLabel: isRealtime && onManageSession != null
                        ? l10n.examCardManageSession
                        : l10n.teacherClassOpenAttemptsList,
                    primaryActionEnabled: aid.isNotEmpty,
                    onPrimaryAction: () {
                      if (isRealtime && onManageSession != null) {
                        onManageSession!();
                      } else {
                        onViewAttempts();
                      }
                    },
                  ),
                  if (aid.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.touch_app_outlined, size: 16, color: AppColors.primary.withValues(alpha: 0.7)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              hasAttempts
                                  ? l10n.teacherClassTapToViewAttempts
                                  : l10n.teacherClassOpenAttemptsList,
                              style: ExamSystemUi.captionMuted.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (onClose != null || onDelete != null)
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_horiz, size: 20, color: AppColors.textSecondary.withValues(alpha: 0.9)),
                              padding: EdgeInsets.zero,
                              onSelected: (v) {
                                if (v == 'close') onClose?.call();
                                if (v == 'delete') onDelete?.call();
                              },
                              itemBuilder: (_) => [
                                if (isActive && onClose != null)
                                  PopupMenuItem(value: 'close', child: Text(l10n.teacherAssignmentClose)),
                                if (canDelete)
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(l10n.teacherAssignmentDelete, style: const TextStyle(color: AppColors.danger)),
                                  ),
                              ],
                            )
                          else
                            Icon(Icons.chevron_right, size: 20, color: AppColors.primary.withValues(alpha: 0.7)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Full-height bottom sheet with student attempt list for this assignment.
  static Future<void> showAttemptsSheet(
    BuildContext context, {
    required String assignmentId,
    String? examTitleHint,
  }) {
    final l10n = context.l10n;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineMuted,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 4, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.teacherClassViewStudentAttempts,
                          style: ExamSystemUi.sectionTitle(context),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TeacherAssignmentGradingHubView(
                    assignmentId: assignmentId,
                    scrollController: scrollController,
                    examTitleHint: examTitleHint,
                    padding: ExamSystemUi.pagePadding.copyWith(top: 0),
                    showPageHeader: false,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
