# WORK-ORDER WO-1 — Correctness & Security chống gian lận

**Task ID:** 20260712-exam-integrity-anticheat-audit / WO-1 · **Loại:** BUG · **Platform:** full-stack (backend + student mobile/web)
**Ngày:** 2026-07-12 · **Nguồn:** `audit.md` finding A1, A2, A5, A6 · **Spec:** `docs/product/bao-cao-nghiep-vu-chong-gian-lan-thi.md` §5
**Ưu tiên:** CAO (lỗ hổng nghiệp vụ)

---

## 1. Vấn đề + nguyên nhân gốc (dẫn chứng code)

| ID | Vấn đề | Root cause |
| --- | --- | --- |
| **A1** | Học sinh (chủ attempt) POST giá trị tuyệt đối → **ghi đè & hạ counter** → reset risk về `low`, xoá bằng chứng. Cũng có thể gửi `fullscreenExited:false` để tắt cờ. Vi phạm §5 "chỉ tăng, không reset". | `examIntegrityService.js:11-12,16-17,21-22` nhánh absolute overwrite; `:26` cho phép set fullscreen về false. Không Zod, controller truyền `req.body` thô (`examStudentController.js:152`). |
| **A2** | Thoát fullscreen KHÔNG nâng risk. Field `fullscreenExited` được lưu nhưng không vào công thức. | `examIntegrityService.js:33-38` công thức risk chỉ dùng `tabs/focus/copy`. |
| **A5** | `tabSwitchCount` đếm gấp đôi trên mobile (một lần rời app đi qua `inactive`→`paused`, mỗi state +1). | `exam_integrity_tracker.dart:48-50` cùng nhánh cho cả `inactive` và `paused`. |
| **A6** | Chỉ đề `integrated_four_skills`/`skills_exam` được giám sát; format khác + legacy runner = không thu tín hiệu. Trái §3.1. | Tracker chỉ bọc trong `IntegratedExamRunnerPage` (`integrated_exam_runner_page.dart:1633`); `ExamRunnerPage` (legacy path) không bọc (`exam_runner_page.dart:682+`). |

---

## 2. Audit downstream

- `mergeIntegrity` là **caller duy nhất** ghi `attempt.integrity`. Không có seed/script nào gửi absolute → **an toàn khi siết chỉ nhận delta / monotonic** (không caller hợp lệ nào bị vỡ). Đã grep: chỉ client datasource gọi endpoint, và chỉ gửi delta (`teacher_exam_remote_datasource.dart:386-398`).
- `riskLevel` được consumer đọc ở: live payload (`examAttemptProgress.js:236`), summary (`examIntegrityService.js:79-81`), audit log gate (`:56`). Đổi công thức (thêm fullscreen) → **các consumer chỉ thấy risk chính xác hơn**, không vỡ shape.
- A5/A6 (client) không đổi payload shape → backend/teacher không ảnh hưởng.

---

## 3. Quyết định thiết kế + cảnh báo

1. **A1 — chống reset (server-side monotonic):** counter chỉ **tăng**. Absolute path dùng `Math.max(cũ, mới)`; delta path cộng dồn (giữ nguyên). `fullscreenExited` **latch OR** (true rồi thì giữ true). Thêm **Zod** validate + **trần trên** mỗi delta để chống spam số khổng lồ.
2. **A2 — tách hàm thuần `computeRiskLevel(...)` export** (phục vụ test B1) và thêm `fullscreenExited` vào nhánh `medium`.
3. **A5 — đếm 1 lần/chu kỳ mất focus:** dùng cờ `_isAway`; chỉ `tabDelta:1` ở lần rời đầu, bỏ qua event lặp cho tới khi `resumed`. Cân nhắc thêm nhánh `AppLifecycleState.hidden`.
4. **A6 — bọc tracker ở legacy runner** (`ExamRunnerPage.build`) khi `status == in_progress` (không bọc khi submitted/expired/review), tương tự cách integrated runner làm. ⚠️ **Chạm là DỪNG & hỏi** nếu legacy runner có cấu trúc `PopScope`/Scaffold khiến việc bọc `ExamIntegrityTracker` ở ngoài cùng gây rebuild lạ — hỏi trước khi refactor sâu.
5. ⚠️ **CẢNH BÁO coupling** (memory `exam-session-presence`): KHÔNG đụng `removeParticipantFromSession`/void-attempt khi làm A6. Chỉ thêm wrapper widget, không chạm luồng session/presence.

