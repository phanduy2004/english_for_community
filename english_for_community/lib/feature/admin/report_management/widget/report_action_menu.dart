// lib/feature/admin/report_management/widget/report_action_menu.dart

import 'package:english_for_community/feature/admin/report_management/widget/report_detail_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/entity/report_entity.dart';
import '../../dashboard_home/bloc/admin_bloc.dart';
import '../../dashboard_home/bloc/admin_event.dart';

class ReportActionMenu extends StatelessWidget {
  final ReportEntity report;
  const ReportActionMenu({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Color(0xFFA1A1AA)),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFFE4E4E7))),
      elevation: 4,
      onSelected: (value) => _handleAction(context, value),
      itemBuilder: (context) {
        final List<PopupMenuEntry<String>> items = [];

        items.add(_buildItem('view', Icons.visibility_outlined, 'View details', Colors.black87));
        items.add(const PopupMenuDivider(height: 1));

        if (report.status != 'reviewed') {
          items.add(_buildItem('mark_reviewed', Icons.remove_red_eye_outlined, 'Mark as Reviewed', Colors.blue));
        }
        if (report.status != 'resolved') {
          items.add(_buildItem('mark_resolved', Icons.check_circle_outline, 'Mark as Resolved', Colors.green));
        }
        if (report.status != 'rejected') {
          items.add(_buildItem('mark_rejected', Icons.cancel_outlined, 'Reject / Cancel', Colors.red));
        }
        return items;
      },
    );
  }

  PopupMenuItem<String> _buildItem(String value, IconData icon, String label, Color color) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
      ]),
    );
  }

  void _handleAction(BuildContext context, String value) {
    final adminBloc = context.read<AdminBloc>();

    switch (value) {
      case 'view':
        showDialog(context: context, builder: (ctx) => ReportDetailDialog(report: report));
        break;
      case 'mark_reviewed':
        _updateStatus(adminBloc, 'reviewed');
        break;
      case 'mark_resolved':
        _updateStatus(adminBloc, 'resolved', adminResponse: 'Processed successfully.');
        break;
      case 'mark_rejected':
        _updateStatus(adminBloc, 'rejected');
        break;
    }
  }

  void _updateStatus(AdminBloc bloc, String status, {String? adminResponse}) {
    bloc.add(UpdateReportStatusEvent(
        reportId: report.id!,
        status: status,
        adminResponse: adminResponse
    ));
  }
}