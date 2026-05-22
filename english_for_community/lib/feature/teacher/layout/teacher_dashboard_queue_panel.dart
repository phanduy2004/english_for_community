import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_dialog_shell.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:flutter/material.dart';

/// Dashboard work queues: bounded preview + full list in dialog (`08-web-screens` A1).
const int kTeacherDashboardGradingPreviewCount = 5;
const int kTeacherDashboardLiveViewAllThreshold = 4;
const double kTeacherDashboardLiveStripHeight = 200;

class TeacherDashboardSectionHeader extends StatelessWidget {
  const TeacherDashboardSectionHeader({
    super.key,
    required this.title,
    this.count,
    this.onViewAll,
    this.viewAllLabel,
  });

  final String title;
  final int? count;
  final VoidCallback? onViewAll;
  final String? viewAllLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Text(title, style: TeacherWebUi.sectionTitle(context))),
        if (count != null && count! > 0) ...[
          const SizedBox(width: AppSpacing.s3),
          _CountBadge(count: count!),
        ],
        if (onViewAll != null && viewAllLabel != null) ...[
          const SizedBox(width: AppSpacing.s2),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            onPressed: onViewAll,
            child: Text(viewAllLabel!),
          ),
        ],
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.warning,
            ),
      ),
    );
  }
}

/// Vertical grading queue: preview rows + optional “view all” dialog.
class TeacherDashboardGradingQueuePanel extends StatelessWidget {
  const TeacherDashboardGradingQueuePanel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.onViewAllTap,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final VoidCallback? onViewAllTap;

  @override
  Widget build(BuildContext context) {
    final previewCount = itemCount.clamp(0, kTeacherDashboardGradingPreviewCount);
    final hidden = itemCount - previewCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(previewCount, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i < previewCount - 1 ? AppSpacing.s3 : 0),
            child: itemBuilder(context, i),
          );
        }),
        if (hidden > 0) ...[
          const SizedBox(height: AppSpacing.s3),
          _QueueMoreFooter(
            label: context.l10n.teacherDashboardQueueMoreHidden(hidden),
            onTap: onViewAllTap,
          ),
        ],
      ],
    );
  }
}

class _QueueMoreFooter extends StatelessWidget {
  const _QueueMoreFooter({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.primaryTint.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.outlineMuted),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.unfold_more_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TeacherWebUi.webBody(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              if (onTap != null)
                Text(
                  l10n.teacherDashboardViewAllQueueShort,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens a scrollable dialog with the full grading queue.
Future<void> showTeacherDashboardGradingQueueDialog({
  required BuildContext context,
  required String title,
  required String subtitle,
  required int itemCount,
  required Widget Function(BuildContext context, int index) itemBuilder,
}) {
  return TeacherDialogShell.show(
    context,
    child: TeacherDialogShell(
      title: title,
      subtitle: subtitle,
      icon: Icons.grade_outlined,
      width: 560,
      maxBodyHeight: 480,
      body: ListView.separated(
        shrinkWrap: true,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s3),
        itemBuilder: itemBuilder,
      ),
    ),
  );
}

/// Horizontal live-session strip inside a fixed-height panel.
class TeacherDashboardLiveStripPanel extends StatelessWidget {
  const TeacherDashboardLiveStripPanel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.onViewAllTap,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final VoidCallback? onViewAllTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final showScrollHint = itemCount > 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showScrollHint)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s2),
            child: Text(
              l10n.teacherDashboardScrollHint,
              style: TeacherWebUi.metaMuted.copyWith(fontSize: 11),
            ),
          ),
        SizedBox(
          height: kTeacherDashboardLiveStripHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.outlineMuted),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  itemCount: itemCount,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: itemBuilder,
                ),
              ),
            ),
          ),
        ),
        if (itemCount >= kTeacherDashboardLiveViewAllThreshold && onViewAllTap != null) ...[
          const SizedBox(height: AppSpacing.s3),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onViewAllTap,
              icon: const Icon(Icons.grid_view_rounded, size: 16),
              label: Text(l10n.teacherDashboardViewAllLiveQueue(itemCount)),
            ),
          ),
        ],
      ],
    );
  }
}

Future<void> showTeacherDashboardLiveQueueDialog({
  required BuildContext context,
  required String title,
  required String subtitle,
  required int itemCount,
  required Widget Function(BuildContext context, int index) itemBuilder,
}) {
  return TeacherDialogShell.show(
    context,
    child: TeacherDialogShell(
      title: title,
      subtitle: subtitle,
      icon: Icons.sensors,
      width: 520,
      maxBodyHeight: 480,
      body: ListView.separated(
        shrinkWrap: true,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s3),
        itemBuilder: itemBuilder,
      ),
    ),
  );
}
