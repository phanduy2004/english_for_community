# 15 — Mobile smart patterns & micro-interactions

> **Phạm vi:** App học sinh (Android, iOS). Bổ sung cho `03` (foundations) và `04` (components) với các pattern **thông minh, thân thiện** mà app hiện đại (Duolingo, Headway, Robinhood, Notion Mobile) đều có.
>
> **Nguyên tắc:** Mỗi pattern phải phục vụ **mục tiêu học tập** — không trang trí.

---

## 0. Student Vibrancy — màu sắc có chủ đích

> **Vấn đề:** UI monochrome (đen + trắng) dễ nhàm chán. **Giải pháp:** Skill Palette (`02` §1.8) — mỗi kỹ năng 1 màu identity, **chữ vẫn đen**, chỉ icon/progress/accent dùng màu.

### 0.1 Khi nào dùng màu

| Element | Màu | Helper Flutter |
|---------|-----|----------------|
| Icon box kỹ năng | Skill `tint` + `color` | `StudentMobileUi.skillIconBox(..., skill:)` |
| Viền trái list card | Skill `color` 3px | `StudentMobileUi.skillAccentCard` |
| AppBar accent line | Skill `color` 2px | `StudentMobileUi.skillAppBar` |
| Filter chip selected | Skill `tint` + border | `filterRow(..., skill:)` |
| Progress bar | Skill hoặc **accent** | `StudentMobileUi.skillProgressBar` |
| Streak / trophy | **accent amber** | `streakChip`, icon `emoji_events` |
| Quick action tròn | Skill mỗi nút | `quickActionButton(..., skill:)` |
| Empty state icon | Skill circle 72dp | `emptyState(..., skill:)` |
| Onboarding slides | Slide 1 Reading · 2 Speaking · 3 accent | `_SlideContent.skill` |

### 0.2 Khi KHÔNG dùng màu

- Heading, body text → luôn `textPrimary`
- Filled CTA chính → luôn `primary` (đen editorial)
- Teacher / Admin UI → không Skill Palette
- Dialog background → `surfaceCard` phẳng, không gradient

---

## 1. Micro-interactions & tactile feedback

> Tham chiếu: Duolingo (haptic mỗi đáp án), Headway (page-turn feel), iOS HIG (system haptic).

### 1.1 Haptic feedback

| Sự kiện | Haptic | Token | Ghi chú |
|---------|--------|-------|---------|
| Chọn đáp án MCQ | `HapticFeedback.selectionClick` | `haptic.select` | Nhẹ, mỗi tap |
| Đáp án **đúng** | `HapticFeedback.mediumImpact` | `haptic.success` | Rõ ràng hơn |
| Đáp án **sai** | `HapticFeedback.heavyImpact` + vibrate 50ms | `haptic.error` | Cảm nhận khác biệt |
| Submit bài | `HapticFeedback.mediumImpact` | `haptic.confirm` | Kèm animation |
| Pull-to-refresh trigger | `HapticFeedback.selectionClick` | `haptic.refresh` | Lúc "nhả" tay |
| Streak milestone | Pattern: short-short-long | `haptic.celebrate` | Chỉ milestone ≥ 7 ngày |

**Code reference:**

```dart
abstract final class AppHaptic {
  static void select() => HapticFeedback.selectionClick();
  static void success() => HapticFeedback.mediumImpact();
  static void error() => HapticFeedback.heavyImpact();
  static void celebrate() {
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 100), HapticFeedback.lightImpact);
  }
}
```

### 1.2 Answer feedback animation

| State | Animation | Duration | Spec |
|-------|-----------|----------|------|
| Đáp án đúng | Scale 1.0 → 1.03 → 1.0 + border glow `success` | 250ms | `easeOutBack` |
| Đáp án sai | Shake X ±4dp (3 cycles) + border flash `danger` | 300ms | `easeOut` |
| Chờ chấm (AI) | Pulse opacity 0.6 ↔ 1.0 trên border | 1200ms loop | `easeInOut` |

### 1.3 Button press feedback

- Filled button: scale 0.97 khi press, 1.0 khi release → **80ms** `easeOut`.
- Outlined button: bg shift → `primaryTint` khi press.
- Destructive: scale 0.97 + bg shift `danger` → darker 8%.
- **Disabled**: không scale, không ripple — chỉ opacity surface.

---

## 2. Bottom sheet system

> Tham chiếu: Apple Maps (peek/half/full), Notion (action sheet), Google Sheets (scrollable form).

