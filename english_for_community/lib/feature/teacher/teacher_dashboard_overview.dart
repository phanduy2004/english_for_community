import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/teacher/bloc/dashboard/teacher_dashboard_state.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_dashboard_layout.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
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

/// Stats-only dashboard body — single viewport, no task lists.
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
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final stacked = c.maxWidth < 880;
              final overview = _OverviewPanel(
                l10n: l10n,
                stats: stats,
                classCount: classrooms.length,
                onOpenExamBank: () => context.push(TeacherExamsListPage.routePath),
              );
              final activity = _ActivityPanel(
                l10n: l10n,
                stats: stats,
                classrooms: classrooms,
                needsActionCount: needsActionCount,
                liveCount: liveCount,
                activeAssignmentCount: activeAssignmentCount,
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 5, child: overview),
                    const SizedBox(height: AppSpacing.s4),
                    Expanded(flex: 4, child: activity),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: overview),
                  const SizedBox(width: AppSpacing.s4),
                  Expanded(flex: 4, child: activity),
                ],
              );
            },
          ),
        ),
        if (classrooms.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s6),
          _ClassroomStrip(
            l10n: l10n,
            classrooms: classrooms,
            memberCount: memberCount,
            onCreateClass: onCreateClass,
          ),
        ],
      ],
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    required this.l10n,
    required this.stats,
    required this.classCount,
    required this.onOpenExamBank,
  });

  final AppLocalizations l10n;
  final TeacherDashboardStatsSnapshot stats;
  final int classCount;
  final VoidCallback onOpenExamBank;

  @override
  Widget build(BuildContext context) {
    return TeacherDashboardPanel(
      expand: true,
      title: l10n.teacherDashboardOverview,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final gap = AppSpacing.s3;
                  final tileW = (c.maxWidth - gap) / 2;
                  final tileH = ((c.maxHeight - gap) / 2).floorToDouble();
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      _StatTile(
                        width: tileW,
                        height: tileH,
                        icon: Icons.school_outlined,
                        label: l10n.teacherDashboardStatStudents,
                        value: '${stats.totalStudents}',
                        accent: AppColors.primary,
                      ),
                      _StatTile(
                        width: tileW,
                        height: tileH,
                        icon: Icons.groups_outlined,
                        label: l10n.teacherDashboardStatClasses,
                        value: '$classCount',
                        accent: AppColors.primary,
                      ),
                      _StatTile(
                        width: tileW,
                        height: tileH,
                        icon: Icons.publish_outlined,
                        label: l10n.teacherDashboardStatPublishedExams,
                        value: '${stats.publishedExams}',
                        accent: AppColors.success,
                        onTap: onOpenExamBank,
                      ),
                      _StatTile(
                        width: tileW,
                        height: tileH,
                        icon: Icons.edit_note_outlined,
                        label: l10n.teacherDashboardStatDraftExams,
                        value: '${stats.draftExams}',
                        accent: AppColors.textSecondary,
                        onTap: onOpenExamBank,
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1, color: AppColors.outlineMuted),
            const SizedBox(height: AppSpacing.s3),
            Text(
              l10n.teacherDashboardSectionGrading,
              style: TeacherWebUi.webCaption(context).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.s2),
            Row(
              children: [
                Expanded(
                  child: _GradingMiniStat(
                    label: l10n.teacherDashboardGradingChipManual,
                    value: stats.manualGrading,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: _GradingMiniStat(
                    label: l10n.teacherDashboardGradingChipAi,
                    value: stats.aiGrading,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: _GradingMiniStat(
                    label: l10n.teacherDashboardGradingChipRelease,
                    value: stats.releasePending,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({
    required this.l10n,
    required this.stats,
    required this.classrooms,
    required this.needsActionCount,
    required this.liveCount,
    required this.activeAssignmentCount,
  });

  final AppLocalizations l10n;
  final TeacherDashboardStatsSnapshot stats;
  final List<dynamic> classrooms;
  final int needsActionCount;
  final int liveCount;
  final int activeAssignmentCount;

  @override
  Widget build(BuildContext context) {
    return TeacherDashboardPanel(
      expand: true,
      title: l10n.teacherDashboardActionItems,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: TeacherDashboardDividedList(
          scrollable: true,
          children: [
                  _ActivityRow(
                    icon: Icons.assignment_late_outlined,
                    label: l10n.teacherDashboardStatNeedsAction,
                    value: '$needsActionCount',
                    color: AppColors.warning,
                    onTap: () => context.push(TeacherInboxPage.location()),
                  ),
                  _ActivityRow(
                    icon: Icons.sensors_outlined,
                    label: l10n.teacherDashboardStatLiveModes,
                    value: '$liveCount',
                    color: AppColors.info,
                    onTap: () => context.push(TeacherInboxPage.location(filter: TeacherInboxFilter.live)),
                  ),
                  _ActivityRow(
                    icon: Icons.assignment_outlined,
                    label: l10n.teacherDashboardStatAssignments,
                    value: '$activeAssignmentCount',
                    color: AppColors.primary,
                    onTap: () => context.push(TeacherCalendarPage.routePath),
                  ),
                  if (stats.dueSoon > 0)
                    _ActivityRow(
                      icon: Icons.schedule_outlined,
                      label: l10n.teacherDashboardDueSoon,
                      value: '${stats.dueSoon}',
                      color: AppColors.warning,
                      onTap: () => context.push(TeacherCalendarPage.routePath),
                    ),
                  if (stats.pendingJoins > 0)
                    _ActivityRow(
                      icon: Icons.group_add_outlined,
                      label: l10n.teacherDashboardPendingJoins,
                      value: '${stats.pendingJoins}',
                      color: AppColors.success,
                      onTap: () => openFirstTeacherClassroom(context, classrooms),
                    ),
                ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.width,
    required this.height,
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.onTap,
  });

  final double width;
  final double height;
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outlineMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: accent),
          const Spacer(),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: TeacherWebUi.webKpiValue(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TeacherWebUi.webCaption(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: child,
      ),
    );
  }
}

class _GradingMiniStat extends StatelessWidget {
  const _GradingMiniStat({
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
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TeacherWebUi.webKpiValue(context).copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TeacherWebUi.webCaption(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: AppSpacing.s2),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Text(label, style: TeacherWebUi.webBody(context)),
              ),
              Text(
                value,
                style: TeacherWebUi.webKpiValue(context).copyWith(color: color),
              ),
              const SizedBox(width: AppSpacing.s2),
              Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassroomStrip extends StatelessWidget {
  const _ClassroomStrip({
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
    final visible = classrooms.take(4).toList();

    return DecoratedBox(
      decoration: TeacherWebUi.panelDecoration(bg: AppColors.surfaceSubtle),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s3, AppSpacing.s4, AppSpacing.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  l10n.teacherMyClassrooms,
                  style: TeacherWebUi.webCaption(context).copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton(
                  style: TeacherWebUi.linkActionStyle(context),
                  onPressed: classrooms.isEmpty ? onCreateClass : () => openFirstTeacherClassroom(context, classrooms),
                  child: Text(l10n.teacherDashboardShortcutOpen),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s2),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: visible.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s2),
                itemBuilder: (context, i) {
                  final m = Map<String, dynamic>.from(visible[i] as Map);
                  final id = m['id'] as String? ?? '';
                  final name = (m['name'] as String?)?.trim() ?? l10n.teacherDashboardStudentUnknown;
                  final count = memberCount(m, 'memberCountActive');
                  final code = (m['inviteCode'] as String?)?.trim() ?? '';
                  return _ClassroomChip(
                    key: ValueKey(id),
                    name: name,
                    meta: l10n.teacherClassroomMemberCountActive(count),
                    inviteCode: code,
                    onOpen: id.isEmpty
                        ? () {}
                        : () => context.push('${TeacherClassroomDetailPage.routePath}/$id'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassroomChip extends StatelessWidget {
  const _ClassroomChip({
    super.key,
    required this.name,
    required this.meta,
    required this.inviteCode,
    required this.onOpen,
  });

  final String name;
  final String meta;
  final String inviteCode;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          width: 220,
          decoration: TeacherWebUi.panelDecoration(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
          child: Row(
            children: [
              const Icon(Icons.groups_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: TeacherWebUi.listTitle(context).copyWith(fontSize: 13, height: 1.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      meta,
                      style: TeacherWebUi.webCaption(context).copyWith(height: 1.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (inviteCode.isNotEmpty)
                IconButton(
                  style: TeacherWebUi.compactHeaderIconStyle(),
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: inviteCode));
                  },
                  icon: const Icon(Icons.copy_outlined, size: 14),
                  tooltip: MaterialLocalizations.of(context).copyButtonLabel,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
