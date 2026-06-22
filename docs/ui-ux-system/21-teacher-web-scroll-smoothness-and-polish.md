# 21 — Teacher web: hiệu năng & mượt (render + data + backend)

> **Phạm vi:** mọi nguyên nhân làm workspace **teacher** cảm thấy chậm/đơ/lag — gồm **(A) render/scroll**, **(B) data & rebuild tầng Flutter**, **(C) backend API**.
> **Mục đích:** chẩn đoán **root-cause kèm `file:dòng`** + **giải pháp theo ưu tiên** để Cursor code theo + **cách đo trước/sau**.
> **Nguồn:** đọc trực tiếp code 06/2026. Bổ sung cho [`18`](18-teacher-web-audit-and-standards.md).
> **Thứ tự khuyến nghị:** P0 của cả 3 tầng trước (đòn bẩy lớn nhất), rồi P1, rồi polish §8.

---

## 1. Triệu chứng & cách đo (baseline trước khi sửa)

- Cuộn trang/kéo scrollbar khựng, rớt frame; mở màn (gradebook/grading hub/assign dialog) **chờ lâu**; thao tác (search/filter/sort) **đơ một nhịp**.
- **Đo render** (`flutter run -d chrome --profile`): DevTools › Performance → **Raster thread** > 16ms khi cuộn = jank; Inspector › **Highlight repaints** (kỳ vọng chỉ card mới vào viewport sáng).
- **Đo rebuild**: DevTools › Performance › **Track widget builds**; bật `debugPrintRebuildDirtyWidgets` tạm để thấy widget rebuild thừa.
- **Đo network**: tab Network của trình duyệt → thời gian từng request; chú ý **waterfall tuần tự** (request sau chờ request trước).
- **Đo backend**: log thời gian mỗi endpoint (middleware timing) + bật Mongo `explain()`/slow-query log cho gradebook & grading hub. Ghi P95 các route: gradebook, `/assignments/:id/attempts`, dashboard, analytics.
- **Lưu renderer:** desktop chạy **CanvasKit** (`web/index.html:41` bootstrap mặc định) — giữ nguyên; đòn bẩy là **giảm repaint + rebuild + chờ API**, không phải đổi renderer.

---

# A · RENDER / SCROLL

## 2A. Chẩn đoán render

| # | Nguyên nhân | `file:dòng` | Vì sao jank | Tác động |
|---|-------------|-------------|-------------|:--------:|
| R1 | **Hover-lift bắn khi cuộn** — `MouseRegion`+`AnimatedScale`+`setState` | `teacher_dashboard_motion.dart:34,67-82`; dùng `teacher_dashboard_layout.dart:805` | Kéo chuột cuộn → con trỏ quét tile → enter/exit → setState + scale animation giữa lúc cuộn | 🔴 Cao |
| R2 | **Shadow blur trên mọi card** — `cardShadow` 2 lớp (blur 12 + 1) | `teacher_web_ui.dart:64-74` | Blur = op raster đắt nhất CanvasKit; repaint lại mỗi lần card layer bẩn | 🔴 Cao |
| R3 | **Toàn trang 1 scroll layer** — `SingleChildScrollView`+Column, không RepaintBoundary/ảo hoá | `teacher_page_scaffold.dart:65-75` | Một layer cao; repaint nào cũng làm bẩn cả layer; bảng dài build hết hàng | 🔴 Cao |
| R4 | **Animation vĩnh viễn** — `livePulse` `.repeat()` | `teacher_dashboard_motion.dart:39-54`; `teacher_dashboard_layout.dart:511` | Animate mỗi frame, cạnh tranh raster lúc cuộn | 🟠 Vừa |
| R5 | **Thiếu RepaintBoundary cục bộ** (gradebook rows, panel, KPI) | `teacher_gradebook_view.dart`, `teacher_dashboard_layout.dart` | Card không tách layer → repaint lan (grading hub `:247`, classroom `:459` đã đúng — nhân rộng) | 🟠 Vừa |
| R6 | **Ảnh/avatar không `cacheWidth`** | avatar member/inbox | Decode ảnh lớn khi cuộn → raster spike | 🟡 Thấp |
| — | Scrollbar `_SafeScrollbar` | `e4c_scroll_behavior.dart:62-127` | **KHÔNG phải thủ phạm** (đã gỡ listener, không setState/pixel) | ✅ OK |

## 3A. Giải pháp render

