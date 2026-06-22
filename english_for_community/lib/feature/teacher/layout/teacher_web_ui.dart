import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/avatar_url.dart';
import 'package:english_for_community/core/theme/app_fonts.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_mobile_ui.dart';
import 'package:flutter/material.dart';

/// Web teacher workspace — `docs/ui-ux-system/00-compact-density-v3.md`.
abstract final class TeacherWebUi {
  static const double sidebarWidth = 212;
  static const double sidebarCollapsedWidth = 48;
  static const double topBarHeight = 44;
  static const double pageHeaderMinHeight = 52;
  static const double contentMaxDashboard = 1120;
  static const double contentMaxForm = 720;
  static const double contentMaxEditor = 960;
  static const double contentMaxTable = 1280;

  // --- Component heights (compact) ---
  static const double buttonHeightPrimary = 32;
  static const double buttonHeightSecondary = 28;
  static const double inputHeight = 32;
  static const double tableRowDefault = 40;
  static const double tableRowCompact = 32;
  static const double sidebarItemHeight = 30;

  /// Dưới mức này → màn fallback (không dùng console), `docs/ui-ux-system/06` §1.
  static const double minFallbackWidth = 768;

  /// Sidebar chỉ mở rộng khi viewport ≥ giá trị này (laptop); nhỏ hơn → icon rail.
  static const double sidebarExpandedMinWidth = 1024;

