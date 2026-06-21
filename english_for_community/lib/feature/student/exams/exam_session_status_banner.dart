import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:flutter/material.dart';

/// Room lifecycle indicator: lobby / live / grading / closed.
class ExamSessionStatusBanner extends StatelessWidget {
  const ExamSessionStatusBanner({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, color, icon) = switch (status) {
      'live' => (l10n.examSessionStatusLive, AppColors.primary, Icons.play_circle_outline),
      'grading' => (l10n.teacherDashboardLiveStatusGrading, AppColors.warning, Icons.hourglass_top_outlined),
      'closed' => (l10n.examSessionStatusClosed, AppColors.textMuted, Icons.check_circle_outline),
      'canceled' => (l10n.examSessionStatusCanceled, AppColors.chartTrend, Icons.cancel_outlined),
      _ => (l10n.examSessionStatusLobby, AppColors.tertiary, Icons.meeting_room_outlined),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: ExamSystemUi.captionSecondary.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
