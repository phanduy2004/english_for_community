import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/classroom_chat/dock/classroom_chat_dock_models.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClassroomChatRoomSubtitle {
  ClassroomChatRoomSubtitle._();

  /// Preview line only — time is shown separately in [ConversationTile].
  static String previewText(ClassroomChatRoomItem room) {
    final body = previewBody(room);
    if (body.isNotEmpty) return body;
    return fallbackSubtitle(room);
  }

  static String previewBody(ClassroomChatRoomItem room) {
    final preview = room.lastMessagePreview;
    if (preview != null && preview.isNotEmpty) {
      final sender = _shortName(room.lastSenderName);
      return sender.isNotEmpty ? '$sender: $preview' : preview;
    }
    return '';
  }

  static String? timeLabel(ClassroomChatRoomItem room) {
    if (room.lastMessageAt == null) return null;
    return formatListTime(room.lastMessageAt!);
  }

  static String fallbackSubtitle(ClassroomChatRoomItem room) {
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
