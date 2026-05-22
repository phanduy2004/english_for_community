# 00 — Compact density v3 (2026)

> **Mục tiêu:** Giao diện gọn như Linear / Vercel / Stripe — chữ không “to”, card không “phình”, nhiều thông tin hơn trên một màn hình.

## So với v2

| Khía cạnh | v2 (cũ) | **v3 (hiện tại)** |
|-----------|---------|-------------------|
| Web page title | 18–22px Bold | **16px Semi-bold** |
| Web KPI số | Dùng nhầm `web.h1` (18px) | **`web.kpi` 15px** tabular-nums |
| Web section title | 13px label | **12px** uppercase / 13px semibold |
| Web page padding | 24×20 | **20×14** |
| Web card padding | 16–24 | **12–16** |
| Web shortcut card | ~128px cao | **~96px** |
| KPI icon box | 40×40 | **32×32** |
| Mobile AppBar title | 15px | **14px** |
| Mobile nav bar | 68dp | **60dp** |
| Body (cả hai) | 13px | **13px** (giữ — đã đúng) |

## Quy tắc nhanh

1. **Nút hành động (teacher):**
   - **Web (≥768):** `TeacherPageScaffold.actions` góc phải header; body → `TeacherInlineActions` (intrinsic width).
   - **Mobile (&lt;768):** CTA chính → `bottomActions` + `TeacherMobileBottomActionBar` (full-width 48dp). Thứ cấp → `TeacherInlineActions` hoặc horizontal scroll trong footer chấm.
   - Code: `teacher_action_bar.dart`, `teacher_mobile_ui.dart`, `teacher_shell.dart` (`_TeacherMobileShell`).
2. **Không** dùng `webH1` / `headlineMedium` cho số KPI, shortcut title, hay label card nhỏ.
2. **Page title** (Xin chào…, tên màn): `TeacherWebUi.webPageTitle` — 16 / 600.
3. **Số liệu dashboard:** `TeacherWebUi.webKpiValue` — 15 / 600 + `tabularFigures`.
4. **Tiêu đề section** (“Shortcuts”, “Grading queue”): `TeacherWebUi.sectionTitle` — 12px label hoặc 13px semibold.
5. **List row title:** `TeacherWebUi.listTitle` — 13px semibold.
6. Khoảng cách section trên dashboard: **`AppSpacing.s6` (20)** — không `s8` (32) trừ block cuối trang.

## Tham chiếu code

| Token doc | Flutter |
|-----------|---------|
| `web.pageTitle` | `TeacherWebUi.webPageTitle` |
| `web.kpi` | `TeacherWebUi.webKpiValue` |
| `web.section` | `TeacherWebUi.sectionTitle` |
| Spacing compact web | `TeacherWebUi.pagePadding`, `AppSpacing` |
| Mobile scale | `AppTypography.mobileTextTheme` |
| Web workspace theme | `AppTheme.mergeWorkspaceWeb` + `WorkspaceLayoutScope` |

## Checklist khi sửa màn

- [ ] Page header ≤ 52px chiều cao nội dung (không padding 32px dọc).
- [ ] Card list `padding` ≤ 12px ngang / 10–12px dọc.
- [ ] Button web 32px cao (`TeacherWebUi.buttonHeightPrimary`).
- [ ] Không `fontSize: 14+` hardcode cho body (dùng `webBody` = 13).
- [ ] Cập nhật doc `02`, `06`, `08` nếu đổi pattern màn.
