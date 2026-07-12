import 'dart:ui' show PathMetric, Tangent;

import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

/// Biểu đồ cột hoạt động theo ngày — **cùng implementation** với tab Progress (`Activity`).
/// (Scroll ngang, highlight cột cuối, đường xu hướng nét đứt.)
///
/// Có animation khi hiện lần đầu / khi dữ liệu đổi (đổi Day/Week/Month):
/// - Các cột "mọc" lên lệch pha trái→phải (kiểu các khối ghép lại thành biểu đồ).
/// - Đường xu hướng vẽ dần từ điểm bắt đầu → điểm kết thúc, mũi tên hiện ở cuối.
class WeeklyActivityBarsChart extends StatefulWidget {
  const WeeklyActivityBarsChart({
    super.key,
    required this.values,
    required this.labels,
    this.barColor,
    this.highlightIndex,
    this.highlightColor,
    this.showTrendLine = true,
  });

  final List<int> values;
  final List<String> labels;
  final Color? barColor;
  final int? highlightIndex;
  final Color? highlightColor;

  /// Đường xu hướng nét đứt phủ lên cột. Tắt (false) cho biểu đồ cần đọc
  /// đơn nghĩa (vd Teacher Analytics "Submissions per day").
  final bool showTrendLine;

  @override
  State<WeeklyActivityBarsChart> createState() => _WeeklyActivityBarsChartState();
}

