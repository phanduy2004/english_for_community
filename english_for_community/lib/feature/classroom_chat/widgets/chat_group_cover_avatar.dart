import 'package:cached_network_image/cached_network_image.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/avatar_url.dart';
import 'package:flutter/material.dart';

/// Ảnh đại diện nhóm chat lớp — dùng chung cho list, header, settings.
class ChatGroupCoverAvatar extends StatelessWidget {
  const ChatGroupCoverAvatar({
    super.key,
    this.coverImageUrl,
    required this.radius,
    this.backgroundColor,
    this.fallbackIcon = Icons.groups_outlined,
    this.fallbackIconColor,
    this.fallbackIconSize,
    this.groupName,
    this.useInitialsFallback = false,
  });

  final String? coverImageUrl;
  final double radius;
  final Color? backgroundColor;
  final IconData fallbackIcon;
  final Color? fallbackIconColor;
  final double? fallbackIconSize;
  final String? groupName;
  final bool useInitialsFallback;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final iconSize = fallbackIconSize ?? (radius * 0.9).clamp(16.0, 32.0);
    final bg = backgroundColor ?? AppColors.primaryTint;
    final iconColor = fallbackIconColor ?? AppColors.primary;
    final url = coverImageUrl?.trim() ?? '';

    Widget fallback() {
      if (useInitialsFallback) {
        return Text(
          avatarInitials(groupName, fallback: 'G'),
          style: TextStyle(
            fontSize: iconSize * 0.75,
            fontWeight: FontWeight.w700,
            color: iconColor,
          ),
        );
      }
      return Icon(fallbackIcon, size: iconSize, color: iconColor);
    }

    if (url.isNotEmpty && isUsableAvatarUrl(url)) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: ClipOval(
          child: CachedNetworkImage(
            key: ValueKey(url),
            imageUrl: url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (_, __) => fallback(),
            errorWidget: (_, __, ___) => fallback(),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: fallback(),
    );
  }
}
