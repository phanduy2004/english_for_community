import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_skeleton.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/auth/bloc/user_bloc.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_page_scaffold.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/teacher_assignment_list_utils.dart';
import 'package:english_for_community/feature/teacher/teacher_dashboard_overview.dart';
import 'package:english_for_community/feature/teacher/teacher_integrated_exam_editor_page.dart';
import 'package:english_for_community/feature/teacher/bloc/dashboard/teacher_dashboard_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/dashboard/teacher_dashboard_event.dart';
import 'package:english_for_community/feature/teacher/bloc/dashboard/teacher_dashboard_state.dart';
import 'package:english_for_community/feature/teacher/teacher_skills_exam_draft_payload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  static const String routePath = '/teacher';
  static const String routeName = 'TeacherDashboardPage';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TeacherDashboardBloc>()..add(const TeacherDashboardLoadRequested()),
      child: const _TeacherDashboardView(),
    );
  }
}

class _TeacherDashboardView extends StatelessWidget {
  const _TeacherDashboardView();

  void _reload(BuildContext context) {
    context.read<TeacherDashboardBloc>().add(const TeacherDashboardLoadRequested());
  }

  Future<void> _createClass(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.teacherClassCreateTitle),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(labelText: context.l10n.teacherClassNameLabel),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.l10n.save)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    final r = await getIt<TeacherExamRepository>().createClassroom(name: name);
    r.fold(
      (f) => AppCornerToast.show(context, f.message, error: true),
      (_) {
        AppCornerToast.show(context, context.l10n.teacherClassCreated);
        _reload(context);
      },
    );
    nameCtrl.dispose();
  }

  int _memberCount(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  int _realtimeAssignmentCount(List<dynamic> assignments) {
    return assignments.where((raw) {
      final m = Map<String, dynamic>.from(raw as Map);
      return TeacherAssignmentListUtils.hasOngoingLiveSession(m);
    }).length;
  }

  int _activeAssignmentCount(List<dynamic> assignments) {
    return assignments.where((raw) {
      final m = Map<String, dynamic>.from(raw as Map);
      return TeacherAssignmentListUtils.isActiveListItem(m);
    }).length;
  }

  Future<void> _newSkillsExam(BuildContext context) async {
    final l10n = context.l10n;
    final r = await getIt<TeacherExamRepository>().createExamDraft(buildTeacherSkillsExamDraftPayload(l10n));
    if (!context.mounted) return;
    r.fold(
      (f) => AppCornerToast.show(context, f.message, error: true),
      (d) {
        final m = Map<String, dynamic>.from(d as Map);
        final id = (m['id'] ?? m['_id'])?.toString() ?? '';
        if (id.isEmpty) return;
        context.push('${TeacherIntegratedExamEditorPage.routePathPrefix}/$id/integrated-edit');
        _reload(context);
      },
    );
  }

  String _greetingName(BuildContext context) {
    final user = context.read<UserBloc>().state.userEntity;
    final name = user?.fullName.trim();
    if (name != null && name.isNotEmpty) return name;
    return context.l10n.teacherDashboardStudentUnknown;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final nowLabel = DateFormat.Hm(locale).format(DateTime.now());

    return BlocConsumer<TeacherDashboardBloc, TeacherDashboardState>(
      listenWhen: (prev, curr) => curr.errorMessage != null && prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        final msg = state.errorMessage;
        if (msg == null) return;
        AppCornerToast.show(context, msg, error: true);
      },
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.errorMessage != curr.errorMessage ||
          prev.classrooms != curr.classrooms ||
          prev.exams != curr.exams ||
          prev.gradingQueue != curr.gradingQueue ||
          prev.assignments != curr.assignments ||
          prev.actionItems != curr.actionItems ||
          prev.gradingLoading != curr.gradingLoading ||
          prev.mutationInProgress != curr.mutationInProgress,
      builder: (context, state) {
        final loading = state.status == TeacherDashboardStatus.loading && state.classrooms.isEmpty;
        final error = state.status == TeacherDashboardStatus.error ? state.errorMessage : null;

        return TeacherPageScaffold(
          scrollable: false,
          title: l10n.teacherDashboardGreeting(_greetingName(context)),
          subtitle: '${l10n.teacherDashboardSubtitle} · ${l10n.teacherDashboardTodayMeta(nowLabel)}',
          actions: [
            IconButton(
              style: TeacherWebUi.compactHeaderIconStyle(),
              onPressed: () => _reload(context),
              icon: const Icon(Icons.refresh_outlined, size: 18),
              color: AppColors.textSecondary,
              tooltip: l10n.retry,
            ),
            OutlinedButton.icon(
              style: TeacherWebUi.compactOutlinedStyle(context),
              onPressed: () => _createClass(context),
              icon: const Icon(Icons.groups_outlined, size: 16),
              label: Text(l10n.teacherClassCreateTitle),
            ),
            FilledButton.icon(
              style: TeacherWebUi.compactFilledStyle(context),
              onPressed: () => _newSkillsExam(context),
              icon: const Icon(Icons.add, size: 16),
              label: Text(l10n.teacherDashboardActionNewExam),
            ),
          ],
          body: Builder(
            builder: (context) {
              if (loading) {
                return TeacherSkeleton.page(TeacherSkeleton.dashboard());
              }
              if (error != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s7),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(error, textAlign: TextAlign.center, style: TeacherWebUi.webBody(context)),
                        const SizedBox(height: AppSpacing.s5),
                        TeacherRetryButton(onPressed: () => _reload(context)),
                      ],
                    ),
                  ),
                );
              }

              final stats = computeTeacherDashboardStats(
                classrooms: state.classrooms,
                exams: state.exams,
                gradingQueue: state.gradingQueue,
                actionItems: state.actionItems,
                memberCount: _memberCount,
              );

              return TeacherDashboardOverviewBody(
                l10n: l10n,
                stats: stats,
                classrooms: state.classrooms,
                needsActionCount: state.gradingQueue.length,
                liveCount: _realtimeAssignmentCount(state.assignments),
                activeAssignmentCount: _activeAssignmentCount(state.assignments),
                onCreateClass: () => _createClass(context),
                memberCount: _memberCount,
              );
            },
          ),
        );
      },
    );
  }
}
