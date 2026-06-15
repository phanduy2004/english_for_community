import 'dart:typed_data';

import 'package:english_for_community/core/entity/classroom_chat_entity.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:flutter/material.dart';

/// Vòng loading giữa thumbnail khi đang upload.
class ChatMediaUploadOverlay extends StatelessWidget {
  const ChatMediaUploadOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Thumbnail cục bộ cho ảnh/video đang chờ hoặc đang upload.
class ChatLocalMediaThumbnail extends StatelessWidget {
  const ChatLocalMediaThumbnail({
    super.key,
    required this.kind,
    this.bytes,
    this.filePath,
    this.width = 72,
    this.height = 72,
    this.borderRadius = 10,
    this.showPlayIcon = false,
    this.showUploading = false,
  });

  final ChatAttachmentKind kind;
  final Uint8List? bytes;
  final String? filePath;
  final double width;
  final double height;
  final double borderRadius;
  final bool showPlayIcon;
  final bool showUploading;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildContent(),
            if (showPlayIcon && kind == ChatAttachmentKind.video)
              Container(
                color: Colors.black.withValues(alpha: 0.28),
                alignment: Alignment.center,
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white.withValues(alpha: 0.92),
                  size: width * 0.38,
                ),
              ),
            if (showUploading) const ChatMediaUploadOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (kind == ChatAttachmentKind.image) {
      if (bytes != null && bytes!.isNotEmpty) {
        return Image.memory(
          bytes!,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.primaryTint,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
          ),
        );
      }
    }

    return Container(
      color: kind == ChatAttachmentKind.video ? Colors.black87 : AppColors.primaryTint,
      alignment: Alignment.center,
      child: Icon(
        kind == ChatAttachmentKind.video
            ? Icons.videocam_outlined
            : Icons.insert_drive_file_outlined,
        color: kind == ChatAttachmentKind.video ? Colors.white70 : AppColors.textMuted,
        size: 28,
      ),
    );
  }
}

/// Hàng preview đính kèm phía trên ô nhập (Messenger-style).
class ChatAttachmentPreviewStrip extends StatelessWidget {
  const ChatAttachmentPreviewStrip({
    super.key,
    required this.attachments,
    required this.onRemove,
    required this.onAdd,
    this.isUploading = false,
    this.compact = false,
  });

  final List<ChatPendingAttachment> attachments;
  final void Function(String id) onRemove;
  final VoidCallback onAdd;
  final bool isUploading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    final thumb = compact ? 64.0 : 72.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 12 : 16, 10, compact ? 12 : 16, 0),
      child: SizedBox(
        height: thumb,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: attachments.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index == attachments.length) {
              return _AddAttachmentTile(size: thumb, onTap: onAdd);
            }
            final item = attachments[index];
            return _StagedAttachmentTile(
              attachment: item,
              size: thumb,
              isUploading: isUploading,
              onRemove: () => onRemove(item.id),
            );
          },
        ),
      ),
    );
  }
}

class _AddAttachmentTile extends StatelessWidget {
  const _AddAttachmentTile({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceSubtle,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: size,
          height: size,
          child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _StagedAttachmentTile extends StatelessWidget {
  const _StagedAttachmentTile({
    required this.attachment,
    required this.size,
    required this.isUploading,
    required this.onRemove,
  });

  final ChatPendingAttachment attachment;
  final double size;
  final bool isUploading;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ChatLocalMediaThumbnail(
          kind: attachment.kind,
          bytes: attachment.bytes,
          filePath: attachment.filePath,
          width: size,
          height: size,
          showPlayIcon: attachment.kind == ChatAttachmentKind.video,
          showUploading: isUploading,
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Material(
            color: Colors.black87,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: isUploading ? null : onRemove,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 22,
                height: 22,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Preview trong bubble tin nhắn đang gửi.
Widget buildChatBubbleLocalMedia({
  required ChatMessageType type,
  required ChatMedia media,
  required bool isPending,
  required double width,
  required double height,
}) {
  final kind = type == ChatMessageType.video
      ? ChatAttachmentKind.video
      : type == ChatMessageType.image
          ? ChatAttachmentKind.image
          : ChatAttachmentKind.file;

  final useLocal = isPending && media.hasLocalPreview;

  if (!useLocal && media.url.isEmpty) {
    return SizedBox(
      width: width,
      height: height,
      child: const AppLoadingIndicator.center(),
    );
  }

  if (!useLocal) {
    return const SizedBox.shrink();
  }

  return ChatLocalMediaThumbnail(
    kind: kind,
    bytes: media.localPreviewBytes,
    filePath: media.localPreviewPath,
    width: width,
    height: height,
    borderRadius: 0,
    showPlayIcon: kind == ChatAttachmentKind.video && !isPending,
    showUploading: isPending,
  );
}
