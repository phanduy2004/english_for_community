import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/feature/classroom_chat/dock/classroom_chat_dock_models.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/chat_group_cover_avatar.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_room_tile.dart';
import 'package:flutter/material.dart';

/// Thẻ hội thoại lớp — tab Tin nhắn (Messenger-clean).
class StudentMessengerConversationTile extends StatelessWidget {
  const StudentMessengerConversationTile({
    super.key,
    required this.room,
    required this.onTap,
  });

  final ClassroomChatRoomItem room;
  final VoidCallback onTap;

  static const SkillType _skill = SkillType.speaking;

  @override
  Widget build(BuildContext context) {
    final hasUnread = room.hasUnread;
    final previewBody = ClassroomChatRoomSubtitle.previewBody(room);
    final preview = previewBody.isNotEmpty
        ? previewBody
        : ClassroomChatRoomSubtitle.fallbackSubtitle(room);
    final time = ClassroomChatRoomSubtitle.timeLabel(room);
    final accent = AppSkillColors.of(_skill).color;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s2),
      child: Material(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ConversationAvatar(
                    coverImageUrl: room.coverImageUrl,
                    name: room.name,
                    hasUnread: hasUnread,
                  ),
                  const SizedBox(width: AppSpacing.s3),
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
                                style: StudentMobileUi.cardTitle(context).copyWith(
                                  fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                                ),
                              ),
                            ),
                            if (time != null) ...[
                              const SizedBox(width: AppSpacing.s2),
                              Text(
                                time,
                                style: StudentMobileUi.caption(context).copyWith(
                                  color: hasUnread ? accent : AppColors.textMuted,
                                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                preview,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: StudentMobileUi.body(context).copyWith(
                                  color: hasUnread ? AppColors.textPrimary : AppColors.textMuted,
                                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (hasUnread) ...[
                              const SizedBox(width: AppSpacing.s2),
                              _UnreadPill(count: room.unreadCount, color: accent),
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
      ),
    );
  }
}

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({
    required this.coverImageUrl,
    required this.name,
    required this.hasUnread,
  });

  final String? coverImageUrl;
  final String name;
  final bool hasUnread;

  static const double _size = 48;

  @override
  Widget build(BuildContext context) {
    final accent = AppSkillColors.speaking.color;

    return Container(
      width: _size + 4,
      height: _size + 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: hasUnread ? accent : AppColors.outline.withValues(alpha: 0.5),
          width: hasUnread ? 2 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: ChatGroupCoverAvatar(
        coverImageUrl: coverImageUrl,
        radius: _size / 2,
        backgroundColor: AppSkillColors.speaking.tint,
        fallbackIconColor: AppSkillColors.speaking.dark,
        fallbackIconSize: 17,
        groupName: name,
        useInitialsFallback: true,
      ),
    );
  }
}

class _UnreadPill extends StatelessWidget {
  const _UnreadPill({required this.count, required this.color});

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
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}
