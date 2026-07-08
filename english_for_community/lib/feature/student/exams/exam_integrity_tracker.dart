import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/feature/student/exams/exam_fullscreen_monitor.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reports tab switches / focus loss / paste attempts / fullscreen exit during an
/// in-progress exam.
///
/// Dùng MỘT mốc trạng thái ([_away]) để mỗi lần rời app chỉ đếm 1 lần rời tab và
/// đo đúng khoảng thời gian mất focus. Một lần rời app, Flutter phát nhiều event
/// lifecycle liên tiếp (`inactive → hidden → paused`, và `hidden → inactive →
/// resumed` khi quay lại); nếu bắt theo từng event như trước thì tab bị đếm dội
/// 2–3 lần và mốc `_unfocusedAt` bị `inactive` (lúc quay về) reset về ~now ngay
/// trước `resumed` khiến focus-loss luôn ≈ 0.
///
/// Paste: [ExamIntegrityScope] cung cấp callback report cho các ô nhập bên dưới
/// (dùng [examPasteAwareContextMenu] cho `TextField.contextMenuBuilder` để bắt
/// long-press "Paste" trên mobile / menu chuột phải trên web); Ctrl+C/V vẫn bắt
/// qua [Focus.onKeyEvent] cho bàn phím vật lý.
class ExamIntegrityTracker extends StatefulWidget {
  const ExamIntegrityTracker({
    super.key,
    required this.attemptId,
    required this.child,
  });

  final String attemptId;
  final Widget child;

  @override
  State<ExamIntegrityTracker> createState() => _ExamIntegrityTrackerState();
}

class _ExamIntegrityTrackerState extends State<ExamIntegrityTracker> with WidgetsBindingObserver {
  /// true khi app đã rời foreground (đã đếm 1 lần rời tab, đang đo focus-loss).
  bool _away = false;
  DateTime? _awayAt;
  ExamFullscreenMonitor? _fullscreen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Web: ép fullscreen (best-effort) + báo khi thoát fullscreen giữa lúc thi.
    // Off-web monitor là no-op (stub), nên guard kIsWeb chỉ để khỏi gọi thừa.
    if (kIsWeb) {
      _fullscreen = ExamFullscreenMonitor(onExited: () => _flush(fullscreenExited: true))..start();
    }
  }

  @override
  void dispose() {
    _fullscreen?.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _flush({int? tabDelta, int? focusDelta, int? copyDelta, bool? fullscreenExited}) async {
    if (widget.attemptId.isEmpty) return;
    await getIt<TeacherExamRepository>().reportExamAttemptIntegrity(
      widget.attemptId,
      tabSwitchDelta: tabDelta,
      focusLossDelta: focusDelta,
      copyPasteDelta: copyDelta,
      fullscreenExited: fullscreenExited,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Rời app THẬT = `paused` (mobile chuyển nền) hoặc `hidden` (web đổi tab /
    // minimize). Bỏ qua `inactive` — transient (kéo notification, cuộc gọi đến,
    // app switcher, control center) không phải rời bài, và nếu tính nó sẽ vừa
    // đếm dội vừa reset sai mốc đo thời gian.
    final leftApp = state == AppLifecycleState.paused || state == AppLifecycleState.hidden;
    if (leftApp) {
      if (!_away) {
        _away = true;
        _awayAt = DateTime.now();
        _flush(tabDelta: 1);
      }
    } else if (state == AppLifecycleState.resumed && _away) {
      final awayAt = _awayAt;
      _away = false;
      _awayAt = null;
      final sec = awayAt == null ? 0 : DateTime.now().difference(awayAt).inSeconds;
      if (sec > 0) _flush(focusDelta: sec);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        HardwareKeyboard.instance.isControlPressed &&
        (event.logicalKey == LogicalKeyboardKey.keyV || event.logicalKey == LogicalKeyboardKey.keyC)) {
      _flush(copyDelta: 1);
    }
    return KeyEventResult.ignored;
  }

  void _reportPaste() => _flush(copyDelta: 1);

  @override
  Widget build(BuildContext context) {
    return ExamIntegrityScope(
      reportPaste: _reportPaste,
      child: Focus(
        onKeyEvent: _onKey,
        child: widget.child,
      ),
    );
  }
}

/// Kênh report gian lận cho các ô nhập nằm dưới [ExamIntegrityTracker].
///
/// [maybeOf] trả null khi không ở trong một bài thi → [examPasteAwareContextMenu]
/// trở thành no-op, an toàn khi dùng lại trên widget dùng chung (vd Writing).
class ExamIntegrityScope extends InheritedWidget {
  const ExamIntegrityScope({
    super.key,
    required this.reportPaste,
    required super.child,
  });

  final VoidCallback reportPaste;

  static ExamIntegrityScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ExamIntegrityScope>();

  @override
  bool updateShouldNotify(ExamIntegrityScope oldWidget) => false;
}

/// `contextMenuBuilder` giữ nguyên menu mặc định nhưng đếm thêm 1 lần paste khi
/// người dùng bấm "Paste". No-op nếu không có [ExamIntegrityScope] tổ tiên.
Widget examPasteAwareContextMenu(BuildContext context, EditableTextState editableState) {
  final scope = ExamIntegrityScope.maybeOf(context);
  final items = editableState.contextMenuButtonItems.map((item) {
    if (scope == null || item.type != ContextMenuButtonType.paste) return item;
    return ContextMenuButtonItem(
      onPressed: () {
        scope.reportPaste();
        item.onPressed?.call();
      },
      type: item.type,
      label: item.label,
    );
  }).toList();
  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: editableState.contextMenuAnchors,
    buttonItems: items,
  );
}