### 2.1 Sheet sizes

| Size | Chiều cao | Khi dùng |
|------|-----------|----------|
| `peek` | 25% màn | Quick action menu (3–5 item) |
| `half` | 50% màn | Filter, sort, chọn skill, in-skill embed |
| `expanded` | 85% màn | Form dài, danh sách nhiều, exam in-skill |
| `full` | 100% (có AppBar) | Editor, review detail |

### 2.2 Anatomy

```
┌──────────────────────────────────────────┐
│         ═══ Handle 36×4 ═══              │ ← drag handle, `textMuted`
│  Title (h2 14/600)           [Close 18]  │ ← chỉ khi `half` trở lên
├──────────────────────────────────────────┤
│                                          │
│  Scrollable body                         │
│                                          │
├──────────────────────────────────────────┤
│  [ CTA full-width 48dp ]                 │ ← optional sticky bottom
│  + bottom safe area                      │
└──────────────────────────────────────────┘
```

### 2.3 Quy tắc

- Handle **luôn** hiện → cho phép swipe-to-dismiss.
- Sheet `peek` → `half` → `expanded`: kéo hoặc tap nội dung mở rộng (snap points).
- Backdrop: `rgba(0,0,0,0.30)` — tap backdrop đóng sheet (trừ `full`).
- Sheet không bao giờ vượt quá **92% chiều cao** (trừ `full`).
- Border radius top: **16**.
- Bg: `surfaceCard`.
- Bottom CTA: dính đáy, padding `16` + `MediaQuery.padding.bottom`.

### 2.4 Action sheet (quick actions)

- List dọc, mỗi item: icon 20 + label 14/400 textPrimary, height **52dp**.
- Item destructive: icon + label `danger`.
- Divider `outlineMuted` 1px trước item destructive.
- Cancel ở cuối: Outlined full-width 44dp, separated bằng gap **8**.

---

## 3. Carousel & swipeable cards

> Tham chiếu: Duolingo (lesson carousel), Lingvist (flashcard swipe), Tinder (swipe gesture).

### 3.1 Horizontal carousel (discover / skill suggest)

- Card width: **280dp** (screen width - 80).
- Gap giữa card: **12**.
- Snap: trung tâm card snap vào giữa viewport.
- Peek: card kế bên nhìn thấy **20dp** để gợi swipe.
- Indicator: dots dưới carousel, 6dp, gap 6, max 5 dots (scroll nếu nhiều hơn).
- Page padding: **14** trái cho card đầu.

### 3.2 SRS flashcard swipe

- Card 280×400, centered.
- Swipe phải = "Biết" (bg tint `success`), swipe trái = "Chưa biết" (bg tint `danger`).
- Rotation nhẹ ±8° theo hướng swipe.
- Threshold: 40% chiều rộng → commit swipe; dưới → snap về.
- Stack 3 card (front + 2 behind scale 0.95 + 0.90).
- Haptic `select` khi vượt threshold.

### 3.3 Skill grid (responsive)

- `xs–md` (≤479dp): Grid **2×2**, card square-ish (chiều cao tự co).
- `lg` (480–599dp): Grid **2×2** nhưng padding 18.
- `tablet` (600+): Grid **4×1** hoặc **2×2** lớn hơn.
- Card tap: ripple + scale 0.97 (80ms) → navigate.

---

## 4. Pull-to-refresh & pagination

### 4.1 Pull-to-refresh

- Indicator: custom — icon **`refresh`** 20dp, bg `surfaceCard` tròn + shadow `e.1`.
- Kéo ≥ 64dp → trigger; icon xoay 360° trong 600ms khi loading.
- Haptic `select` khi trigger point.
- **Skeleton per-section**: mỗi section hiện skeleton riêng, không spinner toàn màn.

### 4.2 Infinite scroll / load-more

- Trigger: còn **3 item** trước cuối list → fetch next page.
- Indicator: `LoadMoreSkeletonBar` 8dp cao, full-width shimmer.
- End-of-list: text `Đã hết nội dung` 12/400 `textMuted`, centered, padding 24 dọc.
- Error load-more: inline card outline + `Thử lại` TextButton.

### 4.3 Skeleton loading rules

| Loại nội dung | Skeleton | Số lượng |
|---------------|----------|----------|
| List card | Card skeleton giống card thật | Bằng `pageSize` hoặc **3** (ít hơn) |
| Grid 2×2 | 4 box skeleton | Cố định 4 |
| Detail page | Header skeleton + body paragraph skeleton | 1 set |
| Tab content | Skeleton riêng từng tab, hiện khi chuyển tab | 1 set/tab |

