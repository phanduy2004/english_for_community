import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
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
  int _tabSwitches = 0;
  int _focusLossSec = 0;
  int _copyPaste = 0;
  DateTime? _unfocusedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _flush({int? tabDelta, int? focusDelta, int? copyDelta}) async {
    if (widget.attemptId.isEmpty) return;
    await getIt<TeacherExamRepository>().reportExamAttemptIntegrity(
      widget.attemptId,
      tabSwitchDelta: tabDelta,
      focusLossDelta: focusDelta,
      copyPasteDelta: copyDelta,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _tabSwitches += 1;
      _unfocusedAt = DateTime.now();
      _flush(tabDelta: 1);
    } else if (state == AppLifecycleState.resumed && _unfocusedAt != null) {
      final sec = DateTime.now().difference(_unfocusedAt!).inSeconds;
      if (sec > 0) {
        _focusLossSec += sec;
        _flush(focusDelta: sec);
      }
      _unfocusedAt = null;
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        ((event.logicalKey == LogicalKeyboardKey.keyV && HardwareKeyboard.instance.isControlPressed) ||
            (event.logicalKey == LogicalKeyboardKey.keyC && HardwareKeyboard.instance.isControlPressed))) {
      _copyPaste += 1;
      _flush(copyDelta: 1);
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _onKey,
      child: widget.child,
    );
  }
}
