# WORK-ORDER — Live monitor (admin/teacher) không bám câu hỏi hiện tại của học sinh

| | |
|---|---|
| **Task ID** | `20260701-live-monitor-current-question-stale` |
| **Loại** | BUG |
| **Platform** | teacher web (admin dùng chung `TeacherExamSessionConsolePage` → tab **Live monitor**) |
| **Cỡ** | MICRO (1 file, ~6 dòng) |
| **Mục tiêu** | Ô số câu hỏi đang tô đậm (current) trong lưới Live monitor phải cập nhật realtime theo đúng câu học sinh đang làm, không đứng yên ở câu 1. |
| **Kỳ vọng đầu ra** | `dart analyze` 0 lỗi · học sinh chuyển câu → ô tô đậm trong Live monitor đổi theo trong vài giây (qua socket, không cần refresh tab) · không regression `progressPercent`/`answeredCount`/status. |
| **Trạng thái** | 📝 Work-order sẵn sàng — chờ implement |

---

## 1. Vấn đề + nguyên nhân gốc (dẫn chứng code)

### Triệu chứng (user, ảnh đính kèm)
- Tab **Live monitor** (`teacher_exam_session_console_page.dart` → `TeacherLiveMonitorPanel`): lưới câu hỏi theo section (Grammar 1–30, Reading 1–4, …) có 1 ô viền đậm = "câu hiện tại". Ô này **đứng yên ở câu 1** dù học sinh đã làm sang câu khác.
- Đối chứng: màn **live mirror** (`student_exam_live_mirror_view.dart`, xem qua icon 👁 Watch) hiển thị **đúng** câu học sinh đang ở (vd Question 5/30) → chứng minh server/socket đã gửi đúng dữ liệu, lỗi nằm ở phía Live monitor grid.

### Data flow — xác nhận socket đã đúng, cache phía client mới sai

1. **Ô "current" đọc từ đâu:**
   `lib/feature/teacher/widgets/teacher_exam_question_strip.dart:88` (và `:239` cho listening sub-strip):
   ```dart
   final selected = currentQuestionIndex != null && currentQuestionIndex == i;
   ```
   `currentQuestionIndex` lấy từ `strip['currentQuestionIndex']` (`:164`, `:216`) — field nằm trong từng phần tử `skillStrips`.

2. **`skillStrips` RAW được socket cập nhật đúng:**
   `lib/feature/teacher/bloc/live_monitor/teacher_live_monitor_bloc.dart:50-52` (`mergeTeacherLivePayload`):
   ```dart
   if (patch['skillStrips'] is List) {
     merged['skillStrips'] = patch['skillStrips'];
   }
   ```
   Bloc lắng `exam_session_live_progress` / `exam_session_live_screen` (`:155-156`) → `_onProgress` (`:179-202`) merge patch mới nhất vào `state.students[idx]`. **`skillStrips` raw luôn tươi.**

3. **BUG — cache `_parsedSkillStrips` không bao giờ invalidate:**
   `lib/feature/teacher/bloc/live_monitor/teacher_live_monitor_derived.dart:86-93`:
   ```dart
   Map<String, dynamic> enrichLiveMonitorStudentRow(Map<String, dynamic> row) {
     final next = Map<String, dynamic>.from(row);
     if (next['skillStrips'] is List && next['_parsedSkillStrips'] == null) {
       next['_parsedSkillStrips'] =
           TeacherExamQuestionStripSection.parseStrips(next['skillStrips']);
     }
     return next;
   }
   ```
   Hàm này được gọi ở **mọi** lần emit (`teacher_live_monitor_bloc.dart:82`: `students.map(enrichLiveMonitorStudentRow)`), kể cả sau socket merge. Nhưng `list[idx]` truyền vào `_mergeStudentLiveRow` (`:190-191`) đã là row **đã enrich từ lần trước** (có sẵn `_parsedSkillStrips` khác `null`). `mergeTeacherLivePayload` chỉ spread `{...prev, ...patch}` (`:14`) — patch (payload socket) không có key `_parsedSkillStrips` nên **giá trị cũ sống sót nguyên vẹn** qua merge. Guard `next['_parsedSkillStrips'] == null` ở bước enrich sau đó luôn `false` → **không bao giờ parse lại**, dù `skillStrips` raw đã đổi.

