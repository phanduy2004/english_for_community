import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/teacher/bloc/dashboard/teacher_dashboard_state.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_dashboard_layout.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_page_scaffold.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_widgets.dart';
import 'package:english_for_community/feature/teacher/teacher_calendar_page.dart';
import 'package:english_for_community/feature/teacher/teacher_classroom_detail_page.dart';
import 'package:english_for_community/feature/teacher/teacher_dashboard_inbox_builder.dart';
import 'package:english_for_community/feature/teacher/teacher_exams_list_page.dart';
import 'package:english_for_community/feature/teacher/teacher_inbox_page.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Derived numbers for the stats-only dashboard.
class TeacherDashboardStatsSnapshot {
  const TeacherDashboardStatsSnapshot({
    required this.totalStudents,
    required this.publishedExams,
    required this.draftExams,
    required this.manualGrading,
    required this.aiGrading,
    required this.releasePending,
    required this.pendingJoins,
    required this.dueSoon,
  });

  final int totalStudents;
  final int publishedExams;
  final int draftExams;
  final int manualGrading;
  final int aiGrading;
  final int releasePending;
  final int pendingJoins;
  final int dueSoon;

  int get needsActionCount => manualGrading + aiGrading + releasePending;
}

TeacherDashboardStatsSnapshot computeTeacherDashboardStats({
  required List<dynamic> classrooms,
  required List<dynamic> exams,
  required List<TeacherGradingQueueItem> gradingQueue,
  required Map<String, dynamic>? actionItems,
  required int Function(Map<String, dynamic> m, String key) memberCount,
}) {
  var students = 0;
  for (final raw in classrooms) {
    final m = Map<String, dynamic>.from(raw as Map);
    students += memberCount(m, 'memberCountActive');
  }

  var published = 0;
  var draft = 0;
  for (final raw in exams) {
    final m = Map<String, dynamic>.from(raw as Map);
    final status = m['status'] as String? ?? '';
    if (status == 'published') published++;
    if (status == 'draft') draft++;
  }

  var manual = 0;
  var ai = 0;
  var release = 0;
  for (final it in gradingQueue) {
    if (it.gradingState == 'pending_manual') {
      manual++;
    } else if (it.gradingState == 'pending_ai') {
      ai++;
    } else if (it.gradingState == 'finalized' && !it.resultsReleased) {
      release++;
    }
  }

  final pendingJoins = (actionItems?['pendingJoins'] as List? ?? []).length;
  final dueSoon = (actionItems?['dueSoon'] as List? ?? []).length;

  return TeacherDashboardStatsSnapshot(
    totalStudents: students,
    publishedExams: published,
    draftExams: draft,
    manualGrading: manual,
    aiGrading: ai,
    releasePending: release,
    pendingJoins: pendingJoins,
    dueSoon: dueSoon,
  );
}

/// v5.2 — đơn giản: KPI = điều hướng; lớp = nội dung chính; panel phụ = số liệu + cảnh báo phụ.
class TeacherDashboardOverviewBody extends StatelessWidget {
  const TeacherDashboardOverviewBody({
    super.key,
    required this.l10n,
    required this.stats,
    required this.classrooms,
    required this.needsActionCount,
    required this.liveCount,
    required this.activeAssignmentCount,
    required this.onCreateClass,
    required this.memberCount,
  });

  final AppLocalizations l10n;
  final TeacherDashboardStatsSnapshot stats;
  final List<dynamic> classrooms;
  final int needsActionCount;
  final int liveCount;
  final int activeAssignmentCount;
  final VoidCallback onCreateClass;
  final int Function(Map<String, dynamic> m, String key) memberCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PrimaryKpiRow(
          l10n: l10n,
          needsActionCount: needsActionCount,
          liveCount: liveCount,
          classCount: classrooms.length,
          activeAssignmentCount: activeAssignmentCount,
          classrooms: classrooms,
          onCreateClass: onCreateClass,
        ),
        const SizedBox(height: AppSpacing.s5),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final stacked = c.maxWidth < 900;
              final classroomsPanel = _ClassroomsPanel(
                l10n: l10n,
                classrooms: classrooms,
                memberCount: memberCount,
                onCreateClass: onCreateClass,
              );
              final sidePanel = _WorkspaceSidePanel(
                l10n: l10n,
                stats: stats,
                classrooms: classrooms,
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: classroomsPanel),
                    const SizedBox(height: AppSpacing.s4),
                    Expanded(flex: 2, child: sidePanel),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: classroomsPanel),
                  const SizedBox(width: AppSpacing.s5),
                  Expanded(flex: 2, child: sidePanel),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Hàng KPI duy nhất — mỗi ô một đích đến (doc `17` §2.1).
