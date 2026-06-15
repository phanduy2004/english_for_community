import 'package:english_for_community/core/entity/classroom_chat_entity.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:flutter/material.dart';

/// Resolves a **JPEG/image** URL for video bubble previews.
/// Never returns the raw video URL — Android cannot decode video bytes as bitmap.
String? resolveChatVideoThumbnailUrl(ChatMedia media) {
  final explicit = media.thumbnailUrl?.trim();
  if (explicit != null && explicit.isNotEmpty) return explicit;

  final url = media.url.trim();
  if (url.isEmpty) return null;

  if (_isCloudinaryVideoUrl(url)) {
    return url.replaceFirst(
      '/video/upload/',
      '/video/upload/so_0,w_440,h_280,c_fill,q_auto,f_jpg/',
    );
  }

  return null;
}

bool _isCloudinaryVideoUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  return uri.host.contains('cloudinary.com') && uri.path.contains('/video/upload/');
}

Widget chatVideoThumbnailPlaceholder({
  required double width,
  required double height,
}) {
  return Container(
    width: width,
    height: height,
    color: Colors.black87,
    alignment: Alignment.center,
    child: Icon(Icons.videocam_outlined, size: 40, color: AppColors.textMuted),
  );
}
