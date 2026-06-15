import 'package:cached_network_image/cached_network_image.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/feature/classroom_chat/widgets/classroom_chat_ui.dart';
import 'package:flutter/material.dart';

/// GitHub profile URLs (e.g. github.com/shadcn.png) serve HTML, not image bytes.
bool isUsableAvatarUrl(String? url) {
  if (url == null || url.trim().isEmpty) return false;
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.hasScheme) return false;
  final host = uri.host.toLowerCase();
  if (host == 'github.com' || host == 'www.github.com') return false;
  return true;
}

String avatarInitials(String? name, {String fallback = '?'}) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) return fallback;
  return trimmed[0].toUpperCase();
}

/// Avatar with network load + fallback initials (no decode crash).
class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    this.avatarUrl,
    required this.displayName,
    this.radius = 16,
    this.fontSize,
    this.teacherHighlight = false,
  });

  final String? avatarUrl;
  final String displayName;
  final double radius;
  final double? fontSize;
  /// Viền vàng ánh kim — tin nhắn từ giáo viên / GV phụ.
  final bool teacherHighlight;

  @override
  Widget build(BuildContext context) {
    final initials = avatarInitials(displayName);
    final size = radius * 2;
    final textSize = fontSize ?? (radius * 0.75).clamp(10, 14);

    final Widget core;
    if (!isUsableAvatarUrl(avatarUrl)) {
      core = _initialsCircle(initials, textSize);
    } else {
      core = ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl!.trim(),
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _initialsCircle(initials, textSize),
          errorWidget: (_, __, ___) => _initialsCircle(initials, textSize),
        ),
      );
    }

    if (!teacherHighlight) return core;
    return ClassroomChatUi.teacherAvatarRing(radius: radius, child: core);
  }

  Widget _initialsCircle(String initials, double textSize) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryTint,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: textSize,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}
