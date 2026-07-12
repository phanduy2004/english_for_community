// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

void enterExamFullscreen() {
  try {
    html.document.documentElement?.requestFullscreen();
  } catch (_) {
    // best-effort: trình duyệt có thể chặn nếu ngoài user-gesture (§9.3)
  }
}

/// Lắng `fullscreenchange`; gọi onExit() khi đã thoát fullscreen. Trả disposer.
void Function() listenExamFullscreenExit(void Function() onExit) {
  void listener(html.Event _) {
    if (html.document.fullscreenElement == null) onExit();
  }

  html.document.addEventListener('fullscreenchange', listener);
  return () => html.document.removeEventListener('fullscreenchange', listener);
}