class _PrimaryKpiRow extends StatelessWidget {
  const _PrimaryKpiRow({
    required this.l10n,
    required this.needsActionCount,
    required this.liveCount,
    required this.classCount,
    required this.activeAssignmentCount,
    required this.classrooms,
    required this.onCreateClass,
  });

  final AppLocalizations l10n;
  final int needsActionCount;
  final int liveCount;
  final int classCount;
  final int activeAssignmentCount;
  final List<dynamic> classrooms;
  final VoidCallback onCreateClass;

  @override
  Widget build(BuildContext context) {
    return TeacherKpiGrid(
      children: [
        TeacherKpiCard(
          icon: Icons.assignment_late_outlined,
          value: '$needsActionCount',
          label: l10n.teacherDashboardStatNeedsAction,
          accent: needsActionCount > 0 ? AppColors.warning : AppColors.textSecondary,
          onTap: () => context.push(TeacherInboxPage.location()),
        ),
        TeacherKpiCard(
          icon: Icons.sensors_outlined,
          value: '$liveCount',
          label: l10n.teacherDashboardStatLiveModes,
          accent: liveCount > 0 ? AppColors.info : AppColors.textSecondary,
          onTap: () => context.push(TeacherInboxPage.location(filter: TeacherInboxFilter.live)),
        ),
        TeacherKpiCard(
          icon: Icons.assignment_outlined,
          value: '$activeAssignmentCount',
          label: l10n.teacherDashboardStatAssignments,
          accent: AppColors.primary,
          onTap: () => context.push(TeacherCalendarPage.routePath),
        ),
        TeacherKpiCard(
          icon: Icons.groups_outlined,
          value: '$classCount',
          label: l10n.teacherDashboardStatClasses,
          accent: AppColors.primary,
          onTap: classCount == 0 ? onCreateClass : () => openFirstTeacherClassroom(context, classrooms),
        ),
      ],
    );
  }
}

class _ClassroomsPanel extends StatelessWidget {
  const _ClassroomsPanel({
    required this.l10n,
    required this.classrooms,
    required this.memberCount,
    required this.onCreateClass,
  });

  final AppLocalizations l10n;
  final List<dynamic> classrooms;
  final int Function(Map<String, dynamic> m, String key) memberCount;
  final VoidCallback onCreateClass;

