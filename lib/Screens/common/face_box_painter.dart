// lib/pages/common/face_box_painter.dart
import 'package:flutter/material.dart';

class FaceBoxPainter extends CustomPainter {
  final Rect? rect;
  final bool? ok;
  final Color? color;
  final String? label;

  const FaceBoxPainter({
    required this.rect,
    this.ok,
    this.color,
    this.label,
  }) : assert(color != null || ok != null, 'Provide either `color` or `ok`.');

  Color get _stroke => color ?? ((ok == true) ? Colors.greenAccent : Colors.redAccent);

  @override
  void paint(Canvas c, Size s) {
    final r = rect;
    if (r == null) return;

    // LOG: painter chạy + thông số
    // ignore: avoid_print
    print('[painter] canvas=${s.width.toStringAsFixed(0)}x${s.height.toStringAsFixed(0)} '
        'rect=(${r.left.toStringAsFixed(1)},${r.top.toStringAsFixed(1)},${r.width.toStringAsFixed(1)}x${r.height.toStringAsFixed(1)}) '
        'label="${label ?? ""}"');

    final strokePaint = Paint()
      ..color = _stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    c.drawRect(r, strokePaint);

    final text = label?.trim();
    if (text == null || text.isEmpty) return;

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );
    tp.layout(maxWidth: s.width - 8.0);

    const padH = 6.0, padV = 3.0;
    final w = tp.width + padH * 2;
    final h = tp.height + padV * 2;

    double x = r.left;
    if (x + w > s.width) x = s.width - w - 4;
    if (x < 0) x = 0;

    double y = r.top - h - 2;
    if (y < 0) y = r.top + 2;

    final bg = Paint()..color = Colors.black.withOpacity(0.65);
    final rr = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(6));
    c.drawRRect(rr, bg);

    final bd = Paint()
      ..color = _stroke.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    c.drawRRect(rr, bd);

    tp.paint(c, Offset(x + padH, y + padV));
  }

  @override
  bool shouldRepaint(covariant FaceBoxPainter o) {
    return o.rect != rect || o.ok != ok || o.color != color || o.label != label;
  }
}
