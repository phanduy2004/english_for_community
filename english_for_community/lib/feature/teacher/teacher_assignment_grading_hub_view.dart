import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_skeleton.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/core/ui/widget/web_data_table.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart' show AppSpacing;
import 'package:english_for_community/feature/teacher/bloc/grading_hub/teacher_grading_hub_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/grading_hub/teacher_grading_hub_event.dart';
import 'package:english_for_community/feature/teacher/bloc/grading_hub/teacher_grading_hub_filter.dart';
import 'package:english_for_community/feature/teacher/bloc/grading_hub/teacher_grading_hub_state.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_card_ui.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_grading_hub_context_header.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/teacher_classroom_detail_page.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_release_results_dialog.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_attempt_grade_page.dart';
import 'package:english_for_community/feature/teacher/teacher_grading_hub_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Loads and displays student attempts for one assignment (grading hub).
class TeacherAssignmentGradingHubView extends StatelessWidget {
  const TeacherAssignmentGradingHubView({
    super.key,
    required this.assignmentId,
    this.scrollController,
    this.padding,
    this.showPageHeader = true,
    this.useParentBloc = false,
    this.examTitleHint,
  });

  final String assignmentId;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;
  /// When false, page scaffold already shows title + batch actions (`TeacherExamGradingPage`).
  final bool showPageHeader;
  final bool useParentBloc;
  final String? examTitleHint;

  @override
  Widget build(BuildContext context) {
    final hub = BlocConsumer<TeacherGradingHubBloc, TeacherGradingHubState>(
      listenWhen: (p, c) => c.errorMessage != null && p.errorMessage != c.errorMessage,
      buildWhen: (p, c) =>
          p.status != c.status ||
          p.errorMessage != c.errorMessage ||
          p.assignment != c.assignment ||
          p.stats != c.stats ||
          p.visibleAttempts != c.visibleAttempts ||
          p.batchAiRunning != c.batchAiRunning ||
          p.batchOpsRunning != c.batchOpsRunning ||
          p.attemptMutationId != c.attemptMutationId ||
          p.filter != c.filter,
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppCornerToast.show(context, state.errorMessage!, error: true);
        }
      },
      builder: (context, state) => _TeacherAssignmentGradingHubBody(
        assignmentId: assignmentId,
        scrollController: scrollController,
        padding: padding,
        showPageHeader: showPageHeader,
        examTitleHint: examTitleHint,
        state: state,
      ),
    );

    if (useParentBloc) return hub;

    return BlocProvider(
      create: (_) => getIt<TeacherGradingHubBloc>(param1: assignmentId)
        ..add(const TeacherGradingHubLoadRequested()),
      child: hub,
    );
  }
}

class _TeacherAssignmentGradingHubBody extends StatelessWidget {
  const _TeacherAssignmentGradingHubBody({
    required this.assignmentId,
    required this.state,
    this.scrollController,
    this.padding,
    this.showPageHeader = true,
    this.examTitleHint,
  });

  final String assignmentId;
  final TeacherGradingHubState state;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;
  final bool showPageHeader;
  final String? examTitleHint;

  void _reload(BuildContext context) {
    context.read<TeacherGradingHubBloc>().add(const TeacherGradingHubLoadRequested());
  }

  String? _formatDate(BuildContext context, dynamic raw) {
    if (raw == null) return null;
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return null;
    return DateFormat.yMMMd(Localizations.localeOf(context).toString()).add_jm().format(dt.toLocal());
  }

  String _studentLabel(Map<String, dynamic> m) {
    final user = m['userId'];
    if (user is Map) {
      final name = (user['fullName'] as String?)?.trim();
      if (name != null && name.isNotEmpty) return name;
      final email = (user['email'] as String?)?.trim();
      if (email != null && email.isNotEmpty) return email;
      final un = (user['username'] as String?)?.trim();
      if (un != null && un.isNotEmpty) return un;
    }
    return m['id'] as String? ?? '—';
  }

