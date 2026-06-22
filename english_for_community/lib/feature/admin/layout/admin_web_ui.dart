import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_fonts.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/core/ui/avatar_url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Web admin console — căn chỉnh teacher compact v3 (`docs/ui-ux-system/06-web-foundations.md`).
abstract final class AdminWebUi {
  static const double sidebarWidth = 212;
  static const double sidebarCollapsedWidth = 48;
  static const double topBarHeight = 44;
  static const double pageHeaderMinHeight = 52;
  static const double contentMaxDashboard = 1120;
  static const double contentMaxForm = 720;
  static const double contentMaxEditor = 960;
  static const double contentMaxTable = 1280;

  static const double buttonHeightPrimary = 32;
  static const double sidebarItemHeight = 30;

  static const double minFallbackWidth = 768;
  static const double sidebarExpandedMinWidth = 1024;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.s6,
    vertical: AppSpacing.s5,
  );

  static const EdgeInsets pageHeaderPadding = EdgeInsets.fromLTRB(
    AppSpacing.s6,
    AppSpacing.s5,
    AppSpacing.s6,
    AppSpacing.s4,
  );

  static EdgeInsets pageScrollPadding(BuildContext context) {
    return const EdgeInsets.only(bottom: AppSpacing.s9);
  }

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: AppColors.shadowCard, blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: AppColors.shadowAmbient, blurRadius: 1, offset: Offset(0, 1)),
  ];

  static BoxDecoration cardDecoration({Color? bg}) => BoxDecoration(
        color: bg ?? AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outline, width: 1),
        boxShadow: cardShadow,
      );

  /// Flat workspace panel — border only, no shadow.
  static BoxDecoration panelDecoration({Color? bg}) => BoxDecoration(
        color: bg ?? AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outline, width: 1),
      );

  /// Decode avatars at display size — skips unusable URLs (e.g. github.com profile pages).
  static ImageProvider? networkAvatar(String? url, {double logicalSize = 36}) {
    if (!isUsableAvatarUrl(url)) return null;
    final dpr = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final px = (logicalSize * dpr).ceil();
    return ResizeImage.resizeIfNeeded(px, px, NetworkImage(url!.trim()));
  }

  /// Circle avatar with network image + initials fallback.
  static Widget userAvatarCircle({
    required String? avatarUrl,
    required String displayName,
    double radius = 14,
  }) {
    final bg = networkAvatar(avatarUrl, logicalSize: radius * 2);
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryTint,
      backgroundImage: bg,
      child: bg == null
          ? Text(
              avatarInitials(displayName),
              style: TextStyle(
                fontSize: radius * 0.85,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            )
          : null,
    );
  }

  static TextStyle webPageTitle(BuildContext context) =>
      AppTypography.webTextTheme.headlineMedium!;

  static TextStyle webH1(BuildContext context) => webPageTitle(context);

  static TextStyle webH2(BuildContext context) =>
      AppTypography.webTextTheme.titleLarge!;

  static TextStyle webKpiValue(BuildContext context) => AppTypography.kpiValue(web: true);

  static TextStyle webH3(BuildContext context) =>
      AppTypography.webTextTheme.titleMedium!;

  static TextStyle webBody(BuildContext context) =>
      AppTypography.webTextTheme.bodyMedium!;

  static TextStyle webLabel(BuildContext context) =>
      AppTypography.webTextTheme.labelMedium!;

  static TextStyle webCaption(BuildContext context) =>
      AppTypography.webTextTheme.bodySmall!;

  static TextStyle webTableHead(BuildContext context) => webLabel(context).copyWith(
        letterSpacing: 0.4,
        color: AppColors.textSecondary,
      );

  static TextStyle webBreadcrumb(BuildContext context) => webCaption(context).copyWith(
        fontSize: AppTypography.webCaption,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle sectionTitle(BuildContext context) => webLabel(context).copyWith(
        fontSize: AppTypography.webLabel,
        letterSpacing: 0.35,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      );

  static const TextStyle metaMuted = TextStyle(
    fontFamily: AppFonts.fontFamily,
    fontSize: AppTypography.webCaption,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static InputDecoration formInputDecoration(BuildContext context, {String? hintText}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: const BorderSide(color: AppColors.outline),
    );
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      hintStyle: metaMuted,
      filled: true,
      fillColor: AppColors.surfaceCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  static ButtonStyle compactHeaderIconStyle() => IconButton.styleFrom(
        minimumSize: const Size(buttonHeightPrimary, buttonHeightPrimary),
        maximumSize: const Size(buttonHeightPrimary, buttonHeightPrimary),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      );

  static ButtonStyle compactFilledStyle(BuildContext context) => FilledButton.styleFrom(
        minimumSize: const Size(0, buttonHeightPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        textStyle: webLabel(context).copyWith(
          fontSize: AppTypography.webLabel,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      );

  static ButtonStyle compactOutlinedStyle(BuildContext context) => OutlinedButton.styleFrom(
        minimumSize: const Size(0, buttonHeightPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        textStyle: webBody(context).copyWith(
          fontSize: AppTypography.webBody,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
      );

  static TextStyle formControlLabelStyle(BuildContext context) => webLabel(context).copyWith(
        fontSize: AppTypography.webLabel,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  static Widget formFieldLabel(BuildContext context, String text) => Text(
        text,
        style: formControlLabelStyle(context),
      );

  // --- A11y / validation helpers (`docs/ui-ux-system/19` §5.3) ---

  /// Error text inline dưới field — KHÔNG dùng toast cho lỗi validate.
  static Widget formFieldError(BuildContext context, String? message) {
    if (message == null || message.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s2),
      child: Text(
        message,
        style: webCaption(context).copyWith(color: AppColors.danger),
      ),
    );
  }

  /// Bọc phần tử tap được để hiện **focus ring 2px** khi Tab + hover/press state.
  static Widget focusableTile({
    required Widget child,
    required VoidCallback? onTap,
    BorderRadius? borderRadius,
    String? tooltip,
    String? semanticLabel,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.card);
    Widget tile = _FocusableTile(
      onTap: onTap,
      radius: radius,
      semanticLabel: semanticLabel,
      child: child,
    );
    if (tooltip != null && tooltip.isNotEmpty) {
      tile = Tooltip(message: tooltip, child: tile);
    }
    return tile;
  }
}

/// Tile tap được có **focus ring 2px** (Tab) + hover/press overlay. `19` §5.3.
class _FocusableTile extends StatefulWidget {
  const _FocusableTile({
    required this.child,
    required this.onTap,
    required this.radius,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius radius;
  final String? semanticLabel;

  @override
  State<_FocusableTile> createState() => _FocusableTileState();
}

class _FocusableTileState extends State<_FocusableTile> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final overlay = _hovered ? AppColors.hoverOverlay : Colors.transparent;
    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: widget.onTap != null,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        mouseCursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppMotion.effective(context, AppMotion.micro),
            decoration: BoxDecoration(
              color: overlay,
              borderRadius: widget.radius,
              border: Border.all(
                color: _focused ? AppColors.focusRing : Colors.transparent,
                width: 2,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
