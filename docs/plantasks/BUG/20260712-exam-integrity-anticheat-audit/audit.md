# AUDIT — Chống gian lận khi thi (Exam Integrity / Proctoring)

**Task ID:** 20260712-exam-integrity-anticheat-audit · **Loại:** BUG (audit) · **Platform:** full-stack
**Ngày:** 2026-07-12 · **Người audit:** Opus (bộ não) · **Trạng thái:** ✅ DONE — 3 WO đã IMPLEMENT + AUDIT (Opus tự code), backend 102/102 + frontend 38/38, chưa commit (xem `tracker.md`)
**Đối chiếu spec:** `docs/product/bao-cao-nghiep-vu-chong-gian-lan-thi.md` (v1.0, tuyên bố "phản ánh hành vi thực tế")

> Phạm vi audit: (A) tính đúng chống gian lận web + mobile, (B) độ phủ automation test, (C) luồng hiển thị báo cáo cheat/risk cho giáo viên. Mọi kết luận đã verify bằng code thật (file:line dán kèm).

---

## 0. Verdict tổng

Kiến trúc **đúng hướng** (thu tín hiệu ở client → cộng dồn + tính risk ở backend → realtime cho teacher + audit log). Nhưng **spec v1.0 mô tả nhiều hành vi mà code CHƯA có/không khớp** — spec đang "lạc quan hơn" thực tế. Có **1 lỗ hổng nghiệp vụ mức cao** (học sinh tự xoá được bằng chứng), **2 tín hiệu trong spec không tồn tại ở client** (fullscreen, paste mobile), **độ phủ test ~0**, và **luồng report cho giáo viên mới dừng ở cờ/mức** (thiếu chi tiết per-student + bảng per-assignment dù API đã sẵn).

| Nhóm | Kết luận |
| --- | --- |
| A. Correctness web + mobile | 2 finding CAO + 1 CAO client-gap + 1 CAO mobile-gap + 3 TB/thấp |
| B. Automation test | Gần như chưa có; `mergeIntegrity` pure nhưng không export → chưa test được |
| C. Report cho giáo viên | Live monitor: chỉ cờ/mức. Per-assignment summary: API chết. Chi tiết per-student: l10n key chết |

---

## 1. Bản đồ kiến trúc (ground-truth)

```
STUDENT (Flutter, mobile+web)                 BACKEND (Node)                          TEACHER (Flutter web)
exam_integrity_tracker.dart                   POST /exams/attempts/:id/integrity      teacher_live_monitor_panel.dart
  - AppLifecycleState → tab+focus     ──►     examStudentController.reportExam...     - cờ ⚑ high/medium + tooltip
  - HardwareKeyboard Ctrl+C/V → copy          examIntegrityService.reportForStudent   - chip "Flagged" (high+medium)
  (KHÔNG fullscreen, KHÔNG paste-menu)          · ownership + status guard            - nút "Xem màn hình" (mirror)
        │ deltas only                            · mergeIntegrity() → riskLevel        - realtime patch tile theo userId
        ▼                                        · log 'integrity_flag' nếu high      teacher_analytics_page.dart
  reportExamAttemptIntegrity()                   · broadcastAttemptProgress()  ──►     - chips high/med/low (period, toàn GV)
  (teacher_exam_remote_datasource.dart:386)     socket: exam_assignment_progress /    - reason rows tab/copy/fullscreen
                                                 exam_session_live_screen             API integrity-summary/:assignmentId
                                                                                       ↑ CÓ 3 tầng data — KHÔNG UI nào gọi
```

**Điểm neo code:**
- Client tracker: `lib/feature/student/exams/exam_integrity_tracker.dart` (toàn file, 76 dòng)
- Bọc tracker: `lib/feature/student/exams/integrated_exam_runner_page.dart:1633` (chỉ integrated/skills)
- Gating format: `lib/feature/student/exams/exam_runner_page.dart:675-681`
- Gửi tín hiệu: `lib/core/datasource/teacher_exam_remote_datasource.dart:386-398`
- Backend service: `english_for_community_backend/src/services/examIntegrityService.js` (toàn file, 86 dòng)
- Model: `src/models/sub/examAttemptSubSchemas.js:22-32` + `src/models/ExamAttempt.js:25`
- Route: `src/routes/examRoutes.js:27` + controller `src/controllers/examStudentController.js:147-158`
- Live monitor UI: `lib/feature/teacher/widgets/teacher_live_monitor_panel.dart:253,289-304`
- Derived flagged: `lib/feature/teacher/bloc/live_monitor/teacher_live_monitor_derived.dart:69-71`
- Analytics UI: `lib/feature/teacher/teacher_analytics_page.dart:1508-1553`
- API assignment-summary (chết): `teacher_exam_remote_datasource.dart:443-446` (+ repo:102, impl:949)