  /// Attempt id — backend `.lean()` trả `_id`; phòng vệ các endpoint khác (`docs/ui-ux-system/25`).
  String _attemptIdOf(Map<String, dynamic> m) =>
      (m['id'] ?? m['attemptId'] ?? m['_id'])?.toString() ?? '';

  String? _studentEmail(Map<String, dynamic> m) {
    final user = m['userId'];
    if (user is Map) return (user['email'] as String?)?.trim();
    return null;
  }

  Widget _filterChip(BuildContext context, String label, TeacherGradingHubFilter f) {
    final selected = state.filter == f;
    return FilterChip(
      label: Text(label, style: TeacherWebUi.webCaption(context)),
      selected: selected,
      onSelected: (_) => context.read<TeacherGradingHubBloc>().add(TeacherGradingHubFilterChanged(f)),
      selectedColor: AppColors.primaryTint,
      checkmarkColor: AppColors.primary,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.outline),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  void _openAttempt(BuildContext context, Map<String, dynamic> attempt) {
    final id = _attemptIdOf(attempt);
    if (id.isEmpty) return;
    context.push(TeacherExamAttemptGradePage.location(assignmentId, id));
  }

  void _runAi(BuildContext context, Map<String, dynamic> attempt) {
    final id = _attemptIdOf(attempt);
    if (id.isEmpty) return;
    context.read<TeacherGradingHubBloc>().add(TeacherGradingHubRunAiRequested(id));
    AppCornerToast.show(context, context.l10n.teacherExamRunAi);
  }

  Future<void> _releaseAttempt(BuildContext context, Map<String, dynamic> attempt) async {
    final id = _attemptIdOf(attempt);
    if (id.isEmpty) return;
    final cfg = state.assignment?['config'];
    final cfgLevel = cfg is Map ? cfg['resultsDetailLevel'] as String? : null;
    final initial = cfgLevel == 'score_only' ? 'score_only' : 'full_detail';
    final detail = await TeacherReleaseResultsDialog.show(
      context,
      initialDetailLevel: initial,
    );
    if (detail == null || !context.mounted) return;
    context.read<TeacherGradingHubBloc>().add(
          TeacherGradingHubReleaseRequested(id, resultsDetailLevel: detail),
        );
    AppCornerToast.show(context, context.l10n.teacherExamReleaseResults);
  }

  Widget _studentCell(BuildContext context, Map<String, dynamic> attempt) {
    final label = _studentLabel(attempt);
    final email = _studentEmail(attempt);
    return Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: AppColors.primaryTint,
          child: Text(
            TeacherGradingHubLabels.studentInitials(label),
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
                label,
                style: TeacherWebUi.webBody(context).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (email != null && email.isNotEmpty)
                Text(email, style: TeacherWebUi.metaMuted, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _attemptStatusCell(BuildContext context, Map<String, dynamic> attempt) {
    final l10n = context.l10n;
    final status = attempt['status'] as String? ?? '';
    return TeacherGradingPill(
      label: TeacherGradingHubLabels.attemptStatus(l10n, status),
      color: _statusColor(status),
    );
  }

  Widget _gradingStateCell(BuildContext context, Map<String, dynamic> attempt) {
    final l10n = context.l10n;
    final gs = attempt['gradingState'] as String? ?? '';
    final released = attempt['resultsReleased'] == true;
    return TeacherGradingPill(
      label: TeacherGradingHubLabels.gradingState(l10n, gs),
      color: _gradingColor(gs, released),
    );
  }

  Widget _scoreCell(BuildContext context, Map<String, dynamic> attempt) {
    final score = _scoreOf(attempt);
    return Text(
      score?.label ?? '—',
      style: TeacherWebUi.webBody(context).copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: score?.partial == true ? AppColors.warning : AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _submittedCell(BuildContext context, Map<String, dynamic> attempt) {
    final label = _formatDate(context, attempt['submittedAt']) ?? _formatDate(context, attempt['startedAt']) ?? '—';
    return Text(
      label,
      style: TeacherWebUi.webCaption(context).copyWith(color: AppColors.textSecondary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _attemptActionMenu(BuildContext context, Map<String, dynamic> attempt) {
    final l10n = context.l10n;
    final status = attempt['status'] as String? ?? '';
    final gs = attempt['gradingState'] as String? ?? '';
    final released = attempt['resultsReleased'] == true;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, size: 18, color: AppColors.textSecondary),
      padding: EdgeInsets.zero,
      tooltip: '',
      position: PopupMenuPosition.under,
      onSelected: (value) {
        if (value == 'open') _openAttempt(context, attempt);
        if (value == 'ai') _runAi(context, attempt);
        if (value == 'release') _releaseAttempt(context, attempt);
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'open', child: _gradingMenuAction(Icons.fact_check_outlined, l10n.teacherGradingHubOpenGrade)),
        if (status == 'submitted')
          PopupMenuItem(value: 'ai', child: _gradingMenuAction(Icons.smart_toy_outlined, l10n.teacherExamRunAi)),
        if (status == 'submitted' && gs == 'finalized' && !released)
          PopupMenuItem(value: 'release', child: _gradingMenuAction(Icons.send_outlined, l10n.teacherExamReleaseResults)),
      ],
    );
  }

  _AttemptScoreData? _scoreOf(Map<String, dynamic> attempt) {
    final scores = attempt['scores'];
    if (scores is! Map) return null;

    num? awarded;
    num? max;
    var partial = false;
    final examFmt = '${scores['examFormat'] ?? ''}';
    final isIntegrated = examFmt == 'integrated_four_skills' || examFmt == 'skills_exam';
    if (isIntegrated) {
      awarded = scores['finalScore'] as num?;
      max = 10;
      partial = '${scores['finalStatus'] ?? ''}' == 'partial';
    } else {
      awarded = scores['totalAwarded'] as num?;
      max = scores['totalMax'] as num?;
    }
    if (awarded == null || max == null) return null;
    return _AttemptScoreData(
      '${_formatScoreNumber(awarded)}/${_formatScoreNumber(max)}',
      partial: partial,
    );
  }

  String _formatScoreNumber(num value) => value.toStringAsFixed(value % 1 == 0 ? 0 : 1);

  Color _statusColor(String status) {
    switch (status) {
      case 'submitted':
        return AppColors.success;
      case 'in_progress':
        return AppColors.primary;
      case 'expired':
        return AppColors.textMuted;
      default:
        return AppColors.warning;
    }
  }

  Color _gradingColor(String gs, bool released) {
    if (released) return AppColors.success;
    if (gs == 'pending_manual' || gs == 'pending_ai') return AppColors.warning;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pad = padding ?? TeacherWebUi.pageScrollPadding(context);

    if (state.status == TeacherGradingHubStatus.loading) {
      return TeacherSkeleton.page(TeacherSkeleton.table(rows: 8));
    }
    if (state.status == TeacherGradingHubStatus.error) {
      return Center(
        child: Padding(
          padding: pad,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.errorMessage ?? '',
                textAlign: TextAlign.center,
                style: TeacherWebUi.webBody(context),
              ),
              const SizedBox(height: 12),
              TeacherRetryButton(onPressed: () => _reload(context)),
            ],
          ),
        ),
      );
    }

    final visibleAttempts = state.visibleAttempts;
    final classroomId = state.assignment?['classroomId'] as String?;

    return RefreshIndicator(
      onRefresh: () async => _reload(context),
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverPadding(
            padding: pad,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (showPageHeader) ...[
                  Text(
                    (state.assignment?['examTitle'] as String?)?.trim() ??
                        examTitleHint?.trim() ??
                        l10n.teacherExamUntitled,
                    style: TeacherWebUi.webPageTitle(context),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                ],
                TeacherGradingHubContextHeader(
                  assignment: state.assignment,
                  stats: state.stats,
                  onClassroomTap: classroomId != null && classroomId.isNotEmpty
                      ? () => context.push('${TeacherClassroomDetailPage.routePath}/$classroomId')
                      : null,
                ),
                const SizedBox(height: AppSpacing.s5),
                Text(l10n.teacherGradingStudentAttemptsTitle, style: TeacherWebUi.sectionTitle(context)),
                const SizedBox(height: AppSpacing.s3),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _filterChip(context, l10n.teacherGradingHubFilterAll, TeacherGradingHubFilter.all),
                    _filterChip(context, l10n.teacherGradingHubFilterInProgress, TeacherGradingHubFilter.inProgress),
                    _filterChip(context, l10n.teacherGradingHubFilterSubmitted, TeacherGradingHubFilter.submitted),
                    _filterChip(
                      context,
                      l10n.teacherGradingHubFilterPendingManual,
                      TeacherGradingHubFilter.pendingManual,
                    ),
                    _filterChip(context, l10n.teacherGradingHubFilterFinalized, TeacherGradingHubFilter.finalized),
                    _filterChip(context, l10n.teacherGradingHubFilterReleased, TeacherGradingHubFilter.released),
                    _filterChip(context, l10n.teacherGradingHubFilterPartial, TeacherGradingHubFilter.partial),
                  ],
                ),
                const SizedBox(height: AppSpacing.s5),
              ]),
            ),
          ),
          if (visibleAttempts.isEmpty)
            SliverPadding(
              padding: pad,
              sliver: SliverToBoxAdapter(
                child: AppCard(
                  variant: AppCardVariant.outline,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    child: Column(
                      children: [
                        Icon(Icons.assignment_ind_outlined, size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          l10n.teacherGradingHubEmpty,
                          textAlign: TextAlign.center,
                          style: TeacherWebUi.webBody(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: pad,
              sliver: SliverToBoxAdapter(
                child: WebDataTable(
                  columns: [
                    WebTableColumn(label: l10n.teacherGradebookStudent, flex: 4),
                    WebTableColumn(label: l10n.teacherClassColStatus, width: 140),
                    WebTableColumn(label: l10n.teacherExamGradingTitle, width: 140),
                    WebTableColumn(
                      label: l10n.studentExamScore,
                      width: 90,
                      align: Alignment.centerRight,
                    ),
                    WebTableColumn(label: l10n.teacherClassColSubmitted, width: 160),
                    const WebTableColumn(label: '', width: 56, align: Alignment.center),
                  ],
                  rowCount: visibleAttempts.length,
                  decoration: TeacherWebUi.panelDecoration(),
                  headStyle: TeacherWebUi.webTableHead(context),
                  onRowTap: (row) => () => _openAttempt(context, visibleAttempts[row]),
                  cellBuilder: (context, row, col) {
                    final m = visibleAttempts[row];
                    return switch (col) {
                      0 => _studentCell(context, m),
                      1 => _attemptStatusCell(context, m),
                      2 => _gradingStateCell(context, m),
                      3 => _scoreCell(context, m),
                      4 => _submittedCell(context, m),
                      _ => _attemptActionMenu(context, m),
                    };
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttemptScoreData {
  const _AttemptScoreData(this.label, {required this.partial});

  final String label;
  final bool partial;
}

Widget _gradingMenuAction(IconData icon, String label, {bool danger = false}) {
  final color = danger ? AppColors.danger : AppColors.textPrimary;
  return Row(
    children: [
      Icon(icon, size: 16, color: danger ? AppColors.danger : AppColors.textSecondary),
      const SizedBox(width: AppSpacing.s3),
      Text(label, style: TextStyle(color: color)),
    ],
  );
}

