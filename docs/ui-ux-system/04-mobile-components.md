# 04 — Mobile components

> Mỗi component liệt kê: anatomy, props, state, ví dụ. Khi tạo widget mới — nếu trùng quy cách, **dùng lại** thay vì tạo bản sao.

## 1. Button

### 1.1 Variants
| Variant | Khi dùng | Visual |
|---------|----------|--------|
| `Filled` (primary) | CTA chính của màn / dialog | Bg `primary`, fg `onPrimary`, h 48, r 10 |
| `Filled tonal` | CTA phụ vẫn nổi | Bg `primaryTint`, fg `primaryDark`, h 44, r 10 |
| `Outlined` | Hành động phụ | Viền 1px `outline`, fg `textPrimary`, h 44, r 10 |
| `Text` | Inline | Fg `primary`, padding 8 ngang, h 36 |
| `Destructive` | Xoá, đóng phiên | Bg `danger`, fg white, h 44 |

### 1.2 Anatomy & spec
- Padding ngang: **16**; **20** nếu chứa icon + label.
- Icon size 18, gap 8.
- **Label**: `label` 12/600, `textPrimary` (hoặc onPrimary).
- Disabled: opacity surface 0.4, fg textMuted; **không** đổi màu primary thành xám.
- Loading: thay icon bằng spinner 16, vô hiệu pointer.

### 1.3 Một CTA / màn
- Mỗi màn chỉ có **1 Filled primary**. Có 2 → dùng pattern Filled + Outlined cạnh nhau (Confirm / Cancel).

## 2. Card

### 2.1 Variants (theo `AppCardVariant`)
| Variant | Khi dùng |
|---------|----------|
| `outline` | **Mặc định** mobile — viền 1px, không shadow |
| `elevated` | List home đặc biệt; tránh dùng đại trà |
| `filled` | Section trong screen tĩnh (không bấm) |
| `danger` | Cảnh báo/lỗi inline |

### 2.2 Spec mobile
- Padding nội dung: **16**.
- Radius: **12**.
- Tap: ripple `primary 0.08`, inkwell bo theo radius.
- Khoảng cách 2 card kề nhau trong list: **12**.
- Card có header + body: dòng header 14/600 + body 13/400, gap 8.

## 3. List item

### 3.1 1-line
- Height tối thiểu 56dp; padding 16 ngang, 12 dọc.
- Leading: icon 22 hoặc avatar 32.
- Title: 14/600 textPrimary; trailing chevron 18 textSecondary.

### 3.2 2-line
- Title 14/600 + subtitle 13/400; cả hai textPrimary.
- Phần meta nhỏ (timestamp) bên phải, 12/400 textSecondary.

### 3.3 3-line (hiếm)
- Cho exam attempt list: title + meta + tag row.
- Tag row dùng chip micro 11.

## 4. Input

- Height **48dp**, radius **10**, viền `outlineStrong` 1px.
- Focused: viền `primary` 1.5px, không glow.
- Label trên field: 12/600 textPrimary, gap 6.
- Helper text: 12/400 textSecondary, gap 4.
- Error: viền `danger`, helper đổi sang `danger`.
- Placeholder: textMuted (chỉ chỗ duy nhất dùng textMuted cho text “nhìn thấy”).

### 4.1 Search bar
- Height 44, leading icon `search` 18, clear icon 18 khi có text.
- Bg `surfaceSubtle`, không viền (chìm). Khi focus → viền `outlineStrong` xuất hiện.

### 4.2 Stepper / number
- Cặp nút `−` / `+` 36×36dp, ở giữa số 16/600.

## 5. Chip & tag

### 5.1 Chip filter (selectable)
- Height 32, padding 12 ngang, radius **r.pill 999**.
- Idle: viền `outline`, fg textPrimary; Selected: bg `primaryTint`, viền `primary`, fg `primaryDark`.
- Label `micro 11/500` (KHÔNG bold to).

