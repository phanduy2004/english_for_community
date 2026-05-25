import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
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
      appBar: StudentMobileUi.appBar(
        context,
        title: l10n.studentExamsHubTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.link_outlined, size: 20),
            tooltip: l10n.examJoinByLinkTitle,
            onPressed: () => context.push(PublicExamJoinPage.routePath),
          ),
        ],
      ),
      body: ListView(
        padding: StudentMobileUi.pagePadding,
        children: [
          StudentMobileUi.skillAccentCard(
            skill: SkillType.speaking,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    StudentMobileUi.skillIconBox(Icons.school_outlined, size: 40, skill: SkillType.speaking),
                    const SizedBox(width: AppSpacing.s4),
                    Expanded(
                      child: Text(
                        l10n.studentExamsGoToClasses,
                        style: StudentMobileUi.cardTitle(context),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 18, color: AppSkillColors.speaking.color),
                  ],
                ),
                const SizedBox(height: AppSpacing.s5),
                FilledButton.icon(
                  onPressed: () => context.push(MyClassesHubPage.routePath),
                  icon: const Icon(Icons.class_outlined, size: 20),
                  label: Text(l10n.studentExamsGoToClasses),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: StudentMobileUi.sectionGap),
          StudentMobileUi.skillAccentCard(
            skill: SkillType.reading,
            onTap: () => context.push(PublicExamJoinPage.routePath),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    StudentMobileUi.skillIconBox(Icons.public, size: 40, skill: SkillType.reading),
                    const SizedBox(width: AppSpacing.s4),
                    Expanded(
                      child: Text(
                        l10n.examJoinByLinkTitle,
                        style: StudentMobileUi.cardTitle(context),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 18, color: AppSkillColors.reading.color),
                  ],
                ),
                const SizedBox(height: AppSpacing.s5),
                OutlinedButton.icon(
                  onPressed: () => context.push(PublicExamJoinPage.routePath),
                  icon: Icon(Icons.arrow_forward_rounded, size: 18, color: AppSkillColors.reading.color),
                  label: Text(l10n.studentClassPublicJoin),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
