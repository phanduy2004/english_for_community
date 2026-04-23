import 'dart:ui' show PathMetric, Tangent;

import 'package:flutter/material.dart';

/// Biểu đồ cột hoạt động theo ngày — **cùng implementation** với tab Progress (`Activity`).
/// (Scroll ngang, highlight cột cuối, đường xu hướng nét đứt.)
class WeeklyActivityBarsChart extends StatefulWidget {
  const WeeklyActivityBarsChart({
    super.key,
    required this.values,
    required this.labels,
    this.barColor,
    this.highlightIndex,
    this.highlightColor,
  });

  final List<int> values;
  final List<String> labels;
  final Color? barColor;
  final int? highlightIndex;
  final Color? highlightColor;

  @override
  State<WeeklyActivityBarsChart> createState() => _WeeklyActivityBarsChartState();
}

class _WeeklyActivityBarsChartState extends State<WeeklyActivityBarsChart> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void didUpdateWidget(covariant WeeklyActivityBarsChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.labels.length != widget.labels.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const axisColor = Color(0xFFA1A1AA);
    const gridColor = Color(0xFFF4F4F5);

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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Divider(height: 1, color: gridColor),
                            const Divider(height: 1, color: gridColor),
                            const Divider(height: 1, color: gridColor),
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
                              final double barHeight = (value == 0) ? 0.0 : (ratio * barAreaHeight).clamp(4.0, barAreaHeight);
                              final isHi = widget.highlightIndex != null && i == widget.highlightIndex;
                              final c = isHi ? (widget.highlightColor ?? Colors.orange) : (widget.barColor ?? Colors.blue);

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
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                      ),
                                    ),
                                    const SizedBox(height: xAxisGap),
                                    SizedBox(
                                      height: xAxisLabelHeight,
                                      child: Center(
                                        child: Text(
                                          widget.labels[i],
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isHi ? FontWeight.bold : FontWeight.normal,
                                            color: isHi ? const Color(0xFF09090B) : axisColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                          IgnorePointer(
                            child: CustomPaint(
                              size: Size(totalContentWidth, barAreaHeight),
                              painter: _WeeklyActivityTrendPainter(
                                values: widget.values,
                                itemWidth: itemSlotWidth,
                                maxValue: chartTopVal,
                                lineColor: const Color(0xFFEF4444),
                                lineWidth: 1.5,
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
                        Text("${chartTopVal.round()}", style: const TextStyle(fontSize: 10, color: axisColor)),
                        Text("${(chartTopVal / 2).round()}", style: const TextStyle(fontSize: 10, color: axisColor)),
                        const Text("0", style: TextStyle(fontSize: 10, color: axisColor)),
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
  }
}

class _WeeklyActivityTrendPainter extends CustomPainter {
  final List<int> values;
  final double itemWidth;
  final double maxValue;
  final Color lineColor;
  final double lineWidth;

  _WeeklyActivityTrendPainter({
    required this.values,
    required this.itemWidth,
    required this.maxValue,
    required this.lineColor,
    required this.lineWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    double getX(int index) => (index * itemWidth) + (itemWidth / 2);
    double getY(int index) {
      final val = values[index];
      final ratio = (val / maxValue).clamp(0.0, 1.0);
      return size.height - (ratio * size.height);
    }

    final Path path = Path();
    path.moveTo(getX(0), getY(0));

    for (int i = 0; i < values.length - 1; i++) {
      final double x1 = getX(i);
      final double y1 = getY(i);
      final double x2 = getX(i + 1);
      final double y2 = getY(i + 1);

      final double controlX1 = x1 + (x2 - x1) / 2;
      final double controlY1 = y1;
      final double controlX2 = x1 + (x2 - x1) / 2;
      final double controlY2 = y2;

      path.cubicTo(controlX1, controlY1, controlX2, controlY2, x2, y2);
    }

    final Path dashedPath = Path();
    const double dashWidth = 6.0;
    const double dashSpace = 4.0;
    double distance = 0.0;

    for (final PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        dashedPath.addPath(
          measurePath.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    final Paint paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(dashedPath, paint);

    final Paint dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final Paint dotBorderPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < values.length; i++) {
      final offset = Offset(getX(i), getY(i));
      if (i != values.length - 1) {
        canvas.drawCircle(offset, 3.0, dotPaint);
        canvas.drawCircle(offset, 3.0, dotBorderPaint);
      }
    }

    if (values.length > 1) {
      final PathMetric lastMetric = path.computeMetrics().last;
      final Tangent? tangent = lastMetric.getTangentForOffset(lastMetric.length);

      if (tangent != null) {
        final Offset endPoint = tangent.position;
        final double angle = -tangent.angle;

        canvas.save();
        canvas.translate(endPoint.dx, endPoint.dy);
        canvas.rotate(-angle);

        final Path arrowPath = Path();
        arrowPath.moveTo(0, 0);
        arrowPath.lineTo(-6, -4);
        arrowPath.lineTo(-6, 4);
        arrowPath.close();

        final Paint arrowPaint = Paint()
          ..color = lineColor
          ..style = PaintingStyle.fill;

        canvas.drawPath(arrowPath, arrowPaint);
        canvas.restore();
      }
    } else if (values.length == 1) {
      final offset = Offset(getX(0), getY(0));
      canvas.drawCircle(offset, 3.0, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyActivityTrendPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.itemWidth != itemWidth ||
        oldDelegate.maxValue != maxValue;
  }
}
