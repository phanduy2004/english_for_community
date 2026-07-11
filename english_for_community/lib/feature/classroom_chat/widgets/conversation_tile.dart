import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
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
    this.onLongPress,
    this.typingText,
    this.isActive = false,
    this.density = ConversationTileDensity.mobile,
  });

  final ClassroomChatRoomItem room;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// Tên người đang nhập → hiển thị "… đang nhập…" thay preview.
  final String? typingText;
  final bool isActive;
  final ConversationTileDensity density;

  static double dividerIndent(ConversationTileDensity density) {
    return switch (density) {
      ConversationTileDensity.mobile => AppSpacing.s4 + 48 + AppSpacing.s3,
      ConversationTileDensity.web => AppSpacing.s3 + 40 + AppSpacing.s3,
    };
  }

  @override
  State<ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<ConversationTile> {
  bool _pressed = false;

  bool get _isWeb => widget.density == ConversationTileDensity.web;

  double get _rowHeight => _isWeb ? 58 : 68;

  static const double _avatarDiameter = 40;

  double get _avatarRadius => _avatarDiameter / 2;

  /// Ô cố định giữ avatar căn đều mọi hàng — mobile chừa chỗ cho ring unread.
  double get _avatarSlot => _isWeb ? _avatarDiameter : 48;

  double get _horizontalPadding =>
      _isWeb ? AppSpacing.s3 : AppSpacing.s4;

  double get _titleSize => _isWeb ? 14 : 15;

  double get _previewSize => 13;

  /// Avatar trong slot cố định. Mobile: **ring gradient màu-định-danh** khi
  /// chưa đọc (kiểu Telegram/IG) — thêm màu + báo unread ngay; web dock giữ phẳng.
  Widget _buildAvatar(
    ClassroomChatRoomItem room,
    ({Color background, Color foreground}) colors,
    bool hasUnread,
  ) {
    final avatar = ChatGroupCoverAvatar(
      coverImageUrl: room.coverImageUrl,
      radius: _avatarRadius,
      backgroundColor: colors.background,
      fallbackIconColor: colors.foreground,
      fallbackIconSize: _avatarRadius * 0.7,
      groupName: room.name,
      useInitialsFallback: true,
    );

    Widget inner;
    if (_isWeb) {
      inner = avatar;
    } else if (!hasUnread) {
      // Đã đọc (mobile): vòng mảnh màu-định-danh — thêm màu nhẹ, không "hét".
      inner = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: colors.foreground.withValues(alpha: 0.28),
            width: 1.5,
          ),
        ),
        child: avatar,
      );
    } else {
      final ring = colors.foreground;
      inner = Container(
        width: _avatarDiameter + 8,
        height: _avatarDiameter + 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ring, Color.lerp(ring, Colors.white, 0.5)!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2.5),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceCard,
            ),
            child: Padding(
              padding: const EdgeInsets.all(1.5),
              child: avatar,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: _avatarSlot,
      height: _avatarSlot,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(child: inner),
          // Chấm online (presence thật) — báo có thành viên khác đang hoạt động.
          if (room.online)
            Positioned(
              right: _isWeb ? 0 : 2,
              bottom: 1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceCard, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final hasUnread = room.hasUnread;
    final isActive = widget.isActive && _isWeb;
    final mediaIcon = _mediaIconFor(room.lastMessageType);
    var preview = ClassroomChatRoomSubtitle.previewText(room);
    if (mediaIcon != null) preview = _stripMediaEmoji(preview);
    final time = ClassroomChatRoomSubtitle.timeLabel(room);
    final avatarColors = ClassroomChatUi.groupAvatarColors(room.name);
    // Mobile: tách "10A1 — Ca sáng · HK2" → tên + chip meta màu-định-danh
    // (thêm tí màu + dễ đọc). Web dock giữ nguyên tên đầy đủ.
    final splitName = _splitRoomName(room.name);
    final displayTitle = _isWeb ? room.name : splitName.title;
    final metaLabel = _isWeb ? null : splitName.meta;
    // Mỗi lớp một "màu unread" theo identity (ring/badge/time) — web giữ đen.
    final unreadAccent = _isWeb ? AppColors.primary : avatarColors.foreground;
    final isMuted = room.muted;
    final isPinned = room.isPinned;
    // Tắt tiếng → không nhuộm màu unread (dùng xám), không ring.
    final effectiveAccent = isMuted ? AppColors.textMuted : unreadAccent;

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
      fontSize: AppTypography.mobileCaption,
      fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
      color: hasUnread ? effectiveAccent : AppColors.textMuted,
    );

    Widget row = Material(
      color: rowBg,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onHighlightChanged: _isWeb ? null : (v) => setState(() => _pressed = v),
        hoverColor: _isWeb ? AppColors.surfaceSubtle : null,
        splashColor: AppColors.pressOverlay,
        highlightColor: AppColors.pressOverlay,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: _rowHeight),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _horizontalPadding,
              vertical: AppSpacing.s2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(room, avatarColors, hasUnread && !isMuted),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    displayTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: titleStyle,
                                  ),
                                ),
                                if (metaLabel != null) ...[
                                  const SizedBox(width: AppSpacing.s2),
                                  Flexible(
                                    child: _MetaChip(
                                      text: metaLabel,
                                      background: avatarColors.background,
                                      foreground: avatarColors.foreground,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isPinned) ...[
                            const SizedBox(width: AppSpacing.s2),
                            const Icon(
                              Icons.push_pin,
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                          ],
                          if (isMuted) ...[
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.notifications_off_rounded,
                              size: 13,
                              color: AppColors.textMuted,
                            ),
                          ],
                          if (time != null) ...[
                            SizedBox(width: AppSpacing.s2),
                            Text(time, style: timeStyle),
                          ],
                        ],
                      ),
                      SizedBox(height: AppSpacing.s1),
                      Row(
                        children: [
                          if (widget.typingText != null)
                            Expanded(
                              child: Text(
                                '${widget.typingText} đang nhập…',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: _previewSize,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                  color: unreadAccent,
                                ),
                              ),
                            )
                          else ...[
                            if (mediaIcon != null) ...[
                              Icon(
                                mediaIcon,
                                size: 14,
                                color: previewStyle.color,
                              ),
                              const SizedBox(width: 3),
                            ],
                            Expanded(
                              child: Text(
                                preview,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: previewStyle,
                              ),
                            ),
                          ],
                          if (hasUnread) ...[
                            SizedBox(width: AppSpacing.s2),
                            _UnreadBadge(
                              count: room.unreadCount,
                              color: effectiveAccent,
                            ),
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
  const _UnreadBadge({required this.count, this.color = AppColors.primary});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: AppColors.textInverse,
          fontSize: AppTypography.mobileCaption,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

/// Tách "10A1 — Ca sáng · HK2" → ("10A1", "Ca sáng · HK2"). Không có dấu ngăn
/// (— / – / -) thì trả (name, null) — an toàn với mọi định dạng tên.
({String title, String? meta}) _splitRoomName(String name) {
  final match = RegExp(r'\s[—–-]\s').firstMatch(name);
  if (match == null) return (title: name, meta: null);
  final title = name.substring(0, match.start).trim();
  final meta = name.substring(match.end).trim();
  if (title.isEmpty || meta.isEmpty) return (title: name, meta: null);
  return (title: title, meta: meta);
}

/// Chip meta màu-định-danh cạnh tên lớp (mobile) — pastel bg + chữ cùng tông,
/// dùng lại palette avatar (`ClassroomChatUi.groupAvatarColors`).
class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: TextStyle(
          fontSize: AppTypography.mobileCaption,
          fontWeight: FontWeight.w600,
          color: foreground,
          height: 1.1,
        ),
      ),
    );
  }
}

