# Work-Order — FEATURE: Chuyển list-card → BẢNG (teacher + admin web)

- **Task ID:** 20260711-web-list-to-table
- **Loại:** FEATURE (UI · web workspace) · **Cỡ:** T2 (>5 file, nhiều màn) → work-order + tracker
- **Platform:** teacher web + admin web
- **Mục tiêu:** Các màn QUẢN LÝ (liệt kê bản ghi) đang render bằng **list card dọc** → chuyển sang **bảng cột** (kẻ dọc/ngang, số căn phải tabular, status pill) để dễ quét/quản lý.
- **Người phân tích:** Opus (brain, KHÔNG tự code). **Implementer:** Cursor. **Auditor:** Opus (Phase 4).
- **Nguồn:** `docs/AI-Working-Process-vi.md` + `_templates/ui-build-web.md` + audit 2 sub-agent (2026-07-11). Mẫu tham chiếu ĐÃ SHIP: `teacher_classroom_detail_page.dart` (bảng Overview/Assignments/Members).

> ⚠️ **Doc thắng nguyên tắc; số density lấy từ code `TeacherWebUi`/`AdminWebUi`.** Editorial Black, token-only, KHÔNG skill color (web). Đủ 4 states (loading skeleton / empty CTA / error / success).

---

## 1. Vấn đề + nguyên nhân gốc (dẫn chứng)

Nhiều màn quản lý render mỗi bản ghi thành **1 card dọc** (`ListView.separated`/`SliverList` → card widget). Hệ quả: khó so sánh giữa dòng (không cột thẳng hàng), tốn chiều dọc, thông tin dàn trải, hành động (⋯) mỗi card một kiểu. Với "management surface" (users, submissions, exams, reports, releases, content) → **bảng** là đúng nghiệp vụ.

Root architectural: **KHÔNG có widget bảng dùng chung.** Bảng đang có đều bespoke/private:
- Teacher: bảng ở `classroom_detail` là private (`_AssignmentTable`/`_MemberTable*`); gradebook là ma trận sticky riêng; analytics `_AtRiskTable` riêng. Grep `DataTable` trong `feature/teacher/**` = 0.
- Admin: chỉ `ops_center` dùng `DataTable` thô + `_PaginationBar` **private** (trùng `AdminPaginationBar`).

→ Nếu convert từng màn mà mỗi màn tự dựng bảng = nhân bản. **P0 phải trích 1 primitive bảng dùng chung** rồi mọi màn nhái theo.

---

## 2. Audit — màn nào chuyển, màn nào giữ (2 scout, đã Opus verify #1)

### Teacher (`lib/feature/teacher/**`)
| # | File | Màn | Kiểu | Khuyến nghị |
|---|------|-----|------|-------------|
| T1 | `teacher_assignment_grading_hub_view.dart` | Grading hub — **danh sách bài nộp/attempt** của 1 assignment | card-list (`SliverList`→`TeacherGradingAttemptCard`) | **CONVERT** (ưu tiên cao nhất) |
| T2 | `teacher_exams_list_page.dart` | My Exams — danh sách đề | card-list (`ListView.separated`→`TeacherListRow`) | **CONVERT** |
| T3 | `teacher_inbox_page.dart` | Inbox — hàng đợi chấm | card-list (`ListView.separated`→`TeacherDashboardInboxCard`) | **CONVERT** |
| — | `widgets/teacher_live_monitor_panel.dart` | Live monitor | card + progress bar + skill strips | **KEEP** (realtime, không map cột gọn) |
| — | `teacher_exam_session_console_page.dart` | Roster 1 phiên | tile + progress live | **KEEP** (roster live) |
| — | `teacher_calendar_page.dart` (list mode) | Lịch | card + milestone timeline | **KEEP** (bản chất calendar) |
| — | `teacher_classroom_detail_page.dart` | Classroom detail | **table** | **ALREADY** (mẫu tham chiếu) |
| — | `teacher_gradebook_view.dart` / `teacher_analytics_page.dart` | Ma trận / dashboard | table/charts | **KEEP** |

