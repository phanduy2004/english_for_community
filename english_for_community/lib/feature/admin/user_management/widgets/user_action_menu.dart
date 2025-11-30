import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/entity/user_entity.dart';
import '../../dashboard_home/bloc/admin_bloc.dart';
import '../../dashboard_home/bloc/admin_event.dart';
import 'user_ban_dialog.dart';

class UserActionMenu extends StatelessWidget {
  final UserEntity user;

  const UserActionMenu({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Lấy trạng thái từ Entity (isBanned có thể null nên default false)
    final bool isBanned = user.isBanned;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Color(0xFFA1A1AA)), // Zinc-400
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE4E4E7)),
      ),
      elevation: 4,
      onSelected: (value) => _handleAction(context, value, isBanned),
      itemBuilder: (context) => [
        _buildItem('edit', Icons.edit_outlined, 'Chỉnh sửa thông tin', Colors.black87),
        _buildItem(
          'ban',
          isBanned ? Icons.lock_open_rounded : Icons.block_rounded,
          isBanned ? 'Mở khóa tài khoản' : 'Khóa tài khoản',
          isBanned ? Colors.green : Colors.orange,
        ),
        const PopupMenuDivider(height: 1),
        _buildItem('delete', Icons.delete_outline, 'Xóa vĩnh viễn', Colors.red),
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
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tính năng Edit đang phát triển"))
        );
        break;

      case 'ban':
        if (isBanned) {
          // Logic Mở khóa
          // Sử dụng closure context (context cha) nên vẫn gọi được Bloc
          _showConfirmDialog(
              context,
              title: 'Mở khóa tài khoản?',
              content: 'Người dùng sẽ có thể đăng nhập và sử dụng dịch vụ bình thường.',
              confirmText: 'Mở khóa',
              confirmColor: Colors.green,
              onConfirm: () {
                context.read<AdminBloc>().add(
                    BanUserEvent(userId: user.id, banType: 'unban', reason: 'Admin unlocked')
                );
              }
          );
        } else {
          // Logic Khóa -> Hiện Dialog UserBanDialog
          // 🔥 SỬA LỖI TẠI ĐÂY: Cần lấy Bloc ra trước khi mở Dialog
          final adminBloc = context.read<AdminBloc>();

          showDialog(
            context: context,
            builder: (ctx) => BlocProvider.value( // ✅ Cung cấp Bloc hiện tại cho Dialog
              value: adminBloc,
              child: UserBanDialog(userId: user.id),
            ),
          );
        }
        break;

      case 'delete':
        _showConfirmDialog(
          context,
          title: 'Xóa người dùng?',
          content: 'Hành động này KHÔNG THỂ hoàn tác. Tất cả dữ liệu học tập sẽ bị mất.',
          confirmText: 'Xóa vĩnh viễn',
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
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey))
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Đóng dialog
              onConfirm();        // Thực hiện hành động (dùng context cha)
            },
            style: TextButton.styleFrom(foregroundColor: confirmColor),
            child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}