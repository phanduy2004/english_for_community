import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../util/app_haptics.dart';
import '../theme/app_color.dart';
import '../theme/app_skill_colors.dart';
import '../theme/app_motion.dart' as theme_motion;
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'e4c_scroll_behavior.dart';
import 'interactive/scale_pressable.dart';
import 'motion/app_lottie_preset.dart';
import 'motion/app_lottie_view.dart';
import 'motion/app_motion.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'widget/app_card.dart';
import 'widget/student_mobile_skeleton.dart';

/// Mobile UI helpers for student screens — `docs/ui-ux-system/03`, `04`, `05`, `15`.
abstract final class StudentMobileUi {
  static const double pageHPadding = 12;
  static const double pageTopPadding = 10;
  static const double pageBottomPadding = 20;
  static const double sectionGap = 14;
  static const double cardGap = 8;
  static const double appBarHeight = 46;

  /// Compact spacing for skill runners (reading/listening MCQ, etc.).
  static const double exerciseSectionGap = 10;
  static const EdgeInsets exerciseCardPadding = EdgeInsets.all(10);

  static EdgeInsets get pagePadding => const EdgeInsets.fromLTRB(
        pageHPadding,
        pageTopPadding,
        pageHPadding,
        pageBottomPadding,
      );

  static EdgeInsets pagePaddingWithBottom(double extra) =>
      EdgeInsets.fromLTRB(pageHPadding, pageTopPadding, pageHPadding, pageBottomPadding + extra);

  // ─── Typography shortcuts ─────────────────────────────────────────────

  static TextStyle greeting(BuildContext context) => context.h1Style;

  static TextStyle sectionTitle(BuildContext context) => context.h2Style;

  static TextStyle cardTitle(BuildContext context) => context.h3Style;

  static TextStyle body(BuildContext context) => context.bodyStyle;

  static TextStyle bodyLg(BuildContext context) =>
      AppTypography.body(large: true);

  static TextStyle caption(BuildContext context) => context.captionStyle;

  static TextStyle kpi(BuildContext context) => AppTypography.kpiValue(web: false);

