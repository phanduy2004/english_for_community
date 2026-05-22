import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/feature/teacher/bloc/exams_list/teacher_exams_list_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/exams_list/teacher_exams_list_event.dart';
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

enum _ExamStatusFilter { all, draft, published, archived }

class TeacherExamsListPage extends StatefulWidget {
  const TeacherExamsListPage({super.key});

  static const String routePath = '/teacher/exams';
  static const String routeName = 'TeacherExamsListPage';

  @override
  State<TeacherExamsListPage> createState() => _TeacherExamsListPageState();
}

class _TeacherExamsListPageState extends State<TeacherExamsListPage> {
  _ExamStatusFilter _filter = _ExamStatusFilter.all;

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

  List<dynamic> _filteredExams(List<dynamic> exams) {
    if (_filter == _ExamStatusFilter.all) return exams;
    final want = switch (_filter) {
      _ExamStatusFilter.draft => 'draft',
      _ExamStatusFilter.published => 'published',
      _ExamStatusFilter.archived => 'archived',
      _ => '',
    };
    return exams.where((raw) => (Map<String, dynamic>.from(raw as Map)['status'] as String?) == want).toList();
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
      (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
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
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) => _buildScaffold(context, l10n, state),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, dynamic l10n, TeacherExamsListState state) {
    final loading = state.status == TeacherExamsListStatus.loading;
    final error = state.status == TeacherExamsListStatus.error ? state.errorMessage : null;
    final exams = _filteredExams(state.exams);

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
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator()),
            );
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
                _buildFilterBar(context, l10n),
                const SizedBox(height: AppSpacing.s5),
                Expanded(
                  child: TeacherEmptyCard(
                    message: state.exams.isEmpty ? l10n.teacherExamsListEmpty : l10n.teacherExamsFilterEmpty,
                    icon: Icons.quiz_outlined,
                  ),
                ),
              ],
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(context),
            child: ListView.separated(
              padding: TeacherWebUi.pageScrollPadding(context),
              itemCount: exams.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s3),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                    child: _buildFilterBar(context, l10n),
                  );
                }
                final m = Map<String, dynamic>.from(exams[index - 1] as Map);
                final id = _examId(m);
                final title = (m['title'] as String?) ?? l10n.studentExamUnknownTitle;
                final st = (m['status'] as String?) ?? '';
                final integrated = _isSkillsExam(m);
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
                final subtitle = integrated ? l10n.teacherExamSkillsBadge : null;

                void openEditor() {
                  if (id.isEmpty) return;
                  if (integrated) {
                    context.push('${TeacherIntegratedExamEditorPage.routePathPrefix}/$id/integrated-edit');
                  } else {
                    context.push('${TeacherExamEditorPage.routePathPrefix}/$id/edit');
                  }
                }

                final bloc = context.read<TeacherExamsListBloc>();

                return TeacherListRow(
                  onTap: id.isEmpty ? null : openEditor,
                  leading: TeacherIconBadge(
                    icon: integrated ? Icons.layers_outlined : Icons.quiz_outlined,
                    color: integrated ? AppColors.secondary : AppColors.primary,
                  ),
                  title: title,
                  subtitle: subtitle,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TeacherStatusPill(label: statusLabel, tone: tone),
                      if (st == 'published' && id.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.s3),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          onPressed: () async {
                            final created = await TeacherDialogs.showAssignExam(
                              context,
                              examId: id,
                            );
                            if (!context.mounted) return;
                            if (created != null) _reload(context);
                          },
                          icon: const Icon(Icons.add_task_outlined, size: 18),
                          label: Text(l10n.teacherAssignmentCreate),
                        ),
                      ],
                      if (id.isNotEmpty)
                        PopupMenuButton<String>(
                          tooltip: l10n.teacherExamMoreActions,
                          icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                          onSelected: (action) async {
                            if (!context.mounted) return;
                            switch (action) {
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
                          itemBuilder: (ctx) => [
                            if (st == 'draft')
                              PopupMenuItem(value: 'publish', child: Text(l10n.teacherExamPublish)),
                            PopupMenuItem(value: 'duplicate', child: Text(l10n.teacherExamDuplicate)),
                            if (st != 'archived')
                              PopupMenuItem(value: 'archive', child: Text(l10n.teacherExamArchive)),
                            if (st == 'archived')
                              PopupMenuItem(value: 'restore', child: Text(l10n.teacherExamRestore)),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(l10n.teacherExamDelete, style: const TextStyle(color: AppColors.danger)),
                            ),
                          ],
                        ),
                      const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, dynamic l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        TeacherFilterChip(
          label: l10n.teacherExamsFilterAll,
          selected: _filter == _ExamStatusFilter.all,
          onSelected: () => setState(() => _filter = _ExamStatusFilter.all),
        ),
        TeacherFilterChip(
          label: l10n.teacherExamsFilterDraft,
          selected: _filter == _ExamStatusFilter.draft,
          onSelected: () => setState(() => _filter = _ExamStatusFilter.draft),
        ),
        TeacherFilterChip(
          label: l10n.teacherExamsFilterPublished,
          selected: _filter == _ExamStatusFilter.published,
          onSelected: () => setState(() => _filter = _ExamStatusFilter.published),
        ),
        TeacherFilterChip(
          label: l10n.teacherExamsFilterArchived,
          selected: _filter == _ExamStatusFilter.archived,
          onSelected: () => setState(() => _filter = _ExamStatusFilter.archived),
        ),
      ],
    );
  }
}
