# 06 — Web foundations (cho teacher & admin)

> Đối tượng: trình duyệt desktop & laptop (1024–2560 px). Trải nghiệm chính của giáo viên & admin.
>
> ⚠️ **Số liệu đã đồng bộ với compact v3** (`00-compact-density-v3.md`) và code `TeacherWebUi`/`AdminWebUi` (06/2026): sidebar **212 / 48**, top bar **44**, nav item **30**, button **32**, row default **40**. Các con số v2 cũ (240/56/36/44) đã thay. Đánh giá hiện trạng & tiêu chuẩn bổ sung: [`18-teacher-web-audit-and-standards.md`](18-teacher-web-audit-and-standards.md).

## 1. Breakpoints web

| Lớp | Width | Mô tả |
|------|-------|-------|
| `sm-web` | 768–1023 | Tablet ngang / cửa sổ nhỏ — show sidebar collapse |
| `md-web` | 1024–1279 | Laptop nhỏ — sidebar full, content max 960 |
| `lg-web` | 1280–1599 | Laptop chuẩn — content max 1120, có chỗ cho aside |
| `xl-web` | 1600+ | Màn rộng — content max 1280, aside 320 |

> Dưới 768 (teacher): **mobile shell** — bottom nav 4 mục + mật độ mobile (`TeacherMobileUi`). CTA chính dùng **bottom action bar** full-width 48dp; toolbar phụ vẫn compact intrinsic-width. Editor đề phức tạp vẫn khuyến nghị tablet ngang / laptop.

## 2. Layout chuẩn

```
┌────────┬──────────────────────────────────────────────────┐
│        │ Top bar (sticky 56h)  · search · profile · help │
│ Side   ├──────────────────────────────────────────────────┤
│ bar    │  Page header (h1 + breadcrumb + primary action) │
│ 240px  ├──────────────────────────────────────────────────┤
│        │                                                  │
│ logo   │   Content max 1120 (centered or left-aligned)    │
│ nav    │                                                  │
│ ...    │                                                  │
│        │                                                  │
│ user   │                                                  │
└────────┴──────────────────────────────────────────────────┘
```

### 2.1 Sidebar
- Width **212px** (`TeacherWebUi.sidebarWidth`). Collapsed: **48px** icon-rail (`sidebarCollapsedWidth`) — tự thu khi viewport < 1024, fallback mobile < 768.
- Bg `surfaceCard`, viền phải 1px `outline`.
- Logo 28 + tên app `web.h3`. Khoảng cách dưới logo 24.
- Group label `web.tableHead` 11/600 letterSpacing 0.4 textSecondary (không uppercase — khớp `webTableHead`).
- Item nav: **30 cao** (`sidebarItemHeight`), icon 18, label `web.body 13/400 textPrimary`. Active: bg `primaryTint`, fg `primaryDark` 13/600.
- Item active: bg `primaryTint`, fg `primaryDark` 13/600, không indicator strip (subtle).
- Footer sidebar: avatar 28 + tên + email truncate + nút **⋮** (`teacherAccountOpenMenu`).
- Menu tài khoản (`showTeacherAccountMenu`): **dialog căn giữa** (mọi breakpoint), không bottom sheet mobile học sinh. Shell: `TeacherDialogShell` (`07` §4 — width 440, padding 24, nút đóng góc phải).
- Hub: thẻ identity + `TeacherDialogOptionTile` theo nhóm; sub-dialog cho **sửa hồ sơ**, ngôn ngữ, múi giờ, đổi mật khẩu, xóa tài khoản (không route `/profile/edit`).
- Footer hub: `compactOutlinedStyle` đăng xuất + text danger xóa tài khoản.
- Spec đầy đủ: [`14-teacher-dialogs.md`](14-teacher-dialogs.md).
- Teacher đăng nhập → redirect `/teacher` (dashboard), không vào shell học sinh (`/homePage`).

### 2.2 Top bar
- **44h** (`TeacherWebUi.topBarHeight`), bg `surfaceCard`, viền dưới 1px `outline`. Sticky top.
- Trái: breadcrumb hoặc page context. Giữa: search global (chỉ admin) hoặc trống.
- Phải: icon `notification` 18 + avatar 28 menu.
- Search global mở `Cmd+K` palette (Linear-style).

### 2.3 Page header (v3)
- Padding `20×16×20×12` (`TeacherWebUi.pageHeaderPadding` — top **16** khớp `pagePadding`); min height **52**.
- Vùng nội dung dưới header: `TeacherPageScaffold` bọc `pagePadding` (**20 ngang / 16 trên+dưới**). ListView con dùng `TeacherWebUi.pageScrollPadding` (chỉ `bottom`) để không double padding.
- Title: `web.pageTitle` **16/600** (không 22px).
- Actions: Filled/Outlined **32px** (`compactFilledStyle` / `compactOutlinedStyle`).

## 3. Spacing & density (v3)