4. **Widget đọc đúng cache đã cũ (không có đường fallback):**
   `lib/feature/teacher/widgets/teacher_live_monitor_panel.dart:256-259`:
   ```dart
   final cached = student['_parsedSkillStrips'];
   final strips = cached is List<Map<String, dynamic>>
       ? cached
       : TeacherExamQuestionStripSection.parseStrips(student['skillStrips']);
   ```
   Vì `cached` sau lần đầu luôn là `List<Map<String, dynamic>>` non-null → nhánh fallback `parseStrips(student['skillStrips'])` (mới) **không bao giờ được chạy lại**. Đây là lý do `currentQuestionIndex` đứng yên ở snapshot đầu tiên (thường là câu 1), trong khi `progressPercent`/`answeredCount` (đọc field top-level trực tiếp, không qua cache) vẫn cập nhật bình thường — khớp đúng triệu chứng user mô tả.

### Đối chứng: vì sao live mirror KHÔNG bị lỗi này
`lib/feature/teacher/bloc/student_live_screen/teacher_student_live_screen_bloc.dart:78` cũng gọi `mergeTeacherLivePayload` y hệt, nhưng KHÔNG có lớp cache derive nào — `student_exam_live_mirror_view.dart:234,254` gọi thẳng `TeacherExamQuestionStripSection.parseStrips(widget.liveScreen['skillStrips'])` **trong `build()`** mỗi lần render → luôn tươi. Đây là bằng chứng cache là nguyên nhân duy nhất, không phải lỗi truyền dữ liệu.

---

## 2. Audit downstream (consumer dùng chung)

| Consumer | Đọc `_parsedSkillStrips`? | Ảnh hưởng khi sửa |
|---|---|---|
| `teacher_live_monitor_panel.dart:256-259` (`_StudentMonitorTile`) | ✅ đọc cache | Sẽ nhận cache **luôn tươi** sau fix — đây là mục tiêu. |
| `teacher_live_monitor_derived.dart` — `liveMonitorRowVisualChanged`/`_rosterUiPatchKeys` | ❌ không tham chiếu `_parsedSkillStrips`/`_parsedSkillStripsSource` (chỉ so `status/progressPercent/answeredCount/totalItems/integrityRiskLevel/skillStrips/fullName/email/username/attemptId`) | Không đổi hành vi so sánh — thêm field mới không ảnh hưởng dedup/`_sameEnrichedRoster`. |
| `mergeTeacherLivePayload` (`teacher_live_monitor_bloc.dart:10-54`) | dùng chung bởi **2 bloc**: `TeacherLiveMonitorBloc` (`:139`) và `TeacherStudentLiveScreenBloc` (`student_live_screen/teacher_student_live_screen_bloc.dart:78`, import trực tiếp `teacher_live_monitor_bloc.dart:3`) | **Fix KHÔNG đụng hàm này** (xem mục 3) → 0 rủi ro cho mirror bloc. |
| Mirror view (`student_exam_live_mirror_view.dart`) | ❌ không dùng field `_parsed*` — tự `parseStrips` mỗi build | Không ảnh hưởng. |

→ Fix chỉ cần khoanh trong `teacher_live_monitor_derived.dart` (file riêng của live-monitor, KHÔNG import bởi mirror bloc) — không cần đụng `mergeTeacherLivePayload` dùng chung.

---

## 3. Quyết định thiết kế + cảnh báo

**Chọn:** sửa `enrichLiveMonitorStudentRow` — thay điều kiện cache từ "parse nếu `_parsedSkillStrips == null`" sang "parse lại nếu **raw `skillStrips` đổi reference**" (lưu thêm `_parsedSkillStripsSource` trỏ tới list raw đã dùng để parse, so bằng `identical()`).

