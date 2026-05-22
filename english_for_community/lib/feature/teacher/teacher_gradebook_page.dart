import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_corner_toast.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_page_scaffold.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/teacher_classroom_detail_page.dart';
import 'package:english_for_community/feature/teacher/teacher_dashboard_page.dart';
import 'package:english_for_community/feature/teacher/teacher_gradebook_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TeacherGradebookPage extends StatefulWidget {
  const TeacherGradebookPage({super.key, required this.classroomId});

  final String classroomId;

  static const String routePathPrefix = '/teacher/classroom';
  static String routePath(String classroomId) => '$routePathPrefix/$classroomId/gradebook';
  static const String routeName = 'TeacherGradebookPage';

  @override
  State<TeacherGradebookPage> createState() => _TeacherGradebookPageState();
}

class _TeacherGradebookPageState extends State<TeacherGradebookPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await getIt<TeacherExamRepository>().getClassroomGradebook(widget.classroomId);
    if (!mounted) return;
    r.fold(
      (f) => setState(() {
        _error = f.message;
        _loading = false;
      }),
      (d) => setState(() {
        _data = d;
        _loading = false;
      }),
    );
  }

  Future<void> _exportCsv() async {
    final r = await getIt<TeacherExamRepository>().downloadClassroomGradebookCsv(widget.classroomId);
    if (!mounted) return;
    r.fold(
      (f) => TeacherCornerToast.show(context, f.message, error: true),
      (csv) async {
        await Clipboard.setData(ClipboardData(text: csv));
        if (!mounted) return;
        TeacherCornerToast.show(context, context.l10n.teacherGradebookExportCopied);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final className = (_data?['classroom'] is Map)
        ? ((_data!['classroom'] as Map)['name'] as String?) ?? ''
        : '';

    return TeacherPageScaffold(
      scrollable: false,
      title: l10n.teacherGradebookTitle,
      subtitle: className.isNotEmpty ? className : null,
      breadcrumbs: [
        TeacherBreadcrumb(label: l10n.teacherNavDashboard, location: TeacherDashboardPage.routePath),
        TeacherBreadcrumb(
          label: className.isNotEmpty ? className : l10n.teacherClassroomDetailTitle,
          location: '${TeacherClassroomDetailPage.routePath}/${widget.classroomId}',
        ),
        TeacherBreadcrumb(label: l10n.teacherGradebookTitle),
      ],
      actions: [
        IconButton(
          style: TeacherWebUi.compactHeaderIconStyle(),
          onPressed: _load,
          icon: const Icon(Icons.refresh_outlined, size: 18),
          color: AppColors.textSecondary,
          tooltip: l10n.retry,
        ),
        TeacherOutlinedButton(
          label: l10n.teacherGradebookExport,
          icon: Icons.download_outlined,
          onPressed: _data == null ? null : _exportCsv,
        ),
      ],
      maxWidth: TeacherWebUi.contentMaxTable,
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: TeacherWebUi.webBody(context), textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.s5),
                      TeacherRetryButton(onPressed: _load),
                    ],
                  ),
                )
              : TeacherGradebookView(data: _data!),
    );
  }
}
