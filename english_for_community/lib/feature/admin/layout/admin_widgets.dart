import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/admin/layout/admin_skill_palette.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'package:flutter/material.dart';

/// Default page size for admin list tables (`19` §5.10).
const int kAdminDefaultRowsPerPage = 20;

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
    return AdminWebUi.focusableTile(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Ink(decoration: AdminWebUi.cardDecoration(), child: child),
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
    return AdminWebUi.focusableTile(
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
    return AdminWebUi.focusableTile(
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
    );
  }
}

/// Alias used across admin list pages.
typedef AdminEmptyState = AdminEmptyCard;

class AdminEmptyCard extends StatelessWidget {
  const AdminEmptyCard({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final hasCta = actionLabel != null && onAction != null;
    if (hasCta) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s4),
        decoration: AdminWebUi.cardDecoration(bg: AppColors.surfaceSubtle),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.s5),
            Expanded(child: Text(message, style: AdminWebUi.webBody(context))),
            const SizedBox(width: AppSpacing.s4),
            FilledButton(
              style: AdminWebUi.compactFilledStyle(context),
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ),
      );
    }
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

/// Editor save-state machine — idle / saving / saved / error (`19` §5.7).
enum AdminSaveState { idle, saving, saved, error }

class AdminSaveStateIndicator extends StatelessWidget {
  const AdminSaveStateIndicator({
    super.key,
    required this.state,
    this.savedAt,
    this.onRetry,
  });

  final AdminSaveState state;
  final DateTime? savedAt;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (Widget icon, String label, Color color) = switch (state) {
      AdminSaveState.idle => (
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle),
          ),
          '',
          AppColors.textMuted,
        ),
      AdminSaveState.saving => (
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.textMuted),
          ),
          l10n.teacherSaveStateSaving,
          AppColors.textMuted,
        ),
      AdminSaveState.saved => (
          const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
          savedAt != null
              ? l10n.teacherSaveStateSavedAt(
                  MaterialLocalizations.of(context).formatTimeOfDay(
                    TimeOfDay.fromDateTime(savedAt!),
                    alwaysUse24HourFormat: true,
                  ),
                )
              : l10n.teacherExamDraftSaved,
          AppColors.success,
        ),
      AdminSaveState.error => (
          const Icon(Icons.error_outline, size: 14, color: AppColors.danger),
          l10n.teacherSaveStateError,
          AppColors.danger,
        ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        if (label.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.s2),
          Text(label, style: AdminWebUi.webCaption(context).copyWith(color: color)),
        ],
        if (state == AdminSaveState.error && onRetry != null) ...[
          const SizedBox(width: AppSpacing.s2),
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onRetry,
            child: Text(l10n.teacherSaveStateRetry, style: AdminWebUi.webCaption(context)),
          ),
        ],
      ],
    );
  }
}

/// Shared pagination footer — Ops Center pattern (`19` §5.10).
class AdminPaginationBar extends StatelessWidget {
  const AdminPaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.totalRows,
    required this.rowsPerPage,
    required this.onRowsPerPageChanged,
    required this.onPageChanged,
    this.rowsPerPageOptions = const [10, 20, 50],
  });

  final int page;
  final int totalPages;
  final int totalRows;
  final int rowsPerPage;
  final ValueChanged<int> onRowsPerPageChanged;
  final ValueChanged<int> onPageChanged;
  final List<int> rowsPerPageOptions;

  @override
  Widget build(BuildContext context) {
    final safeTotalPages = totalPages.clamp(1, 9999);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Total: $totalRows', style: AdminWebUi.webCaption(context)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rows per page:', style: AdminWebUi.webCaption(context)),
            const SizedBox(width: AppSpacing.s3),
            SizedBox(
              height: 28,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: rowsPerPageOptions.contains(rowsPerPage) ? rowsPerPage : rowsPerPageOptions.first,
                  style: AdminWebUi.webCaption(context).copyWith(color: AppColors.textPrimary),
                  icon: const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textMuted),
                  items: rowsPerPageOptions
                      .map((e) => DropdownMenuItem<int>(value: e, child: Text('$e')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onRowsPerPageChanged(v);
                  },
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s5),
            IconButton(
              splashRadius: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.chevron_left, color: page > 1 ? AppColors.textPrimary : AppColors.textMuted),
              onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
            ),
            const SizedBox(width: AppSpacing.s4),
            Text('Page $page of $safeTotalPages', style: AdminWebUi.webCaption(context)),
            const SizedBox(width: AppSpacing.s4),
            IconButton(
              splashRadius: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.chevron_right, color: page < safeTotalPages ? AppColors.textPrimary : AppColors.textMuted),
              onPressed: page < safeTotalPages ? () => onPageChanged(page + 1) : null,
            ),
          ],
        ),
      ],
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
