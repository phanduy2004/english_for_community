# 03 — Mobile foundations

> Typography v3: AppBar **14/600**, body **13/400**, nút **44dp**, bottom nav **60dp**. Chi tiết: `00-compact-density-v3.md`. (cho học sinh)

> Đối tượng: app Flutter chạy trên Android & iOS điện thoại (4.7"–6.7").
> **v2 compact:** pagePadding 14, body 13sp, cardGap 8.

## 1. Breakpoints mobile

| Lớp | Width | Đại diện | Quy tắc |
|------|-------|----------|---------|
| `xs` | 320–359 | iPhone SE (1st) | 1 cột; cho phép xếp 2 chip mỗi dòng tối đa |
| `sm` | 360–399 | Android phổ thông | 1 cột; default |
| `md` | 400–479 | iPhone 14/15 | 1 cột |
| `lg` | 480–599 | Phablet, foldable cover | 1 cột; padding 18 thay vì 14 |
| `tablet` | 600–839 | iPad mini | **2 cột grid** cho list card; max content 560 |

> Trên `tablet`, KHÔNG hiển thị web layout (sidebar) — chỉ phân cột list. Sidebar = web only.

---

## 2. Page anatomy chuẩn

```
┌──────────────────────────────────────────┐
│ AppBar (52dp)                             │ ← title 15/600 textPrimary
├──────────────────────────────────────────┤
│  Page hPadding 14                        │
│                                          │
│  ┌─ Section header (h2) ──────────────┐  │
│  │ "Bài học hôm nay"  15/600          │  │
│  └────────────────────────────────────┘  │
│  s.3 = 8                                 │
│  ┌─ Card (r.card 10, viền 1px) ───────┐  │
│  │ ...                                 │  │
│  └────────────────────────────────────┘  │
│  s.3 = 8 (cardGap)                      │
│  ┌─ Card ──────────────────────────────┐ │
│  └─────────────────────────────────────┘ │
│  s.5 = 16 (sectionGap)                  │
│  ┌─ Section header ───────────────────┐ │
│                                          │
└──────────────────────────────────────────┘
│ NavigationBar (60dp; surfaceCard)       │
└──────────────────────────────────────────┘
```

**Quy tắc:**
- `pagePadding = 14` mọi nơi trừ onboarding hero (20).
- AppBar **không** elevation, **không** scroll under tint.
- Title trái nếu có nhiều action; centered nếu chỉ có 1 action back.
- AppBar action **icon-only**, size 20, max 2 action; nếu cần 3+ → menu `more_vert`.
- Section header: 1 dòng, 15/600 textPrimary, có thể kèm 1 button text bên phải (`Xem tất cả`).
- Khoảng cách giữa AppBar và section đầu: `14`. Khoảng cách giữa hai section: `20`.

---

## 3. Navigation

### 3.1 Bottom navigation (3 tab)
- Tab: Home / Vocabulary / Profile.
- Chiều cao **60dp**, label luôn hiện, font `11/600` khi selected, `11/400` khi không.
- Indicator: pill mờ `primaryTint`, icon đổi từ outlined → filled khi selected.

### 3.2 In-page tabs
- Dùng `TabBar` flutter material 3.
- Label `12/600`, padding ngang 14, indicator dày 2.
- Underline indicator (không pill) — pill dành cho `SegmentedButton` ≤ 3 mục.

### 3.3 Back & navigation
- Nút back (`Icons.arrow_back_rounded` size 20) — luôn ở góc trái AppBar.
- Trên route gốc của tab → KHÔNG hiện back.
- Trang nhúng trong sheet/dialog: dùng `Icons.close_rounded`.

### 3.4 Floating action
- Tối đa 1 FAB / màn. Vị trí góc phải dưới (14, 80 — trên nav bar).
- Style: `FilledButton.icon` extended dạng pill.
- Chỉ có FAB cho thao tác **dương tính** chính (vd. "Bắt đầu luyện tập").

---

## 4. Density & rhythm

- **Line-height** body 1.5; heading 1.25–1.35. Không nén dưới 1.4 cho body.
- **Letter-spacing** chỉ áp cho heading (âm) và micro/label (dương).
- Khoảng cách icon ↔ text: 6dp. Khoảng cách avatar 28dp ↔ text: 10dp.
- Avatar mobile: **28dp** trong list, **36dp** trong header, **56dp** trong profile hero.

---

## 5. Gestures

| Gesture | Hành vi | Ghi chú |
|---------|---------|---------|
| Tap | Navigate / chọn | Hit target ≥ 44dp |
| Long-press | Hiện menu phụ | Tránh dùng — học sinh ít biết |
| Swipe-to-dismiss | Đóng sheet/dialog | Cho phép kéo từ đỉnh sheet |
| Pull-to-refresh | Reload list | Có ở Home, list bài, lịch sử |
| Swipe-tab | Chuyển tab | Chỉ trong TabBarView 2–3 tab |

> Cấm: swipe-to-delete trên list học sinh.

---

## 6. Touch targets & input

- Button height tối thiểu **44dp** (CTA chính). Secondary **40dp**.
- Input height **44dp**, padding 10 ngang, 10 dọc.
- Hit area icon-only: **40×40dp** (icon 20 + 10 padding mỗi bên).
- Khoảng cách giữa 2 button kề nhau: tối thiểu **8dp**.

---

## 7. Color usage on mobile

- Background **`surface`** (#FAFAF9) — KHÔNG trắng tinh.
- Card luôn `surfaceCard` (#FFFFFF) + viền 1px `outline`.
- Phân biệt section bằng **khoảng trắng + heading**, không phải đổi màu nền.
- Trạng thái thành công/lỗi dùng **bg semantic-50** + viền semantic-base + chữ textPrimary.

---

## 8. Status bar & system UI

- Status bar: trong suốt, icon **dark** trên mọi màn.
- Navigation bar Android: cùng tone surface, icon dark.

---

## 9. Loading / empty / error pattern

- **Loading**: dùng `AppSkeleton` cho list & card (3 dòng skeleton là đủ).
- **Empty**: icon outlined 40 + 1 dòng tiêu đề (`h2`) + 1 dòng phụ (`body`) + (tuỳ chọn) 1 CTA `OutlinedButton`.
- **Error**: card `danger` viền đỏ, 1 dòng lỗi ngắn, `Retry` `TextButton`.

---

## 10. Safe area

- Tôn trọng SafeArea **trên** (status bar) và **dưới** (gesture bar).
- Bottom sheet phải `+ MediaQuery.padding.bottom`.
- Không đặt CTA chính dính sát mép dưới (cách 12dp tối thiểu).
