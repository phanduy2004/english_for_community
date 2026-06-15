import 'package:english_for_community/core/entity/classroom_chat_entity.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:flutter/material.dart';

/// Banner tin ghim phía trên danh sách tin nhắn.
class ChatPinnedBanner extends StatelessWidget {
  const ChatPinnedBanner({
    super.key,
    required this.message,
    required this.onTap,
    this.compact = false,
    this.onUnpin,
  });

  final ClassroomChatMessage message;
  final VoidCallback onTap;
  final bool compact;
  final VoidCallback? onUnpin;

  @override
  Widget build(BuildContext context) {
    final sender = message.sender?.fullName ?? 'Thành viên';
    final preview = classroomChatMessagePreview(message);

    return Material(
      color: AppColors.surfaceCard,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 8 : 10,
          ),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.outlineMuted)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.push_pin,
                size: compact ? 16 : 18,
                color: AppColors.primary,
              ),
              SizedBox(width: compact ? 8 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tin ghim · $sender',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onUnpin != null)
                IconButton(
                  onPressed: onUnpin,
                  tooltip: 'Bỏ ghim',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close, size: compact ? 16 : 18, color: AppColors.textMuted),
                )
              else
                Icon(Icons.chevron_right, size: compact ? 18 : 20, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
