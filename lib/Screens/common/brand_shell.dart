import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable screen shell to keep all pages visually consistent:
/// - Gradient + soft blobs background
/// - Transparent AppBar with bold title
/// - SafeArea wrapping
class BrandScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? floating;

  const BrandScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottom,
    this.floating,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _AppBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: actions,
            bottom: bottom,
          ),
          body: SafeArea(child: body),
          floatingActionButton: floating,
        ),
      ],
    );
  }
}

/// Soft gradient background with subtle blobs
class _AppBackground extends StatelessWidget {
  const _AppBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // main gradient
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF0f172a), Color(0xFF111827)],
            ),
          ),
          child: SizedBox.expand(),
        ),
        // top-left blob
        _Blob(
          left: -80, top: -60, size: 220,
          colors: const [Color(0xFFfb7185), Color(0xFFf59e0b)],
        ),
        // bottom-right blob
        _Blob(
          right: -70, bottom: -50, size: 260,
          colors: const [Color(0xFF7c3aed), Color(0xFF0ea5e9)],
        ),
        // bottom glow
        Align(
          alignment: Alignment.bottomCenter,
          child: IgnorePointer(
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [(isDark ? Colors.black : Colors.white).withOpacity(0.12), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final List<Color> colors;
  final double? left, top, right, bottom;

  const _Blob({
    required this.size,
    required this.colors,
    this.left, this.top, this.right, this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left, top: top, right: right, bottom: bottom,
      child: IgnorePointer(
        child: Container(
          height: size, width: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: colors.map((c) => c.withOpacity(0.45)).toList(),
            ),
            boxShadow: [
              BoxShadow(color: colors.first.withOpacity(0.2), blurRadius: 80, spreadRadius: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Frosted glass-like container used for controls/status bars, etc.
class FrostedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  const FrostedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: c.surface.withOpacity(0.15),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
