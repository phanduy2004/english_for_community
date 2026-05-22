import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart' show AppRadius, AppSpacing;
import 'package:english_for_community/feature/teacher/bloc/grading_hub/teacher_grading_hub_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/grading_hub/teacher_grading_hub_event.dart';
import 'package:english_for_community/feature/teacher/bloc/grading_hub/teacher_grading_hub_state.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_grading_hub_context_header.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/teacher_classroom_detail_page.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_attempt_grade_page.dart';
import 'package:english_for_community/feature/teacher/teacher_grading_hub_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

enum TeacherGradingHubFilter {
  all,
  inProgress,
  submitted,
  pendingManual,
  finalized,
  released,
  partial,
}

/// Loads and displays student attempts for one assignment (grading hub).
class TeacherAssignmentGradingHubView extends StatefulWidget {
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
  State<TeacherAssignmentGradingHubView> createState() => _TeacherAssignmentGradingHubViewState();
}

class _TeacherAssignmentGradingHubViewState extends State<TeacherAssignmentGradingHubView> {
  TeacherGradingHubFilter _filter = TeacherGradingHubFilter.all;

  void _reload() {
    context.read<TeacherGradingHubBloc>().add(const TeacherGradingHubLoadRequested());
  }

  String? _formatDate(dynamic raw) {
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

  String? _studentEmail(Map<String, dynamic> m) {
    final user = m['userId'];
    if (user is Map) return (user['email'] as String?)?.trim();
    return null;
  }

  bool _matchesFilter(Map<String, dynamic> m) {
    final status = m['status'] as String? ?? '';
    final gs = m['gradingState'] as String? ?? '';
    final released = m['resultsReleased'] == true;
    final meta = m['meta'];
    final completeness = meta is Map ? meta['submitCompleteness'] as String? : null;

    switch (_filter) {
      case TeacherGradingHubFilter.all:
        return true;
      case TeacherGradingHubFilter.inProgress:
        return status == 'in_progress';
      case TeacherGradingHubFilter.submitted:
        return status == 'submitted';
      case TeacherGradingHubFilter.pendingManual:
        return gs == 'pending_manual' || gs == 'pending_ai';
      case TeacherGradingHubFilter.finalized:
        return gs == 'finalized' && !released;
      case TeacherGradingHubFilter.released:
        return released;
      case TeacherGradingHubFilter.partial:
        return completeness == 'partial';
    }
  }

  List<Map<String, dynamic>> _visibleAttempts(List<Map<String, dynamic>> attempts) =>
      attempts.where(_matchesFilter).toList();

  Widget _filterChip(BuildContext context, String label, TeacherGradingHubFilter f) {
    final selected = _filter == f;
    return FilterChip(
      label: Text(label, style: TeacherWebUi.webCaption(context)),
      selected: selected,
      onSelected: (_) => setState(() => _filter = f),
      selectedColor: AppColors.primaryTint,
      checkmarkColor: AppColors.primary,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.outline),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hub = BlocConsumer<TeacherGradingHubBloc, TeacherGradingHubState>(
      listenWhen: (p, c) => c.errorMessage != null && p.errorMessage != c.errorMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) => _buildContent(context, state),
    );

    if (widget.useParentBloc) return hub;

    return BlocProvider(
      create: (_) => getIt<TeacherGradingHubBloc>(param1: widget.assignmentId)
        ..add(const TeacherGradingHubLoadRequested()),
      child: hub,
    );
  }

