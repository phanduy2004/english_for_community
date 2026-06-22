import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/entity/user_entity.dart';
import '../../dashboard_home/bloc/admin_bloc.dart';
import '../../dashboard_home/bloc/admin_event.dart';
import '../widgets/admin_user_details_dialog.dart'; // 🔥 Import detailed dialog
import 'user_ban_dialog.dart';

class UserActionMenu extends StatelessWidget {
  final UserEntity user;

  const UserActionMenu({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final bool isBanned = user.isBanned;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.textMuted), // Zinc-400
      tooltip: 'User actions',
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        side: const BorderSide(color: AppColors.outline),
      ),
      elevation: 4,
      onSelected: (value) => _handleAction(context, value, isBanned),
      itemBuilder: (context) => [
        // 🔥 CHANGED: Edit -> View Info
        _buildItem('view', Icons.visibility_outlined, 'View Details', Colors.black87),

        _buildItem(
          'ban',
          isBanned ? Icons.lock_open_rounded : Icons.block_rounded,
          isBanned ? 'Unban Account' : 'Ban Account',
          isBanned ? Colors.green : Colors.orange,
        ),
        const PopupMenuDivider(height: 1),
        _buildItem('delete', Icons.delete_outline, 'Delete Permanently', Colors.red),
      ],
    );
  }

  PopupMenuItem<String> _buildItem(String value, IconData icon, String label, Color color) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String value, bool isBanned) {
    switch (value) {
      case 'view':
      // 🔥 CALL DETAIL DIALOG
        showDialog(
          context: context,
          builder: (ctx) => AdminUserDetailsDialog(userId: user.id,),
        );
        break;

      case 'ban':
        if (isBanned) {
          _showConfirmDialog(
              context,
              title: 'Unban Account?',
              content: 'User will be able to login and use services normally.',
              confirmText: 'Unban',
              confirmColor: Colors.green,
              onConfirm: () {
                context.read<AdminBloc>().add(
                    BanUserEvent(userId: user.id, banType: 'unban', reason: 'Admin unlocked')
                );
              }
          );
        } else {
          final adminBloc = context.read<AdminBloc>();
          showDialog(
            context: context,
            builder: (ctx) => BlocProvider.value(
              value: adminBloc,
              child: UserBanDialog(userId: user.id),
            ),
          );
        }
        break;

      case 'delete':
        _showConfirmDialog(
          context,
          title: 'Delete User?',
          content: 'This action CANNOT be undone. All learning data will be lost.',
          confirmText: 'Delete',
          confirmColor: Colors.red,
          onConfirm: () {
            context.read<AdminBloc>().add(DeleteUserEvent(userId: user.id));
          },
        );
        break;
    }
  }

  void _showConfirmDialog(BuildContext context, {
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
    required VoidCallback onConfirm
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        final destructive = confirmColor == Colors.red;
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Row(
            children: [
              Icon(
                destructive ? Icons.warning_amber_rounded : Icons.info_outline,
                color: destructive ? Colors.red : confirmColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
            ],
          ),
          content: Text(content, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.35)),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.outline),
                foregroundColor: AppColors.textPrimary,
              ),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                onConfirm();
              },
              style: FilledButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
              ),
              child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }
}


