# 19 — Admin web: đánh giá thiết kế & tiêu chuẩn bổ sung

> **Phạm vi:** toàn bộ màn hình web role **admin** (`lib/feature/admin/**`).
> **Mục đích:** lặp lại quy trình của [`18`](18-teacher-web-audit-and-standards.md) cho admin — (1) chấm điểm UX 4 trục; (2) khoảng trống **tuân thủ** & **trải nghiệm** (kèm `file:dòng`); (3) **tiêu chuẩn mới**; (4) remediation plan có **audit gate**.
> **Nguồn:** đọc trực tiếp code 06/2026. Tái dùng foundation đã dựng cho teacher (tokens, skeleton, focus-visible, save-state).
> Bổ sung cho [`06`](06-web-foundations.md), [`07`](07-web-components.md), [`08`](08-web-screens.md) §B, [`10`](10-accessibility.md).

---

## 1. Điểm số tổng quan (hiện trạng)

| Trục đánh giá | Điểm | Tóm tắt |
|---------------|:----:|---------|
| **Thân thiện người dùng** | 6.5 / 10 | Ban-user & FORCE-publish có luồng xác nhận mẫu mực; lọc/sort release phong phú. Trừ: **search/filter CMS là stub** (render mà không gọi API), không phân trang, empty-state lệch nhau giữa 3 list. |
| **Trải nghiệm mượt** | 6.0 / 10 | Real-time socket ở user-management. Trừ: **spinner thay skeleton** khắp nơi, **không autosave** editor, validate submit-time/toast, nhiều list `limit 9999`/`20` không ảo hoá. |
| **Kết hợp màu sắc** | 5.5 / 10 | `AdminSkillPalette` gom màu kỹ năng tốt. Trừ: **304 hex literal** — bảng màu status/priority rải rác (ops 56, release 43) + **fork mini-design-system** `content_widgets` (`kBgPage/kTextMain` lệch AppColors, còn mâu thuẫn giữa file). |
| **Chuẩn component** | 6.5 / 10 | `AdminWebUi`/`AdminWidgets`/`AdminDialogShell` song song teacher, tái dùng tốt. Trừ: `content_widgets` (ShadcnCard/ShadcnInput) là hệ thứ 2 tách rời; thiếu focus-ring/Semantics; radius/spacing magic. |
| **Tổng** | **6.1 / 10** | Khung nhất quán với teacher, nhưng **nợ kỹ thuật màu sắc lớn hơn nhiều** (304 vs 13 hex) và có **2 hệ component song song**. Ưu tiên: tokenize status palette + xoá fork + tái dùng chuẩn teacher. |

> **Kết luận một dòng:** Admin thừa hưởng đúng khung teacher nhưng phần CMS/vận hành phát triển lệch chuẩn — phần lớn việc là **tokenize bảng màu status, gỡ fork `content_widgets`, và áp lại các chuẩn đã có ở [`18`](18-teacher-web-audit-and-standards.md) §5** (skeleton, inline-validate, focus-visible, destructive-confirm).

---

## 2. Điểm mạnh cần giữ

1. **Shell khớp teacher 100%.** `admin_shell.dart` — sidebar 212/48, top bar 44, item 30, breakpoint 768/1024. `AdminWebUi` nhân bản đúng dimension/typography/button của `TeacherWebUi`.
2. **`AdminSkillPalette`** (`admin_skill_palette.dart`) gom màu icon kỹ năng CMS một chỗ — **token gốc hợp lệ**, whitelist khỏi audit.
3. **Luồng phá huỷ mẫu mực (một phần):** ban-user 3 bước (type → duration → reason) + nút danger; **FORCE-publish 2 bước gõ chữ `FORCE`** (`release_management_page.dart:177–250`) — đúng chuẩn "không thu hồi".
4. **Real-time:** user-management cập nhật trạng thái qua socket (`user_management_page.dart:91–104`).
5. **Ops Center** là màn duy nhất làm đúng bảng dữ liệu: `DataTable` + `_PaginationBar` (rows 5/8/10/15/20/50) + sticky heading (`admin_ops_center_page.dart:714–775`). Dùng làm mẫu cho các list khác.

---

## 3. Khoảng trống TUÂN THỦ (code vi phạm chuẩn đã có)

