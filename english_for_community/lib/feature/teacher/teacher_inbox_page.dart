import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_skeleton.dart';
import 'package:english_for_community/core/ui/widget/web_data_table.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/teacher/bloc/dashboard/teacher_dashboard_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/dashboard/teacher_dashboard_derived.dart';
import 'package:english_for_community/feature/teacher/bloc/dashboard/teacher_dashboard_event.dart';
import 'package:english_for_community/feature/teacher/bloc/dashboard/teacher_dashboard_state.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_dashboard_layout.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_page_scaffold.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_widgets.dart';
import 'package:english_for_community/feature/teacher/teacher_assignment_list_utils.dart';
import 'package:english_for_community/feature/teacher/teacher_dashboard_inbox_builder.dart';
import 'package:english_for_community/feature/teacher/teacher_dashboard_page.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Action queue — grading, live, pending joins (not on dashboard).
class TeacherInboxPage extends StatelessWidget {
  const TeacherInboxPage({super.key, this.initialFilter = TeacherInboxFilter.all});

  static const String routePath = 'inbox';
  static const String routeName = 'TeacherInboxPage';

  final TeacherInboxFilter initialFilter;

  static String location({TeacherInboxFilter filter = TeacherInboxFilter.all}) {
    if (filter == TeacherInboxFilter.all) return '${TeacherDashboardPage.routePath}/$routePath';
    return '${TeacherDashboardPage.routePath}/$routePath?filter=${filter.name}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TeacherDashboardBloc>()..add(const TeacherDashboardLoadRequested()),
      child: _TeacherInboxView(initialFilter: initialFilter),
    );
  }
}

class _TeacherInboxView extends StatefulWidget {
  const _TeacherInboxView({required this.initialFilter});

  final TeacherInboxFilter initialFilter;

  @override
  State<_TeacherInboxView> createState() => _TeacherInboxViewState();
}

class _TeacherInboxViewState extends State<_TeacherInboxView> {
  late TeacherInboxFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  void _reload() {
    context.read<TeacherDashboardBloc>().add(const TeacherDashboardLoadRequested());
  }

  String _gradingChipLabel(AppLocalizations l10n, TeacherGradingQueueItem it) {
    if (it.gradingState == 'pending_manual') return l10n.teacherDashboardGradingChipManual;
    if (it.gradingState == 'pending_ai') return l10n.teacherDashboardGradingChipAi;
    if (it.gradingState == 'finalized' && !it.resultsReleased) {
      return l10n.teacherDashboardGradingChipRelease;
    }
    return it.gradingState;
  }

