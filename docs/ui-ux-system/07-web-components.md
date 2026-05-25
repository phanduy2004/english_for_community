# 07 — Web components (teacher & admin)

> Mọi component dưới đây được dùng tại web. Mobile có spec riêng ở `04`.

## 1. Button (web)

| Variant | Height | Padding | Use |
|---------|--------|---------|-----|
| Filled primary | 36 | 16 ngang | CTA chính trong header / form |
| Filled subtle | 32 | 14 | Hành động phụ |
| Outlined | 36 | 16 | Cancel, secondary |
| Text | 32 | 10 | Inline action |
| Icon-only | 32×32 | 0 | Toolbar |
| Destructive | 36 | 16 | Xoá, đóng phiên |

- Label `web.label 12/600`.
- Hover: bg shift 4% darker (filled) hoặc bg `surfaceSubtle` (outlined/text).
- Focus visible ring: outline 2 `primary`, offset 2.

## 2. Data table

### 2.1 Anatomy
```
┌───────────────────────────────────────────────────────────┐
│ Toolbar: [search] [filters] [sort] [density]   [actions]  │
├───────────────────────────────────────────────────────────┤
│ Column header (12/600 uppercase tracking 0.4)             │
├───────────────────────────────────────────────────────────┤
│ Row 44h · cell padding 16 ngang · 13/400 textPrimary      │
│ Row hover bg surfaceSubtle                                │
├───────────────────────────────────────────────────────────┤
│ Footer: page x/y · rows per page                          │
└───────────────────────────────────────────────────────────┘
```

### 2.2 Quy tắc
- **Cột số/điểm/tiền**: `text-align: right`, font tabular.
- **Cột status**: dùng status pill (xem `04` §5.3) — KHÔNG đổi màu cả row.
- **Cột tên**: avatar 24 + tên 13/600 textPrimary + dòng dưới 12/400 textSecondary (vd email).
- Sticky header khi scroll.
- Selection checkbox cột đầu width 40.

### 2.3 Empty state trong bảng
- Không hiện row trống. Thay bằng banner trong vùng table: icon 32 + title `web.h3` + body + CTA.

## 3. Drawer (chi tiết bên phải)

- Width 520 (mặc định) hoặc 720 cho editor.
- Slide từ phải, motion `m.web 160ms`.
- Header sticky: title `web.h2` + close 18.
- Action footer sticky bottom: padding 16, border-top `outline`, [Cancel] + [Save].

## 4. Dialog (modal)

- Width 480 phổ thông; 640 cho confirm phức tạp.
- Padding 24, radius 16, shadow `e.3`.
- Backdrop: `rgba(0,0,0,.40)`.
- Close button góc phải trên 24×24.

**Teacher workspace:** bắt buộc dùng `TeacherDialogShell` + catalog trong [`14-teacher-dialogs.md`](14-teacher-dialogs.md) (account hub, edit profile, password, picker). Không bottom sheet cho cài đặt tài khoản giáo viên.

## 5. Filter & toolbar

- Toolbar 56h, sticky trong card list.
- Trái: `Search` 36 cao 320 width + chip filter (chip pill 28).
- Phải: `Sort` dropdown + density toggle + actions.
- Chip filter active có dấu `×` để remove riêng từng filter.

## 6. Tabs với nội dung dày

- Sticky tabs khi scroll.
- Có thể kèm count: `Lượt nộp · 24` (count `web.micro` trong pill nhỏ).

## 6.1 `TeacherExamParticipantStatusChip` (live session)

> Spec đầy đủ: [`16-teacher-live-participant-status.md`](16-teacher-live-participant-status.md).

| Variant | Khi dùng |
|---------|----------|
| Lobby | `Not ready` · `Ready` |
| Live | `In progress` · `Submitted` · `Time expired` · `Removed` |

- Dùng trong **Session control** roster và **Live monitor** student card — **một component**, map từ server.
- Integrity risk = icon flag riêng, không thay chip chính.

## 7. Form

### 7.1 Field
- Label trên `web.label 12/600 textPrimary`, gap 6.
- Input height **36**, radius **10**, viền `outlineStrong`.
- Helper text 12/400 textSecondary; lỗi 12/400 `danger`.
- Disabled: bg `surfaceSubtle`, fg textMuted.

### 7.2 Group
- 2 cột grid (gutter 24) trên `md-web` trở lên.
- Section divider: `outlineMuted` 1px + tiêu đề `web.h3`.

### 7.3 Save bar
- Khi có thay đổi chưa lưu: bottom sticky bar trong page (KHÔNG floating), bg `surfaceCard`, border-top, [Discard] + [Save changes].

