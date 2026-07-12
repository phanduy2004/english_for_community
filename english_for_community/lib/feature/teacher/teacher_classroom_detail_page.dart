import 'package:english_for_community/feature/teacher/layout/teacher_skeleton.dart';
import 'dart:async';

import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/core/ui/widget/web_data_table.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_card_ui.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_page_scaffold.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_widgets.dart';
import 'package:english_for_community/feature/teacher/teacher_assignment_list_utils.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_dialogs.dart';
import 'package:english_for_community/feature/teacher/teacher_grading_hub_labels.dart';
import 'package:english_for_community/feature/teacher/teacher_dashboard_page.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_grading_page.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_session_console_page.dart';
import 'package:english_for_community/feature/teacher/bloc/classroom/teacher_classroom_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/classroom/teacher_classroom_event.dart';
import 'package:english_for_community/feature/teacher/bloc/classroom/teacher_classroom_state.dart';
import 'package:english_for_community/feature/classroom_chat/dock/classroom_chat_dock_controller.dart';
import 'package:english_for_community/feature/teacher/teacher_gradebook_page.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
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
  static const int _tabActivity = 3;

  final _editName = TextEditingController();
  final _editTag = TextEditingController();
  final _editDesc = TextEditingController();
  late TabController _tabs;
  int _visibleTabIndex = 0;
  bool _activityPrimed = false;
  /// Context under [BlocProvider] — State's own [context] is above the bloc.
  BuildContext? _blocCtx;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _tabs.addListener(_onTabIndexSettled);
  }

  void _onTabIndexSettled() {
    if (_tabs.indexIsChanging) return;
    final idx = _tabs.index;
    if (idx != _visibleTabIndex) {
      setState(() => _visibleTabIndex = idx);
    }
    if (idx == _tabActivity && !_activityPrimed) {
      _activityPrimed = true;
      _blocCtx?.read<TeacherClassroomBloc>().add(const TeacherClassroomActivityReloadRequested());
    }
  }

  bool _pageBuildWhen(TeacherClassroomState prev, TeacherClassroomState curr) {
    if (prev.status != curr.status) return true;
    if (prev.errorMessage != curr.errorMessage) return true;
    if (prev.classroom != curr.classroom) return true;
    if (prev.assignments != curr.assignments) return true;
    if (prev.members != curr.members) return true;
    if (prev.assignmentSegment != curr.assignmentSegment) return true;
    if (prev.settingsSaving != curr.settingsSaving) return true;
    // Activity rows reload inside [_ActivityTab] — skip parent rebuild.
    return false;
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
    _tabs.removeListener(_onTabIndexSettled);
    _tabs.dispose();
    _editName.dispose();
    _editTag.dispose();
    _editDesc.dispose();
    super.dispose();
  }

  void _saveClassroomSettings() {
    _bloc.add(
          TeacherClassroomSaveSettingsRequested(
            name: _editName.text.trim(),
            tag: _editTag.text.trim(),
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
      (f) => AppCornerToast.show(context, f.message, error: true),
      (_) {
        AppCornerToast.show(context, context.l10n.teacherMemberRejected);
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

  // Số bài giao MỚI NHẤT hiển thị trong bảng preview "Recent assignments" ở tab
  // Overview (danh sách đầy đủ vẫn ở "View all assignments" → tab Assignments).
  static const int _kOverviewRecentLimit = 6;

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
      (f) async => AppCornerToast.show(context, f.message, error: true),
      (list) async {
        if (list.isEmpty) {
          AppCornerToast.show(context, l10n.teacherNoExams, error: true);
          return;
        }
        final published = <Map<String, dynamic>>[];
        for (final raw in list) {
          final m = Map<String, dynamic>.from(raw as Map);
          if ((m['status'] as String?) == 'published') published.add(m);
        }
        if (published.isEmpty) {
          AppCornerToast.show(context, l10n.teacherNoPublishedExams, error: true);
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
      AppCornerToast.show(context, context.l10n.copiedToClipboard);
    }
  }

  Future<void> _copyInviteToken() async {
    final classroom = _bloc.state.classroom;
    final token = classroom?['inviteToken'] as String? ?? '';
    if (token.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: token));
    if (mounted) {
      AppCornerToast.show(context, context.l10n.copiedToClipboard);
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
            AppCornerToast.show(context, context.l10n.teacherClassArchivedMessage);
            context.pop();
            return;
          }
          if (state.errorMessage != null) {
            AppCornerToast.show(context, state.errorMessage!, error: true);
          }
          final room = state.classroom;
          if (room != null) {
            _editName.text = (room['name'] as String?)?.trim() ?? '';
            _editTag.text = (room['tag'] as String?)?.trim() ?? '';
            _editDesc.text = (room['description'] as String?)?.trim() ?? '';
          }
        },
        builder: (context, state) {
          _blocCtx = context;
          return _buildPage(context, state);
        },
        buildWhen: _pageBuildWhen,
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
    // Ưu tiên field `tag`; lớp cũ chưa có tag thì fallback tách theo "—".
    final tagField = (data?['tag'] as String?)?.trim() ?? '';
    String classTitle = className;
    String? classTag = tagField.isNotEmpty ? tagField : null;
    if (classTag == null) {
      final nameDash = RegExp(r'\s[—–-]\s').firstMatch(className);
      if (nameDash != null) {
        final rawTitle = className.substring(0, nameDash.start).trim();
        final rawMeta = className.substring(nameDash.end).trim();
        if (rawTitle.isNotEmpty && rawMeta.isNotEmpty) {
          classTitle = rawTitle;
          classTag = rawMeta;
        }
      }
    }
    final activeMembers = _memberCount(data, 'memberCountActive');
    final policy = _joinPolicyLabel(l10n, data?['joinPolicy'] as String?);

    return TeacherPageScaffold(
      scrollable: false,
      maxWidth: TeacherWebUi.contentMaxTable,
      title: classTitle,
      titleTag: classTag,
      showBack: true,
      subtitle: data != null ? l10n.teacherClassOverviewMeta(activeMembers, policy) : null,
      breadcrumbs: [
        TeacherBreadcrumb(label: l10n.teacherNavDashboard, location: TeacherDashboardPage.routePath),
        TeacherBreadcrumb(label: l10n.teacherMyClassrooms, location: TeacherDashboardPage.routePath),
        TeacherBreadcrumb(label: classTitle),
      ],
      actions: [
        IconButton(
          style: TeacherWebUi.compactHeaderIconStyle(),
          onPressed: _reload,
          icon: const Icon(Icons.refresh_outlined, size: 18),
          color: AppColors.textSecondary,
          tooltip: l10n.retry,
        ),
        IconButton(
          style: TeacherWebUi.compactHeaderIconStyle(),
          icon: const Icon(Icons.chat_outlined, size: 18),
          color: AppColors.primary,
          tooltip: 'Nhóm chat lớp học',
          onPressed: loading
              ? null
              : () {
                  getIt<ClassroomChatDockController>().openChat(
                    classroomId: widget.classroomId,
                    classroomName: className,
                  );
                },
        ),
        TeacherFilledButton(
          label: l10n.teacherAssignExamToClass,
          icon: Icons.add,
          onPressed: loading ? null : _openAssignExamPicker,
        ),
      ],
      body: loading
          ? TeacherSkeleton.page(TeacherSkeleton.dashboard())
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
                      child: _ClassroomTabStack(
                        index: _visibleTabIndex,
                        children: [
                          RepaintBoundary(
                            key: const ValueKey('classroom_tab_overview'),
                            child: _OverviewTab(
                              activeCount: _activeAssignmentsFrom(assignments).length,
                              historyCount: _historyAssignmentsFrom(assignments).length,
                              pendingMembers: _memberCount(data, 'memberCountPending'),
                              activeMembers: activeMembers,
                              recentAssignments:
                                  _activeAssignmentsFrom(assignments).take(_kOverviewRecentLimit).toList(),
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
                              onOpenMembersTab: () => _tabs.animateTo(2),
                              onOpenAssignmentsTab: () => _tabs.animateTo(1),
                              onOpenGradebook: () => context.push(
                                TeacherGradebookPage.routePath(widget.classroomId),
                              ),
                              onCloseAssignment: (m) => _confirmCloseAssignment(context, m),
                              onDeleteAssignment: (m) => _confirmDeleteAssignment(context, m),
                            ),
                          ),
                          RepaintBoundary(
                            key: const ValueKey('classroom_tab_assignments'),
                            child: _AssignmentsTab(
                              active: _activeAssignmentsFrom(assignments),
                              history: _historyAssignmentsFrom(assignments),
                              segment: state.assignmentSegment,
                              onSegmentChanged: (i) => _bloc.add(TeacherClassroomAssignmentSegmentChanged(i)),
                              onAssignExam: _openAssignExamPicker,
                              onOpenAssignment: _openStudentAttempts,
                              onManageSession: _openSession,
                              onRefresh: () async => _reload(silent: true),
                              onCloseAssignment: (m) => _confirmCloseAssignment(context, m),
                              onDeleteAssignment: (m) => _confirmDeleteAssignment(context, m),
                            ),
                          ),
                          RepaintBoundary(
                            key: const ValueKey('classroom_tab_members'),
                            child: _MembersTab(
                              members: members,
                              inviteCode: (data?['inviteCode'] as String?) ?? '',
                              onApprove: _approveMember,
                              onReject: _rejectMember,
                              onRemove: _removeMember,
                              onCopyInvite: _copyInviteCode,
                              onRefresh: () async => _reload(silent: true),
                            ),
                          ),
                          RepaintBoundary(
                            key: const ValueKey('classroom_tab_activity'),
                            child: _ActivityTab(classroomId: widget.classroomId),
                          ),
                          RepaintBoundary(
                            key: const ValueKey('classroom_tab_settings'),
                            child: _SettingsTab(
                              nameController: _editName,
                              tagController: _editTag,
                              descriptionController: _editDesc,
                              policy: policy,
                              inviteCode: (data?['inviteCode'] as String?) ?? '',
                              inviteToken: (data?['inviteToken'] as String?) ?? '',
                              classroomId: widget.classroomId,
                              primaryTeacher: data?['teacherId'],
                              members: members,
                              activeMemberCount: activeMembers,
                              pendingMemberCount: _memberCount(data, 'memberCountPending'),
                              assignmentCount: assignments.length,
                              integrations: data?['integrations'],
                              archived: data?['archived'] == true,
                              createdAt: _formatDate(context, data?['createdAt']),
                              updatedAt: _formatDate(context, data?['updatedAt']),
                              onCopyInvite: _copyInviteCode,
                              onCopyInviteToken: _copyInviteToken,
                              onSave: _saveClassroomSettings,
                              onRotateInvite: _rotateClassInvite,
                              onArchive: _archiveClassroom,
                              saving: state.settingsSaving,
                              onRefresh: () async => _reload(silent: true),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _ClassroomTabStack extends StatefulWidget {
  const _ClassroomTabStack({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<_ClassroomTabStack> createState() => _ClassroomTabStackState();
}

class _ClassroomTabStackState extends State<_ClassroomTabStack> with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: AppMotion.fast, value: 1);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(covariant _ClassroomTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _fadeCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: IndexedStack(
        index: widget.index,
        sizing: StackFit.expand,
        children: widget.children,
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
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
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

// ── Overview redesign: compact summary + assignments table ──────────────

Map<String, dynamic>? _asgMap(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : null;

String _asgTitle(AppLocalizations l10n, Map<String, dynamic> m) {
  final s = _asgMap(m['examSummary']);
  final a = (s?['title'] as String?)?.trim();
  if (a != null && a.isNotEmpty) return a;
  final e = _asgMap(m['examId']);
  final b = (e?['title'] as String?)?.trim();
  if (b != null && b.isNotEmpty) return b;
  return l10n.studentExamUnknownTitle;
}

Color _asgModeColor(String mode) {
  switch (mode) {
    case 'realtime':
      return AppColors.success;
    case 'scheduled':
      return AppColors.warning;
    case 'practice':
      return AppColors.textSecondary;
    default:
      return AppColors.primary;
  }
}

({String label, Color color}) _asgStatus(AppLocalizations l10n, Map<String, dynamic> m) {
  final mode = m['mode'] as String? ?? '';
  if ((m['status'] as String?) == 'closed') {
    return (label: l10n.studentClassSegmentClosed, color: AppColors.textMuted);
  }
  if (mode == 'realtime') {
    final st = _asgMap(m['activeSession'])?['status'] as String?;
    if (st == 'live') return (label: l10n.examCardStatusLive, color: AppColors.success);
    if (st == 'lobby') return (label: l10n.teacherClassStatusLobby, color: AppColors.primary);
  }
  return (label: TeacherGradingHubLabels.modeLabel(l10n, mode), color: _asgModeColor(mode));
}

String? _asgSchedule(BuildContext context, Map<String, dynamic> m) {
  final schedule = _asgMap(m['schedule']);
  final mode = m['mode'] as String? ?? schedule?['mode'] as String? ?? '';
  final locale = Localizations.localeOf(context).toString();
  String? fmt(dynamic raw) {
    if (raw == null) return null;
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return null;
    return DateFormat.yMMMd(locale).add_jm().format(dt.toLocal());
  }

  if (mode == 'self_paced' || mode == 'practice') return fmt(schedule?['dueAt']);
  if (mode == 'scheduled') return fmt(schedule?['closesAt']) ?? fmt(schedule?['opensAt']);
  if (mode == 'realtime') return fmt(schedule?['scheduledStartAt']);
  return null;
}

({int submitted, int total}) _asgStats(Map<String, dynamic> m) {
  final s = _asgMap(m['attemptStats']);
  if (s == null) return (submitted: 0, total: 0);
  final sub = (s['submitted'] as num?)?.toInt() ?? 0;
  final inp = (s['inProgress'] as num?)?.toInt() ?? 0;
  final total = (s['total'] as num?)?.toInt() ?? (sub + inp);
  return (submitted: sub, total: total);
}

/// Dải thống kê + mã lớp gọn (Overview top) — thay 4 KPI card to.
class _OverviewSummaryStrip extends StatelessWidget {
  const _OverviewSummaryStrip({
    required this.students,
    required this.active,
    required this.history,
    required this.pending,
    required this.inviteCode,
    required this.onCopyInvite,
    required this.onOpenMembers,
    required this.onOpenAssignments,
  });

  final int students;
  final int active;
  final int history;
  final int pending;
  final String inviteCode;
  final VoidCallback onCopyInvite;
  final VoidCallback onOpenMembers;
  final VoidCallback onOpenAssignments;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: TeacherWebUi.panelDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s3),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: AppSpacing.s6,
              runSpacing: AppSpacing.s2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _MiniStat(value: '$students', label: l10n.teacherClassStatStudents, onTap: onOpenMembers),
                _MiniStat(value: '$active', label: l10n.teacherClassStatActiveAssignments, color: AppColors.accentDark, onTap: onOpenAssignments),
                _MiniStat(value: '$history', label: l10n.teacherClassStatHistoryAssignments, onTap: onOpenAssignments),
                _MiniStat(value: '$pending', label: l10n.teacherClassStatPendingMembers, color: pending > 0 ? AppColors.warning : null, onTap: pending > 0 ? onOpenMembers : null),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          if (inviteCode.isNotEmpty) _InviteInline(code: inviteCode, onCopy: onCopyInvite),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label, this.color, this.onTap});

  final String value;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(value, style: TeacherWebUi.webKpiValue(context).copyWith(color: color ?? AppColors.textPrimary)),
        const SizedBox(width: AppSpacing.s2),
        Text(label, style: TeacherWebUi.webCaption(context).copyWith(color: AppColors.textSecondary)),
      ],
    );
    if (onTap == null) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.s1), child: row);
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: AppSpacing.s1), child: row),
    );
  }
}

class _InviteInline extends StatelessWidget {
  const _InviteInline({required this.code, required this.onCopy});

  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.teacherInviteCode, style: TeacherWebUi.sectionTitle(context)),
        const SizedBox(width: AppSpacing.s3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(color: AppColors.outline),
          ),
          child: SelectableText(
            code,
            style: TeacherWebUi.webKpiValue(context).copyWith(letterSpacing: 2, color: AppColors.primaryDark),
          ),
        ),
        const SizedBox(width: AppSpacing.s2),
        IconButton(
          style: TeacherWebUi.compactHeaderIconStyle(),
          icon: const Icon(Icons.copy_outlined, size: 18),
          color: AppColors.textSecondary,
          tooltip: l10n.copyInviteCode,
          onPressed: onCopy,
        ),
      ],
    );
  }
}

