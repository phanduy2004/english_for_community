import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_skeleton.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/core/ui/widget/web_data_table.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/feature/teacher/bloc/exams_list/teacher_exams_list_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/exams_list/teacher_exams_list_event.dart';
import 'package:english_for_community/feature/teacher/bloc/exams_list/teacher_exams_list_filter.dart';
import 'package:english_for_community/feature/teacher/bloc/exams_list/teacher_exams_list_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_page_scaffold.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_widgets.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_dialogs.dart';
import 'package:english_for_community/feature/teacher/teacher_dashboard_page.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_editor_page.dart';
import 'package:english_for_community/feature/teacher/teacher_integrated_exam_editor_page.dart';
import 'package:english_for_community/feature/teacher/teacher_skills_exam_draft_payload.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TeacherExamsListPage extends StatelessWidget {
  const TeacherExamsListPage({super.key});

  static const String routePath = '/teacher/exams';
  static const String routeName = 'TeacherExamsListPage';

  void _reload(BuildContext context) {
    context.read<TeacherExamsListBloc>().add(const TeacherExamsListLoadRequested());
  }

  Future<bool> _confirm(BuildContext context, {required String title, required String body}) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(title)),
        ],
      ),
    );
    return ok == true;
  }

  String _examId(Map<String, dynamic> m) => (m['id'] ?? m['_id'])?.toString() ?? '';

  bool _isSkillsExam(Map<String, dynamic> m) {
    final st = m['settings'];
    if (st is! Map) return false;
    final f = st['examFormat'];
    return f == 'skills_exam' || f == 'integrated_four_skills';
  }

  Future<void> _newIntegratedDraft(BuildContext context) async {
    final l10n = context.l10n;
    final r = await getIt<TeacherExamRepository>().createExamDraft(buildTeacherSkillsExamDraftPayload(l10n));
    if (!context.mounted) return;
    r.fold(
      (f) => AppCornerToast.show(context, f.message, error: true),
      (d) {
        final m = Map<String, dynamic>.from(d as Map);
        final id = _examId(m);
        if (id.isEmpty) return;
        context.push('${TeacherIntegratedExamEditorPage.routePathPrefix}/$id/integrated-edit');
        _reload(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (_) => getIt<TeacherExamsListBloc>()..add(const TeacherExamsListLoadRequested()),
      child: BlocConsumer<TeacherExamsListBloc, TeacherExamsListState>(
        listenWhen: (p, c) => c.errorMessage != null && p.errorMessage != c.errorMessage,
        listener: (context, state) {
          if (state.errorMessage != null) {
            AppCornerToast.show(context, state.errorMessage!, error: true);
          }
        },
        builder: (context, state) => _buildScaffold(context, l10n, state),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, dynamic l10n, TeacherExamsListState state) {
    final loading = state.status == TeacherExamsListStatus.loading;
    final error = state.status == TeacherExamsListStatus.error ? state.errorMessage : null;
    final exams = state.visibleExams;

    return TeacherPageScaffold(
      scrollable: false,
      title: l10n.teacherMyExamsTitle,
      breadcrumbs: [
        TeacherBreadcrumb(label: l10n.teacherNavDashboard, location: TeacherDashboardPage.routePath),
        TeacherBreadcrumb(label: l10n.teacherNavExams),
      ],
      actions: [
        IconButton(
          style: TeacherWebUi.compactHeaderIconStyle(),
          onPressed: () => _reload(context),
          icon: const Icon(Icons.refresh_outlined, size: 18),
          color: AppColors.textSecondary,
        ),
        TeacherFilledButton(
          label: l10n.teacherExamCreateMenuLabel,
          icon: Icons.add,
          onPressed: () => _newIntegratedDraft(context),
        ),
      ],
      maxWidth: TeacherWebUi.contentMaxTable,
      body: Builder(
        builder: (context) {
          if (loading) {
            return TeacherSkeleton.page(TeacherSkeleton.table(rows: 6));
          }
          if (error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error, textAlign: TextAlign.center, style: TeacherWebUi.webBody(context)),
                  const SizedBox(height: AppSpacing.s5),
                  TeacherRetryButton(onPressed: () => _reload(context)),
                ],
              ),
            );
          }
          if (exams.isEmpty) {
            return Column(
              children: [
                _buildFilterBar(context, l10n, state),
                const SizedBox(height: AppSpacing.s5),
                Expanded(
                  child: TeacherEmptyCard(
                    message: state.exams.isEmpty ? l10n.teacherExamsListEmpty : l10n.teacherExamsFilterEmpty,
                    icon: Icons.quiz_outlined,
                    actionLabel: state.exams.isEmpty ? l10n.teacherDashboardActionNewExam : null,
                    onAction: state.exams.isEmpty ? () => _newIntegratedDraft(context) : null,
                  ),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFilterBar(context, l10n, state),
              const SizedBox(height: AppSpacing.s4),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _reload(context),
                  child: WebDataTable(
                    columns: [
                      WebTableColumn(label: l10n.teacherNavExams, flex: 4),
                      WebTableColumn(label: l10n.teacherClassColStatus, width: 130),
                      const WebTableColumn(label: '', width: 56, align: Alignment.center),
                    ],
                    rowCount: exams.length,
                    decoration: TeacherWebUi.panelDecoration(),
                    headStyle: TeacherWebUi.webTableHead(context),
                    scrollable: true,
                    scrollPadding: TeacherWebUi.pageScrollPadding(context),
                    onRowTap: (row) {
                      final exam = Map<String, dynamic>.from(exams[row] as Map);
                      final id = _examId(exam);
                      return id.isEmpty ? null : () => _openEditor(context, exam);
                    },
                    cellBuilder: (context, row, col) {
                      final exam = Map<String, dynamic>.from(exams[row] as Map);
                      return switch (col) {
                        0 => _examCell(context, l10n, exam),
                        1 => _examStatusCell(context, l10n, exam),
                        _ => _examActionMenu(context, l10n, exam),
                      };
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openEditor(BuildContext context, Map<String, dynamic> exam) {
    final id = _examId(exam);
    if (id.isEmpty) return;
    if (_isSkillsExam(exam)) {
      context.push('${TeacherIntegratedExamEditorPage.routePathPrefix}/$id/integrated-edit');
    } else {
      context.push('${TeacherExamEditorPage.routePathPrefix}/$id/edit');
    }
  }

  Widget _examCell(BuildContext context, dynamic l10n, Map<String, dynamic> exam) {
    final title = (exam['title'] as String?) ?? l10n.studentExamUnknownTitle;
    final integrated = _isSkillsExam(exam);
    final subtitle = integrated ? l10n.teacherExamSkillsBadge : null;
    return Row(
      children: [
        TeacherIconBadge(
          icon: integrated ? Icons.layers_outlined : Icons.quiz_outlined,
          color: integrated ? AppColors.secondary : AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TeacherWebUi.webBody(context).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Text(subtitle, style: TeacherWebUi.metaMuted, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _examStatusCell(BuildContext context, dynamic l10n, Map<String, dynamic> exam) {
    final st = (exam['status'] as String?) ?? '';
    final statusLabel = st == 'published'
        ? l10n.teacherExamStatusPublished
        : st == 'archived'
            ? l10n.teacherExamStatusArchived
            : l10n.teacherExamStatusDraft;
    final tone = st == 'published'
        ? TeacherStatusTone.success
        : st == 'archived'
            ? TeacherStatusTone.neutral
            : TeacherStatusTone.warning;
    return TeacherStatusPill(label: statusLabel, tone: tone);
  }

  Widget _examActionMenu(BuildContext context, dynamic l10n, Map<String, dynamic> exam) {
    final id = _examId(exam);
    final st = (exam['status'] as String?) ?? '';
    if (id.isEmpty) return const SizedBox.shrink();
    final bloc = context.read<TeacherExamsListBloc>();
    return PopupMenuButton<String>(
      tooltip: l10n.teacherExamMoreActions,
      icon: const Icon(Icons.more_horiz, size: 18, color: AppColors.textSecondary),
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      onSelected: (action) async {
        if (!context.mounted) return;
        switch (action) {
          case 'assign':
            final created = await TeacherDialogs.showAssignExam(context, examId: id);
            if (!context.mounted) return;
            if (created != null) _reload(context);
            break;
          case 'duplicate':
            bloc.add(TeacherExamsListDuplicateRequested(id));
            break;
          case 'publish':
            if (await _confirm(context, title: l10n.teacherExamPublish, body: l10n.teacherExamPublishConfirm)) {
              bloc.add(TeacherExamsListPublishRequested(id));
            }
            break;
          case 'archive':
            if (await _confirm(context, title: l10n.teacherExamArchive, body: l10n.teacherExamArchiveConfirm)) {
              bloc.add(TeacherExamsListArchiveRequested(id));
            }
            break;
          case 'restore':
            if (await _confirm(context, title: l10n.teacherExamRestore, body: l10n.teacherExamRestoreConfirm)) {
              bloc.add(TeacherExamsListRestoreRequested(id));
            }
            break;
          case 'delete':
            if (await _confirm(context, title: l10n.teacherExamDelete, body: l10n.teacherExamDeleteConfirm)) {
              bloc.add(TeacherExamsListDeleteRequested(id));
            }
            break;
        }
      },
      itemBuilder: (_) => [
        if (st == 'published')
          PopupMenuItem(
            value: 'assign',
            child: _teacherExamMenuAction(Icons.add_task_outlined, l10n.teacherAssignmentCreate),
          ),
        if (st == 'draft')
          PopupMenuItem(value: 'publish', child: _teacherExamMenuAction(Icons.publish_outlined, l10n.teacherExamPublish)),
        PopupMenuItem(value: 'duplicate', child: _teacherExamMenuAction(Icons.copy_outlined, l10n.teacherExamDuplicate)),
        if (st != 'archived')
          PopupMenuItem(value: 'archive', child: _teacherExamMenuAction(Icons.archive_outlined, l10n.teacherExamArchive)),
        if (st == 'archived')
          PopupMenuItem(value: 'restore', child: _teacherExamMenuAction(Icons.unarchive_outlined, l10n.teacherExamRestore)),
        PopupMenuItem(
          value: 'delete',
          child: _teacherExamMenuAction(Icons.delete_outline, l10n.teacherExamDelete, danger: true),
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context, dynamic l10n, TeacherExamsListState state) {
    final bloc = context.read<TeacherExamsListBloc>();
    final f = state.statusFilter;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        TeacherFilterChip(
          label: l10n.teacherExamsFilterAll,
          selected: f == TeacherExamsListStatusFilter.all,
          onSelected: () => bloc.add(const TeacherExamsListFilterChanged(TeacherExamsListStatusFilter.all)),
        ),
        TeacherFilterChip(
          label: l10n.teacherExamsFilterDraft,
          selected: f == TeacherExamsListStatusFilter.draft,
          onSelected: () => bloc.add(const TeacherExamsListFilterChanged(TeacherExamsListStatusFilter.draft)),
        ),
        TeacherFilterChip(
          label: l10n.teacherExamsFilterPublished,
          selected: f == TeacherExamsListStatusFilter.published,
          onSelected: () => bloc.add(const TeacherExamsListFilterChanged(TeacherExamsListStatusFilter.published)),
        ),
        TeacherFilterChip(
          label: l10n.teacherExamsFilterArchived,
          selected: f == TeacherExamsListStatusFilter.archived,
          onSelected: () => bloc.add(const TeacherExamsListFilterChanged(TeacherExamsListStatusFilter.archived)),
        ),
      ],
    );
  }
}

Widget _teacherExamMenuAction(IconData icon, String label, {bool danger = false}) {
  final color = danger ? AppColors.danger : AppColors.textPrimary;
  return Row(
    children: [
      Icon(icon, size: 16, color: danger ? AppColors.danger : AppColors.textSecondary),
      const SizedBox(width: AppSpacing.s3),
      Text(label, style: TextStyle(color: color)),
    ],
  );
}
