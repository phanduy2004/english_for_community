import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_dialog_shell.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// Confirm what students may see when grades are published.
class TeacherReleaseResultsDialog extends StatefulWidget {
  const TeacherReleaseResultsDialog({
    super.key,
    required this.initialDetailLevel,
  });

  final String initialDetailLevel;

  static Future<String?> show(
    BuildContext context, {
    required String initialDetailLevel,
  }) {
    return TeacherDialogShell.show<String>(
      context,
      child: TeacherReleaseResultsDialog(initialDetailLevel: initialDetailLevel),
    );
  }

  @override
  State<TeacherReleaseResultsDialog> createState() => _TeacherReleaseResultsDialogState();
}

class _TeacherReleaseResultsDialogState extends State<TeacherReleaseResultsDialog> {
  late String _detailLevel;

  @override
  void initState() {
    super.initState();
    _detailLevel = widget.initialDetailLevel == 'score_only' ? 'score_only' : 'full_detail';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TeacherDialogShell(
      title: l10n.teacherReleaseResultsDialogTitle,
      icon: Icons.publish_outlined,
      width: 480,
      maxBodyHeight: 360,
      footer: TeacherDialogFooterActions(
        cancelLabel: l10n.cancel,
        primaryLabel: l10n.teacherExamReleaseResults,
        onCancel: () => Navigator.pop(context),
        onPrimary: () => Navigator.pop(context, _detailLevel),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ConsequenceBanner(message: l10n.teacherReleaseResultsDialogSubtitle),
          const SizedBox(height: AppSpacing.s4),
          _DetailTile(
            selected: _detailLevel == 'score_only',
            icon: Icons.leaderboard_outlined,
            title: l10n.teacherResultsDetailScoreOnly,
            hint: l10n.teacherResultsDetailScoreOnlyHint,
            onTap: () => setState(() => _detailLevel = 'score_only'),
          ),
          const SizedBox(height: 10),
          _DetailTile(
            selected: _detailLevel == 'full_detail',
            icon: Icons.fact_check_outlined,
            title: l10n.teacherResultsDetailFull,
            hint: l10n.teacherResultsDetailFullHint,
            onTap: () => setState(() => _detailLevel = 'full_detail'),
          ),
        ],
      ),
    );
  }
}

/// Banner cảnh báo hệ quả cho hành động ảnh hưởng học sinh (`docs/ui-ux-system/18` §5.8).
class _ConsequenceBanner extends StatelessWidget {
  const _ConsequenceBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Text(
              message,
              style: TeacherWebUi.webCaption(context).copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.hint,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: AnimatedContainer(
          duration: AppMotion.segment,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: TeacherWebUi.choiceTileDecoration(selected: selected),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: TeacherWebUi.choiceTileIconBoxColor(selected: selected),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: TeacherWebUi.choiceTileIconColor(selected: selected),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TeacherWebUi.webLabel(context).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: TeacherWebUi.choiceTileTitleColor(selected: selected),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(hint, style: TeacherWebUi.metaMuted.copyWith(fontSize: 11, height: 1.35)),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