---

## 2. PHẦN A — Correctness chống gian lận (web + mobile)

| ID | Mức | Finding | Bằng chứng | Hướng sửa |
| --- | --- | --- | --- | --- |
| **A1** | 🔴 CAO | **Học sinh tự reset được bằng chứng.** Endpoint chấp nhận cả giá trị tuyệt đối; `mergeIntegrity` OVERWRITE khi nhận absolute. Không Zod, controller truyền `req.body` thô. Chủ nhân attempt (qua ownership check) POST `{tabSwitchCount:0, focusLossSeconds:0, copyPasteAttempts:0, fullscreenExited:false}` → risk về `low`, xoá dấu vết. Vi phạm §5 "chỉ tăng, không reset". | `examIntegrityService.js:11-12,16-17,21-22,26` (nhánh absolute overwrite); controller `examStudentController.js:152` (body thô) | Server-side: chỉ nhận **delta** từ client (bỏ nhánh absolute), HOẶC absolute chỉ áp `Math.max(cũ, mới)` (monotonic). Thêm Zod + trần trên mỗi delta. |
| **A2** | 🔴 CAO | **`fullscreenExited` KHÔNG tham gia tính risk.** Spec §5: fullscreen → tối thiểu `medium`. Code chỉ lưu field, công thức risk (dòng 33-38) chỉ dùng tabs/focus/copy. → Thoát fullscreen đơn thuần vẫn `low`. | `examIntegrityService.js:33-38` (không có `fullscreenExited` trong công thức) | Thêm `|| out.fullscreenExited` vào nhánh `medium`. |
| **A3** | 🔴 CAO | **Tín hiệu fullscreen KHÔNG tồn tại ở client.** Không có code ép fullscreen, không phát hiện thoát fullscreen (không `dart:html`/`package:web`, không `kIsWeb`). Signal #4 của spec là "hư cấu" — analytics có hàng "Exited fullscreen" nhưng **luôn = 0**. Web đáng lẽ là nơi tín hiệu này mạnh nhất (§4). | Toàn `exam_integrity_tracker.dart` không có fullscreen; teacher UI đọc `fullscreenExited` chỉ để hiển thị (`teacher_analytics_page.dart:1513,1552`) | Implement web: bật fullscreen ở nút Bắt đầu + lắng `fullscreenchange` phát hiện thoát (guard `kIsWeb`, dùng `package:web`/`dart:js_interop`) → gửi `fullscreenExited:true`. |
| **A4** | 🔴 CAO | **Copy-paste KHÔNG bắt được trên mobile.** Client chỉ bắt Ctrl+C/V qua `HardwareKeyboard`. Mobile không bàn phím cứng → signal 3 = 0. Spec §4 nói mobile bắt qua menu long-press "Paste". | `exam_integrity_tracker.dart:60-67` (chỉ `HardwareKeyboard.isControlPressed`) | Thêm `contextMenuBuilder`/`onPaste` (hoặc `AdaptiveTextSelectionToolbar` + `PasteTextIntent`) trên các ô nhập bài thi → đếm paste trên touch. |
| **A5** | 🟠 TB | **`tabSwitchCount` double-count trên mobile.** `didChangeAppLifecycleState` xử lý cả `inactive` VÀ `paused` cùng `_flush(tabDelta:1)`. Một lần rời app thường đi qua inactive→paused (2 event) → **+2**. Ngưỡng risk (tab≥2 medium, tab≥5 high) → risk bị thổi phồng. Thiếu nhánh `AppLifecycleState.hidden` (web/desktop mới map sang hidden). | `exam_integrity_tracker.dart:48-50` | Đếm 1 lần mỗi chu kỳ mất focus (cờ `_isAway`; +1 khi vừa rời, bỏ qua event lặp cho tới khi resumed). Cân nhắc thêm `hidden`. |
| **A6** | 🟠 TB | **Chỉ đề integrated/skills được giám sát.** Tracker chỉ bọc `IntegratedExamRunnerPage`; runner chỉ route sang đó cho `integrated_four_skills`/`skills_exam`. Format đề khác + lobby = **không thu tín hiệu nào**. Trái §3.1 "áp dụng cho mọi loại đề". | `integrated_exam_runner_page.dart:1633`; `exam_runner_page.dart:675-681` | Bọc `ExamIntegrityTracker` ở lớp runner chung (cả legacy/flat format), gate theo `status == in_progress`. |
| **A7** | 🟢 Thấp | **Mất event best-effort.** `_flush` khi `inactive` gửi POST async lúc app sắp bị OS freeze → có thể mất. focus <1s bị bỏ (`sec>0`). Không debounce (mỗi event 1 POST). | `exam_integrity_tracker.dart:36-58` | (Chấp nhận theo §9.2) hoặc queue local + retry khi resume; gộp delta khi dồn event. |
| **A8** | 🟢 Thấp | **Thiếu Zod + trần trên; `lastEventAt` là String.** Không giới hạn giá trị (một phần của A1); `lastEventAt` String khó query theo thời gian. Field lạ KHÔNG inject được (mergeIntegrity chỉ copy key đã biết) → không phải lỗ hổng. | `examIntegrityService.js:27-28`; controller không có Zod | Zod schema cho payload; đổi `lastEventAt` sang Date nếu cần query. |
| **A9** | 🟢 Thấp | **Audit log chỉ khi high + có classroomId.** Đề `public_link` (không classroom) không lưu vết; risk `medium` không log. | `examIntegrityService.js:56-67` | (Tuỳ nghiệp vụ) log cả medium hoặc gắn flag ở attempt để rà soát đề public. |

