# Work-Order — BUG: Teacher Analytics — số liệu sai (timezone / today / dedupe / scope)

- **Task ID:** `20260712-teacher-analytics-correctness`
- **Loại:** BUG · **Platform:** backend · **Cỡ:** T1
- **Mục tiêu:** Sửa các lỗi tính đúng số liệu ở màn Teacher Analytics (endpoint `GET teacher/dashboard/analytics`). Part 1/2 (Part 2 = redesign UI, đợt sau).
- **Người phân tích + implement:** Opus (user cho phép). **Status:** IN PROGRESS.
- **Quyết định user:** (1) sửa số liệu backend TRƯỚC rồi mới UI; (2) **co-teacher = GỒM cả lớp dạy-cùng** (#8).

---

## 1. Findings (đã đọc code thật `teacherAnalyticsChartsService.js` + `teacherDashboardService.js`)

| # | Lỗi | Bằng chứng | Fix |
|---|---|---|---|
| 1 | Chart "Bài nộp/ngày" + trend **bỏ sót HÔM NAY** & ngày đầu chỉ nửa ngày | `since=now−N*DAY` (giữa ngày); `fillSubmissionDays` sinh key `since`→hôm qua, không có key hôm nay; `$match ≥ since` gồm hôm nay nhưng bị rớt vì thiếu key. `currentSubmissions` (tử số trend) cũng mất hôm nay | Window theo **ngày VN**: `since`=VN-midnight của (today−(N−1)); fill N key VN kết thúc HÔM NAY (ngày đầu thành ngày VN đầy đủ) |
| 2 | Gom ngày theo **UTC** thay vì VN (+07:00) | `$dateToString` không set timezone (`:415,:520`) + `toISOString()` trong fill | Thêm `timezone:'+07:00'`; fill dùng key ngày VN |
| 3 | on-time/late **đếm trùng khi làm lại** | vòng lặp theo attempt (`:249-270`) không dedup theo (student,assignment) → `onTime+late≠submitted`; nộp lại trễ → cờ "late" sai | `dedupeLatestAttempts` giữ attempt mới nhất mỗi (uid,aid) trước khi tally |
| 4 | Cờ **not_submitting** báo nhầm | attempts lọc `submittedAt≥since` nhưng `assignedCount` toàn thời gian (`:232-306`) → nộp trước cửa sổ bị coi "không nộp"; `missing` phồng | At-risk **bỏ window** (xét mọi lần nộp của các assignment active) |
| 5 | Integrity tính **toàn thời gian + gồm bài chưa nộp** | `$match:{assignmentId}` không lọc status/thời gian (`:448-456,:538-549`) | Thêm `status:'submitted', submittedAt:{$gte:since}` |
| 6 | "Chờ chấm" **2 định nghĩa** vênh nhau | charts + summary dùng `gradingState:'pending_manual'` (`:464-467`, dashboard `:235-240`); inbox dùng `gradingAttentionMatch` rộng hơn (`teacherDashboardService.js:14-20`) | Thống nhất: dùng `gradingAttentionMatch` (submitted + pending_manual/pending_ai/finalized-chưa-release) ở CẢ charts + summary |
| 8 | **Co-teacher scope lệch**: `activeStudents` gồm lớp dạy-cùng nhưng metric bài giao/điểm chỉ của assignment mình tạo | charts assignments query `teacherId` only (`:352-359`); KPI trên màn đọc từ `summary` (owner-only) | Scope CHUNG owner+co-taught (assignments = own ∪ classroomId∈classIds) cho CẢ charts + summary |
| 7 | avgScore chỉ integrated còn scoreDist fallback legacy → tập khác nhau | `:468-478` vs `:118-131` | **FOLLOW-UP** (không sửa đợt này — cần quyết cách blend legacy % vào thang /10) |

> **Nguồn KPI quan trọng:** màn analytics đọc "Active students / Completion / In progress / Pending grading" từ `summary` (`teacherDashboardService.getAnalyticsSummary`, owner-only) — nên #6/#8 phải sửa ở CẢ summary lẫn charts mới đồng bộ. `getAnalyticsSummary` chỉ dùng bởi `teacherExamController:118` (an toàn khi đổi scope).

---

## 2. Thiết kế

**Module scope dùng chung mới** `src/services/teacherAnalyticsScope.js` (tránh cycle giữa 2 service):
- `gradingAttentionMatch` (chuyển từ teacherDashboardService sang đây, export) — định nghĩa "cần chấm" chuẩn.
- `classroomIdsForTeacher(teacherId)` (chuyển từ charts service) — owner(archived:false) ∪ co_teacher active.
- `teacherAnalyticsScope(teacherId)` → `{ classIds, assignments, assignmentIds }` với assignments = `$or:[teacherId, teacherId(ObjectId), classroomId∈classIds]` (co-inclusive), select superset.
- `resolveWindow(nowMs, nDays)` → `{ since, prevSince }` mốc ngày VN (since=VN-midnight của today−(N−1); prevSince=since−N*DAY).

**`teacherAnalyticsChartsService.js`:** dùng `teacherAnalyticsScope` + `resolveWindow`; thêm `timezone:'+07:00'` cho 2 `$dateToString`; integrity 2 agg thêm `status:'submitted',submittedAt≥since`; pendingGradingCount dùng `gradingAttentionMatch`; `computeStudentRiskAndOnTime` bỏ window + dedupe; `fillSubmissionDays` sinh key ngày VN. Xoá local `classroomIdsForTeacher`.

**`teacherDashboardService.js`:** import `gradingAttentionMatch`+`teacherAnalyticsScope` từ module mới; `getAnalyticsSummary` dùng scope co-inclusive + pendingGrading = `gradingAttentionMatch` + activeStudentCount thêm `roleInClass:'student'` (đang thiếu → đếm cả co_teacher). Xoá local `gradingAttentionMatch`.

**Pure helpers export để test:** `resolveWindow`, `dedupeLatestAttempts`, `fillSubmissionDays` (VN key, backward-compat test cũ vì `since` UTC-midnight → key VN cùng ngày).

---

## 3. Scope IN / OUT
**IN:** `teacherAnalyticsScope.js` (mới), `teacherAnalyticsChartsService.js`, `teacherDashboardService.js`, `teacherAnalyticsChartsService.test.js` (+ pure-helper tests mới).
**OUT (chạm là DỪNG):** ❌ Frontend (Part 2). ❌ model/schema/migration. ❌ `getActionItems`/`getCalendarEvents` logic (chỉ đổi nguồn `gradingAttentionMatch` qua import). ❌ finding #7 (follow-up). ❌ `adminService`.

---

## 4. Verify
```bash
cd english_for_community_backend
node --check src/services/teacherAnalyticsScope.js src/services/teacherAnalyticsChartsService.js src/services/teacherDashboardService.js
node --test src/services/teacherAnalyticsChartsService.test.js   # cũ pass + test mới (resolveWindow/dedupe/fill-VN)
node --test                                                       # toàn bộ, no-regression
```
**Smoke (⭐, máy thật):** 1) submissions chart có cột HÔM NAY; 2) bài nộp buổi tối VN không nhảy ngày; 3) HS nộp lại không bị đếm trùng on-time; 4) HS nộp trước cửa sổ không bị cờ "không nộp"; 5) teacher co-teacher thấy metric gồm lớp dạy-cùng; 6) "Chờ chấm" trên analytics == inbox.

## 5. Follow-up
- #7 avgScore/scoreDist khác tập (integrated vs legacy) — cần quyết blend.
- Perf: scope tính 2 lần/request (summary + charts). Nhỏ, indexed; cân nhắc gộp ở controller sau.
