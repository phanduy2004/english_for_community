# Tracker — 20260626-mobile-typography-system

| Field | Value |
|-------|-------|
| **Status** | P0 **DONE** · P1 **DONE 2026-07-11** (Opus sweep) |
| **Phase** | P1 — `fontSize` sweep (student mobile) ✅ |
| **Implementer** | P0 Cursor · P1 Opus |
| **Date** | P0 2026-06-21 · P1 audit 2026-07-10 · P1 sweep 2026-07-11 |

## P0 — Files changed

| Δ | File | Nội dung |
|---|------|----------|
| Δ1 | `lib/core/theme/app_typography.dart` | Điền 5 slot thiếu (`displayLarge/Medium`, `headlineLarge/Small`, `labelSmall`) cho `mobileTextTheme` + `webTextTheme` |
| Δ2 | `lib/core/theme/app_theme.dart` | `dialogTheme` (title=h1 16, content=body 13) + `snackBarTheme` trong `getTheme()` |
| Δ3 | `lib/core/theme/app_theme.dart` | `dialogTheme` web-scale trong `mergeWorkspaceWeb()` |

## Verify — `dart analyze`

```
cd english_for_community
dart analyze lib/core/theme/app_typography.dart lib/core/theme/app_theme.dart
```

**Kết quả:** exit code **0**. 1 `info` (`unnecessary_import` services.dart — có sẵn, không phải lỗi mới). **0 error / 0 warning.**

## Visual acceptance (DEV)

- [ ] Hot restart runner → mở dialog "Thoát bài?" / "Leave this exercise?" → tiêu đề **~16px** (không còn ~24px Material default)
- [ ] Thử thêm 1–2 AlertDialog khác (đổi mật khẩu, xoá tài khoản) — đúng scale
- [ ] Teacher/admin web dialog vẫn 16/13 qua `mergeWorkspaceWeb`

**Lý do fix:** `dialogTheme.titleTextStyle = headlineMedium` (16/600) thay Material default `headlineSmall` (~24px).

## P1 — Sweep `fontSize` mobile

**Đã audit đầy đủ 2026-07-10 → `p1-sweep-audit.md`** (fan-out 5 explorer khắp màn student).

**Kết quả:** chỉ 18 site dùng `AppTypography.*`; còn **~255 literal `fontSize:<số>` / ~57 file** hardcode, nhiều giá trị lệch scale (10/12/17/20/22/24) → đây là lý do "mỗi màn một cỡ". Note: `AppTypography._mobileScale=0.9` (native) vừa thêm chỉ áp cho site dùng token → sweep này làm scale áp đều.

**Root cause hệ thống (sửa trước, lan rộng):**
- `core/ui/exam_system_ui.dart` — 8 style factory hardcode 12/13/14 → toàn bộ `student/exams/**` lệch.
- `classroom_chat/widgets/classroom_chat_ui.dart` — 7 style (headerTitle/messageBody/timestamp…) hardcode → toàn bộ chat lệch.
- `.copyWith(fontSize:)` đè lên token tốt; giá trị lệch scale; hero number chưa có token.

**Phase (leverage order — chi tiết + bảng file:line ở `p1-sweep-audit.md`):**

| Phase | Vùng | Đổi | Trạng thái |
|---|---|---|---|
| P1.0 | Shared factory (`core/ui/**`) + token `heroNumber` | 15 site + token | ✅ done |
| P1.1 | listening / listening_comp / reading | 33 | ✅ done |
| P1.2 | speaking / writing / vocabulary | ~92 | ✅ done |
| P1.3 | student/** (exams, classes, messages, join) | 45 | ✅ done |
| P1.4 | classroom_chat/** (màn) | 44 | ✅ done |
| P1.5 | home / progress / profile | 12 | ✅ done |

### Kết quả P1 (2026-07-11)

- Thêm token `AppTypography.mobileHero`/`webHero` + helper `heroNumber()` (score reveal / band).
- Sửa 2 factory dùng chung (`exam_system_ui.dart` 8 style, `classroom_chat_ui.dart` 7 style) → hằng `AppTypography.mobile*` (giữ `const`) ⇒ toàn bộ exam + chat tự đúng cỡ.
- Quét literal `fontSize` khắp màn student → thay bằng hằng `AppTypography.mobile*` (chỉ đổi cỡ, giữ nguyên weight/color/height). Tổng ~178 site / ~50 file.
- **Verify:** `dart analyze` core + toàn bộ folder student + teacher/admin → **0 error** (chỉ còn info/warning có sẵn, không liên quan). `grep fontSize:[0-9]` các folder student → chỉ còn **4 allowlist** cố ý:
  - `vocabulary/review_session_page.dart:375` (32) — chữ tiêu điểm flashcard.
  - `student/classes/student_classroom_member_tile.dart:47` (13) — tham số `ChatAvatar` (không phải TextStyle).
  - `classroom_chat/widgets/chat_message_bubble.dart:484` (28) — emoji glyph trang trí.
  - `classroom_chat/widgets/chat_settings_menu.dart:741` (12) — tham số `ChatAvatar`.
- **Chưa build app thật** (mới verify bằng analyzer + grep). Nên hot-restart xem 360×640 vài màn (home, exam runner, chat, writing feedback) để xác nhận thị giác.

### Cập nhật cơ chế thu-nhỏ (2026-07-11)

Ban đầu dùng `AppTypography._mobileScale = kIsWeb ? 1.0 : 0.9` (bake vào từng hằng, gate theo nền tảng). **Đổi sang responsive `textScaler`** vì:
- Người dùng coi "mobile = màn hẹp" (kể cả web mở trên điện thoại), không phải "native vs web" → gate `kIsWeb` bỏ sót web-trên-điện-thoại (dialog vẫn to).
- Bake vào hằng chỉ tới token, KHÔNG tới Material default (dialog default, v.v.).

Giải pháp: bỏ `_mobileScale` (hằng về cỡ chuẩn) + thêm ở `main.dart` builder:
```dart
final mq = MediaQuery.of(context);
final phoneScale = mq.size.width < 600 ? 0.9 : 1.0;   // màn hẹp → 90%
MediaQuery(data: mq.copyWith(
  textScaler: TextScaler.linear(mq.textScaler.scale(1) * phoneScale)), child: …)
```
⇒ **mọi** text (token + Material default + dialog) co đều 10% khi bề ngang < 600 (điện thoại, native lẫn web); desktop/tablet rộng giữ nguyên. `dart analyze main.dart + app_typography.dart` = 0 error.

**Còn lại (P2):** guardrail grep CI cấm `fontSize` literal mới trên màn mobile + ghi doc (chưa làm).