---

## 4. Scope IN / OUT

**IN:**
- `english_for_community_backend/src/services/examIntegrityService.js`
- `english_for_community_backend/src/controllers/examStudentController.js` (chỉ nếu cần đấu Zod — ưu tiên validate trong service theo pattern repo)
- `english_for_community/lib/feature/student/exams/exam_integrity_tracker.dart` (A5)
- `english_for_community/lib/feature/student/exams/exam_runner_page.dart` (A6 — bọc tracker legacy)
- Test mới (xem §8).

**OUT (chạm là DỪNG & hỏi):** model schema (`ExamAttempt.js`, sub-schema) — KHÔNG đổi shape; luồng session/presence/void; teacher UI; A3/A4 (thuộc WO-2).

---

## 5. CONTEXT BUNDLE

### TS-1 — `examIntegrityService.js` (A1 + A2): tách `computeRiskLevel` + monotonic + latch + Zod

**file:** `english_for_community_backend/src/services/examIntegrityService.js`
**anchor (import block đầu file):** `import ExamAttempt from '../models/ExamAttempt.js';`
**anchor (hàm merge):** `function mergeIntegrity(prev = {}, patch = {}) {`

**BEFORE (verbatim dòng 1-40):**
```js
import ExamAttempt from '../models/ExamAttempt.js';
import { httpError } from '../utils/AppError.js';
import { classroomActivityService } from './classroomActivityService.js';
import { broadcastAttemptProgress } from './examLiveMonitorService.js';

const RISK_TAB_SWITCHES = 5;
const RISK_FOCUS_LOSS_SEC = 120;

function mergeIntegrity(prev = {}, patch = {}) {
  const out = { ...prev };
  if (patch.tabSwitchCount != null) {
    out.tabSwitchCount = Math.max(0, Number(patch.tabSwitchCount) || 0);
  } else if (patch.tabSwitchDelta != null) {
    out.tabSwitchCount = (Number(out.tabSwitchCount) || 0) + Math.max(0, Number(patch.tabSwitchDelta) || 0);
  }
  if (patch.focusLossSeconds != null) {
    out.focusLossSeconds = Math.max(0, Number(patch.focusLossSeconds) || 0);
  } else if (patch.focusLossDelta != null) {
    out.focusLossSeconds = (Number(out.focusLossSeconds) || 0) + Math.max(0, Number(patch.focusLossDelta) || 0);
  }
  if (patch.copyPasteAttempts != null) {
    out.copyPasteAttempts = Math.max(0, Number(patch.copyPasteAttempts) || 0);
  } else if (patch.copyPasteDelta != null) {
    out.copyPasteAttempts = (Number(out.copyPasteAttempts) || 0) + Math.max(0, Number(patch.copyPasteDelta) || 0);
  }
  if (patch.fullscreenExited != null) out.fullscreenExited = !!patch.fullscreenExited;
  if (patch.lastEventAt != null) out.lastEventAt = patch.lastEventAt;
  else out.lastEventAt = new Date().toISOString();

  const tabs = Number(out.tabSwitchCount) || 0;
  const focus = Number(out.focusLossSeconds) || 0;
  const copy = Number(out.copyPasteAttempts) || 0;
  out.riskLevel =
    tabs >= RISK_TAB_SWITCHES || focus >= RISK_FOCUS_LOSS_SEC || copy >= 3
      ? 'high'
      : tabs >= 2 || focus >= 45 || copy >= 1
        ? 'medium'
        : 'low';
  return out;
}
```