  Widget _buildContent(BuildContext context, TeacherGradingHubState state) {
    final l10n = context.l10n;
    final pad = widget.padding ?? TeacherWebUi.pageScrollPadding(context);

    if (state.status == TeacherGradingHubStatus.loading) {
      return const Center(child: CircularProgressIndicator());
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
              TeacherRetryButton(onPressed: _reload),
            ],
          ),
        ),
      );
    }

    final visibleAttempts = _visibleAttempts(state.attempts);
    final classroomId = state.assignment?['classroomId'] as String?;

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(
        controller: widget.scrollController,
        padding: pad,
        children: [
          if (widget.showPageHeader) ...[
            Text(
              (state.assignment?['examTitle'] as String?)?.trim() ??
                  widget.examTitleHint?.trim() ??
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
              _filterChip(context, l10n.teacherGradingHubFilterPendingManual, TeacherGradingHubFilter.pendingManual),
              _filterChip(context, l10n.teacherGradingHubFilterFinalized, TeacherGradingHubFilter.finalized),
              _filterChip(context, l10n.teacherGradingHubFilterReleased, TeacherGradingHubFilter.released),
              _filterChip(context, l10n.teacherGradingHubFilterPartial, TeacherGradingHubFilter.partial),
            ],
          ),
          const SizedBox(height: AppSpacing.s5),
          if (visibleAttempts.isEmpty)
            AppCard(
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
            )
          else
            ...visibleAttempts.map(
              (m) => TeacherGradingAttemptCard(
                attempt: m,
                studentLabel: _studentLabel(m),
                studentEmail: _studentEmail(m),
                submittedLabel: _formatDate(m['submittedAt']),
                startedLabel: _formatDate(m['startedAt']),
                onOpen: () {
                  final id = m['id'] as String? ?? '';
                  if (id.isEmpty) return;
                  context.push(TeacherExamAttemptGradePage.location(widget.assignmentId, id));
                },
                onAi: () {
                  final id = m['id'] as String? ?? '';
                  if (id.isNotEmpty) {
                    context.read<TeacherGradingHubBloc>().add(TeacherGradingHubRunAiRequested(id));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.teacherExamRunAi)));
                  }
                },
                onRelease: () {
                  final id = m['id'] as String? ?? '';
                  if (id.isNotEmpty) {
                    context.read<TeacherGradingHubBloc>().add(TeacherGradingHubReleaseRequested(id));
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(l10n.teacherExamReleaseResults)));
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Student attempt row for teacher grading lists.
class TeacherGradingAttemptCard extends StatelessWidget {
  const TeacherGradingAttemptCard({
    super.key,
    required this.attempt,
    required this.studentLabel,
    this.studentEmail,
    this.submittedLabel,
    this.startedLabel,
    required this.onOpen,
    required this.onAi,
    required this.onRelease,
  });

  final Map<String, dynamic> attempt;
  final String studentLabel;
  final String? studentEmail;
  final String? submittedLabel;
  final String? startedLabel;
  final VoidCallback onOpen;
  final VoidCallback onAi;
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = attempt['status'] as String? ?? '';
    final gs = attempt['gradingState'] as String? ?? '';
    final released = attempt['resultsReleased'] == true;
    final meta = attempt['meta'];
    final completeness = meta is Map ? meta['submitCompleteness'] as String? : null;
    final scores = attempt['scores'];
    num? awarded;
    num? max;
    bool isIntegrated = false;
    bool isPartialScore = false;
    if (scores is Map) {
      final examFmt = '${scores['examFormat'] ?? ''}';
      isIntegrated = examFmt == 'integrated_four_skills' || examFmt == 'skills_exam';
      if (isIntegrated) {
        awarded = scores['finalScore'] as num?;
        max = 10;
        isPartialScore = '${scores['finalStatus'] ?? ''}' == 'partial';
      } else {
        awarded = scores['totalAwarded'] as num?;
        max = scores['totalMax'] as num?;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
      child: AppCard(
        variant: AppCardVariant.outline,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primaryTint,
                      child: Text(
                        TeacherGradingHubLabels.studentInitials(studentLabel),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentLabel,
                            style: TeacherWebUi.webBody(context).copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (studentEmail != null && studentEmail!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              studentEmail!,
                              style: TeacherWebUi.webCaption(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _statusPill(
                                TeacherGradingHubLabels.attemptStatus(l10n, status),
                                _statusColor(status),
                              ),
                              _statusPill(
                                TeacherGradingHubLabels.gradingState(l10n, gs),
                                _gradingColor(gs, released),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (awarded != null && max != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            awarded.toStringAsFixed(awarded % 1 == 0 ? 0 : 1),
                            style: TeacherWebUi.webKpiValue(context).copyWith(
                              color: isPartialScore ? AppColors.warning : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '/ ${max.toStringAsFixed(max % 1 == 0 ? 0 : 1)}',
                            style: TeacherWebUi.webCaption(context),
                          ),
                        ],
                      ),
                  ],
                ),
                if (startedLabel != null || submittedLabel != null) ...[
                  const SizedBox(height: AppSpacing.s4),
                  if (startedLabel != null)
                    _metaRow(Icons.play_circle_outline, l10n.teacherGradingStartedAt(startedLabel!)),
                  if (submittedLabel != null)
                    _metaRow(Icons.check_circle_outline, l10n.teacherGradingHubSubmittedAt(submittedLabel!)),
                ],
                if (completeness == 'partial' || completeness == 'force_end' || (gs == 'finalized' && !released)) ...[
                  const SizedBox(height: AppSpacing.s3),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (completeness == 'partial') _badge(l10n.teacherGradingHubPartialBadge, AppColors.warning),
                      if (completeness == 'force_end') _badge(l10n.teacherGradingHubForceEndBadge, AppColors.textMuted),
                      if (gs == 'finalized' && !released) _badge(l10n.teacherGradingHubNotReleased, AppColors.info),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.s4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton(
                      onPressed: onOpen,
                      style: TeacherWebUi.compactFilledStyle(context),
                      child: Text(l10n.teacherGradingHubOpenGrade),
                    ),
                    if (status == 'submitted') ...[
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: l10n.teacherExamRunAi,
                        onPressed: onAi,
                        style: TeacherWebUi.compactHeaderIconStyle(),
                        icon: const Icon(Icons.smart_toy_outlined, size: 18),
                      ),
                      if (gs == 'finalized' && !released)
                        IconButton(
                          tooltip: l10n.teacherExamReleaseResults,
                          onPressed: onRelease,
                          style: TeacherWebUi.compactHeaderIconStyle(),
                          icon: const Icon(Icons.send_outlined, size: 18, color: AppColors.primary),
                        ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TeacherWebUi.metaMuted)),
        ],
      ),
    );
  }
}