**P0-R1 · Tắt hover khi cuộn + hover rẻ.** Gate `_HoverLift` bỏ qua hover khi `isScrolling` (đặt cờ qua `NotificationListener<ScrollNotification>` + debounce ~120ms, truyền xuống bằng InheritedWidget). Đổi hover từ `AnimatedScale` → **đổi nền/viền qua decoration** (`hoverOverlay` + viền); giữ scale chỉ cho classroom tile.
**P0-R2 · Phẳng-hoá card trong list.** Card trong danh sách cuộn dùng `panelDecoration()` (phẳng, không blur); chỉ KPI strip + dialog giữ shadow, và giảm `cardShadow` còn **1 lớp blur 6** (`teacher_web_ui.dart:64`).
**P0-R3 · RepaintBoundary mỗi card/section** (gradebook row, panel, KPI, exams item) theo mẫu `teacher_assignment_grading_hub_view.dart:247`.
**P1-R4 · Tiết chế `livePulse`**: chỉ animate dot 8px + RepaintBoundary + pause khi `isScrolling`/ngoài viewport.
**P1-R5 · Ảo hoá list dài**: `SingleChildScrollView+Column` → `ListView.builder`/`SliverList` (gradebook). KHÔNG lồng list trong SingleChildScrollView (`teacher_page_scaffold.dart:63`).
**P1-R6 · `cacheWidth`/`memCacheWidth`** cho avatar/cover.

---

# B · DATA & REBUILD (Flutter)

## 2B. Chẩn đoán data/rebuild

| # | Nguyên nhân | `file:dòng` | Vì sao chậm | Tác động |
|---|-------------|-------------|-------------|:--------:|
| F1 | **Network waterfall** — 3 API tuần tự trong `_bootstrap` | `teacher_assign_exam_dialog.dart:104-135` (getExam → listClassrooms → listPresets) | ~1.5s chờ nối tiếp thay vì ~0.5s song song | 🔴 Cao |
| F2 | **BlocBuilder rebuild cả trang** — thiếu `buildWhen`/`BlocSelector` | dashboard `teacher_dashboard_page.dart:126`; analytics `teacher_analytics_page.dart:43`; grading hub `teacher_assignment_grading_hub_view.dart:47` | Mỗi state nhỏ (search/filter/cờ) rebuild toàn Column + chart + list | 🔴 Cao |
| F3 | **Parse JSON `.map().toList()` mỗi build** | gradebook `teacher_gradebook_view.dart:46-95,112`; chart `teacher_analytics_page.dart:302,372,446` | Clone + map toàn list mỗi build/rebuild → 20-30ms với bảng 50+ hàng | 🔴 Cao |
| F4 | **Sort/filter trong build()** | `teacher_gradebook_view.dart:55-90` | Lọc + sort chạy lại mỗi build thay vì memo/đẩy vào Bloc | 🟠 Vừa |
| F5 | **fl_chart dựng lại `barGroups` mỗi build** | `teacher_analytics_page.dart:295-359,363-433` | Fold maxY + tạo BarChartGroupData mỗi build | 🟠 Vừa |
| F6 | **Thiếu `const` / `ValueKey`** item động | gradebook `_ScoreCell` closure `:542-549`; grading card `:248`; classroom chip `teacher_dashboard_overview.dart:581`; `_StatTile` `:207` | Closure `onTap: () => …` + thiếu key → rebuild thừa, không track item | 🟠 Vừa |
| F7 | **Live monitor map cả list mỗi tick** | `teacher_live_monitor_bloc.dart:81,97` | Mỗi update socket → enrich toàn list → emit → rebuild | 🟡 Thấp* |

\* cao nếu phiên live đông.

## 3B. Giải pháp data/rebuild

**P0-F1 · `Future.wait`.** Gộp 3 call song song:
```dart
final r = await Future.wait([repo.getExam(id), repo.listMyClassroomsAsTeacher(), repo.listAssignmentPresets()]);
```
→ ~3× nhanh khi mở assign dialog. Áp cùng mẫu cho mọi `_bootstrap` có await tuần tự độc lập.
**P0-F2 · `buildWhen`/`BlocSelector`.** Dashboard: `buildWhen` chỉ rebuild khi `status/classrooms/exams/gradingQueue` đổi (không phải `searchQuery`). Analytics: tách mỗi chart thành `BlocSelector` theo field. Grading hub: `buildWhen: (p,c) => p.visibleAttempts != c.visibleAttempts`.
**P0-F3 · Đẩy parse/filter/sort vào Bloc.** Bloc emit **dữ liệu đã parse + đã lọc + đã sort** (`filteredRows`, `chartPoints` typed), widget chỉ render. Tránh `Map<String,dynamic>` parse trong build.
**P1-F4 · Memo hoá** kết quả filter/sort theo `(query,hideEmpty,sort,modeFilter)` nếu chưa chuyển hết vào Bloc.
**P1-F5 · Cache `barGroups`** theo identity của `data` (chỉ dựng lại khi data đổi).
**P1-F6 · Thêm `const` + `ValueKey`.** `key: ValueKey(id)` cho grading card/classroom chip/score cell; `const` cho `_StatTile`; tách closure khỏi build.
**P2-F7 · Debounce/emit-on-change** cho live monitor; emit `visibleStudents` pre-computed, chỉ khi thực sự đổi.