**AFTER / thao tác chính xác:**
```js
import { z } from 'zod';
import ExamAttempt from '../models/ExamAttempt.js';
import { httpError } from '../utils/AppError.js';
import { classroomActivityService } from './classroomActivityService.js';
import { broadcastAttemptProgress } from './examLiveMonitorService.js';

const RISK_TAB_SWITCHES = 5;
const RISK_FOCUS_LOSS_SEC = 120;

// Trần trên per-request để chống spam số khổng lồ (A1/A8). Delta/absolute đều clamp.
const MAX_DELTA = 1000;
const MAX_FOCUS_DELTA = 3600; // 1h/lần report là dư

// Zod: chấp nhận delta HOẶC absolute; số không âm, có trần. (A1/A8)
const integrityPatchSchema = z.object({
  tabSwitchDelta: z.number().int().min(0).max(MAX_DELTA).optional(),
  focusLossDelta: z.number().int().min(0).max(MAX_FOCUS_DELTA).optional(),
  copyPasteDelta: z.number().int().min(0).max(MAX_DELTA).optional(),
  tabSwitchCount: z.number().int().min(0).optional(),
  focusLossSeconds: z.number().int().min(0).optional(),
  copyPasteAttempts: z.number().int().min(0).optional(),
  fullscreenExited: z.boolean().optional(),
  lastEventAt: z.string().optional(),
}).strip();

// Hàm THUẦN (export để test B1) — công thức risk KHỚP spec §5 (đã thêm fullscreenExited vào medium — A2).
export function computeRiskLevel({ tabSwitchCount = 0, focusLossSeconds = 0, copyPasteAttempts = 0, fullscreenExited = false } = {}) {
  const tabs = Number(tabSwitchCount) || 0;
  const focus = Number(focusLossSeconds) || 0;
  const copy = Number(copyPasteAttempts) || 0;
  if (tabs >= RISK_TAB_SWITCHES || focus >= RISK_FOCUS_LOSS_SEC || copy >= 3) return 'high';
  if (tabs >= 2 || focus >= 45 || copy >= 1 || !!fullscreenExited) return 'medium';
  return 'low';
}

// MONOTONIC merge (A1): counter chỉ tăng; absolute -> max(cũ, mới); fullscreen latch OR. Export để test B2.
export function mergeIntegrity(prev = {}, patch = {}) {
  const out = { ...prev };
  const prevTab = Number(out.tabSwitchCount) || 0;
  const prevFocus = Number(out.focusLossSeconds) || 0;
  const prevCopy = Number(out.copyPasteAttempts) || 0;

  if (patch.tabSwitchDelta != null) out.tabSwitchCount = prevTab + Math.max(0, Number(patch.tabSwitchDelta) || 0);
  else if (patch.tabSwitchCount != null) out.tabSwitchCount = Math.max(prevTab, Math.max(0, Number(patch.tabSwitchCount) || 0));

  if (patch.focusLossDelta != null) out.focusLossSeconds = prevFocus + Math.max(0, Number(patch.focusLossDelta) || 0);
  else if (patch.focusLossSeconds != null) out.focusLossSeconds = Math.max(prevFocus, Math.max(0, Number(patch.focusLossSeconds) || 0));

  if (patch.copyPasteDelta != null) out.copyPasteAttempts = prevCopy + Math.max(0, Number(patch.copyPasteDelta) || 0);
  else if (patch.copyPasteAttempts != null) out.copyPasteAttempts = Math.max(prevCopy, Math.max(0, Number(patch.copyPasteAttempts) || 0));

  // Latch: đã thoát fullscreen thì giữ true (§5). Không cho set về false.
  if (patch.fullscreenExited === true) out.fullscreenExited = true;
  else out.fullscreenExited = !!out.fullscreenExited;

  out.lastEventAt = patch.lastEventAt != null ? patch.lastEventAt : new Date().toISOString();
  out.riskLevel = computeRiskLevel(out);
  return out;
}
```
**GOTCHA:** giữ nguyên tên field trong `out` (schema Mongoose không đổi). `reportForStudent` phải validate `patch` qua `integrityPatchSchema` TRƯỚC khi gọi `mergeIntegrity` — xem TS-2.

### TS-2 — `examIntegrityService.js` `reportForStudent`: đấu Zod

**anchor:** `async reportForStudent(userId, attemptId, patch = {}) {`
**BEFORE (verbatim dòng 52-54):**
```js
    const prev = attempt.integrity && typeof attempt.integrity === 'object' ? attempt.integrity : {};
    attempt.integrity = mergeIntegrity(prev, patch);
    await attempt.save();
```
**AFTER:**
```js
    const parsed = integrityPatchSchema.safeParse(patch || {});
    if (!parsed.success) throw httpError(400, 'Invalid integrity payload');
    const prev = attempt.integrity && typeof attempt.integrity === 'object' ? attempt.integrity : {};
    attempt.integrity = mergeIntegrity(prev, parsed.data);
    await attempt.save();
```
**GOTCHA:** giữ nguyên ownership check (`:49`) + status guard (`:50`) phía trên — KHÔNG đụng.

