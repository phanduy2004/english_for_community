# 02 — Design tokens

> Mọi giá trị visual phải đi qua token. Hardcode = lỗi PR.

## 1. Color — **Editorial Black**

> **Triết lý màu:** brand = **đen tinh tế** (editorial / báo chí / sách), surface ấm (warm stone), accent **amber** chỉ dành cho "ăn mừng". Không pha trộn brand thứ hai. Mọi sắc xanh teal/indigo cũ đã loại bỏ khỏi vai trò brand — chỉ tồn tại ở `info` (link/badge ngữ cảnh).

### 1.1 Brand & primary
| Token | Hex | Note |
|-------|-----|------|
| `primary` | `#0A0A0A` | **Editorial black** — Filled button, AppBar logo, chevron, link nhấn |
| `primaryDark` | `#000000` | Pressed / focus ring |
| `onPrimary` | `#FFFFFF` | Chữ trên nền primary |
| `primaryTint` | `rgba(10,10,10,0.06)` | BG cho chip selected, soft button |
| `primaryStrong` | `rgba(10,10,10,0.10)` | Hover web, list-selected |

### 1.1.b Accent (highlight & celebrate)
| Token | Hex | Use |
|-------|-----|-----|
| `accent` | `#F59E0B` | Streak chip, badge "new", KPI nổi, chart highlight, milestone |
| `accentDark` | `#D97706` | Pressed của accent |
| `accentTint` | `rgba(245,158,11,0.14)` | BG soft cho chip accent |
| `onAccent` | `#1C1917` | Chữ trên nền accent (tương phản tốt nhất là text đen) |

> ⚠️ Accent **không** thay thế primary cho nút thao tác. Accent chỉ xuất hiện khi cần "ăn mừng / nổi bật" trong list dày.

### 1.2 Surface
| Token | Hex | Use |
|-------|-----|-----|
| `surface` | `#FAFAF9` | Scaffold background (page) |
| `surfaceCard` | `#FFFFFF` | Card, sheet, dialog |
| `surfaceSubtle` | `#F5F5F4` | Section gentle highlight |
| `surfaceInverse` | `#1C1917` | Tooltip, snackbar dark |

### 1.3 Border
| Token | Hex | Use |
|-------|-----|-----|
| `outline` | `#E7E5E4` | Default 1px border |
| `outlineMuted` | `#F1F0EE` | Divider, separator |
| `outlineStrong` | `#D6D3D1` | Input border, hover |

### 1.4 Text — **đen-trước-tiên**
| Token | Hex | Khi dùng |
|-------|-----|----------|
| `textPrimary` | **`#1C1917`** | **Mặc định mọi nội dung** (heading, body, list, input, button) |
| `textSecondary` | `#57534E` | **Chỉ** cho meta đơn lẻ: timestamp, tag count, `· · ·` |
| `textMuted` | `#A8A29E` | **Chỉ** cho placeholder & disabled |
| `textInverse` | `#FFFFFF` | Trên surface tối |

> ⚠️ Code review: nếu thấy `textSecondary` áp dụng cho câu/đoạn body → **reject**.

### 1.5 Semantic
| Token | Hex | BG variant | Use |
|-------|-----|------------|-----|
| `success` | `#16A34A` | `#ECFDF5` | Đáp án đúng, completed |
| `warning` | `#D97706` | `#FFFBEB` | Sắp hết giờ, đang chờ |
| `danger` | `#DC2626` | `#FEF2F2` | Đáp án sai, lỗi |
| `info` | `#6366F1` | `#EEF2FF` | Hint, link nội bộ |

### 1.6 Chart (chỉ progress / report)
| Token | Hex | Note |
|-------|-----|------|
| `chartBar` | `#0A0A0A` | Cột chính — đen editorial |
| `chartHighlight` | `#F59E0B` | Cột nổi (best day, milestone) |
| `chartTrend` | `#EF4444` | Đường xu hướng giảm |
| `chartGrid` | `#E7E5E4` | Grid line, axis |

### 1.7 Anti-patterns (cấm)