  /// Web: defer rebuild to next frame — tránh mouse_tracker assert khi hover + setState.
  static void scheduleRebuild(VoidCallback fn) {
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => fn());
    } else {
      fn();
    }
  }

  /// Web-safe tap target — InkWell (mobile) / GestureDetector (web, tránh mouse_tracker assert).
  static Widget inkTap({
    required Widget child,
    VoidCallback? onTap,
    BorderRadius? borderRadius,
    Color? splashColor,
    Color? materialColor,
  }) {
    if (onTap == null) return child;
    if (kIsWeb) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      );
    }
    return Material(
      color: materialColor ?? Colors.transparent,
      borderRadius: borderRadius,
      clipBehavior: borderRadius != null ? Clip.antiAlias : Clip.none,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: splashColor,
        child: child,
      ),
    );
  }

  // ─── Section header ───────────────────────────────────────────────────

  static Widget sectionHeader(
    BuildContext context, {
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Expanded(child: Text(title, style: sectionTitle(context))),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
              minimumSize: const Size(44, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel, style: AppTypography.label()),
          ),
      ],
    );
  }

  // ─── AppBar (flat, no elevation) ──────────────────────────────────────

  static PreferredSizeWidget appBar(
    BuildContext context, {
    required String title,
    List<Widget>? actions,
    bool showBack = true,
  }) {
    return AppBar(
      toolbarHeight: appBarHeight,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      leading: showBack
          ? (kIsWeb
              ? Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.s2),
                  child: inkTap(
                    onTap: () => Navigator.maybePop(context),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.arrow_back_rounded, size: 20),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  onPressed: () => Navigator.maybePop(context),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                ))
          : null,
      title: Text(title, style: sectionTitle(context)),
      actions: actions,
    );
  }

  // ─── Empty / error ──────────────────────────────────────────────────────

  static Widget emptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    String? ctaLabel,
    VoidCallback? onCta,
    SkillType? skill,
    AppLottiePreset? lottie,
  }) {
    final iconColor = skill != null
        ? AppSkillColors.of(skill).color
        : AppColors.textSecondary;
    final iconBg = skill != null
        ? AppSkillColors.of(skill).tint
        : AppColors.surfaceSubtle;
    final bodyStyle = StudentMobileUi.body(context);
    final iconFallback = Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: iconBg,
        shape: BoxShape.circle,
        border: Border.all(
          color: (skill != null ? AppSkillColors.of(skill).color : AppColors.outline)
              .withValues(alpha: 0.25),
        ),
      ),
      child: Icon(icon, size: 28, color: iconColor),
    );
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const verticalPad = AppSpacing.s10;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (lottie != null)
          AppLottieView(
            preset: lottie,
            size: AppMotion.emptyLottieSize,
            fallback: iconFallback,
          )
        else
          iconFallback,
        const SizedBox(height: AppSpacing.s5),
        Text(title, style: sectionTitle(context), textAlign: TextAlign.center),
        if (body.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s3),
          Text(body, style: bodyStyle, textAlign: TextAlign.center),
        ],
        if (ctaLabel != null && onCta != null) ...[
          const SizedBox(height: AppSpacing.s5),
          FilledButton(onPressed: onCta, child: Text(ctaLabel)),
        ],
      ],
    );
    // Avoid LayoutBuilder — incompatible with SliverFillRemaining intrinsics.
    return Align(
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          pageHPadding,
          verticalPad,
          pageHPadding,
          verticalPad + bottomInset,
        ),
        child: content,
      ),
    );
  }

  /// Centered page loading — skeleton thay spinner (`20` §5.4).
  static Widget pageLoading() => runnerLoading();

  static Widget listLoading({int itemCount = 6}) =>
      StudentMobileSkeleton.skillList(itemCount: itemCount);

  static Widget runnerLoading() => StudentMobileSkeleton.runnerQuestion();

  static Widget flashcardLoading() => StudentMobileSkeleton.flashcard();

  static Widget lobbyLoading() => StudentMobileSkeleton.examLobby();

  static Widget errorBanner({
    required String message,
    required VoidCallback onRetry,
    String retryLabel = 'Retry',
  }) {
    return AppCard(
      variant: AppCardVariant.danger,
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: AppTypography.body(color: AppColors.textPrimary),
            ),
          ),
          kIsWeb
              ? inkTap(
                  onTap: onRetry,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s4,
                      vertical: AppSpacing.s2,
                    ),
                    child: Text(retryLabel, style: AppTypography.label(color: AppColors.primary)),
                  ),
                )
              : TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }

  /// Full-page fetch error + retry — `docs/ui-ux-system/20` §5.9.
  static Widget errorRetry(
    BuildContext context, {
    required String message,
    required VoidCallback onRetry,
    String? title,
    String? retryLabel,
  }) {
    final label = retryLabel ?? 'Retry';
    return Center(
      child: Padding(
        padding: pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.s5),
            if (title != null) ...[
              Text(title, style: sectionTitle(context), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.s2),
            ],
            Text(message, style: body(context), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.s5),
            FilledButton.icon(
              onPressed: () {
                AppHaptics.confirm(context);
                onRetry();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  /// Bọc icon-only / nút nhỏ — đảm bảo touch target ≥ [minSize] (doc 20 §5.1).
  static Widget tappable({
    required BuildContext context,
    required Widget child,
    required VoidCallback? onTap,
    double minSize = 48,
    String? tooltip,
    String? semanticsLabel,
    BorderRadius? borderRadius,
  }) {
    final label = semanticsLabel ?? tooltip;
    Widget wrapped = ConstrainedBox(
      constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
      child: inkTap(
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.input),
        onTap: onTap == null
            ? null
            : () {
                AppHaptics.select(context);
                onTap();
              },
        child: Center(child: child),
      ),
    );
    if (tooltip != null && tooltip.isNotEmpty) {
      wrapped = Tooltip(message: tooltip, child: wrapped);
    }
    if (label != null && label.isNotEmpty) {
      wrapped = Semantics(label: label, button: true, child: wrapped);
    }
    return wrapped;
  }

  // ─── List tile (1-line / 2-line) ──────────────────────────────────────

  static Widget listTile({
    required BuildContext context,
    required String title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s5,
        vertical: AppSpacing.s4,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: AppSpacing.s4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: cardTitle(context)),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.s2),
                  Text(subtitle, style: body(context)),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing
          else if (onTap != null)
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );

    if (onTap == null) return child;
    return inkTap(
      materialColor: AppColors.surfaceCard,
      onTap: onTap,
      child: child,
    );
  }

  // ─── Filter chips & search (skill hubs) ───────────────────────────────

  /// Selectable filter chip — selected dùng skill color nếu [skill] có; không thì primary.
  static Widget filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    SkillType? skill,
  }) {
    final skillSet = skill != null ? AppSkillColors.of(skill) : null;
    final bg = selected
        ? (skillSet?.tint ?? AppColors.primaryTint)
        : AppColors.surfaceCard;
    final borderColor = selected
        ? (skillSet?.color ?? AppColors.primary)
        : AppColors.outline;
    final fg = selected
        ? (skillSet?.dark ?? AppColors.primaryDark)
        : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.s3),
      child: inkTap(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        materialColor: bg,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: borderColor),
          ),
          child: Text(label, style: AppTypography.label(color: fg)),
        ),
      ),
    );
  }

  static Widget filterRow({
    required List<String> labels,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    SkillType? skill,
  }) {
    return e4cHorizontalScroll(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: List.generate(
            labels.length,
            (i) => filterChip(
              label: labels[i],
              selected: i == selectedIndex,
              onTap: () => onSelected(i),
              skill: skill,
            ),
          ),
        ),
      ),
    );
  }

  /// Search field — `04` §4.1: `surfaceSubtle`, no shadow.
  static Widget searchField({
    required TextEditingController controller,
    required String hintText,
    bool? showClear,
    VoidCallback? onClear,
  }) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final clearVisible = showClear ?? value.text.trim().isNotEmpty;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(AppRadius.input + 2),
            border: Border.all(color: AppColors.outline),
          ),
          child: TextField(
            controller: controller,
            style: AppTypography.body(),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTypography.body(color: AppColors.textMuted),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: AppSpacing.s4,
                horizontal: AppSpacing.s4,
              ),
              isDense: true,
              suffixIcon: clearVisible
                  ? (kIsWeb
                      ? inkTap(
                          onTap: onClear,
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          color: AppColors.textMuted,
                          onPressed: onClear,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        ))
                  : null,
            ),
          ),
        );
      },
    );
  }

  /// Flat promo card for skill hub tops — dùng màu kỹ năng nếu có (`05` §4.1).
  static Widget skillHubBanner({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    String? badge,
    SkillType? skill,
  }) {
    final colors = skill != null ? AppSkillColors.of(skill) : null;
    return Container(
      decoration: BoxDecoration(
        color: colors?.tint ?? AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors?.color.withValues(alpha: 0.20) ?? AppColors.outline,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: sectionTitle(context)),
                const SizedBox(height: AppSpacing.s1),
                Text(subtitle, style: body(context)),
                if (badge != null) ...[
                  const SizedBox(height: AppSpacing.s2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s3,
                      vertical: AppSpacing.s1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Text(
                      badge,
                      style: AppTypography.label(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          skillIconBox(icon, skill: skill, size: 44),
        ],
      ),
    );
  }

  static Color difficultyColor(String? key) {
    switch (key?.toLowerCase()) {
      case 'easy':
      case 'beginner':
        return AppColors.success;
      case 'medium':
      case 'intermediate':
        return AppColors.warning;
      case 'hard':
      case 'advanced':
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

  /// AppBar với accent line 2px theo màu kỹ năng — nhận diện ngay màn đang ở skill nào.
  ///
  /// [showLoading] — thay accent tĩnh bằng progress indeterminate (đổi filter / fetch list).
  static PreferredSizeWidget skillAppBar(
    BuildContext context, {
    required String title,
    required SkillType skill,
    List<Widget>? actions,
    bool showBack = true,
    bool showLoading = false,
  }) {
    final accent = AppSkillColors.of(skill).color;
    return PreferredSize(
      preferredSize: const Size.fromHeight(appBarHeight + 2),
      child: Column(
        children: [
          appBar(context, title: title, actions: actions, showBack: showBack),
          if (showLoading)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: accent.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            )
          else
            Container(height: 2, color: accent.withValues(alpha: 0.55)),
        ],
      ),
    );
  }

  /// Card có viền trái theo màu kỹ năng — tăng nhận diện trong list bài học.
  ///
  /// [emphasized] — một card nổi full màu; các card còn lại chỉ icon-tint nhẹ.
  static Widget skillAccentCard({
    required SkillType skill,
    required Widget child,
    VoidCallback? onTap,
    /// Web: bỏ outer tap khi [child] đã có nút riêng — tránh mouse_tracker assert.
    bool tapViaChildActionsOnWeb = false,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.s4),
    EdgeInsetsGeometry? margin,
    bool emphasized = false,
  }) {
    final colors = AppSkillColors.of(skill);
    final radius = BorderRadius.circular(AppRadius.card + 2);
    final effectiveOnTap =
        onTap == null || (kIsWeb && tapViaChildActionsOnWeb) ? null : onTap;

    Widget cardBody = Padding(padding: padding, child: child);
    if (effectiveOnTap != null) {
      cardBody = inkTap(
        onTap: effectiveOnTap,
        borderRadius: radius,
        splashColor: colors.color.withValues(alpha: 0.10),
        child: cardBody,
      );
    }

    Widget card = Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: radius,
        border: Border.all(color: AppColors.outline),
      ),
      foregroundDecoration: emphasized
          ? BoxDecoration(
              borderRadius: radius,
              border: Border(
                left: BorderSide(color: colors.color, width: AppSpacing.s2),
              ),
            )
          : null,
      child: cardBody,
    );

    if (margin != null) {
      card = Padding(padding: margin, child: card);
    }
    return card;
  }

  /// Footer list card kỹ năng: meta/progress trên, nút căn phải — tránh overflow web hẹp.
  static Widget skillListCardFooter({
    required Widget info,
    required Widget actions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        info,
        const SizedBox(height: AppSpacing.s4),
        Align(alignment: Alignment.centerRight, child: actions),
      ],
    );
  }

  /// Progress bar — animated when [context] is set (`20` §5.7).
  static Widget skillProgressBar({
    required double value,
    BuildContext? context,
    SkillType? skill,
    double height = 8,
    Color? color,
  }) {
    final clamped = value.clamp(0.0, 1.0);
    final fill = color ??
        (skill != null
            ? AppSkillColors.of(skill).color
            : (clamped >= 1.0 ? AppColors.success : AppColors.accent));

    Widget bar(double v) => ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: v,
            backgroundColor: AppColors.outlineMuted,
            valueColor: AlwaysStoppedAnimation(fill),
            minHeight: height,
          ),
        );

    if (context != null && !kIsWeb) {
      return TweenAnimationBuilder<double>(
        key: ValueKey(clamped.toStringAsFixed(3)),
        tween: Tween(begin: 0, end: clamped),
        duration: theme_motion.AppMotion.effective(context, theme_motion.AppMotion.base),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => bar(v),
      );
    }
    return bar(clamped);
  }

  /// Nút truy cập nhanh tròn — dùng màu kỹ năng hoặc accent.
  static Widget quickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    SkillType? skill,
    Color? iconColor,
    Color? iconBg,
  }) {
    final set = skill != null ? AppSkillColors.of(skill) : null;
    final fg = iconColor ?? set?.color ?? AppColors.primary;
    final bg = iconBg ?? set?.tint ?? AppColors.primaryTint;
    const iconDiameter = 48.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScalePressable(
          onTap: onTap,
          borderRadius: BorderRadius.circular(iconDiameter / 2),
          minScale: 0.97,
          splashColor: fg.withValues(alpha: 0.12),
          child: SizedBox(
            width: iconDiameter,
            height: iconDiameter,
            child: DecoratedBox(
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: fg, size: 22),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: caption(context).copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// Stat card nhỏ (streak / points / level) với icon màu.
  ///
  /// [compact] — home stats row: thấp hơn (~80dp), label `textMuted`.
  static Widget statCard({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    Color? iconColor,
    Color? iconBg,
    SkillType? skill,
    bool compact = false,
  }) {
    final set = skill != null ? AppSkillColors.of(skill) : null;
    final fg = iconColor ?? set?.color ?? AppColors.textSecondary;
    final bg = iconBg ?? set?.tint ?? AppColors.primaryTint;
    final iconBox = compact ? AppSpacing.s7 : AppSpacing.s8;
    final iconGlyph = compact ? 14.0 : 15.0;

    return SizedBox(
      width: double.infinity,
      child: AppCard(
        variant: AppCardVariant.outline,
        padding: EdgeInsets.symmetric(
          vertical: compact ? AppSpacing.s2 : AppSpacing.s3,
          horizontal: AppSpacing.s4,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          Container(
            width: iconBox,
            height: iconBox,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: iconGlyph, color: fg),
          ),
          SizedBox(height: compact ? AppSpacing.s1 : AppSpacing.s2),
          Text(value, style: kpi(context)),
          const SizedBox(height: AppSpacing.s1),
          Text(
            label,
            style: compact
                ? caption(context).copyWith(color: AppColors.textMuted)
                : caption(context),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        ),
      ),
    );
  }

  /// Icon box for skill / lesson rows.
  ///
  /// Khi [skill] được cung cấp → dùng màu kỹ năng (student vibrancy).
  /// Không cung cấp → monochrome (dùng cho context phi kỹ năng).
  static Widget skillIconBox(
    IconData icon, {
    double size = 48,
    SkillType? skill,
    SkillColorSet? colors,
  }) {
    final set = colors ?? (skill != null ? AppSkillColors.of(skill) : null);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: set?.tint ?? AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Icon(icon, color: set?.color ?? AppColors.primary, size: size * 0.5),
    );
  }

  /// Icon box dạng tròn (cho profile, stats).
  static Widget roundIconBox(
    IconData icon, {
    double size = 48,
    Color? color,
    Color? bg,
  }) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg ?? AppColors.primaryTint,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color ?? AppColors.primary, size: size * 0.5),
    );
  }

  /// Circular header action (notification, AI) — touch target ≥44dp (`20` §4.1).
  static Widget headerIconButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    String? semanticsLabel,
    Widget? badge,
    Color? backgroundColor,
    Color? iconColor,
    Color? borderColor,
  }) {
    const visualSize = 36.0;
    const tapSize = 48.0;
    const iconSize = 18.0;
    final label = semanticsLabel ?? tooltip;
    Widget button = SizedBox(
      width: tapSize,
      height: tapSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          inkTap(
            onTap: () {
              AppHaptics.select(context);
              onPressed();
            },
            borderRadius: BorderRadius.circular(visualSize / 2),
            materialColor: backgroundColor ?? AppColors.surfaceCard,
            child: Container(
              width: visualSize,
              height: visualSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: backgroundColor ?? AppColors.surfaceCard,
                border: Border.all(color: borderColor ?? AppColors.outline, width: 1),
              ),
              child: Icon(icon, size: iconSize, color: iconColor ?? AppColors.primary),
            ),
          ),
          if (badge != null)
            Positioned(top: 0, right: 0, child: badge),
        ],
      ),
    );
    if (tooltip != null) {
      button = Tooltip(message: tooltip, child: button);
    }
    if (label != null) {
      button = Semantics(button: true, label: label, child: button);
    }
    return button;
  }

  /// Exit-confirm dialog khi runner đang `in_progress` (`20` §5.8).
  static Future<bool> confirmRunnerExit(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.studentRunnerExitTitle),
        content: Text(l10n.studentRunnerExitMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.studentRunnerExitCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.studentRunnerExitConfirm),
          ),
        ],
      ),
    );
    return ok == true;
  }

  /// `PopScope` + confirm thoát khi [blockExit] (`20` §5.8).
  static Widget runnerPopScope({
    required BuildContext context,
    required bool blockExit,
    required Widget child,
    VoidCallback? onConfirmedExit,
  }) {
    return PopScope<Object?>(
      canPop: !blockExit,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (!blockExit) return;
        confirmRunnerExit(context).then((leave) {
          if (!leave || !context.mounted) return;
          if (onConfirmedExit != null) {
            onConfirmedExit();
          } else {
            Navigator.of(context).pop();
          }
        });
      },
      child: child,
    );
  }

  static Widget notificationBadge(int count) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceCard, width: 1.5),
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
            color: AppColors.textInverse,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }

  /// Bottom action bar for lesson runners.
  static Widget bottomActionBar({
    required BuildContext context,
    required String progressLabel,
    required String ctaLabel,
    required VoidCallback onCta,
    bool ctaEnabled = true,
    bool loading = false,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s3,
        AppSpacing.s4,
        AppSpacing.s3 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(top: BorderSide(color: AppColors.outlineMuted)),
      ),
      child: Row(
        children: [
          Text(progressLabel, style: cardTitle(context)),
          const Spacer(),
          FilledButton(
            onPressed: ctaEnabled && !loading ? onCta : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(80, 36),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : Text(ctaLabel),
          ),
        ],
      ),
    );
  }

  // ─── Skill list card actions (hub list — completed row) ─────────────────

  /// Nút Start trên thẻ bài chưa hoàn thành.
  static Widget skillCardPrimaryButton({
    required VoidCallback onPressed,
    required String label,
  }) {
    if (kIsWeb) {
      return GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          child: Text(label, style: AppTypography.label(color: AppColors.onPrimary)),
        ),
      );
    }
    return SizedBox(
      height: 32,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
        ),
        child: Text(label, style: AppTypography.label(color: AppColors.onPrimary)),
      ),
    );
  }

  /// Nút Review trên thẻ bài đã hoàn thành.
  static Widget skillCardReviewButton({
    required VoidCallback onPressed,
    required String label,
  }) {
    if (kIsWeb) {
      return GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.remove_red_eye_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.s2),
              Text(label, style: AppTypography.label(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 32,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.outline),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
        ),
        icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
        label: Text(label, style: AppTypography.label()),
      ),
    );
  }

  /// Nút Retake — foreground trắng (tránh `AppTypography.label()` đen trên nền primary).
  static Widget skillCardRetakeButton({
    required VoidCallback onPressed,
    required String label,
  }) {
    if (kIsWeb) {
      return GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.replay, size: 16, color: AppColors.onPrimary),
              const SizedBox(width: AppSpacing.s2),
              Text(label, style: AppTypography.label(color: AppColors.onPrimary)),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 32,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
        ),
        icon: const Icon(Icons.replay, size: 16, color: AppColors.onPrimary),
        label: Text(label, style: AppTypography.label(color: AppColors.onPrimary)),
      ),
    );
  }

  // ─── MCQ pager (Phase 4 — swipe giữa câu, `20` §4.4) ───────────────────

  /// Header hiển thị tiến độ câu hỏi (vd. `3 / 12`).
  static Widget mcqPagerHeader(
    BuildContext context, {
    required int current,
    required int total,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        pageHPadding,
        AppSpacing.s3,
        pageHPadding,
        AppSpacing.s2,
      ),
      child: Row(
        children: [
          Text('$current / $total', style: caption(context)),
          const Spacer(),
          Text(
            total > 0 ? '${((current / total) * 100).round()}%' : '0%',
            style: caption(context),
          ),
        ],
      ),
    );
  }

  /// Swipe [PageView] giữa câu MCQ — một câu mỗi trang; 1 câu → scroll đơn.
  static Widget mcqQuestionPager({
    required BuildContext context,
    required PageController controller,
    required int itemCount,
    required ValueChanged<int> onPageChanged,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    if (itemCount <= 1) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: pagePadding,
        child: itemBuilder(context, 0),
      );
    }
    return PageView.builder(
      controller: controller,
      itemCount: itemCount,
      onPageChanged: onPageChanged,
      physics: const BouncingScrollPhysics(),
      itemBuilder: itemBuilder,
    );
  }

  // ─── MCQ options (`04` §11) ─────────────────────────────────────────────

  static String mcqLetter(int index) => String.fromCharCode(65 + index);

  /// Single- or multi-select MCQ row; review via [showReviewCorrect] / [showReviewWrong].
  static Widget mcqOption({
    required BuildContext context,
    required int index,
    required String text,
    bool selected = false,
    bool multiSelect = false,
    bool checked = false,
    VoidCallback? onTap,
    bool showReviewCorrect = false,
    bool showReviewWrong = false,
    String? subtitle,
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: AppSpacing.s2),
  }) {
    var bg = AppColors.surfaceCard;
    var border = AppColors.outline;
    var textColor = AppColors.textPrimary;
    IconData? trailIcon;
    Color? trailColor;

    if (showReviewCorrect) {
      bg = AppColors.successBg;
      border = AppColors.success;
      trailIcon = Icons.check_circle_rounded;
      trailColor = AppColors.success;
    } else if (showReviewWrong) {
      bg = AppColors.dangerBg;
      border = AppColors.danger;
      trailIcon = Icons.cancel_rounded;
      trailColor = AppColors.danger;
    } else if (selected || (multiSelect && checked)) {
      bg = AppColors.infoBg;
      border = AppColors.info;
      textColor = AppSkillColors.listening.dark;
    }

    final bodyStyle = body(context);
    final semanticsLabel = '${mcqLetter(index)}. $text';

    return Padding(
      padding: margin,
      child: Semantics(
        button: onTap != null,
        selected: selected || (multiSelect && checked),
        inMutuallyExclusiveGroup: !multiSelect,
        label: semanticsLabel,
        child: inkTap(
          onTap: onTap == null
              ? null
              : () {
                  AppHaptics.select(context);
                  onTap();
                },
          borderRadius: BorderRadius.circular(AppRadius.card),
          materialColor: bg,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: border),
            ),
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
                decoration: BoxDecoration(
                  color: border.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppRadius.card - 1),
                  ),
                ),
                child: Text(
                  mcqLetter(index),
                  style: bodyStyle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s3,
                    AppSpacing.s3,
                    AppSpacing.s3,
                    AppSpacing.s3,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text, style: bodyStyle.copyWith(color: textColor)),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.s2),
                        Text(subtitle, style: caption(context)),
                      ],
                    ],
                  ),
                ),
              ),
              if (trailIcon != null)
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.s4,
                    right: AppSpacing.s4,
                  ),
                  child: Icon(trailIcon, color: trailColor, size: 22),
                )
              else if (multiSelect)
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.s3,
                    right: AppSpacing.s3,
                  ),
                  child: Icon(
                    checked
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 20,
                    color: checked ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  /// Streak chip — dùng accent màu lửa khi có streak, xám khi chưa có.
  static Widget streakChip(BuildContext context, int days) {
    final hasStreak = days > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasStreak ? AppColors.accentTint : AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: hasStreak ? AppColors.accent.withValues(alpha: 0.35) : AppColors.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 16,
            color: hasStreak ? AppColors.accent : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            '$days',
            style: kpi(context).copyWith(
              color: hasStreak ? AppColors.accentDark : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog shell for student modals — `04` §6.1.
class StudentDialogShell extends StatelessWidget {
  const StudentDialogShell({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.actions,
    this.maxWidth = 320,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sheet + 2),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: StudentMobileUi.sectionTitle(context)),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.s3),
                Text(subtitle!, style: StudentMobileUi.body(context)),
              ],
              const SizedBox(height: AppSpacing.s5),
              child,
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet with handle — `15` §2.
class StudentBottomSheet extends StatelessWidget {
  const StudentBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.showClose = true,
  });

  final String title;
  final Widget child;
  final bool showClose;

  static Future<T?> show<T>(BuildContext context, StudentBottomSheet sheet) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet + 2)),
      ),
      builder: (_) => sheet,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.s3),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s5,
              AppSpacing.s4,
              AppSpacing.s5,
              AppSpacing.s3,
            ),
            child: Row(
              children: [
                if (showClose)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                Expanded(
                  child: Text(
                    title,
                    style: StudentMobileUi.sectionTitle(context),
                    textAlign: showClose ? TextAlign.center : TextAlign.start,
                  ),
                ),
                if (showClose) const SizedBox(width: 44),
              ],
            ),
          ),
          Flexible(child: child),
        ],
      ),
    );
  }
}