/// Icon prefix cho tin media (null nếu là text) — `docs/ui-ux-system/23` §3.6.
IconData? _mediaIconFor(String? type) {
  switch (type) {
    case 'image':
      return Icons.photo_rounded;
    case 'video':
      return Icons.videocam_rounded;
    case 'file':
      return Icons.insert_drive_file_rounded;
    default:
      return null;
  }
}

/// Bỏ emoji media khỏi preview khi đã render icon riêng — tránh trùng và đồng
/// bộ hiển thị (emoji font lệch trên Android).
String _stripMediaEmoji(String s) {
  const emojis = ['📷', '🎬', '📎', '🎞️', '🖼️', '🎥'];
  var out = s;
  for (final e in emojis) {
    out = out.replaceAll('$e ', '').replaceAll(e, '');
  }
  return out.trim();
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
    const avatarSize = 40.0;
    final slot = isWeb ? 40.0 : 48.0;
    final rowHeight = isWeb ? 58.0 : 68.0;
    final horizontal = isWeb ? AppSpacing.s3 : AppSpacing.s4;

    return SizedBox(
      height: rowHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        child: Row(
          children: [
            SizedBox(
              width: slot,
              height: slot,
              child: Center(
                child: AppSkeleton.box(
                  height: avatarSize,
                  width: avatarSize,
                  borderRadius: BorderRadius.circular(avatarSize / 2),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeleton.box(height: isWeb ? 14 : 13, width: 160),
                  SizedBox(height: AppSpacing.s1),
                  AppSkeleton.box(height: isWeb ? 12 : 11, width: double.infinity),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
