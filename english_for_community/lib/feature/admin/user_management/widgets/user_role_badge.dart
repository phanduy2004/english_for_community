import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'package:flutter/material.dart';

/// Role pill for admin user lists — distinguishes student / teacher / admin.
class UserRoleBadge extends StatelessWidget {
  const UserRoleBadge({super.key, required this.role});

  final String role;

  _RoleStyle _styleFor(String role) {
    switch (role) {
      case 'admin':
        return _RoleStyle(
          labelKey: _RoleLabel.admin,
          fg: AppColors.primaryDark,
          bg: AppColors.primaryTint,
          border: AppColors.primary,
        );
      case 'teacher':
        return const _RoleStyle(
          labelKey: _RoleLabel.teacher,
          fg: Color(0xFF1D4ED8),
          bg: Color(0xFFEFF6FF),
          border: Color(0xFF93C5FD),
        );
      default:
        return const _RoleStyle(
          labelKey: _RoleLabel.student,
          fg: Color(0xFF047857),
          bg: Color(0xFFECFDF5),
          border: Color(0xFF6EE7B7),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = _styleFor(role);
    final label = switch (style.labelKey) {
      _RoleLabel.admin => l10n.adminUserRoleAdmin,
      _RoleLabel.teacher => l10n.adminUserRoleTeacher,
      _ => l10n.adminUserRoleStudent,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: style.border.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: AdminWebUi.webCaption(context).copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: style.fg,
          height: 1.1,
        ),
      ),
    );
  }
}

enum _RoleLabel { student, teacher, admin }

class _RoleStyle {
  const _RoleStyle({
    required this.labelKey,
    required this.fg,
    required this.bg,
    required this.border,
  });

  final _RoleLabel labelKey;
  final Color fg;
  final Color bg;
  final Color border;
}
