import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/entity/user_entity.dart';
import 'admin_user_details_dialog.dart';
import 'user_action_menu.dart';
import 'user_role_badge.dart';

class UserCard extends StatelessWidget {
  final UserEntity user;
  final VoidCallback? onChanged;

  const UserCard({super.key, required this.user, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final bool isOnline = user.isOnline;
    final bool isBanned = user.isBanned;

    return Container(
      decoration: BoxDecoration(
        color: isBanned ? AppColors.dangerBg : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
            color: isBanned ? AppColors.dangerBg : AppColors.outline),
        boxShadow: [
          BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          // ?? CLICK CARD TO OPEN DIALOG
          onTap: () async {
            final changed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AdminUserDetailsDialog(
                userId: user.id,
              ),
            );
            if (changed == true) onChanged?.call();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AdminWebUi.userAvatarCircle(
                  avatarUrl: user.avatarUrl,
                  displayName: user.fullName,
                  radius: 24,
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
                              user.fullName.isNotEmpty
                                  ? user.fullName
                                  : 'Unknown User',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isBanned
                                      ? AppColors.danger
                                      : AppColors.textPrimary,
                                  decoration: isBanned
                                      ? TextDecoration.lineThrough
                                      : null),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isBanned)
                            const _StatusChip(
                                label: 'BANNED',
                                color: Colors.red,
                                icon: Icons.block)
                          else
                            _StatusChip(
                                label: isOnline
                                    ? t.adminUserStatusOnline
                                    : t.adminUserStatusOffline,
                                color: isOnline
                                    ? AppColors.success
                                    : AppColors.textMuted,
                                isDot: true),
                          const SizedBox(width: 6),
                          UserRoleBadge(role: user.role),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email.isNotEmpty ? user.email : 'No email',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            isOnline
                                ? t.adminUserActiveNow
                                : (user.lastActivityDate != null
                                    ? t.adminUserLastActive(
                                        DateFormat('HH:mm dd/MM').format(
                                            user.lastActivityDate!.toLocal()))
                                    : t.adminUserNeverActive),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                // --- 3 DOT MENU ---
                UserActionMenu(user: user, onChanged: onChanged),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDot;
  final IconData? icon;

  const _StatusChip(
      {required this.label,
      required this.color,
      this.isDot = false,
      this.icon});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.xs),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDot)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              )
            else if (icon != null)
              Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