**Vì sao `identical()` đúng ở đây:**
- Khi patch socket **không** mang `skillStrips` mới → `mergeTeacherLivePayload` giữ nguyên reference cũ (`{...prev, ...patch}` không ghi đè) → `identical()` = `true` → **không parse lại** (giữ đúng tinh thần cache gốc: tránh parse lại khi chỉ đổi `progressPercent`/status).
- Khi patch **có** `skillStrips` mới (câu hỏi/đáp án đổi) → server luôn gửi list mới decode từ JSON → reference khác → `identical()` = `false` → **parse lại ngay**, đúng lúc cần.

**Vì sao KHÔNG sửa ở `mergeTeacherLivePayload`:** hàm này dùng chung với mirror bloc (mục 2). Sửa tại `teacher_live_monitor_derived.dart` (file riêng, chỉ live-monitor bloc dùng) là điểm khoanh vùng nhỏ nhất, giữ đúng nguyên tắc "biên giới cứng".

**KHÔNG làm trong scope này:**
- Không đụng backend (server đã emit đúng `skillStrips`/`currentQuestionIndex` qua socket — đã xác nhận ở mục 1.2).
- Không đụng `teacher_live_monitor_panel.dart`, `teacher_exam_question_strip.dart`, `mergeTeacherLivePayload`, mirror bloc/view.
- Không đổi UI/token — đây là bug logic state, không phải layout.

---

## 4. Scope IN / OUT

**IN (được sửa):**
- `english_for_community/lib/feature/teacher/bloc/live_monitor/teacher_live_monitor_derived.dart` — chỉ hàm `enrichLiveMonitorStudentRow`.

**OUT (chạm là DỪNG & hỏi):**
- `teacher_live_monitor_bloc.dart` (kể cả `mergeTeacherLivePayload`).
- `teacher_live_monitor_panel.dart`, `teacher_exam_question_strip.dart`.
- `teacher_student_live_screen_bloc.dart`, `student_exam_live_mirror_view.dart` (đang có task `20260630-teacher-live-mirror-multi-resource` dở dang, uncommitted — **tuyệt đối không đụng**).
- Backend (`examLiveSkillStrips.js`, `examLiveMonitorService.js`, socket emitter).

---

## 5. Diff cụ thể

**File:** `english_for_community/lib/feature/teacher/bloc/live_monitor/teacher_live_monitor_derived.dart` (dòng 85-93)

Thay:
```dart
/// Attach parsed skill strips once per merge to avoid re-parsing in list tiles.
Map<String, dynamic> enrichLiveMonitorStudentRow(Map<String, dynamic> row) {
  final next = Map<String, dynamic>.from(row);
  if (next['skillStrips'] is List && next['_parsedSkillStrips'] == null) {
    next['_parsedSkillStrips'] =
        TeacherExamQuestionStripSection.parseStrips(next['skillStrips']);
  }
  return next;
}
```

Bằng:
```dart
/// Re-parse skill strips only when the raw `skillStrips` reference changes (new socket patch),
/// otherwise reuse the cached parse — avoids both re-parsing every emit AND going stale.
Map<String, dynamic> enrichLiveMonitorStudentRow(Map<String, dynamic> row) {
  final next = Map<String, dynamic>.from(row);
  final raw = next['skillStrips'];
  if (raw is List && !identical(next['_parsedSkillStripsSource'], raw)) {
    next['_parsedSkillStrips'] = TeacherExamQuestionStripSection.parseStrips(raw);
    next['_parsedSkillStripsSource'] = raw;
  }
  return next;
}
```

**Ý định:** so sánh bằng `identical()` trên chính list `skillStrips` raw (không phải deep-equals) — rẻ, và đúng vì mọi patch có `skillStrips` mới đều là list JSON-decode mới (không tái dùng reference cũ). Không đổi signature hàm, không đổi field UI đọc (`_parsedSkillStrips` vẫn cùng tên/kiểu `List<Map<String, dynamic>>`).

