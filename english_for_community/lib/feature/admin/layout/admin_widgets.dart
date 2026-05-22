import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'package:flutter/material.dart';

class AdminKpiCard extends StatelessWidget {
  const AdminKpiCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.meta,
    this.accent = AppColors.chartHighlight,
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
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: AdminWebUi.webLabel(context)),
              ),
              Icon(icon, size: 18, color: accent),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(value, style: AdminWebUi.webH1(context)),
          if (meta != null && meta!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(meta!, style: AdminWebUi.webCaption(context), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          decoration: AdminWebUi.cardDecoration(),
          child: child,
        ),
      ),
    );
  }
}

class AdminNavTile extends StatelessWidget {
  const AdminNavTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = AppColors.primary,
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
          padding: const EdgeInsets.all(AppSpacing.s5),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  border: Border.all(color: accent.withValues(alpha: 0.15)),
                ),
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(width: AppSpacing.s5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AdminWebUi.webBody(context).copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AdminWebUi.webCaption(context), maxLines: 1, overflow: TextOverflow.ellipsis),
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

class AdminSearchField extends StatelessWidget {
  const AdminSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.width = 320,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 36,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AdminWebUi.webBody(context),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AdminWebUi.webCaption(context),
          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.surfaceSubtle,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide: const BorderSide(color: AppColors.outlineStrong),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide: const BorderSide(color: AppColors.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class AdminStatusPill extends StatelessWidget {
  const AdminStatusPill({
    super.key,
    required this.label,
    this.tone = AdminStatusTone.neutral,
  });

  final String label;
  final AdminStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      AdminStatusTone.success => (AppColors.successBg, AppColors.success),
      AdminStatusTone.warning => (AppColors.warningBg, AppColors.warning),
      AdminStatusTone.danger => (AppColors.dangerBg, AppColors.danger),
      AdminStatusTone.primary => (AppColors.primaryTint, AppColors.primaryDark),
      AdminStatusTone.neutral => (AppColors.outlineMuted, AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: fg,
              height: 1.2,
            ),
      ),
    );
  }
}

enum AdminStatusTone { neutral, primary, success, warning, danger }

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.s5),
            Text(message, style: AdminWebUi.webBody(context), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
