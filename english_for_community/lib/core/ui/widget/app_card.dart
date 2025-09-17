import 'package:flutter/material.dart';

enum AppCardVariant { elevated, filled, outline, danger }

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.variant = AppCardVariant.elevated,
    this.radius = 16,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final AppCardVariant variant;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Màu nền & viền theo biến thể
    Color bg;
    Border? border;
    List<BoxShadow>? boxShadow;

    switch (variant) {
      case AppCardVariant.elevated:
        bg = Theme.of(context).cardColor; // gần giống Home
        boxShadow = const [
          BoxShadow(
            blurRadius: 8,
            color: Color(0x1A000000),
            offset: Offset(0, 2),
          ),
        ];
        break;
      case AppCardVariant.filled:
        bg = scheme.surface;
        boxShadow = null;
        break;
      case AppCardVariant.outline:
        bg = scheme.surface;
        border = Border.all(color: scheme.outlineVariant);
        boxShadow = null;
        break;
      case AppCardVariant.danger:
        bg = scheme.errorContainer;
        border = Border.all(color: scheme.error);
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
