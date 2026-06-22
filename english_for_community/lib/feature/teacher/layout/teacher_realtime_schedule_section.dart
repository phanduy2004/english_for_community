import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// Schedule picker for realtime (session) assignments: in-class vs calendar.
class TeacherRealtimeScheduleSection extends StatelessWidget {
  const TeacherRealtimeScheduleSection({
    super.key,
    required this.scheduleMode,
    required this.scheduledStartAt,
    required this.lobbyOpensAt,
    required this.onScheduleModeChanged,
    required this.onScheduledStartChanged,
    required this.onLobbyOpensChanged,
    required this.onPickDateTime,
    required this.formatDateTime,
  });

  /// `manual` = open in class when teacher starts; `scheduled` = fixed times for students.
  final String scheduleMode;
  final DateTime? scheduledStartAt;
  final DateTime? lobbyOpensAt;
  final ValueChanged<String> onScheduleModeChanged;
  final ValueChanged<DateTime?> onScheduledStartChanged;
  final ValueChanged<DateTime?> onLobbyOpensChanged;
  final Future<void> Function({
    required DateTime? initial,
    required void Function(DateTime) onPicked,
    DateTime? firstDate,
  }) onPickDateTime;
  final String Function(DateTime?) formatDateTime;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isScheduled = scheduleMode == 'scheduled';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.infoBg,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.info),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.teacherAssignExamRealtimeNote,
                  style: TeacherWebUi.webBody(context).copyWith(fontSize: 12, height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        TeacherWebUi.formFieldLabel(context, l10n.teacherAssignmentRealtimeScheduleModeLabel),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _scheduleModeTile(
                context,
                value: 'manual',
                icon: Icons.groups_outlined,
                label: l10n.teacherAssignmentRealtimeScheduleManual,
                hint: l10n.teacherAssignmentRealtimeScheduleManualHint,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _scheduleModeTile(
                context,
                value: 'scheduled',
                icon: Icons.event_outlined,
                label: l10n.teacherAssignmentRealtimeScheduleScheduled,
                hint: l10n.teacherAssignmentRealtimeScheduleScheduledHint,
              ),
            ),
          ],
        ),
        if (isScheduled) ...[
          const SizedBox(height: AppSpacing.s4),
          _dateField(
            context,
            label: l10n.teacherAssignmentRealtimeScheduledStart,
            value: scheduledStartAt,
            required: true,
            onTap: () => onPickDateTime(
              initial: scheduledStartAt,
              firstDate: DateTime.now(),
              onPicked: onScheduledStartChanged,
            ),
            onClear: scheduledStartAt != null ? () => onScheduledStartChanged(null) : null,
            formatDateTime: formatDateTime,
          ),
          const SizedBox(height: AppSpacing.s4),
          _dateField(
            context,
            label: l10n.teacherAssignmentRealtimeLobbyOpens,
            value: lobbyOpensAt,
            required: false,
            onTap: () => onPickDateTime(
              initial: lobbyOpensAt ?? scheduledStartAt,
              firstDate: DateTime.now(),
              onPicked: onLobbyOpensChanged,
            ),
            onClear: lobbyOpensAt != null ? () => onLobbyOpensChanged(null) : null,
            formatDateTime: formatDateTime,
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            l10n.teacherAssignmentRealtimeLobbyOpensHint,
            style: TeacherWebUi.metaMuted.copyWith(fontSize: 11, height: 1.35),
          ),
        ],
      ],
    );
  }

  Widget _scheduleModeTile(
    BuildContext context, {
    required String value,
    required IconData icon,
    required String label,
    required String hint,
  }) {
    final selected = scheduleMode == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onScheduleModeChanged(value),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: AnimatedContainer(
          duration: AppMotion.segment,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: TeacherWebUi.choiceTileDecoration(selected: selected),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: TeacherWebUi.choiceTileIconBoxColor(selected: selected),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Icon(
                      icon,
                      size: 15,
                      color: TeacherWebUi.choiceTileIconColor(selected: selected),
                    ),
                  ),
                  const Spacer(),
                  if (selected)
                    const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.primary),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TeacherWebUi.webLabel(context).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: TeacherWebUi.choiceTileTitleColor(selected: selected),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hint,
                style: TeacherWebUi.metaMuted.copyWith(
                  fontSize: 10,
                  height: 1.35,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateField(
    BuildContext context, {
    required String label,
    required DateTime? value,
    required bool required,
    required VoidCallback onTap,
    required VoidCallback? onClear,
    required String Function(DateTime?) formatDateTime,
  }) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TeacherWebUi.formFieldLabel(context, required ? '$label *' : label),
        const SizedBox(height: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Ink(
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                border: Border.all(color: AppColors.outline),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              padding: TeacherWebUi.formInputContentPadding,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value != null ? formatDateTime(value) : l10n.teacherAssignmentOptional,
                      style: TeacherWebUi.webBody(context).copyWith(
                        fontSize: 14,
                        color: value == null ? AppColors.textMuted : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textMuted),
                  if (onClear != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: onClear,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
