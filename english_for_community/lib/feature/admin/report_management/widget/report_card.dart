// lib/feature/admin/report_management/widget/report_card.dart

import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/entity/report_entity.dart';
import 'report_action_menu.dart';
import 'report_detail_dialog.dart';

class ReportCard extends StatelessWidget {
  final ReportEntity report;
  const ReportCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    Color typeColor = AppColors.textMuted;
    IconData typeIcon = Icons.help_outline;

    switch (report.type) {
      case 'bug': typeColor = AppColors.danger; typeIcon = Icons.bug_report_rounded; break;
      case 'feature': typeColor = AppColors.info; typeIcon = Icons.lightbulb_rounded; break;
      case 'improvement': typeColor = AppColors.info; typeIcon = Icons.trending_up_rounded; break;
      case 'other': typeColor = AppColors.warning; typeIcon = Icons.chat_bubble_outline_rounded; break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => ReportDetailDialog(report: report),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(typeIcon, size: 20, color: typeColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _StatusBadge(label: report.type.toUpperCase(), color: typeColor),
                          const Spacer(),
                          Text(
                            report.createdAt != null
                                ? DateFormat('HH:mm dd/MM').format(report.createdAt!.toLocal())
                                : '',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        report.title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.description,
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            report.user?.fullName ?? 'Unknown User',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                ReportActionMenu(report: report),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Trạng thái: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
        ),
      ),
    );
  }
}


