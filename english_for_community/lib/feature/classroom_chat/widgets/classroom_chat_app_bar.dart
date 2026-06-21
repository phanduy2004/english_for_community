import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/chat_group_cover_avatar.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_ui.dart';
import 'package:flutter/material.dart';

/// Header cửa sổ chat — full page hoặc mini window.
class ClassroomChatHeader extends StatelessWidget {
  const ClassroomChatHeader({
    super.key,
    required this.title,
    this.subtitle = 'Nhóm lớp học',
    this.compact = false,
    this.dark = false,
    this.settingsOpen = false,
    this.onTitleTap,
    this.onMinimize,
    this.onClose,
    this.leading,
    this.coverImageUrl,
    this.onCoverTap,
    this.coverUploading = false,
  });

  final String title;
  final String subtitle;
  final bool compact;
  final bool dark;
  final bool settingsOpen;
  final VoidCallback? onTitleTap;
  final VoidCallback? onMinimize;
  final VoidCallback? onClose;
  final Widget? leading;
  final String? coverImageUrl;
  final VoidCallback? onCoverTap;
  final bool coverUploading;

  @override
  Widget build(BuildContext context) {
    final height = compact ? ClassroomChatUi.headerHeightCompact : ClassroomChatUi.headerHeight;
    final bg = dark
        ? const Color(0xFF6B21A8)
        : settingsOpen
            ? AppColors.primaryTint
            : AppColors.surfaceCard;
    final borderColor = dark ? AppColors.primaryStrong : AppColors.outline;
    final titleStyle = ClassroomChatUi.headerTitle(compact: compact).copyWith(
      color: dark ? AppColors.textInverse : AppColors.textPrimary,
    );
    final subtitleStyle = ClassroomChatUi.headerSubtitle(compact: compact).copyWith(
      color: dark ? AppColors.textInverse.withValues(alpha: 0.75) : AppColors.textMuted,
    );
    final iconColor = dark ? AppColors.textInverse.withValues(alpha: 0.85) : AppColors.textSecondary;
    final avatarBg = dark ? AppColors.textInverse.withValues(alpha: 0.15) : AppColors.primaryTint;
    final avatarIconColor = dark ? AppColors.textInverse : AppColors.primary;

    return Material(
      color: bg,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: compact ? AppSpacing.s2 : AppSpacing.s3),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              SizedBox(width: compact ? AppSpacing.s1 : AppSpacing.s2),
            ],
            _buildCoverAvatar(
              radius: compact ? 15 : 17,
              backgroundColor: avatarBg,
              iconColor: avatarIconColor,
              compact: compact,
            ),
            SizedBox(width: compact ? AppSpacing.s2 : AppSpacing.s3),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTitleTap,
                  borderRadius: BorderRadius.circular(8),
                  hoverColor: dark
                      ? AppColors.textInverse.withValues(alpha: 0.08)
                      : AppColors.primaryStrong,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: titleStyle,
                              ),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: subtitleStyle,
                              ),
                            ],
                          ),
                        ),
                        if (onTitleTap != null)
                          Icon(
                            settingsOpen ? Icons.expand_less : Icons.expand_more,
                            size: 18,
                            color: iconColor,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (onMinimize != null)
              _HeaderIconButton(
                icon: Icons.remove,
                tooltip: 'Thu nhỏ',
                onPressed: onMinimize!,
                color: iconColor,
              ),
            if (onClose != null)
              _HeaderIconButton(
                icon: Icons.close,
                tooltip: 'Đóng',
                onPressed: onClose!,
                color: iconColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverAvatar({
    required double radius,
    required Color backgroundColor,
    required Color iconColor,
    required bool compact,
  }) {
    final size = radius * 2;
    final iconSize = compact ? 16.0 : 18.0;

    Widget avatar = ChatGroupCoverAvatar(
      coverImageUrl: coverImageUrl,
      radius: radius,
      backgroundColor: backgroundColor,
      fallbackIconColor: iconColor,
      fallbackIconSize: iconSize,
    );

    if (coverUploading) {
      avatar = Stack(
        alignment: Alignment.center,
        children: [
          avatar,
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
          ),
        ],
      );
    }

    if (onCoverTap == null) return avatar;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: coverUploading ? null : onCoverTap,
        customBorder: const CircleBorder(),
        child: avatar,
      ),
    );
  }
}

/// Header panel cài đặt bên trái — không trùng chrome cửa sổ chat.
class ChatSettingsPanelHeader extends StatelessWidget {
  const ChatSettingsPanelHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      child: Container(
        height: ClassroomChatUi.headerHeightCompact,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.outline)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              tooltip: 'Quay lại chat',
              color: AppColors.textSecondary,
              onPressed: onBack,
              visualDensity: VisualDensity.compact,
            ),
            const Expanded(
              child: Text(
                'Thông tin nhóm',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = AppColors.textSecondary,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      color: color,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}
