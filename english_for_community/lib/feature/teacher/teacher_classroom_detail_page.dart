import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_page_scaffold.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_widgets.dart';
import 'package:english_for_community/feature/teacher/teacher_assignment_list_utils.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_dialogs.dart';
import 'package:english_for_community/feature/teacher/teacher_classroom_assignment_tile.dart';
import 'package:english_for_community/feature/teacher/teacher_dashboard_page.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_grading_page.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_session_console_page.dart';
import 'package:english_for_community/feature/teacher/bloc/classroom/teacher_classroom_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/classroom/teacher_classroom_event.dart';
import 'package:english_for_community/feature/teacher/bloc/classroom/teacher_classroom_state.dart';
import 'package:english_for_community/feature/teacher/teacher_gradebook_page.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TeacherClassroomDetailPage extends StatefulWidget {
  const TeacherClassroomDetailPage({super.key, required this.classroomId});

  final String classroomId;

  static const String routePath = '/teacher/classroom';
  static const String routeName = 'TeacherClassroomDetailPage';

  @override
  State<TeacherClassroomDetailPage> createState() => _TeacherClassroomDetailPageState();
}

class _TeacherClassroomDetailPageState extends State<TeacherClassroomDetailPage>
    with SingleTickerProviderStateMixin {
  final _editName = TextEditingController();
  final _editDesc = TextEditingController();
  late TabController _tabs;
  int _assignmentSegment = 0;
  /// Context under [BlocProvider] — State's own [context] is above the bloc.
  BuildContext? _blocCtx;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  TeacherClassroomBloc get _bloc {
    final ctx = _blocCtx;
    assert(ctx != null, 'TeacherClassroomBloc context not ready');
    return ctx!.read<TeacherClassroomBloc>();
  }

  void _reload({bool silent = false}) {
    _bloc.add(TeacherClassroomLoadRequested(silent: silent));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _editName.dispose();
    _editDesc.dispose();
    super.dispose();
  }

  void _saveClassroomSettings() {
    _bloc.add(
          TeacherClassroomSaveSettingsRequested(
            name: _editName.text.trim(),
            description: _editDesc.text.trim(),
          ),
        );
  }

  Future<void> _rotateClassInvite() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.teacherClassRotateInvite),
        content: Text(l10n.teacherClassRotateInviteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.teacherClassRotateInvite)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    _bloc.add(const TeacherClassroomRotateInviteRequested());
  }

  Future<void> _archiveClassroom() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.teacherClassArchive),
        content: Text(l10n.teacherClassArchiveConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.teacherClassArchive)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    _bloc.add(const TeacherClassroomArchiveRequested());
  }

  String _memberUserId(Map<String, dynamic> m) {
    final u = m['userId'];
    if (u is Map) return (u['id'] ?? u['_id'])?.toString() ?? '';
    return u?.toString() ?? '';
  }

  Future<void> _approveMember(Map<String, dynamic> m) async {
    final uid = () {
      final u = m['userId'];
      if (u is Map) return (u['id'] ?? u['_id'])?.toString() ?? '';
      return u?.toString() ?? '';
    }();
    if (uid.isEmpty) return;
    _bloc.add(TeacherClassroomApproveMemberRequested(uid));
  }

  Future<void> _rejectMember(Map<String, dynamic> m) async {
    final uid = () {
      final u = m['userId'];
      if (u is Map) return (u['id'] ?? u['_id'])?.toString() ?? '';
      return u?.toString() ?? '';
    }();
    if (uid.isEmpty) return;
    final r = await getIt<TeacherExamRepository>().rejectClassroomMember(widget.classroomId, uid);
    if (!mounted) return;
    r.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.teacherMemberRejected)));
        _reload();
      },
    );
  }

  Future<void> _removeMember(Map<String, dynamic> m) async {
    final l10n = context.l10n;
    final uid = _memberUserId(m);
    if (uid.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.teacherClassMemberRemove),
        content: Text(l10n.teacherClassMemberRemoveConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.teacherClassMemberRemove)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    _bloc.add(TeacherClassroomRemoveMemberRequested(uid));
  }

  int _memberCount(Map<String, dynamic>? m, String key) {
    if (m == null) return 0;
    final v = m[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  String? _formatDate(BuildContext context, dynamic raw) {
    if (raw == null) return null;
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return null;
    return DateFormat.yMMMd(Localizations.localeOf(context).toString()).add_jm().format(dt.toLocal());
  }

  String _joinPolicyLabel(AppLocalizations l10n, String? policy) {
    if (policy == 'approval_required') return l10n.studentClassJoinPolicyApproval;
    return l10n.studentClassJoinPolicyOpen;
  }

  List<Map<String, dynamic>> _activeAssignmentsFrom(List<dynamic> assignments) => assignments
      .map((raw) => Map<String, dynamic>.from(raw as Map))
      .where(TeacherAssignmentListUtils.isActiveListItem)
      .toList();

  List<Map<String, dynamic>> _historyAssignmentsFrom(List<dynamic> assignments) => assignments
      .map((raw) => Map<String, dynamic>.from(raw as Map))
      .where(TeacherAssignmentListUtils.isHistory)
      .toList();

  Future<void> _openSession(Map<String, dynamic> assignment) async {
    final aid = assignment['id'] as String? ?? '';
    if (aid.isEmpty || !mounted) return;
    await context.push('${TeacherExamSessionConsolePage.routePath}/$aid');
    if (mounted) _reload(silent: true);
  }

  Future<void> _openStudentAttempts(Map<String, dynamic> assignment) async {
    final aid = assignment['id'] as String? ?? '';
    if (aid.isEmpty || !mounted) return;
    await context.push('${TeacherExamGradingPage.routePath}/$aid');
    if (mounted) _reload(silent: true);
  }

  Future<void> _confirmCloseAssignment(BuildContext context, Map<String, dynamic> m) async {
    final l10n = context.l10n;
    final id = m['id'] as String? ?? '';
    if (id.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.teacherAssignmentClose),
        content: Text(l10n.teacherAssignmentCloseConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.teacherAssignmentClose)),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<TeacherClassroomBloc>().add(TeacherClassroomCloseAssignmentRequested(id));
    }
  }

  Future<void> _confirmDeleteAssignment(BuildContext context, Map<String, dynamic> m) async {
    final l10n = context.l10n;
    final id = m['id'] as String? ?? '';
    if (id.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.teacherAssignmentDelete),
        content: Text(l10n.teacherAssignmentDeleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.teacherAssignmentDelete),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<TeacherClassroomBloc>().add(TeacherClassroomDeleteAssignmentRequested(id));
    }
  }

  Future<void> _openAssignExamPicker() async {
    final l10n = context.l10n;
    final examsR = await getIt<TeacherExamRepository>().listMyExams();
    if (!mounted) return;
    await examsR.fold(
      (f) async => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
      (list) async {
        if (list.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.teacherNoExams)));
          return;
        }
        final published = <Map<String, dynamic>>[];
        for (final raw in list) {
          final m = Map<String, dynamic>.from(raw as Map);
          if ((m['status'] as String?) == 'published') published.add(m);
        }
        if (published.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.teacherNoPublishedExams)));
          return;
        }
        final picked = await showDialog<String>(
          context: context,
          builder: (ctx) => _PickExamDialog(exams: published),
        );
        if (picked == null || !mounted || picked.isEmpty) return;
        final navCtx = _blocCtx;
        if (navCtx == null || !navCtx.mounted) return;
        final created = await TeacherDialogs.showAssignExam(
          navCtx,
          examId: picked,
          initialClassroomId: widget.classroomId,
        );
        if (!mounted) return;
        if (created != null) _reload(silent: true);
      },
    );
  }

  Future<void> _copyInviteCode() async {
    final classroom = _bloc.state.classroom;
    final code = classroom?['inviteCode'] as String? ?? '';
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.copiedToClipboard)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TeacherClassroomBloc>(param1: widget.classroomId)
        ..add(const TeacherClassroomLoadRequested()),
      child: BlocConsumer<TeacherClassroomBloc, TeacherClassroomState>(
        listenWhen: (p, c) =>
            (c.classroom != null && c.classroom != p.classroom) ||
            (c.archived && !p.archived) ||
            (c.errorMessage != null && c.errorMessage != p.errorMessage),
        listener: (context, state) {
          if (state.archived && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.teacherClassArchivedMessage)),
            );
            context.pop();
            return;
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
          final room = state.classroom;
          if (room != null) {
            _editName.text = (room['name'] as String?)?.trim() ?? '';
            _editDesc.text = (room['description'] as String?)?.trim() ?? '';
          }
        },
        builder: (context, state) {
          _blocCtx = context;
          return _buildPage(context, state);
        },
      ),
    );
  }

  Widget _buildPage(BuildContext context, TeacherClassroomState state) {
    final l10n = context.l10n;
    final data = state.classroom;
    final loading = state.status == TeacherClassroomStatus.loading;
    final error = state.status == TeacherClassroomStatus.error ? state.errorMessage : null;
    final assignments = state.assignments;
    final members = state.members;

    final className = (data?['name'] as String?)?.trim() ?? l10n.teacherClassroomDetailTitle;
    final activeMembers = _memberCount(data, 'memberCountActive');
    final policy = _joinPolicyLabel(l10n, data?['joinPolicy'] as String?);

    return TeacherPageScaffold(
      scrollable: false,
      maxWidth: TeacherWebUi.contentMaxTable,
      title: className,
      showBack: true,
      subtitle: data != null ? l10n.teacherClassOverviewMeta(activeMembers, policy) : null,
      breadcrumbs: [
        TeacherBreadcrumb(label: l10n.teacherNavDashboard, location: TeacherDashboardPage.routePath),
        TeacherBreadcrumb(label: l10n.teacherMyClassrooms, location: TeacherDashboardPage.routePath),
        TeacherBreadcrumb(label: className),
      ],
      actions: [
        IconButton(
          style: TeacherWebUi.compactHeaderIconStyle(),
          onPressed: _reload,
          icon: const Icon(Icons.refresh_outlined, size: 18),
          color: AppColors.textSecondary,
          tooltip: l10n.retry,
        ),
        TeacherFilledButton(
          label: l10n.teacherAssignExamToClass,
          icon: Icons.add,
          onPressed: loading ? null : _openAssignExamPicker,
        ),
      ],
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s7),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(error, textAlign: TextAlign.center, style: TeacherWebUi.webBody(context)),
                        const SizedBox(height: AppSpacing.s5),
                        TeacherRetryButton(onPressed: () => _reload()),
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ClassroomTabBar(controller: _tabs, l10n: l10n),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _OverviewTab(
                            activeCount: _activeAssignmentsFrom(assignments).length,
                            historyCount: _historyAssignmentsFrom(assignments).length,
                            pendingMembers: _memberCount(data, 'memberCountPending'),
                            activeMembers: activeMembers,
                            recentAssignments: _activeAssignmentsFrom(assignments).take(3).toList(),
                            description: (data?['description'] as String?)?.trim() ?? '',
                            inviteCode: (data?['inviteCode'] as String?) ?? '',
                            createdAt: _formatDate(context, data?['createdAt']),
                            updatedAt: _formatDate(context, data?['updatedAt']),
                            onCopyInvite: _copyInviteCode,
                            onRefresh: () async => _reload(silent: true),
                            onViewAllAssignments: () => _tabs.animateTo(1),
                            onAssignExam: _openAssignExamPicker,
                            onOpenAssignment: _openStudentAttempts,
                            onManageSession: _openSession,
                            onOpenGradebook: () => context.push(
                              TeacherGradebookPage.routePath(widget.classroomId),
                            ),
                            onCloseAssignment: (m) => _confirmCloseAssignment(context, m),
                            onDeleteAssignment: (m) => _confirmDeleteAssignment(context, m),
                          ),
                          _AssignmentsTab(
                            active: _activeAssignmentsFrom(assignments),
                            history: _historyAssignmentsFrom(assignments),
                            segment: _assignmentSegment,
                            onSegmentChanged: (i) => setState(() => _assignmentSegment = i),
                            onAssignExam: _openAssignExamPicker,
                            onOpenAssignment: _openStudentAttempts,
                            onManageSession: _openSession,
                            onRefresh: () async => _reload(silent: true),
                            onCloseAssignment: (m) => _confirmCloseAssignment(context, m),
                            onDeleteAssignment: (m) => _confirmDeleteAssignment(context, m),
                          ),
                          _MembersTab(
                            members: members,
                            onApprove: _approveMember,
                            onReject: _rejectMember,
                            onRemove: _removeMember,
                            onRefresh: () async => _reload(silent: true),
                          ),
                          _ActivityTab(classroomId: widget.classroomId),
                          _SettingsTab(
                            nameController: _editName,
                            descriptionController: _editDesc,
                            policy: policy,
                            inviteCode: (data?['inviteCode'] as String?) ?? '',
                            classroomId: widget.classroomId,
                            integrations: data?['integrations'],
                            createdAt: _formatDate(context, data?['createdAt']),
                            updatedAt: _formatDate(context, data?['updatedAt']),
                            onCopyInvite: _copyInviteCode,
                            onSave: _saveClassroomSettings,
                            onRotateInvite: _rotateClassInvite,
                            onArchive: _archiveClassroom,
                            saving: state.settingsSaving,
                            onRefresh: () async => _reload(silent: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _ClassroomTabBar extends StatelessWidget {
  const _ClassroomTabBar({required this.controller, required this.l10n});

  final TabController controller;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.outline, width: 1)),
        ),
        child: TabBar(
          controller: controller,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.primaryDark,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          dividerColor: Colors.transparent,
          labelStyle: TeacherWebUi.webBody(context).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: TeacherWebUi.webBody(context).copyWith(fontSize: 13),
          tabs: [
            Tab(text: l10n.teacherClassTabOverview),
            Tab(text: l10n.teacherClassTabAssignments),
            Tab(text: l10n.teacherClassTabMembers),
            Tab(text: l10n.teacherClassTabActivity),
            Tab(text: l10n.teacherClassTabSettings),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.activeCount,
    required this.historyCount,
    required this.pendingMembers,
    required this.activeMembers,
    required this.recentAssignments,
    required this.description,
    required this.inviteCode,
    required this.createdAt,
    required this.updatedAt,
    required this.onCopyInvite,
    required this.onRefresh,
    required this.onViewAllAssignments,
    required this.onAssignExam,
    required this.onOpenAssignment,
    required this.onManageSession,
    required this.onOpenGradebook,
    required this.onCloseAssignment,
    required this.onDeleteAssignment,
  });

  final int activeCount;
  final int historyCount;
  final int pendingMembers;
  final int activeMembers;
  final List<Map<String, dynamic>> recentAssignments;
  final String description;
  final String inviteCode;
  final String? createdAt;
  final String? updatedAt;
  final VoidCallback onCopyInvite;
  final Future<void> Function() onRefresh;
  final VoidCallback onViewAllAssignments;
  final VoidCallback onAssignExam;
  final void Function(Map<String, dynamic>) onOpenAssignment;
  final void Function(Map<String, dynamic>) onManageSession;
  final VoidCallback onOpenGradebook;
  final void Function(Map<String, dynamic>) onCloseAssignment;
  final void Function(Map<String, dynamic>) onDeleteAssignment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: TeacherWebUi.pageScrollPadding(context),
        children: [
          TeacherInlineActions(
            alignment: Alignment.centerRight,
            children: [
              TeacherOutlinedButton(
                label: l10n.teacherGradebookTitle,
                icon: Icons.table_chart_outlined,
                onPressed: onOpenGradebook,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s5),
          TeacherKpiGrid(
            children: [
              TeacherKpiCard(
                icon: Icons.groups_outlined,
                value: '$activeMembers',
                label: l10n.teacherClassStatStudents,
                accent: AppColors.primary,
              ),
              TeacherKpiCard(
                icon: Icons.assignment_outlined,
                value: '$activeCount',
                label: l10n.teacherClassStatActiveAssignments,
                accent: AppColors.secondary,
              ),
              TeacherKpiCard(
                icon: Icons.history_outlined,
                value: '$historyCount',
                label: l10n.teacherClassStatHistoryAssignments,
                accent: AppColors.textSecondary,
              ),
              TeacherKpiCard(
                icon: Icons.hourglass_top_outlined,
                value: '$pendingMembers',
                label: l10n.teacherClassStatPendingMembers,
                accent: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s7),
          TeacherResponsiveColumns(
            left: _DescriptionPanel(
              description: description,
              emptyLabel: l10n.studentClassNoDescription,
              createdAt: createdAt,
              updatedAt: updatedAt,
            ),
            right: _InvitePanel(
              code: inviteCode,
              onCopy: onCopyInvite,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              Expanded(child: Text(l10n.teacherClassRecentAssignments, style: TeacherWebUi.sectionTitle(context))),
              if (recentAssignments.isNotEmpty)
                TextButton(onPressed: onViewAllAssignments, child: Text(l10n.teacherClassViewAllAssignments)),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          if (recentAssignments.isEmpty)
            TeacherEmptyCard(
              message: l10n.teacherClassNoAssignments,
              icon: Icons.assignment_outlined,
            )
          else
            ...recentAssignments.map(
              (m) => TeacherClassroomAssignmentTile(
                assignment: m,
                onViewAttempts: () => onOpenAssignment(m),
                onManageSession: (m['mode'] as String?) == 'realtime' ? () => onManageSession(m) : null,
                onClose: (m['status'] as String?) != 'closed' ? () => onCloseAssignment(m) : null,
                onDelete: () => onDeleteAssignment(m),
              ),
            ),
          if (recentAssignments.isEmpty) ...[
            const SizedBox(height: AppSpacing.s5),
            TeacherInlineActions(
              children: [
                TeacherFilledButton(
                  label: l10n.teacherClassAssignExamCta,
                  icon: Icons.add_task_outlined,
                  onPressed: onAssignExam,
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.s9),
        ],
      ),
    );
  }
}

class _AssignmentsTab extends StatelessWidget {
  const _AssignmentsTab({
    required this.active,
    required this.history,
    required this.segment,
    required this.onSegmentChanged,
    required this.onAssignExam,
    required this.onOpenAssignment,
    required this.onManageSession,
    required this.onRefresh,
    required this.onCloseAssignment,
    required this.onDeleteAssignment,
  });

  final List<Map<String, dynamic>> active;
  final List<Map<String, dynamic>> history;
  final int segment;
  final ValueChanged<int> onSegmentChanged;
  final VoidCallback onAssignExam;
  final void Function(Map<String, dynamic>) onOpenAssignment;
  final void Function(Map<String, dynamic>) onManageSession;
  final Future<void> Function() onRefresh;
  final void Function(Map<String, dynamic>) onCloseAssignment;
  final void Function(Map<String, dynamic>) onDeleteAssignment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = segment == 0 ? active : history;
    final emptyText = segment == 0 ? l10n.teacherClassNoAssignments : l10n.teacherClassNoHistory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s8, AppSpacing.s5, AppSpacing.s8, AppSpacing.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.teacherClassDetailAssignmentsTitle, style: TeacherWebUi.sectionTitle(context)),
              const SizedBox(height: AppSpacing.s5),
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(value: 0, label: Text(l10n.teacherClassDetailActiveTitle)),
                  ButtonSegment(value: 1, label: Text(l10n.teacherClassDetailHistoryTitle)),
                ],
                selected: {segment},
                onSelectionChanged: (s) => onSegmentChanged(s.first),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: items.isEmpty
                ? ListView(
                    padding: TeacherWebUi.pageScrollPadding(context),
                    children: [
                      TeacherEmptyCard(message: emptyText, icon: Icons.assignment_outlined),
                      const SizedBox(height: AppSpacing.s5),
                      TeacherInlineActions(
                        children: [
                          TeacherFilledButton(
                            label: l10n.teacherClassAssignExamCta,
                            icon: Icons.add_task_outlined,
                            onPressed: onAssignExam,
                          ),
                        ],
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: TeacherWebUi.pageScrollPadding(context),
                    itemCount: items.length,
                    itemBuilder: (_, i) => TeacherClassroomAssignmentTile(
                      assignment: items[i],
                      onViewAttempts: () => onOpenAssignment(items[i]),
                      onManageSession: (items[i]['mode'] as String?) == 'realtime'
                          ? () => onManageSession(items[i])
                          : null,
                      onClose: (items[i]['status'] as String?) != 'closed'
                          ? () => onCloseAssignment(items[i])
                          : null,
                      onDelete: () => onDeleteAssignment(items[i]),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _MembersTab extends StatelessWidget {
  const _MembersTab({
    required this.members,
    required this.onApprove,
    required this.onReject,
    required this.onRemove,
    required this.onRefresh,
  });

  final List<dynamic> members;
  final Future<void> Function(Map<String, dynamic>) onApprove;
  final Future<void> Function(Map<String, dynamic>) onReject;
  final Future<void> Function(Map<String, dynamic>) onRemove;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (members.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: TeacherWebUi.pageScrollPadding(context),
          children: [
            const SizedBox(height: 40),
            Text(l10n.teacherClassMembersEmpty, style: TeacherWebUi.webBody(context), textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: TeacherWebUi.pageScrollPadding(context),
        itemCount: members.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final m = Map<String, dynamic>.from(members[i] as Map);
          final st = m['status'] as String? ?? '';
          final pending = st == 'pending';
          final uid = () {
            final u = m['userId'];
            if (u is Map) return (u['id'] ?? u['_id'])?.toString() ?? '';
            return u?.toString() ?? '';
          }();
          final title = () {
            final u = m['userId'];
            if (u is Map) {
              final name = (u['fullName'] as String?)?.trim();
              if (name != null && name.isNotEmpty) return name;
              final un = (u['username'] as String?)?.trim();
              if (un != null && un.isNotEmpty) return un;
              final em = (u['email'] as String?)?.trim();
              if (em != null && em.isNotEmpty) return em;
            }
            return uid;
          }();
          return Material(
            color: AppColors.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.outline),
            ),
            child: ListTile(
              title: Text(title, style: TeacherWebUi.listTitle(context)),
              subtitle: pending ? Text(l10n.teacherClassMemberStatusPending, style: TeacherWebUi.metaMuted) : null,
              trailing: uid.isEmpty
                  ? null
                  : pending
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(onPressed: () => onReject(m), child: Text(l10n.teacherMemberReject)),
                            FilledButton(onPressed: () => onApprove(m), child: Text(l10n.teacherMemberApprove)),
                          ],
                        )
                      : TextButton(
                          onPressed: () => onRemove(m),
                          child: Text(l10n.teacherClassMemberRemove),
                        ),
            ),
          );
        },
      ),
    );
  }
}

class _ActivityTab extends StatefulWidget {
  const _ActivityTab({required this.classroomId});

  final String classroomId;

  @override
  State<_ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<_ActivityTab> {
  bool _reloading = true;
  List<dynamic> _rows = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _reloading = true);
    final r = await getIt<TeacherExamRepository>().listClassroomActivity(widget.classroomId);
    if (!mounted) return;
    r.fold((_) => setState(() => _reloading = false), (list) {
      setState(() {
        _rows = list;
        _reloading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_reloading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_rows.isEmpty) {
      return RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: TeacherWebUi.pageScrollPadding(context),
          children: [
            const SizedBox(height: 40),
            Text(l10n.teacherClassActivityEmpty, style: TeacherWebUi.webBody(context), textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.separated(
        padding: TeacherWebUi.pageScrollPadding(context),
        itemCount: _rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final m = Map<String, dynamic>.from(_rows[i] as Map);
          final msg = (m['message'] as String?) ?? (m['type'] as String?) ?? '';
          final at = DateTime.tryParse(m['createdAt'] as String? ?? '');
          return ListTile(
            tileColor: AppColors.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.outline),
            ),
            title: Text(msg, style: TeacherWebUi.listTitle(context)),
            subtitle: at != null ? Text(DateFormat.yMMMd().add_jm().format(at.toLocal()), style: TeacherWebUi.metaMuted) : null,
          );
        },
      ),
    );
  }
}

class _SettingsTab extends StatefulWidget {
  const _SettingsTab({
    required this.nameController,
    required this.descriptionController,
    required this.policy,
    required this.inviteCode,
    required this.classroomId,
    this.integrations,
    required this.createdAt,
    required this.updatedAt,
    required this.onCopyInvite,
    required this.onSave,
    required this.onRotateInvite,
    required this.onArchive,
    required this.saving,
    required this.onRefresh,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final String policy;
  final String inviteCode;
  final String classroomId;
  final dynamic integrations;
  final String? createdAt;
  final String? updatedAt;
  final VoidCallback onCopyInvite;
  final VoidCallback onSave;
  final VoidCallback onRotateInvite;
  final VoidCallback onArchive;
  final bool saving;
  final Future<void> Function() onRefresh;

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  final _coEmail = TextEditingController();
  final _googleCourseId = TextEditingController();

  @override
  void dispose() {
    _coEmail.dispose();
    _googleCourseId.dispose();
    super.dispose();
  }

  Future<void> _addCoTeacher() async {
    final l10n = context.l10n;
    final r = await getIt<TeacherExamRepository>().addCoTeacher(widget.classroomId, _coEmail.text.trim());
    if (!mounted) return;
    r.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.teacherCoTeacherAdded)));
        _coEmail.clear();
        widget.onRefresh();
      },
    );
  }

  Future<void> _linkGoogle() async {
    final l10n = context.l10n;
    final r = await getIt<TeacherExamRepository>().linkGoogleClassroom(widget.classroomId, {
      'googleCourseId': _googleCourseId.text.trim(),
    });
    if (!mounted) return;
    r.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.teacherGoogleClassroomLink)));
        widget.onRefresh();
      },
    );
  }

  Future<void> _unlinkGoogle() async {
    final l10n = context.l10n;
    final r = await getIt<TeacherExamRepository>().unlinkGoogleClassroom(widget.classroomId);
    if (!mounted) return;
    r.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.teacherGoogleClassroomUnlink)));
        widget.onRefresh();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gc = widget.integrations is Map ? (widget.integrations as Map)['googleClassroom'] : null;
  final gcName = gc is Map ? gc['courseName'] as String? : null;
    return ListView(
      padding: TeacherWebUi.pageScrollPadding(context),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: TeacherWebUi.contentMaxForm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.teacherClassSettingsAbout, style: TeacherWebUi.sectionTitle(context)),
                const SizedBox(height: AppSpacing.s4),
                TextField(
                  controller: widget.nameController,
                  decoration: InputDecoration(
                    labelText: l10n.teacherClassNameLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                TextField(
                  controller: widget.descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.teacherExamDescriptionLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.s5),
                TeacherInlineActions(
                  children: [
                    FilledButton(
                      style: TeacherWebUi.compactFilledStyle(context),
                      onPressed: widget.saving ? null : widget.onSave,
                      child: widget.saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.teacherClassSaveSettings),
                    ),
                  ],
                ),
                if (widget.createdAt != null) ...[
                  const SizedBox(height: AppSpacing.s6),
                  _SettingsField(label: l10n.teacherClassCreatedLabel, value: widget.createdAt!),
                ],
                if (widget.updatedAt != null) _SettingsField(label: l10n.teacherClassUpdatedLabel, value: widget.updatedAt!),
                const SizedBox(height: AppSpacing.s8),
                Text(l10n.teacherCoTeacherAdd, style: TeacherWebUi.sectionTitle(context)),
                const SizedBox(height: AppSpacing.s4),
                TextField(
                  controller: _coEmail,
                  decoration: InputDecoration(
                    labelText: l10n.teacherCoTeacherEmailHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                TeacherInlineActions(
                  children: [
                    TeacherOutlinedButton(label: l10n.teacherCoTeacherAdd, onPressed: _addCoTeacher),
                  ],
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(l10n.teacherIntegrationsTitle, style: TeacherWebUi.sectionTitle(context)),
                if (gcName != null && gcName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                    child: Text(gcName, style: TeacherWebUi.webBody(context)),
                  ),
                TextField(
                  controller: _googleCourseId,
                  decoration: InputDecoration(
                    labelText: l10n.teacherGoogleClassroomCourseId,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                TeacherInlineActions(
                  children: [
                    TeacherOutlinedButton(
                      label: l10n.teacherGoogleClassroomLink,
                      onPressed: _linkGoogle,
                    ),
                  ],
                ),
                if (gc != null)
                  TextButton(onPressed: _unlinkGoogle, child: Text(l10n.teacherGoogleClassroomUnlink)),
                const SizedBox(height: AppSpacing.s8),
                Text(l10n.teacherClassSettingsJoin, style: TeacherWebUi.sectionTitle(context)),
                const SizedBox(height: AppSpacing.s4),
                _SettingsField(label: l10n.teacherClassSettingsJoin, value: widget.policy),
                const SizedBox(height: AppSpacing.s5),
                _SettingsField(label: l10n.teacherInviteCode, value: widget.inviteCode, mono: true),
                const SizedBox(height: AppSpacing.s4),
                TeacherInlineActions(
                  children: [
                    TeacherOutlinedButton(
                      label: l10n.copyInviteCode,
                      icon: Icons.copy_outlined,
                      onPressed: widget.onCopyInvite,
                    ),
                    TeacherOutlinedButton(
                      label: l10n.teacherClassRotateInvite,
                      icon: Icons.refresh_rounded,
                      onPressed: widget.onRotateInvite,
                    ),
                    TeacherDangerOutlinedButton(
                      label: l10n.teacherClassArchive,
                      icon: Icons.archive_outlined,
                      onPressed: widget.onArchive,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsField extends StatelessWidget {
  const _SettingsField({
    required this.label,
    required this.value,
    this.muted = false,
    this.mono = false,
  });

  final String label;
  final String value;
  final bool muted;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TeacherWebUi.webCaption(context)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TeacherWebUi.webBody(context).copyWith(
              color: muted ? AppColors.textMuted : AppColors.textPrimary,
              fontFamily: mono ? 'monospace' : null,
              letterSpacing: mono ? 2 : null,
              fontWeight: mono ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionPanel extends StatelessWidget {
  const _DescriptionPanel({
    required this.description,
    required this.emptyLabel,
    required this.createdAt,
    required this.updatedAt,
  });

  final String description;
  final String emptyLabel;
  final String? createdAt;
  final String? updatedAt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s5),
      decoration: TeacherWebUi.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.teacherExamDescriptionLabel, style: TeacherWebUi.sectionTitle(context)),
          const SizedBox(height: AppSpacing.s4),
          Text(
            description.isNotEmpty ? description : emptyLabel,
            style: TeacherWebUi.webBody(context).copyWith(
              color: description.isNotEmpty ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
          if (createdAt != null || updatedAt != null) ...[
            const SizedBox(height: AppSpacing.s5),
            const Divider(height: 1, color: AppColors.outlineMuted),
            const SizedBox(height: AppSpacing.s4),
            if (createdAt != null) Text(l10n.studentClassCreatedAt(createdAt!), style: TeacherWebUi.metaMuted),
            if (updatedAt != null) ...[
              const SizedBox(height: 4),
              Text(l10n.studentClassUpdatedAt(updatedAt!), style: TeacherWebUi.metaMuted),
            ],
          ],
        ],
      ),
    );
  }
}

class _InvitePanel extends StatelessWidget {
  const _InvitePanel({required this.code, required this.onCopy});

  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s5),
      decoration: TeacherWebUi.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.teacherInviteCode, style: TeacherWebUi.sectionTitle(context)),
          const SizedBox(height: AppSpacing.s5),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: SelectableText(
              code,
              style: TeacherWebUi.webH1(context).copyWith(letterSpacing: 4, color: AppColors.primaryDark),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          FilledButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_outlined, size: 18),
            label: Text(l10n.copyInviteCode),
          ),
        ],
      ),
    );
  }
}

class _PickExamDialog extends StatelessWidget {
  const _PickExamDialog({required this.exams});

  final List<Map<String, dynamic>> exams;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.teacherPickExamToAssign, style: TeacherWebUi.webH1(context)),
      content: SizedBox(
        width: 480,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: exams.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final m = exams[i];
            final id = (m['id'] ?? m['_id'])?.toString() ?? '';
            final title = (m['title'] as String?) ?? l10n.studentExamUnknownTitle;
            return ListTile(
              leading: const Icon(Icons.task_alt_outlined, color: AppColors.primary),
              title: Text(title, style: TeacherWebUi.listTitle(context)),
              onTap: () => Navigator.pop(context, id),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
      ],
    );
  }
}
