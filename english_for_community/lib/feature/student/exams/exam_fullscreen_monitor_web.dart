import 'dart:async';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Web: ép fullscreen (best-effort) khi vào bài & báo [onExited] khi người dùng
/// thoát fullscreen giữa lúc thi (F11 / Esc / nút thoát của trình duyệt).
///
/// Lưu ý: `requestFullscreen()` cần user gesture còn hiệu lực; nếu bị trình duyệt
/// chặn thì ta vẫn gắn listener nên vẫn bắt được lần thoát khi user tự vào
/// fullscreen. Chỉ báo khi CHUYỂN từ fullscreen → không, tránh dương tính giả.
class ExamFullscreenMonitor {
  ExamFullscreenMonitor({required this.onExited});

  final void Function() onExited;

  StreamSubscription<html.Event>? _sub;
  bool _wasFullscreen = false;

  void start() {
    // Bị chặn (thiếu user gesture) → reject async; nuốt lỗi, listener vẫn hoạt
    // động nên vẫn bắt được lần thoát khi user tự vào fullscreen.
    html.document.documentElement?.requestFullscreen().catchError((_) {});
    _wasFullscreen = html.document.fullscreenElement != null;
    _sub = html.document.onFullscreenChange.listen((_) {
      final isFullscreen = html.document.fullscreenElement != null;
      if (_wasFullscreen && !isFullscreen) onExited();
      _wasFullscreen = isFullscreen;
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }
}
