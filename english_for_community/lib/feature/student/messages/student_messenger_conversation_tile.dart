import 'package:cached_network_image/cached_network_image.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/classroom_chat/dock/classroom_chat_dock_models.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/chat_avatar.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_room_tile.dart';
import 'package:flutter/material.dart';

/// Một dòng hội thoại kiểu Messenger — tab Tin nhắn học sinh.
class StudentMessengerConversationTile extends StatefulWidget {
  const StudentMessengerConversationTile({
    super.key,
    required this.room,
    required this.onTap,
  });

  final ClassroomChatRoomItem room;
  final VoidCallback onTap;

  static const double avatarRadius = 28;

  @override
  State<StudentMessengerConversationTile> createState() =>
      _StudentMessengerConversationTileState();
}

class _StudentMessengerConversationTileState
    extends State<StudentMessengerConversationTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final hasUnread = room.hasUnread;
    final preview = ClassroomChatRoomSubtitle.build(room);

    return Material(
      color: _pressed ? AppColors.surfaceSubtle : Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (v) => setState(() => _pressed = v),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ConversationAvatar(
                coverImageUrl: room.coverImageUrl,
                name: room.name,
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                        color: hasUnread ? AppColors.textSecondary : AppColors.textMuted,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasUnread) ...[
                const SizedBox(width: AppSpacing.s2),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({
    required this.coverImageUrl,
    required this.name,
  });

  final String? coverImageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    const radius = StudentMessengerConversationTile.avatarRadius;
    final size = radius * 2;
    final url = coverImageUrl?.trim() ?? '';

    Widget child;
    if (url.isNotEmpty && isUsableAvatarUrl(url)) {
      child = ClipOval(
        child: CachedNetworkImage(
          key: ValueKey(url),
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _fallback(radius),
          errorWidget: (_, __, ___) => _fallback(radius),
        ),
      );
    } else {
      child = _fallback(radius);
    }

    return SizedBox(width: size, height: size, child: child);
  }

  Widget _fallback(double radius) {
    final initial = avatarInitials(name, fallback: 'G');
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryTint,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

/// Chip lọc kiểu Messenger (All / Unread).
class StudentChatHubFilterChip extends StatelessWidget {
  const StudentChatHubFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surfaceSubtle,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.textInverse : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
