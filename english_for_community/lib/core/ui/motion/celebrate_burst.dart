import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_color.dart';
import '../../util/app_haptics.dart';

/// Overlay ăn mừng gamification — `docs/ui-ux-system/20` §5.3.
class CelebrateBurst extends StatefulWidget {  const CelebrateBurst({
    super.key,
    required this.child,
    this.trigger = false,
    this.onComplete,
  });

  final Widget child;
  final bool trigger;
  final VoidCallback? onComplete;

  @override
  State<CelebrateBurst> createState() => _CelebrateBurstState();
}

class _CelebrateBurstState extends State<CelebrateBurst> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _wasTriggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(CelebrateBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !_wasTriggered) {
      _wasTriggered = true;
      _play();
    }
    if (!widget.trigger) {
      _wasTriggered = false;
    }
  }

  Future<void> _play() async {
    final duration = AppHaptics.celebrateDuration(context);
    _controller.duration = duration;
    AppHaptics.celebrate(context);
    await _controller.forward(from: 0);
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (_controller.value == 0) return const SizedBox.shrink();
                return CustomPaint(
                  painter: _BurstPainter(progress: Curves.easeOut.transform(_controller.value)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.35);
    final paint = Paint()..style = PaintingStyle.fill;
    const colors = [AppColors.accent, AppColors.accentDark, AppColors.warning, AppColors.success];
    final random = math.Random(42);
    for (var i = 0; i < 18; i++) {
      final angle = (i / 18) * math.pi * 2 + random.nextDouble() * 0.4;
      final dist = 40 + progress * (80 + random.nextDouble() * 60);
      final x = center.dx + math.cos(angle) * dist;
      final y = center.dy + math.sin(angle) * dist;
      paint.color = colors[i % colors.length].withValues(alpha: (1 - progress).clamp(0.0, 1.0));
      final r = 4 + random.nextDouble() * 5 * (1 - progress * 0.5);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
    if (progress < 0.85) {
      paint.color = AppColors.accent.withValues(alpha: (0.25 * (1 - progress)).clamp(0.0, 0.25));
      canvas.drawCircle(center, 28 + progress * 36, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) => oldDelegate.progress != progress;
}

/// Bắt mốc streak/level tăng (và daily goal đạt) → kích hoạt [CelebrateBurst] — `20` §5.3.
class GamificationCelebrateHost extends StatefulWidget {
  const GamificationCelebrateHost({
    super.key,
    required this.child,
    this.streak,
    this.level,
    this.dailyGoalReached,
  });

  final Widget child;
  final int? streak;
  final int? level;

  /// True khi học sinh vừa hoàn thành mục tiêu ngày. Burst chỉ bắn ở nhịp
  /// chuyển false→true (không bắn lại khi mở lại màn lúc đã đạt sẵn).
  final bool? dailyGoalReached;

  @override
  State<GamificationCelebrateHost> createState() => _GamificationCelebrateHostState();
}

class _GamificationCelebrateHostState extends State<GamificationCelebrateHost> {
  int? _lastStreak;
  int? _lastLevel;
  bool? _lastGoalReached;
  bool _trigger = false;

  @override
  void initState() {
    super.initState();
    _lastStreak = widget.streak;
    _lastLevel = widget.level;
    _lastGoalReached = widget.dailyGoalReached;
  }

  @override
  void didUpdateWidget(GamificationCelebrateHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    final s = widget.streak;
    final l = widget.level;
    final g = widget.dailyGoalReached;
    if (s != null && _lastStreak != null && s > _lastStreak! && s > 0) {
      _trigger = true;
    }
    if (l != null && _lastLevel != null && l > _lastLevel! && l > 1) {
      _trigger = true;
    }
    if (g == true && _lastGoalReached == false) {
      _trigger = true;
    }
    _lastStreak = s ?? _lastStreak;
    _lastLevel = l ?? _lastLevel;
    _lastGoalReached = g ?? _lastGoalReached;
  }

  @override
  Widget build(BuildContext context) {
    return CelebrateBurst(
      trigger: _trigger,
      onComplete: () {
        if (mounted) setState(() => _trigger = false);
      },
      child: widget.child,
    );
  }
}
