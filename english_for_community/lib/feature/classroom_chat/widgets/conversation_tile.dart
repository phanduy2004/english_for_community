import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/ui/widget/app_skeleton.dart';
import 'package:english_for_community/feature/classroom_chat/dock/classroom_chat_dock_models.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/chat_group_cover_avatar.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_room_tile.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_ui.dart';
import 'package:flutter/material.dart';

/// Density variant for shared conversation list rows (`docs/ui-ux-system/23`).
enum ConversationTileDensity { mobile, web }

/// Messenger-clean conversation row — web dock + mobile hub.
class ConversationTile extends StatefulWidget {
  const ConversationTile({
    super.key,
    required this.room,
    required this.onTap,
    this.isActive = false,
    this.density = ConversationTileDensity.mobile,
  });

  final ClassroomChatRoomItem room;
  final VoidCallback onTap;
  final bool isActive;
  final ConversationTileDensity density;

  static double dividerIndent(ConversationTileDensity density) {
    return switch (density) {
      ConversationTileDensity.mobile =>
        StudentMobileUi.pageHPadding + 48 + AppSpacing.s3,
      ConversationTileDensity.web => AppSpacing.s3 + 40 + AppSpacing.s3,
    };
  }

  @override
  State<ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<ConversationTile> {
  bool _pressed = false;

  bool get _isWeb => widget.density == ConversationTileDensity.web;

  double get _rowHeight => _isWeb ? 58 : 72;

  double get _avatarRadius => _isWeb ? 20 : 24;

  double get _horizontalPadding =>
      _isWeb ? AppSpacing.s3 : AppSpacing.s4;

  double get _titleSize => _isWeb ? 14 : 15;

  double get _previewSize => 13;

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final hasUnread = room.hasUnread;
    final isActive = widget.isActive && _isWeb;
    final preview = ClassroomChatRoomSubtitle.previewText(room);
    final time = ClassroomChatRoomSubtitle.timeLabel(room);
    final avatarColors = ClassroomChatUi.groupAvatarColors(room.name);

    Color rowBg = Colors.transparent;
    if (isActive) {
      rowBg = AppColors.primaryTint;
    } else if (_pressed && !_isWeb) {
      rowBg = AppColors.pressOverlay;
    }

    final titleStyle = TextStyle(
      fontSize: _titleSize,
      fontWeight: hasUnread || isActive ? FontWeight.w700 : FontWeight.w600,
      color: isActive ? AppColors.primary : AppColors.textPrimary,
    );

    final previewStyle = TextStyle(
      fontSize: _previewSize,
      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
      color: hasUnread ? AppColors.textPrimary : AppColors.textMuted,
    );

    final timeStyle = TextStyle(
      fontSize: 12,
      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
      color: hasUnread ? AppColors.primary : AppColors.textMuted,
    );

    Widget row = Material(
      color: rowBg,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: _isWeb ? null : (v) => setState(() => _pressed = v),
        hoverColor: _isWeb ? AppColors.surfaceSubtle : null,
        splashColor: AppColors.pressOverlay,
        highlightColor: AppColors.pressOverlay,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: _rowHeight),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _horizontalPadding,
              vertical: _isWeb ? AppSpacing.s2 : AppSpacing.s3,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ChatGroupCoverAvatar(
                  coverImageUrl: room.coverImageUrl,
                  radius: _avatarRadius,
                  backgroundColor: avatarColors.background,
                  fallbackIconColor: avatarColors.foreground,
                  fallbackIconSize: _avatarRadius * 0.7,
                  groupName: room.name,
                  useInitialsFallback: true,
                ),
                SizedBox(width: _isWeb ? AppSpacing.s3 : AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              room.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: titleStyle,
                            ),
                          ),
                          if (time != null) ...[
                            SizedBox(width: AppSpacing.s2),
                            Text(time, style: timeStyle),
                          ],
                        ],
                      ),
                      SizedBox(height: _isWeb ? AppSpacing.s1 : AppSpacing.s2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: previewStyle,
                            ),
                          ),
                          if (hasUnread) ...[
                            SizedBox(width: AppSpacing.s2),
                            _UnreadBadge(count: room.unreadCount),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isActive) {
      row = DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.primary, width: 3),
          ),
        ),
        child: row,
      );
    }

    return row;
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: AppColors.textInverse,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

/// Skeleton row matching [ConversationTile] layout.
class ConversationTileSkeleton extends StatelessWidget {
  const ConversationTileSkeleton({
    super.key,
    this.density = ConversationTileDensity.mobile,
  });

  final ConversationTileDensity density;

  @override
  Widget build(BuildContext context) {
    final isWeb = density == ConversationTileDensity.web;
    final avatarSize = isWeb ? 40.0 : 48.0;
    final rowHeight = isWeb ? 58.0 : 72.0;
    final horizontal = isWeb ? AppSpacing.s3 : AppSpacing.s4;

    return SizedBox(
      height: rowHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        child: Row(
          children: [
            AppSkeleton.box(
              height: avatarSize,
              width: avatarSize,
              borderRadius: BorderRadius.circular(avatarSize / 2),
            ),
            SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeleton.box(height: 14, width: 160),
                  SizedBox(height: AppSpacing.s2),
                  AppSkeleton.box(height: 12, width: double.infinity),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
