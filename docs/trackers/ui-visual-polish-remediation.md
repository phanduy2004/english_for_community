# Tracker — UI Visual Polish (Teacher web + Student mobile)

> **Mục tiêu:** làm UI **đẹp & "polished" hơn** ở 3 trục người dùng phản ánh: **bố cục/căn chỉnh**, **màu/phong cách**, **phân cấp/nhấn mạnh**.
> **Phạm vi:** `lib/feature/teacher/**` (web) + các module student mobile (`feature/{home,student,listening,listening_comp,reading,speaking,writing,vocabulary,profile,progress}`).
> **KHÔNG đụng:** admin web; logic nghiệp vụ; API.
> **Khác với** [`teacher-web-ui-remediation`](teacher-web-ui-remediation.md) & [`admin-web-ui-remediation`](admin-web-ui-remediation.md): hai tracker đó lo **conformance** (token, skeleton, validate). File này lo **thẩm mỹ thị giác** (composition, hierarchy, restraint màu) — phần "nhìn vẫn chưa đẹp" dù token đã sạch.
> **Nguồn token (đọc trước khi sửa):** `lib/core/theme/{app_color,app_spacing,app_typography}.dart`, `lib/feature/teacher/layout/teacher_web_ui.dart`, `StudentMobileUi`. Chuẩn: [`../ui-ux-system/02-design-tokens.md`](../ui-ux-system/02-design-tokens.md), [`../ui-ux-system/01-design-philosophy.md`](../ui-ux-system/01-design-philosophy.md).
> **Cập nhật:** 2026-06-21.

---

## 0. Cách dùng file này với Cursor

