# Tracker — 20260711-progress-lesson-count-range

- **Loại/Cỡ:** BUG · T1 · backend-only
- **Status:** `IMPLEMENTED (Opus tự code) — node --check + node --test PASS; smoke UI chờ máy thật`
- **Work-order:** [`work-order.md`](work-order.md)

## Tóm tắt fix
| # | Finding | Fix | File |
|---|---|---|---|
| F6 | Card "Bài học hoàn thành" (8) ≠ số dòng list (7): card đếm counter sự kiện, list liệt kê doc nguồn | Tách `_fetchCompletedLessons` dùng CHUNG cho card (`.length`) + detail (liệt kê) → card == list theo cấu trúc | progressService.js |
| F7 | Filter không khớp: 'day' card = hôm nay, detail = 7 ngày | `_calculateDateRange('day')` = chỉ hôm nay; card lessons/vocab + detail cùng gọi `_calculateDateRange(range)` | progressService.js |

## Quyết định nghiệp vụ (user chọn)
- Card "Bài học hoàn thành" = **số bài trong danh sách** (đếm distinct doc đã hoàn thành trong kỳ; làm lại tính 1; luyện nói tự do KHÔNG tính là "bài học" vì không có doc trong list).

## Thay đổi (2 file Scope IN)
- `progressService.js`:
  - `_calculateDateRange('day')`: bỏ nhánh −6 ngày → start = hôm nay (F7).
  - Thêm helper `_fetchCompletedLessons(userId, startDate, endDate)` — bê nguyên logic isLessonMode + `Promise.all` (song song).
  - `getSummaryData`: gộp `rangeStart/rangeEnd` = `_calculateDateRange(range)` cho CẢ vocab + lessons; `statsGrid.lessonsCompleted = (await _fetchCompletedLessons(...)).length` (override counter, giống pattern F2 vocab).
  - `getStatDetailData` isLessonMode: thay 5 query inline bằng `queryResult = await _fetchCompletedLessons(...)` (hành vi list y nguyên, chỉ nhanh hơn).
- `progressService.summary.test.js`: import 5 model lesson + helper `leanChain`/`mockLessons`; mock cho 3 test getSummaryData cũ; thêm suite F6 (2 test: card=3 không phải counter 396; detail length=3 khớp card).

## Audit downstream (đã grep)
- `statsGrid.lessonsCompleted` (getSummaryData) chỉ dùng bởi card `progress_report_page.dart:464`.
- AI tools (`implementations.js`), `userController` (home + admin-detail), admin dialog → đọc **raw** `rec.lessonsCompleted.*` hoặc endpoint riêng → **KHÔNG ảnh hưởng**.
- `aggregateProgressRecords` (pure) giữ nguyên `lessonsSum` → test `progressService.test.js` (lessons=7) vẫn pass.
- Vocab 'day'/'week'/'month' filter bounds KHÔNG đổi giá trị (rangeStart cho 'day' == userTodayStart cũ).

## Bằng chứng
- [x] `node --check src/services/progressService.js`: OK
- [x] `node --test progressService.summary.test.js`: **6/6** (3 cũ + vocab-detail + F6×2)
- [x] `node --test progressService.test.js`: **13/13** (pure `aggregateProgressRecords`, lessons=7 giữ nguyên)
- [x] `node --test` (toàn bộ backend pure-logic): **83/83 pass** (23 suites) — no-regression
- [ ] Smoke UI end-to-end (⭐ card Lessons == số dòng list; Ngày/Tuần/Tháng khớp khoảng): chờ chạy app + DB seed.

## Opus self-audit
- [x] Chỉ 2 file Scope IN đổi; write-path/counter/aggregateProgressRecords/frontend KHÔNG đụng.
- [x] F7 `_calculateDateRange('day')` = today; card & detail chung `_calculateDateRange(range)`.
- [x] F6 card = `_fetchCompletedLessons(...).length`; detail dùng cùng helper → khớp theo cấu trúc (unit test khoá).
- [x] Không placeholder/TODO; không đổi shape JSON/schema/l10n.
- **Verdict:** ✅ PASS (unit + check). ⚠️ Cần smoke ⭐ trên máy thật để xác nhận số distinct thực tế + range 'day'.
