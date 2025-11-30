import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/entity/user_entity.dart';
import 'user_action_menu.dart'; // Import Menu

class UserCard extends StatelessWidget {
  final UserEntity user;
  const UserCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final bool isOnline = user.isOnline;
    final bool isBanned = user.isBanned ?? false; // Cần thêm field này vào Entity

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isBanned ? const Color(0xFFFEF2F2) : Colors.white, // Nền đỏ nhạt nếu bị ban
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isBanned ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)), // Viền đỏ nếu ban
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              image: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                  ? DecorationImage(image: NetworkImage(user.avatarUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                ? Center(child: Text(user.fullName.isNotEmpty ? user.fullName[0] : 'U', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))))
                : null,
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.fullName.isNotEmpty ? user.fullName : 'Unknown User',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isBanned ? const Color(0xFF991B1B) : const Color(0xFF0F172A),
                            decoration: isBanned ? TextDecoration.lineThrough : null
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isBanned)
                      _StatusChip(label: 'BANNED', color: Colors.red, icon: Icons.block)
                    else
                      _StatusChip(
                          label: isOnline ? 'Online' : 'Offline',
                          color: isOnline ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
                          isDot: true
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.email.isNotEmpty ? user.email : 'No email',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      isOnline
                          ? 'Đang hoạt động'
                          : (user.lastActivityDate != null
                          ? 'Truy cập ${DateFormat('HH:mm dd/MM').format(user.lastActivityDate!.toLocal())}'
                          : 'Chưa truy cập'),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                )
              ],
            ),
          ),

          // --- MENU 3 CHẤM ---
          UserActionMenu(user: user),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDot;
  final IconData? icon;

  const _StatusChip({required this.label, required this.color, this.isDot = false, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDot)
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            )
          else if (icon != null)
            Icon(icon, size: 10, color: color),

          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}