1. **Làm theo thứ tự P0 → P1 → P2.** Mỗi task có: vị trí (`file ≈ dòng` + tên widget/hàm), **vấn đề**, **cách sửa** (token/API chính xác), **nghiệm thu**.
2. **Số dòng là gần đúng** (đọc code 06/2026) — Cursor xác nhận lại bằng tên hàm/widget, đừng sửa mù theo số dòng.
3. **Mọi giá trị phải qua token** — `AppColors` / `AppSpacing` / `AppRadius` / `AppTypography`. Cấm hex/số rời mới.
4. **Sau mỗi nhóm:** chạy `bash tool/ui_audit.sh` (teacher) / `bash tool/ui_audit.sh student`, `flutter analyze lib`, smoke-test 1280×800 (teacher) + 360×800 (mobile). Số vi phạm **không được tăng**.
5. Prompt mẫu cho Cursor ở [§5](#5-prompt-mẫu-cho-cursor).

### Bảng tham chiếu nhanh (API có sẵn — dùng, đừng tự chế)

| Cần | Dùng |
|-----|------|
| Page title web / h1 mobile | `context.h1Style` (16/600) |
| Section/card title lớn | `context.h2Style` (14/600) |
| Card title / list item | `context.h3Style` (13/600) |
| Body | `context.bodyStyle` (13/400) |
| Meta/timestamp | `context.captionStyle` (11/400, `textSecondary`) |
| Số KPI/streak/điểm | `AppTypography.kpiValue()` (15/600 tabular) |
| Card phẳng (list/dashboard) | `TeacherWebUi.panelDecoration()` — **border, KHÔNG shadow** |
| Card nổi (dialog/popover) | `TeacherWebUi.cardDecoration()` — border + shadow |
| Màu kỹ năng (chỉ student) | `AppSkillColors.of(SkillType).{color,tint,dark}` |
| Thang màu điểm | `AppScoreScale.ramp` |
| Hover/press nền | `AppColors.hoverOverlay` / `pressOverlay` |

---

## 1. Chẩn đoán gốc — vì sao "nhìn chưa đẹp"

Hệ design-system đã **rất tốt** (token sạch, triết lý Editorial Black rõ). "Xấu" không đến từ thiếu chuẩn mà từ **3 thói quen khi ráp màn**:

| Trục | Triệu chứng lặp lại | Hệ quả thị giác |
|------|---------------------|-----------------|
| **Bố cục & căn chỉnh** | padding hardcode lệch nhau (vd `24` cạnh `12`), card/stat **cao thấp lởm chởm**, icon/chevron **không căn giữa theo chiều cao** card, hàng nút thừa ô trống. | Mép phải răng cưa, các khối "trôi", cảm giác cẩu thả. |
| **Màu & phong cách** | card phẳng dùng **viền + shadow cùng lúc**, tint quá nhạt (contrast <1.5:1), **màu kỹ năng gán cho chỉ số chung** (điểm/level), 5 màu kỹ năng đứng cạnh nhau. | Vừa "nặng" vừa "loè", thiếu tinh tế kiểu Linear/Stripe. |
| **Phân cấp & nhấn mạnh** | tiêu đề / nội dung / nút **cùng cỡ, cùng weight**, không có điểm dừng thị giác, không rõ "nhìn đâu trước". | Mọi thứ phẳng như nhau → mắt không biết bám vào đâu. |

**North-star:** một màn chỉ có **1 tâm điểm** (KPI nổi / CTA chính), phân cấp rõ qua **size + weight + màu** (không phải tô màu lung tung), khối căn theo **lưới spacing 4px**, card phẳng **viền-only**, màu kỹ năng **chỉ cho kỹ năng**, amber **chỉ để ăn mừng**.

---

## 2. Foundation (làm TRƯỚC — ảnh hưởng cả 2 surface) · P0

| ID | Việc | Chi tiết | Nghiệm thu |
|----|------|----------|-----------|
| **F-1** | **Card phẳng = viền-only** | `TeacherWebUi.cardDecoration()` đang dùng **viền 1px + shadow 2 lớp** (`teacher_web_ui.dart:64-74`) → vi phạm triết lý P2 ("không dùng đồng thời shadow + viền"). Chuyển **mọi card list/dashboard** sang `panelDecoration()` (đã có sẵn, border-only). Giữ `cardDecoration()` shadow **chỉ** cho dialog/popover/floating. | Dashboard/list không còn shadow; chỉ dialog mới có shadow. |
| **F-2** | **Thang phân cấp chữ thống nhất** | Rà mọi nơi tự set `fontSize`/`fontWeight` rời → thay bằng `context.h1Style/h2Style/h3Style/bodyStyle/captionStyle` + `AppTypography.kpiValue()`. Quy ước: **page title** = h1; **section/card title** = h2/h3; **body** = bodyStyle; **meta** = captionStyle (`textSecondary`); **số KPI** = `kpiValue()`. | Không còn `TextStyle(fontSize: …)` rời trong widget; phân cấp nhất quán. |
| **F-3** | **Kỷ luật màu** | (a) **Màu kỹ năng** (`AppSkillColors`) chỉ cho icon box / progress / left-border của **kỹ năng** — KHÔNG cho chỉ số chung (điểm/level/streak). (b) **Amber `accent`** chỉ cho ăn mừng/KPI nổi, không cho nút thường. (c) Tint nền semantic dùng `*Bg` (`successBg/warningBg/dangerBg`) đủ contrast, không dùng `surfaceSubtle` cho khối cần nổi. | Không skill-color trên stat chung; không amber trên nút thao tác. |

> Làm F-1..F-3 xong mới sang surface — vì nhiều task dưới đây **phụ thuộc** chúng.

---

## 3. Teacher web — `lib/feature/teacher/**`

> Điểm UX hiện tại (doc `18`): **7.4/10**. Nền vững, thiếu "polish". Dưới đây là các sửa **thẩm mỹ** (không trùng conformance ở tracker teacher-web).

### 3A. Bố cục & căn chỉnh

| ID | Vị trí (≈) | Vấn đề | Cách sửa | P |
|----|-----------|--------|----------|---|
| **TW-L1** | `teacher_dashboard_layout.dart` inbox card row `≈1003,1055` | Chevron `chevron_right` chỉ `top:8`, **không căn giữa** theo chiều cao card → "trôi" khi subtitle 2 dòng. | Outer `Row` đặt `crossAxisAlignment: CrossAxisAlignment.center`. | P0 |
| **TW-L2** | `teacher_dashboard_overview.dart` KPI grid `≈198-244` | Tile 2×2 tính width thủ công `(maxWidth-gap)/2`, **không ép cùng cao** → mép dưới lởm chởm. | Bọc hàng tile trong `IntrinsicHeight`, hoặc cho tile `SizedBox(height: cố định)`. | P0 |
| **TW-L3** | `teacher_dashboard_layout.dart` `MetricCell` `≈64-103` | padding compact/wide **bất đối xứng** (`s4` vs `s5`) → số KPI nhảy vị trí dọc khi đổi viewport. | Dùng padding **đối xứng** `AppSpacing.s4`; cân lại bằng `gap` cột nếu cần. | P1 |
| **TW-L4** | `teacher_page_scaffold.dart` header actions `≈129-200` | Ở ~640px actions xuống dòng với gap `s4`, title dài làm actions "rời rạc". | Khi wrap, gap = `AppSpacing.s5`; hoặc nâng breakpoint lên ~800. | P2 |
| **TW-L5** | `teacher_shell.dart` sidebar `≈240-301` | padding collapsed `fromLTRB(8,16,8,8)` **bất đối xứng** → logo bị "ép". | Collapsed: `EdgeInsets.symmetric(horizontal: 8, vertical: 16)`. | P2 |

### 3B. Màu & phong cách

| ID | Vị trí (≈) | Vấn đề | Cách sửa | P |
|----|-----------|--------|----------|---|
| **TW-C1** | (toàn dashboard) | Card phẳng dùng `cardDecoration()` (viền+shadow) → nặng. | **Áp F-1**: đổi sang `panelDecoration()`. | P0 |
| **TW-C2** | `teacher_dashboard_layout.dart` AttentionStrip `≈226-230` | Nền `surfaceSubtle` + viền `outlineMuted` → contrast <1.5:1, khó đọc. | Nền `AppColors.warningBg` (hoặc `successBg`) + viền `outline`. | P0 |
| **TW-C3** | `teacher_widgets.dart` `TeacherStatusPill` `≈190-250` | Thiếu tone **secondary** → badge "đang chấm" cũng amber như việc gấp → mọi thứ "cùng độ khẩn". | Thêm `TeacherStatusTone.secondary` → `textSecondary`; `warning` chỉ cho việc nhạy giờ. | P1 |
| **TW-C4** | `teacher_dashboard_layout.dart` QuickActionChip `≈348-372` | Nút phụ chỉ viền nhạt → "chìm" vào nền. | Thêm nền `AppColors.surfaceSubtle` cho outlined secondary (kiểu Stripe/Linear). | P1 |
| **TW-C5** | `teacher_widgets.dart` `TeacherKpiCard` `≈25-64` | Hover gần như vô hình trên nền trắng. | Thêm `hoverColor: AppColors.hoverOverlay` cho `Material/InkWell`. | P2 |

### 3C. Phân cấp & nhấn mạnh

| ID | Vị trí (≈) | Vấn đề | Cách sửa | P |
|----|-----------|--------|----------|---|
| **TW-H1** | `teacher_dashboard_layout.dart` `MetricCell` `≈96-142` | Số KPI và label **cùng màu/độ nặng** → số không nổi. | Số = `AppTypography.kpiValue()` (15/600 tabular, `textPrimary`); label = `captionStyle` (`textSecondary`); gap số↔label = `AppSpacing.s1` (2). | P0 |
| **TW-H2** | `teacher_dashboard_layout.dart` `PanelHeader` `≈499-505` | Header `surfaceSubtle` vs body trắng chỉ lệch ~2% → không thấy ranh giới. | Header nền `surfaceCard` + **divider dưới** `AppColors.outline` (không `outlineMuted`). | P1 |
| **TW-H3** | `teacher_dashboard_layout.dart` `SectionHeader` `≈548-605` | Title section thiếu weight → không phải "điểm dừng". | Title `context.h3Style` (đảm bảo **w600**); giữ thanh accent 3px trái. | P1 |
| **TW-H4** | `teacher_dashboard_layout.dart` AttentionRow `≈264-274` | Icon box 24×24 "nặng" ngang label nhỏ. | Icon box 20×20, icon 14; label `context.bodyStyle` (13) thay caption. | P2 |
| **TW-H5** | `teacher_page_scaffold.dart` Breadcrumb `≈209-239` | Quá mờ (gap 2px, `textSecondary`) → giống meta hơn là điều hướng. | Gap 4px; crumb không-active `textPrimary`; crumb cuối **w600**. (Nếu hầu như không dùng → cân nhắc bỏ.) | P2 |

---

## 4. Student mobile — `feature/{home,…}`

> Điểm UX hiện tại (doc `20`): **7.1/10**, token sạch nhất. "Xấu" chủ yếu ở **home**: phẳng, màu thiếu tiết chế, padding lệch.
> **Lưu ý "Student Vibrancy":** doc **cho phép** màu kỹ năng để tăng hứng thú (Duolingo) — **không gỡ màu**, mà **tiết chế & xếp nhịp** cho gọn. Heading/body vẫn `textPrimary`.

### 4A. Bố cục & căn chỉnh

| ID | Vị trí (≈) | Vấn đề | Cách sửa | P |
|----|-----------|--------|----------|---|
| **SM-L1** | `home_page.dart` error state `≈393` vs content `≈440` | Error dùng `EdgeInsets.symmetric(horizontal:24)` còn content dùng `StudentMobileUi.pagePadding` (12) → mép lệch. | Dùng **cùng** `pagePadding`/`AppSpacing.s4` cho error. | P0 |
| **SM-L2** | `home_page.dart` quick actions `≈725-749` | 2 hàng nút để **lòi 2 ô Expanded trống** → lỗ hổng bố cục. | Thay 2-`Row` bằng `GridView.count(crossAxisCount: 2, childAspectRatio: …)` cho nhịp đều. | P0 |
| **SM-L3** | `home_page.dart` stats row `≈577-611` | 3 stat card **cao thấp lệch** (nội dung khác nhau). | `IntrinsicHeight` cho row, hoặc `minHeight` chung; Column stat `mainAxisAlignment: start`. | P1 |
| **SM-L4** | `student_mobile_ui.dart` `statCard` `≈689-692` | padding ngang chỉ `s3` (8) trong khi icon 30dp → chật. | padding ngang `AppSpacing.s4` (12); icon 28dp. | P1 |
| **SM-L5** | `home_page.dart` daily goal icon `≈548-574` | Icon phải **dính mép** card. | Thêm `SizedBox(width: AppSpacing.s2)` / padding phải. | P2 |
| **SM-L6** | `student_mobile_ui.dart` `skillAccentCard` `≈573` | Viền trái 3px **mảnh** so với chevron 18px. | Viền trái **4px** (hoặc chevron 16). | P2 |

### 4B. Màu & phong cách

| ID | Vị trí (≈) | Vấn đề | Cách sửa | P |
|----|-----------|--------|----------|---|
| **SM-C1** | `home_page.dart` stat icons `≈596-608` | **Points = màu reading (cam), Level = màu writing (tím)** → màu kỹ năng gán sai cho chỉ số chung. | **Áp F-3**: Streak/Points/Level dùng `AppColors.accent` + `accentTint` (hoặc neutral), **bỏ** `skill: SkillType.*`. | P0 |
| **SM-C2** | home lesson cards (5 skill colors cạnh nhau) | 5 màu kỹ năng đứng liền → "candy store". | Giữ màu nhưng **xếp nhịp**: 1 card "kỹ năng hôm nay" full màu, còn lại dùng icon-tint nhẹ; hoặc nhóm theo input/output. Không 2 skill-color cạnh nhau cùng row. | P1 |
| **SM-C3** | `home_study_dashboard.dart` progress `≈143-148` | Bar ngày = amber, bar tuần = đen → 2 màu fill 1 card. | Thống nhất: highlight cột nổi = `chartHighlight` (amber), cột thường = `chartBar` (đen) theo doc chart. | P2 |

### 4C. Phân cấp & nhấn mạnh

| ID | Vị trí (≈) | Vấn đề | Cách sửa | P |
|----|-----------|--------|----------|---|
| **SM-H1** | `home_page.dart` stats vs quick actions `≈462 / 683` | Stat row và hàng nút **cùng trọng lượng** → không rõ tâm điểm. | Stat card **nhỏ lại** (~84dp, label `textMuted`); ưu tiên trọng lượng cho **lesson card + daily goal** (tâm điểm học). | P0 |
| **SM-H2** | `home_page.dart` greeting `≈497-504` | Greeting (h1) + subtitle (body) cách nhau `s2` (4) → dính thành 1 khối. | Gap `AppSpacing.s3` (8); subtitle `textSecondary` để lùi nền. | P1 |

---

## 5. Prompt mẫu cho Cursor

```
Đọc docs/trackers/ui-visual-polish-remediation.md và docs/ui-ux-system/02-design-tokens.md.
Thực hiện task <ID> (vd TW-C1). Quy tắc:
- Chỉ sửa UI của task đó, không đổi logic/API.
- Mọi giá trị qua token: AppColors / AppSpacing / AppRadius / AppTypography (xem bảng §0). Cấm hex/số rời mới.
- Xác nhận vị trí bằng tên widget/hàm (số dòng chỉ gần đúng).
- Sau khi sửa: chạy `flutter analyze lib` và `bash tool/ui_audit.sh` (hoặc `... student`); số vi phạm không được tăng.
- Báo lại diff + ảnh hưởng màn nào.
```

**Thứ tự đề xuất:** `F-1 → F-2 → F-3` → P0 teacher (TW-L1, TW-L2, TW-C1, TW-C2, TW-H1) → P0 student (SM-L1, SM-L2, SM-C1, SM-H1) → P1 → P2.

---

## 6. Nghiệm thu (Definition of Done)

- [ ] **F-1**: card list/dashboard = `panelDecoration` (border-only); shadow chỉ ở dialog/popover.
- [ ] **F-2**: không còn `TextStyle(fontSize:…)` rời trong widget teacher/student; phân cấp qua `context.*Style` / `kpiValue()`.
- [ ] **F-3**: không màu kỹ năng trên chỉ số chung; không amber trên nút thao tác.
- [ ] Teacher P0 (TW-L1/L2/C1/C2/H1) xong; smoke 1280×800 + 768.
- [ ] Student P0 (SM-L1/L2/C1/H1) xong; smoke 360×800.
- [ ] `flutter analyze lib` 0 lỗi mới; `ui_audit` hex/radius/duration không tăng.
- [ ] Mỗi màn có **1 tâm điểm** rõ; mép phải không răng cưa; card cùng nhóm cùng chiều cao.

---

## 7. Nhật ký

| Ngày | Thay đổi |
|------|----------|
| 2026-06-21 | Khởi tạo: chẩn đoán 3 trục + 3 foundation (F-1..3) + 13 task teacher + 11 task student, kèm prompt Cursor & DoD. |
| 2026-06-21 | **Đợt 1 (P0):** F-1..F-3 + TW-L1/L2/C1/C2/H1 + SM-L1/L2/C1/H1 — panelDecoration sweep, MetricCell kpiValue, AttentionStrip warningBg, KPI grid equal height, home stats/quick actions polish. |
| 2026-06-21 | **Đợt 2 (P1+P2):** TW-L3..L5, TW-C3..C5, TW-H2..H5, SM-L3..L6, SM-C2/C3, SM-H2 — padding/hover/breadcrumb/sidebar, status secondary tone, lesson rhythm, chart bar unify, greeting hierarchy. |