### 3.1 Hex literal off-palette — vi phạm [`10`](10-accessibility.md) §14 & [`02`]

> Baseline **304 hex** (so teacher 13). Chia 3 nhóm:

**(a) Bảng màu status/priority — nên token-hoá thành palette (≈100 hex):**
| Vị trí | Dùng cho |
|--------|----------|
| `admin_ops_center_page.dart:463–495, 605–609` (≈56 hex) | chip priority/SLA: `0xFFFEE2E2/0xFFFEF3C7/0xFFDCFCE7/0xFFE0E7FF…` + fg |
| `release_management_page.dart:40–76` (≈43 hex) | pipeline status bg/fg: pending/approved/published/scheduled/rejected/archived |
| `admin_user_details_dialog.dart`, `report_card.dart`, `user_role_badge.dart` | badge trạng thái |

**(b) Fork mini-design-system `content_widgets.dart` — nợ kiến trúc:**
- `content_widgets.dart:4,8` định nghĩa `kBgPage = 0xFFF8FAFC`, `kTextMuted = 0xFF64748B`, shadow `0xFF0F172A`… **song song và lệch** `AppColors`.
- `admin_writing_list_view.dart:226–230` **định nghĩa lại** `kBgPage = 0xFFF9FAFB`, `kTextMain = 0xFF09090B` — **mâu thuẫn** với `content_widgets` (`0xFFF8FAFC`/`0xFF0F172A`). Hai "đen", hai "nền xám" khác nhau.
- `ShadcnCard`/`ShadcnInput` (`content_widgets.dart:21–108`) là hệ component thứ 2, không qua `AdminWebUi`.

**(c) Off-palette rải rác trong CMS/editor:**
- `admin_reading_list_view.dart:184,204,337,341` `0xFFF1F5F9`; `:364–379` `Colors.blue/purple/orange.shade50` (Material shade — cấm).
- `reading_editor_page.dart:393–417` info/warn container `0xFFEFF6FF/0xFFFFF7ED/0xFF1E40AF…`; `:563,602` success `0xFF15803D/0xFFF0FDF4` — **nên dùng `AppColors.info/warning/success` + `*Bg`**.
- `admin_listening_comp_list_page.dart:247–251` purple `0xFFF3E8FF/0xFF9333EA`.

**(d) Shadow trong foundation:** `admin_web_ui.dart:41–42`, `admin_page_scaffold.dart:302` dùng `0x0A000000/0x04000000` thay vì `AppColors.shadowCard/shadowAmbient` (teacher đã token-hoá).

### 3.2 Radius / spacing / Duration literal

- **Radius 202 literal** (histogram 8×72, 12×39, 6×20, 4×20, 14×17, 10×13, 999×5, 7×5, 20×5, 2×3, 16×3) → map `AppRadius` y như teacher (8→input, 12→card, 6/7→chip, 4/2→xs, 14/16→sheet, 10→card, 20→lg, 999→pill). Gồm cả `admin_web_ui.dart:102,115` `circular(10)` trong lớp token.
- **Duration 11 literal:** `release_management_page.dart:463` `160ms`; `admin_user_details_dialog.dart:48,50` `300ms`; `admin_shell.dart:398` `400ms` tooltip. → `AppMotion.*`. ⚠️ **Không** đụng `activity_history_page.dart:374` `Duration(hours: 7)` (lệch múi giờ, không phải motion).
- **Spacing magic** `EdgeInsets.symmetric(24,20)`, `fromLTRB(20,18,20,8)`… → `AppSpacing`.

### 3.3 Spinner thay skeleton — vi phạm [`10`](10-accessibility.md) §12

- **29 spinner** `AppLoadingIndicator.center()` (dashboard, mọi list CMS, user/report/release). Skeleton usage = **0**. Doc §12: list/card lớn phải skeleton.

### 3.4 Validate submit-time/toast — vi phạm [`10`](10-accessibility.md) §8

- `release_management_page.dart:141–143` reject reason rỗng → **âm thầm** fallback "Rejected by admin" (không báo).
- `admin_teacher_applications_page.dart:79–80` reject reason rỗng → **return im lặng**, không toast.
- CMS editor (`reading_editor_page.dart:133–136`) validate lúc submit qua toast, không inline.

