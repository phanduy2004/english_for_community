# WORK-ORDER WO-2 — Tín hiệu client đầy đủ (fullscreen web + paste mobile)

**Task ID:** 20260712-exam-integrity-anticheat-audit / WO-2 · **Loại:** BUG (feature-gap) · **Platform:** student mobile + web
**Ngày:** 2026-07-12 · **Nguồn:** `audit.md` finding A3, A4 · **Spec:** §4 (signal 3, 4)
**Ưu tiên:** CAO (A3) / TB (A4) · **Phụ thuộc:** nên làm SAU/CÙNG WO-1 (A2 đưa fullscreen vào công thức risk; nếu WO-1 chưa xong thì fullscreenExited gửi lên vẫn chưa nâng risk).

---

## 1. Vấn đề + nguyên nhân gốc

| ID | Vấn đề | Root cause |
| --- | --- | --- |
| **A3** | Client KHÔNG có tín hiệu fullscreen: không ép fullscreen, không phát hiện thoát. Hàng "Exited fullscreen" ở teacher luôn 0. | `exam_integrity_tracker.dart` không có code fullscreen; report chain (`teacher_exam_remote_datasource.dart:386`) không có param `fullscreenExited`. |
| **A4** | Mobile không bắt copy-paste (chỉ Ctrl+C/V bàn phím cứng). | `exam_integrity_tracker.dart:60-67` chỉ nghe `HardwareKeyboard`; các ô nhập bài thi dùng `TextField` mặc định, không có `contextMenuBuilder`/`onPaste`. |

---

## 2. Audit downstream

- **A3:** thêm param `fullscreenExited` xuyên chain datasource→repo→interface→tracker `_flush`. Backend `mergeIntegrity` (sau WO-1) đã latch `fullscreenExited===true` và đưa vào `medium`. Payload live-screen hiện KHÔNG chứa `fullscreenExited` (chỉ 3 count + riskLevel) → risk sẽ tự lên medium nên teacher vẫn thấy cờ; hiển thị con số fullscreen riêng là việc của WO-3/analytics (out scope).
- **A4:** `contextMenuBuilder` dùng chung `examContextMenuBuilder`. 4 widget input tái sử dụng có mặt CẢ trong practice mode (`_Editor`, `PracticeTab`) → phải đảm bảo **chỉ đếm khi đang thi** qua `ExamIntegrityScope` (no-op ngoài exam). Không đổi hành vi paste (vẫn cho paste, chỉ ghi nhận).

---

## 3. Quyết định thiết kế + cảnh báo

1. **A3 — conditional import (nhái pattern repo sẵn có `file_download.dart`):** tạo `exam_fullscreen.dart` (export switch) + `exam_fullscreen_web.dart` (`dart:html`) + `exam_fullscreen_stub.dart` (no-op mobile/io). KHÔNG thêm package (repo chưa có `package:web`/`universal_html`; `dart:html` đã được dùng ở `file_download_web.dart`).
2. **A3 — nơi kích hoạt:** trong `ExamIntegrityTracker` (đã là `WidgetsBindingObserver`, wrap toàn runner, chỉ sống khi đang thi). `initState`→ `enterExamFullscreen()` (best-effort) + `listenFullscreenExit()`; `dispose`→ gỡ listener. ⚠️ `requestFullscreen` cần user-gesture còn hiệu lực → best-effort (§9.3 đã thừa nhận có thể bị chặn); KHÔNG throw nếu bị chặn.
3. **A4 — scope-gated paste:** `ExamIntegrityScope` (InheritedWidget) do tracker cung cấp `reportPaste()`. Helper `examContextMenuBuilder` gắn vào `contextMenuBuilder` của các ô nhập; khi nút "Paste" được bấm → gọi `ExamIntegrityScope.maybeOf(context)?.reportPaste()` (null ⇒ practice ⇒ no-op). Vẫn cho paste bình thường.
4. ⚠️ **Chạm là DỪNG & hỏi:** nếu thêm `contextMenuBuilder` làm vỡ context menu tuỳ biến nào đó có sẵn (grep xác nhận hiện KHÔNG có) → hỏi. Không đổi `readOnly`/`enabled` của TextField.