  /// @deprecated Dùng [minFallbackWidth].
  static const double minDesktopWidth = minFallbackWidth;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.s6,
    vertical: AppSpacing.s5,
  );

  /// Web vs teacher-mobile shell padding.
  static EdgeInsets pagePaddingFor(BuildContext context) {
    return TeacherMobileUi.isMobileWorkspace(context)
        ? TeacherMobileUi.pagePadding
        : pagePadding;
  }

  /// ListView / inner scroll inside [TeacherPageScaffold] — horizontal & top from scaffold.
  static EdgeInsets pageScrollPadding(BuildContext context) {
    final mobile = TeacherMobileUi.isMobileWorkspace(context);
    return EdgeInsets.only(
      bottom: AppSpacing.s9 + (mobile ? AppSpacing.s3 : 0),
    );
  }

  static const EdgeInsets pageHeaderPadding = EdgeInsets.fromLTRB(
    AppSpacing.s6,
    AppSpacing.s5,
    AppSpacing.s6,
    AppSpacing.s4,
  );

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: AppColors.shadowCard, blurRadius: 6, offset: Offset(0, 2)),
  ];

  /// Elevated surface — dialog, popover, floating card only (border + shadow).
  ///
  /// List/dashboard tiles use [panelDecoration] (F-1 / visual polish).
  static BoxDecoration cardDecoration({Color? bg}) => BoxDecoration(
        color: bg ?? AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outline, width: 1),
        boxShadow: cardShadow,
      );

  /// Flat workspace panel — border only, no shadow (Linear / Stripe lists).
  static BoxDecoration panelDecoration({Color? bg}) => BoxDecoration(
        color: bg ?? AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outline, width: 1),
      );

  /// Decode avatars at display size (P1-R6) — pass logical diameter in px.
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

  /// Inline text action in data tables (Open, Grade, Copy…).
  static ButtonStyle linkActionStyle(BuildContext context) => TextButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: webLabel(context).copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.outline,
        ),
      );

  /// Page title (dashboard greeting, console title) — 16 / 600.
  static TextStyle webPageTitle(BuildContext context) =>
      AppTypography.webTextTheme.headlineMedium!;

  /// @deprecated Prefer [webPageTitle]. Alias for migration.
  static TextStyle webH1(BuildContext context) => webPageTitle(context);

  static TextStyle webH2(BuildContext context) =>
      AppTypography.webTextTheme.titleLarge!;

  /// KPI / stat number — 15 / 600 tabular.
  static TextStyle webKpiValue(BuildContext context) => AppTypography.kpiValue(web: true);

  static TextStyle webH3(BuildContext context) =>
      AppTypography.webTextTheme.titleMedium!;

  static TextStyle webBody(BuildContext context) =>
      AppTypography.webTextTheme.bodyMedium!;

  static TextStyle webBodyLg(BuildContext context) =>
      AppTypography.webTextTheme.bodyLarge!;

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

  static TextStyle listTitle(BuildContext context) => webH3(context);

  static TextStyle sectionTitle(BuildContext context) => webLabel(context).copyWith(
        fontSize: AppTypography.webLabel,
        letterSpacing: 0.35,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      );

  /// Meta line (timestamp, hint) — không cần [BuildContext].
  static const TextStyle metaMuted = TextStyle(
    fontFamily: AppFonts.fontFamily,
    fontSize: AppTypography.webCaption,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  // --- Web form pattern (`docs/ui-ux-system/07-web-components.md` §7.4) ---

  /// Label **phía trên** ô nhập (không dùng `labelText` nổi của Material — tránh chữ cắt viền).
  static TextStyle formControlLabelStyle(BuildContext context) =>
      webLabel(context).copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: AppTypography.webLabel,
        height: 1.25,
      );

  static Widget formFieldLabel(BuildContext context, String text) => Text(
        text,
        style: formControlLabelStyle(context),
      );

  /// Padding chuẩn ô text/dropdown — compact (minHeight ~32).
  static const EdgeInsets formInputContentPadding = EdgeInsets.symmetric(horizontal: 10, vertical: 8);

  /// Viền + fill đồng bộ mọi field trong form workspace.
  static InputDecoration formInputDecoration(BuildContext context, {String? hintText}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      borderSide: const BorderSide(color: AppColors.outline),
    );
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      hintStyle: metaMuted,
      filled: true,
      fillColor: AppColors.surfaceCard,
      contentPadding: formInputContentPadding,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    );
  }

  /// Segmented control: nền chưa chọn đồng nhất (`surfaceCard`), đã chọn `primaryTint` + chữ `primary`.
  /// Custom choice tiles (assign exam, classroom picker) dùng cùng pattern — xem [choiceTileDecoration].
  static BoxDecoration choiceTileDecoration({required bool selected}) => BoxDecoration(
        color: selected ? AppColors.primaryTint : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.outline,
          width: selected ? 1.5 : 1,
        ),
      );

  static Color choiceTileTitleColor({required bool selected}) =>
      selected ? AppColors.primary : AppColors.textPrimary;

  static Color choiceTileIconColor({required bool selected}) =>
      selected ? AppColors.primary : AppColors.textMuted;

  static Color choiceTileIconBoxColor({required bool selected}) =>
      selected ? AppColors.primaryStrong : AppColors.surfaceSubtle;

  /// Icon cùng chiều cao với [compactFilledStyle] trong page header / toolbar.
  static ButtonStyle compactHeaderIconStyle() => IconButton.styleFrom(
        minimumSize: const Size(buttonHeightPrimary, buttonHeightPrimary),
        maximumSize: const Size(buttonHeightPrimary, buttonHeightPrimary),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      );

  static ButtonStyle compactFilledStyle(BuildContext context) => FilledButton.styleFrom(
        minimumSize: const Size(0, buttonHeightPrimary),
        maximumSize: Size(double.infinity, buttonHeightPrimary),
        padding: _compactButtonPadding,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: _compactButtonShape,
        textStyle: _compactButtonText(context),
      );

  static ButtonStyle compactOutlinedStyle(BuildContext context) => OutlinedButton.styleFrom(
        minimumSize: const Size(0, buttonHeightPrimary),
        maximumSize: Size(double.infinity, buttonHeightPrimary),
        padding: _compactButtonPadding,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: _compactButtonShape,
        side: const BorderSide(color: AppColors.outline),
        textStyle: _compactButtonText(context),
      );

  /// Destructive outlined — end session, remove member, etc.
  static ButtonStyle compactDangerOutlinedStyle(BuildContext context) => OutlinedButton.styleFrom(
        minimumSize: const Size(0, buttonHeightPrimary),
        maximumSize: Size(double.infinity, buttonHeightPrimary),
        padding: _compactButtonPadding,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: _compactButtonShape,
        foregroundColor: AppColors.danger,
        side: const BorderSide(color: AppColors.danger),
        textStyle: _compactButtonText(context),
      );

  static const EdgeInsets _compactButtonPadding = EdgeInsets.symmetric(horizontal: AppSpacing.s4);
  static const RoundedRectangleBorder _compactButtonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.input)),
  );

  // --- A11y / validation helpers (`docs/ui-ux-system/18` §5.6, §5.9) ---

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

  /// Header icon button with focus ring (`18` §5.9).
  static Widget headerIconButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback? onPressed,
    String? tooltip,
    Color? color,
  }) {
    final radius = BorderRadius.circular(AppRadius.input);
    return focusableTile(
      onTap: onPressed,
      borderRadius: radius,
      tooltip: tooltip,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
      ),
    );
  }

  /// Bọc phần tử tap được để hiện **focus ring 2px** khi Tab + hover/press state.
  /// Dùng cho sidebar tile, KPI card, dialog choice tile, icon action.
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

  static TextStyle _compactButtonText(BuildContext context) => webLabel(context).copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.0,
      );

  static ButtonStyle segmentedControlStyle(BuildContext context) {
    return ButtonStyle(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: const WidgetStatePropertyAll(Size(32, 32)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
      textStyle: WidgetStatePropertyAll(
        webBody(context).copyWith(fontSize: AppTypography.webBody, fontWeight: FontWeight.w500, height: 1.2),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primaryTint;
        if (states.contains(WidgetState.disabled)) return AppColors.surfaceSubtle;
        return AppColors.surfaceCard;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        if (states.contains(WidgetState.disabled)) return AppColors.textMuted;
        return AppColors.textPrimary;
      }),
      side: const WidgetStatePropertyAll(BorderSide(color: AppColors.outline, width: 1)),
    );
  }
}

/// Tile tap được có **focus ring 2px** (Tab) + hover/press overlay. `18` §5.9.
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
