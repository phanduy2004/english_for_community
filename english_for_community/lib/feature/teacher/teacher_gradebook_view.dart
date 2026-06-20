import 'package:english_for_community/feature/teacher/bloc/gradebook/teacher_gradebook_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/gradebook/teacher_gradebook_derived.dart';
import 'package:english_for_community/feature/teacher/bloc/gradebook/teacher_gradebook_event.dart';
import 'package:english_for_community/feature/teacher/bloc/gradebook/teacher_gradebook_state.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_widgets.dart';
import 'package:english_for_community/feature/teacher/teacher_classroom_detail_page.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_attempt_grade_page.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_grading_page.dart';
import 'package:english_for_community/feature/teacher/teacher_gradebook_labels.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

const double _kStudentColWidth = 220;
const double _kAssignmentColWidth = 136;
const double _kRowHeight = TeacherWebUi.tableRowDefault;
const double _kHeaderHeight = 76;

/// Gradebook matrix — `docs/ui-ux-system/07` §2 + `08` gradebook.
class TeacherGradebookView extends StatefulWidget {
  const TeacherGradebookView({super.key, this.classroomId});

  final String? classroomId;

  @override
  State<TeacherGradebookView> createState() => _TeacherGradebookViewState();
}

class _TeacherGradebookViewState extends State<TeacherGradebookView> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openCell(BuildContext context, Map<String, dynamic> cell) {
    final assignmentId = cell['assignmentId'] as String? ?? '';
    final attemptId = cell['attemptId'] as String?;
    if (attemptId != null && attemptId.isNotEmpty) {
      context.push(TeacherExamAttemptGradePage.location(assignmentId, attemptId));
      return;
    }
    if (assignmentId.isNotEmpty) {
      context.push('${TeacherExamGradingPage.routePath}/$assignmentId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeacherGradebookBloc, TeacherGradebookState>(
      buildWhen: (p, c) =>
          p.assignments != c.assignments ||
          p.summary != c.summary ||
          p.classAverages != c.classAverages ||
          p.filteredRows != c.filteredRows ||
          p.visibleAssignments != c.visibleAssignments ||
          p.searchQuery != c.searchQuery ||
          p.modeFilter != c.modeFilter ||
          p.sort != c.sort ||
          p.hideEmpty != c.hideEmpty,
      builder: (context, state) => _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, TeacherGradebookState state) {
    final l10n = context.l10n;
    final assignments = state.visibleAssignments;
    final rows = state.filteredRows;
    final summary = state.summary;

    if (state.assignments.isEmpty) {
      return Center(
        child: TeacherEmptyCard(
          message: l10n.teacherGradebookNoAssignments,
          icon: Icons.assignment_outlined,
          actionLabel: widget.classroomId != null ? l10n.teacherEmptyGradebookCta : null,
          onAction: widget.classroomId != null
              ? () => context.push('${TeacherClassroomDetailPage.routePath}/${widget.classroomId}')
              : null,
        ),
      );
    }

    if (assignments.isEmpty) {
      return Center(
        child: TeacherEmptyCard(
          message: l10n.teacherGradebookNoColumnsForFilter,
          icon: Icons.filter_list_off_outlined,
        ),
      );
    }


    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summary != null) ...[
          _SummaryKpiRow(summary: summary, l10n: l10n),
          const SizedBox(height: AppSpacing.s4),
        ],
        _Toolbar(
          searchCtrl: _searchCtrl,
          query: state.searchQuery,
          onQueryChanged: (v) =>
              context.read<TeacherGradebookBloc>().add(TeacherGradebookSearchChanged(v)),
          modeFilter: state.modeFilter,
          onModeFilter: (v) =>
              context.read<TeacherGradebookBloc>().add(TeacherGradebookModeFilterChanged(v)),
          sort: state.sort,
          onSort: (v) => context.read<TeacherGradebookBloc>().add(TeacherGradebookSortChanged(v)),
          hideEmpty: state.hideEmpty,
          onHideEmpty: (v) =>
              context.read<TeacherGradebookBloc>().add(TeacherGradebookHideEmptyChanged(v)),
          resultCount: rows.length,
          l10n: l10n,
        ),
        const SizedBox(height: AppSpacing.s4),
        Expanded(
          child: DecoratedBox(
            decoration: TeacherWebUi.panelDecoration(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: rows.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.s7),
                        child: Text(
                          l10n.teacherGradebookNoStudentsMatch,
                          style: TeacherWebUi.webBody(context),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _StickyGradebookTable(
                      rows: rows,
                      assignments: assignments,
                      classAvgs: state.classAverages,
                      classAvgPercent: summary?['classAvgPercent'],
                      l10n: l10n,
                      onAssignmentTap: (id) => context.push('${TeacherExamGradingPage.routePath}/$id'),
                      onCellTap: (c) => _openCell(context, c),
                    ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        Text(
          l10n.teacherGradebookTapHint,
          style: TeacherWebUi.metaMuted.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

class _SummaryKpiRow extends StatelessWidget {
  const _SummaryKpiRow({required this.summary, required this.l10n});

  final Map<String, dynamic> summary;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final avg = summary['classAvgPercent'];
    final pending = (summary['pendingGradingCount'] as num?)?.toInt() ?? 0;
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 640;
        final children = [
          Expanded(
            child: TeacherKpiCard(
              icon: Icons.groups_outlined,
              value: '${summary['studentCount'] ?? 0}',
              label: l10n.teacherGradebookKpiStudents,
              accent: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: TeacherKpiCard(
              icon: Icons.assignment_outlined,
              value: '${summary['assignmentCount'] ?? 0}',
              label: l10n.teacherGradebookKpiAssignments,
              accent: AppColors.secondary,
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: TeacherKpiCard(
              icon: Icons.percent_outlined,
              value: avg is num ? '${avg.toStringAsFixed(avg % 1 == 0 ? 0 : 1)}%' : '—',
              label: l10n.teacherGradebookKpiClassAvg,
              accent: AppColors.tertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: TeacherKpiCard(
              icon: Icons.pending_actions_outlined,
              value: '$pending',
              label: l10n.teacherGradebookKpiPending,
              accent: pending > 0 ? AppColors.warning : AppColors.textMuted,
            ),
          ),
        ];
        if (wide) {
          return Row(children: children);
        }
        return Column(
          children: [
            Row(children: children.sublist(0, 2)),
            const SizedBox(height: AppSpacing.s3),
            Row(children: children.sublist(2)),
          ],
        );
      },
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.searchCtrl,
    required this.query,
    required this.onQueryChanged,
    required this.modeFilter,
    required this.onModeFilter,
    required this.sort,
    required this.onSort,
    required this.hideEmpty,
    required this.onHideEmpty,
    required this.resultCount,
    required this.l10n,
  });

  final TextEditingController searchCtrl;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final String? modeFilter;
  final ValueChanged<String?> onModeFilter;
  final TeacherGradebookSort sort;
  final ValueChanged<TeacherGradebookSort> onSort;
  final bool hideEmpty;
  final ValueChanged<bool> onHideEmpty;
  final int resultCount;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outlineMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: searchCtrl,
                  onChanged: onQueryChanged,
                  style: TeacherWebUi.webBody(context).copyWith(fontSize: 14),
                  decoration: TeacherWebUi.formInputDecoration(
                    context,
                    hintText: l10n.teacherGradebookSearchHint,
                  ).copyWith(
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  key: ValueKey(modeFilter),
                  initialValue: modeFilter,
                  isExpanded: true,
                  decoration: TeacherWebUi.formInputDecoration(context, hintText: l10n.teacherGradebookFilterMode),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.teacherGradebookFilterAllModes)),
                    DropdownMenuItem(value: 'self_paced', child: Text(l10n.examModeSelfPaced)),
                    DropdownMenuItem(value: 'scheduled', child: Text(l10n.examModeScheduled)),
                    DropdownMenuItem(value: 'realtime', child: Text(l10n.examModeRealtime)),
                  ],
                  onChanged: onModeFilter,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l10n.teacherGradebookSortLabel, style: TeacherWebUi.metaMuted.copyWith(fontSize: 12)),
              TeacherFilterChip(
                label: l10n.teacherGradebookSortName,
                selected: sort == TeacherGradebookSort.nameAsc,
                onSelected: () => onSort(TeacherGradebookSort.nameAsc),
              ),
              TeacherFilterChip(
                label: l10n.teacherGradebookSortAvg,
                selected: sort == TeacherGradebookSort.avgDesc,
                onSelected: () => onSort(TeacherGradebookSort.avgDesc),
              ),
              FilterChip(
                label: Text(l10n.teacherGradebookHideEmpty, style: const TextStyle(fontSize: 12)),
                selected: hideEmpty,
                onSelected: onHideEmpty,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
              ),
              Text(
                l10n.teacherGradebookShowingCount(resultCount),
                style: TeacherWebUi.metaMuted.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.assignments,
    required this.l10n,
    required this.onAssignmentTap,
  });

  final List<Map<String, dynamic>> assignments;
  final AppLocalizations l10n;
  final void Function(String assignmentId) onAssignmentTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kHeaderHeight,
      decoration: const BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border(bottom: BorderSide(color: AppColors.outlineMuted)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _kStudentColWidth,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  l10n.teacherGradebookStudent.toUpperCase(),
                  style: TeacherWebUi.webTableHead(context),
                ),
              ),
            ),
          ),
          ...assignments.map((a) {
            final id = a['id'] as String? ?? '';
            return _AssignmentHeaderCell(
              col: a,
              l10n: l10n,
              onTap: id.isNotEmpty ? () => onAssignmentTap(id) : null,
            );
          }),
          SizedBox(
            width: 88,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  l10n.teacherGradebookColAvg.toUpperCase(),
                  style: TeacherWebUi.webTableHead(context),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentHeaderCell extends StatelessWidget {
  const _AssignmentHeaderCell({required this.col, required this.l10n, this.onTap});

  final Map<String, dynamic> col;
  final AppLocalizations l10n;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = TeacherGradebookLabels.assignmentHeaderTitle(col);
    final short = (col['shortTitle'] as String?)?.trim() ?? title;
    final mode = TeacherGradebookLabels.assignmentHeaderSubtitle(l10n, col);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Tooltip(
          message: title,
          waitDuration: AppMotion.tooltipWait,
          child: Text(
            short,
            style: TeacherWebUi.webLabel(context).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              height: 1.25,
              color: onTap != null ? AppColors.primaryDark : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        Text(mode, style: TeacherWebUi.metaMuted.copyWith(fontSize: 10), maxLines: 1),
      ],
    );

    return SizedBox(
      width: _kAssignmentColWidth,
      child: onTap == null
          ? Padding(padding: const EdgeInsets.fromLTRB(8, 10, 8, 8), child: body)
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Padding(padding: const EdgeInsets.fromLTRB(8, 10, 8, 8), child: body),
              ),
            ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.row,
    required this.assignments,
    required this.l10n,
    required this.onCellTap,
  });