  @override
  Widget build(BuildContext context) {
    return TeacherDashboardPanel(
      expand: true,
      title: l10n.teacherMyClassrooms,
      trailing: OutlinedButton(
        style: TeacherWebUi.compactOutlinedStyle(context),
        onPressed: onCreateClass,
        child: Text(l10n.teacherClassCreateTitle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: classrooms.isEmpty
            ? Center(
                child: TeacherEmptyCard(
                  message: l10n.teacherClassCreateTitle,
                  icon: Icons.groups_outlined,
                  actionLabel: l10n.teacherClassCreateTitle,
                  onAction: onCreateClass,
                ),
              )
            : LayoutBuilder(
                builder: (context, c) {
                  return SingleChildScrollView(
                    child: TeacherCardGrid(
                      children: [
                        for (var i = 0; i < classrooms.length; i++)
                          _ClassroomGridTile(
                            key: ValueKey(classrooms[i] is Map ? (classrooms[i] as Map)['id'] : i),
                            l10n: l10n,
                            classroom: classrooms[i],
                            memberCount: memberCount,
                            index: i,
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _ClassroomGridTile extends StatelessWidget {
  const _ClassroomGridTile({
    super.key,
    required this.l10n,
    required this.classroom,
    required this.memberCount,
    required this.index,
  });

  final AppLocalizations l10n;
  final dynamic classroom;
  final int Function(Map<String, dynamic> m, String key) memberCount;
  final int index;

  @override
  Widget build(BuildContext context) {
    final m = Map<String, dynamic>.from(classroom as Map);
    final id = m['id'] as String? ?? '';
    final name = (m['name'] as String?)?.trim() ?? l10n.teacherDashboardStudentUnknown;
    final count = memberCount(m, 'memberCountActive');
    final code = (m['inviteCode'] as String?)?.trim() ?? '';

    return TeacherDashboardClassroomTile(
      index: index,
      name: name,
      meta: l10n.teacherClassroomMemberCountActive(count),
      inviteCode: code.isEmpty ? null : code,
      onCopyCode: code.isEmpty ? null : () => Clipboard.setData(ClipboardData(text: code)),
      onOpen: id.isEmpty ? () {} : () => context.push('${TeacherClassroomDetailPage.routePath}/$id'),
    );
  }
}

/// Số liệu đọc + cảnh báo phụ (không lặp KPI inbox/live/assignments).
class _WorkspaceSidePanel extends StatelessWidget {
  const _WorkspaceSidePanel({
    required this.l10n,
    required this.stats,
    required this.classrooms,
  });

  final AppLocalizations l10n;
  final TeacherDashboardStatsSnapshot stats;
  final List<dynamic> classrooms;

  @override
  Widget build(BuildContext context) {
    final alerts = _secondaryAlerts(context);

    return TeacherDashboardPanel(
      expand: true,
      title: l10n.teacherDashboardOverview,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _SnapshotStat(
                    label: l10n.teacherDashboardStatStudents,
                    value: '${stats.totalStudents}',
                    icon: Icons.school_outlined,
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: _SnapshotStat(
                    label: l10n.teacherDashboardStatPublishedExams,
                    value: '${stats.publishedExams}',
                    icon: Icons.publish_outlined,
                    onTap: () => context.push(TeacherExamsListPage.routePath),
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: _SnapshotStat(
                    label: l10n.teacherDashboardStatDraftExams,
                    value: '${stats.draftExams}',
                    icon: Icons.edit_note_outlined,
                    onTap: () => context.push(TeacherExamsListPage.routePath),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              l10n.teacherDashboardSectionGrading,
              style: TeacherWebUi.webCaption(context).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.s2),
            Row(
              children: [
                Expanded(child: _GradingChip(label: l10n.teacherDashboardGradingChipManual, value: stats.manualGrading, color: AppColors.warning)),
                const SizedBox(width: AppSpacing.s2),
                Expanded(child: _GradingChip(label: l10n.teacherDashboardGradingChipAi, value: stats.aiGrading, color: AppColors.info)),
                const SizedBox(width: AppSpacing.s2),
                Expanded(child: _GradingChip(label: l10n.teacherDashboardGradingChipRelease, value: stats.releasePending, color: AppColors.success)),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            const Divider(height: 1, color: AppColors.outlineMuted),
            const SizedBox(height: AppSpacing.s3),
            Expanded(
              child: alerts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                        child: Text(
                          l10n.teacherDashboardWorkZoneSubtitle,
                          style: TeacherWebUi.metaMuted,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.teacherDashboardActionItems,
                          style: TeacherWebUi.webCaption(context).copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.s2),
                        Expanded(
                          child: TeacherDashboardDividedList(
                            scrollable: true,
                            children: alerts,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _secondaryAlerts(BuildContext context) {
    final rows = <Widget>[];
    if (stats.pendingJoins > 0) {
      rows.add(
        _AlertRow(
          icon: Icons.group_add_outlined,
          label: l10n.teacherDashboardPendingJoins,
          detail: l10n.teacherDashboardPendingJoinsCount(stats.pendingJoins),
          color: AppColors.success,
          onTap: () => openFirstTeacherClassroom(context, classrooms),
        ),
      );
    }
    if (stats.dueSoon > 0) {
      rows.add(
        _AlertRow(
          icon: Icons.schedule_outlined,
          label: l10n.teacherDashboardDueSoon,
          detail: l10n.teacherDashboardDueSoonCount(stats.dueSoon),
          color: AppColors.warning,
          onTap: () => context.push(TeacherCalendarPage.routePath),
        ),
      );
    }
    return rows;
  }
}

class _SnapshotStat extends StatelessWidget {
  const _SnapshotStat({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outlineMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.s2),
          Text(value, style: TeacherWebUi.webKpiValue(context)),
          const SizedBox(height: AppSpacing.s1),
          Text(
            label,
            style: TeacherWebUi.webCaption(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        hoverColor: AppColors.hoverOverlay,
        child: content,
      ),
    );
  }
}

class _GradingChip extends StatelessWidget {
  const _GradingChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: TeacherWebUi.webKpiValue(context).copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: TeacherWebUi.webCaption(context), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.icon,
    required this.label,
    required this.detail,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String detail;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: AppSpacing.s3),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TeacherWebUi.webBody(context)),
                    Text(detail, style: TeacherWebUi.metaMuted),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted.withValues(alpha: 0.75)),
            ],
          ),
        ),
      ),
    );
  }
}
