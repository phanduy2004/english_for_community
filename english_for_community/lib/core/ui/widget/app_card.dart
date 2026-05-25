import 'package:flutter/material.dart';
import 'package:english_for_community/core/theme/app_color.dart';

enum AppCardVariant { elevated, filled, outline, danger }

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.variant = AppCardVariant.outline,
    this.radius = 12,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final AppCardVariant variant;
  final double radius;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Border? border;
    List<BoxShadow>? boxShadow;

    switch (variant) {
      case AppCardVariant.elevated:
        bg = AppColors.surfaceCard;
        border = Border.all(color: AppColors.outline, width: 1);
        boxShadow = const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ];
        break;
      case AppCardVariant.filled:
        bg = AppColors.surfaceSubtle;
        boxShadow = null;
        break;
      case AppCardVariant.outline:
        bg = AppColors.surfaceCard;
        border = Border.all(color: AppColors.outline, width: 1);
        boxShadow = null;
        break;
      case AppCardVariant.danger:
        bg = AppColors.dangerBg;
        border = Border.all(color: AppColors.danger);
        boxShadow = null;
        break;
    }

    final content = Padding(padding: padding, child: child);

    Widget cardCore = DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: boxShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: onTap == null
            ? content
            : InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          child: content,
        ),
      ),
    );

    if (margin != null) {
      cardCore = Padding(padding: margin!, child: cardCore);
    }

    return cardCore;
  }
}
