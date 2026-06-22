# 07 — Web components (teacher & admin)

> Mọi component dưới đây được dùng tại web. Mobile có spec riêng ở `04`.
>
> ⚠️ **Đồng bộ compact v3** (`00`) + code `TeacherWebUi` (06/2026): button **32** (primary) / **28** (secondary), input **32**, card radius **10** (`AppRadius.card`). Số v2 cũ (36/12-radius-card) đã thay. Đánh giá & tiêu chuẩn bổ sung: [`18`](18-teacher-web-audit-and-standards.md).

## 1. Button (web — compact v3)

| Variant | Height | Style helper (`TeacherWebUi`) | Use |
|---------|--------|-------------------------------|-----|
| Filled primary | **32** | `compactFilledStyle` | CTA chính header / form |
| Outlined | **32** | `compactOutlinedStyle` | Cancel, secondary |
| Destructive outlined | **32** | `compactDangerOutlinedStyle` | Xoá, đóng phiên |
| Filled subtle | **28** | `buttonHeightSecondary` | Hành động phụ |
| Icon-only | **32×32** | `compactHeaderIconStyle` | Toolbar |
| Text / inline | intrinsic | `linkActionStyle` | Action trong bảng (Open, Grade) |

- Padding ngang **12** (`_compactButtonPadding`), radius **8** (`AppRadius.input`), label `web.label 12/600`.
- Hover: bg shift 4% darker (filled) hoặc bg `surfaceSubtle` (outlined/text).
- Focus visible ring: outline 2 `primary`, offset 2 — **bắt buộc cho mọi phần tử tap được, không chỉ button** ([`18`](18-teacher-web-audit-and-standards.md) §5.9).

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

- Width 480 phổ thông; 560 cho assign/giao bài; 640 cho confirm phức tạp.
- Padding 24, **radius 16** (`TeacherDialogShell` đang hard-code 16; token `AppRadius.sheet = 14` — cần thống nhất, xem [`18`](18-teacher-web-audit-and-standards.md) §3.2).
- Backdrop: `scrim` ≈ `rgba(0,0,0,.40)`.
- Close button góc phải trên 24×24.
- **Hành động không thu hồi** (phát hành kết quả, kết thúc phiên): nút **filled danger** + banner hệ quả + gõ xác nhận ([`18`](18-teacher-web-audit-and-standards.md) §5.8).

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

### 7.1 Field (compact v3)
- Label trên `web.label 11/600 textPrimary`, gap 6 (`TeacherWebUi.formFieldLabel`) — **không** dùng `InputDecoration.labelText` nổi.
- Input height ~**32** (`isDense`), content padding **10×8** (`formInputContentPadding`), radius **10**, fill `surfaceCard`, viền `outline`; focus `primary` 1.5 (`formInputDecoration`).
- Helper text 11/400 textSecondary; **lỗi 11/400 `danger` inline ngay dưới ô** — validate on blur → on change, KHÔNG dùng toast cho lỗi validate ([`18`](18-teacher-web-audit-and-standards.md) §5.6).
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
- **TextField / Dropdown**: `isDense: true`, `contentPadding` **10 ngang × 8 dọc** (`TeacherWebUi.formInputContentPadding`, compact v3), `filled: true`, `fillColor: surfaceCard`, radius **10**, border `outline`, focused `primary` 1.5px; chữ nhập `web.body 13` `textPrimary`.
- **Date/time pickers (dạng ô chạm)**: cùng viền/fill/radius/padding với text field; một dòng giá trị; placeholder optional `textMuted`; icon lịch **18** `textMuted` góc phải.
- **SegmentedButton**: `TeacherWebUi.segmentedControlStyle`; `showSelectedIcon: false` (mặc định gọn); chưa chọn `surfaceCard`, đã chọn `primaryTint` + chữ `primary`; mọi segment chưa chọn **cùng** nền (không xám lệch nhau).
- **Switch + đoạn mô tả**: `SwitchListTile` + `subtitle` `metaMuted` (`textSecondary`, height 1.45); có thể tách bằng `border-top outlineMuted` khi là khối tùy chọn cuối card.
- **CTA cuối trang**: `FilledButton` `primary`, full-width, height **48**, radius **10**.

**Code tham chiếu:** `TeacherWebUi.formInputDecoration`, `formFieldLabel`, `segmentedControlStyle`; `TeacherAssignmentWizardPage`.

## 8. Status pill / chip

- Pill 22 cao, padding 10 ngang, radius 999.
- 4 tone semantic giống mobile (success/warning/danger/info) + tone neutral cho `Draft / Archived`.
- Font `web.micro 11/500`. KHÔNG bold.

## 9. Card (compact v3)

- Padding **12–16** (web compact, `00`), radius **10** (`AppRadius.card`), viền 1px `outline`.
- Hai biến thể (`TeacherWebUi`): `cardDecoration()` có shadow nhẹ (`cardShadow`) · `panelDecoration()` phẳng, chỉ viền (kiểu Linear/Stripe list).
- Card có header + body: header `web.h3 13/600` + body `web.body 13`.
- Card click-able (vd classroom card): hover bg `surfaceSubtle`, cursor pointer, **focus ring** khi `Tab`.

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

## 17. Teacher dashboard (v4)

> Layout đầy đủ: [`17-teacher-dashboard-layout.md`](17-teacher-dashboard-layout.md).

| Component | Mô tả |
|-----------|--------|
| `TeacherDashboardPanel` | Section card có title/subtitle/trailing; `fillHeight` = 340h work zone |
| `TeacherDashboardAttentionStrip` | Chip cảnh báo vàng — pending join, due, grading |
| `TeacherDashboardQuickActions` | Chip ngang scroll; 1 chip `filled` primary |
| `TeacherDashboardClassroomTile` | Tile lớp trong grid — icon, tên, HS, mã mời + copy |
| `TeacherDashboardSectionHeader` | Title + count badge + «Xem tất cả» |
| `TeacherDashboardGradingQueuePanel` | Preview ≤5 + footer `+N` |
| `TeacherDashboardLiveStripPanel` | Carousel ngang trong khung viền |

**Quy tắc:** KPI dashboard **4 ô**; draft/published không nằm KPI; work zone **luôn** chiều cao cố định trước assignment hub.
