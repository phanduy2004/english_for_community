import 'package:flutter/material.dart';

import 'app_lottie_preset.dart';
import 'app_lottie_view.dart';
import 'app_motion.dart';

/// Short full-screen celebrate overlay — use sparingly (submit success, level up).
class AppCelebrateOverlay extends StatelessWidget {
  const AppCelebrateOverlay({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'celebrate',
      barrierColor: Colors.black26,
      transitionDuration: AppMotion.fast,
      pageBuilder: (ctx, _, __) => const AppCelebrateOverlay(),
    ).whenComplete(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: AppLottieView(
            preset: AppLottiePreset.successCelebrate,
            size: AppMotion.celebrateLottieSize,
            repeat: false,
          ),
        ),
      ),
    );
  }
}