/// Mô tả lớp 1 dòng, bấm để mở rộng (secondary).
class _OverviewDescriptionLine extends StatefulWidget {
  const _OverviewDescriptionLine({
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.emptyLabel,
  });

  final String description;
  final String? createdAt;
  final String? updatedAt;
  final String emptyLabel;

  @override
  State<_OverviewDescriptionLine> createState() => _OverviewDescriptionLineState();
}

class _OverviewDescriptionLineState extends State<_OverviewDescriptionLine> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (widget.description.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
        child: Row(
          children: [
            const Icon(Icons.notes_outlined, size: 15, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.s3),
            Text(widget.emptyLabel, style: TeacherWebUi.metaMuted),
          ],
        ),
      );
    }
    final descStyle = TeacherWebUi.webCaption(context).copyWith(color: AppColors.textSecondary, height: 1.5);
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: AppSpacing.s2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(Icons.notes_outlined, size: 15, color: AppColors.textMuted),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Text(
                    widget.description,
                    style: descStyle,
                    maxLines: _expanded ? null : 1,
                    overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 16, color: AppColors.textMuted),
              ],
            ),
            if (_expanded && (widget.createdAt != null || widget.updatedAt != null)) ...[
              const SizedBox(height: AppSpacing.s2),
              Padding(
                padding: const EdgeInsets.only(left: 23),
                child: Wrap(
                  spacing: AppSpacing.s5,
                  runSpacing: AppSpacing.s1,
                  children: [
                    if (widget.createdAt != null)
                      Text(l10n.studentClassCreatedAt(widget.createdAt!), style: TeacherWebUi.metaMuted),
                    if (widget.updatedAt != null)
                      Text(l10n.studentClassUpdatedAt(widget.updatedAt!), style: TeacherWebUi.metaMuted),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Chiều rộng cột dùng chung header + row (căn thẳng để kẻ dọc liền mạch).
const double _colStatusW = 140;
const double _colSubmittedW = 100;
const double _colActionsW = 56;
const double _colMemberStatusW = 130;
const double _colMemberJoinedW = 170;
const double _colMemberActionsW = 190;

/// Đường kẻ dọc giữa 2 ô — giãn hết chiều cao hàng (Row crossAxis stretch).


/// Cỡ chữ nội dung ô bảng web — nén 1 bậc so với webBody(13) cho dày như mobile.
TextStyle _tableText(BuildContext context) => TeacherWebUi.webBody(context).copyWith(fontSize: 12);

/// Một dòng hành động trong menu ⋯ (icon + nhãn).
Widget _menuAction(IconData icon, String label, {bool danger = false}) {
  final color = danger ? AppColors.danger : AppColors.textPrimary;
  return Row(
    children: [
      Icon(icon, size: 16, color: danger ? AppColors.danger : AppColors.textSecondary),
      const SizedBox(width: AppSpacing.s3),
      Text(label, style: TextStyle(color: color)),
    ],
  );
}

/// Bảng bài kiểm tra — kẻ dọc + kẻ ngang, hàng cao cố định. Dùng cho Overview
/// (preview, [scrollable] = false) và tab Assignments (list dài, scrollable).
class _AssignmentTable extends StatelessWidget {
  const _AssignmentTable({
    required this.items,
    required this.onOpen,
    required this.onManageSession,
    required this.onClose,
    required this.onDelete,
    this.scrollable = false,
    this.scrollPadding = EdgeInsets.zero,
  });

  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic>) onOpen;
  final void Function(Map<String, dynamic>) onManageSession;
  final void Function(Map<String, dynamic>) onClose;
  final void Function(Map<String, dynamic>) onDelete;
  final bool scrollable;
  final EdgeInsets scrollPadding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return WebDataTable(
      columns: [
        WebTableColumn(label: l10n.teacherClassColExam, flex: 4),
        WebTableColumn(label: l10n.teacherClassColStatus, width: _colStatusW),
        WebTableColumn(label: l10n.teacherClassColSchedule, flex: 3),
        WebTableColumn(
          label: l10n.teacherClassColSubmitted,
          width: _colSubmittedW,
          align: Alignment.centerRight,
        ),
        const WebTableColumn(label: '', width: _colActionsW, align: Alignment.center),
      ],
      rowCount: items.length,
      decoration: TeacherWebUi.panelDecoration(),
      headStyle: TeacherWebUi.webTableHead(context),
      scrollable: scrollable,
      scrollPadding: scrollPadding,
      onRowTap: (row) {
        final m = items[row];
        final aid = m['id'] as String? ?? '';
        if (aid.isEmpty) return null;
        return _primaryActionFor(m);
      },
      cellBuilder: (context, row, col) {
        final m = items[row];
        return switch (col) {
          0 => _assignmentExamCell(context, m),
          1 => _assignmentStatusCell(context, m),
          2 => _assignmentScheduleCell(context, m),
          3 => _assignmentSubmittedCell(context, m),
          _ => _assignmentActionMenu(context, m),
        };
      },
    );
  }

  VoidCallback _primaryActionFor(Map<String, dynamic> m) {
    final mode = m['mode'] as String? ?? '';
    final isRealtime = mode == 'realtime';
    final isActive = (m['status'] as String?) != 'closed';
    return isRealtime && isActive ? () => onManageSession(m) : () => onOpen(m);
  }

  Widget _assignmentExamCell(BuildContext context, Map<String, dynamic> m) {
    final l10n = context.l10n;
    final title = _asgTitle(l10n, m);
    final mode = m['mode'] as String? ?? '';
    return Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: AppColors.primaryTint,
          child: Text(
            TeacherGradingHubLabels.studentInitials(title),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
          ),
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
                style: _tableText(context).copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                TeacherGradingHubLabels.modeLabel(l10n, mode),
                style: TeacherWebUi.metaMuted,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _assignmentStatusCell(BuildContext context, Map<String, dynamic> m) {
    final status = _asgStatus(context.l10n, m);
    return TeacherGradingPill(label: status.label, color: status.color, alpha: 0.12);
  }

  Widget _assignmentScheduleCell(BuildContext context, Map<String, dynamic> m) {
    return Text(
      _asgSchedule(context, m) ?? '—',
      style: TeacherWebUi.webCaption(context).copyWith(color: AppColors.textSecondary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _assignmentSubmittedCell(BuildContext context, Map<String, dynamic> m) {
    final stats = _asgStats(m);
    return Text(
      '${stats.submitted}/${stats.total}',
      style: _tableText(context).copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _assignmentActionMenu(BuildContext context, Map<String, dynamic> m) {
    final l10n = context.l10n;
    final mode = m['mode'] as String? ?? '';
    final isRealtime = mode == 'realtime';
    final isActive = (m['status'] as String?) != 'closed';
    final canManageSession = isRealtime && isActive;
    final canDelete = _asgStats(m).submitted == 0;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, size: 18, color: AppColors.textSecondary),
      padding: EdgeInsets.zero,
      tooltip: '',
      position: PopupMenuPosition.under,
      onSelected: (v) {
        if (v == 'session') onManageSession(m);
        if (v == 'view') onOpen(m);
        if (v == 'close') onClose(m);
        if (v == 'delete') onDelete(m);
      },
      itemBuilder: (_) => [
        if (canManageSession)
          PopupMenuItem(value: 'session', child: _menuAction(Icons.sensors_rounded, l10n.examCardManageSession)),
        PopupMenuItem(value: 'view', child: _menuAction(Icons.fact_check_outlined, l10n.teacherClassOpenAttemptsList)),
        if (isActive)
          PopupMenuItem(value: 'close', child: _menuAction(Icons.lock_outline, l10n.teacherAssignmentClose)),
        if (canDelete)
          PopupMenuItem(value: 'delete', child: _menuAction(Icons.delete_outline, l10n.teacherAssignmentDelete, danger: true)),
      ],
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
    required this.onOpenMembersTab,
    required this.onOpenAssignmentsTab,
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
  final VoidCallback onOpenMembersTab;
  final VoidCallback onOpenAssignmentsTab;
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
          _OverviewSummaryStrip(
            students: activeMembers,
            active: activeCount,
            history: historyCount,
            pending: pendingMembers,
            inviteCode: inviteCode,
            onCopyInvite: onCopyInvite,
            onOpenMembers: onOpenMembersTab,
            onOpenAssignments: onOpenAssignmentsTab,
          ),
          const SizedBox(height: AppSpacing.s3),
          _OverviewDescriptionLine(
            description: description,
            createdAt: createdAt,
            updatedAt: updatedAt,
            emptyLabel: l10n.studentClassNoDescription,
          ),
          const SizedBox(height: AppSpacing.s7),
          Row(
            children: [
              Expanded(child: Text(l10n.teacherClassRecentAssignments, style: TeacherWebUi.sectionTitle(context))),
              if (recentAssignments.isNotEmpty)
                TextButton(onPressed: onViewAllAssignments, child: Text(l10n.teacherClassViewAllAssignments)),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          if (recentAssignments.isEmpty)
            TeacherEmptyCard(
              message: l10n.teacherClassNoAssignments,
              icon: Icons.assignment_outlined,
              actionLabel: l10n.teacherClassAssignExamCta,
              onAction: onAssignExam,
            )
          else
            _AssignmentTable(
              items: recentAssignments,
              onOpen: onOpenAssignment,
              onManageSession: onManageSession,
              onClose: onCloseAssignment,
              onDelete: onDeleteAssignment,
            ),
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
              TeacherSegmentTileRow<int>(
                selected: segment,
                onChanged: onSegmentChanged,
                options: [
                  TeacherSegmentOption(
                    value: 0,
                    label: l10n.teacherClassDetailActiveTitle,
                    icon: Icons.playlist_add_check_outlined,
                    count: active.length,
                    fg: AppColors.primary,
                    bg: AppColors.primaryTint,
                    border: AppColors.primary,
                  ),
                  TeacherSegmentOption(
                    value: 1,
                    label: l10n.teacherClassDetailHistoryTitle,
                    icon: Icons.history_rounded,
                    count: history.length,
                    fg: AppColors.info,
                    bg: AppColors.infoBg,
                    border: AppColors.info,
                  ),
                ],
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
                : _AssignmentTable(
                    scrollable: true,
                    scrollPadding: TeacherWebUi.pageScrollPadding(context).copyWith(bottom: 0),
                    items: items,
                    onOpen: onOpenAssignment,
                    onManageSession: onManageSession,
                    onClose: onCloseAssignment,
                    onDelete: onDeleteAssignment,
                  ),
          ),
        ),
      ],
    );
  }
}

enum _MemberFilter { all, active, pending }

class _MembersTab extends StatefulWidget {
  const _MembersTab({
    required this.members,
    required this.inviteCode,
    required this.onApprove,
    required this.onReject,
    required this.onRemove,
    required this.onCopyInvite,
    required this.onRefresh,
  });

  final List<dynamic> members;
  final String inviteCode;
  final Future<void> Function(Map<String, dynamic>) onApprove;
  final Future<void> Function(Map<String, dynamic>) onReject;
  final Future<void> Function(Map<String, dynamic>) onRemove;
  final VoidCallback onCopyInvite;
  final Future<void> Function() onRefresh;

  @override
  State<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<_MembersTab> {
  final _searchCtrl = TextEditingController();
  _MemberFilter _filter = _MemberFilter.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _studentMembers => widget.members
      .map((raw) => Map<String, dynamic>.from(raw as Map))
      .where((m) => m['roleInClass'] != 'co_teacher')
      .toList();

  String _memberName(Map<String, dynamic> m) {
    final u = m['userId'];
    if (u is Map) {
      final name = (u['fullName'] as String?)?.trim();
      if (name != null && name.isNotEmpty) return name;
      final un = (u['username'] as String?)?.trim();
      if (un != null && un.isNotEmpty) return un;
      final em = (u['email'] as String?)?.trim();
      if (em != null && em.isNotEmpty) return em;
    }
    return _memberUid(m);
  }

  String _memberEmail(Map<String, dynamic> m) {
    final u = m['userId'];
    if (u is Map) {
      return (u['email'] as String?)?.trim() ?? '';
    }
    return '';
  }

  String _memberUsername(Map<String, dynamic> m) {
    final u = m['userId'];
    if (u is Map) return (u['username'] as String?)?.trim() ?? '';
    return '';
  }

  String _memberUid(Map<String, dynamic> m) {
    final u = m['userId'];
    if (u is Map) return (u['id'] ?? u['_id'])?.toString() ?? '';
    return u?.toString() ?? '';
  }

  String? _memberAvatar(Map<String, dynamic> m) {
    final u = m['userId'];
    if (u is Map) return (u['avatar'] as String?)?.trim();
    return null;
  }

  String? _memberJoinDate(Map<String, dynamic> m) {
    final raw = m['joinedAt'] ?? m['createdAt'];
    if (raw == null) return null;
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return null;
    return DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(dt.toLocal());
  }

  bool _matchesSearch(Map<String, dynamic> m, String q) {
    if (q.isEmpty) return true;
    final lower = q.toLowerCase();
    return _memberName(m).toLowerCase().contains(lower) ||
        _memberEmail(m).toLowerCase().contains(lower) ||
        _memberUsername(m).toLowerCase().contains(lower);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final query = _searchCtrl.text.trim();
    final all = _studentMembers;

    final pending = all.where((m) => (m['status'] as String? ?? '') == 'pending').toList();
    final active = all.where((m) => (m['status'] as String? ?? '') != 'pending').toList();

    List<Map<String, dynamic>> filtered;
    switch (_filter) {
      case _MemberFilter.active:
        filtered = active;
      case _MemberFilter.pending:
        filtered = pending;
      case _MemberFilter.all:
        filtered = all;
    }
    if (query.isNotEmpty) {
      filtered = filtered.where((m) => _matchesSearch(m, query)).toList();
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: _buildToolbar(l10n, all.length, pending.length, active.length),
          ),
          Expanded(
            child: filtered.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: _buildEmptyState(l10n, all.isEmpty),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: _MemberTable(
                      members: filtered,
                      memberName: _memberName,
                      memberEmail: _memberEmail,
                      memberAvatar: _memberAvatar,
                      memberJoinDate: _memberJoinDate,
                      onApprove: widget.onApprove,
                      onReject: widget.onReject,
                      onRemove: widget.onRemove,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(AppLocalizations l10n, int total, int pendingCount, int activeCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: TeacherWebUi.webBody(context),
                decoration: TeacherWebUi.formInputDecoration(context, hintText: l10n.teacherMembersSearchHint).copyWith(
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),
            if (widget.inviteCode.isNotEmpty) ...[
              const SizedBox(width: 10),
              Tooltip(
                message: l10n.teacherMembersCopyInvite,
                child: OutlinedButton.icon(
                  onPressed: widget.onCopyInvite,
                  icon: const Icon(Icons.link, size: 16),
                  label: Text(l10n.teacherMembersInvite),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 36),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    side: const BorderSide(color: AppColors.outline),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            TeacherFilterChip(
              label: '${l10n.teacherMembersFilterAll} ($total)',
              selected: _filter == _MemberFilter.all,
              onSelected: () => setState(() => _filter = _MemberFilter.all),
            ),
            TeacherFilterChip(
              label: '${l10n.teacherMembersFilterActive} ($activeCount)',
              selected: _filter == _MemberFilter.active,
              onSelected: () => setState(() => _filter = _MemberFilter.active),
            ),
            if (pendingCount > 0)
              TeacherFilterChip(
                label: '${l10n.teacherMembersFilterPending} ($pendingCount)',
                selected: _filter == _MemberFilter.pending,
                onSelected: () => setState(() => _filter = _MemberFilter.pending),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, bool noMembers) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              noMembers ? Icons.people_outline : Icons.search_off_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              noMembers ? l10n.teacherClassMembersEmpty : l10n.teacherMembersNoResults,
              style: TeacherWebUi.webBody(context),
              textAlign: TextAlign.center,
            ),
            if (noMembers) ...[
              const SizedBox(height: 8),
              Text(
                l10n.teacherMembersEmptyHint,
                style: TeacherWebUi.metaMuted,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

}

class _MemberTable extends StatelessWidget {
  const _MemberTable({
    required this.members,
    required this.memberName,
    required this.memberEmail,
    required this.memberAvatar,
    required this.memberJoinDate,
    required this.onApprove,
    required this.onReject,
    required this.onRemove,
  });

  final List<Map<String, dynamic>> members;
  final String Function(Map<String, dynamic>) memberName;
  final String Function(Map<String, dynamic>) memberEmail;
  final String? Function(Map<String, dynamic>) memberAvatar;
  final String? Function(Map<String, dynamic>) memberJoinDate;
  final void Function(Map<String, dynamic>) onApprove;
  final void Function(Map<String, dynamic>) onReject;
  final void Function(Map<String, dynamic>) onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return WebDataTable(
      columns: [
        WebTableColumn(label: l10n.teacherClassColMember, flex: 4),
        WebTableColumn(label: l10n.teacherClassColStatus, width: _colMemberStatusW),
        WebTableColumn(label: l10n.teacherClassColJoined, width: _colMemberJoinedW),
        const WebTableColumn(label: '', width: _colMemberActionsW, align: Alignment.centerRight),
      ],
      rowCount: members.length,
      decoration: TeacherWebUi.panelDecoration(),
      headStyle: TeacherWebUi.webTableHead(context),
      scrollable: true,
      cellBuilder: (context, row, col) {
        final member = members[row];
        return switch (col) {
          0 => _memberIdentityCell(context, member),
          1 => _memberStatusCell(context, member),
          2 => _memberJoinedCell(context, member),
          _ => _memberActionsCell(context, member),
        };
      },
    );
  }

  Widget _memberIdentityCell(BuildContext context, Map<String, dynamic> member) {
    final name = memberName(member);
    final email = memberEmail(member);
    return Row(
      children: [
        TeacherWebUi.userAvatarCircle(
          avatarUrl: memberAvatar(member),
          displayName: name,
          radius: 15,
        ),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: _tableText(context).copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (email.isNotEmpty)
                Text(
                  email,
                  style: TeacherWebUi.metaMuted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _memberStatusCell(BuildContext context, Map<String, dynamic> member) {
    final l10n = context.l10n;
    final isPending = (member['status'] as String? ?? '') == 'pending';
    return _StatusPill(
      label: isPending ? l10n.teacherMembersStatusPending : l10n.teacherMembersFilterActive,
      color: isPending ? AppColors.warning : AppColors.success,
    );
  }

  Widget _memberJoinedCell(BuildContext context, Map<String, dynamic> member) {
    return Text(
      memberJoinDate(member) ?? '—',
      style: TeacherWebUi.webCaption(context).copyWith(color: AppColors.textSecondary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _memberActionsCell(BuildContext context, Map<String, dynamic> member) {
    final l10n = context.l10n;
    final isPending = (member['status'] as String? ?? '') == 'pending';
    if (isPending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CompactActionButton(
            label: l10n.teacherMemberReject,
            icon: Icons.close,
            onPressed: () => onReject(member),
            danger: true,
          ),
          const SizedBox(width: AppSpacing.s2),
          _CompactActionButton(
            label: l10n.teacherMemberApprove,
            icon: Icons.check,
            onPressed: () => onApprove(member),
            filled: true,
          ),
        ],
      );
    }
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.person_remove_outlined, size: 18, color: AppColors.textSecondary),
      tooltip: l10n.teacherClassMemberRemove,
      onPressed: () => onRemove(member),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final fg = danger ? AppColors.danger : (filled ? Colors.white : AppColors.textPrimary);
    final bg = filled
        ? AppColors.primary
        : danger
            ? AppColors.danger.withValues(alpha: 0.08)
            : AppColors.surfaceSubtle;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.input),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
            ],
          ),
        ),
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
  Future<void> _reload() async {
    context.read<TeacherClassroomBloc>().add(const TeacherClassroomActivityReloadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<TeacherClassroomBloc, TeacherClassroomState>(
      builder: (context, state) {
        if (state.activityReloading && state.activityRows.isEmpty) {
          return TeacherSkeleton.page(TeacherSkeleton.table(rows: 6));
        }
        if (state.activityRows.isEmpty) {
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
            itemCount: state.activityRows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final m = Map<String, dynamic>.from(state.activityRows[i] as Map);
              final type = m['type'] as String?;
              final isIntegrity = type == 'integrity_flag'; // C4: nhấn mạnh cờ gian lận
              final msg = (m['message'] as String?) ?? (type) ?? '';
              final at = DateTime.tryParse(m['createdAt'] as String? ?? '');
              return ListTile(
                tileColor: AppColors.surfaceCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  side: BorderSide(color: isIntegrity ? AppColors.danger : AppColors.outline),
                ),
                leading: isIntegrity ? Icon(Icons.flag, color: AppColors.danger) : null,
                title: Text(msg, style: TeacherWebUi.listTitle(context)),
                subtitle: at != null
                    ? Text(DateFormat.yMMMd().add_jm().format(at.toLocal()), style: TeacherWebUi.metaMuted)
                    : null,
              );
            },
          ),
        );
      },
    );
  }
}

class _SettingsTab extends StatefulWidget {
  const _SettingsTab({
    required this.nameController,
    required this.tagController,
    required this.descriptionController,
    required this.policy,
    required this.inviteCode,
    required this.inviteToken,
    required this.classroomId,
    required this.primaryTeacher,
    required this.members,
    required this.activeMemberCount,
    required this.pendingMemberCount,
    required this.assignmentCount,
    this.integrations,
    this.archived = false,
    required this.createdAt,
    required this.updatedAt,
    required this.onCopyInvite,
    required this.onCopyInviteToken,
    required this.onSave,
    required this.onRotateInvite,
    required this.onArchive,
    required this.saving,
    required this.onRefresh,
  });

  final TextEditingController nameController;
  final TextEditingController tagController;
  final TextEditingController descriptionController;
  final String policy;
  final String inviteCode;
  final String inviteToken;
  final String classroomId;
  final dynamic primaryTeacher;
  final List<dynamic> members;
  final int activeMemberCount;
  final int pendingMemberCount;
  final int assignmentCount;
  final dynamic integrations;
  final bool archived;
  final String? createdAt;
  final String? updatedAt;
  final VoidCallback onCopyInvite;
  final VoidCallback onCopyInviteToken;
  final VoidCallback onSave;
  final VoidCallback onRotateInvite;
  final VoidCallback onArchive;
  final bool saving;
  final Future<void> Function() onRefresh;

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  final _coUsername = TextEditingController();
  final _googleCourseId = TextEditingController();
  Timer? _searchDebounce;
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;
  String? _addingTeacherId;
  late List<Map<String, dynamic>> _coTeacherMembers;
  late List<Map<String, dynamic>> _pendingCoTeacherMembers;

  @override
  void initState() {
    super.initState();
    _coTeacherMembers = _coTeachersFrom(widget.members, activeOnly: true);
    _pendingCoTeacherMembers = _coTeachersFrom(widget.members, activeOnly: false);
  }

  @override
  void didUpdateWidget(covariant _SettingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.members != widget.members) {
      _coTeacherMembers = _coTeachersFrom(widget.members, activeOnly: true);
    _pendingCoTeacherMembers = _coTeachersFrom(widget.members, activeOnly: false);
    }
  }

  List<Map<String, dynamic>> _coTeachersFrom(List<dynamic> members, {required bool activeOnly}) {
    return members
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .where((m) {
          if (m['roleInClass'] != 'co_teacher') return false;
          final status = m['status']?.toString();
          return activeOnly ? status == 'active' : status == 'pending';
        })
        .toList();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _coUsername.dispose();
    _googleCourseId.dispose();
    super.dispose();
  }

  Set<String> get _coTeacherUserIds {
    return {
      ..._coTeacherMembers.map(_memberUserId),
      ..._pendingCoTeacherMembers.map(_memberUserId),
    }.where((id) => id.isNotEmpty).toSet();
  }

  String _memberUserId(Map<String, dynamic> m) {
    final u = m['userId'];
    if (u is Map) return (u['id'] ?? u['_id'])?.toString() ?? '';
    return u?.toString() ?? '';
  }

  String _userDisplayName(Map<String, dynamic>? user) {
    if (user == null) return '—';
    final name = (user['fullName'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
    final username = (user['username'] as String?)?.trim();
    if (username != null && username.isNotEmpty) return username;
    final email = (user['email'] as String?)?.trim();
    if (email != null && email.isNotEmpty) return email;
    return '—';
  }

  String? _userUsername(Map<String, dynamic>? user) {
    final username = (user?['username'] as String?)?.trim();
    return username != null && username.isNotEmpty ? username : null;
  }

  String? _userEmail(Map<String, dynamic>? user) {
    final email = (user?['email'] as String?)?.trim();
    return email != null && email.isNotEmpty ? email : null;
  }

  String _userInitial(Map<String, dynamic>? user) {
    final label = _userDisplayName(user);
    if (label == '—') return '?';
    return label[0].toUpperCase();
  }

  void _onCoTeacherSearchChanged(String value) {
    _searchDebounce?.cancel();
    setState(() {});
    final q = value.trim();
    if (q.length < 2) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _searchDebounce = Timer(AppMotion.debounce, () => _runCoTeacherSearch(q));
  }

  Future<void> _runCoTeacherSearch(String query) async {
    final r = await getIt<TeacherExamRepository>().searchTeachersForCoTeacher(query);
    if (!mounted) return;
    r.fold(
      (_) => setState(() {
        _searchResults = [];
        _searching = false;
      }),
      (list) {
        final primaryId = widget.primaryTeacher is Map
            ? ((widget.primaryTeacher as Map)['id'] ?? (widget.primaryTeacher as Map)['_id'])?.toString()
            : widget.primaryTeacher?.toString();
        final blocked = {..._coTeacherUserIds, if (primaryId != null && primaryId.isNotEmpty) primaryId};
        setState(() {
          _searchResults = list
              .map((e) => Map<String, dynamic>.from(e as Map))
              .where((u) => !blocked.contains(u['id']?.toString()))
              .toList();
          _searching = false;
        });
      },
    );
  }

  Map<String, dynamic> _memberFromTeacherSearch(Map<String, dynamic> teacher) {
    return {
      'roleInClass': 'co_teacher',
      'status': 'pending',
      'userId': teacher,
    };
  }

  Map<String, dynamic> _normalizeAddedMember(dynamic raw, Map<String, dynamic> teacher) {
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      final u = m['userId'];
      if (u is Map && (u['username'] as String?)?.isNotEmpty == true) return m;
      if (u == null || u is! Map) {
        m['userId'] = teacher;
      }
      return m;
    }
    return _memberFromTeacherSearch(teacher);
  }

  Future<void> _addCoTeacher(Map<String, dynamic> teacher) async {
    final l10n = context.l10n;
    final teacherId = teacher['id']?.toString() ?? '';
    final username = (teacher['username'] as String?)?.trim() ?? '';
    if (username.isEmpty) return;
    setState(() => _addingTeacherId = teacherId);
    final r = await getIt<TeacherExamRepository>().addCoTeacher(widget.classroomId, username);
    if (!mounted) return;
    setState(() => _addingTeacherId = null);
    r.fold(
      (f) => AppCornerToast.show(context, f.message, error: true),
      (member) {
        final added = _normalizeAddedMember(member, teacher);
        final addedId = _memberUserId(added);
        final isPending = (added['status']?.toString() ?? '') == 'pending';
        setState(() {
          if (isPending) {
            _pendingCoTeacherMembers = [
              ..._pendingCoTeacherMembers.where((m) => _memberUserId(m) != addedId),
              added,
            ];
          } else {
            _coTeacherMembers = [
              ..._coTeacherMembers.where((m) => _memberUserId(m) != addedId),
              added,
            ];
          }
          _searchResults = _searchResults.where((u) => u['id']?.toString() != teacherId).toList();
          _coUsername.clear();
        });
        AppCornerToast.show(
          context,
          isPending ? l10n.teacherCoTeacherInviteSent : l10n.teacherCoTeacherAdded,
        );
        widget.onRefresh();
      },
    );
  }

  Future<void> _removeCoTeacher(Map<String, dynamic> member) async {
    final l10n = context.l10n;
    final uid = _memberUserId(member);
    if (uid.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.teacherCoTeacherRemove),
        content: Text(l10n.teacherCoTeacherRemoveConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.teacherCoTeacherRemove)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final r = await getIt<TeacherExamRepository>().removeCoTeacher(widget.classroomId, uid);
    if (!mounted) return;
    r.fold(
      (f) => AppCornerToast.show(context, f.message, error: true),
      (_) {
        setState(() {
          _coTeacherMembers = _coTeacherMembers.where((m) => _memberUserId(m) != uid).toList();
          _pendingCoTeacherMembers =
              _pendingCoTeacherMembers.where((m) => _memberUserId(m) != uid).toList();
        });
        AppCornerToast.show(context, l10n.teacherCoTeacherRemoved);
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
      (f) => AppCornerToast.show(context, f.message, error: true),
      (_) {
        AppCornerToast.show(context, l10n.teacherGoogleClassroomLink);
        widget.onRefresh();
      },
    );
  }

  Future<void> _unlinkGoogle() async {
    final l10n = context.l10n;
    final r = await getIt<TeacherExamRepository>().unlinkGoogleClassroom(widget.classroomId);
    if (!mounted) return;
    r.fold(
      (f) => AppCornerToast.show(context, f.message, error: true),
      (_) {
        AppCornerToast.show(context, l10n.teacherGoogleClassroomUnlink);
        widget.onRefresh();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gc = widget.integrations is Map ? (widget.integrations as Map)['googleClassroom'] : null;
    final gcName = gc is Map ? gc['courseName'] as String? : null;
    final primary = widget.primaryTeacher is Map
        ? Map<String, dynamic>.from(widget.primaryTeacher as Map)
        : null;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: TeacherWebUi.pageScrollPadding(context),
        children: [
          TeacherResponsiveColumns(
            left: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SettingsSectionCard(
                  title: l10n.teacherClassSettingsAbout,
                  icon: Icons.edit_note_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: widget.nameController,
                        decoration: InputDecoration(
                          labelText: l10n.teacherClassNameLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      TextField(
                        controller: widget.tagController,
                        decoration: InputDecoration(
                          labelText: l10n.teacherClassTagLabel,
                          hintText: l10n.teacherClassTagHint,
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
                                    child: AppLoadingIndicator.button(),
                                  )
                                : Text(l10n.teacherClassSaveSettings),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s5),
                _SettingsSectionCard(
                  title: l10n.teacherClassSettingsTeam,
                  icon: Icons.groups_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.teacherCoTeacherPrimaryTeacher, style: TeacherWebUi.webCaption(context)),
                      const SizedBox(height: AppSpacing.s3),
                      _TeacherPersonTile(
                        name: _userDisplayName(primary),
                        username: _userUsername(primary),
                        email: _userEmail(primary),
                        avatarUrl: primary?['avatarUrl'] as String?,
                        initial: _userInitial(primary),
                        badge: l10n.teacherCoTeacherPrimaryTeacher,
                        badgeColor: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.s6),
                      Text(l10n.teacherCoTeacherListTitle, style: TeacherWebUi.webCaption(context)),
                      const SizedBox(height: AppSpacing.s3),
                      if (_pendingCoTeacherMembers.isNotEmpty)
                        ..._pendingCoTeacherMembers.map((m) {
                          final user = m['userId'] is Map
                              ? Map<String, dynamic>.from(m['userId'] as Map)
                              : null;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                            child: _TeacherPersonTile(
                              name: _userDisplayName(user),
                              username: _userUsername(user),
                              email: _userEmail(user),
                              avatarUrl: user?['avatarUrl'] as String?,
                              initial: _userInitial(user),
                              badge: l10n.teacherCoTeacherPending,
                              badgeColor: AppColors.warning,
                              trailing: IconButton(
                                tooltip: l10n.teacherCoTeacherRemove,
                                icon: const Icon(Icons.person_remove_outlined, size: 20),
                                color: AppColors.danger,
                                onPressed: () => _removeCoTeacher(m),
                              ),
                            ),
                          );
                        }),
                      if (_coTeacherMembers.isEmpty && _pendingCoTeacherMembers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
                          child: Text(l10n.teacherCoTeacherNone, style: TeacherWebUi.metaMuted),
                        )
                      else
                        ..._coTeacherMembers.map((m) {
                          final user = m['userId'] is Map
                              ? Map<String, dynamic>.from(m['userId'] as Map)
                              : null;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                            child: _TeacherPersonTile(
                              name: _userDisplayName(user),
                              username: _userUsername(user),
                              email: _userEmail(user),
                              avatarUrl: user?['avatarUrl'] as String?,
                              initial: _userInitial(user),
                              trailing: IconButton(
                                tooltip: l10n.teacherCoTeacherRemove,
                                icon: const Icon(Icons.person_remove_outlined, size: 20),
                                color: AppColors.danger,
                                onPressed: () => _removeCoTeacher(m),
                              ),
                            ),
                          );
                        }),
                      const Divider(height: AppSpacing.s8, color: AppColors.outlineMuted),
                      Text(l10n.teacherCoTeacherAdd, style: TeacherWebUi.webCaption(context)),
                      const SizedBox(height: AppSpacing.s3),
                      TextField(
                        controller: _coUsername,
                        decoration: InputDecoration(
                          labelText: l10n.teacherCoTeacherUsernameHint,
                          hintText: l10n.teacherCoTeacherSearchPlaceholder,
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    child: AppLoadingIndicator.button(),
                                  ),
                                )
                              : (_coUsername.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _coUsername.clear();
                                        setState(() {
                                          _searchResults = [];
                                        });
                                      },
                                    )
                                  : null),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: _onCoTeacherSearchChanged,
                      ),
                      if (_coUsername.text.trim().length >= 2 && !_searching && _searchResults.isEmpty) ...[
                        const SizedBox(height: AppSpacing.s3),
                        Text(l10n.teacherCoTeacherSearchEmpty, style: TeacherWebUi.metaMuted),
                      ] else if (_searchResults.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.s3),
                        Material(
                          color: AppColors.surfaceSubtle,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            side: const BorderSide(color: AppColors.outline),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (var i = 0; i < _searchResults.length; i++) ...[
                                if (i > 0) const Divider(height: 1, color: AppColors.outlineMuted),
                                _CoTeacherSearchResultRow(
                                  teacher: _searchResults[i],
                                  adding: _addingTeacherId == _searchResults[i]['id']?.toString(),
                                  addLabel: l10n.teacherCoTeacherAdd,
                                  onAdd: () => _addCoTeacher(_searchResults[i]),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            right: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SettingsSectionCard(
                  title: l10n.teacherClassSettingsStats,
                  icon: Icons.insights_outlined,
                  child: Column(
                    children: [
                      _SettingsInfoRow(
                        icon: Icons.groups_outlined,
                        label: l10n.teacherClassStatStudents,
                        value: '${widget.activeMemberCount}',
                      ),
                      _SettingsInfoRow(
                        icon: Icons.hourglass_top_outlined,
                        label: l10n.teacherClassStatPendingMembers,
                        value: '${widget.pendingMemberCount}',
                      ),
                      _SettingsInfoRow(
                        icon: Icons.assignment_outlined,
                        label: l10n.teacherClassStatActiveAssignments,
                        value: '${widget.assignmentCount}',
                      ),
                      if (widget.createdAt != null)
                        _SettingsInfoRow(
                          icon: Icons.event_outlined,
                          label: l10n.teacherClassCreatedLabel,
                          value: widget.createdAt!,
                        ),
                      if (widget.updatedAt != null)
                        _SettingsInfoRow(
                          icon: Icons.update_outlined,
                          label: l10n.teacherClassUpdatedLabel,
                          value: widget.updatedAt!,
                        ),
                      if (widget.archived)
                        _SettingsInfoRow(
                          icon: Icons.archive_outlined,
                          label: l10n.teacherClassArchive,
                          value: l10n.teacherClassArchive,
                          valueColor: AppColors.warning,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s5),
                _SettingsSectionCard(
                  title: l10n.teacherClassSettingsInvite,
                  icon: Icons.link_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SettingsInfoRow(
                        icon: Icons.login_outlined,
                        label: l10n.teacherClassSettingsJoin,
                        value: widget.policy,
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Text(l10n.teacherInviteCode, style: TeacherWebUi.webCaption(context)),
                      const SizedBox(height: AppSpacing.s3),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: SelectableText(
                          widget.inviteCode.isEmpty ? '—' : widget.inviteCode,
                          style: TeacherWebUi.webH1(context).copyWith(
                            letterSpacing: 4,
                            color: AppColors.primaryDark,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      if (widget.inviteToken.isNotEmpty) ...[
                        Text(l10n.teacherInviteToken, style: TeacherWebUi.webCaption(context)),
                        const SizedBox(height: 4),
                        Text(l10n.teacherInviteTokenHint, style: TeacherWebUi.metaMuted),
                        const SizedBox(height: AppSpacing.s3),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: SelectableText(
                            widget.inviteToken,
                            style: TeacherWebUi.webBody(context).copyWith(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                      ],
                      TeacherInlineActions(
                        children: [
                          TeacherOutlinedButton(
                            label: l10n.copyInviteCode,
                            icon: Icons.copy_outlined,
                            onPressed: widget.inviteCode.isEmpty ? null : widget.onCopyInvite,
                          ),
                          if (widget.inviteToken.isNotEmpty)
                            TeacherOutlinedButton(
                              label: l10n.copyInviteToken,
                              icon: Icons.content_copy_outlined,
                              onPressed: widget.onCopyInviteToken,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s5),
                _SettingsSectionCard(
                  title: l10n.teacherIntegrationsTitle,
                  icon: Icons.extension_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (gcName != null && gcName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                          child: _SettingsInfoRow(
                            icon: Icons.school_outlined,
                            label: 'Google Classroom',
                            value: gcName,
                          ),
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
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s5),
                _SettingsSectionCard(
                  title: l10n.teacherClassSettingsDanger,
                  icon: Icons.settings_suggest_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TeacherInlineActions(
                        children: [
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
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s9),
        ],
      ),
    );
  }
}

class _CoTeacherSearchResultRow extends StatelessWidget {
  const _CoTeacherSearchResultRow({
    required this.teacher,
    required this.adding,
    required this.addLabel,
    required this.onAdd,
  });

  final Map<String, dynamic> teacher;
  final bool adding;
  final String addLabel;
  final VoidCallback onAdd;

  String _displayName() {
    final name = (teacher['fullName'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
    final username = (teacher['username'] as String?)?.trim();
    if (username != null && username.isNotEmpty) return username;
    return '—';
  }

  String? _username() {
    final username = (teacher['username'] as String?)?.trim();
    return username != null && username.isNotEmpty ? username : null;
  }

  String _initial() {
    final label = _displayName();
    return label != '—' ? label[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final username = _username();
    final teacherAvatar = TeacherWebUi.networkAvatar(teacher['avatarUrl'] as String?, logicalSize: 36);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryTint,
            backgroundImage: teacherAvatar,
            child: teacherAvatar == null
                ? Text(
                    _initial(),
                    style: TeacherWebUi.webCaption(context).copyWith(fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_displayName(), style: TeacherWebUi.listTitle(context)),
                if (username != null)
                  Text('@$username', style: TeacherWebUi.metaMuted),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (adding)
            const SizedBox(
              width: 28,
              height: 28,
              child: Padding(
                padding: EdgeInsets.all(4),
                child: AppLoadingIndicator(strokeWidth: 2),
              ),
            )
          else
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              onPressed: onAdd,
              child: Text(addLabel),
            ),
        ],
      ),
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s5),
      decoration: TeacherWebUi.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: TeacherWebUi.sectionTitle(context))),
            ],
          ),
          const SizedBox(height: AppSpacing.s5),
          child,
        ],
      ),
    );
  }
}

class _SettingsInfoRow extends StatelessWidget {
  const _SettingsInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TeacherWebUi.webCaption(context)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TeacherWebUi.webBody(context).copyWith(
                    color: valueColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherPersonTile extends StatelessWidget {
  const _TeacherPersonTile({
    required this.name,
    this.username,
    this.email,
    this.avatarUrl,
    required this.initial,
    this.badge,
    this.badgeColor,
    this.trailing,
  });

  final String name;
  final String? username;
  final String? email;
  final String? avatarUrl;
  final String initial;
  final String? badge;
  final Color? badgeColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final memberAvatar = TeacherWebUi.networkAvatar(avatarUrl, logicalSize: 40);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryTint,
            backgroundImage: memberAvatar,
            child: memberAvatar == null
                ? Text(initial, style: TeacherWebUi.webCaption(context).copyWith(fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TeacherWebUi.listTitle(context)),
                if (username != null) ...[
                  const SizedBox(height: 2),
                  Text('@$username', style: TeacherWebUi.metaMuted),
                ],
                if (email != null && email!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(email!, style: TeacherWebUi.metaMuted, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          if (badge != null)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppColors.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: (badgeColor ?? AppColors.primary).withValues(alpha: 0.35)),
              ),
              child: Text(
                badge!,
                style: TeacherWebUi.webCaption(context).copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: badgeColor ?? AppColors.primaryDark,
                ),
              ),
            ),
          if (trailing != null) trailing!,
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