- ❌ Dùng teal `#0D9488` ở bất cứ đâu.
- ❌ Heading tô màu accent để "nổi" — heading luôn `textPrimary`.
- ❌ Filled button nền amber — amber **không** phải brand.
- ❌ AppBar nền đen toàn phần. AppBar mặc định `surface` (`#FAFAF9`).
- ❌ Đặt 2 màu primary cạnh nhau.

---

## 2. Typography — **Inter** (compact scale **v3**)

> **Font chính:** **Inter** (`AppFonts.fontFamily`). **Fallback IPA:** NotoSans.
>
> **Triết lý v3** (`00-compact-density-v3.md`): nhỏ gọn như Linear / Vercel — body **13**; page title web **16** (không 18–22); KPI **15** tabular.

### Nguyên tắc phân cấp

| Cấp | Weight | Khi dùng |
|-----|--------|----------|
| **Regular (400)** | Nội dung — body, đáp án MCQ, ô input, bảng cell |
| **Semi-bold (600)** | Tiêu đề section, card title, list title, nút, chip, AppBar |
| **Bold (700)** | Page title web, display hero onboarding |

> ❌ Không dùng Medium (500) cho body. ❌ Không bold body để nhấn.

### 2.1 Mobile scale (320–480 dp) — body **13sp**

| Token | Size | Weight | LH | Color | Use |
|-------|------|--------|-----|-------|-----|
| `display` | 18 | **700** | 1.2 | `textPrimary` | Hero onboarding |
| `h1` | 16 | **600** | 1.25 | `textPrimary` | Tiêu đề trong body |
| `h2` | 14 | **600** | 1.3 | `textPrimary` | **AppBar**, section header |
| `h3` | 13 | **600** | 1.35 | `textPrimary` | Card title, list item title |
| `kpi` | 15 | **600** | 1.2 | `textPrimary` | Số điểm / streak (tabular) |
| `body` | **13** | **400** | 1.5 | `textPrimary` | **Default** |
| `bodyLg` | **15** | **400** | 1.5 | `textPrimary` | Reading excerpt |
| `caption` | 11 | 400 | 1.4 | `textSecondary` | Timestamp, meta |
| `label` | 11 | **600** | 1.2 | `textPrimary` | Button, chip |

### 2.2 Web scale (≥768 px) — body **13px**

| Token | Size | Weight | LH | Use |
|-------|------|--------|-----|-----|
| `web.display` | 18 | **700** | 1.2 | Hero (hiếm) |
| `web.pageTitle` | **16** | **600** | 1.25 | **Page header** (Xin chào, tên màn) |
| `web.h2` | 14 | **600** | 1.3 | Card title lớn |
| `web.h3` / `listTitle` | 13 | **600** | 1.35 | List row, shortcut title |
| `web.kpi` | **15** | **600** | 1.2 | **Số KPI dashboard** (tabular-nums) |
| `web.body` | **13** | **400** | 1.5 | Body, input |
| `web.bodyLg` | 15 | **400** | 1.5 | Mô tả dài |
| `web.caption` | 11 | 400 | 1.4 | Meta |
| `web.label` | 11 | **600** | 1.2 | Section label, button |
| `web.table` | 13 | 400 | 1.4 | Table cell |

> ❌ **Không** dùng `web.pageTitle` / `headlineMedium` cho số KPI. Dùng `TeacherWebUi.webKpiValue`.

### 2.3 Code (Flutter)

| File | Vai trò |
|------|---------|
| `lib/core/theme/app_fonts.dart` | `Inter`, `NotoSans` |
| `lib/core/theme/app_typography.dart` | `mobileTextTheme`, `webTextTheme`, `AppTypographyContext` |
| `lib/core/theme/app_theme.dart` | `kIsWeb` → chọn scale; `fontFamily: Inter` |

### 2.4 Numeric / data
- Số tiền/điểm/tỷ lệ trong dashboard dùng **tabular-nums**.
- Bảng (web) căn phải cho cột số.

---

## 3. Spacing

> Unit cơ sở **4**. Đừng tự nghĩ ra giá trị 7, 11, 15.

