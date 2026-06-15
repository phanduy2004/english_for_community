import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'app_lottie_cache.dart';
import 'app_lottie_preset.dart';
import 'app_motion.dart';

/// Plays a bundled Lottie JSON; falls back to [fallback] if the asset is missing.
class AppLottieView extends StatefulWidget {
  const AppLottieView({
    super.key,
    required this.preset,
    this.size = AppMotion.emptyLottieSize,
    this.repeat = true,
    this.fallback,
  });

  final AppLottiePreset preset;
  final double size;
  final bool repeat;
  final Widget? fallback;

  @override
  State<AppLottieView> createState() => _AppLottieViewState();
}

class _AppLottieViewState extends State<AppLottieView> {
  LottieComposition? _composition;

  @override
  void initState() {
    super.initState();
    _composition = AppLottieCache.composition(widget.preset);
    if (_composition == null) {
      _loadComposition();
    }
  }

  @override
  void didUpdateWidget(covariant AppLottieView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preset != widget.preset) {
      _composition = AppLottieCache.composition(widget.preset);
      if (_composition == null) _loadComposition();
    }
  }

  Future<void> _loadComposition() async {
    try {
      final composition = await AppLottieCache.ensureLoaded(widget.preset);
      if (mounted) setState(() => _composition = composition);
    } catch (_) {
      if (mounted) setState(() => _composition = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final composition = _composition;
    if (composition == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: widget.fallback ?? const SizedBox.shrink(),
      );
    }

    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Lottie(
          composition: composition,
          fit: BoxFit.contain,
          repeat: widget.repeat,
          addRepaintBoundary: true,
          renderCache: RenderCache.drawingCommands,
        ),
      ),
    );
  }
}