---

## 4. Scope IN / OUT

**IN:**
- (mới) `lib/feature/student/exams/exam_fullscreen.dart` + `exam_fullscreen_web.dart` + `exam_fullscreen_stub.dart`
- `lib/feature/student/exams/exam_integrity_tracker.dart` (A3 hook + `ExamIntegrityScope` + `examContextMenuBuilder` + `_flush` thêm fullscreen)
- `lib/core/datasource/teacher_exam_remote_datasource.dart` (thêm param `fullscreenExited`)
- `lib/core/repository/teacher_exam_repository.dart` + `lib/core/repository_impl/teacher_exam_repository_impl.dart` (thêm param)
- 4 ô nhập tái sử dụng (A4): `integrated_exam_grammar_widgets.dart` (`_GrammarBlankField`), `writing_task_page.dart` (`_Editor`), `listening/widget/practice_tab.dart`, `exam_embedded_fixed_writing_panel.dart`. (Tùy chọn: 2 ô legacy `exam_runner_page.dart`.)

**OUT (DỪNG & hỏi):** backend (đã xong ở WO-1); teacher UI; thêm package pubspec; đổi hành vi cho phép paste (chỉ ghi nhận, KHÔNG chặn); notice/điều khoản cho học sinh (khác task).

---

## 5. CONTEXT BUNDLE

### TS-1 — (MỚI) `exam_fullscreen.dart` + web + stub

**CLONE-THIS:** `lib/core/util/file_download.dart` (export switch) + `file_download_web.dart` (`import 'dart:html'`) + `file_download_stub.dart`.

**`lib/feature/student/exams/exam_fullscreen.dart`:**
```dart
export 'exam_fullscreen_stub.dart'
    if (dart.library.html) 'exam_fullscreen_web.dart';
```
**`lib/feature/student/exams/exam_fullscreen_stub.dart`:**
```dart
/// No-op trên mobile/desktop (io). Fullscreen chỉ có nghĩa trên web.
void enterExamFullscreen() {}

/// Trả về disposer; no-op ngoài web.
void Function() listenExamFullscreenExit(void Function() onExit) => () {};
```
**`lib/feature/student/exams/exam_fullscreen_web.dart`:**
```dart
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
```
**GOTCHA:** file `_web` chỉ compile trên web (guard `if (dart.library.html)`); mobile/io lấy stub → không lỗi build Android/iOS. Đừng `import 'dart:html'` trực tiếp ở tracker — chỉ import qua `exam_fullscreen.dart`.

### TS-2 — `exam_integrity_tracker.dart`: hook fullscreen + `ExamIntegrityScope` + `_flush(fullscreenExited)`

**file:** `english_for_community/lib/feature/student/exams/exam_integrity_tracker.dart`
**anchor (import):** `import 'package:flutter/services.dart';`
**anchor (flush):** `Future<void> _flush({int? tabDelta, int? focusDelta, int? copyDelta}) async {`
**anchor (build):** `return Focus(`

**BEFORE (verbatim `_flush` + `build`, dòng 36-75):**
```dart
  Future<void> _flush({int? tabDelta, int? focusDelta, int? copyDelta}) async {
    if (widget.attemptId.isEmpty) return;
    await getIt<TeacherExamRepository>().reportExamAttemptIntegrity(
      widget.attemptId,
      tabSwitchDelta: tabDelta,
      focusLossDelta: focusDelta,
      copyPasteDelta: copyDelta,
    );
  }
  ...
  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _onKey,
      child: widget.child,
    );
  }
}
```

