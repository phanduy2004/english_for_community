/// No-op trên mobile/desktop (io). Fullscreen chỉ có nghĩa trên web.
void enterExamFullscreen() {}

/// Trả về disposer; no-op ngoài web.
void Function() listenExamFullscreenExit(void Function() onExit) => () {};
