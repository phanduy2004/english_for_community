# 08 — Web screens (teacher & admin)

> Áp dụng các foundation `06` và component `07`. Mỗi spec dưới đây mô tả **layout + state + l10n key chính**.

---

## A. TEACHER WORKSPACE

### A0. Teacher mobile (&lt;768px)

**Shell:** Bottom `NavigationBar` 60dp — Dashboard · Exams · Calendar · Analytics. Sub-routes (lớp, chấm bài, live session) ẩn bottom nav, chỉ **back** + title.

**Layout:**
- Padding trang **16**; title **18/600** (`TeacherMobileUi.pageTitle`).
- **1 CTA primary** / màn — full width **48dp** trong `TeacherMobileBottomActionBar` (live session: Bắt đầu / Kết thúc; wizard: Tạo bài giao).
- Header actions (New exam, Export…) → hàng dưới title khi hẹp; không kéo full bleed ngang màn hình trống.

**Tham chiếu:** `04-mobile-components` §1 (button), §4.3 (bottom bar).

### A1. Teacher dashboard (route gốc)

**Mục tiêu:** giáo viên thấy ngay điều cần làm hôm nay.

**Layout (v3 compact):**
- Page header: `web.pageTitle` 16/600 + meta `web.caption` + actions 32px (`compactFilled` / `compactOutlined`).
- Hàng 1: KPI grid 4 cột — số `web.kpi` 15/600, label `web.caption`, icon 32×32, card padding 12×8.
- Hàng 2: 2 cột (chiều cao cố định — không kéo dài trang).
  - Trái: `Cần chấm` — tối đa **5** card gần nhất; badge số lượng; footer `+N bài` / **Xem tất cả** → dialog cuộn danh sách đầy đủ.
  - Phải: `Phòng trực tiếp` — carousel ngang (~200px), gợi ý vuốt ngang; từ **4** phòng trở lên có **Xem tất cả** → dialog danh sách dọc.
- Hàng 3: full-width `Lớp của tôi` — card grid lớp 3 cột.

### A2. Classroom detail

**Tabs:** Overview · Members · Assignments · Sessions · Settings.

