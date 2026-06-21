import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Design tokens — `docs/ui-ux-system/02`, `04`, `07`.
abstract final class ClassroomChatUi {
  // Layout
  static const double miniWindowWidth = 328;
  static const double miniWindowHeight = 460;
  static const double settingsPanelWidth = 300;
  static const double listPanelWidth = 340;
  static const double headerHeight = 52;
  static const double headerHeightCompact = 48;

  static const double bubbleRadius = 18;
  static const double bubbleRadiusTail = 6;
  static const double maxBubbleWidthRatio = 0.72;

  /// Tin gửi — xanh da trời (Messenger-style).
  static const Color bubbleSent = Color(0xFF0EA5E9);
  static const Color bubbleSentDark = Color(0xFF0284C7);

  /// Tin nhận — xám nhạt (Messenger-style).
  static const Color bubbleReceived = Color(0xFFE7E5E4);

  static const Duration hoverFade = Duration(milliseconds: 160);
  static const Duration reactionStrip = Duration(milliseconds: 200);
  static const Curve hoverCurve = Curves.easeOutCubic;

  static bool isHeartReaction(String emoji) {
    final normalized = emoji.replaceAll(RegExp(r'[\uFE0E\uFE0F]'), '').trim();
    return normalized == '❤' || normalized == '♥' || emoji.contains('❤');
  }

  /// Hiển thị emoji cảm xúc — trái tim luôn màu đỏ (tránh font đen trên Android).
  static Widget reactionGlyph(String emoji, {double size = 13}) {
    if (isHeartReaction(emoji)) {
      return Icon(Icons.favorite, size: size + 1, color: AppColors.danger);
    }
    return Text(emoji, style: TextStyle(fontSize: size, height: 1.1));
  }

  /// Viền avatar giáo viên — vàng ánh kim.
  static const Color teacherRingLight = Color(0xFFF7E98A);
  static const Color teacherRingMid = Color(0xFFD4AF37);
  static const Color teacherRingDark = Color(0xFFB8860B);

  /// Tin nhắn giáo viên — nền & chữ.
  static const Color bubbleTeacherReceived = Color(0xFFFFF7E6);
  static const Color bubbleTeacherSent = Color(0xFFFDE68A);
  static const Color teacherSenderName = Color(0xFF9A7209);
  static const Color teacherMessageText = Color(0xFF422006);

  static const double teacherAvatarRingWidth = 2.5;

  static double teacherAvatarOuterSize([double radius = 16]) =>
      radius * 2 + teacherAvatarRingWidth * 2 + 2;

  /// Viền tròn vàng ánh kim quanh avatar giáo viên.
  static Widget teacherAvatarRing({
    required Widget child,
    required double radius,
  }) {
    final inner = radius * 2;
    final outer = teacherAvatarOuterSize(radius);
    return SizedBox(
      width: outer,
      height: outer,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [teacherRingLight, teacherRingMid, teacherRingDark, teacherRingLight],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: teacherRingMid.withValues(alpha: 0.45),
              blurRadius: 5,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(1.5),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceCard,
            ),
            child: Center(
              child: SizedBox(
                width: inner,
                height: inner,
                child: ClipOval(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static bool supportsHoverActions(BuildContext context) {
    if (!kIsWeb) return false;
    return MediaQuery.sizeOf(context).width >= 640;
  }

  static bool isMobileLayout(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 640;

  /// Avatar (32) + gap (8) — căn bubble tin nhận trên mobile.
  static const double avatarColumnWidth = 40;

  static double maxBubbleWidth({required bool compact, double? parentWidth}) {
    final base = parentWidth ?? (compact ? miniWindowWidth : 480);
    return base * maxBubbleWidthRatio;
  }

  static double bubbleParentWidth(BuildContext context, {required bool compact}) =>
      compact ? miniWindowWidth : MediaQuery.sizeOf(context).width;

  static double messageSideRailWidth({required bool compact}) {
    final size = compact ? 26.0 : 30.0;
    final gap = compact ? 3.0 : 4.0;
    return size * 3 + gap * 2;
  }

  static double messageSideRailGap({required bool compact}) => compact ? 4.0 : 6.0;

  static double bubbleContentMaxWidth({
    required double parentMaxWidth,
    required bool compact,
    required bool reserveSideActionRail,
  }) {
    if (!reserveSideActionRail) return parentMaxWidth;
    final reserved =
        messageSideRailWidth(compact: compact) + messageSideRailGap(compact: compact);
    return (parentMaxWidth - reserved).clamp(48.0, parentMaxWidth);
  }

  // Surfaces
  static BoxDecoration chatCanvas({bool compact = false}) => const BoxDecoration(
        color: AppColors.surface,
      );

  static List<BoxShadow> dockShadow({double elevation = 12}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: elevation,
          offset: Offset(0, elevation / 4),
        ),
      ];

  static BoxDecoration panelShell({double radius = 12}) => BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.outline),
        boxShadow: dockShadow(elevation: 16),
      );

  /// Alias for mini-window dock chrome (legacy call sites).
  static BoxDecoration miniWindowShell({double radius = 16}) =>
      panelShell(radius: radius);

  // Typography
  static TextStyle headerTitle({bool compact = false}) => TextStyle(
        fontSize: compact ? 13 : 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle headerSubtitle({bool compact = false}) => const TextStyle(
        fontSize: 11,
        color: AppColors.textMuted,
        height: 1.2,
      );

  static TextStyle messageBody({required bool isMe, bool isTeacher = false}) => TextStyle(
        fontSize: 13,
        height: 1.4,
        color: isTeacher
            ? teacherMessageText
            : (isMe ? AppColors.textInverse : AppColors.textPrimary),
      );

  static TextStyle senderName({bool isTeacher = false}) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: isTeacher ? teacherSenderName : AppColors.textSecondary,
      );

  static TextStyle timestamp() => const TextStyle(
        fontSize: 10,
        color: AppColors.textMuted,
      );

  // Bubbles
  static Color bubbleBackground({required bool isMe, bool isTeacher = false}) {
    if (isTeacher) return isMe ? bubbleTeacherSent : bubbleTeacherReceived;
    return isMe ? bubbleSent : bubbleReceived;
  }

  static BoxDecoration bubbleDecoration({
    required bool isMe,
    required bool isTail,
    bool isTeacher = false,
  }) =>
      BoxDecoration(
        color: bubbleBackground(isMe: isMe, isTeacher: isTeacher),
        borderRadius: bubbleBorderRadius(isMe: isMe, isTail: isTail),
        border: isTeacher
            ? Border.all(color: teacherRingMid.withValues(alpha: 0.55))
            : (isMe ? null : Border.all(color: AppColors.outline.withValues(alpha: 0.55))),
      );

  static BorderRadius bubbleBorderRadius({required bool isMe, required bool isTail}) {
    if (isMe) {
      return BorderRadius.only(
        topLeft: const Radius.circular(bubbleRadius),
        topRight: const Radius.circular(bubbleRadius),
        bottomLeft: const Radius.circular(bubbleRadius),
        bottomRight: Radius.circular(isTail ? bubbleRadiusTail : bubbleRadius),
      );
    }
    return BorderRadius.only(
      topLeft: const Radius.circular(bubbleRadius),
      topRight: const Radius.circular(bubbleRadius),
      bottomLeft: Radius.circular(isTail ? bubbleRadiusTail : bubbleRadius),
      bottomRight: const Radius.circular(bubbleRadius),
    );
  }

  // Composer
  static BoxDecoration inputBarSurface() => const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(top: BorderSide(color: AppColors.outline)),
      );

  /// Outer pill shell around the composer [TextField].
  static BoxDecoration composerField({required bool compact}) => BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      );

