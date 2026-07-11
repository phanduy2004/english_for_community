import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_color.dart';
import '../../theme/app_skill_colors.dart';
import '../../util/app_haptics.dart';

/// Cường độ ăn mừng "tung hoa" ở màn hoàn thành bài — `docs/ui-ux-system/20` §5.3.
///
/// - [gentle]  : chỉ hoàn thành (điểm chưa tốt / chưa chấm) → mưa confetti nhẹ.
/// - [festive] : điểm đạt ngưỡng tốt → bung pháo hoa 2 góc + mưa phủ.
enum CelebrationLevel { gentle, festive }

/// Confetti chúc mừng hoàn thành bài tập kỹ năng / bài thi.
///
/// Pure-paint (không cần asset Rive/Lottie) nên chạy được ngay ở mọi màn. Bắn
/// qua [Overlay] để nổi trên toàn màn (kể cả dialog kết quả) mà không cần bọc
/// từng màn trong Stack.
///
/// Tôn trọng reduce-motion (`10-accessibility` §6): tắt animation ⇒ không bắn,
/// không haptic. Chuyển động **có hướng** (bay lên–rơi xuống + xoay trọn vòng),
/// không dao động tại chỗ.
abstract final class CompletionCelebration {
  CompletionCelebration._();

  /// Chọn mức theo tỉ lệ điểm. [goodThreshold] mặc định 0.7 (~70%).
  static CelebrationLevel levelForScore(
    double score,
    double maxScore, {
    double goodThreshold = 0.7,
  }) {
    if (maxScore <= 0) return CelebrationLevel.gentle;
    return (score / maxScore) >= goodThreshold
        ? CelebrationLevel.festive
        : CelebrationLevel.gentle;
  }

  /// Bắn confetti một lần. An toàn khi gọi trong listener / callback: việc chèn
  /// overlay được hoãn tới post-frame nên luôn nổi trên dialog vừa mở.
  static void fire(
    BuildContext context, {
    CelebrationLevel level = CelebrationLevel.festive,
  }) {
    // Reduce-motion → bỏ qua hoàn toàn.
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    if (level == CelebrationLevel.festive) {
      AppHaptics.celebrate(context);
    } else {
      AppHaptics.confirm(context);
    }

    late OverlayEntry entry;
    var removed = false;
    void remove() {
      if (removed) return;
      removed = true;
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: IgnorePointer(
          child: _ConfettiLayer(level: level, onDone: remove),
        ),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (overlay.mounted) overlay.insert(entry);
    });
  }

  /// Bắn theo điểm: festive khi đạt ngưỡng, còn lại gentle.
  static void fireForScore(
    BuildContext context, {
    required double score,
    required double maxScore,
    double goodThreshold = 0.7,
  }) {
    fire(
      context,
      level: levelForScore(score, maxScore, goodThreshold: goodThreshold),
    );
  }
}

/// Bọc quanh một subtree để tự bắn confetti **một lần** khi subtree gắn vào cây
/// (dùng cho màn stateless / BlocBuilder — vd. speaking feedback). Render
/// [child] nguyên vẹn; nếu không truyền thì vô hình.
class CelebrationTrigger extends StatefulWidget {
  const CelebrationTrigger({
    super.key,
    required this.level,
    this.enabled = true,
    this.child = const SizedBox.shrink(),
  });

  final CelebrationLevel level;
  final bool enabled;
  final Widget child;

  @override
  State<CelebrationTrigger> createState() => _CelebrationTriggerState();
}

class _CelebrationTriggerState extends State<CelebrationTrigger> {
  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) CompletionCelebration.fire(context, level: widget.level);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ── Nội bộ ────────────────────────────────────────────────────────────────

/// Palette celebrate — amber + xanh lá + bộ skill color (token, không hex mới).
/// `final` (không `const`) vì `.color` là truy cập field trên instance.
final List<Color> _palette = <Color>[
  AppColors.accent,
  AppColors.accentDark,
  AppColors.success,
  AppSkillColors.listening.color, // blue
  AppSkillColors.speaking.color, // emerald
  AppSkillColors.reading.color, // orange
  AppSkillColors.writing.color, // violet
  AppSkillColors.vocabulary.color, // rose
];

class _ConfettiLayer extends StatefulWidget {
  const _ConfettiLayer({required this.level, required this.onDone});

  final CelebrationLevel level;
  final VoidCallback onDone;

  @override
  State<_ConfettiLayer> createState() => _ConfettiLayerState();
}

