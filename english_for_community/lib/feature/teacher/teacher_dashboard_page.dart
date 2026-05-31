import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/feature/auth/bloc/user_bloc.dart';
import 'package:english_for_community/feature/student/exams/exam_assignment_card.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_page_scaffold.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_dashboard_queue_panel.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_widgets.dart';
import 'package:english_for_community/feature/teacher/teacher_apply_page.dart';
import 'package:english_for_community/feature/teacher/teacher_assignment_list_utils.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_dialogs.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_content_label.dart';
import 'package:english_for_community/feature/teacher/teacher_classroom_detail_page.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_attempt_grade_page.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_grading_page.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_session_console_page.dart';
import 'package:english_for_community/feature/teacher/teacher_exams_list_page.dart';
import 'package:english_for_community/feature/teacher/teacher_integrated_exam_editor_page.dart';
import 'package:english_for_community/feature/teacher/bloc/dashboard/teacher_dashboard_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/dashboard/teacher_dashboard_derived.dart';
import 'package:english_for_community/feature/teacher/bloc/dashboard/teacher_dashboard_event.dart';
import 'package:english_for_community/feature/teacher/bloc/dashboard/teacher_dashboard_state.dart';
import 'package:english_for_community/feature/teacher/bloc/dashboard/teacher_dashboard_ui.dart';
import 'package:english_for_community/feature/teacher/teacher_skills_exam_draft_payload.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<void> _copyAssignmentPublicToken(BuildContext context, Map<String, dynamic> m) async {
    final pj = m['publicJoin'];
    if (pj is! Map) return;
    final t = pj['token'] as String? ?? '';
    if (t.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: t));
    if (!context.mounted) return;
    AppCornerToast.show(context, context.l10n.dashboardPublicTokenCopied);
  }

  Future<void> _rotateAssignmentPublicLink(BuildContext context, Map<String, dynamic> m) async {
    final l10n = context.l10n;
    final id = m['id'] as String? ?? '';
    if (id.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dashboardPublicRotateLink),
        content: Text(l10n.dashboardPublicRotateConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.dashboardPublicRotateLink)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    context.read<TeacherDashboardBloc>().add(TeacherDashboardRotatePublicLinkRequested(id));
  }

  Future<void> _closeAssignmentPublic(BuildContext context, Map<String, dynamic> m) async {
    final l10n = context.l10n;
    final id = m['id'] as String? ?? '';
    if (id.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dashboardPublicCloseLink),
        content: Text(l10n.dashboardPublicCloseConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.dashboardPublicCloseLink)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    context.read<TeacherDashboardBloc>().add(TeacherDashboardCloseAssignmentRequested(id));
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
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

  String _modeLabel(BuildContext context, String mode) {
    final l10n = context.l10n;
    switch (mode) {
      case 'scheduled':
        return l10n.examModeScheduled;
      case 'realtime':
        return l10n.examModeRealtime;
      default:
        return l10n.examModeSelfPaced;
    }
  }

  int _examCountByStatus(String status, List<dynamic> exams) {
    return exams.where((raw) {
      final m = Map<String, dynamic>.from(raw as Map);
      return (m['status'] as String?) == status;
    }).length;
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

  String? _examIdFromAssignment(Map<String, dynamic> m) {
    final exam = m['examId'];
    if (exam is Map) {
      return (exam['id'] ?? exam['_id'])?.toString();
    }
    return m['examId']?.toString();
  }

  String _classNameFromAssignment(Map<String, dynamic> m) {
    final c = m['classroomId'];
    if (c is Map) {
      return (c['name'] as String?)?.trim() ?? '';
    }
    return '';
  }

  String _dateLine(BuildContext context, Map<String, dynamic> m) {
    final l10n = context.l10n;
    final cfg = m['config'];
    if (cfg is! Map) return '';
    final map = Map<String, dynamic>.from(cfg);
    final mode = m['mode'] as String? ?? '';
    final locale = Localizations.localeOf(context).toString();
    String fmt(DateTime? d) {
      if (d == null) return '';
      return DateFormat.yMMMd(locale).format(d);
    }

    if (mode == 'self_paced') {
      final due = _parseDate(map['dueAt']);
      if (due != null) return l10n.teacherDashboardDue(fmt(due));
    }
    if (mode == 'scheduled') {
      final o = _parseDate(map['opensAt']);
      final c = _parseDate(map['closesAt']);
      if (o != null && c != null) {
        return l10n.teacherDashboardWindow(fmt(o), fmt(c));
      }
    }
    return '';
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

  String _gradingChipLabel(AppLocalizations l10n, TeacherGradingQueueItem it) {
    if (it.gradingState == 'pending_manual') return l10n.teacherDashboardGradingChipManual;
    if (it.gradingState == 'pending_ai') return l10n.teacherDashboardGradingChipAi;
    if (it.gradingState == 'finalized' && !it.resultsReleased) {
      return l10n.teacherDashboardGradingChipRelease;
    }
    return it.gradingState;
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
      listenWhen: (prev, curr) =>
          curr.errorMessage != null && prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        final msg = state.errorMessage;
        if (msg == null) return;
        AppCornerToast.show(context, msg, error: true);
      },
      builder: (context, state) {
        final loading =
            state.status == TeacherDashboardStatus.loading && state.classrooms.isEmpty;
        final error =
            state.status == TeacherDashboardStatus.error ? state.errorMessage : null;
        final classrooms = state.classrooms;
        final assignments = state.assignments;
        final exams = state.exams;
        final gradingQueue = state.gradingQueue;
        final actionItems = state.actionItems;

        return TeacherPageScaffold(
      scrollable: false,
      title: l10n.teacherDashboardGreeting(_greetingName(context)),
      subtitle: l10n.teacherDashboardTodayMeta(nowLabel),
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
          icon: const Icon(Icons.add, size: 16),
          label: Text(l10n.teacherClassFab),
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
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator()),
            );
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
          return RefreshIndicator(
            onRefresh: () async {
              _reload(context);
            },
            child: ListView(
              padding: TeacherWebUi.pageScrollPadding(context),
              children: [
                _OverviewRow(
                      classCount: classrooms.length,
                      assignmentCount: _activeAssignmentCount(assignments),
                      liveCount: _realtimeAssignmentCount(assignments),
                      draftExamCount: _examCountByStatus('draft', exams),
                      publishedExamCount: _examCountByStatus('published', exams),
                      needsActionCount: gradingQueue.length,
                      gradingStillLoading: state.gradingLoading,
                    ),
                    if (actionItems != null) ...[
                      const SizedBox(height: AppSpacing.s6),
                      Text(l10n.teacherDashboardActionItems, style: TeacherWebUi.sectionTitle(context)),
                      const SizedBox(height: AppSpacing.s3),
                      _DashboardActionItemsCard(
                        data: actionItems,
                        onOpenClassroom: (id) => context.push('${TeacherClassroomDetailPage.routePath}/$id'),
                        onOpenGrading: (assignmentId) =>
                            context.push('${TeacherExamGradingPage.routePath}/$assignmentId'),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s6),
                    Text(l10n.teacherDashboardShortcuts, style: TeacherWebUi.sectionTitle(context)),
                    const SizedBox(height: AppSpacing.s3),
                    _ShortcutRow(
                      onExamBank: () => context.push(TeacherExamsListPage.routePath),
                      onNewSkills: () => _newSkillsExam(context),
                      onApply: () => context.push(TeacherApplyPage.routePath),
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    TeacherResponsiveColumns(
                      left: _DashboardGradingColumn(
                        l10n: l10n,
                        gradingLoading: state.gradingLoading,
                        gradingQueue: gradingQueue,
                        chipLabelFn: _gradingChipLabel,
                      ),
                      right: _DashboardLiveColumn(
                        l10n: l10n,
                        assignments: assignments,
                        examTitleFn: (m) => teacherDashboardExamTitleFromAssignment(
                          m,
                          fallback: l10n.studentExamUnknownTitle,
                        ),
                        classNameFn: _classNameFromAssignment,
                        onOpenConsole: (id) => context.push('${TeacherExamSessionConsolePage.routePath}/$id'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    Text(l10n.teacherMyClassrooms, style: TeacherWebUi.sectionTitle(context)),
                    const SizedBox(height: AppSpacing.s4),
                    if (classrooms.isEmpty)
                      TeacherEmptyCard(message: l10n.teacherNoClassrooms, icon: Icons.groups_2_outlined)
                    else
                      TeacherCardGrid(
                        children: classrooms.map((raw) {
                          final m = Map<String, dynamic>.from(raw as Map);
                          final id = m['id'] as String? ?? '';
                          final name = m['name'] as String? ?? '';
                          final nActive = _memberCount(m, 'memberCountActive');
                          final code = (m['inviteCode'] as String?) ?? '';
                          return _ClassroomCard(
                            name: name,
                            inviteCode: code,
                            memberLine: l10n.teacherClassroomMemberCountActive(nActive),
                            onOpen: () => context.push('/teacher/classroom/$id'),
                            onCopyCode: code.isEmpty
                                ? null
                                : () async {
                                    await Clipboard.setData(ClipboardData(text: code));
                                    if (context.mounted) {
                                      AppCornerToast.show(context, l10n.copiedToClipboard);
                                    }
                                  },
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: AppSpacing.s6),
                    Text(l10n.teacherDashboardSectionAssignments, style: TeacherWebUi.sectionTitle(context)),
                    const SizedBox(height: 6),
                    _DashboardSearchField(
                      searchQuery: state.searchQuery,
                      hintText: l10n.teacherDashboardSearchHint,
                    ),
                    const SizedBox(height: 12),
                    if (classrooms.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<String?>(
                          key: ValueKey(state.classroomFilterId),
                          initialValue: state.classroomFilterId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: l10n.teacherDashboardFilterByClass,
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.surfaceCard,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(ExamSystemUi.cardRadius),
                            ),
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(l10n.teacherDashboardAllClasses),
                            ),
                            ...classrooms.map((raw) {
                              final m = Map<String, dynamic>.from(raw as Map);
                              final id = m['id'] as String? ?? '';
                              final name = (m['name'] as String?)?.trim() ?? id;
                              return DropdownMenuItem<String?>(
                                value: id.isEmpty ? null : id,
                                child: TeacherTaggedTitleRow.fromRaw(name, compact: true, maxLines: 1),
                              );
                            }),
                          ],
                          onChanged: (v) => context
                              .read<TeacherDashboardBloc>()
                              .add(TeacherDashboardClassroomFilterChanged(v)),
                        ),
                      ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TeacherFilterChip(
                          label: l10n.teacherDashboardFilterAll,
                          selected: state.assignmentFilter == TeacherDashboardAssignmentFilter.all,
                          onSelected: () => context.read<TeacherDashboardBloc>().add(
                                const TeacherDashboardAssignmentFilterChanged(TeacherDashboardAssignmentFilter.all),
                              ),
                        ),
                        TeacherFilterChip(
                          label: l10n.examModeSelfPaced,
                          selected: state.assignmentFilter == TeacherDashboardAssignmentFilter.selfPaced,
                          onSelected: () => context.read<TeacherDashboardBloc>().add(
                                const TeacherDashboardAssignmentFilterChanged(
                                  TeacherDashboardAssignmentFilter.selfPaced,
                                ),
                              ),
                        ),
                        TeacherFilterChip(
                          label: l10n.examModeScheduled,
                          selected: state.assignmentFilter == TeacherDashboardAssignmentFilter.scheduled,
                          onSelected: () => context.read<TeacherDashboardBloc>().add(
                                const TeacherDashboardAssignmentFilterChanged(
                                  TeacherDashboardAssignmentFilter.scheduled,
                                ),
                              ),
                        ),
                        TeacherFilterChip(
                          label: l10n.examModeRealtime,
                          selected: state.assignmentFilter == TeacherDashboardAssignmentFilter.realtime,
                          onSelected: () => context.read<TeacherDashboardBloc>().add(
                                const TeacherDashboardAssignmentFilterChanged(
                                  TeacherDashboardAssignmentFilter.realtime,
                                ),
                              ),
                        ),
                        TeacherFilterChip(
                          label: l10n.teacherDashboardFilterPublic,
                          selected: state.assignmentFilter == TeacherDashboardAssignmentFilter.publicLink,
                          onSelected: () => context.read<TeacherDashboardBloc>().add(
                                const TeacherDashboardAssignmentFilterChanged(
                                  TeacherDashboardAssignmentFilter.publicLink,
                                ),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: ExamSystemUi.cardGap),
                    Builder(
                      builder: (context) {
                        final list = state.filteredAssignments;
                        if (list.isEmpty) {
                          return TeacherEmptyCard(message: l10n.teacherNoAssignments);
                        }
                        return Column(
                          children: list
                              .map(
                                (m) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _AssignmentHubCard(
                                    assignment: Map<String, dynamic>.from(m as Map),
                                    title: teacherDashboardExamTitleFromAssignment(
                                      m,
                                      fallback: l10n.studentExamUnknownTitle,
                                    ),
                                    modeLabel: _modeLabel(context, m['mode'] as String? ?? ''),
                                    audienceLabel: (m['audience'] as String?) == 'public_link'
                                        ? l10n.teacherDashboardAudiencePublic
                                        : l10n.teacherDashboardAudienceClass,
                                    dateLine: _dateLine(context, m),
                                    classLine: _classNameFromAssignment(m).isEmpty
                                        ? null
                                        : l10n.teacherDashboardClassLabel(_classNameFromAssignment(m)),
                                    isRealtime: (m['mode'] as String?) == 'realtime',
                                    onCopyPublicToken: () =>
                                        _copyAssignmentPublicToken(context, Map<String, dynamic>.from(m as Map)),
                                    onRotatePublicLink: () =>
                                        _rotateAssignmentPublicLink(context, Map<String, dynamic>.from(m as Map)),
                                    onClosePublic: () =>
                                        _closeAssignmentPublic(context, Map<String, dynamic>.from(m as Map)),
                                    onGrade: () {
                                      final id = m['id'] as String? ?? '';
                                      if (id.isNotEmpty) {
                                        context.push('${TeacherExamGradingPage.routePath}/$id');
                                      }
                                    },
                                    onConsole: () {
                                      final id = m['id'] as String? ?? '';
                                      if (id.isNotEmpty) {
                                        context.push('${TeacherExamSessionConsolePage.routePath}/$id');
                                      }
                                    },
                                    onAssign: () async {
                                      final examId = _examIdFromAssignment(m);
                                      if (examId == null || examId.isEmpty) return;
                                      final created = await TeacherDialogs.showAssignExam(
                                        context,
                                        examId: examId,
                                      );
                                      if (!context.mounted) return;
                                      if (created != null) _reload(context);
                                    },
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
          );
        },
      ),
    );
      },
    );
  }
}

class _DashboardSearchField extends StatefulWidget {
  const _DashboardSearchField({required this.searchQuery, required this.hintText});

  final String searchQuery;
  final String hintText;

  @override
  State<_DashboardSearchField> createState() => _DashboardSearchFieldState();
}

class _DashboardSearchFieldState extends State<_DashboardSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant _DashboardSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery && _controller.text != widget.searchQuery) {
      _controller.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      style: TeacherWebUi.webBody(context),
      onChanged: (v) => context.read<TeacherDashboardBloc>().add(TeacherDashboardSearchQueryChanged(v)),
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hintText,
        hintStyle: TeacherWebUi.metaMuted,
        prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ExamSystemUi.cardRadius),
          borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.45), width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ExamSystemUi.cardRadius),
          borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.45), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ExamSystemUi.cardRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.classCount,
    required this.assignmentCount,
    required this.liveCount,
    required this.draftExamCount,
    required this.publishedExamCount,
    required this.needsActionCount,
    required this.gradingStillLoading,
  });

  final int classCount;
  final int assignmentCount;
  final int liveCount;
  final int draftExamCount;
  final int publishedExamCount;
  final int needsActionCount;
  final bool gradingStillLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TeacherKpiGrid(
      children: [
        TeacherKpiCard(
          icon: Icons.groups_2_outlined,
          value: '$classCount',
          label: l10n.teacherDashboardStatClasses,
          accent: AppColors.primary,
        ),
        TeacherKpiCard(
          icon: Icons.assignment_outlined,
          value: '$assignmentCount',
          label: l10n.teacherDashboardStatAssignments,
          accent: AppColors.secondary,
        ),
        TeacherKpiCard(
          icon: Icons.sensors_outlined,
          value: '$liveCount',
          label: l10n.teacherDashboardStatLiveModes,
          accent: AppColors.tertiary,
        ),
        TeacherKpiCard(
          icon: Icons.fact_check_outlined,
          value: gradingStillLoading ? '…' : '$needsActionCount',
          label: l10n.teacherDashboardStatNeedsAction,
          accent: AppColors.warning,
        ),
        TeacherKpiCard(
          icon: Icons.edit_note_outlined,
          value: '$draftExamCount',
          label: l10n.teacherDashboardStatDraftExams,
          accent: AppColors.textSecondary,
        ),
        TeacherKpiCard(
          icon: Icons.publish_outlined,
          value: '$publishedExamCount',
          label: l10n.teacherDashboardStatPublishedExams,
          accent: AppColors.success,
        ),
      ],
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({
    required this.onExamBank,
    required this.onNewSkills,
    required this.onApply,
  });

  final VoidCallback onExamBank;
  final VoidCallback onNewSkills;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 520;
        final children = [
          _ShortcutCard(
            icon: Icons.folder_open_outlined,
            title: l10n.teacherDashboardShortcutExamBank,
            subtitle: l10n.teacherMyExamsTitle,
            onTap: onExamBank,
          ),
          _ShortcutCard(
            icon: Icons.auto_awesome_motion_outlined,
            title: l10n.teacherDashboardShortcutNewSkillsExam,
            subtitle: l10n.teacherExamNewExam,
            onTap: onNewSkills,
          ),
          _ShortcutCard(
            icon: Icons.person_add_alt_1_outlined,
            title: l10n.teacherApplyTitle,
            onTap: onApply,
          ),
        ];
        if (narrow) {
          return Column(
            children: children
                .map((w) => Padding(padding: const EdgeInsets.only(bottom: 10), child: w))
                .toList(),
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: children[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final linkStyle = TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ExamSystemUi.cardRadius),
        child: Ink(
          decoration: TeacherWebUi.cardDecoration(),
          child: SizedBox(
            height: 96,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TeacherIconBadge(icon: icon, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: TeacherWebUi.listTitle(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (subtitle != null && subtitle!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TeacherWebUi.metaMuted.copyWith(height: 1.35),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: linkStyle,
                      onPressed: onTap,
                      child: Text(l10n.teacherDashboardShortcutOpen),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardGradingColumn extends StatelessWidget {
  const _DashboardGradingColumn({
    required this.l10n,
    required this.gradingLoading,
    required this.gradingQueue,
    required this.chipLabelFn,
  });

  final AppLocalizations l10n;
  final bool gradingLoading;
  final List<TeacherGradingQueueItem> gradingQueue;
  final String Function(AppLocalizations l10n, TeacherGradingQueueItem it) chipLabelFn;

  void _openGrading(BuildContext context, TeacherGradingQueueItem it) {
    context.push(TeacherExamAttemptGradePage.location(it.assignmentId, it.attemptId));
  }

  void _openAllDialog(BuildContext context) {
    showTeacherDashboardGradingQueueDialog(
      context: context,
      title: l10n.teacherDashboardGradingQueueAllTitle,
      subtitle: l10n.teacherDashboardGradingQueueAllSubtitle(gradingQueue.length),
      itemCount: gradingQueue.length,
      itemBuilder: (ctx, i) {
        final it = gradingQueue[i];
        return _GradingQueueCard(
          item: it,
          chipLabel: chipLabelFn(l10n, it),
          onTap: () {
            Navigator.of(ctx).pop();
            _openGrading(context, it);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMore = gradingQueue.length > kTeacherDashboardGradingPreviewCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TeacherDashboardSectionHeader(
          title: l10n.teacherDashboardSectionGrading,
          count: gradingQueue.isEmpty ? null : gradingQueue.length,
          onViewAll: hasMore ? () => _openAllDialog(context) : null,
          viewAllLabel: hasMore ? l10n.teacherDashboardViewAllQueue(gradingQueue.length) : null,
        ),
        const SizedBox(height: AppSpacing.s4),
        if (gradingLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (gradingQueue.isEmpty)
          TeacherEmptyCard(message: l10n.teacherDashboardGradingEmpty, icon: Icons.fact_check_outlined)
        else
          TeacherDashboardGradingQueuePanel(
            itemCount: gradingQueue.length,
            itemBuilder: (ctx, i) {
              final it = gradingQueue[i];
              return _GradingQueueCard(
                item: it,
                chipLabel: chipLabelFn(l10n, it),
                onTap: () => _openGrading(context, it),
              );
            },
            onViewAllTap: hasMore ? () => _openAllDialog(context) : null,
          ),
      ],
    );
  }
}

class _DashboardLiveColumn extends StatelessWidget {
  const _DashboardLiveColumn({
    required this.l10n,
    required this.assignments,
    required this.examTitleFn,
    required this.classNameFn,
    required this.onOpenConsole,
  });

  final AppLocalizations l10n;
  final List<dynamic> assignments;
  final String Function(Map<String, dynamic>) examTitleFn;
  final String Function(Map<String, dynamic>) classNameFn;
  final void Function(String assignmentId) onOpenConsole;

  List<Map<String, dynamic>> get _liveAssignments => assignments
      .map((raw) => Map<String, dynamic>.from(raw as Map))
      .where(TeacherAssignmentListUtils.hasOngoingLiveSession)
      .toList();

  void _openAllDialog(BuildContext context) {
    final live = _liveAssignments;
    showTeacherDashboardLiveQueueDialog(
      context: context,
      title: l10n.teacherDashboardLiveQueueAllTitle,
      subtitle: l10n.teacherDashboardLiveQueueAllSubtitle(live.length),
      itemCount: live.length,
      itemBuilder: (ctx, i) => _LiveSessionCard(
        assignment: live[i],
        examTitleFn: examTitleFn,
        classNameFn: classNameFn,
        onOpenConsole: onOpenConsole,
        compact: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final live = _liveAssignments;
    final hasMany = live.length >= kTeacherDashboardLiveViewAllThreshold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TeacherDashboardSectionHeader(
          title: l10n.teacherDashboardSectionLive,
          count: live.isEmpty ? null : live.length,
          onViewAll: hasMany ? () => _openAllDialog(context) : null,
          viewAllLabel: hasMany ? l10n.teacherDashboardViewAllLiveQueue(live.length) : null,
        ),
        const SizedBox(height: AppSpacing.s4),
        if (live.isEmpty)
          TeacherEmptyCard(message: l10n.teacherDashboardLiveEmpty, icon: Icons.live_tv_outlined)
        else
          TeacherDashboardLiveStripPanel(
            itemCount: live.length,
            onViewAllTap: hasMany ? () => _openAllDialog(context) : null,
            itemBuilder: (ctx, i) => _LiveSessionCard(
              assignment: live[i],
              examTitleFn: examTitleFn,
              classNameFn: classNameFn,
              onOpenConsole: onOpenConsole,
              compact: true,
            ),
          ),
      ],
    );
  }
}

class _LiveSessionCard extends StatelessWidget {
  const _LiveSessionCard({
    required this.assignment,
    required this.examTitleFn,
    required this.classNameFn,
    required this.onOpenConsole,
    this.compact = true,
  });

  final Map<String, dynamic> assignment;
  final String Function(Map<String, dynamic>) examTitleFn;
  final String Function(Map<String, dynamic>) classNameFn;
  final void Function(String assignmentId) onOpenConsole;
  final bool compact;

  String _sessionStatusLabel(AppLocalizations l10n, String? status) {
    switch (status) {
      case 'lobby':
        return l10n.examCardStatusLobby;
      case 'live':
        return l10n.examCardStatusLive;
      case 'grading':
        return l10n.teacherDashboardLiveStatusGrading;
      case 'closed':
        return l10n.studentClassAssignmentClosed;
      default:
        return status ?? '';
    }
  }

  List<String> _metaLines(BuildContext context, AppLocalizations l10n, Map<String, dynamic> m) {
    final lines = <String>[];
    final className = classNameFn(m).trim();
    if (className.isNotEmpty) {
      lines.add(l10n.teacherDashboardClassLabel(className));
    }

    final assigned = ExamAssignmentCard.formatIso(context, m['assignedAt']);
    if (assigned != null) {
      lines.add(l10n.examCardAssignedAt(assigned));
    }

    final session = m['activeSession'];
    if (session is Map) {
      final sm = Map<String, dynamic>.from(session);
      final st = sm['status'] as String?;
      final statusLabel = _sessionStatusLabel(l10n, st);
      if (statusLabel.isNotEmpty) {
        lines.add(l10n.teacherDashboardLiveSessionStatus(statusLabel));
      }
      final code = (sm['roomCode'] as String?)?.trim();
      if (code != null && code.isNotEmpty) {
        lines.add(l10n.examCardRoomCode(code));
      }
      final started = ExamAssignmentCard.formatIso(context, sm['startedAt']);
      if (started != null) {
        lines.add(l10n.examCardSessionStarted(started));
      }
      final jc = sm['joinedCount'];
      if (jc is num && jc > 0) {
        lines.add(l10n.teacherExamSessionJoinedCount(jc.toInt()));
      }
    } else {
      lines.add(l10n.teacherDashboardLiveWaitingSession);
    }

    final stats = m['attemptStats'];
    if (stats is Map) {
      final submitted = (stats['submitted'] as num?)?.toInt() ?? 0;
      final inProgress = (stats['inProgress'] as num?)?.toInt() ?? 0;
      final total = (stats['total'] as num?)?.toInt() ?? 0;
      if (total > 0) {
        lines.add(l10n.examCardTeacherAttemptsSummary(submitted, inProgress, total));
      }
    }

    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final m = assignment;
    final id = m['id'] as String? ?? '';
    final summary = m['examSummary'];
    String title = examTitleFn(m);
    if (summary is Map) {
      final t = (summary['title'] as String?)?.trim();
      if (t != null && t.isNotEmpty) title = t;
    }
    final meta = _metaLines(context, l10n, m);

    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: id.isEmpty ? null : () => onOpenConsole(id),
        borderRadius: BorderRadius.circular(ExamSystemUi.cardRadius),
        child: Ink(
          decoration: TeacherWebUi.cardDecoration(),
          padding: EdgeInsets.fromLTRB(14, compact ? 10 : 14, 12, compact ? 10 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.sensors, size: 16, color: AppColors.tertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.examModeRealtime,
                      style: ExamSystemUi.captionSecondary.copyWith(
                        color: AppColors.tertiary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    onPressed: id.isEmpty ? null : () => onOpenConsole(id),
                    child: Text(l10n.teacherDashboardOpenConsole),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TeacherWebUi.listTitle(context),
              ),
              const SizedBox(height: 8),
              if (compact)
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: meta
                          .map(
                            (line) => Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                line,
                                style: TeacherWebUi.metaMuted.copyWith(fontSize: 11, height: 1.35),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                )
              else
                ...meta.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      line,
                      style: TeacherWebUi.metaMuted.copyWith(fontSize: 12, height: 1.35),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (!compact) return card;
    return SizedBox(width: 280, child: card);
  }
}

class _GradingQueueCard extends StatelessWidget {
  const _GradingQueueCard({
    required this.item,
    required this.chipLabel,
    required this.onTap,
  });

  final TeacherGradingQueueItem item;
  final String chipLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final when = item.submittedAt != null
        ? '${DateFormat.yMMMd(locale).format(item.submittedAt!)} · ${DateFormat.Hm(locale).format(item.submittedAt!)}'
        : '';
    return TeacherListRow(
      onTap: onTap,
      leading: const TeacherIconBadge(icon: Icons.grade_outlined, color: AppColors.primary),
      title: item.studentLabel,
      subtitle: '${item.assignmentTitle}${when.isNotEmpty ? '\n$when' : ''}',
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          TeacherStatusPill(label: chipLabel, tone: TeacherStatusTone.warning),
          TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.only(top: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    onPressed: onTap,
            child: Text(l10n.teacherDashboardOpenGrading),
          ),
        ],
      ),
    );
  }
}

class _ClassroomCard extends StatelessWidget {
  const _ClassroomCard({
    required this.name,
    required this.inviteCode,
    required this.memberLine,
    required this.onOpen,
    required this.onCopyCode,
  });

  final String name;
  final String inviteCode;
  final String memberLine;
  final VoidCallback onOpen;
  final VoidCallback? onCopyCode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TeacherListRow(
      onTap: onOpen,
      leading: const TeacherIconBadge(icon: Icons.class_outlined, color: AppColors.secondary),
      titleWidget: TeacherTaggedTitleRow.fromRaw(name, compact: true),
      subtitle: '${l10n.teacherInviteCode}: $inviteCode\n$memberLine',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onCopyCode != null)
            IconButton(
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
              tooltip: l10n.copyInviteCode,
              onPressed: onCopyCode,
              icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.textSecondary),
            ),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _AssignmentHubCard extends StatelessWidget {
  const _AssignmentHubCard({
    required this.assignment,
    required this.title,
    required this.modeLabel,
    required this.audienceLabel,
    required this.dateLine,
    required this.classLine,
    required this.isRealtime,
    required this.onGrade,
    required this.onConsole,
    required this.onAssign,
    this.onCopyPublicToken,
    this.onRotatePublicLink,
    this.onClosePublic,
  });

  final Map<String, dynamic> assignment;
  final String title;
  final String modeLabel;
  final String audienceLabel;
  final String dateLine;
  final String? classLine;
  final bool isRealtime;
  final VoidCallback onGrade;
  final VoidCallback onConsole;
  final VoidCallback onAssign;
  final VoidCallback? onCopyPublicToken;
  final VoidCallback? onRotatePublicLink;
  final VoidCallback? onClosePublic;

  @override
  Widget build(BuildContext context) {
    final aud = assignment['audience'] as String? ?? '';
    final st = assignment['status'] as String? ?? '';
    final showPublicOps = aud == 'public_link' && st == 'active';
    final smallBtn = TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
    );
    return DecoratedBox(
      decoration: TeacherWebUi.cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.assignment_turned_in_outlined, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TeacherWebUi.listTitle(context)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _MiniBadge(icon: Icons.schedule_outlined, text: modeLabel),
                          _MiniBadge(icon: Icons.people_outline, text: audienceLabel),
                          if (classLine != null) _MiniBadge(icon: Icons.class_outlined, text: classLine!),
                        ],
                      ),
                      if (dateLine.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(dateLine, style: TeacherWebUi.metaMuted),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 4,
              runSpacing: 0,
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  style: smallBtn,
                  onPressed: onAssign,
                  child: Text(context.l10n.teacherAssignmentWizardTitle),
                ),
                TextButton(
                  style: smallBtn,
                  onPressed: onGrade,
                  child: Text(context.l10n.teacherExamGradingGrade),
                ),
                if (isRealtime)
                  TextButton(
                    style: smallBtn,
                    onPressed: onConsole,
                    child: Text(context.l10n.teacherDashboardOpenConsole),
                  ),
                if (showPublicOps && onCopyPublicToken != null)
                  TextButton(
                    style: smallBtn,
                    onPressed: onCopyPublicToken,
                    child: Text(context.l10n.dashboardPublicCopyToken),
                  ),
                if (showPublicOps && onRotatePublicLink != null)
                  TextButton(
                    style: smallBtn,
                    onPressed: onRotatePublicLink,
                    child: Text(context.l10n.dashboardPublicRotateLink),
                  ),
                if (showPublicOps && onClosePublic != null)
                  TextButton(
                    style: smallBtn,
                    onPressed: onClosePublic,
                    child: Text(context.l10n.dashboardPublicCloseLink),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardActionItemsCard extends StatelessWidget {
  const _DashboardActionItemsCard({
    required this.data,
    required this.onOpenClassroom,
    required this.onOpenGrading,
  });

  final Map<String, dynamic> data;
  final void Function(String classroomId) onOpenClassroom;
  final void Function(String assignmentId) onOpenGrading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pending = (data['pendingJoins'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final dueSoon = (data['dueSoon'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final needsGrading = data['needsGradingCount'] as int? ?? 0;
    final df = DateFormat.yMMMd(Localizations.localeOf(context).toString());

    if (pending.isEmpty && dueSoon.isEmpty && needsGrading == 0) {
      return TeacherEmptyCard(message: l10n.teacherDashboardGradingEmpty, icon: Icons.check_circle_outline);
    }

    return Material(
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (needsGrading > 0)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.fact_check_outlined, color: AppColors.warning),
                title: Text(l10n.teacherDashboardNeedsGrading(needsGrading)),
              ),
            if (pending.isNotEmpty) ...[
              Text(l10n.teacherDashboardPendingJoins, style: TeacherWebUi.webTableHead(context)),
              const SizedBox(height: AppSpacing.s3),
              ...pending.take(5).map((p) {
                final cid = p['classroomId'] as String? ?? '';
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${p['studentName']} → ${p['classroomName']}'),
                  trailing: cid.isNotEmpty
                      ? TextButton(onPressed: () => onOpenClassroom(cid), child: Text(l10n.teacherMemberApprove))
                      : null,
                  onTap: cid.isEmpty ? null : () => onOpenClassroom(cid),
                );
              }),
            ],
            if (dueSoon.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s4),
              Text(l10n.teacherDashboardDueSoon, style: TeacherWebUi.webTableHead(context)),
              const SizedBox(height: AppSpacing.s3),
              ...dueSoon.take(5).map((d) {
                final aid = d['assignmentId'] as String? ?? '';
                final deadline = DateTime.tryParse(d['deadline'] as String? ?? '');
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(d['examTitle'] as String? ?? '—'),
                  subtitle: Text(deadline != null ? df.format(deadline.toLocal()) : ''),
                  trailing: aid.isNotEmpty
                      ? TextButton(
                          onPressed: () => onOpenGrading(aid),
                          child: Text(l10n.teacherGradingHubOpenGrade),
                        )
                      : null,
                  onTap: aid.isEmpty ? null : () => onOpenGrading(aid),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.outlineMuted,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Text(
            text,
            style: ExamSystemUi.captionMuted.copyWith(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

