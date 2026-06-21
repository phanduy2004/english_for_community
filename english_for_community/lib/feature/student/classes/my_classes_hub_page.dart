import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
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
import 'package:english_for_community/feature/student/exams/exam_assignments_page.dart';
import 'package:english_for_community/feature/student/join/student_unified_join_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MyClassesHubPage extends StatelessWidget {
  const MyClassesHubPage({super.key});

  static const String routePath = '/student/classes';
  static const String routeName = 'MyClassesHubPage';

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

          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: StudentMobileUi.skillAppBar(
              context,
              title: l10n.studentClassesTitle,
              skill: SkillType.speaking,
              actions: [
                TextButton(
                  onPressed: () => context.push(ExamAssignmentsPage.routePath),
                  child: Text(l10n.studentExamsMenu),
                ),
              ],
            ),
            body: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => reload(),
              child: ListView(
                padding: StudentMobileUi.pagePadding,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  StudentUnifiedJoinCard(onClassJoined: reload),
                  const SizedBox(height: StudentMobileUi.sectionGap),
                  if (loading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: StudentMobileUi.listLoading(),
                      ),
                    )
                  else if (error != null)
                    StudentMobileUi.errorBanner(
                      message: error,
                      onRetry: reload,
                      retryLabel: l10n.retry,
                    )
                  else ...[
                    _SectionHeader(
                      title: l10n.studentMyClassesTitle,
                      count: classes.length,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    if (classes.isEmpty)
                      SizedBox(
                        height: 240,
                        child: StudentMobileUi.emptyState(
                          context,
                          icon: Icons.school_outlined,
                          lottie: AppLottiePreset.emptyClasses,
                          title: l10n.studentNoClasses,
                          body: '',
                        ),
                      )
                    else
                      ...classes.map((raw) {
                        final m = Map<String, dynamic>.from(raw as Map);
                        final id = (m['id'] ?? m['_id'])?.toString() ?? '';
                        final name = (m['name'] as String?)?.trim() ?? '';
                        final desc = (m['description'] as String?)?.trim() ?? '';
                        final teacher = _teacherLine(m);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                          child: _ClassroomTile(
                            name: name.isEmpty ? l10n.studentClassDetailTitle : name,
                            teacher: teacher.isEmpty
                                ? null
                                : l10n.studentClassTeacher(teacher),
                            description: desc,
                            onOpen: id.isEmpty ? null : () => _openClass(context, id),
                          ),
                        );
                      }),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: StudentMobileUi.sectionTitle(context)),
        if (count != null) ...[
          const SizedBox(width: AppSpacing.s3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                height: 1.2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ClassroomTile extends StatelessWidget {
  const _ClassroomTile({
    required this.name,
    required this.teacher,
    required this.description,
    required this.onOpen,
  });

  final String name;
  final String? teacher;
  final String description;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return StudentMobileUi.skillAccentCard(
      skill: SkillType.speaking,
      onTap: onOpen,
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          StudentMobileUi.skillIconBox(Icons.menu_book_rounded, size: 36, skill: SkillType.speaking),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StudentMobileUi.cardTitle(context),
                ),
                if (teacher != null) ...[
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    teacher!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StudentMobileUi.body(context),
                  ),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: StudentMobileUi.caption(context),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          Icon(Icons.chevron_right_rounded, size: 18, color: AppSkillColors.speaking.color),
        ],
      ),
    );
  }
}
