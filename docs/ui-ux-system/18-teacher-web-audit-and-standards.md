# 18 — Teacher web: đánh giá thiết kế & tiêu chuẩn bổ sung

> **Phạm vi:** toàn bộ màn hình web role **teacher** (`lib/feature/teacher/**`).
> **Mục đích:** (1) chấm điểm UX hiện trạng theo 4 trục người dùng yêu cầu — thân thiện, mượt, màu sắc, chuẩn component; (2) liệt kê **khoảng trống tuân thủ** (code lệch chuẩn đã có) và **khoảng trống trải nghiệm** (chuẩn còn thiếu); (3) **đề xuất tiêu chuẩn mới**.
> **Nguồn:** đọc trực tiếp code 06/2026. Mọi nhận định kèm `file:dòng`.
> Bổ sung cho [`06`](06-web-foundations.md), [`07`](07-web-components.md), [`08`](08-web-screens.md), [`10`](10-accessibility.md).

---

## 1. Điểm số tổng quan (hiện trạng)

| Trục đánh giá | Điểm | Tóm tắt |
|---------------|:----:|---------|
| **Thân thiện người dùng** | 7.5 / 10 | Điều hướng rõ, breadcrumb + path URL tốt, gradebook giàu thông tin. Trừ điểm: empty state cụt (không CTA), nút disabled không nói lý do, không stepper cho wizard. |
| **Trải nghiệm mượt** | 7.0 / 10 | Có motion vào trang (`TeacherDashboardMotion`), hover-lift, live-pulse. Trừ điểm: **spinner toàn màn thay vì skeleton** (trái `10` §12), validate bằng toast lúc submit thay vì inline, không autosave indicator. |
| **Kết hợp màu sắc** | 8.0 / 10 | Hệ Editorial Black + amber rất kỷ luật, semantic nhất quán ở phần lớn nơi. Trừ điểm: **hex literal off-palette** trong chart/policy, **4 sắc “success” khác nhau** cùng tồn tại. |
| **Chuẩn component** | 7.0 / 10 | `TeacherWebUi` + `TeacherDialogShell` tập trung hoá tốt. Trừ điểm: **radius/spacing/alpha hard-code** xuyên suốt, kể cả bên trong chính lớp token. |
| **Tổng** | **7.4 / 10** | Nền tảng vững, hệ thống đã có — **vấn đề chính là tuân thủ (conformance), không phải thiếu triết lý.** |

> **Kết luận một dòng:** Bộ tiêu chuẩn đã đủ tốt; phần lớn lỗi là **code chưa theo doc**. Ưu tiên đóng khoảng cách tuân thủ + bổ sung ~6 tiêu chuẩn còn thiếu (skeleton, inline-validate, autosave state, destructive confirm, focus-visible toàn cục, token enforcement).

---

## 2. Điểm mạnh cần giữ

1. **Bảng màu kỷ luật.** `AppColors` (`core/theme/app_color.dart`) — chữ đen trước tiên, brand đen `#0A0A0A`, amber chỉ để “ăn mừng”. Triết lý rõ, không loè loẹt.
2. **Tập trung hoá component.** `TeacherWebUi` (`layout/teacher_web_ui.dart`) gom button/input/card/segmented; `TeacherDialogShell` ép mọi dialog cùng khung header–body–footer. Đây là tài sản lớn — phải tận dụng để sửa hàng loạt.
3. **Điều hướng web đúng chất.** Sidebar collapse theo breakpoint (768 / 1024), path URL go_router (bookmark + F5), breadcrumb. Xem `teacher_shell.dart`.
4. **Compact density nhất quán về typography.** Page title 16/600, KPI 15/600 tabular, body 13 — đúng `00-compact-density-v3`.
5. **Gradebook giàu thông tin** với sort/filter/search, tooltip tiêu đề đầy đủ, hàng “Trung bình lớp” (`teacher_gradebook_view.dart`).

---

## 3. Khoảng trống TUÂN THỦ (code vi phạm chuẩn đã có)

> Đây là lỗi “đã có luật nhưng chưa làm theo”. Sửa = đưa code về đúng doc, **không** cần chuẩn mới.

