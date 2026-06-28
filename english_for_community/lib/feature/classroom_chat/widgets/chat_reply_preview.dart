import 'package:english_for_community/core/entity/classroom_chat_entity.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_ui.dart';
import 'package:flutter/material.dart';

/// Preview tin trích dẫn — trong bubble hoặc input bar.
class ChatReplyPreview extends StatelessWidget {
  const ChatReplyPreview({
    super.key,
    required this.snapshot,
    required this.isMe,
    this.onDismiss,
    this.inInputBar = false,
    this.embeddedInBubble = false,
    this.isTeacherBubble = false,
  });

  final ChatReplySnapshot snapshot;
  final bool isMe;
  final VoidCallback? onDismiss;
  final bool inInputBar;
  final bool embeddedInBubble;
  /// Bubble ngoài đang dùng palette giáo viên (vàng kem).
  final bool isTeacherBubble;

  @override
  Widget build(BuildContext context) {
    if (inInputBar) return _InputBarPreview(snapshot: snapshot, onDismiss: onDismiss);
    if (embeddedInBubble) {
      return _EmbeddedPreview(
        snapshot: snapshot,
        isMe: isMe,
        isTeacherBubble: isTeacherBubble,
      );
    }
    return _StandalonePreview(snapshot: snapshot);
  }
}

class _InputBarPreview extends StatelessWidget {
  const _InputBarPreview({required this.snapshot, this.onDismiss});
  final ChatReplySnapshot snapshot;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(child: _QuoteContent(snapshot: snapshot)),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: AppColors.textMuted,
              onPressed: onDismiss,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ],
      ),
    );
  }
}

class _EmbeddedPreview extends StatelessWidget {
  const _EmbeddedPreview({
    required this.snapshot,
    required this.isMe,
    required this.isTeacherBubble,
  });
  final ChatReplySnapshot snapshot;
  final bool isMe;
  final bool isTeacherBubble;

  BoxDecoration _decoration() {
    if (isTeacherBubble) {
      return BoxDecoration(
        color: ClassroomChatUi.teacherRingMid.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: ClassroomChatUi.teacherRingDark, width: 3),
        ),
      );
    }
    if (isMe) {
      // Tin gửi (xanh): inset tối hơn bubble — chữ trắng dễ đọc (Messenger-style).
      return BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: Colors.white, width: 3),
        ),
      );
    }
    // Tin nhận (xám): inset sáng — chữ tối.
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(10),
      border: const Border(
        left: BorderSide(color: ClassroomChatUi.bubbleSentDark, width: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: _decoration(),
        child: _QuoteContent(
          snapshot: snapshot,
          inBubble: true,
          bubbleIsMe: isMe,
          isTeacherBubble: isTeacherBubble,
        ),
      ),
    );
  }
}

class _StandalonePreview extends StatelessWidget {
  const _StandalonePreview({required this.snapshot});
  final ChatReplySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 3),
        ),
      ),
      child: _QuoteContent(snapshot: snapshot),
    );
  }
}

class _QuoteContent extends StatelessWidget {
  const _QuoteContent({
    required this.snapshot,
    this.inBubble = false,
    this.bubbleIsMe = true,
    this.isTeacherBubble = false,
  });

  final ChatReplySnapshot snapshot;
  final bool inBubble;
  final bool bubbleIsMe;
  final bool isTeacherBubble;

  @override
  Widget build(BuildContext context) {
    final Color nameColor;
    final Color textColor;

    if (inBubble && isTeacherBubble) {
      nameColor = ClassroomChatUi.teacherRingDark;
      textColor = ClassroomChatUi.teacherMessageText;
    } else if (inBubble && !bubbleIsMe) {
      nameColor = ClassroomChatUi.bubbleSentDark;
      textColor = AppColors.textPrimary;
    } else if (inBubble) {
      nameColor = Colors.white;
      textColor = Colors.white.withValues(alpha: 0.92);
    } else {
      nameColor = AppColors.primary;
      textColor = AppColors.textSecondary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          snapshot.senderName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: nameColor,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          snapshot.contentPreview,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