| Token | Value | Use |
|-------|-------|-----|
| `s.0` | 0 | — |
| `s.1` | 2 | Hairline gap (icon-text inline) |
| `s.2` | 4 | Tight |
| `s.3` | 8 | Default inline gap |
| `s.4` | 12 | Card inner padding tight |
| `s.5` | 16 | Section gap mobile |
| `s.6` | 20 | Page hPadding web (compact); section gap inner |
| `s.7` | 24 | Page hPadding web standard; section gap mobile |
| `s.8` | 32 | Block gap web (rộng) |
| `s.9` | 40 | Top hero pad |
| `s.10` | 56 | Empty state |
| `s.11` | 80 | Onboarding |

**Mobile defaults (compact)**
- `pagePadding`: **14** (giảm từ 16).
- `cardPadding`: **14**.
- `sectionGap`: **20**.
- `cardGap` trong list: **8**.

**Web defaults (compact SaaS)**
- `pagePadding` outer: **24** (giảm từ 32).
- `contentMaxWidth`: **1120** cho main; **1280** cho dashboard có sidebar.
- `sectionGap`: **24** (giảm từ 32).
- `cardGap`: **12** (giảm từ 16).
- `cardPadding`: **20** (giảm từ 24).

---

## 4. Radius

| Token | Value | Use |
|-------|-------|-----|
| `r.chip` | 6 | Chip, micro-tag |
| `r.input` | 8 | Input, button |
| `r.card` | 10 | Card, list tile container |
| `r.sheet` | 14 | Bottom sheet, dialog |
| `r.pill` | 999 | Pill button, chip selected, avatar |

> Mobile & web card **10** (giảm từ 12). Radius lớn dành cho element "floating".

---

## 5. Shadow & elevation

| Token | Spec | Use |
|-------|------|-----|
| `e.0` | none | Default — viền 1px |
| `e.1` | `0 1px 2px rgba(0,0,0,.04), 0 1px 1px rgba(0,0,0,.03)` | Card hover web |
| `e.2` | `0 4px 12px rgba(0,0,0,.06)` | Drawer, popover |
| `e.3` | `0 12px 32px rgba(0,0,0,.10)` | Dialog, modal |
| `e.fab` | `0 6px 20px rgba(10,10,10,.20)` | Mobile FAB |

> **Mobile card dùng `e.0` + viền `outline`**. Không shadow cho list rộng.

---

## 6. Motion

| Token | Duration | Curve | Use |
|-------|----------|-------|-----|
| `m.fast` | 100ms | `easeOut` | Press, hover |
| `m.base` | 160ms | `easeOut` | Show/hide chip, accordion |
| `m.page` | 200ms | `Cupertino` | Page transition mobile |
| `m.web` | 140ms | `easeOutQuad` | Drawer slide, route change web |
| `m.celebrate` | 340ms | `easeOutBack` | Done milestone (giới hạn) |

---

## 7. Iconography

- Bộ chính: **Material Symbols Outlined**, weight 400, grade 0, optical size 24.
- Mobile size: **18** trong list, **20** trong AppBar action, **16** trong inline label.
- Web size: **14** trong table, **16** sidebar, **18** action.
- Cấm trộn 2 bộ icon (outlined + filled) trừ cặp `selected/unselected` trong navigation.

---

## 8. Component heights (compact)

| Component | Mobile | Web |
|-----------|--------|-----|
| Button primary (Filled) | 44dp | 32px |
| Button secondary | 40dp | 28px |
| Input / TextField | 44dp | 32px |
| AppBar / Top bar | 52dp | 48px |
| Sidebar item | — | 30px |
| Table row (default) | — | 40px |
| Table row (compact) | — | 32px |
| Tab bar | 44dp | 36px |
| Status pill | 22dp | 20px |
| Chip filter | 28dp | 24px |

---

## 9. Z-index (web)

| Layer | z |
|-------|---|
| Page | 0 |
| Sticky header | 10 |
| Sidebar | 20 |
| Drawer | 30 |
| Popover / dropdown | 40 |
| Toast | 50 |
| Dialog | 60 |
| Command palette | 70 |