### 3.1 Hex literal off-palette — vi phạm [`10`](10-accessibility.md) §14 & [`02`] “không hardcode hex trong widget”

| Vị trí | Màu hard-code | Phải thay bằng |
|--------|---------------|----------------|
| `teacher_analytics_page.dart:366,368` | `0xFFEA580C`, `0xFF65A30D` (bucket điểm) | token thang điểm (xem §5.3) |
| `teacher_assign_exam_dialog.dart:76` | `0xFF7C3AED`, `0xFFF5F3FF` (practice tím) | thêm token `info`/`practice` |
| `teacher_assign_exam_dialog.dart:81–83` | `0xFF15803D / 0xFF86EFAC / 0xFFFCD34D / 0xFFFCA5A5 …` | `AppColors.success/warning/danger` + `*Bg` |
| `teacher_exam_question_strip.dart:273` | `0xFF43A047` (đúng) | `AppColors.success` |
| `teacher_widgets.dart:634` | `0xFF43A047` (legend đúng) | `AppColors.success` |

**Hệ quả màu sắc:** đang tồn tại **≥4 sắc “xanh đúng/đạt”** khác nhau: `#16A34A` (`AppColors.success`), `#15803D`, `#43A047`, `#65A30D`. Người dùng thấy “xanh” không nhất quán giữa chart, legend, policy. → Phải hợp nhất về một nguồn.

### 3.2 Radius / spacing / alpha hard-code — vi phạm chuẩn token

- **Radius literal thay cho `AppRadius`** xuất hiện ngay trong lớp token: `teacher_web_ui.dart:175,188,202` dùng `BorderRadius.circular(10)` thay vì `AppRadius.card`; `choiceTileDecoration` (`:202`) tương tự; dialog shell dùng `16` trong khi `AppRadius.sheet = 14` (lệch token). Rải rác `circular(14/20/22)` trong `teacher_widgets.dart`, `teacher_dashboard_layout.dart`.
- **Spacing magic** (`EdgeInsets.fromLTRB(14,12,8,8)`, `symmetric(horizontal:10,vertical:4)`…) thay cho `AppSpacing.sX` ở gradebook/analytics/shell.
- **Alpha overlay rời rạc** `.withValues(alpha: 0.06/0.08/0.12/0.22/0.55/0.65)` không có tên ngữ nghĩa → mỗi nơi một độ mờ.

### 3.3 Spinner thay vì skeleton — vi phạm [`10`](10-accessibility.md) §12 & [`06`](06-web-foundations.md) §12

- Dashboard/analytics/gradebook load bằng `AppLoadingIndicator.center()` (spinner toàn vùng) thay vì skeleton cùng kích thước content. Doc §12 ghi rõ “Skeleton mọi list/card lớn; spinner toàn màn chỉ khi route mới chưa có khung”.

### 3.4 Validate lúc submit bằng toast — vi phạm [`10`](10-accessibility.md) §8 & [`07`](07-web-components.md) §7.1

- `teacher_exam_editor_page.dart:78–96`, `teacher_assign_exam_dialog.dart:214–233`: lỗi hiển thị bằng `AppCornerToast`/`error:true` **khi bấm lưu**, không có error text 12/400 `danger` ngay dưới field. Doc yêu cầu “validate on blur → on change”, “mỗi field có label + helper/error”.

### 3.5 Không có autosave indicator — vi phạm [`06`](06-web-foundations.md) §10

- Editor đề (`teacher_exam_editor_page.dart`, `teacher_integrated_exam_editor_page.dart`) chỉ có nút **Lưu nháp** thủ công; đóng tab = mất dữ liệu nhập dở. Doc §10 mô tả chỉ báo `Saved 12:48 PM` / `Sync failed · Retry` nhưng chưa hiện thực.

### 3.6 Hành động ảnh hưởng học sinh thiếu cảnh báo hệ quả — [`08`](08-web-screens.md) §C1