> **Điểm KHỚP spec (giữ nguyên, không đụng):** ownership guard (`:49`) + status guard (`:50`); ngưỡng `high` (tab≥5 / focus≥120 / copy≥3) và các ngưỡng `medium` phần tabs/focus/copy; cộng dồn delta + clamp ≥0; realtime piggyback trên progress; index `ExamAttempt` cho query summary.

---

## 3. PHẦN B — Automation test (chỗ cần & đề xuất)

**Hiện trạng:** độ phủ ~0.
- Backend: chỉ 1 test map field `buildAttemptLiveProgressRow includes integrity fields` (`src/tests/examRealtime.e2e.test.js`) — truyền `riskLevel:'high'` cứng, **không** test công thức tính risk.
- Frontend: `test/teacher_analytics_content_test.dart` chỉ test layout không overflow, integrity là mock, **không assert**.
- `mergeIntegrity` là hàm **pure nhưng không export** → chưa test được dạng pure. `teacher_live_monitor_derived.dart` pure, dễ test, chưa có test.
- Chạy: backend `node --test` (co-located `*.test.js`); frontend `flutter test`. Không có mock DB → phải test hàm thuần (khớp memory `test-conventions`).

**Đề xuất bộ test (ưu tiên từ trên xuống):**

| ID | Loại | Nội dung | Điều kiện tiên quyết |
| --- | --- | --- | --- |
| **B1** | backend pure | Boundary công thức risk: tab {1→low,2→med,4→med,5→high}; focus {44→low,45→med,119→med,120→high}; copy {0→low,1→med,2→med,3→high}; **fullscreenExited=true + mọi counter=0 → medium** (đóng đinh A2). | Tách/export `computeRiskLevel(...)` hoặc export `mergeIntegrity` |
| **B2** | backend pure | Cộng dồn delta + clamp ≥0; **(sau A1) absolute nhỏ hơn KHÔNG hạ counter** (chống reset). | như B1 |
| **B3** | backend pure | Đếm summary high/medium/total từ list attempt (tách hàm đếm thuần khỏi query DB). | tách `countRisk(attempts)` |
| **B4** | frontend pure | `teacher_live_monitor_derived.dart`: `summaryFromLiveMonitorStudents` đếm flagged = high+medium; `filterLiveMonitorStudents(flagged)`; `liveMonitorRowVisualChanged` phản ứng khi `integrityRiskLevel` đổi. | không (pure sẵn) |
| **B5** | frontend widget | `ExamIntegrityTracker`: giả lập lifecycle inactive→resumed → verify gọi `reportExamAttemptIntegrity` đúng delta; đóng đinh **không double-count** (A5). | inject repo mock qua get_it |
| **B6** | frontend widget | `teacher_live_monitor_panel`: risk high/medium render cờ + tooltip; nút "Xem màn hình" hiện khi in_progress. | mock state |

> Ưu tiên **B1 + B2 + B4** trước (pure, rẻ, chốt nghiệp vụ + chống regression cho các fix A1/A2).

---

## 4. PHẦN C — Luồng hiển thị báo cáo cheat/risk cho giáo viên

