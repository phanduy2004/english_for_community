import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/classroom_chat/dock/classroom_chat_dock_models.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Một dòng trong danh sách nhóm chat lớp (teacher panel + student hub).
class ClassroomChatRoomTile extends StatefulWidget {
  const ClassroomChatRoomTile({
    super.key,
    required this.room,
    required this.onTap,
    this.isActive = false,
    this.compact = false,
  });

  final ClassroomChatRoomItem room;
  final VoidCallback onTap;
  final bool isActive;
  final bool compact;

  @override
  State<ClassroomChatRoomTile> createState() => _ClassroomChatRoomTileState();
}

class _ClassroomChatRoomTileState extends State<ClassroomChatRoomTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final hasUnread = room.hasUnread;
    final bg = widget.isActive
        ? AppColors.primaryTint
        : hasUnread
            ? AppColors.primaryTint.withValues(alpha: 0.45)
            : (_pressed ? AppColors.primaryStrong : Colors.transparent);

    return Material(
      color: bg,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (v) => setState(() => _pressed = v),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? AppSpacing.s3 : AppSpacing.s4,
            vertical: widget.compact ? 10 : 12,
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: widget.compact ? 20 : 22,
                    backgroundColor: widget.isActive
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.primaryTint,
                    child: Icon(
                      Icons.groups_outlined,
                      color: widget.isActive ? AppColors.primary : AppColors.textSecondary,
                      size: widget.compact ? 20 : 22,
                    ),
                  ),
                  if (widget.isActive)
                    Positioned(
                      right: -2,
                      bottom: -2,
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
              SizedBox(width: widget.compact ? AppSpacing.s2 : AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                        fontSize: widget.compact ? 13 : 14,
                        color: widget.isActive ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ClassroomChatRoomSubtitle.build(room),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                        color: hasUnread ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasUnread)
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    room.unreadCount > 99 ? '99+' : '${room.unreadCount}',
                    style: const TextStyle(
                      color: AppColors.textInverse,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: widget.isActive ? AppColors.primary : AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClassroomChatRoomSubtitle {
  ClassroomChatRoomSubtitle._();

  static String build(ClassroomChatRoomItem room) {
    final preview = room.lastMessagePreview;
    if (preview != null && preview.isNotEmpty) {
      final sender = _shortName(room.lastSenderName);
      final time = room.lastMessageAt != null ? formatListTime(room.lastMessageAt!) : '';
      final body = sender.isNotEmpty ? '$sender: $preview' : preview;
      return time.isNotEmpty ? '$body · $time' : body;
    }
    final count = room.memberCount;
    if (count != null) return '$count thành viên';
    return 'Nhóm lớp học';
  }

  static String _shortName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '';
    return fullName.trim().split(RegExp(r'\s+')).first;
  }

  static String formatListTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}g';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('dd/MM').format(local);
  }
}

class ClassroomChatRoomListEmpty extends StatelessWidget {
  const ClassroomChatRoomListEmpty({
    super.key,
    required this.hasQuery,
    this.compact = false,
  });

  final bool hasQuery;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(compact ? AppSpacing.s5 : AppSpacing.s6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasQuery ? Icons.search_off_outlined : Icons.groups_outlined,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            hasQuery ? 'Không tìm thấy lớp' : 'Chưa có lớp học',
            style: ClassroomChatUi.headerTitle().copyWith(fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            hasQuery
                ? 'Thử từ khóa khác hoặc xóa bộ lọc.'
                : 'Các lớp bạn tham gia sẽ hiện ở đây.',
            textAlign: TextAlign.center,
            style: ClassroomChatUi.headerSubtitle(),
          ),
        ],
      ),
    );
  }
}

class ClassroomChatRoomListError extends StatelessWidget {
  const ClassroomChatRoomListError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.textMuted, size: 32),
          const SizedBox(height: AppSpacing.s3),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.s3),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
