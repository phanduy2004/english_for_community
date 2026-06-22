# Tracker — Fixups sau review batch "perf + polish teacher" (2026-06-21)

> **Bối cảnh:** review 6 commit `perf(teacher…)` (range `7240055..HEAD`) + lồng ghép F-1 visual polish.
> **Kết luận review:** batch **chất lượng cao, KHÔNG gây regression**. Toán chấm điểm, `.lean()`, aggregation, index, server-authority đều đã verify đúng. Còn vài việc dọn dưới đây.
> **Cách dùng:** giao Cursor theo từng `RF-x` (prompt mẫu ở §cuối). Mọi sửa qua token; không đổi logic ngoài mô tả.

---

## RF-1 · 🔴 Bug chấm điểm: Writing bỏ qua `examOnly` (CÓ SẴN, nên vá)

**File:** `english_for_community_backend/src/services/examAttemptService.js` — hàm `fetchWritingRecord` (`≈539`).

**Vấn đề:** hàm chỉ nhận `(userId, topicId, bounds)` — **thiếu `opts`**, nên chạy fallback `latest_linked` (`≈567-571`) vô điều kiện. Nhưng 2 call site đều truyền `{ examOnly: true }` (`examIntegratedScoring.js:402`, `examGradingService.js:76`). Hậu quả: HS không viết trong bài thi → hệ thống lấy **bài luyện cũ cùng topic** và auto-gán điểm IELTS của nó làm **điểm thi** (`gradingSource: 'practice_cms'`, finalized) → **điểm thi sai**.

**Chuẩn để mirror:** các sibling honor `examOnly` bằng cách return ngay **sau khối `exam_window`** (chỉ cửa sổ thi, bỏ cả near_session + latest_linked): xem `fetchReadingRecord` (`:478-488`), `fetchSpeakingRecords` (`:504-518`).

**Cách sửa (đúng pattern sibling):**
1. Đổi chữ ký: `async function fetchWritingRecord(userId, topicId, bounds, opts = {}) {`
2. Dòng đầu thân hàm thêm: `const examOnly = opts.examOnly === true;`
3. **Ngay sau** dòng `if (doc) return { records: doc, source: 'exam_window' };` (`≈554`), chèn:
   ```js
   if (examOnly) return { records: null, source: null };
   ```
   (KHÔNG chèn sau near_session — phải chặn cả near_session lẫn latest_linked, giống reading/speaking.)

**Nghiệm thu:** với `examOnly: true`, writing chỉ trả bài trong cửa sổ thi; HS không viết → `records: null` (không lấy bài luyện cũ). Chạy `node --test` (test `examIntegratedScoring` vẫn xanh).

---

## RF-2 · 🟠 `batchFetchWritingRecordsMap` cũng thiếu `examOnly`

**File:** cùng file, hàm `batchFetchWritingRecordsMap` (`≈809`).

**Vấn đề:** batch map (phục vụ **màn chấm tay của GV**, không phải điểm lưu) luôn gồm stage `latest_linked` (`≈871-891`) → GV có thể thấy bài luyện cũ như bài thi. Các batch map listening/reading/speaking đã gate `latest_linked` sau `examOnly`.

**Cách sửa:** thêm tham số `opts`/`examOnly` và **bỏ stage `latest_linked` khi `examOnly`**, mirror đúng batch map sibling trong cùng file. Cập nhật call site (nơi dựng map cho grading display) truyền `{ examOnly: true }` nếu ngữ cảnh là bài thi.

**Nghiệm thu:** màn chấm tay không hiển thị bài luyện ngoài cửa sổ thi.

---

## RF-3 · 🟠 (tuỳ chọn) Giới hạn concurrency batch AI/release

**File:** `english_for_community_backend/src/services/examGradingService.js` — `runAiBatchForAssignment` / `batchReleaseResults` / `batchFinalizeAttempts` (`≈351,375,399`).

**Vấn đề:** dùng `Promise.all` **không giới hạn** trên toàn bộ attempt → lớp đông = fan-out Groq/connection-pool không kiểm soát. Không sai logic (mỗi task 1 doc, idempotent), chỉ rủi ro rate-limit/hiệu năng.

**Cách sửa:** chạy theo lô concurrency nhỏ (vd 4–6) bằng helper p-limit thủ công (chunk + `Promise.all` từng chunk). Không đổi kết quả.

---

## RF-4 · 🧹 Xóa dead code gradebook (~275 dòng)

**File:** `english_for_community/lib/feature/teacher/teacher_gradebook_view.dart`.

**Vấn đề:** `_HeaderRow` (`≈338`), `_StudentRow` (`≈453`), `_ClassAverageRow` (`≈615`) **mồ côi** sau khi chuyển sang `_StickyGradebookTable` — analyzer báo `unused_element`.

**Cách sửa:** xóa 3 class này. **GIỮ** `_AssignmentHeaderCell` và `_ScoreCell` (vẫn được `_StickyGradebookTable` dùng). Sau xóa: `flutter analyze lib` không còn `unused_element` ở file này.

---

## RF-5 · 🧹 (nit) Thứ tự import

**File:** `english_for_community/lib/feature/teacher/teacher_classroom_detail_page.dart` — `import 'dart:async'` đặt sau package import → lint `directives_ordering`. Đưa `dart:` import lên đầu.

---

## Ưu tiên & prompt cho Cursor

**Ưu tiên người dùng chọn:** **RF-1** + **RF-4** (làm trước). RF-2/RF-3/RF-5 làm sau nếu rảnh.

```
Đọc @docs/trackers/review-fixups-perf-batch.md.
Thực hiện RF-1 và RF-4 theo đúng mô tả.
Quy tắc:
- RF-1: chỉ sửa hàm fetchWritingRecord đúng 3 bước trong doc; KHÔNG đổi sibling; chèn guard examOnly NGAY SAU khối exam_window (không sau near_session).
- RF-4: chỉ xóa _HeaderRow/_StudentRow/_ClassAverageRow; giữ _AssignmentHeaderCell/_ScoreCell.
- Không đổi logic khác.
Sau khi sửa: chạy `node --test` (backend) và `flutter analyze lib`; báo kết quả + diff.
```

---

## Đã VERIFY ĐÚNG (không cần đụng)

- Toán chấm: MCQ / fill-blank / grammar partial-credit / `computeFinal` — khớp `examIntegratedScoring.test.js`.
- `.lean()` (39 chỗ) đều read-only; path ghi dùng doc đầy đủ + `markModified`.
- Aggregation analytics (bucket 0–10, chặn chia 0, filter finalized) đúng.
- Index hợp lý; server-authority giữ (clamp input client); public-start atomic.
- UI teacher: gradebook search/sort/filter (view→bloc) byte-identical; assign toast→inline cùng guard; integrated editor feedback không mất; token sạch hơn (gỡ skill-leak, greens→AppScoreScale).

---

## Nhật ký

| Ngày | Ghi chú |
|------|---------|
| 2026-06-21 | Tạo từ review batch perf+polish; RF-1 (writing examOnly) verify là bug có sẵn; RF-4 dead code. |
