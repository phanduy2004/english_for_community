import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/utils/global_keys.dart';
import 'package:flutter/material.dart';

/// Top in-app banner for foreground realtime events (student mobile / student web).
/// Auto-dismisses; tap invokes [onTap].
class AppInAppBanner {
  AppInAppBanner._();

  static OverlayEntry? _entry;
  static String? _lastKey;
  static DateTime? _lastAt;
  static const _dedupWindow = Duration(seconds: 3);

  static void show({
    required String title,
    required String body,
    VoidCallback? onTap,
    String? dedupKey,
  }) {
    final key = dedupKey ?? '$title|$body';
    final now = DateTime.now();
    if (_lastKey == key &&
        _lastAt != null &&
        now.difference(_lastAt!) < _dedupWindow) {
      return;
    }
    _lastKey = key;
    _lastAt = now;

    hide();

    final overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _entry = OverlayEntry(
      builder: (ctx) {
        final top = MediaQuery.paddingOf(ctx).top;
        return Positioned(
          top: top + AppSpacing.s2,
          left: AppSpacing.s4,
          right: AppSpacing.s4,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(AppRadius.card),
            color: AppColors.surfaceCard,
            child: InkWell(
              onTap: () {
                hide();
                onTap?.call();
              },
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s4,
                  vertical: AppSpacing.s3,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.outline),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_outlined, size: 20, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (body.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_entry!);

    Future.delayed(const Duration(seconds: 5), hide);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}
