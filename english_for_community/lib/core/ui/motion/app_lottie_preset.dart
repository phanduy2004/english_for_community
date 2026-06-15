/// Bundled Lottie files under [assets/animations/].
///
/// Download replacements from LottieFiles / Lordicon (export JSON),
/// keep the same filename, then hot-restart the app.
enum AppLottiePreset {
  emptyGeneric('assets/animations/empty_generic.json'),
  emptyNotifications('assets/animations/empty_notifications.json'),
  emptyClasses('assets/animations/empty_classes.json'),
  loading('assets/animations/loading.json'),
  successCelebrate('assets/animations/success_celebrate.json');

  const AppLottiePreset(this.assetPath);

  final String assetPath;
}