- `teacher_release_results_dialog.dart`: “Phát hành kết quả” ảnh hưởng toàn bộ học sinh nhưng **có thể đổi lại sau** (theo chính subtitle). Vì vậy **không** ép nút đỏ / type-to-confirm (sẽ sai mức độ) — thay vào đó thêm **banner cảnh báo hệ quả** nổi bật trong body. ✅ Đã sửa: `_ConsequenceBanner` (warningBg).
- Mục thật sự **không thu hồi** cần xử lý mạnh (§5.8) là **“Kết thúc & nộp tất cả”** trong session console (force-submit học sinh).

### 3.7 Focus ring chỉ có ở input — vi phạm [`10`](10-accessibility.md) §3

- Input có `focusedBorder primary 1.5` (`teacher_web_ui.dart:187`) ✅. Nhưng **sidebar nav tile, icon button, KPI card click, dialog tile** chỉ có `InkWell` mặc định, không ring 2px primary thấy được bằng `Tab`. Người dùng bàn phím lạc focus.

---

## 4. Khoảng trống TRẢI NGHIỆM (chuẩn còn thiếu)

> Lỗi “chưa có luật”. Cần định nghĩa chuẩn mới (xem §5) rồi mới implement.

1. **Bảng dữ liệu lớn chưa có:** cột đầu (tên HS) **sticky** khi cuộn ngang, **zebra** tuỳ chọn, **virtualization/pagination** khi >100 hàng. Gradebook hiện cuộn toàn bộ; lớp đông sẽ giật. (`teacher_gradebook_view.dart`)
2. **Empty state cụt:** `TeacherEmptyCard` chỉ icon + 1 dòng, không nút hành động kế tiếp (trái `06` §11 “Empty state có CTA Filled”).
3. **Wizard giao bài là một modal khổng lồ** (`teacher_assign_exam_dialog.dart`) — không stepper/progress; form dài dễ nản, không lưu nháp.
4. **Nút disabled không giải thích lý do** (vd “Lưu nháp” mờ khi đã publish; “Phát hành” mờ khi chưa finalize) — thiếu `tooltip`/helper.
5. **Hover/press affordance không đồng đều** trên các tile/cell click được (một số chỗ im lặng khi tap — trái `10` §7).
6. **Motion off-scale:** `Duration(milliseconds: 150)` (segment), `900` (live-pulse) không nằm trong `AppMotion` → khó đồng bộ và tôn trọng reduce-motion.

---

## 5. TIÊU CHUẨN MỚI ĐỀ XUẤT

> Mỗi mục dưới đây cần **thêm vào doc tương ứng** + tạo helper trong code để ép tuân thủ.

### 5.1 Token enforcement (P0) — chặn lệch ngay từ gốc

- **Cấm hex literal & radius/spacing magic trong `lib/feature/**`.** Mọi màu qua `AppColors`, radius qua `AppRadius`, spacing qua `AppSpacing`.
- Thêm **CI guard** (regex lint script) chặn `Color(0x`, `BorderRadius.circular(<number>)`, `EdgeInsets.*(<số lẻ>)` trong widget — cho phép whitelist ở `core/theme/*`.
- Ngoại lệ duy nhất: định nghĩa token gốc trong `core/theme/`.

### 5.2 Semantic overlay tokens (P0) — đặt tên cho mọi alpha

Thêm vào `AppColors`:
```dart
static Color get hoverOverlay  => primary.withValues(alpha: 0.04); // row/tile hover web
static Color get pressOverlay  => primary.withValues(alpha: 0.08); // press feedback
static Color get focusRing     => primary;                          // ring 2px
static const Color scrim       = Color(0x66000000);                 // backdrop dialog
static const Color shadowCard  = Color(0x0A000000);                 // = cardShadow
```
→ Thay toàn bộ `.withValues(alpha: 0.0x)` rải rác bằng các token này.

### 5.3 Score color scale (P0) — một nguồn cho “điểm/đạt”