### TS-3 — `exam_integrity_tracker.dart` (A5): đếm 1 lần/chu kỳ mất focus

**file:** `english_for_community/lib/feature/student/exams/exam_integrity_tracker.dart`
**anchor:** `void didChangeAppLifecycleState(AppLifecycleState state) {`
**BEFORE (verbatim dòng 21-58):**
```dart
class _ExamIntegrityTrackerState extends State<ExamIntegrityTracker> with WidgetsBindingObserver {
  DateTime? _unfocusedAt;
  ...
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _unfocusedAt = DateTime.now();
      _flush(tabDelta: 1);
    } else if (state == AppLifecycleState.resumed && _unfocusedAt != null) {
      final sec = DateTime.now().difference(_unfocusedAt!).inSeconds;
      if (sec > 0) {
        _flush(focusDelta: sec);
      }
      _unfocusedAt = null;
    }
  }
```
**AFTER:**
```dart
class _ExamIntegrityTrackerState extends State<ExamIntegrityTracker> with WidgetsBindingObserver {
  DateTime? _unfocusedAt;
  bool _isAway = false; // A5: chống đếm gấp đôi qua inactive->paused
  ...
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
```
**GOTCHA:** không đụng `_onKey` (copy-paste) và `build`. WO-2 sẽ thêm fullscreen ở cùng file → giữ diff A5 gọn để tránh xung đột.

### TS-4 — `exam_runner_page.dart` (A6): bọc tracker cho legacy runner

**file:** `english_for_community/lib/feature/student/exams/exam_runner_page.dart`
**anchor:** `return PopScope<Object?>(`
**BEFORE (verbatim dòng 683-705):**
```dart
    final flat = _flatItems();
    final status = _attempt?['status'] as String? ?? '';
    final submitted = status == 'submitted';
    final expired = status == 'expired';
    final remaining = _remainingLabel(l10n);
    final locked = submitted || expired;
    final lastIndex = flat.isEmpty ? 0 : flat.length - 1;

    return PopScope<Object?>(
      canPop: !_blocksExitConfirm(),
      onPopInvokedWithResult: (didPop, _) {
        ...
      child: Scaffold(
```
**AFTER / thao tác:** bọc `PopScope` bằng `ExamIntegrityTracker` khi đang thi. Gán kết quả `PopScope` vào biến `final Widget runner = PopScope<Object?>(...);` rồi:
```dart
    final Widget runner = PopScope<Object?>( /* ... giữ nguyên ... */ );
    if (status == 'in_progress') {
      return ExamIntegrityTracker(attemptId: widget.attemptId, child: runner);
    }
    return runner;
```
**Import cần thêm:** `import 'package:english_for_community/feature/student/exams/exam_integrity_tracker.dart';` (kiểm tra path package thật trong file — dùng cùng style import các file exams khác).
**GOTCHA:** chỉ bọc khi `status == 'in_progress'` (không bọc submitted/expired). KHÔNG đụng nhánh integrated (dòng 675-681) — nó đã có tracker riêng, tránh double-wrap.

### SYMBOL TABLE

| Symbol | Trạng thái | Chữ ký / giá trị |
| --- | --- | --- |
| `computeRiskLevel` | [THÊM] export | `({tabSwitchCount, focusLossSeconds, copyPasteAttempts, fullscreenExited}) => 'low'|'medium'|'high'` |
| `mergeIntegrity` | [ĐỔI] private→export | `(prev, patch) => integrityObject` (monotonic) |
| `integrityPatchSchema` | [THÊM] | Zod object `.strip()` |
| `examIntegrityService.reportForStudent` | [CÓ] giữ chữ ký | `(userId, attemptId, patch)` |
| `ExamIntegrityTracker` | [CÓ] | `ExamIntegrityTracker({required attemptId, required child})` |
| `_isAway` | [THÊM] field | `bool` |
| ngưỡng risk | [CÓ] | tab 5/2 · focus 120/45 · copy 3/1 · fullscreen→medium |

### CLONE-THIS
- Zod trong service: nhái `teacherExamAssignmentService.js` (đã import `zod`, pattern `schema.safeParse`).
- Bọc tracker: nhái `integrated_exam_runner_page.dart:1632-1635`.

---

