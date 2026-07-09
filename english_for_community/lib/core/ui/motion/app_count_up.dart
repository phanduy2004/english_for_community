import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';

/// Số đếm tăng dần (streak / points / level) — đếm từ 0 lên [value] khi xuất
/// hiện, và chuyển mượt khi [value] thay đổi.
///
/// Tôn trọng reduce-motion (`10-accessibility` §6): hiện thẳng giá trị cuối.
class AppCountUpText extends StatelessWidget {
  const AppCountUpText({
    super.key,
    required this.value,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration,
  });

  final int value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    if (value <= 0 || MediaQuery.disableAnimationsOf(context)) {
      return Text('$prefix$value$suffix', style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: AppMotion.effective(context, duration ?? AppMotion.enter),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('$prefix${v.round()}$suffix', style: style),
    );
  }
}