---

# C · BACKEND (Express + Mongoose)

## 2C. Chẩn đoán backend

| # | Nguyên nhân | `file:dòng` | Vì sao chậm | Tác động |
|---|-------------|-------------|-------------|:--------:|
| B1 | **N+1 khi dựng bài chấm** — lồng `for sec → for res → await find` | `examAttemptService.js:777-917` (≈796,805) | ~40 query/attempt khi lấy bài từ CMS (dictation/reading/speaking/writing × 3 lần) | 🔴 Cao |
| B2 | **N+1 batch grading** — loop attempt, mỗi vòng load full doc | `examGradingService.js:328-387` | 50 attempt → 50× (findById + assignment + submissions) | 🔴 Cao |
| B3 | **Thiếu index** field find/sort | `ExamAttempt.js` (chỉ `{assignmentId,userId,status}`), `ExamAssignment.js` | Collection scan: `{assignmentId,status}`, `{sessionId,...}`, `{status,attemptDeadlineAt}`, sort `submittedAt` | 🔴 Cao |
| B4 | **Thiếu `.lean()`** trên query readonly | gradebook/dashboard/analytics services; `examAttemptService.js:1251` | Hydrate Mongoose doc tốn 20-30% CPU khi chỉ đọc | 🟠 Vừa |
| B5 | **populate kéo `exam.sections` lớn** | `examAttemptService.js:1248` (populate `examId`) | Kéo 50-100KB sections khi chỉ cần title/settings | 🟠 Vừa |
| B6 | **Class-average O(n²) bằng JS loop** | `teacherGradebookService.js:157-194` | Lặp `rows.find()` lồng cho mỗi cột × mỗi assignment | 🟠 Vừa |
| B7 | **Analytics 10 query tuần tự** | `teacherAnalyticsChartsService.js` (~34-197) | Có thể gộp `$facet` + `Promise.all` còn 1-2 query | 🟠 Vừa |
| B8 | **Thiếu pagination** list lớn | `teacherExamAssignmentService.js:272-284` | `find()` không limit + stats theo từng assignment | 🟡 Thấp* |

\* tăng theo số assignment.

## 3C. Giải pháp backend

**P0-B1 · Khử N+1 dựng bài chấm.** Trước vòng lặp, batch tất cả bằng `$in` + `Promise.all`, nạp vào `Map` theo (userId, resourceId, time-window), rồi loop đọc từ Map (0 query trong loop). Ưu tiên fallback **inline data** từ `attempt.answers` trước khi đụng CMS.
**P0-B2 · Khử N+1 batch grading.** Bỏ `.select('_id')`, fetch full docs một lần; xử lý in-memory / `Promise.all`; nếu chỉ đổi trạng thái → `updateMany`.
**P0-B3 · Thêm index** (schema):
```js
ExamAttempt:  {assignmentId:1,status:1} · {assignmentId:1,submittedAt:-1} · {sessionId:1,status:1}
              · {sessionId:1,userId:1,status:1} · {status:1,attemptDeadlineAt:1} · {userId:1,status:1}
ExamAssignment: {classroomId:1,audience:1,status:1}
```
**P1-B4 · `.lean()`** cho mọi query chỉ-đọc (gradebook/dashboard/analytics/attempts list).
**P1-B5 · Projection populate**: `populate('examId','title settings')` (loại `sections`); attempts `.select(...)` chỉ field cần.
**P1-B6 · Aggregation** thay loop class-average: `$group` theo `assignmentId` tính avg/submitted/pending một lần.
**P1-B7 · `$facet` + `Promise.all`** gộp analytics còn 1-2 query.
**P2-B8 · Pagination** `skip/limit` cho `listForTeacher`; cân nhắc cache data ít đổi.

---

## 4. Layout đẹp hơn (sau khi mượt)

> Giữ design tokens. "Hơi xấu" chủ yếu do **elevation lộn xộn** (hộp-trong-hộp + shadow khắp nơi) và **nhịp dọc chưa đều**.