### Admin (`lib/feature/admin/**`)
| # | File | Màn | Kiểu | Khuyến nghị |
|---|------|-----|------|-------------|
| A1 | `user_management/user_management_page.dart` | **User management** | `ListView.separated`→`UserCard` | **CONVERT** (ưu tiên #1) |
| A2 | `submission_managerment/activity_history_page.dart` | Submissions / Activity | `ListView.separated`→`_AdminHistoryCard` | **CONVERT** |
| A3 | `report_management/report_management_page.dart` | Reports | `ListView.separated`→`ReportCard` | **CONVERT** |
| A4 | `content_management/reading/admin_reading_list_view.dart` | Reading | `ListView.separated`→`ShadcnCard` | **CONVERT** |
| A5 | `content_management/listening/admin_listening_list_view.dart` | Listening | `ShadcnCard` | **CONVERT** |
| A6 | `content_management/listening_comp/admin_listening_comp_list_page.dart` | Listening Comp | `ShadcnCard` | **CONVERT** |
| A7 | `content_management/writing/admin_writing_list_view.dart` | Writing topics | `ShadcnCard` | **CONVERT** |
| A8 | `content_management/speaking/admin_speaking_list_view.dart` | Speaking | `ShadcnCard` | **CONVERT** |
| A9 | `release_management/release_management_page.dart` | Releases | `Column`→`_ReleaseItemCard` | **CONVERT** (nhiều action → dồn ⋯) |
| A10 | `ops_center/admin_ops_center_page.dart` | Ops Center | **DataTable** + `_PaginationBar` private | **CLEANUP** (thay `_PaginationBar`→`AdminPaginationBar`) |
| — | `content_dashboard_page.dart` / `dashboard_home/admin_dashboard.dart` | Hub / Overview | grid / charts | **KEEP** |

---

## 3. Quyết định thiết kế + cảnh báo

### 3.1 P0 — Primitive bảng dùng chung (BẮT BUỘC làm trước)
Trích pattern bespoke của `classroom_detail` thành **1 widget dùng chung** cho cả teacher + admin. File mới: **`lib/core/ui/widget/web_data_table.dart`**. API (WebUi-agnostic — nhận decoration/head-style từ ngoài nên dùng được cả 2 workspace):

```dart
class WebTableColumn {
  const WebTableColumn({required this.label, this.width, this.flex, this.align = Alignment.centerLeft, this.headAlign});
  final String label;      // header (sẽ .toUpperCase())
  final double? width;     // cột cố định (status/số/actions) — dùng SizedBox
  final int? flex;         // cột co giãn (name/title) — dùng Expanded(flex)
  final Alignment align;   // căn nội dung ô
  final Alignment? headAlign;
}

class WebDataTable extends StatelessWidget {
  const WebDataTable({
    required this.columns,
    required this.rowCount,
    required this.cellBuilder,      // (row, col) -> Widget nội dung ô (đã trừ padding/align)
    required this.decoration,       // TeacherWebUi.panelDecoration() | AdminWebUi.panelDecoration()
    required this.headStyle,        // TeacherWebUi.webTableHead(context) | AdminWebUi.webTableHead(context)
    this.onRowTap,                  // (row)->VoidCallback? — hover + tap-to-open
    this.rowHeight = 48,
    this.headHeight = 36,
    this.scrollable = false,        // false: shrinkwrap (preview); true: Expanded>ListView.builder
    this.scrollPadding = EdgeInsets.zero,
    this.cellPadding = const EdgeInsets.symmetric(horizontal: 12 /*s4*/),
  });
  // ... render: Container(decoration, clipBehavior: antiAlias) > Column[header, rows]
  //     header/row = Row(crossAxisAlignment: stretch) với cột Expanded(flex)/SizedBox(width)
  //     xen Container(width:1, color: outlineMuted) [kẻ dọc]; mỗi ô Padding(cellPadding)+Align(col.align)
  //     row: Material>InkWell(hoverColor: surfaceSubtle, onTap: onRowTap?.call(row))>Container(height, border bottom outlineMuted trừ row cuối)
}
```

**CLONE-THIS (source để trích — đã ship, verbatim ở `teacher_classroom_detail_page.dart`):**
- Hằng: `_vCellDivider()` `Container(width:1, color: AppColors.outlineMuted)`; `_cellPad = symmetric(horizontal: AppSpacing.s4)`; `_tableRowHeight=48`; `_tableHeadHeight=36`.
- Header: `Container(height:36, decoration: color surface + Border(bottom: outline))` + `Row(stretch)` cột `Expanded(flex)`/`SizedBox(width)` xen `_vCellDivider()`, chữ `.toUpperCase()` style `webTableHead`.
- Row: `Material>InkWell(hoverColor: surfaceSubtle)>Container(height:48, border bottom outlineMuted trừ cuối)` + `Row(stretch)`.
> Sau khi có `WebDataTable`: **refactor `classroom_detail` dùng lại nó** (bỏ `_AssignmentTable`/`_MemberTable*` bespoke) để không tồn 2 nguồn — HOẶC giữ nguyên classroom_detail, chỉ dùng `WebDataTable` cho các màn mới (chốt ở §4). Khuyến nghị: refactor luôn (1 nguồn).

### 3.2 Quy ước ô (mọi bảng)
- Cột **tên/danh tính** (User/Exam/Student/Topic): `Expanded(flex:4)` — avatar (radius 15) + Column[tên (webBody 12/w600) + phụ (metaMuted 11): email/skills/mode].
- Cột **status**: `SizedBox(width:~140)` — pill (`TeacherGradingPill`/admin `StatusBadge`), **không tô cả row**.
- Cột **số** (score/submitted/count): căn phải, `SizedBox(width:~100)`, `tabular` (fontFeatures tabularFigures).
- Cột **thời gian**: `Expanded(flex:2)` hoặc `SizedBox(width:~160)` — webCaption textSecondary.
- Cột **actions**: `SizedBox(width:56)` — **⋯ menu chứa MỌI action** của row (mẫu classroom_detail: `PopupMenuButton` + `_menuAction(icon,label,{danger})`); row-tap = hành động chính. (Không nhét nút vào ô làm phình bảng.)
- Chữ nội dung ô = **12** (`webBody.copyWith(fontSize:12)` — mẫu `_tableText`), meta = 11.

### 3.3 Reuse (KHÔNG dựng lại)
- **Teacher:** `TeacherWebUi.panelDecoration()` · `webTableHead` · `TeacherSkeleton.table(rows:)` (loading) · `TeacherGradingPill`/`TeacherStatusPill` (status) · `TeacherEmptyCard`/`TeacherRetryButton` · `TeacherWebUi.userAvatarCircle` · menu `PopupMenuButton`.
- **Admin:** `AdminWebUi.panelDecoration()` · **`AdminWebUi.webTableHead`** (đang có, chưa dùng) · **`AdminSkeleton.table(rows:)`** (đang có, đổi từ `cardList`) · **`AdminPaginationBar`** (đang dùng — giữ nguyên dưới bảng) · `AdminWebUi.userAvatarCircle` · giữ `UserRoleBadge`/`UserActionMenu`/`ReportActionMenu`/`StatusBadge`.
- **Ops Center:** thay `_PaginationBar` private → `AdminPaginationBar`; căn header theo `webTableHead`.

### 3.4 Cảnh báo
- **Data giữ nguyên** — chỉ đổi render (list→table). KHÔNG đổi bloc/query/entity.
- Các màn có **pagination sẵn** (admin): bảng nằm trên, `AdminPaginationBar` dưới; đừng bỏ.
- Search/filter/tabs giữ nguyên (toolbar trên bảng).
- `content_management` dùng `ShadcnCard` + `_MetaBadge`/`StatusBadge` cục bộ (fork `content_widgets`) — convert sang bảng là cơ hội **bớt phụ thuộc fork** (nợ kỹ thuật admin, doc `19`). Nhưng KHÔNG gỡ `ShadcnCard` toàn cục trong task này (defer).
- Row cao cố định 48 + `crossAxisAlignment: stretch` để kẻ dọc thẳng; cột số/status/actions dùng `SizedBox(width)`, tên/thời gian dùng `Expanded(flex)`.

---

## 4. Scope IN / OUT

**IN:**
- **P0:** tạo `lib/core/ui/widget/web_data_table.dart` (+ refactor `teacher_classroom_detail_page.dart` dùng lại — 1 nguồn).
- **P1 (teacher):** T1 grading hub · T2 exams list · T3 inbox → bảng.
- **P2 (admin):** A1 users · A2 submissions · A3 reports · A4–A8 content (5) · A9 releases → bảng.
- **P3 (admin cleanup):** A10 Ops Center → `AdminPaginationBar` (bỏ `_PaginationBar` private) + header `webTableHead`.

**OUT (chạm là DỪNG & hỏi):**
- ❌ Live monitor, session console roster, calendar (KEEP — realtime/timeline).
- ❌ Dashboards (KEEP).
- ❌ Đổi bloc/event/state/entity/query backend.
- ❌ Gỡ fork `content_widgets`/`ShadcnCard` toàn cục (defer, task riêng).
- ❌ Bỏ pagination/search/filter/tabs sẵn có.

---

## 5. CONTEXT BUNDLE (touch-site — anchor = chuỗi search unique, KHÔNG neo số dòng)

> Mỗi màn convert = thay khối `itemBuilder → Card` bằng `WebDataTable(columns:…, cellBuilder:…)`. Data + toolbar + pagination giữ nguyên. Dưới đây: anchor + BEFORE + mapping CỘT (cellBuilder trả nội dung ô).

### P0 — `lib/core/ui/widget/web_data_table.dart` (THÊM)
Symbol: xem §3.1. CLONE-THIS: các widget bảng trong `teacher_classroom_detail_page.dart` (anchor `class _AssignmentTableHeader`, `class _AssignmentRow`, `Widget _vCellDivider()`).

### T1 — Grading hub · `teacher_assignment_grading_hub_view.dart`
- **Anchor:** `child: TeacherGradingAttemptCard(` (trong `SliverChildBuilderDelegate`).
- **BEFORE:** `SliverList(delegate: SliverChildBuilderDelegate((context,index){ final m = visibleAttempts[index]; return RepaintBoundary(child: TeacherGradingAttemptCard(...)); }))`.
- **Data:** `state.visibleAttempts` (`List<Map>`); helper sẵn `_studentLabel(m)`, `_studentEmail(m)`, `_attemptIdOf(m)`, `_formatDate(context, m['submittedAt'])`; score parse trong `TeacherGradingAttemptCard.build` (`scores.finalScore`/`totalAwarded`/`totalMax`, `status`, `gradingState`, `resultsReleased`, `meta.submitCompleteness`).
- **CỘT:** `Student`(flex4: avatar+tên+email) · `Status`(w140: pill attempt) · `Grading`(w140: pill state) · `Score`(w90 phải: `awarded/max`) · `Submitted`(w160: date) · `⋯`(w56: menu Open-grade / Run AI / Release — giữ callback `onOpen/onAi/onRelease`). Row-tap = `onOpen`.
- **GOTCHA:** giữ `RepaintBoundary` + `ValueKey(attemptId)` mỗi row (đã có trong `WebDataTable` builder). Loading đã `TeacherSkeleton.table`. Filter chips giữ nguyên trên bảng.

### T2 — Exams list · `teacher_exams_list_page.dart`
- **Anchor:** `child: TeacherListRow(` (trong `ListView.separated` itemBuilder; `itemCount: exams.length + 1`).
- **BEFORE:** `TeacherListRow(leading: TeacherIconBadge(...), title, subtitle: skills, trailing: Row(TeacherStatusPill + "Giao bài" + PopupMenuButton))`.
- **CỘT:** `Exam`(flex4: icon badge + title + subtitle skills) · `Status`(w130: `TeacherStatusPill`) · `⋯`(w56: menu **Giao bài** / Publish / Duplicate / Archive / Restore / Delete — dồn PopupMenuButton hiện có). Row-tap = openEditor. Giữ item `+1` (nút "Tạo đề"?) → đưa ra toolbar trên bảng, KHÔNG là 1 row.
- **GOTCHA:** đổi `TeacherSkeleton.cardList(n:4)` → `TeacherSkeleton.table(rows:6)`.

### T3 — Inbox · `teacher_inbox_page.dart`
- **Anchor:** `itemBuilder: (_, i) => TeacherDashboardInboxCard(entry: entries[i])`.
- **CỘT:** `Việc`(flex4: icon kind + title HV + subtitle đề) · `Loại`(w150: pill pending_manual/ai/release) · `Lớp`(flex2: classroomName) · `Thời gian`(w120) · `⋯`(w56). Row-tap = mở việc.
- **GOTCHA:** đổi `cardList(n:5)`→`table`.

### A1 — Users · `user_management/user_management_page.dart` (+ `widgets/user_card..dart`)
- **Anchor:** `itemBuilder: (context, index) => UserCard(` (trong `ListView.separated`).
- **BEFORE (fields verbatim):** `UserEntity` → `user.avatarUrl/fullName/email/isOnline/isBanned/role/lastActivityDate`; card: `AdminWebUi.userAvatarCircle(radius:24)` + tên (gạch ngang nếu banned) + `_StatusChip`(online/offline/BANNED) + `UserRoleBadge(role)` + email + last-active + `UserActionMenu(user, onChanged)`.
- **CỘT:** `User`(flex4: `userAvatarCircle(radius:14)` + fullName + email) · `Status`(w120: online `success`/offline `textMuted`/**BANNED** `danger`) · `Role`(w110: `UserRoleBadge`) · `Last active`(w150: `Active now`/`lastActive(HH:mm dd/MM)`/`Never`) · `⋯`(w56: `UserActionMenu`). Row-tap = `AdminUserDetailsDialog(userId: user.id)`.
- **GOTCHA:** banned → tô chữ tên `danger` + gạch ngang (giữ), KHÔNG tô cả row. Đổi loading `AdminSkeleton.cardList`→`AdminSkeleton.table`. Giữ `AdminPaginationBar` + search + role dropdown + tabs.

### A2 — Submissions/Activity · `submission_managerment/activity_history_page.dart`
- **Anchor:** `itemBuilder: (context, index) { return _AdminHistoryCard(item: filteredList[index]); }`.
- **CỘT:** `User`(flex3: avatar+tên) · `Skill`(w120: icon+skill) · `Loại`(w130: subType) · `Bài`(flex3: title) · `Status`(w120: Pending/Reviewed/Draft) · `Score`(w90 phải: Band/%) · `Ngày`(w150). Row-tap = mở detail view (`writing/reading/... _detail_view`).
- **GOTCHA:** không pagination sẵn → cân nhắc thêm sau (defer); giữ date-range + user dropdown + skill tabs.

### A3 — Reports · `report_management/report_management_page.dart` (+ `widget/report_card.dart`)
- **Anchor:** `itemBuilder: (context, index) => ReportCard(report: reportsList[index])`.
- **CỘT:** `Loại`(w130: type badge) · `Tiêu đề`(flex4: title + description 1 dòng ellipsis) · `Người báo`(flex2: user.fullName) · `Tạo`(w150: createdAt) · `Status`(w120: Pending/Reviewed/Resolved/Rejected) · `⋯`(w56: `ReportActionMenu`).
- **GOTCHA:** giữ `AdminPaginationBar` + search + status tabs; `AdminSkeleton.table`.

### A4–A8 — Content management (5 màn) — cùng khung, khác cột meta
- **Anchor chung:** `ShadcnCard(... onTap: () => _openEditor(...) ...)` trong itemBuilder mỗi màn.
- **CỘT chung:** `Nội dung`(flex4: [thumbnail/icon] + title + code nếu có) · **[meta riêng]** · `Submissions`(w110 phải: attemptsCount/submissionsCount) · `Status`(w120: adminStatus/approvalStatus) · `⋯`(w56: Edit(row-tap) / Approve nếu có / Delete). Meta riêng:
  - **A4 Reading:** `Difficulty`(w120) · `Đọc`(w90: `${minutesToRead} min`).
  - **A5 Listening:** `Code`(w120) · `Cues`(w80: totalCues).
  - **A6 Listening Comp:** `Difficulty`(w120) · `Thời lượng`(w90: minutesToComplete).
  - **A7 Writing:** `Level`(w110) · `Tasks`(w80: taskCount) — status = approvalStatus, nút approval vào ⋯.
  - **A8 Speaking:** `Sentences`(w110: totalSentences) — ít cột nhất.
- **GOTCHA:** mỗi màn giữ `AdminPaginationBar` sẵn; `AdminSkeleton.table`; nút Delete/Approve → ⋯ menu.

### A9 — Releases · `release_management/release_management_page.dart`
- **Anchor:** `_ReleaseItemCard(item: items[i], ...)` (trong `Column`/`for`).
- **CỘT:** `Version`(flex3: platform icon + `v{name}+{code}` + FORCE badge) · `Platform`(w120) · `Status`(w130: pill) · `Min version`(w120) · `Tạo`(w150: createdAt) · `⋯`(w56: Approve/Reject/Schedule/Publish/Rollback — nhiều action → menu; hành động chính theo status làm row-tap hoặc item đầu menu).
- **GOTCHA:** **destructive guard giữ nguyên** (Publish/Rollback/FORCE = filled danger + gõ xác nhận theo `_templates` §A4). KHÔNG hạ cấp confirm. Đang render toàn bộ (không pagination) → OK giữ (list ngắn) hoặc thêm `AdminPaginationBar` (defer).

### A10 — Ops Center cleanup · `ops_center/admin_ops_center_page.dart`
- **Anchor:** `class _PaginationBar` (private, `:1097`) + chỗ dùng nó.
- **Thao tác:** thay `_PaginationBar` → `AdminPaginationBar` (`layout/admin_widgets.dart:326`); `DataTable` header dùng `AdminWebUi.webTableHead`. Giữ `DataTable` (đã đúng).

**SYMBOL TABLE (verbatim, [CÓ]/[THÊM]):**
- [THÊM] `WebDataTable` / `WebTableColumn` — `lib/core/ui/widget/web_data_table.dart`.
- [CÓ] `TeacherWebUi.panelDecoration()` · `.webTableHead(context)` · `.userAvatarCircle(...)` · `.webBody(context)` · `.webCaption(context)` · `.metaMuted`.
- [CÓ] `AdminWebUi.panelDecoration()` · `.webTableHead(context)` · `.userAvatarCircle(...)`.
- [CÓ] `TeacherSkeleton.table({int rows})` · `AdminSkeleton.table({int rows})` · `.page(child)`.
- [CÓ] `AdminPaginationBar` (Total/rows-per-page/prev-next) · `AdminSearchField` · `AdminEmptyState`.
- [CÓ] status: `TeacherGradingPill(label,color,{alpha})` · `TeacherStatusPill` · admin `StatusBadge`/`UserRoleBadge`.
- [CÓ] menu: `UserActionMenu` · `ReportActionMenu` · `PopupMenuButton` + mẫu `_menuAction(icon,label,{danger})` (classroom_detail).
- [CÓ] `AppColors.outlineMuted/surfaceSubtle/textSecondary/danger/success/warning/info` · `AppSpacing.s*` · `AppRadius.card`.

---

## 6b. Ràng buộc UI/UX
- Editorial Black; token-only (0 `Color(0x…)`/`circular(<số>)`/`Duration(ms:N)` trong feature); KHÔNG skill color.
- Bảng: header + (nếu bảng dài) cân nhắc sticky header; số căn phải tabular; status = pill (không tô cả row); hover row `surfaceSubtle`; kẻ dọc `outlineMuted` + kẻ ngang giữa row.
- 4 states: loading = `*Skeleton.table` (KHÔNG spinner); empty = `*EmptyCard`/CTA; error = retry; success.
- Actions dồn vào **⋯ menu** mỗi row (icon+label); row-tap = hành động chính.
- content max: `contentMaxTable = 1280`.
- a11y: menu ⋯ có tooltip; status pill có Semantics; focus ring qua `focusableTile` nếu dùng.

## 6c. Backend
Không chạm (chỉ đổi render). Nếu A2/A9 muốn thêm pagination server → task backend riêng (defer).

---

## 7. Hồi quy tối thiểu (smoke) + verify
- Mỗi màn: mở → thấy bảng (cột thẳng, kẻ dọc/ngang) · search/filter/tabs/pagination vẫn chạy · ⋯ menu đủ action · row-tap mở đúng detail/editor · loading = skeleton table · empty/error đúng.
- Grading hub: Open-grade / Run AI / Release vẫn hoạt động. Users: ban/role/delete + dialog detail. Releases: destructive guard còn nguyên.
- Account test: `docs/dev/seeds/` (admin + teacher).
```bash
cd english_for_community/english_for_community
bash tool/ui_audit.sh teacher --list    # 0 (trừ whitelist)
bash tool/ui_audit.sh admin --list      # 0 (trừ whitelist)
dart analyze lib                          # 0 lỗi mới
flutter gen-l10n                          # nếu thêm header string
```

---

## 8. HANDOFF — Cursor IMPLEMENT (copy khối, biên giới cứng)
```text
Bạn là implementer. BƯỚC 0: đọc work-order docs/plantasks/FEATURE/20260711-web-list-to-table/work-order.md (§3, §5).
Làm THEO PHASE, P0 TRƯỚC (không có primitive thì dừng): tạo lib/core/ui/widget/web_data_table.dart theo §3.1 (trích từ teacher_classroom_detail_page.dart: _AssignmentTableHeader/_AssignmentRow/_vCellDivider/_cellPad/_tableText). Sau đó P1 (teacher T1→T3), P2 (admin A1→A9), P3 (A10). Mỗi màn = 1 PR nhỏ.
Với mỗi màn: thay khối itemBuilder→Card bằng WebDataTable(columns theo §5, cellBuilder trả nội dung ô); GIỮ NGUYÊN data/bloc/toolbar/search/filter/pagination; đổi skeleton cardList→table; dồn action vào ⋯ menu; row-tap = hành động chính.
TÁI DÙNG §5 SYMBOL TABLE — KHÔNG dựng lại pagination/skeleton/pill/avatar/menu.
TUYỆT ĐỐI KHÔNG: đổi bloc/event/state/entity/query; đụng live monitor/session console/calendar/dashboards; gỡ fork ShadcnCard toàn cục; bỏ pagination/filter; hạ cấp destructive guard (releases).
L10n: header cột mới (Status/Score/Role/…) → app_en.arb + app_vi.arb + flutter gen-l10n (tái dùng key sẵn nếu có).
VERIFY mỗi phase: dart analyze lib/<màn> sạch + ui_audit.sh (teacher/admin) 0 vi phạm + smoke §7. Dán tracker → báo Opus audit.
```

## 9. Checklist OPUS AUDIT (Phase 4)
- [ ] P0 `WebDataTable` đúng API §3.1; classroom_detail đã dùng lại (1 nguồn) hoặc quyết định giữ bespoke (ghi rõ).
- [ ] Mỗi màn convert: cột đúng §5, kẻ dọc/ngang thẳng, số căn phải, status pill (không tô row), hover.
- [ ] Data/bloc/toolbar/search/filter/pagination KHÔNG đổi; skeleton = table; empty/error đủ.
- [ ] Action đủ trong ⋯; row-tap đúng; grading Open/AI/Release + users ban/role + releases destructive-guard còn nguyên.
- [ ] Token-only; `ui_audit` teacher+admin = 0; `dart analyze` 0 lỗi mới; l10n EN+VI.
- [ ] KEEP-list (live/console/calendar/dashboard) KHÔNG bị đụng.
- [ ] Ghi Migration log `docs/ui-ux-system/11-implementation-mapping.md`.

---

## 10. Việc còn lại của DEV (ngoài task)
- Thêm pagination server cho A2 (submissions) / A9 (releases) nếu data lớn (backend task).
- Gỡ fork `content_widgets`/`ShadcnCard` toàn admin (nợ kỹ thuật doc `19`).
- Hợp nhất Ops Center `DataTable` vào `WebDataTable` (nếu muốn 1 pattern tuyệt đối).
