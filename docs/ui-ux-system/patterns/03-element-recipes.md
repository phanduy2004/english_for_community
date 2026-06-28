# 03 — Element recipes (tinh chỉnh "Mobbin-grade")

> Lớp **micro-detail** chồng lên [`04-mobile-components`](../04-mobile-components.md). `04` định nghĩa "element là gì"; file này lo **những chi tiết khiến nó "đắt"**: state (rest/hover/press/disabled), kỷ luật **shadow & overlay**, nhịp spacing, motion, edge-case — bám đúng token Editorial Black.
>
> Không định nghĩa token/màu mới. Khi lệch `04` → `04` thắng.

**Token nền hay dùng ở đây:**
- Overlay: `hoverOverlay` (đen 4%, web) · `pressOverlay` (đen 8%) — đặt tên cho mọi alpha, **không hardcode**.
- Tint: `primaryTint` (đen 6%) · `primaryStrong` (đen 10%) · `accentTint` (amber 14%).
- Shadow 3 lớp: `shadowCard` · `shadowAmbient` · `shadowHairline` — **mảnh, nhiều lớp nhẹ** hơn 1 bóng đậm.
- Radius: `AppRadius.input/card/chip/pill/sheet`. Spacing: `AppSpacing.s1…s10`. Motion: `AppMotion.base` + reduce-motion.

---

## R1 · Card

**Mobbin-grade khi:** phẳng, viền hairline + bóng **rất mảnh nhiều lớp**, không "nổi khối".

| Chi tiết | Spec |
|----------|------|
| Nền / viền | `surfaceCard` + `outline` 1px; radius `AppRadius.card` |
| Bóng | tối đa **2 lớp**: `shadowCard` + `shadowAmbient` (đừng đổ bóng đậm 1 lớp) |
| Press (mobile) | overlay `pressOverlay` qua `InkWell`, **không** scale toàn card (trừ `ScalePressable` cho nút nhỏ) |
| Padding | `s4` mặc định; card dày `s5` |
| Variant | `AppCardVariant.outline` (phẳng) / `danger` (lỗi) |
| Lồng nhau | **tránh card-trong-card**; dùng `surfaceSubtle` cho khối con |

**Build:** `AppCard` (`widget/app_card.dart`). **Don't:** bóng đậm, bo > `card+2`, lồng 3 tầng.

---

## R2 · List row

**Mobbin-grade khi:** hàng **phẳng**, phân tách bằng **divider inset** (sau avatar/leading), không xếp thẻ; trailing tối giản (time + badge/chevron tùy ngữ cảnh).

| Chi tiết | Spec |
|----------|------|
| Chiều cao | ≥ 64dp (chat 72); touch ≥ 44 |
| Phân tách | `Divider(indent = leading + gap)` màu `outlineMuted`; **không** viền cả ô |
| Press | `pressOverlay` (mobile) / `hoverOverlay` (web) |
| Trailing | **chat-list: KHÔNG chevron** (`23`); **settings: CÓ chevron** (A9) — đúng ngữ cảnh |
| Unread | đậm + badge **pill**; **không tô nền cả row** |
| Active (web) | `primaryTint` + thanh trái 3px `primary` |

**Build:** `ConversationTile` (chat), `StudentMobileUi.listTile` (settings). **Don't:** chevron trong chat-list; nền-loang unread; thẻ accent mỗi hàng.

---

## R3 · Button

**Mobbin-grade khi:** 1 primary rõ ràng/màn, hệ phân cấp filled→outline→text, press có phản hồi.

| Cấp | Token | Dùng |
|-----|-------|------|
| Primary | `FilledButton` nền `primary` (đen), chữ `onPrimary` | hành động chính (1/màn) |
| Secondary | `OutlinedButton` viền `outline`, chữ `textSecondary` | phụ |
| Text | `TextButton` chữ `primary` | tertiary/inline |
| Destructive | nền/viền `danger` + **confirm** | xoá/đăng xuất |

- Min size 36–44dp; loading → spinner `onPrimary` thay label (giữ width).
- Press: ripple `pressOverlay`; nút nhỏ icon dùng `ScalePressable` (scale 0.97) + `AppHaptics.select`.
- **Amber KHÔNG làm nút** (chỉ celebrate/KPI).

**Don't:** 2 primary cạnh nhau; amber button; nút disabled không rõ trạng thái.

---

## R4 · Input / Search

| Chi tiết | Spec |
|----------|------|
| Nền | `surfaceSubtle` + `outline`, radius `AppRadius.input(+2)`; **no shadow** |
| Focus | viền `primary`/focus ring 2px; không glow màu |
| Prefix/suffix | icon `textMuted`; search có **clear** khi có text |
| Validate | inline **dưới field**, màu `danger` + helper; không dialog chặn |
| Search | debounce ~250ms; empty kết quả → `emptyState(search_off)` |

**Build:** `StudentMobileUi.searchField`; input form `04` §4. **Don't:** validate bằng dialog; ô tìm không có clear; glow màu.

---

## R5 · Chip / Filter

| Trạng thái | Token |
|-----------|-------|
| Unselected | `surfaceCard` + `outline`, chữ `textPrimary` |
| Selected (skill-screen) | `AppSkillColors.of(skill)`: tint bg + color border + dark text |
| Selected (phi-skill) | `primaryTint` bg + `primary` border + `primaryDark` text |
| Radius | **`AppRadius.pill`** (chip lọc) |

