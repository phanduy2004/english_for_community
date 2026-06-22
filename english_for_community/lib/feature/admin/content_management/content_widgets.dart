import 'package:english_for_community/core/theme/admin_status_palette.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'package:flutter/material.dart';

/// Semantic aliases — dùng `AppColors` trực tiếp ở code mới.
const kBgPage = AppColors.surface;
const kWhite = AppColors.surfaceCard;
const kTextMain = AppColors.textPrimary;
const kTextMuted = AppColors.textSecondary;
const kBorder = AppColors.outline;
const kPrimary = AppColors.textPrimary;

/// Card CMS — delegate `AdminWebUi.cardDecoration`.
class ShadcnCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const ShadcnCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          decoration: AdminWebUi.cardDecoration(),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.s5),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Form input CMS — delegate `AdminWebUi`.
class ShadcnInput extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final int maxLines;
  final bool isReadOnly;
  final Widget? suffixIcon;
  final Function(String)? onChanged;
  final TextInputType? keyboardType;

  const ShadcnInput({
    super.key,
    required this.label,
    this.hint = '',
    this.controller,
    this.maxLines = 1,
    this.isReadOnly = false,
    this.suffixIcon,
    this.onChanged,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          AdminWebUi.formFieldLabel(context, label),
          const SizedBox(height: AppSpacing.s2),
        ],
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: maxLines,
          readOnly: isReadOnly,
          keyboardType: keyboardType,
          style: AdminWebUi.webBody(context),
          decoration: AdminWebUi.formInputDecoration(context, hintText: hint.isEmpty ? null : hint).copyWith(
            suffixIcon: suffixIcon,
            fillColor: isReadOnly ? AppColors.surfaceSubtle : AppColors.surfaceCard,
          ),
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const SectionHeader({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: AdminWebUi.webH3(context),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: AppSpacing.s2),
            action!,
          ],
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const StatusBadge({super.key, required this.text, required this.color});

  factory StatusBadge.active({required bool isActive}) {
    return StatusBadge(
      text: isActive ? 'Published' : 'Draft',
      color: isActive ? AdminStatusPalette.approvedFg : AppColors.textSecondary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: AppSpacing.s1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