## 6c. Ràng buộc backend (BACKEND GATE)
- Logic ở service (đã đúng), controller vẫn mỏng. Validate Zod trong service (`reportForStudent`) theo pattern repo. Không N+1 mới. Không đổi index/schema.

## 6. Ràng buộc hiệu năng
- Không ảnh hưởng: A5 giảm số POST (bớt double event). A6 chỉ thêm 1 widget wrapper. `computeRiskLevel` O(1).

---

## 7. Hồi quy tối thiểu + account test
1. Thi integrated (mobile): rời app 1 lần → backend `tabSwitchCount` +1 (KHÔNG +2). Quay lại → `focusLossSeconds` cộng đúng.
2. Web: gửi `fullscreenExited:true` (giả lập) → risk ≥ `medium`. Gửi lại `fullscreenExited:false` → vẫn giữ (latch).
3. Gửi `{tabSwitchCount:0}` sau khi đã có tab=3 → counter **vẫn 3** (monotonic), risk không hạ.
4. Thi legacy format (non-integrated) → có ghi nhận tín hiệu (trước đây = 0).
5. Payload rác (`tabSwitchDelta:-5` hoặc `99999999`) → Zod chặn/clamp, không lỗi 500.
- Account test: `docs/dev/seeds/` (tài khoản student + teacher + 1 assignment).

## 8. Lệnh verify
- Backend: `cd english_for_community_backend && npm test` — thêm test **B1** (`computeRiskLevel` boundary + fullscreen→medium) và **B2** (`mergeIntegrity` monotonic/không-reset + latch). Đặt file `src/services/examIntegrityService.test.js` (co-located, `node --test`, pure — KHÔNG mock DB).
- Frontend: `cd english_for_community && flutter analyze && flutter test` — thêm **B5** widget test `ExamIntegrityTracker` (giả lập lifecycle, verify không double-count; inject mock `TeacherExamRepository` qua get_it).

### Gợi ý test case B1/B2 (đóng đinh spec)
- B1: tab {1→low,2→medium,4→medium,5→high}; focus {44→low,45→medium,119→medium,120→high}; copy {0→low,1→medium,2→medium,3→high}; `{fullscreenExited:true}` mọi counter 0 → `medium`.
- B2: delta cộng dồn; absolute nhỏ hơn KHÔNG hạ; `fullscreenExited:false` sau true → vẫn true.

---

## 9. HANDOFF PROMPT (Phase 3 — copy cho Cursor)

```text
BƯỚC 0: Đọc trọn work-order docs/plantasks/BUG/20260712-exam-integrity-anticheat-audit/WO-1-correctness-security.md. Code lấy từ §5 CONTEXT BUNDLE, không tự grep đoán. File thật lệch BEFORE → DỪNG, hỏi (doc thắng).
Sửa ĐÚNG 4 file IN (§4): examIntegrityService.js (A1+A2 export computeRiskLevel/mergeIntegrity + Zod), exam_integrity_tracker.dart (A5 _isAway + hidden), exam_runner_page.dart (A6 bọc tracker khi in_progress). Ngoài danh sách → DỪNG & hỏi.
TUYỆT ĐỐI KHÔNG: đổi schema ExamAttempt/sub-schema; đụng ownership/status guard; đụng removeParticipantFromSession/void; đổi public signature reportForStudent; hardcode.
Backend: Zod validate trong service (pattern teacherExamAssignmentService.js). Controller giữ mỏng.
Thêm test B1+B2 (backend pure, node --test) + B5 (flutter widget). Verify: npm test + flutter analyze + flutter test.
Xong → self-audit (file đổi · rủi ro · checklist) → dán tracker.md → báo Opus audit.
```

## 10. Checklist OPUS AUDIT (Phase 4)
- [ ] `computeRiskLevel` KHỚP §5 (fullscreen→medium) + export; `mergeIntegrity` monotonic (không hạ) + latch fullscreen.
- [ ] Zod chặn payload rác; ownership/status guard còn nguyên; schema không đổi.
- [ ] A5: 1 tab/chu kỳ (đọc diff `_isAway`); có `hidden`.
- [ ] A6: legacy runner bọc tracker chỉ khi in_progress, không double-wrap integrated.
- [ ] Test B1/B2 pass + cover boundary; B5 chứng minh không double-count.
- [ ] No regression: attempt nộp/expired vẫn từ chối ghi (400).
- Verdict: __ APPROVED / CHANGES REQUESTED.
