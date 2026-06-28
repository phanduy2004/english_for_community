# Work-Order — BUG: Cỡ chữ mobile không theo scale (dialog/component bung default Material)

- **Task ID:** 20260626-mobile-typography-system
- **Loại:** BUG (typography / design-token enforcement)
- **Mục tiêu:** Mọi chữ trên màn mobile bám **một scale duy nhất** (AppTypography). Không còn dialog/component bung cỡ mặc định Material (24px+); không còn `fontSize` hardcode tuỳ tiện.
- **Cỡ task:** T2 (P0 sửa theme = MICRO, fix ngay; P1 sweep `fontSize` toàn mobile = nhiều PR) → **work-order + tracker**.
- **Người phân tích:** Opus (brain, KHÔNG tự code). **Implementer:** Cursor. **Auditor:** Cursor + Opus Phase 4. **Status:** PHÂN TÍCH XONG — sẵn sàng handoff **P0 ngay** (§7), P1 theo tracker.

> Theo `docs/AI-Working-Process-vi.md`. Trigger: ảnh dialog "Leave this exercise?" tiêu đề ~24px trên mobile.

---

## 1. Vấn đề + nguyên nhân gốc (có dẫn chứng)

**Triệu chứng:** dialog "Leave this exercise?" có tiêu đề **quá to** (~24px) so với scale mobile (h1=16). Nghi ngờ lan ra các màn khác.

**Ground-truth — 3 tầng nguyên nhân:**

| # | Nguyên nhân gốc | Dẫn chứng | Hệ quả |
|---|-----------------|-----------|--------|
| **RC1** | **Không có `dialogTheme` toàn cục.** Theme chỉ set `appBarTheme.titleTextStyle`; mọi `AlertDialog` không tự set style → tiêu đề rơi về **Material default `headlineSmall` (~24px)**, nội dung `bodyMedium`. | `app_theme.dart` (không có `dialogTheme`); ảnh dialog là `student_mobile_ui.dart:846` `AlertDialog(title: Text(studentRunnerExitTitle))` **không** `titleTextStyle` | 42 `AlertDialog` / 28 file đều to mặc định |
| **RC2** | **`TextTheme` thiếu 5 slot** → component dùng slot đó rơi về default Material (24–57px). | `app_typography.dart` mobile/web **thiếu** `displayLarge`, `displayMedium`, `headlineLarge`, `headlineSmall`, `labelSmall` | bất kỳ widget dùng slot thiếu → off-scale |
| **RC3** | **`fontSize` hardcode tràn lan** → bỏ qua token, không nhất quán giữa màn. | `grep "fontSize:"` = **755 lần / 128 file** (cả mobile + web). | mỗi màn một cỡ; sửa scale 1 nơi không lan |

> RC1+RC2 là **gốc của ảnh chụp** và sửa được **toàn cục, rủi ro thấp**. RC3 là phần "tất cả các màn" — sweep theo phase.

---

## 2. Audit (số liệu)

- `AlertDialog(` : **42** lần / **28** file (đều dựa default trừ vài cái tự set style như `profile_page` delete dialog).
- `fontSize:` hardcode : **755** lần / **128** file (gồm cả teacher/admin web — ngoài scope mobile).
- `dialogTheme` toàn cục: **0** (chỉ 1 local `DialogThemeData(backgroundColor)` ở admin activity_history — không set chữ).
- `TextTheme` slot **đã định nghĩa** (mobile): displaySmall, headlineMedium(h1=16), titleLarge(h2=14), titleMedium/Small(13), body*, label{Large,Medium}. **Thiếu:** displayLarge, displayMedium, headlineLarge, headlineSmall, labelSmall.
- Token scale hiện có (tốt, giữ nguyên): body 13 · h3 13 · h2 14 · h1 16 · display 18 · kpi 15 · caption/label 11.

---

## 3. Cách tối ưu (font architecture đề xuất)

**Nguyên tắc: 1 scale (token) + ép ở tầng theme để không gì "thoát" ra default Material.**

**Tầng 1 — Token (giữ nguyên):** `AppTypography` đã là SSOT, scale compact v3 hợp lý. Không đổi con số.