### 3.5 Hành động phá huỷ không nhất quán — vi phạm [`08`](08-web-screens.md) §C1

- ✅ Ban-user / FORCE-publish: đúng chuẩn (danger + confirm + gõ xác nhận).
- ❌ **Rollback release `release_management_page.dart:360–361` fire THẲNG, không dialog** — đây là hành động không thu hồi → **P0**.
- ❌ Reject release (`:115–151`) có dialog nhưng nút **không tô danger**.

### 3.6 Focus ring / Semantics thiếu — vi phạm [`10`](10-accessibility.md) §3, §5

- `AdminWebUi` **không** có helper focus-visible (teacher có `TeacherWebUi.focusableTile`). Sidebar tile, KPI card, dialog tile, nav tile đều không ring khi `Tab`.
- Status pill khắp nơi **không** `Semantics(label:)` (`admin_user_details_dialog.dart:495–501`, `release_management_page.dart:741`, `activity_history_page.dart:461–466`).
- Nhiều icon-only button thiếu `tooltip` (đặc biệt trong editor CMS).

---

## 4. Khoảng trống TRẢI NGHIỆM (chuẩn còn thiếu)

1. **Search/filter CMS là stub:** `admin_reading_list_view.dart:188–211`, `admin_writing_list_view.dart:278` render ô tìm kiếm + icon lọc nhưng **không gọi API** → người dùng gõ mà không có gì xảy ra. Phải **nối thật hoặc gỡ bỏ** (không bày control chết).
2. **Không phân trang/ảo hoá:** user/report/release/applications/activity dùng `ListView` `limit 20`/`9999` (`admin_reading_list_view.dart:63`). Chỉ Ops Center có phân trang. Lớp dữ liệu lớn sẽ giật.
3. **CMS editor:** không autosave (mất dữ liệu khi crash), không preview tách, không drag-reorder câu hỏi (`reading_editor_page.dart:457–459`).
4. **Empty state lệch nhau:** reading/listening-comp có icon+text+CTA; writing chỉ 1 dòng text → cần thống nhất `AdminEmptyCard` + CTA.
5. **Hai hệ component song song:** `AdminWidgets` (chuẩn) vs `content_widgets` Shadcn* (fork) → trùng lặp, khó bảo trì.

---

## 5. TIÊU CHUẨN MỚI ĐỀ XUẤT

> Phần lớn **tái dùng nguyên** chuẩn teacher ([`18`](18-teacher-web-audit-and-standards.md) §5). Dưới đây nêu phần **đặc thù admin**.

### 5.1 `AdminStatusPalette` (P0) — tokenize bảng màu trạng thái

Gom toàn bộ màu pipeline/priority rải rác (ops + release) vào **một** nguồn — thay ≈100 hex:
```dart
abstract final class AdminStatusPalette {
  // Pipeline release / report
  static const pendingBg   = AppColors.warningBg; static const pendingFg   = AppColors.warning;
  static const approvedBg  = AppColors.successBg; static const approvedFg  = AppColors.success;
  static const rejectedBg  = AppColors.dangerBg;  static const rejectedFg  = AppColors.danger;
  static const scheduledBg = AppColors.infoBg;    static const scheduledFg = AppColors.info;
  static const archivedBg  = AppColors.surfaceSubtle; static const archivedFg = AppColors.textSecondary;
  // Priority / SLA (ops center) — tái dùng semantic, không tạo sắc mới
  static const highBg = AppColors.dangerBg;   static const highFg = AppColors.danger;
  static const medBg  = AppColors.warningBg;  static const medFg  = AppColors.warning;
  static const lowBg  = AppColors.successBg;  static const lowFg  = AppColors.success;
}
```
→ Ưu tiên **ánh xạ về semantic `AppColors`** sẵn có; chỉ định nghĩa hex gốc khi không có token tương đương.

### 5.2 Gỡ fork `content_widgets` (P0) — một hệ component duy nhất

- Xoá `kBgPage/kTextMain/kTextMuted` cục bộ → dùng `AppColors.surface*/textPrimary/textSecondary`.
- `ShadcnCard` → `AdminWebUi.cardDecoration/panelDecoration`; `ShadcnInput` → `AdminWebUi.formInputDecoration` + `formFieldLabel`.
- Xoá định nghĩa trùng ở `admin_writing_list_view.dart:226–230`.