Định nghĩa một thang 5 bậc dùng chung cho chart phân phối điểm, ô gradebook, status skill — **thay** các hex `0xFFEA580C`/`0xFF65A30D`/`0xFF43A047`…:
```dart
abstract final class AppScoreScale {
  static const fail   = AppColors.danger;   // < 4
  static const weak   = Color(0xFFEA580C);  // 4–5.5  (định nghĩa MỘT lần ở đây)
  static const mid    = AppColors.warning;  // 5.5–7
  static const good   = Color(0xFF65A30D);  // 7–8.5  (định nghĩa MỘT lần ở đây)
  static const strong = AppColors.success;  // ≥ 8.5
  static const List<Color> ramp = [fail, weak, mid, good, strong];
}
```
→ Hợp nhất 4 sắc xanh về `AppColors.success`. Legend/policy “đạt” = `success` duy nhất.

### 5.4 Skeleton standard (P1)

- Mỗi loại màn có skeleton riêng cùng kích thước thật: **KPI grid** (4 ô xám), **bảng** (header + 6 hàng), **list card** (3 thẻ). Cấm spinner + skeleton chồng (`10` §12).
- Tạo `TeacherSkeleton.kpiGrid()`, `.table(rows: 6)`, `.cardList(n: 3)` trong `teacher_widgets.dart`; thay mọi `AppLoadingIndicator.center()` ở dashboard/gradebook/analytics.

### 5.5 Data-table standard (P1) — formal hoá trong `07`

| Yêu cầu | Quy tắc |
|---------|---------|
| Sticky | Header **và** cột đầu (tên) sticky khi cuộn ngang |
| Số/điểm | Phải `text-align: right`, font tabular |
| Zebra | Tuỳ chọn, bật khi >8 cột; nền lẻ `surfaceSubtle` |
| Hàng tổng | Pin đáy hoặc nền `primaryTint` rõ |
| Hiệu năng | >100 hàng → `ListView.builder`/pagination, không render hết |
| Hover | Hàng hover `surfaceSubtle`; cell click được → cursor pointer |

### 5.6 Inline validation standard (P1)

- Lỗi hiển thị **ngay dưới field** (`error 12/400 danger`), kích hoạt **on blur → on change** sau lần lỗi đầu (`10` §8).
- Lỗi cấp form: banner `dangerBg` đầu form liệt kê field lỗi.
- Toast chỉ cho lỗi **mạng/máy chủ**, không cho lỗi validate.
- Thêm helper `TeacherWebUi.formFieldError(context, msg)` + ràng `TextFormField.validator` hiển thị inline.

### 5.7 Save-state machine (P1) — autosave chuẩn

- Máy trạng thái 4 pha: `idle → saving → saved → error`.
- UI góc phải editor: chấm 6px `textMuted` (idle) → spinner nhỏ (saving) → `success` + “Đã lưu 12:48” (saved, mờ sau 800ms) → `Sync failed · Retry` (`danger`).
- Debounce 1.5–2s sau lần gõ cuối; giữ nháp local khi mất mạng (`06` §10).

### 5.8 Destructive & irreversible action standard (P0)

| Mức | Ví dụ | Yêu cầu |
|-----|-------|---------|
| Phá huỷ thường | Xoá member, đóng phiên | Nút `compactDangerOutlinedStyle` + confirm 480 + body hệ quả |
| **Không thu hồi** | **Phát hành kết quả**, kết thúc & nộp tất cả | Nút **filled danger** + banner cảnh báo + **gõ xác nhận** (số HS bị ảnh hưởng) |

→ Sửa `teacher_release_results_dialog.dart` theo mức “không thu hồi”.

### 5.9 Focus-visible toàn cục (P0)

- Bọc mọi phần tử tap được bằng `FocusableActionDetector` hoặc `WidgetStateProperty` để vẽ ring 2px `focusRing` offset 2 khi focus bằng `Tab` (không chỉ input).
- Áp cho: sidebar tile (`teacher_shell.dart`), icon button header, KPI card, dialog choice tile.

### 5.10 Motion scale hoàn chỉnh (P2)

Thêm vào `AppMotion`:
```dart
static const Duration micro      = Duration(milliseconds: 90);   // hover/press
static const Duration pulse      = Duration(milliseconds: 900);  // live dot
static const Duration staggerStep= Duration(milliseconds: 55);   // list enter
```
- Cấm `Duration(milliseconds: <số>)` rời trong widget; chỉ dùng `AppMotion.*`.
- Mọi animation tôn trọng `MediaQuery.disableAnimations` → fade 80ms (`10` §6).