  static InputDecoration composerDecoration({required bool compact}) => InputDecoration(
        hintText: 'Nhắn tin…',
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        filled: true,
        fillColor: AppColors.surfaceSubtle,
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 16,
          vertical: compact ? 9 : 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        isDense: true,
      );

  static InputDecoration searchFieldDecoration({required String hintText}) => InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surfaceSubtle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide.none,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      );

  /// TextField decoration when wrapped by [composerField].
  static InputDecoration composerTextDecoration({required bool compact}) =>
      composerDecoration(compact: compact).copyWith(
        filled: false,
        fillColor: Colors.transparent,
      );

  static InputDecoration textFieldDecoration({required bool compact}) =>
      composerDecoration(compact: compact);

  static EdgeInsets messageListPadding({
    required bool compact,
    bool mobile = false,
  }) =>
      EdgeInsets.fromLTRB(
        compact ? AppSpacing.s3 : (mobile ? AppSpacing.s3 : AppSpacing.s4),
        compact ? AppSpacing.s3 : (mobile ? AppSpacing.s2 : AppSpacing.s4),
        compact ? AppSpacing.s3 : (mobile ? AppSpacing.s3 : AppSpacing.s4),
        compact ? AppSpacing.s2 : AppSpacing.s3,
      );

  static EdgeInsets bubbleMargin({
    required bool isMe,
    required bool compact,
    required bool showSenderInfo,
    bool mobile = false,
  }) {
    if (mobile) {
      return EdgeInsets.only(
        left: isMe ? 48 : AppSpacing.s2,
        right: isMe ? AppSpacing.s2 : 48,
        top: showSenderInfo ? AppSpacing.s2 : 2,
        bottom: 2,
      );
    }
    return EdgeInsets.only(
      left: isMe ? (compact ? 52 : 64) : (compact ? AppSpacing.s2 : AppSpacing.s3),
      right: isMe ? (compact ? AppSpacing.s2 : AppSpacing.s3) : (compact ? 52 : 64),
      top: showSenderInfo ? AppSpacing.s3 : AppSpacing.s1,
      bottom: AppSpacing.s1,
    );
  }

  /// Stable avatar tint from group name — Telegram-style identity (`23` §3.3).
  static ({Color background, Color foreground}) groupAvatarColors(String name) {
    const palette = <({Color background, Color foreground})>[
      (background: AppColors.infoBg, foreground: AppColors.info),
      (background: AppColors.successBg, foreground: AppColors.successDark),
      (background: AppColors.accentTint, foreground: AppColors.accentDark),
      (background: AppColors.primaryTint, foreground: AppColors.primaryDark),
      (background: AppColors.dangerBg, foreground: AppColors.danger),
      (background: AppColors.warningBg, foreground: AppColors.warning),
      (background: AppColors.surfaceSubtle, foreground: AppColors.textSecondary),
      (background: AppColors.dangerBg, foreground: AppColors.textPrimary),
    ];
    final trimmed = name.trim();
    var hash = 0;
    for (final codeUnit in trimmed.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7FFFFFFF;
    }
    return palette[hash % palette.length];
  }
}
