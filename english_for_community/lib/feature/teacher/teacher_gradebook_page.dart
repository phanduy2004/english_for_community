import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_skeleton.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/util/file_download.dart';
import 'package:english_for_community/feature/teacher/bloc/gradebook/teacher_gradebook_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/gradebook/teacher_gradebook_event.dart';
import 'package:english_for_community/feature/teacher/bloc/gradebook/teacher_gradebook_state.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_page_scaffold.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/teacher_classroom_detail_page.dart';
import 'package:english_for_community/feature/teacher/teacher_dashboard_page.dart';
import 'package:english_for_community/feature/teacher/teacher_gradebook_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';

class TeacherGradebookPage extends StatelessWidget {
  const TeacherGradebookPage({super.key, required this.classroomId});

  final String classroomId;

  static const String routePathPrefix = '/teacher/classroom';
  static String routePath(String classroomId) => '$routePathPrefix/$classroomId/gradebook';
  static const String routeName = 'TeacherGradebookPage';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TeacherGradebookBloc>(param1: classroomId)
        ..add(const TeacherGradebookLoadRequested()),
      child: _TeacherGradebookView(classroomId: classroomId),
    );
  }
}

class _TeacherGradebookView extends StatelessWidget {
  const _TeacherGradebookView({required this.classroomId});

  final String classroomId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<TeacherGradebookBloc, TeacherGradebookState>(
      listenWhen: (prev, curr) =>
          (curr.errorMessage != null && prev.errorMessage != curr.errorMessage) ||
          (curr.lastExportCsv != null && prev.lastExportCsv != curr.lastExportCsv),
      listener: (context, state) async {
        final err = state.errorMessage;
        if (err != null) {
          AppCornerToast.show(context, err, error: true);
          return;
        }
        final csv = state.lastExportCsv;
        if (csv == null) return;
        final data = state.data;
        final name = (data?['classroom'] is Map)
            ? '${((data!['classroom'] as Map)['name'] as String?) ?? 'gradebook'}-gradebook.csv'
            : 'gradebook.csv';
        if (kIsWeb) {
          await downloadBytes(
            filename: name.replaceAll(RegExp(r'[^\w\-.]'), '_'),
            bytes: utf8.encode(csv),
            mimeType: 'text/csv;charset=utf-8',
          );
          if (!context.mounted) return;
          AppCornerToast.show(context, l10n.teacherGradebookExportDownloaded);
        } else {
          await Clipboard.setData(ClipboardData(text: csv));
          if (!context.mounted) return;
          AppCornerToast.show(context, l10n.teacherGradebookExportCopied);
        }
      },
      builder: (context, state) {
        final className = (state.data?['classroom'] is Map)
            ? ((state.data!['classroom'] as Map)['name'] as String?) ?? ''
            : '';

        return TeacherPageScaffold(
          scrollable: false,
          title: l10n.teacherGradebookTitle,
          subtitle: className.isNotEmpty ? className : null,
          breadcrumbs: [
            TeacherBreadcrumb(label: l10n.teacherNavDashboard, location: TeacherDashboardPage.routePath),
            TeacherBreadcrumb(
              label: className.isNotEmpty ? className : l10n.teacherClassroomDetailTitle,
              location: '${TeacherClassroomDetailPage.routePath}/$classroomId',
            ),
            TeacherBreadcrumb(label: l10n.teacherGradebookTitle),
          ],
          actions: [
            IconButton(
              style: TeacherWebUi.compactHeaderIconStyle(),
              onPressed: () => context.read<TeacherGradebookBloc>().add(const TeacherGradebookLoadRequested()),
              icon: const Icon(Icons.refresh_outlined, size: 18),
              color: AppColors.textSecondary,
              tooltip: l10n.retry,
            ),
            TeacherOutlinedButton(
              label: l10n.teacherGradebookExport,
              icon: Icons.download_outlined,
              onPressed: state.data == null || state.exportInProgress
                  ? null
                  : () => context.read<TeacherGradebookBloc>().add(const TeacherGradebookExportCsvRequested()),
            ),
          ],
          maxWidth: TeacherWebUi.contentMaxTable,
          body: state.status == TeacherGradebookStatus.loading
              ? TeacherSkeleton.page(TeacherSkeleton.table(rows: 8))
              : state.status == TeacherGradebookStatus.error
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.errorMessage ?? '',
                            style: TeacherWebUi.webBody(context),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.s5),
                          TeacherRetryButton(
                            onPressed: () =>
                                context.read<TeacherGradebookBloc>().add(const TeacherGradebookLoadRequested()),
                          ),
                        ],
                      ),
                    )
                  : state.data != null
                      ? TeacherGradebookView(classroomId: classroomId)
                      : const SizedBox.shrink(),
        );
      },
    );
  }
}