class _ConfettiLayerState extends State<_ConfettiLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Confetto> _pieces;

  @override
  void initState() {
    super.initState();
    final festive = widget.level == CelebrationLevel.festive;
    _pieces = _generate(festive);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: festive ? 2200 : 1500),
    )..forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(progress: _controller.value, pieces: _pieces),
        ),
      ),
    );
  }
}

/// Một mảnh confetti — toạ độ/vận tốc chuẩn hoá theo kích thước canvas (0..1),
/// painter nhân với size thật lúc vẽ nên không cần biết size ở initState.
class _Confetto {
  const _Confetto({
    required this.ox,
    required this.oy,
    required this.vx,
    required this.vy,
    required this.gy,
    required this.rot0,
    required this.spin,
    required this.color,
    required this.w,
    required this.h,
    required this.delay,
    required this.square,
  });

  final double ox; // origin x (fraction of width)
  final double oy; // origin y (fraction of height)
  final double vx; // horizontal velocity (fraction of width, applied * p)
  final double vy; // vertical velocity (fraction of height, applied * p)
  final double gy; // gravity (fraction of height, applied * p²)
  final double rot0; // rotation phase
  final double spin; // total spin (radians over the run)
  final Color color;
  final double w; // px
  final double h; // px
  final double delay; // 0..1 start offset
  final bool square;
}

List<_Confetto> _generate(bool festive) {
  final rnd = math.Random();
  double range(double a, double b) => a + rnd.nextDouble() * (b - a);
  Color pick() => _palette[rnd.nextInt(_palette.length)];
  double spin() => range(2, 6) * math.pi * 2 * (rnd.nextBool() ? 1 : -1);

  final pieces = <_Confetto>[];

  if (festive) {
    // Hai "pháo" ở góc dưới bắn lên–vào trong rồi rơi theo trọng lực.
    for (final side in const [-1.0, 1.0]) {
      final ox = side < 0 ? 0.06 : 0.94;
      for (var i = 0; i < 30; i++) {
        final vxMag = range(0.12, 0.6);
        pieces.add(_Confetto(
          ox: ox,
          oy: 1.02,
          vx: side < 0 ? vxMag : -vxMag,
          vy: -range(0.72, 1.15),
          gy: range(1.1, 1.6),
          rot0: range(0, math.pi * 2),
          spin: spin(),
          color: pick(),
          w: range(6, 11),
          h: range(4, 8),
          delay: range(0, 0.12),
          square: rnd.nextDouble() < 0.28,
        ));
      }
    }
    // Mưa phủ từ trên cho đầy khung.
    for (var i = 0; i < 18; i++) {
      pieces.add(_Confetto(
        ox: range(0.05, 0.95),
        oy: -0.05,
        vx: range(-0.08, 0.08),
        vy: range(0.85, 1.2),
        gy: 0.25,
        rot0: range(0, math.pi * 2),
        spin: spin(),
        color: pick(),
        w: range(6, 10),
        h: range(4, 7),
        delay: range(0, 0.5),
        square: rnd.nextDouble() < 0.28,
      ));
    }
  } else {
    // Gentle: mưa confetti nhẹ, thưa, từ trên rơi xuống.
    for (var i = 0; i < 24; i++) {
      pieces.add(_Confetto(
        ox: range(0.05, 0.95),
        oy: -0.05,
        vx: range(-0.06, 0.06),
        vy: range(0.85, 1.15),
        gy: 0.15,
        rot0: range(0, math.pi * 2),
        spin: range(2, 4) * math.pi * 2 * (rnd.nextBool() ? 1 : -1),
        color: pick(),
        w: range(5, 9),
        h: range(4, 7),
        delay: range(0, 0.55),
        square: rnd.nextDouble() < 0.3,
      ));
    }
  }

  return pieces;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.pieces});

  final double progress;
  final List<_Confetto> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    for (final c in pieces) {
      final p = (progress - c.delay) / (1 - c.delay);
      if (p <= 0) continue;
      final pp = p.clamp(0.0, 1.0);

      final x = (c.ox + c.vx * pp) * w;
      final y = (c.oy + c.vy * pp + c.gy * pp * pp) * h;
      if (y > h * 1.15 || y < -h * 0.25) continue;

      double alpha = 1;
      if (pp < 0.06) {
        alpha = pp / 0.06; // pop-in
      } else if (pp > 0.78) {
        alpha = (1 - (pp - 0.78) / 0.22).clamp(0.0, 1.0); // fade-out
      }
      if (alpha <= 0) continue;

      paint.color = c.color.withValues(alpha: alpha);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(c.rot0 + c.spin * pp);
      final rect = c.square
          ? Rect.fromCenter(center: Offset.zero, width: c.w, height: c.w)
          : Rect.fromCenter(center: Offset.zero, width: c.w, height: c.h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
