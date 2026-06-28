import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/motion/app_lottie_preset.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/feature/student/bloc/classes_hub/student_classes_hub_bloc.dart';
import 'package:english_for_community/feature/student/bloc/classes_hub/student_classes_hub_event.dart';
import 'package:english_for_community/feature/student/bloc/classes_hub/student_classes_hub_state.dart';
import 'package:english_for_community/feature/student/classes/student_classroom_detail_page.dart';
import 'package:english_for_community/feature/student/classes/student_classroom_grouped_card.dart';
import 'package:english_for_community/feature/student/classes/student_classroom_hub_tile.dart';
import 'package:english_for_community/feature/student/exams/exam_assignments_page.dart';
import 'package:english_for_community/feature/student/join/student_unified_join_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MyClassesHubPage extends StatelessWidget {
  const MyClassesHubPage({super.key});

  static const String routePath = '/student/classes';
  static const String routeName = 'MyClassesHubPage';

  static SkillColorSet get _accent => AppSkillColors.speaking;

  static PreferredSizeWidget _appBar(
    BuildContext context, {
    required String title,
    required List<Widget>? actions,
  }) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(StudentMobileUi.appBarHeight + 2),
      child: Column(
        children: [
          StudentMobileUi.appBar(context, title: title, actions: actions),
          Container(
            height: 2,
            color: _accent.color.withValues(alpha: 0.65),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (_) => getIt<StudentClassesHubBloc>()..add(const StudentClassesHubLoadRequested()),
      child: BlocBuilder<StudentClassesHubBloc, StudentClassesHubState>(
        builder: (context, state) {
          void reload() {
            context.read<StudentClassesHubBloc>().add(const StudentClassesHubLoadRequested());
          }

          final loading = state.status == StudentClassesHubStatus.loading;
          final error = state.status == StudentClassesHubStatus.error ? state.errorMessage : null;
          final classes = state.classes;
          final hasClasses = classes.isNotEmpty;

          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: _appBar(
              context,
              title: l10n.studentClassesTitle,
              actions: [
                StudentMobileUi.headerIconButton(
                  context: context,
                  icon: Icons.assignment_outlined,
                  tooltip: l10n.studentExamsMenu,
                  iconColor: AppColors.info,
                  backgroundColor: AppColors.infoBg,
                  borderColor: AppColors.info.withValues(alpha: 0.22),
                  onPressed: () => context.push(ExamAssignmentsPage.routePath),
                ),
              ],
            ),
            body: RefreshIndicator(
              color: _accent.color,
              onRefresh: () async => reload(),
              child: ListView(
                padding: StudentMobileUi.pagePadding,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  StudentUnifiedJoinCard(
                    onClassJoined: reload,
                    compact: hasClasses,
                  ),
                  SizedBox(height: hasClasses ? AppSpacing.s3 : StudentMobileUi.sectionGap),
                  if (loading && classes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: StudentMobileUi.listLoading(),
                    )
                  else if (error != null)
                    StudentMobileUi.errorBanner(
                      message: error,
                      onRetry: reload,
                      retryLabel: l10n.retry,
                    )
                  else if (!hasClasses)
                    StudentMobileUi.emptyState(
                      context,
                      icon: Icons.school_outlined,
                      lottie: AppLottiePreset.emptyClasses,
                      skill: SkillType.speaking,
                      title: l10n.studentNoClasses,
                      body: l10n.studentClassesSubtitle,
                    )
                  else ...[
                    StudentMobileUi.sectionHeader(
                      context,
                      title: l10n.studentMyClassesTitle,
                    ),
                    const SizedBox(height: AppSpacing.s1),
                    Text(
                      l10n.studentClassesHubListHint(classes.length),
                      style: StudentMobileUi.caption(context),
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    StudentClassroomGroupedCard(
                      dividerIndent: StudentClassroomGroupedCard.memberDividerIndent(),
                      accentColor: _accent.color,
                      children: classes.map((raw) {
                        final m = Map<String, dynamic>.from(raw as Map);
                        final id = (m['id'] ?? m['_id'])?.toString() ?? '';
                        final name = (m['name'] as String?)?.trim() ?? '';
                        final cover = (m['coverImageUrl'] as String?)?.trim();
                        final teacher = _teacherLine(m);
                        final policy = m['joinPolicy'] as String?;
                        return StudentClassroomHubTile(
                          key: ValueKey(id),
                          name: name.isEmpty ? l10n.studentClassDetailTitle : name,
                          coverImageUrl: cover?.isNotEmpty == true ? cover : null,
                          teacherLine: teacher.isEmpty
                              ? null
                              : l10n.studentClassTeacher(teacher),
                          joinPolicy: policy,
                          onTap: id.isEmpty ? null : () => _openClass(context, id),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _teacherLine(Map<String, dynamic> m) {
    final t = m['teacherId'];
    if (t is Map) {
      final name = (t['fullName'] as String?)?.trim();
      if (name != null && name.isNotEmpty) return name;
      final un = (t['username'] as String?)?.trim();
      if (un != null && un.isNotEmpty) return un;
    }
    return '';
  }

  static void _openClass(BuildContext context, String id) {
    if (id.isEmpty) return;
    context.push('${StudentClassroomDetailPage.routePath}/$id');
  }
}
