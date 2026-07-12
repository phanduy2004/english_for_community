# Tracker — 20260712-teacher-analytics-correctness

- **Loại/Cỡ:** BUG · T1 · backend
- **Status:** `PART 1 (số liệu) + PART 2 (UI redesign) IMPLEMENTED — unit/analyze/test PASS; smoke máy thật chờ.`
- **Work-order:** [`work-order.md`](work-order.md)

## Quyết định user
- (1) Sửa số liệu backend TRƯỚC → UI sau. (2) Co-teacher = GỒM lớp dạy-cùng (#8).

## Fix đã làm (Part 1)
| # | Lỗi | Fix | File |
|---|---|---|---|
| 1 | submissions/trend rớt HÔM NAY + ngày đầu nửa ngày | `resolveWindow` window ngày VN gồm hôm nay; fill key VN | teacherAnalyticsScope.js, chartsService |
| 2 | gom ngày UTC thay vì VN | `timezone:'+07:00'` cho 2 `$dateToString` + fill key VN | chartsService |
| 3 | on-time/late đếm trùng khi nộp lại | `dedupeLatestAttempts` (latest per student,assignment) | chartsService |
| 4 | not_submitting báo nhầm | at-risk bỏ window (`submittedAt≥since`) → xét mọi lần nộp assignment active | chartsService |
| 5 | integrity toàn thời gian + gồm bài chưa nộp | thêm `status:'submitted', submittedAt≥since` cho 2 agg | chartsService |
| 6 | "chờ chấm" 2 định nghĩa vênh | `gradingAttentionMatch` chung ở charts + summary | scope.js, chartsService, dashboardService |
| 8 | co-teacher scope lệch | `teacherAnalyticsScope` (owner∪co-taught) ở charts + summary; activeStudentCount thêm `roleInClass:'student'` | scope.js, chartsService, dashboardService |
| 7 | avgScore integrated vs scoreDist legacy | **FOLLOW-UP** (chưa sửa) | — |

## Kiến trúc
- Module mới `teacherAnalyticsScope.js`: `gradingAttentionMatch`, `classroomIdsForTeacher`, `teacherAnalyticsScope`, `resolveWindow` (dùng chung, tránh cycle 2 service).
- `chartsService`: dùng scope+window mới; xóa local `classroomIdsForTeacher`; export `dedupeLatestAttempts`.
- `dashboardService`: import shared; `getAnalyticsSummary` scope co-inclusive + pending chuẩn + student-only; xóa local `gradingAttentionMatch`.

## Bằng chứng
- [x] `node --check` 3 service: OK
- [x] `node --test teacherAnalyticsChartsService.test.js`: **53/53** (46 cũ + 7 mới: resolveWindow VN/today, dedupe, evening-VN)
- [x] `node --test` (full backend): **90/90 pass** (25 suites) — no-regression
- [x] Import smoke: 3 module load OK, export đúng (`resolveWindow`/`teacherAnalyticsScope`/`gradingAttentionMatch`/`getCharts`/`getAnalyticsSummary`)
- [ ] Smoke máy thật: cột hôm nay, tối VN không lệch ngày, nộp lại không trùng, không cờ not_submitting sai, co-teacher gồm lớp dạy-cùng, "chờ chấm" == inbox

## Opus self-audit
- [x] Chỉ 4 file đổi (3 service + 1 test) + 1 file mới; frontend/model KHÔNG đụng.
- [x] `getAnalyticsSummary` chỉ dùng bởi endpoint analytics (verify grep) → đổi scope an toàn.
- [x] Pure helper (`resolveWindow`/`dedupeLatestAttempts`/`fillSubmissionDays`) có unit test; DB-orchestration verify bằng review + node --check + import smoke.
- **Verdict:** ✅ PASS (unit + check). ⚠️ Số distinct/thời gian thực cần smoke máy thật + DB.

## PART 2 — redesign UI `teacher_analytics_page.dart` ✅ (spec: `part2-ui-redesign.md`)
- Implement: subagent theo build-spec; Opus audit (đọc diff thật + tự chạy test).
- R1 phân **4 section có header** (Tổng quan · Hoạt động & điểm số · Học sinh & câu hỏi · Tính toàn vẹn & nộp bài) — thêm `_SectionHeader`.
- R2 **bỏ hết `_NewPill`/isNew** (nhiễu dev-marker); `_KpiCard` gỡ Stack thừa.
- R3 `_EmptyNote` cho Section C rỗng (không mất section → hết "trống trơn").
- R4 `_asMapList` null-safe (`raw is! List` + `whereType<Map>`).
- R5 tokenize an toàn (at-risk `_hdr`→`webTableHead`); KHÔNG đổi micro-font chart (tránh overflow).
- R6 +5 l10n key EN/VI + `gen-l10n`.
- Opus refine: bỏ subtitle Section A (trùng title smart-summary), rút gọn `_SectionHeader`.
- **Bằng chứng:** chỉ 3 file đổi (page + 2 ARB); `dart analyze` page **No issues found**; `flutter test` analytics **20/20**; **full suite 30/30**; ARB JSON valid + VI tự nhiên; 0 sót `_NewPill`/`isNew`.
- [ ] Smoke UI máy thật (xem 4 section, empty-state, chart hôm nay, số co-teacher).

## Verdict Opus
✅ **APPROVED** (Part 1 + Part 2). Unit/analyze/test PASS, no regression. Chờ smoke máy thật + DB. Chưa commit.
