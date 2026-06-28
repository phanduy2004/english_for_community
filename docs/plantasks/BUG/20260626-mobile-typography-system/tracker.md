# Tracker — 20260626-mobile-typography-system

| Field | Value |
|-------|-------|
| **Status** | **DONE** (P0) |
| **Phase** | P0 — theme enforcement |
| **Implementer** | Cursor |
| **Date** | 2026-06-21 |

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

Chưa làm — theo tracker phase từng feature folder (work-order §6).