### 5.11 Density tiers chính thức (P2)

| Tier | Row height | Token | Dùng cho |
|------|-----------|-------|----------|
| Compact | 32 | `tableRowCompact` | Audit log, gradebook lớp đông |
| Default | 40 | `tableRowDefault` | Hầu hết bảng |
| Comfortable | 52 | — | Cell 2 dòng (tên + email) |

→ Khớp `TeacherWebUi` (32/40); cập nhật `06` §9 (đang ghi 36/44/52 cũ).

### 5.12 Empty-state-with-CTA standard (P2)

- `TeacherEmptyCard` thêm tham số `action` (Filled 32px) + 1 dòng gợi ý bước kế tiếp. Vd bảng đề rỗng → “Tạo đề đầu tiên”.

---

## 6. Remediation plan (thực thi theo phase, có audit gate)

> **Nguyên tắc:** foundation trước → sweep cơ học → UX theo màn → polish. **Mỗi phase đóng bằng 1 cổng audit** (tự động + tĩnh + thủ công); không đạt thì không qua phase sau.
> **Baseline 06/2026** (đo bằng `tool/ui_audit`): hex literal **13** · `BorderRadius.circular(<số>)` **144** · spinner `AppLoadingIndicator.center` **22**. Mỗi phase phải kéo các số này về mục tiêu.

### 6.0 Ưu tiên gốc

| Ưu tiên | Hạng mục | Lý do |
|:-------:|----------|-------|
| **P0** | §5.1 token enforcement · §5.2 overlay tokens · §5.3 score scale · §5.8 destructive · §5.9 focus-visible | Rủi ro cao (a11y, mất dữ liệu, sai màu) + chặn lệch tương lai |
| **P1** | §5.4 skeleton · §5.5 data-table · §5.6 inline validate · §5.7 save-state | Tác động trực tiếp “mượt” & “thân thiện” |
| **P2** | §5.10 motion · §5.11 density · §5.12 empty CTA | Polish, làm sau khi P0/P1 xong |

### 6.1 Phase 0 — Công cụ audit (làm đầu tiên)

- `tool/ui_audit` đếm & liệt kê vi phạm trong `lib/feature/teacher/**`: `Color(0x`, `BorderRadius.circular(<số>)`, `Duration(milliseconds:<số>)`, `AppLoadingIndicator.center` còn sót.
- In baseline + mục tiêu; về sau tích hợp CI chặn merge nếu số tăng.
- **Cổng:** script chạy được, in đúng baseline.

### 6.2 Phase 1 — Token foundation

- §5.2 overlay tokens (`hoverOverlay/pressOverlay/focusRing/scrim/shadowCard`) vào `AppColors`.
- §5.3 `AppScoreScale` (file mới) hợp nhất 4 sắc xanh.
- §5.10 thêm `AppMotion.micro/pulse/staggerStep`.
- Sửa radius literal **nội bộ** `TeacherWebUi` → `AppRadius.*`; thêm helper `formFieldError()`, `focusableTile()`.
- §5.4 `TeacherSkeleton.kpiGrid/table/cardList` (ghép `AppSkeleton.box` có sẵn).
- **Cổng:** `flutter analyze` sạch; token/helper mới tồn tại.

### 6.3 Phase 2 — Sweep cơ học

- Hex → token (6 file: analytics, assign-dialog, widgets, question-strip). **Mục tiêu hex 13→0.**
- Radius literal → `AppRadius` (map `10→card, 8→input, 6→chip, 14→sheet, 999→pill`; case lệch 20/22 quyết riêng). **Mục tiêu 144→0.**
- Alpha rời → overlay token.
- **Cổng:** `ui_audit` báo hex 0 · radius-literal 0; analyze sạch; smoke-test 5 màn.

### 6.4 Phase 3 — UX theo màn (chia batch)

