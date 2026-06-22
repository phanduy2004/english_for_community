import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// Centered modal shell — `docs/ui-ux-system/07-web-components.md` §4.
class TeacherDialogShell extends StatelessWidget {
  const TeacherDialogShell({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.body,
    this.footer,
    this.width = 480,
    this.maxBodyHeight = 420,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget body;
  final Widget? footer;
  final double width;
  final double maxBodyHeight;

  static Future<T?> show<T>(BuildContext context, {required Widget child}) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Icon(icon, size: 20, color: AppColors.primaryDark),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TeacherWebUi.webH2(context)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(subtitle!, style: TeacherWebUi.metaMuted),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TeacherWebUi.compactHeaderIconStyle(),
                    icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                    tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.outline),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxBodyHeight),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  child: body,
                ),
              ),
            ),
            if (footer != null) ...[
              const Divider(height: 1, color: AppColors.outline),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: footer!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standard dialog footer: Cancel (outlined) + primary action.
class TeacherDialogFooterActions extends StatelessWidget {
  const TeacherDialogFooterActions({
    super.key,
    required this.cancelLabel,
    required this.primaryLabel,
    this.onCancel,
    this.onPrimary,
    this.primaryLoading = false,
    this.destructive = false,
    this.primaryEnabled = true,
  });

  final String cancelLabel;
  final String primaryLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onPrimary;
  final bool primaryLoading;
  final bool destructive;
  final bool primaryEnabled;

  @override
  Widget build(BuildContext context) {
    final primaryStyle = destructive
        ? FilledButton.styleFrom(
            minimumSize: const Size(0, TeacherWebUi.buttonHeightPrimary),
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            textStyle: TeacherWebUi.webLabel(context).copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          )
        : TeacherWebUi.compactFilledStyle(context);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: primaryLoading ? null : (onCancel ?? () => Navigator.of(context).pop()),
            style: TeacherWebUi.compactOutlinedStyle(context),
            child: Text(cancelLabel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: (primaryLoading || !primaryEnabled || onPrimary == null) ? null : onPrimary,
            style: primaryStyle,
            child: primaryLoading
                ? const SizedBox(
                    child: const AppLoadingIndicator.button(color: Colors.white),
                  )
                : Text(primaryLabel),
          ),
        ),
      ],
    );
  }
}

/// Tappable row inside teacher dialogs (settings hub, pickers).
class TeacherDialogOptionTile extends StatelessWidget {
  const TeacherDialogOptionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outlineMuted),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: Icon(icon, size: 18, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TeacherWebUi.webBody(context).copyWith(fontWeight: FontWeight.w500),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: TeacherWebUi.webCaption(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Text(
                  trailing!,
                  style: TeacherWebUi.webCaption(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (showChevron && onTap != null) ...[
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Section label inside dialog body.
class TeacherDialogSectionLabel extends StatelessWidget {
  const TeacherDialogSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: Text(text, style: TeacherWebUi.webTableHead(context)),
    );
  }
}

/// Collapsible block inside teacher dialogs — bordered card + explicit expand control (`14` §4.3).
class TeacherDialogExpandableSection extends StatefulWidget {
  const TeacherDialogExpandableSection({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.expandLabel,
    required this.collapseLabel,
    required this.child,
    this.initiallyExpanded = false,
    this.onExpandedChanged,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String expandLabel;
  final String collapseLabel;
  final Widget child;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpandedChanged;

  @override
  State<TeacherDialogExpandableSection> createState() =>
      _TeacherDialogExpandableSectionState();
}

class _TeacherDialogExpandableSectionState
    extends State<TeacherDialogExpandableSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    widget.onExpandedChanged?.call(_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final actionLabel = _expanded ? widget.collapseLabel : widget.expandLabel;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outlineMuted),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(AppRadius.card),
                bottom: _expanded ? Radius.zero : const Radius.circular(AppRadius.card),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(AppRadius.input),
                      ),
                      child: Icon(widget.icon, size: 18, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TeacherWebUi.webBody(context).copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle!,
                              style: TeacherWebUi.metaMuted.copyWith(fontSize: 11, height: 1.35),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _toggle,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      child: Text(actionLabel),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1, color: AppColors.outlineMuted),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                    child: widget.child,
                  ),
                ],
              ),
              crossFadeState:
                  _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: AppMotion.web,
              sizeCurve: Curves.easeOut,
            ),
          ],
        ),
      ),
    );
  }
}