### 5.3 Tái dùng chuẩn teacher (P1)

- **Skeleton:** tạo `AdminSkeleton` ghép `AppSkeleton.box` (hoặc dùng chung `TeacherSkeleton` đổi tên thành `WorkspaceSkeleton`) — thay 29 spinner.
- **Focus-visible:** thêm `AdminWebUi.focusableTile()` y hệt `TeacherWebUi` (`FocusableActionDetector` + ring 2px `focusRing`).
- **Inline-validate:** `AdminWebUi.formFieldError()`; reject/ban reason báo lỗi inline thay vì im lặng/toast.
- **Save-state machine:** editor CMS dùng idle/saving/saved/error + autosave debounce ([`18`](18-teacher-web-audit-and-standards.md) §5.7).

### 5.4 Destructive standard cho admin (P0)

| Mức | Ví dụ | Yêu cầu |
|-----|-------|---------|
| Không thu hồi | **Rollback release**, FORCE-publish | dialog + **filled danger** + banner hệ quả + (khi rất nặng) gõ xác nhận |
| Phá huỷ thường | ban user, reject application/release | confirm + nút danger + lý do **bắt buộc có validate inline** |

→ Sửa ngay rollback (`:360`) và tô danger nút reject release (`:135–147`).

### 5.5 Data-table & list standard (P1)

- Lấy **Ops Center** làm chuẩn: phân trang (`_PaginationBar`) hoặc ảo hoá khi >100 hàng; sticky header; số căn phải tabular.
- Áp cho user/report/release/applications/activity; bỏ `limit 9999`.

### 5.6 Control phải hoạt động (P1)

- Search/filter: **nối API** hoặc **ẩn** — không render control không phản hồi (CMS list).

### 5.7 Semantics cho status pill (P2)

- Mọi pill/badge bọc `Semantics(label: 'Trạng thái: …')`; icon-only button có `tooltip`.

---

## 6. Remediation plan (thực thi theo phase, có audit gate)

> **Nguyên tắc:** foundation → sweep cơ học → UX theo màn → polish. Mỗi phase đóng bằng cổng audit (tự động + `dart analyze` + thủ công).
> **Baseline 06/2026** (`tool/ui_audit.sh` scope admin): hex **304** · radius **202** · Duration **11** · spinner **29** · skeleton **0**.
> **Whitelist:** `admin_skill_palette.dart` (màu gốc CMS) + token shadow.

### 6.0 Ưu tiên gốc

| Ưu tiên | Hạng mục |
|:-------:|----------|
| **P0** | §5.1 AdminStatusPalette · §5.2 gỡ fork content_widgets · §5.4 destructive (rollback confirm) · token enforcement |
| **P1** | §5.3 skeleton/focus/inline-validate/save-state · §5.5 data-table · §5.6 nối/ẩn search |
| **P2** | §5.7 Semantics · Duration→AppMotion · empty-state CTA đồng nhất |

### 6.1 Phase 0 — Mở rộng audit
- Thêm scope admin cho `tool/ui_audit.sh` (tham số thư mục); whitelist `admin_skill_palette.dart` + dòng có `// audit-ignore`.
- **Cổng:** in đúng baseline 304/202/11/29.

### 6.2 Phase 1 — Foundation
- Tạo `AdminStatusPalette` (§5.1); `AdminSkeleton` (§5.3); thêm `AdminWebUi.focusableTile()` + `formFieldError()`.
- Token-hoá shadow trong `admin_web_ui.dart`/`admin_page_scaffold.dart`; sửa radius literal nội bộ `AdminWebUi`.
- **Cổng:** `dart analyze` sạch; token/helper mới tồn tại.

### 6.3 Phase 2 — Sweep cơ học (subagent song song, mỗi agent cụm file riêng)
- Hex → token: status/priority → `AdminStatusPalette`; off-palette CMS → `AppColors.info/warning/success` + `*Bg`; **gỡ fork** `content_widgets` (§5.2). **Mục tiêu hex 304→0** (trừ whitelist).
- Radius literal → `AppRadius` (bảng mapping như teacher). **202→0.**
- Duration → `AppMotion` (trừ `hours:7`). **→0.**
- **Cổng:** `ui_audit` admin hex/radius/duration = 0 (trừ whitelist); analyze sạch; smoke-test 5 màn.