**RÀNG BUỘC:** không đổi tên/kiểu field `_parsedSkillStrips` (đang được `teacher_live_monitor_panel.dart:256` đọc y nguyên) — chỉ thêm field phụ `_parsedSkillStripsSource` để track.

---

## 6. Ràng buộc hiệu năng (PERF GATE)

- ✅ Re-parse chỉ khi `skillStrips` raw đổi reference (đúng lúc socket bắn cập nhật câu hỏi) — không re-parse trên mọi emit (vd chỉ đổi `progressPercent`) → giữ đúng tinh thần cache gốc, không thoái hoá thành "parse mỗi build".
- ✅ `TeacherExamQuestionStripSection.parseStrips` chạy trên list nhỏ (≤30 câu/section/học sinh) — chi phí không đáng kể kể cả khi re-parse.
- ✅ Không đụng `build()`/widget — thay đổi nằm hoàn toàn trong bloc enrich step.

## 6b. UI/UX GATE

Không áp dụng đầy đủ — đây là **bug logic state (cache invalidation)**, không đổi token/spacing/component/layout. Không cần đọc `docs/ui-ux-system/` sâu; đã đối chiếu `13-teacher-live-session-console-layout.md` §4 và `16-teacher-live-participant-status.md` — không có spec nào quy định cách cache `skillStrips`, không xung đột.

## 6c. Backend GATE

Không áp dụng — đã xác nhận (mục 1.2) server/socket gửi đúng `skillStrips`/`currentQuestionIndex`; lỗi thuần phía client cache. Không sửa backend.

---

## 7. Hồi quy tối thiểu (smoke)

Account test: `docs/dev/seeds/` (teacher + student cùng 1 session live, tương tự pattern task `20260630`).

1. **Bug chính:** GV mở tab Live monitor cho 1 học sinh đang `in_progress`. Học sinh làm lần lượt câu 1 → 5 (Grammar). Ô tô đậm trong lưới Live monitor phải **đổi theo** trong vài giây, không đứng yên ở câu 1.
2. **Đối chiếu:** so với mirror (👁 Watch) mở song song — 2 màn phải khớp câu hiện tại.
3. **Regression progress-only:** patch không kèm `skillStrips` (vd chỉ đổi `answeredCount`/`progressPercent`) vẫn không gây re-parse thừa — verify bằng cách theo dõi không giật/lag lưới khi socket bắn dồn dập (DevTools performance overlay `p`, hoặc log tạm thời đếm số lần `parseStrips` chạy nếu cần).
4. **Multi-section:** Reading/Listening/Speaking strips vẫn tô đúng ô hiện tại của từng section (không chỉ Grammar).
5. **Filter tab** (All/In progress/Submitted/Flagged) vẫn hoạt động bình thường sau fix (không ảnh hưởng `_sameEnrichedRoster`).

---

## 8. Lệnh verify

```bash
cd english_for_community
dart analyze lib/feature/teacher/bloc/live_monitor
flutter analyze
```
Yêu cầu: `dart analyze` / `flutter analyze` **0 lỗi**.

---

## 9. HANDOFF — Cursor IMPLEMENT (copy-paste, biên giới cứng)

