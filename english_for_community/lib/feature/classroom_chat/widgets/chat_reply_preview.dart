import 'package:english_for_community/core/entity/classroom_chat_entity.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
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
  });

  final ChatReplySnapshot snapshot;
  final bool isMe;
  final VoidCallback? onDismiss;
  final bool inInputBar;
  final bool embeddedInBubble;

  @override
  Widget build(BuildContext context) {
    if (inInputBar) return _InputBarPreview(snapshot: snapshot, onDismiss: onDismiss);
    if (embeddedInBubble) return _EmbeddedPreview(snapshot: snapshot, isMe: isMe);
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
  const _EmbeddedPreview({required this.snapshot, required this.isMe});
  final ChatReplySnapshot snapshot;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: isMe
            ? BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: BorderSide(
                    color: Colors.white.withValues(alpha: 0.85),
                    width: 3,
                  ),
                ),
              )
            : BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: const Border(
                  left: BorderSide(color: AppColors.primary, width: 3),
                ),
              ),
        child: _QuoteContent(snapshot: snapshot, inBubble: true, bubbleIsMe: isMe),
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
  });

  final ChatReplySnapshot snapshot;
  final bool inBubble;
  final bool bubbleIsMe;

  @override
  Widget build(BuildContext context) {
    final Color nameColor;
    final Color textColor;

    if (inBubble && !bubbleIsMe) {
      nameColor = AppColors.primary;
      textColor = AppColors.textSecondary;
    } else if (inBubble) {
      nameColor = Colors.white;
      textColor = Colors.white.withValues(alpha: 0.85);
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
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: nameColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          snapshot.contentPreview,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, height: 1.3, color: textColor),
        ),
      ],
    );
  }
}
