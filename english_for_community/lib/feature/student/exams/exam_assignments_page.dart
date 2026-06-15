import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/feature/student/classes/my_classes_hub_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Hub for exams — class assignments and unified join live under [MyClassesHubPage].
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
      ),
      body: ListView(
        padding: StudentMobileUi.pagePadding,
        children: [
          StudentMobileUi.skillAccentCard(
            skill: SkillType.speaking,
            onTap: () => context.push(MyClassesHubPage.routePath),
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
                const SizedBox(height: AppSpacing.s3),
                Text(
                  l10n.studentUnifiedJoinSubtitle,
                  style: StudentMobileUi.caption(context).copyWith(height: 1.4),
                ),
                const SizedBox(height: AppSpacing.s5),
                FilledButton.icon(
                  onPressed: () => context.push(MyClassesHubPage.routePath),
                  icon: const Icon(Icons.class_outlined, size: 20),
                  label: Text(l10n.studentUnifiedJoinButton),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
