import 'package:flutter/material.dart';

/// Thẻ / ô bấm: scale nhẹ khi highlight + ripple Material — micro-interaction mượt.
class ScalePressable extends StatefulWidget {
  const ScalePressable({
    super.key,
    required this.child,
    this.onTap,
    this.minScale = 0.98,
    this.duration = const Duration(milliseconds: 140),
    this.borderRadius,
    this.padding = EdgeInsets.zero,
    this.backgroundColor,
    this.splashColor,
    this.highlightColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double minScale;
  final Duration duration;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? splashColor;
  final Color? highlightColor;

  @override
  State<ScalePressable> createState() => _ScalePressableState();
}

class _ScalePressableState extends State<ScalePressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(14);
    return AnimatedScale(
      scale: _pressed ? widget.minScale : 1.0,
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      child: Material(
        color: widget.backgroundColor ?? Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: radius,
          splashColor: widget.splashColor,
          highlightColor: widget.highlightColor,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          child: Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
