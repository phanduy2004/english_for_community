# WORK-ORDER (MICRO) — Chấm bằng AI không được reload cả màn hình

**Task ID:** 20260712-ai-grade-no-fullscreen-reload · **Loại:** BUG · **Platform:** teacher web
**Ngày:** 2026-07-12 · **Người làm:** Opus (tự code + tự audit) · **Trạng thái:** ✅ DONE (chưa commit)

## 1. Vấn đề + nguyên nhân gốc
Màn chấm 1 bài (`TeacherExamAttemptGradePage`): nhấn **"Chấm AI"** → **cả màn hình flash về skeleton rồi load lại**, mất vị trí cuộn.
Root cause: sau mutation, bloc `add(TeacherExamAttemptGradeLoadRequested())` → `_onLoad` `emit(status: loading)` → build (`teacher_exam_attempt_grade_page.dart:1388,1401`) rơi vào nhánh `body: loading ? TeacherSkeleton.page(...)` = full-screen skeleton. Cùng bug ở các nút Save / Save skill / Finalize / Release trên MÀN NÀY.

## 2. Giải pháp
Thêm event **silent refresh** nạp lại data **KHÔNG bật `status: loading`** → không rơi skeleton; chỉ rebuild tại chỗ các phần bám `attempt` (score card, chip trạng thái, footer skill). Giữ `expandedSkillSections` (UI state của GV), giữ vị trí cuộn (cùng cây widget). `clearSuccess: true` để tránh double-toast.

## 3. Scope
Phần A (màn chấm 1 bài): `bloc/exam_attempt_grade/teacher_exam_attempt_grade_event.dart` (event mới), `..._bloc.dart` (handler + đổi 3 chỗ add), `teacher_exam_attempt_grade_page.dart` (_release).
Phần B (grading hub — thêm theo yêu cầu): `bloc/grading_hub/teacher_grading_hub_event.dart` (event mới), `..._bloc.dart` (handler + đổi 5 mutation + edit-assignment), `teacher_exam_grading_page.dart` (edit-assignment reload).
GIỮ full-load ở: initial-create, retry-button, pull-to-refresh (`_reload`), edit dialog cancel.

## 4. Diff (đã áp)
- **event.dart:** thêm `TeacherExamAttemptGradeRefreshRequested`.
- **bloc.dart:** `on<...RefreshRequested>(_onRefresh)`; `_onRefresh` = `getGradingAttempt` → success `emit(status:success, attempt:m, clearSuccess:true)` (KHÔNG loading, giữ expandedSkillSections), lỗi `emit(errorMessage)` (giữ data hiện tại, không status:error). Đổi `add(LoadRequested)`→`add(RefreshRequested)` ở `_onRunAi`/`_onSave`/`_onSaveSkillScore`.
- **page.dart:** `_release` success → `RefreshRequested`. GIỮ full-load ở initial (`:54`) + retry-button (`:1413`).

## 5. Verify
- `flutter analyze` (3 file) → **No issues found**.
- Smoke thủ công (đề xuất): mở màn chấm 1 bài submitted → cuộn xuống → nhấn Chấm AI → điểm/section cập nhật tại chỗ, KHÔNG flash skeleton, KHÔNG mất vị trí cuộn; toast hiện 1 lần. Tương tự Save/Finalize/Release.

## 6. Grading hub (Phần B — đã áp silent-refresh)
`TeacherGradingHubRefreshRequested` + `_onRefresh` (fetch KHÔNG bật status=loading, giữ filter + integritySummary, `clearError`, lỗi giữ data + toast). Đổi 5 mutation success branch (`_onRunAi`/`_onRelease`/`_onBatchAi`/`_onBatchRelease`/`_onBatchFinalize`) + edit-assignment reload (`teacher_exam_grading_page.dart:98`) sang Refresh. Bẫy: 3 handler batch dùng arrow-form `(_) => add(...)` (kết `,` không phải `;`) — phải replace riêng.

## 7. Self-audit (Phase 4) — ✅ APPROVED
### Phần A (màn chấm 1 bài)
- [x] Hết skeleton toàn màn khi chấm AI (bỏ status=loading trên nhánh refresh).
- [x] Dữ liệu cập nhật đúng chỗ: listener re-sync controllers khi `attempt` đổi (`!identical`), score/chip/footer rebuild in-place.
- [x] No regression: initial + retry vẫn full-load; refresh lỗi giữ data + toast (không blank); không double-toast (clearSuccess); giữ expandedSkillSections + scroll.
### Phần B (grading hub)
- [x] Hết skeleton toàn màn hub khi chấm AI (⋮ menu) / release / batch / edit-assignment.
- [x] Row cập nhật in-place: buildWhen bám `visibleAttempts`/`attemptMutationId`; row spinner (attemptMutationId) chạy trong lúc AI.
- [x] Giữ filter + integritySummary (grading không đổi integrity); lỗi refresh giữ data + toast. Toast hub bắn lúc dispatch (không double).
- [x] No regression: initial-create + `_reload` (pull-refresh/retry) vẫn full-load.
### Verify
- [x] `flutter analyze` cả 2 phần → 0 error (chỉ info/warning pre-existing).