- **Overview**: card top metrics + chart engagement 30 ngày + danh sách bài hoạt động gần.
- **Members**: bảng danh sách (avatar + tên + email + ngày join + status + action). Toolbar có search + invite button. Bulk action khi select nhiều row.
- **Assignments**: bảng bài đã giao (đề + due + mode + #đã nộp / tổng + status pill).
- **Sessions**: lịch — segmented (List · Calendar). Mỗi session có card 88h.
- **Settings**: form 1 cột 720 max — tên lớp, mô tả, mã mời (rotate), chính sách join.

### A3. Exam editor (skills exam)

**Layout 2 cột (lg-web):**
```
┌──────────────────────────────────────┬────────────────────────┐
│ Editor 640                            │ Preview 480            │
│                                       │                        │
│ Title                                 │ ┌─ Học sinh sẽ thấy ─┐ │
│ Skill toggles (Reading/Listening/...) │ │ Hub bài thi mock   │ │
│ Per-skill resources panel             │ │                    │ │
│ Grammar block (MCQ list)              │ │                    │ │
│                                       │ │                    │ │
└──────────────────────────────────────┴────────────────────────┘
```

- Save bar bottom với `Last saved 12:48` + [Discard] [Save draft] [Publish].
- Skill toggles dạng switch + label kỹ năng + count tài nguyên.
- Resources picker: drawer 520 mở phải khi nhấn `Choose resource`.

### A3.1 Giao bài kiểm tra (assign dialog)

**Mở:** từ Ngân hàng đề → **Tạo bài giao** → `TeacherDialogs.showAssignExam` — **dialog căn giữa** (`14-teacher-dialogs` §4.3), không full-page.

| Thuộc tính | Giá trị |
|------------|---------|
| Width | 560 |
| `maxBodyHeight` | 520 |
| Footer | Cancel + **Giao bài** |

**Body (thứ tự):**
1. Banner nếu đề chưa `published`.
2. **Đối tượng** — segmented Lớp / Link công khai + dropdown lớp hoặc field link.
3. **Hình thức** — grid 2×2 mode card (Tự học / Theo lịch / Trực tiếp / Luyện tập) + hint ngắn; khối lịch động (due / opens+closes / info realtime).
4. Ghi chú Schedule: Mở · Hạn nộp · Đóng vs «Đang diễn ra» trên lịch.
5. Preset (nếu có) + **ExpansionTile** «Lượt làm & kết quả».

**Legacy route** `/teacher/exams/:id/assign` vẫn tồn tại: mở dialog rồi `pop` — không render form full-width.

### A3.2 Sổ điểm lớp (gradebook)

**Route:** `/teacher/classroom/:classroomId/gradebook` — `TeacherGradebookPage` + `TeacherGradebookView`.

**API:** `GET /api/teacher/exams/classrooms/:id/gradebook` → `summary`, `assignments[]`, `rows[]`, `classAverages[]`; CSV qua endpoint export (clipboard toast).

| Khối | Nội dung |
|------|----------|
| Header | Breadcrumb Dashboard → Lớp → Sổ điểm; Refresh + **Xuất CSV** (góc toast, không full-width) |
| KPI (4) | Số HS · Số bài giao · % TB lớp · Ô cần chấm |
| Toolbar | Tìm tên/email · lọc **hình thức** (ẩn cột, không lọc hàng) · sort Tên / TB · chip «Ẩn HS chưa nộp» · đếm kết quả |
| Bảng | Scroll ngang; cột HS 220px sticky feel; mỗi bài 136px — **tooltip** tiêu đề đầy đủ + chip mode; ô: % + `awarded/max`, pill «Chờ chấm», màu theo % |
| Hàng cuối | **Trung bình lớp** theo từng cột + cột TB HS |
| Tương tác | Tap ô có `attemptId` → chấm attempt; tap ô trống / chưa làm → grading hub assignment |

**Không** dùng `DataTable` hẹp cột (truncate `[SEED:HoangDo…`). Cột hiển thị `shortTitle` từ API; full title trong `Tooltip`.

### A4. Grading hub (assignment-level)

**Route:** `/teacher/exam-grading/:assignmentId` — `TeacherExamGradingPage`.

**Anatomy (v3):**
- **Page header** (`TeacherPageScaffold`): tiêu đề = **tên đề**; subtitle = `Lớp · Hình thức · Loại đề` (vd. `Lớp 10A · Live session · Đề 4 kỹ năng`); breadcrumb Dashboard → Lớp → Bài làm học sinh; actions = batch AI / Finalize / Release (icon 32).
- **Context card** (`TeacherGradingHubContextHeader`): chip **Lớp** (tap → classroom detail), **Mode** (self-paced / scheduled / **live session** / practice), **Format** (integrated / skills / classic), **Audience**; dòng lịch từ `assignment.config` (due / opens–closes / time limit).
- **KPI trong card:** Đã nộp · Đang làm · Cần chấm · Nộp thiếu (4 cột mini, `web.kpi`).
- **Export Excel:** icon tải trên header → `GET …/assignments/:id/attempts/export.xlsx` → file `.xlsx` (cột HS, email, trạng thái, điểm /10 hoặc %, thời gian).
- **Filter chips** (`TeacherWebUi` outline / `primaryTint` khi chọn).
- **Danh sách:** `TeacherGradingAttemptCard` — `AppCard` outline, avatar, status pills, điểm 0–10, meta thời gian, CTA `Grade` (`compactFilledStyle` 32).
- API: `GET …/assignments/:id/attempts` → `assignment.classroomName`, `classroomId`, `mode`, `examFormat`, `config`.

**Không** chỉ hiện tên đề mà thiếu lớp/hình thức — giáo viên phải nhận ra ngay bài **live** hay **tự luyện** trước khi chấm.

### A5. Grade attempt (drawer hoặc full page)

**Mục đích:** chấm 1 lượt làm.

- Header sticky: avatar + tên + đề + status chips (Submitted/Graded/Released).
- **Đề tích hợp / skills** (`integrated_four_skills`, `skills_exam`): card **Điểm theo kỹ năng** (`IntegratedGradingScorePanel`) — **không** dùng `X / Y pts` hay progress bar tỷ lệ điểm tối đa.
  - Bảng 2 cột: **Kỹ năng** | **Điểm** (0–10): Nghe, Đọc, Viết, Nói, Ngữ pháp (theo thứ tự snapshot).
  - Chi tiết phụ (vd. `12/15 correct`) dưới tên kỹ năng khi có.
  - Hàng cuối nổi bật: **Điểm TB** hoặc **TB tạm** = trung bình cộng các thành phần đã chấm; kỹ năng **Pending** chưa vào TB.
  - Gợi ý công thức một dòng phía trên bảng.
  - Nói / Viết: nhập 0–10 + Lưu trong card từng kỹ năng (footer section).
- **Đề classic:** total score card `X / Y pts` + linear progress (giữ nguyên).
- Sections (theo thứ tự đã có trong app):
  - **Grammar**: từng câu — card outline. MCQ dùng `McqGradingReviewList` (xanh đúng / đỏ sai).
  - **Per skill (L/S/R/W)**: card có toggle “Xem bài làm” → mở submission CMS bên trong card. Hiển thị editor read-only / audio player phù hợp kỹ năng.
- Footer sticky: [Run AI] [Save] [Finalize] [Release].

### A6. Sessions / live console

> **Chi tiết layout:** [`13-teacher-live-session-console-layout.md`](13-teacher-live-session-console-layout.md)

- **Tabs only** dưới page header — không card metadata cố định trên tabs.
- **Live monitor:** toolbar tóm tắt + filter (~56px) → list HS scroll (`Expanded`).
- **Metadata:** `TeacherExamSessionCompactStrip` (mặc định thu gọn) trong tab Session control / lobby.
- **Trạng thái HS (cả 2 tab):** `TeacherExamParticipantStatusChip` — lobby: Ready / Not ready; live: **Đang làm** / **Đã nộp** / Hết giờ / Đã rời. Chi tiết [`16-teacher-live-participant-status.md`](16-teacher-live-participant-status.md).
- **Session control khi live:** summary `N in progress · M submitted` + roster có **cùng chip** (không chỉ nút Kick).
- Actions: [Start session] [End and submit all] — header web / bottom bar mobile.
- Thẻ HS compact: status chip + progress + skill strips + icon watch (không nút full-width).

### A7. My exams list

- Bảng card view (3 cột) hoặc list (toggle segmented).
- Mỗi card: title + meta `Reading · Listening · Grammar` + status pill.
- Hover shows action `Edit` `Duplicate` `Archive`.

---

## B. ADMIN CONSOLE

> **v3 compact** — cùng shell/token với teacher (`06-web-foundations`, `07-web-components`): sidebar 212px, top bar 44px, page header 52px min, nút 32px. Toast góc phải qua `AdminCornerToast` (= teacher). **Giữ** bảng màu icon kỹ năng CMS (`AdminSkillPalette`).

### B0. Admin shell

| Thuộc tính | Giá trị |
|------------|---------|
| Sidebar | 212 expanded / 48 collapsed; nav item **30px**; group label `web.tableHead` |
| Top bar | 44px — menu (khi collapsed) + route label + notification icon 32 |
| Fallback | &lt;768px: full-screen “dùng desktop” |
| Theme | `WorkspaceLayoutScope` + `AppTheme.mergeWorkspaceWeb` |

**Files:** `admin_shell.dart`, `admin_web_ui.dart`, `admin_page_scaffold.dart`.

### B1. Admin dashboard

**Route:** `/admin-dashboard` — `AdminDashboardPage`.

| Khối | Nội dung |
|------|----------|
| Header | `adminOverviewTitle` + ngày (caption) + segmented Day/Week/Month (32px) |
| KPI (4) | Submissions · AI cost · Reports · Active users — `AdminKpiCard`, icon 32×32 màu accent |
| Chart | Activity by skill — legend màu `AdminSkillPalette`; bar chart scroll ngang |
| Hub | `managementSection` (`sectionTitle`) + grid `AdminNavTile` — **icon 40×40 màu accent** (content, reports, users, teacher apps, ops, releases) |

### B2. User management

- `AdminPageScaffold`: breadcrumb Overview → Users; `AdminSearchField`; tabs All/Today/Online; trash = compact outlined.
- List: `UserCard`; empty `AdminEmptyState`.

### B3. Content management (CMS)

**Hub** `/admin/content` — `ContentDashboardPage`:
- Breadcrumb Overview → Content Manager.
- Grid 4× `AdminSkillCard` — **màu icon giữ nguyên:** Writing `#EF4444`, Speaking `#3B82F6`, Reading chart highlight, Listening `#8B5CF6`.
- Listening → dialog chọn Dictation / Comprehension.

**List/editor:** nested routes theo skill; editor pattern 2 cột khi có preview (giống A3).

### B4. Submission management

- Bảng review bài học sinh nộp lên ngân hàng nội dung (nếu áp dụng).
- Action: approve / reject / edit before publish.

### B5. Report management

- Inbox style: list trái 360 (item 88) + detail phải.
- Status: open / in_progress / resolved / dismissed.

### B6. Teacher application review

- List đơn → drawer chi tiết (lý do, CV, audit) → [Approve] / [Reject + reason].
- Audit log inline ở cuối drawer.

### B7. App release management

- Bảng release: version / channel / status / created / published.
- Status pipeline: Pending approval → Approved → Scheduled → Published → Rolled back.
- Drawer chi tiết: changelog, artifacts, action [Approve] [Schedule] [Publish] [Rollback].
- Có graph rollout % nếu staged.

### B8. Audit log

- Compact density (row 36).
- Cột: time / actor / action / target / metadata (truncate 60 char + tooltip full).
- Filter theo actor / action type / time range.

---

## C. SHARED PATTERNS

### C1. Confirmation flow
- Hành động phá huỷ (xoá / đóng / phát hành) → dialog confirm 480 width:
  - Title `Bạn chắc chắn muốn ...?`
  - Body 13/400 textPrimary giải thích **hệ quả**.
  - 2 actions: Outlined `Huỷ` + Destructive `Xác nhận`.

### C2. Bulk action toolbar
- Khi select rows: top bar bảng đổi sang “Selected 5 · [Action] [Action]” bg `primaryTint`.
- Action chính bên phải; close `×` góc trái để clear selection.

### C3. Saved view / filter preset
- Cho phép admin lưu filter (URL param + name).
- Hiển thị dropdown “Views”: Default / All teachers pending / Reports today …

### C4. Keyboard shortcut hints
- Hiển thị `kbd` trong tooltip / palette: `⌘K`, `⌘S`, `⌘Enter` (publish), `Esc` (close drawer).
- Footer page có dòng nhỏ `Shortcuts: ⌘K to search · ? for help`.

---

## D. State chung cho mọi web screen

- **Loading**: skeleton table (header + 6 rows) hoặc skeleton card 3 cột.
- **Error toàn page**: full-screen message 480 width + Retry + link `Báo lỗi`.
- **Permission denied**: page với icon lock + dòng `Bạn không có quyền truy cập trang này` + nút quay lại.
- **404**: minimal centered, không vẽ vời.