```text
Bạn là IMPLEMENTER (Codex/Sonnet). Thực thi đúng work-order:
docs/plantasks/BUG/20260701-live-monitor-current-question-stale/work-order.md

CHỈ ĐƯỢC SỬA:
  - english_for_community/lib/feature/teacher/bloc/live_monitor/teacher_live_monitor_derived.dart
Ngoài file trên → DỪNG & hỏi.

LÀM:
  1. Sửa hàm `enrichLiveMonitorStudentRow` (mục 5) — thay guard `_parsedSkillStrips == null`
     bằng so sánh `identical()` trên raw `skillStrips` qua field phụ `_parsedSkillStripsSource`.
     Copy đúng code mẫu ở mục 5, không tự đổi tên field `_parsedSkillStrips` (đang bị
     `teacher_live_monitor_panel.dart:256` đọc y nguyên).

TUYỆT ĐỐI KHÔNG:
  - Đụng `teacher_live_monitor_bloc.dart` (kể cả `mergeTeacherLivePayload` — dùng chung với
    mirror bloc, xem mục 2).
  - Đụng `teacher_live_monitor_panel.dart`, `teacher_exam_question_strip.dart`.
  - Đụng `student_exam_live_mirror_view.dart` / `teacher_student_live_screen_bloc.dart`
    (có task khác đang dở dang, uncommitted).
  - Đụng backend.
  - Đổi public signature / kiểu trả về của `enrichLiveMonitorStudentRow`.

VERIFY trước khi báo xong:
  - dart analyze lib/feature/teacher/bloc/live_monitor → 0 lỗi
  - flutter analyze → 0 lỗi
  - Smoke mục 7 (ít nhất case 1, 2) — cần 2 tài khoản (teacher + student) live cùng session,
    xem docs/dev/seeds/.
Dán kết quả verify + diff vào tracker (mục 11). Sau đó báo: "implementer đã xong, audit đi".
KHÔNG tự kết luận APPROVED.
```

---

## 10. Tracker

| Mốc | Trạng thái | Ghi chú / bằng chứng |
|---|---|---|
| Work-order (Opus) | ✅ Done | File này |
| IMPLEMENT (Cursor) | ⏳ | |
| Verify analyze | ⏳ | |
| Smoke E2E (user) | ⏳ | Cần 2 tài khoản teacher+student live cùng session — xem mục 7. |
| Opus AUDIT | ⏳ | Xem checklist mục 11 |

---

## 11. Checklist OPUS AUDIT (Phase 4) + HANDOFF Cursor AUDIT

### Checklist audit (đọc DIFF thật, đối chiếu plan)
- [ ] Chỉ sửa `teacher_live_monitor_derived.dart`, đúng 1 hàm `enrichLiveMonitorStudentRow`.
- [ ] Field `_parsedSkillStrips` giữ nguyên tên/kiểu (`List<Map<String, dynamic>>`) — `teacher_live_monitor_panel.dart:256` vẫn đọc đúng.
- [ ] Dùng `identical()` (không phải deep-equals tốn kém) để so raw `skillStrips`.
- [ ] Không đụng `mergeTeacherLivePayload`/file OUT-scope khác.
- [ ] `dart analyze` 0 lỗi.
- [ ] Smoke: ô current-question trong Live monitor đổi theo học sinh chuyển câu (không đứng yên câu 1); không giật/lag khi socket bắn progress-only.
- **Verdict:** APPROVED | CHANGES REQUESTED → ghi tracker, finding = file:line + fix cụ thể.

### HANDOFF — Cursor AUDIT (copy-paste, "nhờ cursor audit luôn")
```text
Bạn là AUDITOR (model khác implementer). KHÔNG sửa code — chỉ đọc DIFF + verify, ra verdict.
Plan: docs/plantasks/BUG/20260701-live-monitor-current-question-stale/work-order.md (mục 11 checklist).

Kiểm:
  1. Mở Live monitor cho 1 học sinh in_progress; học sinh chuyển câu 1→5 (Grammar) →
     ô tô đậm trong lưới phải đổi theo trong vài giây, không đứng yên câu 1.
  2. So với mirror (👁 Watch) mở song song — phải khớp câu hiện tại.
  3. Patch progress-only (không kèm skillStrips, vd đổi answeredCount) không gây re-parse thừa/giật lưới.
  4. Multi-section (Reading/Listening/Speaking) tô đúng ô hiện tại từng section.
  5. Field `_parsedSkillStrips` không đổi tên/kiểu; không đụng file ngoài scope
     (đặc biệt `mergeTeacherLivePayload`, mirror bloc/view).
  6. dart analyze / flutter analyze 0 lỗi.

Mỗi finding: file:line + mô tả + fix đề xuất. Verdict: APPROVED | CHANGES REQUESTED. Ghi vào tracker mục 10.
```