class _WeeklyActivityBarsChartState extends State<WeeklyActivityBarsChart>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
      _anim.forward();
    });
  }

  @override
  void didUpdateWidget(covariant WeeklyActivityBarsChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.labels.length != widget.labels.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
    // Dữ liệu đổi (đổi Day/Week/Month hoặc pull-to-refresh) → chạy lại animation.
    if (!listEquals(oldWidget.values, widget.values) ||
        !listEquals(oldWidget.labels, widget.labels)) {
      _anim.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Tiến độ "mọc" của cột thứ [i] tại thời điểm [t] (0..1) — lệch pha trái→phải.
  double _barProgress(int i, int count, double t) {
    if (count <= 1) return Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    const double window = 0.55; // mỗi cột mọc trong 55% thời lượng
    final double start = (i / count) * (1 - window);
    final double local = ((t - start) / window).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(local);
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = (widget.values.isEmpty ? 0 : widget.values.reduce((a, b) => a > b ? a : b)).toDouble();
    double chartTopVal;
    if (maxVal <= 10) {
      chartTopVal = 10;
    } else if (maxVal <= 60) {
      chartTopVal = (maxVal / 10).ceil() * 10.0;
    } else {
      chartTopVal = (maxVal / 30).ceil() * 30.0;
    }
    if (chartTopVal == 0) chartTopVal = 10;

    return LayoutBuilder(
      builder: (context, constraints) {
        const double xAxisLabelHeight = 20;
        const double xAxisGap = 8;
        const double yAxisWidth = 30;

        final double barAreaHeight = (constraints.maxHeight - xAxisLabelHeight - xAxisGap).clamp(0.0, constraints.maxHeight);
        final double chartAreaWidth = constraints.maxWidth - yAxisWidth;

        final int itemCount = widget.values.length;
        const double minItemWidth = 46.0;
        final double totalContentWidth = (itemCount * minItemWidth > chartAreaWidth)
            ? itemCount * minItemWidth
            : chartAreaWidth;

        final double itemSlotWidth = itemCount > 0 ? totalContentWidth / itemCount : 0;

        return AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            final double t = _anim.value;
            // Đường xu hướng vẽ ở nửa sau, sau khi cột đã mọc kha khá.
            final double lineT = Curves.easeInOut.transform(((t - 0.4) / 0.6).clamp(0.0, 1.0));

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: barAreaHeight,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Divider(height: 1, color: AppColors.chartGrid),
                                Divider(height: 1, color: AppColors.chartGrid),
                                Divider(height: 1, color: AppColors.chartGrid),
                              ],
                            ),
                          ),
                          const SizedBox(height: xAxisLabelHeight + xAxisGap),
                        ],
                      ),
                      SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: totalContentWidth,
                          height: constraints.maxHeight,
                          child: Stack(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(itemCount, (i) {
                                  final value = widget.values[i];
                                  final ratio = (value / chartTopVal).clamp(0.0, 1.0);
                                  final double fullBarHeight =
                                      (value == 0) ? 0.0 : (ratio * barAreaHeight).clamp(4.0, barAreaHeight);
                                  final double barHeight = fullBarHeight * _barProgress(i, itemCount, t);
                                  final isHi = widget.highlightIndex != null && i == widget.highlightIndex;
                                  final c = isHi
                                      ? (widget.highlightColor ?? AppColors.chartHighlight)
                                      : (widget.barColor ?? AppColors.chartBar);

                                  return SizedBox(
                                    width: itemSlotWidth,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          width: 14,
                                          height: barHeight,
                                          decoration: BoxDecoration(
                                            color: c,
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.chip)),
                                          ),
                                        ),
                                        const SizedBox(height: xAxisGap),
                                        SizedBox(
                                          height: xAxisLabelHeight,
                                          child: Center(
                                            child: Text(
                                              widget.labels[i],
                                              style: TextStyle(
                                                fontSize: AppTypography.mobileCaption,
                                                fontWeight: isHi ? FontWeight.bold : FontWeight.normal,
                                                color: isHi ? AppColors.textPrimary : AppColors.textMuted,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                              if (widget.showTrendLine)
                                IgnorePointer(
                                  child: CustomPaint(
                                    size: Size(totalContentWidth, barAreaHeight),
                                    painter: _WeeklyActivityTrendPainter(
                                      values: widget.values,
                                      itemWidth: itemSlotWidth,
                                      maxValue: chartTopVal,
                                      lineColor: AppColors.chartTrend,
                                      lineWidth: 1.5,
                                      progress: lineT,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: yAxisWidth,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: barAreaHeight,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${chartTopVal.round()}', style: const TextStyle(fontSize: AppTypography.mobileCaption, color: AppColors.textMuted)),
                            Text('${(chartTopVal / 2).round()}', style: const TextStyle(fontSize: AppTypography.mobileCaption, color: AppColors.textMuted)),
                            const Text('0', style: TextStyle(fontSize: AppTypography.mobileCaption, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      const SizedBox(height: xAxisLabelHeight + xAxisGap),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _WeeklyActivityTrendPainter extends CustomPainter {
  final List<int> values;
  final double itemWidth;
  final double maxValue;
  final Color lineColor;
  final double lineWidth;

  /// 0..1 — phần đường đã được vẽ (từ điểm đầu tới điểm hiện tại).
  final double progress;

  _WeeklyActivityTrendPainter({
    required this.values,
    required this.itemWidth,
    required this.maxValue,
    required this.lineColor,
    required this.lineWidth,
    this.progress = 1.0,
  });

  double _x(int index) => (index * itemWidth) + (itemWidth / 2);
  double _y(int index, double height) {
    final ratio = (values[index] / maxValue).clamp(0.0, 1.0);
    return height - (ratio * height);
  }

  /// Đường cong cubic đi qua tất cả các điểm.
  Path _buildPath(double height, {int? upToVertex}) {
    final end = upToVertex ?? (values.length - 1);
    final path = Path()..moveTo(_x(0), _y(0, height));
    for (int i = 0; i < end; i++) {
      final x1 = _x(i), y1 = _y(i, height);
      final x2 = _x(i + 1), y2 = _y(i + 1, height);
      final cx = x1 + (x2 - x1) / 2;
      path.cubicTo(cx, y1, cx, y2, x2, y2);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || progress <= 0) return;

    final Path path = _buildPath(size.height);
    final metrics = path.computeMetrics().toList();
    final double totalLen = metrics.fold(0.0, (s, m) => s + m.length);
    final double drawnLen = totalLen * progress.clamp(0.0, 1.0);

    // Phần đường đang hiển thị: từ đầu tới `drawnLen`.
    final Path visible = Path();
    double acc = 0.0;
    for (final m in metrics) {
      if (acc >= drawnLen) break;
      final double take = (drawnLen - acc).clamp(0.0, m.length);
      visible.addPath(m.extractPath(0, take), Offset.zero);
      acc += m.length;
    }

    // Điểm mút hiện tại của đường (đầu mút phần đã vẽ) — để khép vùng tô.
    Offset? tip;
    double accTip = 0.0;
    for (final m in metrics) {
      if (drawnLen <= accTip + m.length) {
        tip = m.getTangentForOffset(drawnLen - accTip)?.position;
        break;
      }
      accTip += m.length;
    }
    tip ??= metrics.isNotEmpty
        ? metrics.last.getTangentForOffset(metrics.last.length)?.position
        : null;

    // Vùng tô gradient mềm dưới đường (mờ dần xuống đáy) — tạo chiều sâu.
    if (tip != null) {
      final Path fill = Path()
        ..addPath(visible, Offset.zero)
        ..lineTo(tip.dx, size.height)
        ..lineTo(_x(0), size.height)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..style = PaintingStyle.fill
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [lineColor.withValues(alpha: 0.16), lineColor.withValues(alpha: 0.0)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
    }

    // Chuyển sang nét đứt.
    final Path dashedPath = Path();
    const double dashWidth = 6.0;
    const double dashSpace = 4.0;
    for (final PathMetric m in visible.computeMetrics()) {
      double d = 0.0;
      while (d < m.length) {
        dashedPath.addPath(m.extractPath(d, d + dashWidth), Offset.zero);
        d += dashWidth + dashSpace;
      }
    }

    // Quầng sáng mờ dưới nét đứt cho đường mềm & nổi khối hơn.
    canvas.drawPath(
      dashedPath,
      Paint()
        ..color = lineColor.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineWidth + 2.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );

    final Paint paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(dashedPath, paint);

    // Chấm tròn ở mỗi điểm — hiện dần khi đường vẽ tới điểm đó.
    final Paint dotPaint = Paint()
      ..color = AppColors.surfaceCard
      ..style = PaintingStyle.fill;
    final Paint dotBorderPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    if (values.length == 1) {
      canvas.drawCircle(Offset(_x(0), _y(0, size.height)), 3.0, Paint()..color = lineColor);
      return;
    }

    for (int i = 0; i < values.length - 1; i++) {
      // Độ dài đường tính tới đỉnh i — chấm chỉ hiện khi nét đã vẽ qua.
      final double lenToVertex =
          _buildPath(size.height, upToVertex: i).computeMetrics().fold(0.0, (s, m) => s + m.length);
      if (lenToVertex > drawnLen + 0.5) continue;
      final offset = Offset(_x(i), _y(i, size.height));
      canvas.drawCircle(offset, 3.0, dotPaint);
      canvas.drawCircle(offset, 3.0, dotBorderPaint);
    }

    // Mũi tên chỉ hiện khi đã vẽ (gần) hết đường.
    if (progress >= 0.999 && metrics.isNotEmpty) {
      final PathMetric last = metrics.last;
      final Tangent? tangent = last.getTangentForOffset(last.length);
      if (tangent != null) {
        final Offset endPoint = tangent.position;
        final double angle = -tangent.angle;
        canvas.save();
        canvas.translate(endPoint.dx, endPoint.dy);
        canvas.rotate(-angle);
        final Path arrowPath = Path()
          ..moveTo(0, 0)
          ..lineTo(-6, -4)
          ..lineTo(-6, 4)
          ..close();
        canvas.drawPath(arrowPath, Paint()..color = lineColor..style = PaintingStyle.fill);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyActivityTrendPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.itemWidth != itemWidth ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.progress != progress;
  }
}