### 7.4 Form nhiều section (teacher workspace) — wizard giao bài / tương tự

> **Mục tiêu:** nhất quán nhãn – khung – typographic; tránh label Material dính viền và segmented lệch màu.

- **Card section**: mỗi cụm logic = một `AppCard` (outline), padding **24**, k-spacing giữa các card **24** (`sectionGap`).
- **Tiêu đề card** một dòng (`sectionTitle`) — **không** lặp lại cùng ngữ nghĩa ngay bên dưới (vd đã có "Đối tượng" thì không thêm label trùng trên `SegmentedButton`).
- **Control label**: luôn **phía trên** ô, gap **6** tới field — **không** dùng `InputDecoration.labelText` nổi cho text/dropdown trên web teacher; pattern: `Column → TeacherWebUi.formFieldLabel → SizedBox(6) → field`.
- **TextField / Dropdown**: `isDense: true`, `contentPadding` **12 ngang × 12 dọc** (`TeacherWebUi.formInputContentPadding`), `filled: true`, `fillColor: surfaceCard`, radius **10**, border `outline`, focused `primary` 1.5px; style chữ nhập **15/400** `textPrimary` — ô phải đủ cao (~**44–48**) để chữ không trông "bé" trong khung.
- **Date/time pickers (dạng ô chạm)**: cùng viền/fill/radius/padding với text field; một dòng giá trị; placeholder optional `textMuted`; icon lịch **18** `textMuted` góc phải.
- **SegmentedButton**: `TeacherWebUi.segmentedControlStyle`; `showSelectedIcon: false` (mặc định gọn); chưa chọn `surfaceCard`, đã chọn `primaryTint` + chữ `primary`; mọi segment chưa chọn **cùng** nền (không xám lệch nhau).
- **Switch + đoạn mô tả**: `SwitchListTile` + `subtitle` `metaMuted` (`textSecondary`, height 1.45); có thể tách bằng `border-top outlineMuted` khi là khối tùy chọn cuối card.
- **CTA cuối trang**: `FilledButton` `primary`, full-width, height **48**, radius **10**.

**Code tham chiếu:** `TeacherWebUi.formInputDecoration`, `formFieldLabel`, `segmentedControlStyle`; `TeacherAssignmentWizardPage`.

## 8. Status pill / chip

- Pill 22 cao, padding 10 ngang, radius 999.
- 4 tone semantic giống mobile (success/warning/danger/info) + tone neutral cho `Draft / Archived`.
- Font `web.micro 11/500`. KHÔNG bold.

## 9. Card

- Padding 24 (web), radius 12, viền 1px `outline`, không shadow.
- Card có header + body: header `web.h3 15/600` + body `web.body`.
- Card click-able (vd classroom card): hover bg `surfaceSubtle`, cursor pointer.

## 10. Tooltip

- Bg `surfaceInverse`, fg white, padding 8 ngang 6 dọc, radius 6.
- Font `web.micro 11/500`. Hiện sau 300ms hover.
- Có mũi tên 6×6.

## 11. Popover / dropdown

- Width tối thiểu 200, max 320 (trừ menu user / search).
- Item 36 cao, hover `surfaceSubtle`. Icon 16 trái + label 13/400.
- Section divider `outlineMuted` 1px nếu có nhóm.

## 12. Code / log block (admin)

- Font `JetBrains Mono 12/400`.
- Bg `#0F172A` (mã đen tinh tế), fg `#E2E8F0`. Radius 10. Padding 16.
- Có copy button góc trên phải.

## 13. Editor (exam, content)

- Layout 2 cột: editor trái 640 — preview phải 480 trên `lg-web` trở lên.
- Editor body bg `surfaceCard`, viền `outline`. Preview bg `surface` để tách thị giác.
- Toolbar editor 40 cao: bold / italic / list / link, icon 16.

## 14. File upload

- Drop zone height 160, viền dashed 1px `outlineStrong`, bg `surfaceSubtle`.
- Khi drag-over: viền `primary`, bg `primaryTint`.
- Item upload: card list 60 cao, progress bar trong card.

## 15. Charts (admin / analytics)

- fl_chart / Recharts với `chartPrimary` cho line; trục dùng `chartGrid` mảnh.
- Tooltip hover dạng popover (xem §10).
- Legend dưới chart, font `web.micro`.

## 16. Pagination

- 32 cao; mỗi nút 32×32; active bg `primaryTint` fg `primaryDark`.
- Có select rows-per-page (10/20/50/100).