**AFTER / thao tác chính xác:**
1. Thêm import: `import 'package:english_for_community/feature/student/exams/exam_fullscreen.dart';` (dùng đúng prefix package như các import khác trong file).
2. Trong state thêm field + hook (đặt cạnh `_isAway` của WO-1):
```dart
  void Function()? _fullscreenDisposer;
  bool _fullscreenReported = false;
```
3. `initState` (sau `addObserver`):
```dart
    enterExamFullscreen();
    _fullscreenDisposer = listenExamFullscreenExit(_onFullscreenExit);
```
4. `dispose` (trước `removeObserver`):
```dart
    _fullscreenDisposer?.call();
```
5. Thêm handler + mở rộng `_flush`:
```dart
  void _onFullscreenExit() {
    if (_fullscreenReported) return; // latch client-side, tránh spam
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
```
6. `build`: cung cấp scope cho paste:
```dart
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
```
7. Thêm InheritedWidget + helper (cuối file):
```dart
/// Cho phép các ô nhập trong bài thi báo cáo paste. maybeOf == null ⇒ ngoài exam ⇒ no-op.
class ExamIntegrityScope extends InheritedWidget {
  const ExamIntegrityScope({super.key, required this.reportPaste, required super.child});
  final VoidCallback reportPaste;

  static ExamIntegrityScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ExamIntegrityScope>();

  @override
  bool updateShouldNotify(ExamIntegrityScope oldWidget) => false;
}

/// contextMenuBuilder dùng chung: giữ menu mặc định, hook nút Paste để đếm (khi ở trong exam).
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
      );
    }
    return item;
  }).toList();
  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: editableState.contextMenuAnchors,
    buttonItems: items,
  );
}
```
**GOTCHA:** `EditableTextState`, `ContextMenuButtonItem`, `AdaptiveTextSelectionToolbar`, `ContextMenuButtonType` đều ở `package:flutter/material.dart` (đã import gián tiếp; file hiện import `material.dart` dòng 3 — OK). `updateShouldNotify` trả `false` vì `reportPaste` ổn định theo instance state.

### TS-3 — `teacher_exam_remote_datasource.dart`: thêm `fullscreenExited`

**file:** `english_for_community/lib/core/datasource/teacher_exam_remote_datasource.dart`
**anchor:** `final r = await dio.post('exams/attempts/$attemptId/integrity', data: {`
**BEFORE (verbatim dòng 386-398):**
```dart
  Future<dynamic> reportExamAttemptIntegrity(
    String attemptId, {
    int? tabSwitchDelta,
    int? focusLossDelta,
    int? copyPasteDelta,
  }) async {
    final r = await dio.post('exams/attempts/$attemptId/integrity', data: {
      if (tabSwitchDelta != null) 'tabSwitchDelta': tabSwitchDelta,
      if (focusLossDelta != null) 'focusLossDelta': focusLossDelta,
      if (copyPasteDelta != null) 'copyPasteDelta': copyPasteDelta,
    });
    return r.data;
  }
```
**AFTER:**
```dart
  Future<dynamic> reportExamAttemptIntegrity(
    String attemptId, {
    int? tabSwitchDelta,
    int? focusLossDelta,
    int? copyPasteDelta,
    bool? fullscreenExited,
  }) async {
    final r = await dio.post('exams/attempts/$attemptId/integrity', data: {
      if (tabSwitchDelta != null) 'tabSwitchDelta': tabSwitchDelta,
      if (focusLossDelta != null) 'focusLossDelta': focusLossDelta,
      if (copyPasteDelta != null) 'copyPasteDelta': copyPasteDelta,
      if (fullscreenExited != null) 'fullscreenExited': fullscreenExited,
    });
    return r.data;
  }
```

### TS-4 — repository interface + impl: thêm `fullscreenExited`

