import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_color.dart';
import '../theme/app_skill_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'interactive/scale_pressable.dart';
import 'widget/app_card.dart';

/// Mobile UI helpers for student screens — `docs/ui-ux-system/03`, `04`, `05`, `15`.
abstract final class StudentMobileUi {
  static const double pageHPadding = 14;
  static const double pageTopPadding = 14;
  static const double pageBottomPadding = 24;
  static const double sectionGap = 20;
  static const double cardGap = 12;
  static const double appBarHeight = 52;

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
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              onPressed: () => Navigator.maybePop(context),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            )
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
  }) {
    final iconColor = skill != null
        ? AppSkillColors.of(skill).color
        : AppColors.textSecondary;
    final iconBg = skill != null
        ? AppSkillColors.of(skill).tint
        : AppColors.surfaceSubtle;
    final bodyStyle = StudentMobileUi.body(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: (skill != null
                        ? AppSkillColors.of(skill).color
                        : AppColors.outline)
                    .withValues(alpha: 0.25),
              ),
            ),
            child: Icon(icon, size: 36, color: iconColor),
          ),
          const SizedBox(height: AppSpacing.s5),
          Text(title, style: sectionTitle(context), textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.s3),
          Text(body, style: bodyStyle, textAlign: TextAlign.center),
          if (ctaLabel != null && onCta != null) ...[
            const SizedBox(height: AppSpacing.s5),
            FilledButton(onPressed: onCta, child: Text(ctaLabel)),
          ],
        ],
      ),
    );
  }

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
          TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
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
    return Material(
      color: AppColors.surfaceCard,
      child: InkWell(
        onTap: onTap,
        child: child,
      ),
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
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          side: BorderSide(color: borderColor),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: 6,
            ),
            child: Text(label, style: AppTypography.label(color: fg)),
          ),
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
    return SingleChildScrollView(
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
    );
  }

  /// Search field — `04` §4.1: `surfaceSubtle`, no shadow.
  static Widget searchField({
    required TextEditingController controller,
    required String hintText,
    bool showClear = false,
    VoidCallback? onClear,
  }) {
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
          suffixIcon: showClear
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  color: AppColors.textMuted,
                  onPressed: onClear,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                )
              : null,
        ),
      ),
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
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: sectionTitle(context)),
                const SizedBox(height: AppSpacing.s2),
                Text(subtitle, style: body(context)),
                if (badge != null) ...[
                  const SizedBox(height: AppSpacing.s3),
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
          const SizedBox(width: AppSpacing.s4),
          skillIconBox(icon, skill: skill, size: 52),
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
  static PreferredSizeWidget skillAppBar(
    BuildContext context, {
    required String title,
    required SkillType skill,
    List<Widget>? actions,
    bool showBack = true,
  }) {
    final accent = AppSkillColors.of(skill).color;
    return PreferredSize(
      preferredSize: const Size.fromHeight(appBarHeight + 2),
      child: Column(
        children: [
          appBar(context, title: title, actions: actions, showBack: showBack),
          Container(height: 2, color: accent.withValues(alpha: 0.55)),
        ],
      ),
    );
  }

  /// Card có viền trái 3px theo màu kỹ năng — tăng nhận diện trong list bài học.
  static Widget skillAccentCard({
    required SkillType skill,
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.s4),
    EdgeInsetsGeometry? margin,
  }) {
    final colors = AppSkillColors.of(skill);
    final radius = BorderRadius.circular(AppRadius.card + 2);

    Widget card = Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: radius,
        border: Border.all(color: AppColors.outline),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border(
          left: BorderSide(color: colors.color, width: 3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: colors.color.withValues(alpha: 0.10),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (margin != null) {
      card = Padding(padding: margin, child: card);
    }
    return card;
  }

  /// Progress bar — mặc định accent; có thể truyền [skill] để dùng màu kỹ năng.
  static Widget skillProgressBar({
    required double value,
    SkillType? skill,
    double height = 8,
    Color? color,
  }) {
    final fill = color ??
        (skill != null
            ? AppSkillColors.of(skill).color
            : (value >= 1.0 ? AppColors.success : AppColors.accent));
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        backgroundColor: AppColors.outlineMuted,
        valueColor: AlwaysStoppedAnimation(fill),
        minHeight: height,
      ),
    );
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
  static Widget statCard({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    Color? iconColor,
    Color? iconBg,
    SkillType? skill,
  }) {
    final set = skill != null ? AppSkillColors.of(skill) : null;
    final fg = iconColor ?? set?.color ?? AppColors.textSecondary;
    final bg = iconBg ?? set?.tint ?? AppColors.primaryTint;

    return AppCard(
      variant: AppCardVariant.outline,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.s4,
        horizontal: AppSpacing.s3,
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: fg),
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(value, style: kpi(context)),
          const SizedBox(height: AppSpacing.s2),
          Text(
            label,
            style: caption(context),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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

  /// Circular header action (notification, AI).
  static Widget headerIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    Widget? badge,
  }) {
    const size = 40.0;
    const iconSize = 20.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: AppColors.surfaceCard,
            shape: const CircleBorder(
              side: BorderSide(color: AppColors.outline, width: 1),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: SizedBox(
                width: size,
                height: size,
                child: Icon(icon, size: iconSize, color: AppColors.primary),
              ),
            ),
          ),
          if (badge != null)
            Positioned(top: -2, right: -2, child: badge),
        ],
      ),
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
        AppSpacing.s5,
        AppSpacing.s4,
        AppSpacing.s5,
        AppSpacing.s4 + MediaQuery.paddingOf(context).bottom,
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
              minimumSize: const Size(88, 44),
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

  /// Nút Review trên thẻ bài đã hoàn thành.
  static Widget skillCardReviewButton({
    required VoidCallback onPressed,
    required String label,
  }) {
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
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: AppSpacing.s3),
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

    return Padding(
      padding: margin,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: border),
        ),
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap();
                },
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
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
                    AppSpacing.s4,
                    AppSpacing.s4,
                    AppSpacing.s3,
                    AppSpacing.s4,
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
