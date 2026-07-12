import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/feature/student/exams/exam_fullscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reports tab switches / focus loss / paste attempts during an in-progress exam.
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
  DateTime? _unfocusedAt;
  bool _isAway = false; // A5: chống đếm gấp đôi qua inactive->paused
  void Function()? _fullscreenDisposer;
  bool _fullscreenReported = false; // A3: latch client-side, chỉ report thoát fullscreen 1 lần

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    enterExamFullscreen(); // A3: web ép fullscreen (best-effort); io/mobile no-op
    _fullscreenDisposer = listenExamFullscreenExit(_onFullscreenExit);
  }

  @override
  void dispose() {
    _fullscreenDisposer?.call();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onFullscreenExit() {
    if (_fullscreenReported) return;
    _fullscreenReported = true;
    _flush(fullscreenExited: true);
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
    final away = state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden; // A5: web/desktop mới map sang hidden
    if (away) {
      if (!_isAway) {
        _isAway = true;
        _unfocusedAt = DateTime.now();
        _flush(tabDelta: 1); // chỉ +1 mỗi chu kỳ rời màn
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isAway && _unfocusedAt != null) {
        final sec = DateTime.now().difference(_unfocusedAt!).inSeconds;
        if (sec > 0) _flush(focusDelta: sec);
      }
      _isAway = false;
      _unfocusedAt = null;
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        ((event.logicalKey == LogicalKeyboardKey.keyV && HardwareKeyboard.instance.isControlPressed) ||
            (event.logicalKey == LogicalKeyboardKey.keyC && HardwareKeyboard.instance.isControlPressed))) {
      _flush(copyDelta: 1);
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return ExamIntegrityScope(
      reportPaste: () => _flush(copyDelta: 1),
      child: Focus(
        onKeyEvent: _onKey,
        child: widget.child,
      ),
    );
  }
}

/// Cho phép các ô nhập trong bài thi báo cáo paste. maybeOf == null ⇒ ngoài exam ⇒ no-op.
class ExamIntegrityScope extends InheritedWidget {
  const ExamIntegrityScope({super.key, required this.reportPaste, required super.child});

  final VoidCallback reportPaste;

  static ExamIntegrityScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ExamIntegrityScope>();

  @override
  bool updateShouldNotify(ExamIntegrityScope oldWidget) => false;
}

/// contextMenuBuilder dùng chung cho ô nhập bài thi: giữ menu mặc định, hook nút Paste
/// để đếm copy-paste khi đang trong exam (A4). Ngoài exam (scope null) ⇒ menu mặc định, không đếm.
Widget examContextMenuBuilder(BuildContext context, EditableTextState editableState) {
  final scope = ExamIntegrityScope.maybeOf(context);
  final items = editableState.contextMenuButtonItems.map((item) {
    if (item.type == ContextMenuButtonType.paste && scope != null) {
      return ContextMenuButtonItem(
        onPressed: () {
          scope.reportPaste();
          item.onPressed?.call();
        },
        type: item.type,
        label: item.label,
      );
    }
    return item;
  }).toList();
  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: editableState.contextMenuAnchors,
    buttonItems: items,
  );
}