**Interface** `lib/core/repository/teacher_exam_repository.dart:88` — anchor: `reportExamAttemptIntegrity(`
BEFORE (chữ ký): `Future<Either<Failure, void>> reportExamAttemptIntegrity(String attemptId, {int? tabSwitchDelta, int? focusLossDelta, int? copyPasteDelta});`
AFTER: thêm `, bool? fullscreenExited` vào named params.

**Impl** `lib/core/repository_impl/teacher_exam_repository_impl.dart:838-858` — anchor: `await remote.reportExamAttemptIntegrity(`
BEFORE (verbatim body):
```dart
      await remote.reportExamAttemptIntegrity(
        attemptId,
        tabSwitchDelta: tabSwitchDelta,
        focusLossDelta: focusLossDelta,
        copyPasteDelta: copyPasteDelta,
      );
```
AFTER: thêm named param ở CẢ chữ ký hàm impl và lời gọi `remote....`: `fullscreenExited: fullscreenExited,`.

### TS-5 — 4 ô nhập tái sử dụng (A4): thêm `contextMenuBuilder: examContextMenuBuilder`

Import cần cho mỗi file (nếu chưa có): `import 'package:english_for_community/feature/student/exams/exam_integrity_tracker.dart';`

**5a — `lib/feature/student/exams/integrated_exam_grammar_widgets.dart`** (`_GrammarBlankField`) — anchor: `child: TextField(` (dòng ~186, trong widget `_GrammarBlankField`). Thêm `contextMenuBuilder: examContextMenuBuilder,` vào TextField. → cover mọi grammar blank + gap-fill.

**5b — `lib/feature/writing/writing_task_page.dart`** (`_Editor`) — anchor: `hintText: t.writingEditorHint,`. BEFORE: `final Widget field = TextField(controller: controller, focusNode: focusNode, ...)`. Thêm `contextMenuBuilder: examContextMenuBuilder,`. → cover writing composer (kể cả embedded exam). Ngoài exam (practice) scope null ⇒ no-op.

**5c — `lib/feature/listening/widget/practice_tab.dart`** — anchor: `hintText: t.dictationTypeWhatYouHearHint,`. Thêm `contextMenuBuilder: examContextMenuBuilder,` vào TextField dictation.

**5d — `lib/feature/student/exams/exam_embedded_fixed_writing_panel.dart`** — anchor: `hintText: l10n.studentExamEssayPlaceholder,` (trong file này, TextField có `controller: _controller`). Thêm `contextMenuBuilder: examContextMenuBuilder,`.

**(Tùy chọn 5e — legacy)** `lib/feature/student/exams/exam_runner_page.dart` 2 TextField (anchor `controller: _essayCtrl,` và `controller: _blankControllers[`). Chỉ làm nếu WO-1 A6 đã bọc tracker cho legacy runner (nếu không, scope null ⇒ vô hại nhưng vô dụng).

**GOTCHA A4:** `writing_task_page.dart` và `practice_tab.dart` được dùng ngoài exam. `examContextMenuBuilder` khi `maybeOf==null` vẫn build menu mặc định (không hook) ⇒ practice không bị đếm, menu không đổi hình thức. KHÔNG bọc thêm `ExamIntegrityScope` ở practice.

### SYMBOL TABLE
| Symbol | Trạng thái | Chữ ký |
| --- | --- | --- |
| `enterExamFullscreen` | [THÊM] | `void enterExamFullscreen()` (web: requestFullscreen; io: no-op) |
| `listenExamFullscreenExit` | [THÊM] | `void Function() listenExamFullscreenExit(void Function() onExit)` |
| `ExamIntegrityScope` | [THÊM] InheritedWidget | `{required VoidCallback reportPaste, required Widget child}` + `maybeOf` |
| `examContextMenuBuilder` | [THÊM] | `Widget Function(BuildContext, EditableTextState)` |
| `reportExamAttemptIntegrity` | [ĐỔI chữ ký] | thêm `bool? fullscreenExited` (datasource/repo/impl) |
| `_flush` | [ĐỔI] | thêm `bool? fullscreenExited` |

