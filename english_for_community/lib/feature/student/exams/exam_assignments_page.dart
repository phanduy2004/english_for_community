import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/student/classes/my_classes_hub_page.dart';
import 'package:english_for_community/feature/student/exams/public_exam_join_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Hub for **public** exams by link. Class assignments live under [MyClassesHubPage].
class ExamAssignmentsPage extends StatelessWidget {
  const ExamAssignmentsPage({super.key});

  static const String routePath = '/student/exams';
  static const String routeName = 'ExamAssignmentsPage';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: ExamSystemUi.appBar(
        context,
        title: l10n.studentExamsHubTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.link_outlined),
            iconSize: ExamSystemUi.iconSm,
            color: AppColors.textSecondary,
            tooltip: l10n.examJoinByLinkTitle,
            onPressed: () => context.push(PublicExamJoinPage.routePath),
          ),
        ],
      ),
      body: ListView(
        padding: ExamSystemUi.pagePadding,
        children: [
          AppCard(
            variant: AppCardVariant.outline,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.school_outlined, color: AppColors.primary.withValues(alpha: 0.85)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.studentExamsGoToClasses,
                          style: ExamSystemUi.listTitle(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.push(MyClassesHubPage.routePath),
                    icon: const Icon(Icons.class_outlined, size: 22),
                    label: Text(l10n.studentExamsGoToClasses),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: ExamSystemUi.sectionGap),
          AppCard(
            variant: AppCardVariant.outline,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.public, color: AppColors.secondary.withValues(alpha: 0.9)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.examJoinByLinkTitle,
                          style: ExamSystemUi.listTitle(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => context.push(PublicExamJoinPage.routePath),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    label: Text(l10n.studentClassPublicJoin),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
