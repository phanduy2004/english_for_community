// lib/feature/admin/report_management/widget/report_card.dart

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
    Color typeColor = const Color(0xFF64748B);
    IconData typeIcon = Icons.help_outline;

    switch (report.type) {
      case 'bug': typeColor = const Color(0xFFEF4444); typeIcon = Icons.bug_report_rounded; break;
      case 'feature': typeColor = const Color(0xFF8B5CF6); typeIcon = Icons.lightbulb_rounded; break;
      case 'improvement': typeColor = const Color(0xFF3B82F6); typeIcon = Icons.trending_up_rounded; break;
      case 'other': typeColor = const Color(0xFFF59E0B); typeIcon = Icons.chat_bubble_outline_rounded; break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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
                    color: typeColor.withOpacity(0.1),
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
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        report.title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.description,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 14, color: const Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text(
                            report.user?.fullName ?? 'Unknown User',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}