### 5.2 Tag (semantic, không bấm)
- Height 22, padding 8 ngang, radius `r.chip 6`.
- 4 màu: success / warning / danger / info — bg-50, viền-base/0.35, fg-base.
- Label `micro 11/500`. Không icon trừ khi cần thiết.

### 5.3 Status pill (cho “Đã nộp / Đã chấm / Đã công bố”)
- Pill 24 cao, padding 10 ngang, font 11/600.
- Outline pill (không tô) cho list; tô (chip filter style) cho header.

## 6. Dialog & sheet

### 6.1 AlertDialog
- Width content max 320; padding 24, radius **16**.
- Title 16/600 textPrimary; body 14/400 textPrimary; action row align right.
- 2 actions: Outlined + Filled. Không 3 nút trở lên.

### 6.2 Bottom sheet
- Radius top 16; handle bar 36×4 textMuted; padding 16 + bottom safe area.
- Sheet không full-screen → giới hạn 80% chiều cao.
- Sheet có form → có **AppBar nội bộ** (handle + tiêu đề + close).

### 6.3 Snackbar / Toast
- Bg `surfaceInverse`, fg white, radius 12, height 48, max width 92% màn.
- Auto-dismiss 4s; có 1 action `TextButton` text white.
- Trượt từ dưới lên 16dp; tránh che FAB.

## 7. Skeleton

- Dùng cho list & card chiếm > 30% màn.
- Animation shimmer 1.4s, gradient `outlineMuted → outline → outlineMuted`.
- Số dòng skeleton bằng số card kỳ vọng (không hiển thị 10 dòng nếu chỉ có 3 card).

## 8. Avatar

- Size: 24/32/40/64 (cấu hình rời rạc, không tự ý 36).
- Fallback: nền `primaryTint`, chữ initials `primaryDark` 14/600.
- Border 1px white khi đè trên ảnh / list dày.

## 9. Progress

### 9.1 Linear
- Height 6 mobile, 4 web. Bg `outlineMuted`, fg `primary`. Radius 999.
- Có label cuối dòng bên phải (vd `2/5`) — 12/600 textPrimary.

### 9.2 Circular ring (gamification)
- Stroke 4, đường kính 56–88. Trong ring: số 18/700 textPrimary.

## 10. Empty / Error templates

- `EmptyState`: icon outlined 48 textSecondary + title h2 + body textPrimary + CTA Outlined.
- `ErrorState`: card danger 1 dòng + Retry TextButton.
- `OfflineState`: banner top page surfaceSubtle + icon `wifi_off` + dòng giải thích.

## 11. Score / answer review block (đặc thù exam)

- **MCQ option** đúng: bg `success-50`, viền `success`, icon `check_circle` `success`.
- **MCQ option** sai (đã chọn): bg `danger-50`, viền `danger`, icon `cancel` `danger`.
- **MCQ option** thường: viền `outline`, fg textPrimary.
- Letter prefix `A · B · C` trong ô vuông 36 trái, font 14/700 textPrimary.
- KHÔNG bôi đỏ/lục cả đoạn câu hỏi gốc — chỉ tô option.

## 12. Audio player (Listening / Speaking)

- Hộp 64dp cao, viền `outline`, padding 12.
- Nút play/pause 40dp tròn primary; thanh waveform 6dp; thời gian 12/400 textPrimary.
- Trên Speaking: thêm nút record 56dp pulse mờ khi đang ghi.

## 13. Banner (info / warning)

- Bg semantic-50, viền 1px semantic/0.35, padding 12, radius 12.
- Icon 18 + 1 dòng body 13/400 textPrimary + (tuỳ chọn) `Close`.

---

**Component đã có trong code (cập nhật theo doc này):**
- `AppCard` — `AppCardVariant.outline` chuẩn, gỡ shadow nặng `0x1A000000` cho `elevated`.
- `AppNavigationBar` — đổi `selectedIcon` weight nhẹ hơn, label 12/600.
- `ExamSystemUi` — refactor body sizes về 14, gỡ caption `textSecondary` cho body.
