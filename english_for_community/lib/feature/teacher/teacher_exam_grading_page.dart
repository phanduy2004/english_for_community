import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/feature/teacher/bloc/grading_hub/teacher_grading_hub_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/grading_hub/teacher_grading_hub_event.dart';
import 'package:english_for_community/feature/teacher/bloc/grading_hub/teacher_grading_hub_state.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_edit_assignment_dialog.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_page_scaffold.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/teacher_assignment_grading_hub_view.dart';
import 'package:english_for_community/feature/teacher/teacher_grading_hub_export.dart';
import 'package:english_for_community/feature/teacher/teacher_classroom_detail_page.dart';
import 'package:english_for_community/feature/teacher/teacher_dashboard_page.dart';
import 'package:english_for_community/feature/teacher/teacher_grading_hub_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
class TeacherExamGradingPage extends StatelessWidget {
  const TeacherExamGradingPage({super.key, required this.assignmentId});

  final String assignmentId;

  static const String routePath = '/teacher/exam-grading';
  static const String routeName = 'TeacherExamGradingPage';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TeacherGradingHubBloc>(param1: assignmentId)
        ..add(const TeacherGradingHubLoadRequested()),
      child: _TeacherExamGradingScaffold(assignmentId: assignmentId),
    );
  }
}

class _TeacherExamGradingScaffold extends StatelessWidget {
  const _TeacherExamGradingScaffold({required this.assignmentId});

  final String assignmentId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Scaffold header only rebuilds when assignment metadata changes, not on
    // every attempt-list or filter state change (which is more frequent).
    return BlocBuilder<TeacherGradingHubBloc, TeacherGradingHubState>(
      buildWhen: (prev, curr) => prev.assignment != curr.assignment,
      builder: (context, state) {
        final assignment = state.assignment;
        final examTitle = (assignment?['examTitle'] as String?)?.trim();
        final title = examTitle != null && examTitle.isNotEmpty
            ? examTitle
            : l10n.teacherExamUntitled;
        final subtitle = assignment != null
            ? TeacherGradingHubLabels.assignmentContextMeta(l10n, assignment)
            : l10n.teacherClassViewStudentAttempts;

        final classroomId = assignment?['classroomId'] as String?;
        final breadcrumbs = <TeacherBreadcrumb>[
          TeacherBreadcrumb(
            label: l10n.teacherNavDashboard,
            location: TeacherDashboardPage.routePath,
          ),
          if (classroomId != null && (assignment?['classroomName'] as String?)?.isNotEmpty == true)
            TeacherBreadcrumb(
              label: assignment!['classroomName'] as String,
              location: '${TeacherClassroomDetailPage.routePath}/$classroomId',
            ),
          TeacherBreadcrumb(label: l10n.teacherClassViewStudentAttempts),
        ];

        return TeacherPageScaffold(
          title: title,
          subtitle: subtitle.isNotEmpty ? subtitle : null,
          showBack: true,
          breadcrumbs: breadcrumbs,
          maxWidth: TeacherWebUi.contentMaxTable,
          scrollable: false,
          actions: [
            if (assignment != null)
              Builder(
                builder: (ctx) => IconButton(
                  tooltip: ctx.l10n.teacherAssignmentEditTooltip,
                  icon: const Icon(Icons.edit_calendar_outlined),
                  onPressed: () async {
                    final id =
                        (assignment['id'] ?? assignment['_id'])?.toString() ??
                            '';
                    if (id.isEmpty) return;
                    final updated =
                        await TeacherEditAssignmentDialog.show(
                      ctx,
                      assignmentId: id,
                      assignment: assignment,
                    );
                    if (updated == true && ctx.mounted) {
                      ctx.read<TeacherGradingHubBloc>().add(
                            const TeacherGradingHubLoadRequested(),
                          );
                    }
                  },
                ),
              ),
            // Batch actions need the full state (attempts list), use a nested builder.
            BlocBuilder<TeacherGradingHubBloc, TeacherGradingHubState>(
              buildWhen: (prev, curr) =>
                  prev.visibleAttempts != curr.visibleAttempts ||
                  prev.status != curr.status,
              builder: (ctx, s) => Row(
                mainAxisSize: MainAxisSize.min,
                children: gradingHubBatchActions(ctx, s, assignmentId: assignmentId),
              ),
            ),
          ],
          body: TeacherAssignmentGradingHubView(
            assignmentId: assignmentId,
            useParentBloc: true,
            showPageHeader: false,
          ),
        );
      },
    );
  }
}

List<Widget> gradingHubBatchActions(
  BuildContext context,
  TeacherGradingHubState state, {
  required String assignmentId,
}) {
  final l10n = context.l10n;
  if (state.batchAiRunning || state.batchOpsRunning) {
    return const [
      SizedBox(child: const AppLoadingIndicator.button()),
    ];
  }
  final canExport =
      state.status == TeacherGradingHubStatus.success && state.attempts.isNotEmpty;
  return [
    IconButton(
      tooltip: l10n.teacherGradingHubExportExcel,
      onPressed: canExport
          ? () => exportAssignmentScoresExcel(context, assignmentId: assignmentId)
          : null,
      icon: const Icon(Icons.download_outlined),
    ),
    IconButton(
      tooltip: l10n.teacherGradingHubBatchAi,
      onPressed: () => context.read<TeacherGradingHubBloc>().add(const TeacherGradingHubBatchAiRequested()),
      icon: const Icon(Icons.auto_awesome_outlined),
    ),
    IconButton(
      tooltip: l10n.teacherGradingHubBatchFinalize,
      onPressed: () =>
          context.read<TeacherGradingHubBloc>().add(const TeacherGradingHubBatchFinalizeRequested()),
      icon: const Icon(Icons.done_all_outlined),
    ),
    IconButton(
      tooltip: l10n.teacherGradingHubBatchRelease,
      onPressed: () =>
          context.read<TeacherGradingHubBloc>().add(const TeacherGradingHubBatchReleaseRequested()),
      icon: const Icon(Icons.publish_outlined),
    ),
  ];
}
