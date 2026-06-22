import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/feature/teacher/teacher_grading_hub_labels.dart';
import 'package:flutter/material.dart';

/// Assignment context strip for grading hub — `docs/ui-ux-system/08` A4.
class TeacherGradingHubContextHeader extends StatelessWidget {
  const TeacherGradingHubContextHeader({
    super.key,
    required this.assignment,
    required this.stats,
    this.onClassroomTap,
  });

  final Map<String, dynamic>? assignment;
  final Map<String, dynamic> stats;
  final VoidCallback? onClassroomTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final a = assignment;
    if (a == null) return const SizedBox.shrink();

    final mode = a['mode'] as String? ?? '';
    final modeLabel = TeacherGradingHubLabels.modeLabel(l10n, mode);
    final formatLabel = TeacherGradingHubLabels.examFormatLabel(l10n, a['examFormat'] as String?);
    final audience = a['audience'] as String? ?? 'classroom';
    final className = (a['classroomName'] as String?)?.trim();
    final schedule = TeacherGradingHubLabels.scheduleLines(context, l10n, a);

    final submitted = (stats['submitted'] as num?)?.toInt() ?? 0;
    final inProgress = (stats['inProgress'] as num?)?.toInt() ?? 0;
    final pending = (stats['pendingManual'] as num?)?.toInt() ?? 0;
    final partial = (stats['partial'] as num?)?.toInt() ?? 0;

    return AppCard(
      variant: AppCardVariant.outline,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (className != null && className.isNotEmpty)
                  _ContextChip(
                    icon: Icons.school_outlined,
                    label: className,
                    tone: _ChipTone.neutral,
                    onTap: onClassroomTap,
                  ),
                _ContextChip(
                  icon: _modeIcon(mode),
                  label: modeLabel,
                  tone: _modeTone(mode),
                ),
                if (formatLabel != null)
                  _ContextChip(
                    icon: Icons.layers_outlined,
                    label: formatLabel,
                    tone: _ChipTone.neutral,
                  ),
                _ContextChip(
                  icon: audience == 'public' ? Icons.link_outlined : Icons.groups_outlined,
                  label: TeacherGradingHubLabels.audienceLabel(l10n, audience),
                  tone: _ChipTone.neutral,
                ),
              ],
            ),
            if (schedule.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s4),
              ...schedule.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.schedule_outlined, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(line, style: TeacherWebUi.metaMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s5),
            const Divider(height: 1, color: AppColors.outlineMuted),
            const SizedBox(height: AppSpacing.s4),
            Row(
              children: [
                _KpiMini(
                  value: '$submitted',
                  label: l10n.teacherGradingHubFilterSubmitted,
                  color: AppColors.success,
                ),
                _KpiMini(
                  value: '$inProgress',
                  label: l10n.teacherGradingHubFilterInProgress,
                  color: AppColors.primary,
                ),
                _KpiMini(
                  value: '$pending',
                  label: l10n.teacherGradingHubFilterPendingManual,
                  color: AppColors.warning,
                ),
                _KpiMini(
                  value: '$partial',
                  label: l10n.teacherGradingHubFilterPartial,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static IconData _modeIcon(String mode) {
    switch (mode) {
      case 'realtime':
        return Icons.sensors_outlined;
      case 'scheduled':
        return Icons.event_outlined;
      case 'practice':
        return Icons.school_outlined;
      default:
        return Icons.timer_outlined;
    }
  }

  static _ChipTone _modeTone(String mode) {
    switch (mode) {
      case 'realtime':
        return _ChipTone.live;
      case 'scheduled':
        return _ChipTone.info;
      case 'practice':
        return _ChipTone.neutral;
      default:
        return _ChipTone.neutral;
    }
  }
}

enum _ChipTone { neutral, live, info }

class _ContextChip extends StatelessWidget {
  const _ContextChip({
    required this.icon,
    required this.label,
    required this.tone,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final _ChipTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (tone) {
      _ChipTone.live => (
          AppColors.successBg,
          AppColors.success,
          AppColors.success.withValues(alpha: 0.35),
        ),
      _ChipTone.info => (
          AppColors.infoBg,
          AppColors.info,
          AppColors.info.withValues(alpha: 0.3),
        ),
      _ChipTone.neutral => (
          AppColors.surfaceSubtle,
          AppColors.textPrimary,
          AppColors.outline,
        ),
    };

    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TeacherWebUi.webLabel(context).copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 14, color: fg.withValues(alpha: 0.7)),
          ],
        ],
      ),
    );

    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadius.lg), child: child),
    );
  }
}

class _KpiMini extends StatelessWidget {
  const _KpiMini({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
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