**Tầng 2 — Ép Material theme (P0, sửa 2 file, fix ngay):**
1. **Hoàn thiện `TextTheme`** (mobile + web): định nghĩa nốt 5 slot thiếu, map về trong scale (≤18px) → mọi component dùng bất kỳ slot nào cũng đúng cỡ.
2. **Thêm `dialogTheme`** (mobile + web): `titleTextStyle` = h1(16/600), `contentTextStyle` = body(13). → fix 42 AlertDialog.
3. **Thêm `snackBarTheme.contentTextStyle`** = body(13). → snackbar đúng cỡ.

**Tầng 3 — Sweep + guardrail (P1/P2):**
4. Thay `fontSize` hardcode trên **màn mobile** → token (`AppTypography.*` / `context.*Style` / `StudentMobileUi.*`). Phase theo feature (tracker).
5. Guardrail: doc `12` + grep CI cấm `fontSize` mới trên mobile; mọi dialog/snackbar qua token.

---

## 4. Scope IN / OUT

**IN:**
- **P0:** `lib/core/theme/app_typography.dart` (điền slot), `lib/core/theme/app_theme.dart` (dialogTheme + snackBarTheme + mergeWorkspaceWeb dialogTheme).
- **P1 (sweep mobile):** các feature **student-facing + shared mobile** (xem tracker): `feature/listening*`, `feature/listening_comp`, `feature/reading`, `feature/writing`, `feature/speaking`, `feature/vocabulary`, `feature/student/**`, `feature/classroom_chat/**` (phần mobile), `feature/progress`, `feature/home`, `feature/profile`, `core/ui/**` (mobile widgets).
- **P2:** doc `12`/`02`/`03` + grep guardrail.

**OUT (chạm là DỪNG & hỏi):**
- ❌ Đổi **con số token** trong AppTypography (scale đang đúng).
- ❌ Sweep `fontSize` ở **teacher/admin web** (`feature/teacher/**`, `feature/admin/**`, `*_web_ui.dart`) — scale web riêng, đã có audit `18`/`19`. *(P0 theme có chạm `mergeWorkspaceWeb` cho dialog web — đúng scale web, OK.)*
- ❌ Đổi style các `AlertDialog` đã tự set token (giữ nguyên).
- ❌ Đổi layout/logic màn — chỉ chữ.

---

## 5. Diff P0 (Cursor implement — fix ảnh chụp + toàn bộ dialog)

### Δ1 — `app_typography.dart` · điền 5 slot thiếu (mobile)
Trong `mobileTextTheme = TextTheme( … )` thêm:
```dart
displayLarge: TextStyle(fontFamily: _f, fontSize: mobileDisplay, fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.2, color: AppColors.textPrimary),   // 18
displayMedium: TextStyle(fontFamily: _f, fontSize: mobileDisplay, fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.2, color: AppColors.textPrimary),  // 18
headlineLarge: TextStyle(fontFamily: _f, fontSize: mobileH1, fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1.25, color: AppColors.textPrimary),       // 16
headlineSmall: TextStyle(fontFamily: _f, fontSize: mobileH1, fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1.25, color: AppColors.textPrimary),       // 16 ← dialog title
labelSmall: TextStyle(fontFamily: _f, fontSize: mobileLabel, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.2, color: AppColors.textPrimary),         // 11
```
Làm **tương tự cho `webTextTheme`** với `webDisplay`(18) / `webPageTitle`(16) / `webLabel`(11).

### Δ2 — `app_theme.dart` · thêm `dialogTheme` + `snackBarTheme` (trong `getTheme()` ThemeData)
```dart
dialogTheme: DialogThemeData(
  backgroundColor: AppColors.surfaceCard,
  surfaceTintColor: Colors.transparent,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  titleTextStyle: baseText.headlineMedium,   // h1 16/600 — tiêu đề dialog mobile
  contentTextStyle: baseText.bodyMedium,     // 13/400
),
snackBarTheme: SnackBarThemeData(
  behavior: SnackBarBehavior.floating,
  backgroundColor: AppColors.surfaceInverse,
  contentTextStyle: baseText.bodyMedium?.copyWith(color: AppColors.textInverse),
),
```

### Δ3 — `app_theme.dart` · `mergeWorkspaceWeb()` thêm dialog web-scale
```dart
dialogTheme: base.dialogTheme.copyWith(
  titleTextStyle: web.headlineMedium,   // 16 web
  contentTextStyle: web.bodyMedium,     // 13 web
),
```

> Sau Δ1–Δ3: dialog "Leave this exercise?" về 16px, toàn bộ 42 AlertDialog + component dùng slot thiếu đều đúng scale — **không đụng từng màn**.