  String _classNameFromAssignment(Map<String, dynamic> m) {
    return TeacherAssignmentListUtils.classroomNameFromAssignment(m) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<TeacherDashboardBloc, TeacherDashboardState>(
      builder: (context, state) {
        final loading = state.status == TeacherDashboardStatus.loading && state.classrooms.isEmpty;
        final error = state.status == TeacherDashboardStatus.error ? state.errorMessage : null;

        return TeacherPageScaffold(
          scrollable: false,
          showBack: true,
          title: l10n.teacherDashboardActionItems,
          subtitle: l10n.teacherDashboardWorkZoneSubtitle,
          breadcrumbs: [
            TeacherBreadcrumb(label: l10n.teacherNavDashboard, location: TeacherDashboardPage.routePath),
            TeacherBreadcrumb(label: l10n.teacherDashboardActionItems),
          ],
          actions: [
            IconButton(
              style: TeacherWebUi.compactHeaderIconStyle(),
              onPressed: _reload,
              icon: const Icon(Icons.refresh_outlined, size: 18),
              color: AppColors.textSecondary,
              tooltip: l10n.retry,
            ),
          ],
          body: loading
              ? TeacherSkeleton.page(TeacherSkeleton.table(rows: 5))
              : error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(error, style: TeacherWebUi.webBody(context)),
                          const SizedBox(height: AppSpacing.s5),
                          TeacherRetryButton(onPressed: _reload),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _InboxFilterBar(
                          filter: _filter,
                          l10n: l10n,
                          onChanged: (f) => setState(() => _filter = f),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        TeacherDashboardLegendBar(l10n: l10n),
                        const SizedBox(height: AppSpacing.s4),
                        Expanded(
                          child: _InboxListBody(
                            state: state,
                            filter: _filter,
                            gradingChipLabel: _gradingChipLabel,
                            classNameFromAssignment: _classNameFromAssignment,
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }
}

class _InboxFilterBar extends StatelessWidget {
  const _InboxFilterBar({
    required this.filter,
    required this.l10n,
    required this.onChanged,
  });

  final TeacherInboxFilter filter;
  final AppLocalizations l10n;
  final ValueChanged<TeacherInboxFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s2,
      runSpacing: AppSpacing.s2,
      children: [
        TeacherFilterChip(
          label: l10n.teacherDashboardFilterAll,
          selected: filter == TeacherInboxFilter.all,
          onSelected: () => onChanged(TeacherInboxFilter.all),
        ),
        TeacherFilterChip(
          label: l10n.teacherDashboardSectionGrading,
          selected: filter == TeacherInboxFilter.grading,
          onSelected: () => onChanged(TeacherInboxFilter.grading),
        ),
        TeacherFilterChip(
          label: l10n.teacherDashboardSectionLive,
          selected: filter == TeacherInboxFilter.live,
          onSelected: () => onChanged(TeacherInboxFilter.live),
        ),
      ],
    );
  }
}

class _InboxListBody extends StatelessWidget {
  const _InboxListBody({
    required this.state,
    required this.filter,
    required this.gradingChipLabel,
    required this.classNameFromAssignment,
  });

  final TeacherDashboardState state;
  final TeacherInboxFilter filter;
  final String Function(AppLocalizations l10n, TeacherGradingQueueItem it) gradingChipLabel;
  final String Function(Map<String, dynamic> m) classNameFromAssignment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entries = buildTeacherDashboardInboxEntries(
      context: context,
      l10n: l10n,
      gradingQueue: state.gradingQueue,
      assignments: state.assignments,
      actionItems: state.actionItems,
      classrooms: state.classrooms,
      gradingChipLabel: gradingChipLabel,
      examTitleFromAssignment: (m) => teacherDashboardExamTitleFromAssignment(
        m,
        fallback: l10n.studentExamUnknownTitle,
      ),
      classNameFromAssignment: classNameFromAssignment,
      filter: filter,
    );

    if (state.gradingLoading) {
      return TeacherSkeleton.table(rows: 5);
    }

    if (entries.isEmpty) {
      return Center(
        child: TeacherEmptyCard(
          message: l10n.teacherDashboardGradingEmpty,
          icon: Icons.inbox_outlined,
          actionLabel: l10n.teacherEmptyInboxCta,
          onAction: () => context.go(TeacherDashboardPage.routePath),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(l10n.teacherCalendarSectionToday, style: TeacherWebUi.sectionTitle(context)),
            const SizedBox(width: AppSpacing.s2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.outlineMuted),
              ),
              child: Text(
                l10n.teacherInboxItemCount(entries.length),
                style: TeacherWebUi.webCaption(context).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        Expanded(
          child: WebDataTable(
            columns: [
              WebTableColumn(label: l10n.teacherDashboardActionItems, flex: 4),
              WebTableColumn(label: l10n.teacherInboxColType, width: 150),
              WebTableColumn(label: l10n.teacherDashboardFilterByClass, flex: 2),
              WebTableColumn(label: l10n.teacherInboxColTime, width: 120),
              const WebTableColumn(label: '', width: 56, align: Alignment.center),
            ],
            rowCount: entries.length,
            decoration: TeacherWebUi.panelDecoration(),
            headStyle: TeacherWebUi.webTableHead(context),
            scrollable: true,
            onRowTap: (row) => entries[row].onTap,
            cellBuilder: (context, row, col) {
              final entry = entries[row];
              return switch (col) {
                0 => _inboxWorkCell(context, entry),
                1 => TeacherStatusPill(label: entry.badge, tone: _toneForKind(entry.kind)),
                2 => _singleLineMeta(context, entry.classroomName ?? '—'),
                3 => _singleLineMeta(context, entry.timestamp ?? '—'),
                _ => _inboxActionMenu(context, entry),
              };
            },
          ),
        ),
      ],
    );
  }

  Widget _inboxWorkCell(BuildContext context, TeacherDashboardInboxEntry entry) {
    final accent = TeacherDashboardInboxStyle.color(entry.kind);
    final icon = TeacherDashboardInboxStyle.icon(entry.kind);
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: Icon(icon, size: 16, color: accent),
        ),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.title,
                style: TeacherWebUi.webBody(context).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (entry.subtitle != null && entry.subtitle!.isNotEmpty)
                Text(
                  entry.subtitle!,
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

  Widget _singleLineMeta(BuildContext context, String value) {
    return Text(
      value,
      style: TeacherWebUi.webCaption(context).copyWith(color: AppColors.textSecondary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _inboxActionMenu(BuildContext context, TeacherDashboardInboxEntry entry) {
    return PopupMenuButton<String>(
      tooltip: context.l10n.teacherExamMoreActions,
      icon: const Icon(Icons.more_horiz, size: 18, color: AppColors.textSecondary),
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      onSelected: (_) => entry.onTap(),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'open',
          child: _teacherInboxMenuAction(TeacherDashboardInboxStyle.icon(entry.kind), context.l10n.teacherClassOpenAttemptsList),
        ),
      ],
    );
  }

  TeacherStatusTone _toneForKind(TeacherDashboardInboxKind kind) => switch (kind) {
        TeacherDashboardInboxKind.grading => TeacherStatusTone.secondary,
        TeacherDashboardInboxKind.live => TeacherStatusTone.primary,
        TeacherDashboardInboxKind.dueSoon => TeacherStatusTone.danger,
        TeacherDashboardInboxKind.pendingJoin => TeacherStatusTone.success,
      };
}

/// Dialog row for full grading queue (shared).
class TeacherInboxGradingRow extends StatelessWidget {
  const TeacherInboxGradingRow({
    super.key,
    required this.item,
    required this.chipLabel,
    required this.onTap,
    this.classroomName,
  });

  final TeacherGradingQueueItem item;
  final String chipLabel;
  final VoidCallback onTap;
  final String? classroomName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final when = item.submittedAt != null
        ? DateFormat.yMMMd(locale).add_Hm().format(item.submittedAt!.toLocal())
        : null;
    final classLabel = (classroomName ?? item.classroomName ?? '').trim().isNotEmpty
        ? (classroomName ?? item.classroomName)!.trim()
        : l10n.teacherInboxPublicAssignment;

    return TeacherDashboardInboxCard(
      entry: TeacherDashboardInboxEntry(
        kind: TeacherDashboardInboxKind.grading,
        title: item.studentLabel,
        subtitle: item.assignmentTitle,
        classroomName: classLabel,
        timestamp: when,
        badge: chipLabel,
        onTap: onTap,
      ),
    );
  }
}

Widget _teacherInboxMenuAction(IconData icon, String label, {bool danger = false}) {
  final color = danger ? AppColors.danger : AppColors.textPrimary;
  return Row(
    children: [
      Icon(icon, size: 16, color: danger ? AppColors.danger : AppColors.textSecondary),
      const SizedBox(width: AppSpacing.s3),
      Text(label, style: TextStyle(color: color)),
    ],
  );
}