### 6.4 Phase 3 — UX theo màn

| Batch | Màn | Việc |
|------|-----|------|
| 3a | dashboard, mọi list CMS, user/report/release | spinner→`AdminSkeleton`; empty + CTA đồng nhất |
| 3b | user/report/release/applications/activity | phân trang/ảo hoá theo mẫu Ops Center (§5.5) |
| 3c | reading/writing editor | save-state + autosave + inline-validate; nối/ẩn search (§5.6) |
| 3d | release (rollback/reject), ban, reject-application | destructive chuẩn §5.4 (rollback confirm + danger + validate inline) |

- **Cổng (mỗi batch):** spinner màn đó = 0; lỗi validate inline; destructive có confirm+danger; bảng ký nhận màn × tiêu chí.

### 6.5 Phase 4 — Polish a11y & motion
- `focusableTile` cho sidebar/KPI/nav/dialog tile; `Semantics` status pill; tooltip icon-only.
- **Cổng:** Duration-literal 0; tab keyboard thấy ring; checklist §7 full ✓.

### 6.6 Cơ chế audit check (mọi cổng)
1. **Tự động:** `tool/ui_audit.sh` scope admin — bảng trước/sau (về 0 trừ whitelist).
2. **Tĩnh:** `dart analyze lib` 0 lỗi mới.
3. **Thủ công:** bảng ký nhận màn × tiêu chí (skeleton/empty-CTA/inline-validate/focus/destructive/pagination/Semantics).
4. **Hồi quy:** smoke-test 1280×800 + fallback 768.

---

## 7. Checklist tuân thủ (mở rộng [`18`](18-teacher-web-audit-and-standards.md) §7 cho admin)

- [ ] Không `Color(0x…)` trong `lib/feature/admin/**` (trừ `admin_skill_palette.dart` + `AdminStatusPalette` gốc).
- [ ] Không còn `content_widgets` fork (`kBgPage/kTextMain/ShadcnCard/ShadcnInput`).
- [ ] Không `BorderRadius.circular(<số>)` / `Duration(milliseconds:<số>)` rời.
- [ ] Loading = skeleton; lỗi field = inline `danger`.
- [ ] **Rollback/FORCE** = filled danger + confirm; reject = danger + lý do validate inline.
- [ ] List dữ liệu lớn có phân trang/ảo hoá; search/filter hoạt động thật hoặc ẩn.
- [ ] Phần tử tap được có focus ring; status pill có `Semantics`.

---

## 8. Bản đồ file ↔ vấn đề (tra nhanh)

| File | Vấn đề chính | Mục |
|------|--------------|-----|
| `admin_ops_center_page.dart` | 56 hex status/priority; (đã có pagination — làm mẫu) | 3.1a, 5.1, 5.5 |
| `release_management_page.dart` | 43 hex pipeline; rollback không confirm; reject không danger; Duration 160 | 3.1a, 3.5, 5.1, 5.4 |
| `content_widgets.dart` + `admin_writing_list_view.dart` | fork `kBgPage/kTextMain` lệch & mâu thuẫn | 3.1b, 5.2 |
| `reading_editor_page.dart` | hex info/feedback; không autosave/preview/reorder; validate toast | 3.1c, 3.4, 5.3 |
| `admin_reading_list_view.dart` | `Colors.*.shade50`; search stub; limit 9999 | 3.1c, 4.1, 4.2 |
| `admin_web_ui.dart` / `admin_page_scaffold.dart` | shadow hex; radius literal; thiếu focusableTile | 3.1d, 3.2, 3.6, 5.3 |
| `user_ban_dialog.dart` | mẫu tốt (giữ); radius literal; thiếu tooltip | 2, 3.2, 3.6 |
| `admin_user_details_dialog.dart` / `report_card.dart` | badge hex; pill thiếu Semantics; Duration 300 | 3.1a, 3.2, 3.6 |
| `admin_teacher_applications_page.dart` | reject validate im lặng; không filter | 3.4, 4.2 |

> **Khi sửa xong từng mục:** cập nhật `06`/`07`/`08` §B nếu đổi pattern; ghi commit vào [`11-implementation-mapping.md`](11-implementation-mapping.md) "Migration log".
</content>