| Batch | Màn | Việc |
|------|-----|------|
| 3a | dashboard, analytics, gradebook, exams-list | spinner→`TeacherSkeleton` (§5.4); empty + CTA (§5.12) |
| 3b | gradebook | sticky cột tên + header; số căn phải tabular; ảo hoá >100 hàng (§5.5) |
| 3c | exam-editor, integrated-editor | save-state idle/saving/saved/error + autosave debounce (§5.7); inline validate (§5.6) |
| 3d | assign-dialog, edit-profile | inline validate thay toast (§5.6); stepper nếu form quá dài |
| 3e | release-results (reversible) | banner cảnh báo hệ quả (warningBg) — KHÔNG nút đỏ |
| 3e | end-session (không thu hồi) | confirm dialog danger + banner hệ quả (§5.8) |

- **Cổng (mỗi batch):** spinner màn đó = 0; lỗi validate inline; bảng ký nhận màn × tiêu chí.

### 6.5 Phase 4 — Polish a11y & motion

- §5.9 `focusableTile()` cho sidebar tile, icon button, KPI card, dialog tile.
- Hover/press đồng đều; `Duration` rời → `AppMotion`; reduce-motion fade 80ms.
- **Cổng:** Duration-literal 0; tab keyboard thấy ring toàn dashboard; checklist §7 full ✓.

### 6.6 Cơ chế audit check (áp cho mọi cổng)

1. **Tự động:** `tool/ui_audit` — bảng vi phạm trước/sau (mục tiêu về 0).
2. **Tĩnh:** `flutter analyze` sạch.
3. **Thủ công:** bảng ký nhận màn × tiêu chí (skeleton / empty-CTA / inline-validate / focus / destructive / sticky-table).
4. **Hồi quy:** smoke-test 1280×800 + fallback 768.

---

## 7. Checklist tuân thủ (mở rộng từ [`10`](10-accessibility.md) §14)

Bổ sung vào checklist merge UI cho **web teacher**:

- [ ] Không `Color(0x…)` trong `lib/feature/teacher/**` (chỉ `AppColors`/`AppScoreScale`).
- [ ] Không `BorderRadius.circular(<số>)` — dùng `AppRadius`.
- [ ] Không `Duration(milliseconds:<số>)` rời — dùng `AppMotion`.
- [ ] Loading = **skeleton** đúng khung, không spinner toàn vùng.
- [ ] Lỗi field = inline `danger` dưới ô, không toast.
- [ ] Editor có **save-state** (idle/saving/saved/error).
- [ ] Hành động không thu hồi = **filled danger + gõ xác nhận**.
- [ ] Mọi phần tử tap được có **focus ring** thấy bằng `Tab` + hover/press state.
- [ ] Bảng: cột đầu sticky + số căn phải tabular.

---

## 8. Bản đồ file ↔ vấn đề (tra nhanh)

| File | Vấn đề chính | Mục |
|------|--------------|-----|
| `teacher_web_ui.dart` | radius literal trong lớp token; thiếu helper error/skeleton/focus | 3.2, 5.1, 5.6, 5.9 |
| `teacher_shell.dart` | sidebar tile thiếu focus ring; padding magic | 3.7, 5.9 |
| `teacher_gradebook_view.dart` | không sticky cột/zebra/ảo hoá; spacing magic | 4.1, 5.5 |
| `teacher_analytics_page.dart` | hex bucket; spinner | 3.1, 3.3, 5.3 |
| `teacher_assign_exam_dialog.dart` | hex policy; wizard 1-modal; validate submit | 3.1, 3.4, 4.3 |
| `teacher_release_results_dialog.dart` | destructive không tô danger | 3.6, 5.8 |
| `teacher_exam_editor_page.dart` | không autosave; validate toast | 3.4, 3.5, 5.7 |
| `teacher_widgets.dart` / `teacher_exam_question_strip.dart` | `#43A047` legend lệch `success` | 3.1, 5.3 |

> **Khi sửa xong từng mục:** cập nhật `06`/`07`/`08` cho khớp, ghi commit vào [`11-implementation-mapping.md`](11-implementation-mapping.md) “Migration log”.
</content>
</invoke>