  final Map<String, dynamic> row;
  final List<Map<String, dynamic>> assignments;
  final AppLocalizations l10n;
  final void Function(Map<String, dynamic> cell) onCellTap;

  @override
  Widget build(BuildContext context) {
    final cells = (row['cells'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final name = TeacherGradebookLabels.studentLabel(row);
    final email = (row['email'] as String?)?.trim() ?? '';
    final rowAvg = row['rowAvgPercent'];

    return Container(
      height: _kRowHeight,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outlineMuted)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _kStudentColWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: TeacherWebUi.listTitle(context).copyWith(fontSize: 13, height: 1.15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      email,
                      style: TeacherWebUi.metaMuted.copyWith(fontSize: 10, height: 1.1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          ...assignments.map((a) {
            final id = a['id'] as String? ?? '';
            final cell = cells.firstWhere(
              (c) => c['assignmentId'] == id,
              orElse: () => <String, dynamic>{'assignmentId': id, 'status': 'not_started'},
            );
            return _ScoreCell(
              key: ValueKey('gb-cell-$id-${cell['attemptId'] ?? cell['status']}'),
              cell: cell,
              l10n: l10n,
              onTap: () => onCellTap(cell),
            );
          }),
          SizedBox(
            width: 88,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  rowAvg is num ? '${rowAvg.toStringAsFixed(rowAvg % 1 == 0 ? 0 : 1)}%' : '—',
                  style: TeacherWebUi.webBody(context).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: rowAvg is num ? AppColors.primaryDark : AppColors.textMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCell extends StatelessWidget {
  const _ScoreCell({super.key, required this.cell, required this.l10n, required this.onTap});

  final Map<String, dynamic> cell;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = TeacherGradebookLabels.cellPrimaryText(l10n, cell);
    final secondary = TeacherGradebookLabels.cellSecondaryText(l10n, cell);
    final scoreColor = TeacherGradebookLabels.scoreColor(cell);
    final tappable = TeacherGradebookLabels.cellIsTappable(cell);

    final secondaryStyle = cell['pendingGrading'] == true
        ? Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.warning,
              height: 1.1,
            )
        : TeacherWebUi.metaMuted.copyWith(fontSize: 10, height: 1.1);

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            primary,
            style: TeacherWebUi.webBody(context).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.15,
              color: scoreColor ?? AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (secondary != null) ...[
            const SizedBox(height: 1),
            Text(
              secondary,
              style: secondaryStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ],
        ],
      ),
    );

    return SizedBox(
      width: _kAssignmentColWidth,
      height: _kRowHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: tappable ? onTap : null,
          child: content,
        ),
      ),
    );
  }
}

class _ClassAverageRow extends StatelessWidget {
  const _ClassAverageRow({
    required this.assignments,
    required this.classAvgs,
    required this.classAvgPercent,
    required this.l10n,
  });

