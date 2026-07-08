/// No-op ngoài web: mobile/desktop không có khái niệm "thoát fullscreen".
class ExamFullscreenMonitor {
  ExamFullscreenMonitor({required this.onExited});

  final void Function() onExited;

  void start() {}

  void stop() {}
}