- `pagePadding`: **20 ngang / 16 dọc**.
- `cardPadding`: **12–16**.
- `cardGap` grid: **12**.
- Section gap dashboard: **20** (`AppSpacing.s6`).

## 4. Container max-widths

| Loại nội dung | Max width | Note |
|---------------|-----------|------|
| Form, settings | 720 | Đọc dễ, không kéo dài |
| Editor (exam, content) | 960 | Có panel preview phía phải tuỳ chọn |
| Dashboard, analytics | 1120 | Card grid 3 cột |
| Data table full | 1280 | Cho phép scroll ngang khi cần |
| Documentation/long text | 720 | Văn bản đọc kỹ |

## 5. Grid system

- **12 cột**, gutter 24, margin 32.
- Card grid: `repeat(auto-fit, minmax(280px, 1fr))` cho dashboard.
- Form: 2 cột field trên `md-web`, 1 cột dưới đó.

## 6. Navigation patterns

### 6.0 URL trên trình duyệt (Flutter Web)

- App teacher/admin là **SPA** (một file `index.html`, điều hướng bằng **go_router**).
- Mỗi màn có **path riêng**, ví dụ:
  - `/teacher` — dashboard
  - `/teacher/exams` — ngân hàng đề
  - `/teacher/exams/{examId}/integrated-edit` — soạn đề kỹ năng
  - `/teacher/exam-grading/{assignmentId}` — hub chấm bài
  - `/teacher/exam-grading/{assignmentId}/attempt/{attemptId}` — chấm một bài
- **Path URL** (không `#`): bật trong `main.dart` qua `configureWebUrlStrategy()` — thanh địa chỉ đổi khi `context.push` / `context.go`, có thể bookmark & F5 (cần server rewrite về `index.html` khi deploy).
- Tránh `Navigator.push(MaterialPageRoute(...))` cho màn chính — không cập nhật URL (ví dụ live screen nên có route sau).

### 6.1 Breadcrumb
- 12/500 textSecondary; chip cuối active textPrimary.
- Tách bằng `chevron_right` 14.

### 6.2 Tabs (in-page)
- Underline indicator dày 2 `primary`. Label `web.body 13/600` khi active, `13/400 textPrimary` khi không.
- Khoảng cách giữa tab 24; tab có thể có badge `Beta` / số lượng.

### 6.3 Segmented (chuyển view ngắn)
- Khi cần chuyển 2–4 chế độ (List / Calendar / Board): segmented control 32 cao, radius 8, item active bg `surfaceCard` + shadow `e.1`.

### 6.4 Command palette (Cmd+K)
- Đặc thù **admin**. Tất cả tác vụ chính có thể tìm bằng từ khoá.
- Modal 640×480, blur backdrop, danh sách 36 cao, kbd shortcut hiện bên phải.

## 7. Page header pattern (chuẩn)

```
<page-header>
  <breadcrumb> Classes / Lớp 12A / Bài kiểm tra </breadcrumb>
  <h1>Bài kiểm tra cuối kỳ</h1>
  <actions>
    [Outlined Lưu nháp] [Filled Xuất bản]
  </actions>
  <meta-row> Updated 2h ago · 3 sections · Draft </meta-row>
</page-header>
```

- Meta row dưới h1: `web.body 13/400 textPrimary` + tag dọc theo bằng dấu `·`.

## 8. Color usage on web

- Background **`surface`** cho main; sidebar **`surfaceCard`** trắng.
- Hover row trên table: bg `surfaceSubtle`. Active row: `primaryTint`.
- Selection: checkbox vuông 16, viền `outlineStrong`, tick `primary`.

## 9. Table density

| Density | Row height | Token | Use |
|---------|------------|-------|-----|
| Compact | 32 | `tableRowCompact` | Admin audit log, gradebook lớp đông |
| Default | 40 | `tableRowDefault` | Hầu hết bảng (lớp, học sinh, bài) |
| Comfortable | 52 | — | Bảng có 2 dòng nội dung mỗi cell |

> Mặc định **default 40** (`TeacherWebUi.tableRowDefault`). Spec đầy đủ data-table: [`18`](18-teacher-web-audit-and-standards.md) §5.5.

## 10. Saving & autosave indicators

- Field có autosave: chấm 6 textMuted khi idle, đổi sang `success` 800ms khi saved.
- Form lớn (editor exam): top right `Saved 12:48 PM` 12/400 textSecondary; lỗi → `Sync failed · Retry` `danger`.

## 11. Empty state web

- Width 480, centered trong content.
- Illustration / icon 48, title `web.h2`, body `web.body`, CTA Filled.

## 12. Loading

- **Skeleton**: cùng kích thước thật với content sắp render.
- **Optimistic**: cập nhật UI ngay, rollback nếu API lỗi (thông báo toast).

## 13. Dark mode (chưa hỗ trợ — nhưng giữ chỗ)

- Tất cả token dùng tên ngữ nghĩa (không hardcode hex trong widget) → tương lai bật dark chỉ cần đổi map token.
