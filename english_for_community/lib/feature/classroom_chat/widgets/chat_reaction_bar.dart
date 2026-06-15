import 'package:english_for_community/core/entity/classroom_chat_entity.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_ui.dart';
import 'package:flutter/material.dart';

class ChatReactionBar extends StatelessWidget {
  const ChatReactionBar({
    super.key,
    required this.reactions,
    required this.currentUserId,
    required this.onTap,
    this.isMe = false,
  });

  final List<ChatReaction> reactions;
  final String currentUserId;
  final void Function(String emoji) onTap;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final items = reactions.where((r) => r.count > 0).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: items.map((r) {
        final reacted = r.userIds.contains(currentUserId);
        return GestureDetector(
          onTap: () => onTap(r.emoji),
          child: AnimatedContainer(
            duration: ClassroomChatUi.hoverFade,
            curve: ClassroomChatUi.hoverCurve,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: reacted ? AppColors.primary : AppColors.outline,
                width: reacted ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClassroomChatUi.reactionGlyph(r.emoji),
                const SizedBox(width: 3),
                Text(
                  '${r.count}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: reacted ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
