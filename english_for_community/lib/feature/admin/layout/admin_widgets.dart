import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/admin/layout/admin_skill_palette.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'package:flutter/material.dart';

/// KPI compact — icon màu trong ô 32×32 (giống teacher dashboard).
class AdminKpiCard extends StatelessWidget {
  const AdminKpiCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.meta,
    required this.accent,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final String? meta;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Icon(icon, color: accent, size: 16),
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AdminWebUi.webKpiValue(context)),
                const SizedBox(height: 2),
                Text(label, style: AdminWebUi.webCaption(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (meta != null && meta!.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(meta!, style: AdminWebUi.metaMuted, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(decoration: AdminWebUi.cardDecoration(), child: child),
      ),
    );
  }
}

/// Thẻ kỹ năng CMS — icon lớn, màu nổi bật (giữ thiết kế content dashboard).
class AdminSkillCard extends StatelessWidget {
  const AdminSkillCard({
    super.key,
    required this.title,
    required this.count,
    required this.countLabel,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final int count;
  final String countLabel;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          decoration: AdminWebUi.cardDecoration(),
          padding: const EdgeInsets.all(AppSpacing.s5),
          child: SizedBox(
            height: 148,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AdminWebUi.webBody(context).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text('$count $countLabel', style: AdminWebUi.webCaption(context)),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hub điều hướng nhanh trên dashboard — icon màu 40×40.
class AdminNavTile extends StatelessWidget {
  const AdminNavTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = AdminSkillPalette.contentHub,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          decoration: AdminWebUi.cardDecoration(),
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  border: Border.all(color: accent.withValues(alpha: 0.18)),
                ),
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AdminWebUi.webBody(context).copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AdminWebUi.metaMuted, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alias used across admin list pages.
typedef AdminEmptyState = AdminEmptyCard;

class AdminEmptyCard extends StatelessWidget {
  const AdminEmptyCard({super.key, required this.message, this.icon = Icons.inbox_outlined});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8, horizontal: AppSpacing.s6),
      decoration: AdminWebUi.cardDecoration(bg: AppColors.surfaceSubtle),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.s4),
          Text(message, style: AdminWebUi.webBody(context), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class AdminSearchField extends StatelessWidget {
  const AdminSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.width = 280,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: AdminWebUi.buttonHeightPrimary,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AdminWebUi.webBody(context),
        decoration: AdminWebUi.formInputDecoration(context, hintText: hint).copyWith(
          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class AdminRetryButton extends StatelessWidget {
  const AdminRetryButton({super.key, required this.onPressed, this.label});

  final VoidCallback onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: AdminWebUi.compactOutlinedStyle(context),
      onPressed: onPressed,
      icon: const Icon(Icons.refresh, size: 16),
      label: Text(label ?? 'Retry'),
    );
  }
}