- 1 selected/nhóm; cuộn ngang nếu tràn; gap `s3`.
- Badge **đếm** (không phải filter) → cũng `pill`, nền `primary`/`accent`, chữ trắng.

**Build:** `StudentMobileUi.filterChip/filterRow`. **Don't:** nhiều selected mơ hồ; radius `card` cho badge số (phải `pill`).

---

## R6 · Bottom sheet / Dialog

| Chi tiết | Spec |
|----------|------|
| Sheet | handle 36×4 `textMuted`; radius `AppRadius.sheet(+2)` top; `surfaceCard`; `isScrollControlled` |
| Header sheet | title giữa + close 44dp (`StudentBottomSheet`) |
| Dialog | `StudentDialogShell` maxWidth ~320; title h2 + body + actions phải |
| Scrim | `scrim` (đen 40%); tap-outside đóng (trừ flow chặn) |
| Motion | trượt lên `AppMotion.base`; reduce-motion → fade |

**Build:** `StudentBottomSheet.show`, `StudentDialogShell`. **Don't:** sheet không handle; dialog quá rộng; chặn đóng khi không cần.

---

## R7 · Banner / Strip

| Loại | Spec |
|------|------|
| Promo/hub | card phẳng `surfaceSubtle` (hoặc skill tint) + icon box; ngắn 1–2 dòng |
| Info strip | **1 dòng**, icon 20 + text, padding `s3` — dùng khi không cần card to (xem brief Messages) |
| Realtime | `AppFeedback.banner` (kết nối lại, tin mới) — không chặn |
| First-run hint | chỉ hiện lần đầu/khi rỗng; có hội thoại/data → ẩn |

**Don't:** banner 3 dòng cho thông tin tĩnh chiếm chỗ; lặp ý với subtitle/header.

---

## R8 · Badge / Pill / Status

| Loại | Token |
|------|-------|
| Unread đếm | `pill`, nền `primary`, chữ `onPrimary`, minWidth 20 |
| Notification dot | `danger`, viền `surfaceCard` 1.5px (tách nền) |
| Status (đang làm/đã nộp…) | semantic bg (`successBg`/`warningBg`/`infoBg`) + chữ đậm semantic |
| Celebrate (streak/KPI) | `accentTint` + `accent`/`accentDark` (ngoại lệ amber) |

**Build:** `_UnreadBadge` (conversation_tile), `StudentMobileUi.notificationBadge/streakChip`. **Don't:** badge số radius `card`; status tô skill color.

---

## R9 · Avatar

| Chi tiết | Spec |
|----------|------|
| Có ảnh | hiện ảnh (cover) — `ChatGroupCoverAvatar` |
| Không ảnh | **initials trên màu-theo-tên** (hash) — KHÔNG icon xám đơn điệu |
| Ring/active | ring `primary` khi cần nhấn (vd unread/active) |
| Presence dot | chỉ cho **online thật** (tương lai) — KHÔNG dùng cho "đang mở" |

**Build:** `ChatGroupCoverAvatar(useInitialsFallback:true)` + `ClassroomChatUi.groupAvatarColors`. **Don't:** icon nhóm xám; chấm xanh "online" cho trạng thái active.

---

## R10 · Empty / Loading / Error (polish)

- **Loading = skeleton khung GIỐNG nội dung thật** (không spinner full-màn). Skeleton có shimmer nhẹ; reduce-motion → tĩnh.
- **Empty**: icon tròn (skill nếu skill-screen, neutral nếu không) + title + body + CTA tùy; phân biệt **empty-data** vs **search-empty** (icon + copy khác).
- **Error**: `errorRetry` icon `cloud_off` + nút **Thử lại** (+ `AppHaptics.confirm`).

**Build:** `StudentMobileSkeleton.*`, `StudentMobileUi.emptyState/errorRetry/errorBanner`. **Don't:** màn trắng; nuốt lỗi; spinner thay skeleton.

---

## R11 · Feedback (toast / inline / blocking)

Theo [`26-mobile-feedback-and-notifications`](../26-mobile-feedback-and-notifications.md): `AppFeedback` định tuyến theo mức độ.

| Mức | Kênh |
|-----|------|
| Nhẹ (đã lưu, đã gửi) | SnackBar ngắn |
| Cần chú ý nhưng không chặn | inline / banner |
| Chặn (lỗi nghiêm trọng, xác nhận) | dialog |
| Realtime (tin mới, kết nối) | banner / push |

**Don't:** corner-toast trên student (đã bỏ); lạm dụng dialog cho việc nhẹ.

---

## R12 · Divider / Section / Spacing rhythm

- **Nhịp dọc**: section cách nhau `sectionGap`(14); trong section gap `s2/s3`; tránh `s4+` thừa giữa các khối nhỏ.
- **Section header**: title h2 + (tùy) count pill phải; KHÔNG lặp đếm ở 2 nơi.
- **Divider**: inset (sau leading) màu `outlineMuted` 1px; dùng spacing thay divider khi đủ.

**Don't:** nhồi nhiều "tiêu đề" lặp ý; spacing rời rạc không nhịp; divider full-width trong list có avatar.

---

> Áp recipe vào element thật → cập nhật `04` nếu đổi base, ghi `11` "Migration log".