**4.1 Kỷ luật elevation — khuyến nghị hướng A "Linear-clean" (phẳng):** list/bảng dùng panel phẳng (viền 1px, không shadow), phân tách bằng viền + khoảng trắng; chỉ **KPI strip trên cùng + dialog** có shadow nhẹ (blur 6). (Hướng B "Stripe-card" shadow đồng nhất chỉ dùng nếu card ít — đánh đổi với mục tiêu mượt.)
**4.2 Nhịp & phân cấp:** section gap `s6` giữa khối, `s4–s5` trong card; chèn section bằng divider `outlineMuted` + label để có nhịp giữa title 16 và section 11; bảng **sticky header + zebra nhẹ** (`surfaceSubtle` hàng lẻ), row 40 thoáng.
**4.3 Hover/affordance rẻ:** hover đổi nền `hoverOverlay` (không scale); selected `primaryTint` + viền primary; focus ring 2px (`focusableTile`).
**4.4 Chi tiết "xịn":** skeleton đúng khung (đã có `TeacherSkeleton`); empty state + CTA; divider nội bộ dùng `outlineMuted`.

---

## 5. Ưu tiên tổng hợp (làm theo thứ tự này)

| Bước | Hạng mục | Kỳ vọng |
|:----:|----------|---------|
| 1 | **P0-F1** Future.wait waterfall | mở dialog/màn nhanh ~3× |
| 2 | **P0-B1/B2/B3** N+1 + index | API gradebook/grading nhanh nhiều lần, hết "đơ khi mở" |
| 3 | **P0-R1/R2/R3** hover-khi-cuộn + phẳng card + RepaintBoundary | cuộn mượt, hết giật |
| 4 | **P0-F2/F3** buildWhen/Selector + parse trong Bloc | thao tác search/filter mượt |
| 5 | **P1** (R4/R5, F4-F6, B4-B7) | giảm dư raster/CPU/query còn lại |
| 6 | **§4 polish** elevation + nhịp | đẹp, nhất quán |

---

## 6. Checklist nghiệm thu

- [ ] **Render:** raster < 16ms khi cuộn dashboard/gradebook; "Highlight repaints" chỉ sáng card mới; hover không bắn khi cuộn; card list phẳng (`panelDecoration`); list dài đã builder/Sliver.
- [ ] **Data:** `_bootstrap` dùng `Future.wait`; BlocBuilder có `buildWhen`/`BlocSelector`; parse/sort/filter ở Bloc, không trong build; item có `ValueKey`; `barGroups` memo hoá.
- [ ] **Backend:** không còn vòng lặp `await find` (đã `$in`+Map / aggregation); index đã thêm (kiểm bằng `explain()` thấy `IXSCAN` không `COLLSCAN`); query readonly có `.lean()`; populate không kéo `sections`; list lớn có pagination.
- [ ] **Đo lại** P95 các route + FPS cuộn trước/sau, ghi vào PR.

---

## 7. Bản đồ file ↔ việc

| Tầng | File | Việc | Mục |
|------|------|------|-----|
| Render | `teacher_dashboard_motion.dart` | gate hover khi cuộn; hover→decoration; pulse dot+RepaintBoundary | R1,R4 |
| Render | `teacher_web_ui.dart` | giảm `cardShadow` blur 6; `cardDecoration`(hero) vs `panelDecoration`(list) | R2,§4.1 |
| Render | `teacher_page_scaffold.dart` / `teacher_gradebook_view.dart` | RepaintBoundary; Sliver/builder list dài | R3,R5 |
| Data | `teacher_assign_exam_dialog.dart` | `Future.wait` `_bootstrap` | F1 |
| Data | `teacher_dashboard_page.dart` / `teacher_analytics_page.dart` / `teacher_assignment_grading_hub_view.dart` | buildWhen/BlocSelector; ValueKey; const | F2,F5,F6 |
| Data | `teacher_gradebook_view.dart` | parse/filter/sort → Bloc; memo; ScoreCell key | F3,F4,F6 |
| Data | `teacher_live_monitor_bloc.dart` | emit-on-change/debounce | F7 |
| Backend | `examAttemptService.js` | khử N+1 dựng bài (batch `$in`+Map); `.lean()`; projection populate | B1,B4,B5 |
| Backend | `examGradingService.js` | khử N+1 batch grading | B2 |
| Backend | `ExamAttempt.js` / `ExamAssignment.js` | thêm compound index | B3 |
| Backend | `teacherGradebookService.js` | class-average aggregation; `.lean()` | B6,B4 |
| Backend | `teacherAnalyticsChartsService.js` | `$facet`+`Promise.all` | B7 |
| Backend | `teacherExamAssignmentService.js` | pagination | B8 |

> **Đo trước/sau mỗi P0/P1** (§1). Ghi commit vào [`11-implementation-mapping.md`](11-implementation-mapping.md) "Migration log".
</content>