---

## 6b. Ràng buộc UI/UX
- Không đổi visual ô nhập; menu chọn văn bản giữ `AdaptiveTextSelectionToolbar` mặc định (chỉ hook callback paste). Fullscreen web: không thêm chrome/nút; im lặng.

## 6. Ràng buộc hiệu năng
- `listenFullscreenExit` gỡ listener trong `dispose` (không leak). `examContextMenuBuilder` chỉ chạy khi mở menu (không trong build thường). `ExamIntegrityScope.updateShouldNotify=false` → không rebuild lan.

---

## 7. Hồi quy tối thiểu + account test
1. **Web (Chrome):** vào bài → (best-effort) fullscreen bật. Bấm ESC/thoát fullscreen → 1 POST `fullscreenExited:true` → (sau WO-1) risk ≥ medium → teacher thấy cờ.
2. **Mobile:** long-press ô writing/dictation/grammar trong bài thi → bấm "Paste" → `copyPasteAttempts` +1 ở backend.
3. **Practice mode (mobile):** long-press → Paste trong `writing_task_page`/`practice_tab` NGOÀI exam → KHÔNG có POST integrity (scope null).
4. Build **Android/iOS** vẫn OK (stub, không kéo `dart:html`).
5. Không paste 2 lần đếm 2 (đúng); fullscreen exit nhiều lần chỉ report 1 (latch client + latch server).

## 8. Lệnh verify
- `cd english_for_community && flutter analyze && flutter test`
- Build web: `flutter build web` (đảm bảo conditional import OK) — hoặc `flutter run -d chrome` smoke fullscreen.
- Build mobile: `flutter build apk --debug` (đảm bảo stub không kéo dart:html).
- (Tùy) widget test: `examContextMenuBuilder` khi có/không `ExamIntegrityScope` → hook/không hook nút paste.

---

## 9. HANDOFF PROMPT (Phase 3)

```text
BƯỚC 0: Đọc trọn docs/plantasks/BUG/20260712-exam-integrity-anticheat-audit/WO-2-client-signals.md. Code lấy từ §5 CONTEXT BUNDLE. File lệch BEFORE → DỪNG, hỏi (doc thắng). Ưu tiên làm SAU WO-1.
Tạo 3 file exam_fullscreen(.dart/_web/_stub) nhái pattern lib/core/util/file_download*. Sửa exam_integrity_tracker.dart (hook fullscreen + ExamIntegrityScope + examContextMenuBuilder + _flush fullscreenExited). Thêm param fullscreenExited xuyên datasource→repo→impl. Thêm contextMenuBuilder: examContextMenuBuilder vào 4 ô input (§5 TS-5).
TUYỆT ĐỐI KHÔNG: thêm package pubspec; import dart:html trực tiếp ngoài file _web; chặn paste (chỉ ghi nhận); đụng backend/teacher UI; bọc ExamIntegrityScope ở practice.
Verify: flutter analyze + test + build web + build apk (stub không kéo dart:html). Practice mode KHÔNG phát integrity.
Xong → self-audit → tracker.md → báo Opus.
```

## 10. Checklist OPUS AUDIT
- [ ] Conditional import đúng: web dùng dart:html, mobile dùng stub (build apk pass).
- [ ] Fullscreen exit → đúng 1 POST `fullscreenExited:true` (latch); listener gỡ ở dispose.
- [ ] `examContextMenuBuilder`: trong exam hook paste, practice no-op (đọc `maybeOf==null`).
- [ ] Menu paste vẫn hoạt động (không chặn); visual không đổi.
- [ ] Param `fullscreenExited` xuyên suốt datasource/repo/impl/_flush khớp.
- [ ] Không thêm package; không import dart:html ngoài _web.
- Verdict: __ APPROVED / CHANGES REQUESTED.