---

## 6. P1 — Sweep `fontSize` mobile (theo `tracker.md`)
- Mỗi phase = 1 feature folder mobile; thay `TextStyle(fontSize: N…)` → token gần nhất (13/14/16/18/15/11) qua `AppTypography.*`/`context.*Style`.
- Giữ nguyên ngữ nghĩa (weight/color). Không đổi layout.
- Acceptance mỗi phase: `grep "fontSize:" <folder>` → 0 (hoặc allowlist có lý do), `dart analyze` sạch, nhìn 360×640 không vỡ.

---

## 7. Lệnh verify

```bash
cd english_for_community
dart analyze lib/core/theme/app_typography.dart lib/core/theme/app_theme.dart
# P1 mỗi phase:
dart analyze lib/feature/<folder>
# Đo tiến độ sweep:
grep -rn "fontSize:" lib/feature/<mobile-folders> | wc -l
```
**Nghiệm thu P0:** mở runner → "Thoát bài?"/"Leave this exercise?" tiêu đề ~16px; thử vài AlertDialog khác (đổi mật khẩu, xoá tài khoản) đều đúng cỡ; `dart analyze` 0 lỗi mới.

---

## 8. HANDOFF — Cursor IMPLEMENT P0 (copy nguyên khối)

```text
Bạn là implementer. CHỈ sửa 2 file dưới; file khác → DỪNG & hỏi.
Repo: english_for_community (Flutter). Work-order: docs/plantasks/BUG/20260626-mobile-typography-system/work-order.md (§5).

FILE:
  1. lib/core/theme/app_typography.dart  — Δ1: điền 5 slot thiếu (displayLarge/Medium, headlineLarge/Small, labelSmall) cho CẢ mobileTextTheme và webTextTheme, dùng hằng size có sẵn (mobileDisplay/mobileH1/mobileLabel; webDisplay/webPageTitle/webLabel).
  2. lib/core/theme/app_theme.dart       — Δ2: thêm dialogTheme + snackBarTheme trong getTheme(); Δ3: thêm dialogTheme web trong mergeWorkspaceWeb().

TUYỆT ĐỐI KHÔNG: đổi con số token; sweep fontSize từng màn (đó là P1); đổi style các AlertDialog đã tự set token; đổi layout/logic.
VERIFY: dart analyze 2 file trên → sạch. Mở runner xem dialog "Thoát bài?" tiêu đề ~16px. Dán kết quả + DONE.
```

---

## 9. HANDOFF — Cursor AUDIT P0 (copy nguyên khối)

```text
Bạn là AUDITOR (không sửa trừ khi tìm lỗi và được phép).
Work-order: docs/plantasks/BUG/20260626-mobile-typography-system/work-order.md

KIỂM:
  - Δ1: cả mobile + web TextTheme nay đủ slot (không còn displayLarge/Medium, headlineLarge/Small, labelSmall = null); size nằm trong scale (≤18 mobile, ≤18 web).
  - Δ2: dialogTheme.titleTextStyle = headlineMedium(16), contentTextStyle = bodyMedium(13); snackBar contentTextStyle = body + màu inverse.
  - Δ3: mergeWorkspaceWeb có dialogTheme web-scale (16/13).
  - Không đổi token số; không đụng layout; AlertDialog tự-set-style vẫn thắng (không bị override sai).
VERIFY: dart analyze 2 file → sạch; mở 2-3 AlertDialog (runner exit, đổi mật khẩu) đúng cỡ.
KẾT QUẢ: APPROVED hoặc finding kèm file:line.
```

---

## 10. Checklist OPUS AUDIT (Phase 4)
- [ ] Δ1 đủ slot mobile + web; size trong scale.
- [ ] Δ2 dialogTheme + snackBarTheme đúng token.
- [ ] Δ3 web dialog scale đúng.
- [ ] Không đổi token số; không scope-creep sang P1/web sweep.
- [ ] `dart analyze` pass; ảnh dialog đã về 16px.
- [ ] P1 tracker được tạo, phase rõ ràng.

## 11. Việc còn lại của DEV
1. Ship P0 trước (fix ảnh + toàn bộ dialog).
2. Chạy P1 theo tracker từng feature; mỗi phase 1 PR nhỏ.
3. P2: thêm guardrail grep vào CI/dev doc khi sweep xong phần lớn.