### C1. Live Monitor (giám sát trực tiếp) — CÓ, nhưng chỉ cờ/mức
- Cờ ⚑ + tooltip mức per-student khi high/medium (`teacher_live_monitor_panel.dart:289-295`), màu theo mức (`:37-46`).
- Chip đếm "Flagged" = high+medium (`teacher_live_monitor_derived.dart:69-71`; panel `:127-131`) + filter Flagged.
- Nút "Xem màn hình" mở mirror (`:296-304`) — nhưng **mirror KHÔNG hiển thị integrity** (chỉ soi đáp án).
- Realtime **patch tile theo userId** khi `integrityRiskLevel` đổi (`teacher_live_monitor_bloc.dart:178-201`), `RepaintBoundary` + `ValueKey` → perf tốt.
- ⚠️ **GAP:** không hiển thị **số liệu chi tiết per-student** (số lần rời tab / giây focus / số paste). Đã có sẵn 4 l10n key (`teacherLiveMonitorTabSwitches/FocusLoss/CopyPaste/IntegrityLabel`, EN+VI) nhưng **chết** (chỉ được tham chiếu trong `l10n/generated/*`). Đúng là đề xuất "Cao" ở spec §10.

### C2. Analytics (thống kê) — CÓ, nhưng tổng hợp thô
- Chips high/medium/low (`teacher_analytics_page.dart:1508-1534`) + reason rows tab/copy/fullscreen (`:1548-1553`, dạng "N×").
- ⚠️ Chỉ **tổng hợp dashboard-wide theo period**, **không per-assignment, không per-student**. Reason "Exited fullscreen" **luôn 0** (do A3).

### C3. Assignment Summary (per-bài-giao) — API CHẾT
- Đủ 3 tầng data: `teacher_exam_remote_datasource.dart:443-446`, `teacher_exam_repository.dart:102`, `...impl.dart:949-951`. Backend `GET /teacher/exams/assignments/:id/integrity-summary` trả `{high, medium, total}`.
- ⚠️ **KHÔNG UI/bloc nào gọi** (grep `getAssignmentIntegritySummary` trong `lib/feature` = 0). Spec §7.2 mô tả tính năng này nhưng **chưa có màn hiển thị**. `teacher_classroom_detail_page` không có gì về integrity.

### C4. Audit trail — backend ghi, cần verify UI
- Backend ghi `ClassroomActivityLog` type `integrity_flag` khi high (`examIntegrityService.js:56-67`). **Cần kiểm tra** UI nhật ký hoạt động lớp có render dòng `integrity_flag` không (chưa scout — TODO nếu làm work-order C).

### C5. Data-shape — Map thô, không typed
- Roster live monitor là `List<Map<String,dynamic>>`, đọc `student['integrityRiskLevel']` bằng key string; không có entity typed. Dễ vỡ khi đổi key (đúng style hiện tại của repo — minor).

**Kết luận C:** giáo viên hiện chỉ thấy **cờ + mức realtime** và **tổng hợp thô theo period**. Thiếu: chi tiết per-student (C1 gap), bảng summary per-assignment (C3 — API sẵn), fullscreen luôn rỗng (do A3).

---

## 5. Đề xuất chuyển thành work-order (3 nhóm độc lập)

| Nhóm | Nội dung | Ưu tiên | Ghi chú |
| --- | --- | --- | --- |
| **WO-1 Correctness/Security** | A1 (chống reset) + A2 (fullscreen vào risk) + A5 (double-count) [+ A6 mở rộng format] | CAO | Fix backend + client; kèm B1/B2/B5 để chống regression |
| **WO-2 Client signals đầy đủ** | A3 (web fullscreen enter/exit) + A4 (mobile paste-menu) | CAO/TB | Chạm platform-specific (`kIsWeb`, `package:web`, contextMenu); có thể tách riêng web vs mobile |
| **WO-3 Teacher report** | C1 (chi tiết per-student — l10n key đã sẵn) + C3 (đấu API assignment-summary vào UI) + C4 (verify audit-log UI) | TB | Thuần UI teacher web; API C3 đã có sẵn nên rẻ |
| **WO-Test** | B1–B6 (có thể gộp vào từng WO trên hoặc làm 1 batch) | CAO cho B1/B2/B4 | Theo `test-conventions` |

---

## 6. Lệnh verify (khi implement)

- Backend: `cd english_for_community_backend && npm test` (`node --test`).
- Frontend: `cd english_for_community && flutter analyze && flutter test`.
- L10n (nếu thêm string): `flutter gen-l10n` (EN + VI).
- Smoke: (a) thi integrated trên mobile → rời app → teacher thấy cờ; (b) thi trên web → thoát fullscreen → risk lên medium (sau A2/A3); (c) POST absolute reset → bị từ chối/không hạ (sau A1).

---

## 7. Nhật ký audit

- 2026-07-12 — Opus PHÂN TÍCH: delegate 4 scout (client/backend/teacher/test), Opus tự đọc `examIntegrityService.js` + `exam_integrity_tracker.dart` + verify grep (assignment-summary unused, tracker chỉ bọc integrated, gating format). Ra 9 finding A + 6 đề xuất test B + bản đồ report C. Chờ user chọn WO để viết CONTEXT BUNDLE.