---

## 5. Image & media placeholders

### 5.1 Thumbnail

- Aspect ratio cố định: **1:1** (avatar, skill icon), **16:9** (lesson card), **4:3** (reading).
- Placeholder: `surfaceSubtle` + icon `image_outlined` 18 `textMuted` centered.
- Loading: shimmer (`AppSkeleton.box`) cùng kích thước.
- Error: bg `surfaceSubtle` + icon `broken_image_outlined` 18 `textMuted`.

### 5.2 Avatar fallback (mở rộng `04` §8)

- Size rời rạc: **24 / 32 / 40 / 64 / 88** (thêm 88 cho profile hero).
- Fallback: bg `primaryTint`, initials `primaryDark` (weight 600).
  - 24: font 10. 32: font 12. 40: font 14. 64: font 22. 88: font 28.
- Border: **1px `outline`** khi trên nền trắng; **2px white** khi trên ảnh.
- Online dot (nếu cần): 8dp circle `success`, border 2px `surfaceCard`, góc dưới phải.

### 5.3 Audio waveform placeholder

- Khi audio chưa load: 5 bar tĩnh (height random 8–24dp, width 3dp, gap 2dp), color `outlineMuted`.
- Loading: bar shimmer.
- Playing: bar animate theo amplitude (simple sin wave, 120ms update).

---

## 6. Badge & notification system

### 6.1 Badge variants

| Variant | Size | Khi dùng |
|---------|------|----------|
| `dot` | 8dp circle | Có update chưa đọc (notification, lớp mới) |
| `count` | 18dp min-width pill, font 10/600 | Số thông báo, bài chờ nộp |
| `text` | auto pill, font 10/600 | "New", "AI", "Beta" |

### 6.2 Placement

- **Tab icon** (bottom nav): dot hoặc count **trên phải** icon, offset (-2, -2).
- **Card trailing**: dot cạnh chevron, hoặc count pill.
- **Avatar**: dot `success` cho online (góc dưới phải avatar).
- **List item**: dot 6dp cạnh trái title (notification center).

### 6.3 Styling

- `dot`: bg `danger` (notification) hoặc `primary` (update).
- `count`: bg `danger`, fg white, border 1.5px `surfaceCard`.
- `text`: bg `infoBg`, fg `info`, border 1px `info.withOpacity(0.3)`.

---

## 7. Gamification components

> Tham chiếu: Duolingo (streak, XP bar, crown), Headway (reading streak), Apple Fitness (rings).

### 7.1 Streak flame

- Flame icon **24dp** khi inline, **40dp** khi hero.
- Color tiers:
  - 1–6 ngày: `textSecondary` (chưa đặc biệt).
  - 7–29 ngày: `accent` (amber glow).
  - 30+ ngày: `accent` + subtle pulse animation (2s cycle, opacity 0.8 ↔ 1.0).
- Bên phải: số ngày `kpi` weight 600 + "ngày" caption.

### 7.2 XP progress bar

- Full-width 8dp, bg `outlineMuted`, fg gradient `primary → primaryDark`.
- Label dưới bar: `120 / 500 XP` caption 11/400 `textSecondary`.
- Khi đạt mốc: bar flash `accent` 400ms + confetti (xem §7.5).

### 7.3 Level badge

- Circle 32dp, bg `primaryTint`, border 2px `primary`.
- Số level bên trong: `kpi` 13/600 `primaryDark`.
- Khi level up: scale 1.0 → 1.3 → 1.0 (300ms `easeOutBack`) + haptic celebrate.

### 7.4 Daily goal ring

- Stroke 4dp, đường kính 56dp (compact) / 88dp (hero).
- Track: `outlineMuted`. Fill: `primary`.
- Bên trong: phần trăm `kpi` 15/700 `textPrimary`.
- 100%: fill đổi sang `accent`, icon ✓ overlay.

### 7.5 Celebration sheet

> Hiện **sau khi hoàn thành bài** hoặc **đạt milestone** — sheet `half`, auto-dismiss 4s.