  final List<Map<String, dynamic>> assignments;
  final List<Map<String, dynamic>> classAvgs;
  final dynamic classAvgPercent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kRowHeight,
      decoration: BoxDecoration(
        color: AppColors.primaryTint.withValues(alpha: 0.35),
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _kStudentColWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                l10n.teacherGradebookClassAverage,
                style: TeacherWebUi.webBody(context).copyWith(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
          ...assignments.map((a) {
            final id = a['id'] as String? ?? '';
            final avg = classAvgs.firstWhere(
              (x) => x['assignmentId'] == id,
              orElse: () => <String, dynamic>{},
            );
            final pct = avg['avgPercent'];
            final sub = avg['submittedCount'] != null && avg['studentCount'] != null
                ? '${avg['submittedCount']}/${avg['studentCount']}'
                : null;
            return SizedBox(
              width: _kAssignmentColWidth,
              height: _kRowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      pct is num ? '${pct.toStringAsFixed(pct % 1 == 0 ? 0 : 1)}%' : '—',
                      style: TeacherWebUi.webBody(context).copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      maxLines: 1,
                    ),
                    if (sub != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        sub,
                        style: TeacherWebUi.metaMuted.copyWith(fontSize: 10, height: 1.1),
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          SizedBox(
            width: 88,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  classAvgPercent is num
                      ? '${classAvgPercent.toStringAsFixed(classAvgPercent % 1 == 0 ? 0 : 1)}%'
                      : '—',
                  style: TeacherWebUi.webBody(context).copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sticky cột tên + header; ListView.builder khi >100 hàng (`18` §5.5).
class _StickyGradebookTable extends StatefulWidget {
  const _StickyGradebookTable({
    required this.rows,
    required this.assignments,
    required this.classAvgs,
    required this.classAvgPercent,
    required this.l10n,
    required this.onAssignmentTap,
    required this.onCellTap,
  });

  final List<Map<String, dynamic>> rows;
  final List<Map<String, dynamic>> assignments;
  final List<Map<String, dynamic>> classAvgs;
  final dynamic classAvgPercent;
  final AppLocalizations l10n;
  final void Function(String assignmentId) onAssignmentTap;
  final void Function(Map<String, dynamic> cell) onCellTap;

  @override
  State<_StickyGradebookTable> createState() => _StickyGradebookTableState();
}

class _StickyGradebookTableState extends State<_StickyGradebookTable> {
  final ScrollController _vLeft = ScrollController();
  final ScrollController _vRight = ScrollController();
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _vLeft.addListener(_syncLeftToRight);
    _vRight.addListener(_syncRightToLeft);
  }

  void _syncLeftToRight() {
    if (_syncing || !_vRight.hasClients) return;
    _syncing = true;
    _vRight.jumpTo(_vLeft.offset);
    _syncing = false;
  }

  void _syncRightToLeft() {
    if (_syncing || !_vLeft.hasClients) return;
    _syncing = true;
    _vLeft.jumpTo(_vRight.offset);
    _syncing = false;
  }

  @override
  void dispose() {
    _vLeft.removeListener(_syncLeftToRight);
    _vRight.removeListener(_syncRightToLeft);
    _vLeft.dispose();
    _vRight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataWidth = widget.assignments.length * _kAssignmentColWidth + 88;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _kStudentColWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: _kHeaderHeight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          widget.l10n.teacherGradebookStudent.toUpperCase(),
                          style: TeacherWebUi.webTableHead(context),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _vLeft,
                      itemCount: widget.rows.length,
                      itemExtent: _kRowHeight,
                      itemBuilder: (context, i) {
                        final row = widget.rows[i];
                        final rowId = (row['userId'] ?? row['id'])?.toString() ?? '$i';
                        return RepaintBoundary(
                          key: ValueKey('gb-name-$rowId'),
                          child: _StudentNameCell(row: row),
                        );
                      },
                    ),
                  ),
                  _ClassAverageStudentCell(l10n: widget.l10n),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: dataWidth,
                  height: constraints.maxHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AssignmentHeadersRow(
                        assignments: widget.assignments,
                        l10n: widget.l10n,
                        onAssignmentTap: widget.onAssignmentTap,
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _vRight,
                          itemCount: widget.rows.length,
                          itemExtent: _kRowHeight,
                          itemBuilder: (context, i) {
                            final row = widget.rows[i];
                            final rowId = (row['userId'] ?? row['id'])?.toString() ?? '$i';
                            return RepaintBoundary(
                              key: ValueKey('gb-scores-$rowId'),
                              child: _StudentScoresRow(
                                row: row,
                                assignments: widget.assignments,
                                l10n: widget.l10n,
                                onCellTap: widget.onCellTap,
                                zebra: i.isOdd,
                              ),
                            );
                          },
                        ),
                      ),
                      _ClassAverageScoresRow(
                        assignments: widget.assignments,
                        classAvgs: widget.classAvgs,
                        classAvgPercent: widget.classAvgPercent,
                        l10n: widget.l10n,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StudentNameCell extends StatelessWidget {
  const _StudentNameCell({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final name = TeacherGradebookLabels.studentLabel(row);
    final email = (row['email'] as String?)?.trim() ?? '';
    return Container(
      height: _kRowHeight,
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(bottom: BorderSide(color: AppColors.outlineMuted)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: TeacherWebUi.listTitle(context).copyWith(fontSize: 13, height: 1.15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 1),
              Text(
                email,
                style: TeacherWebUi.metaMuted.copyWith(fontSize: 10, height: 1.1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AssignmentHeadersRow extends StatelessWidget {
  const _AssignmentHeadersRow({
    required this.assignments,
    required this.l10n,
    required this.onAssignmentTap,
  });

  final List<Map<String, dynamic>> assignments;
  final AppLocalizations l10n;
  final void Function(String assignmentId) onAssignmentTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kHeaderHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...assignments.map((a) {
            final id = a['id'] as String? ?? '';
            return _AssignmentHeaderCell(
              col: a,
              l10n: l10n,
              onTap: id.isNotEmpty ? () => onAssignmentTap(id) : null,
            );
          }),
          SizedBox(
            width: 88,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  l10n.teacherGradebookColAvg.toUpperCase(),
                  style: TeacherWebUi.webTableHead(context),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentScoresRow extends StatelessWidget {
  const _StudentScoresRow({
    required this.row,
    required this.assignments,
    required this.l10n,
    required this.onCellTap,
    this.zebra = false,
  });

  final Map<String, dynamic> row;
  final List<Map<String, dynamic>> assignments;
  final AppLocalizations l10n;
  final void Function(Map<String, dynamic> cell) onCellTap;
  final bool zebra;

  @override
  Widget build(BuildContext context) {
    final cells = (row['cells'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final rowAvg = row['rowAvgPercent'];
    return Container(
      height: _kRowHeight,
      color: zebra ? AppColors.surfaceSubtle : AppColors.surfaceCard,
      child: Row(
        children: [
          ...assignments.map((a) {
            final id = a['id'] as String? ?? '';
            final cell = cells.firstWhere(
              (c) => c['assignmentId'] == id,
              orElse: () => <String, dynamic>{'assignmentId': id, 'status': 'not_started'},
            );
            return _ScoreCell(
              key: ValueKey('gb-cell-$id-${cell['attemptId'] ?? cell['status']}'),
              cell: cell,
              l10n: l10n,
              onTap: () => onCellTap(cell),
            );
          }),
          SizedBox(
            width: 88,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  rowAvg is num ? '${rowAvg.toStringAsFixed(rowAvg % 1 == 0 ? 0 : 1)}%' : '—',
                  style: TeacherWebUi.webBody(context).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: rowAvg is num ? AppColors.primaryDark : AppColors.textMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassAverageStudentCell extends StatelessWidget {
  const _ClassAverageStudentCell({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kRowHeight,
      decoration: BoxDecoration(
        color: AppColors.primaryTint.withValues(alpha: 0.35),
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.teacherGradebookClassAverage,
            style: TeacherWebUi.webBody(context).copyWith(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class _ClassAverageScoresRow extends StatelessWidget {
  const _ClassAverageScoresRow({
    required this.assignments,
    required this.classAvgs,
    required this.classAvgPercent,
    required this.l10n,
  });

  final List<Map<String, dynamic>> assignments;
  final List<Map<String, dynamic>> classAvgs;
  final dynamic classAvgPercent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kRowHeight,
      decoration: BoxDecoration(
        color: AppColors.primaryTint.withValues(alpha: 0.35),
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: Row(
        children: [
          ...assignments.map((a) {
            final id = a['id'] as String? ?? '';
            final avg = classAvgs.firstWhere(
              (x) => x['assignmentId'] == id,
              orElse: () => <String, dynamic>{},
            );
            final pct = avg['avgPercent'];
            final sub = avg['submittedCount'] != null && avg['studentCount'] != null
                ? '${avg['submittedCount']}/${avg['studentCount']}'
                : null;
            return SizedBox(
              width: _kAssignmentColWidth,
              height: _kRowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      pct is num ? '${pct.toStringAsFixed(pct % 1 == 0 ? 0 : 1)}%' : '—',
                      style: TeacherWebUi.webBody(context).copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      maxLines: 1,
                    ),
                    if (sub != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        sub,
                        style: TeacherWebUi.metaMuted.copyWith(fontSize: 10, height: 1.1),
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          SizedBox(
            width: 88,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  classAvgPercent is num
                      ? '${classAvgPercent.toStringAsFixed(classAvgPercent % 1 == 0 ? 0 : 1)}%'
                      : '—',
                  style: TeacherWebUi.webBody(context).copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