```
┌──────────────────────────────────────────┐
│                                          │
│         🎉  (confetti particles)         │
│                                          │
│     ✦ Xuất sắc ✦                        │ ← h1 18/700 textPrimary
│                                          │
│     +15 XP       Streak: 12 ngày        │ ← kpi + accent flame
│                                          │
│  ┌────────────────────────────────────┐  │
│  │  Writing: 8.5/10 · Reading: 9/10  │  │ ← breakdown card outline
│  └────────────────────────────────────┘  │
│                                          │
│  [ Tiếp tục ]   ← Filled primary 48dp   │
└──────────────────────────────────────────┘
```

- Confetti: 20–30 particles, colors `accent` / `success` / `info` / `primaryTint`.
- Duration: 1.2s ease, particles fall + rotate.
- **Không** auto-play audio. Chỉ haptic celebrate.

---

## 8. Transition & navigation

### 8.1 Page transitions

| Từ → Tới | Animation | Duration |
|-----------|-----------|----------|
| Tab ↔ Tab | Fade crossfade | 160ms |
| List → Detail | Slide right + fade | 200ms (Cupertino) |
| Card → Full page | Hero (shared element) nếu có ảnh/icon | 250ms |
| Sheet open | Slide up | 200ms `easeOutCubic` |
| Sheet close | Slide down | 160ms `easeIn` |
| Dialog | Fade + scale 0.95 → 1.0 | 160ms |

### 8.2 Shared element (Hero)

- Dùng cho: avatar (list → profile), skill icon (grid → hub), thumbnail (card → detail).
- Chỉ dùng `Hero` widget khi **cùng hình dạng** (cùng radius, cùng aspect ratio).
- Tag: `hero-avatar-{userId}`, `hero-skill-{skillId}`.

### 8.3 Staggered entry

- Khi list đầu tiên load xong → card xuất hiện lần lượt: slide up 20dp + fade, **40ms** delay giữa mỗi card.
- Max: stagger **8 card** đầu, phần còn lại hiện ngay.
- **Chỉ** lần đầu load. Pull-to-refresh **không** stagger lại.

---

## 9. Smart hints & onboarding

### 9.1 Coachmark (first-time tooltip)

- Spotlight: dim mọi thứ (backdrop `rgba(0,0,0,0.60)`) trừ target element.
- Tooltip: `surfaceCard`, radius 12, padding 16, shadow `e.2`.
  - Arrow 8×8 hướng về target.
  - Title 14/600 textPrimary, body 13/400 textPrimary.
  - Button `Got it` TextButton bên phải.
- Max: **3 coachmarks** per flow, không nhiều hơn.
- Persist: lưu `SharedPreferences` key `coachmark_{feature}_seen`.

### 9.2 Contextual empty state

- Thay vì generic "Chưa có dữ liệu" → **gợi ý hành động cụ thể**:

| Vị trí | Empty | CTA |
|--------|-------|-----|
| SRS review trống | `Lưu từ vựng khi tra để ôn sau` | `Tra từ điển →` |
| Speaking chưa có bài | `Thử đọc to một đoạn văn` | `Bắt đầu luyện →` |
| Exam chưa có | `Giáo viên chưa giao bài — hãy ôn luyện trước` | `Khám phá kỹ năng →` |
| Progress tuần trống | `Tuần mới, khởi đầu mới` | `Học ngay →` |

### 9.3 Inline tip (non-blocking)

- Card nhỏ `infoBg`, radius 10, icon `lightbulb_outlined` 16 `info`.
- Text 12/400 textPrimary, 1–2 dòng.
- Dismissible: nút `×` 14 góc phải.
- Show max **1** tip/page.

---

## 10. Offline & connectivity

### 10.1 Offline banner

- Sticky top, 36dp, bg `surfaceInverse`, fg `textInverse`.
- Icon `wifi_off` 16 + text `Không có mạng` 12/600.
- Animate: slide down 36dp khi offline, slide up khi online.

### 10.2 Cached content indicator

- Card có sẵn offline: trailing icon `download_done` 16 `success`.
- Card cần mạng: trailing icon `cloud_outlined` 16 `textMuted`.

### 10.3 Retry pattern

- Inline retry: text `Không tải được` 13/400 `textPrimary` + `Thử lại` TextButton.
- Full-page retry: icon `error_outline` 48 `textSecondary` + title h2 + body + Filled `Thử lại` 48dp.

---

## 11. Accessibility enhancements

### 11.1 Large text support

- Khi `MediaQuery.textScaleFactor > 1.3`: card padding tăng **+4**, button height tăng **+4**.
- Hàng 2-column → fallback 1-column khi text không vừa.

### 11.2 Reduced motion

```dart
final reduceMotion = MediaQuery.disableAnimationsOf(context);
final pageDuration = reduceMotion
    ? const Duration(milliseconds: 50)
    : AppMotion.page;
```

- Tắt: staggered entry, confetti, shake, pulse.
- Giữ: fade (ngắn 50ms), focus ring.

### 11.3 Touch target audit

| Component | Current | Spec | Action |
|-----------|---------|------|--------|
| Chip filter | ~28dp | 44dp (touch area) | Thêm padding invisible |
| Tab label | ~32dp | 44dp | Extend tap area |
| Trailing chevron | 18dp icon | 44dp tap area | InkWell bọc 44×44 |
| Close button sheet | 18dp | 44dp | IconButton constraints 44 |

---

## 12. Dark mode token mapping (chuẩn bị)

> Chưa implement — nhưng map sẵn để khi bật chỉ cần swap.

| Light token | Dark value | Note |
|-------------|-----------|------|
| `surface` #FAFAF9 | `#121212` | True dark |
| `surfaceCard` #FFFFFF | `#1E1E1E` | Elevated surface |
| `surfaceSubtle` #F5F5F4 | `#2A2A2A` | |
| `textPrimary` #1C1917 | `#E7E5E4` | Swap light ↔ dark |
| `textSecondary` #57534E | `#A8A29E` | |
| `textMuted` #A8A29E | `#57534E` | |
| `outline` #E7E5E4 | `#3A3A3A` | |
| `outlineMuted` #F1F0EE | `#2E2E2E` | |
| `primary` #0A0A0A | `#FFFFFF` | Black → white on dark |
| `onPrimary` #FFFFFF | `#0A0A0A` | |
| `accent` #F59E0B | `#FBBF24` | Brighter amber on dark |
| `primaryTint` rgba(10,10,10,.06) | rgba(255,255,255,.08) | |
| Semantic bg (success/warning/danger/info) | Darken 50-tone: #0A3D20 / #3D2A0A / #3D0A0A / #1E1E3D | |

---

## 13. Component code map

| Pattern | Proposed file | Status |
|---------|---------------|--------|
| `AppHaptic` | `lib/core/ui/interactive/app_haptic.dart` | Mới |
| `AppBottomSheet` helpers | `lib/core/ui/widget/app_bottom_sheet.dart` | Mới |
| `AppBadge` (dot/count/text) | `lib/core/ui/widget/app_badge.dart` | Mới |
| `AppChip` (filter/tag/status) | `lib/core/ui/widget/app_chip.dart` | Mới |
| `AppCoachmark` | `lib/core/ui/interactive/app_coachmark.dart` | Mới |
| `CelebrationSheet` | `lib/core/ui/widget/celebration_sheet.dart` | Mới |
| `OfflineBanner` | `lib/core/ui/widget/offline_banner.dart` | Mới |
| `AppCard` | `lib/core/ui/widget/app_card.dart` | Sửa (radius, border, shadow, token) |
| `AppNavigationBar` | `lib/core/ui/widget/app_navigation_bar.dart` | Sửa (height, label style) |
| `AppSkeleton` | `lib/core/ui/widget/app_skeleton.dart` | Sửa (dùng AppColors token) |

---

## 14. Checklist cho dev mobile

- [ ] Haptic đã gọi đúng event (select/success/error/celebrate)?
- [ ] Sheet có handle + swipe-to-dismiss?
- [ ] Card dùng `AppCard(variant: .outline, radius: 12)` không hardcode?
- [ ] Loading dùng skeleton, không spinner toàn màn?
- [ ] Empty state có CTA cụ thể (không generic)?
- [ ] Image có placeholder + error fallback?
- [ ] Badge/dot cho notification đã update realtime?
- [ ] Staggered entry chỉ lần đầu (flag `_hasAnimated`)?
- [ ] Pull-to-refresh mỗi section riêng?
- [ ] Hit target ≥ 44dp cho mọi interactive element?
- [ ] `reduceMotion` check trước animation phức tạp?

---

## 15. Liên kết

- Foundations: [`03-mobile-foundations.md`](03-mobile-foundations.md)
- Components base: [`04-mobile-components.md`](04-mobile-components.md)
- Screen specs: [`05-mobile-screens.md`](05-mobile-screens.md)
- Tokens: [`02-design-tokens.md`](02-design-tokens.md)
- Accessibility: [`10-accessibility.md`](10-accessibility.md)
- AI guardrails: [`12-ai-guardrails.md`](12-ai-guardrails.md)
