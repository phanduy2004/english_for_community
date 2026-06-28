# Pattern Library — bộ sưu tập thiết kế kiểu "Mobbin"

> **Mục đích:** một **thư viện tham chiếu** (reference library) các **blueprint màn hình** và **pattern UI** mobile chất lượng cao — kiểu [Mobbin](https://mobbin.com) — để khi dựng/redesign một màn, bạn **tra archetype → ráp theo zone → map token** thay vì thiết kế lại từ đầu.
>
> Khác với phần còn lại của `ui-ux-system/`:
> - `02/04` = **spec component của App** (button/card/input… — "cái app có gì").
> - `patterns/` (file này) = **catalog mẫu theo archetype** ("màn loại này dựng thế nào, app tốt làm sao") — lớp cảm hứng + khung layout, **map ngược** về token + widget sẵn có.
>
> Toàn bộ vẫn tuân **Editorial Black** (`02-design-tokens.md`): chữ/brand đen, surface warm-stone, amber chỉ để "ăn mừng". Không có màu lạ ngoài hệ.

---

## 1. Cách dùng bộ này

1. **Xác định archetype** của màn cần dựng (Home? List? Detail? Empty? Chat?) → mở [`01-screen-archetypes.md`](01-screen-archetypes.md).
2. **Đọc blueprint**: zone layout (ASCII), state (loading/empty/error/success), reference apps để xem mẫu thật trên Mobbin.
3. **Ráp bằng widget sẵn có** (cột "Build with") — `StudentMobileUi.*`, `AppCard`, `ConversationTile`, … — KHÔNG tự chế component mới nếu đã có.
4. **Map token**: mọi màu/spacing/radius lấy từ `AppColors` / `AppSpacing` / `AppRadius` (`11-implementation-mapping.md`). Accent amber chỉ cho celebrate.
5. **Đối chiếu chuẩn mobile**: touch-target 44dp, skeleton, reduce-motion, Semantics — `20-student-mobile-audit-and-standards.md`.

> **Quy tắc vàng:** pattern ở đây là **khung**, không phải luật cứng. Khi lệch với `02/04`, **token/`04` thắng**. Pattern chỉ quyết định *bố cục & nhịp*, không quyết định *màu/typography*.

---

## 2. Hai trục phân loại (như Mobbin)

Mobbin cho duyệt theo **Screen** và theo **UI Element**. Bộ này cũng vậy:

### 2.1 Theo Screen archetype → [`01-screen-archetypes.md`](01-screen-archetypes.md)
Khung layout cho từng *loại* màn. Áp cho app học sinh E4C:

| # | Archetype | Màn E4C tương ứng |
|---|-----------|-------------------|
| A1 | **Home / Dashboard** | Home học sinh (greeting + stats + quick actions + continue) |
| A2 | **Hub / Browse list** | Skill hubs (listening/reading/…), danh sách bài |
| A3 | **Runner / Focused task** | Làm bài MCQ, dictation, speaking, exam |
| A4 | **Detail / Reader** | Bài đọc, chi tiết bài học, review |
| A5 | **Conversation list** | Tab Messages (`ConversationTile`) |
| A6 | **Chat thread** | Màn chat lớp (`classroom_chat`) |
| A7 | **Search & Filter** | Search trong hub/messages, filter chips |
| A8 | **Empty / Loading / Error** | Mọi màn — 3 trạng thái bắt buộc |
| A9 | **Profile / Settings** | Profile, cài đặt tài khoản, reminder |
| A10 | **Auth / Onboarding** | Login, register, OTP, goal/level setup |
| A11 | **Result / Celebrate** | Kết quả bài, streak, level-up |
| A12 | **Stats / Progress** | Trang tiến độ, biểu đồ tuần |

### 2.2 Theo UI Element → trỏ về [`04-mobile-components.md`](../04-mobile-components.md)
Không spec lại element ở đây. Khi pattern cần 1 element, link tới `04` + widget thật:

| Element | Spec | Widget |
|---------|------|--------|
| Tab bar (bottom nav) | `03` §nav | `app_navigation_bar.dart` |
| Top header | `04` | `StudentMobileUi.appBar` / `skillAppBar` |
| Card | `04` | `AppCard` (`widget/app_card.dart`) |
| List row | `04`, `23` | `ConversationTile`, `StudentMobileUi.listTile` |
| Button | `04` | `FilledButton` (primary), `OutlinedButton` |
| Input / Search | `04` §4.1 | `StudentMobileUi.searchField` |
| Chip / Filter | `04` | `StudentMobileUi.filterChip/filterRow` |
| Banner | `05` §4.1 | `StudentMobileUi.skillHubBanner` |
| Sheet / Dialog | `15` §2, `04` §6 | `StudentBottomSheet`, `StudentDialogShell` |
| Skeleton | `20` §5.4 | `StudentMobileSkeleton`, `*Skeleton` |
| Badge | `20` | `StudentMobileUi.notificationBadge`, unread pill |
| Empty/Error | `20` §5.9 | `StudentMobileUi.emptyState/errorRetry` |
| Feedback (toast/banner) | `26` | `AppFeedback` |

### 2.3 Theo Flow (tùy chọn, sẽ bổ sung) → `02-flows.md` (TODO)
Onboarding flow, Lesson/runner flow, Exam flow, Chat flow — chuỗi màn + transition.

---

## 3. Reference apps (để "đào" mẫu trên Mobbin)

Chọn app gần triết lý Editorial Black + đúng archetype. Khi xem trên Mobbin, **lọc bằng tên app** dưới đây:

| Nhóm | App tham chiếu | Học gì |
|------|----------------|--------|
| **Learning / habit** | Duolingo, Headway, Blinkist, Quizlet, Busuu, Khan Academy | Home gamified, lesson runner, streak/celebrate, progress |
| **Editorial / clean** | Linear (mobile), Notion, Things 3, Cron | List phẳng, density, typographic hierarchy, empty state tinh tế |
| **Chat / social** | Telegram, Messenger, Slack, WhatsApp | Conversation list, chat thread, composer, presence |
| **Finance / data** | Robinhood, Copilot, Cash App | Stats/biểu đồ, KPI nổi (amber), number-forward |
| **OS baseline** | iOS HIG, Material 3 | Sheet, nav, gesture, touch-target, motion |

> **Mẹo dùng Mobbin:** duyệt theo **Screen category** (Home, List, Detail, Empty State, Paywall, Onboarding…) hoặc **UI Element** (Tab bar, Card, Bottom sheet…). Lưu screen vào board, rồi đối chiếu với blueprint ở `01`. Bộ doc này = bản "đã lọc + adapt về Editorial Black" của những gì đáng lấy.

---

## 4. Template 1 pattern (dùng khi thêm pattern mới)

```md
## [Mã] Tên pattern
**Khi nào dùng:** 1–2 câu.
**Reference apps:** App A, App B (xem category … trên Mobbin).

### Anatomy (ASCII)
┌───────────── zone layout ─────────────┐

### Zones
| Zone | Nội dung | Token / spacing |

### States
- Loading → skeleton …
- Empty → … (`20` §5.9)
- Error → … (retry)
- Success / filled → …

### Editorial Black notes
- Màu/typography lệ thuộc token nào; chỗ nào KHÔNG dùng skill color.

### Build with (Flutter)
- Widget sẵn có: `StudentMobileUi.…`, `AppCard`, …

### Don't
- Anti-pattern cụ thể (vd: chevron trong chat-list; tô nền cả row unread).
```

---

## 5. File map

| File | Nội dung | Trạng thái |
|------|----------|-----------|
| [`README.md`](README.md) | Index, taxonomy, reference apps, cách dùng, template | ✅ |
| [`01-screen-archetypes.md`](01-screen-archetypes.md) | Blueprint 12 archetype màn (A1–A12) | ✅ |
| [`02-flows.md`](02-flows.md) | Onboarding / lesson / exam / chat flows (F1–F4) | ✅ |
| [`03-element-recipes.md`](03-element-recipes.md) | "Mobbin-grade" refinement chồng lên `04` (R1–R12 micro-detail) | ✅ |
| [`04-screen-briefs/`](04-screen-briefs/README.md) | Brief redesign từng màn thật. **6 brief**: Home(A1) · Skill-hub(A2) · Runner(A3) · Messages(A5) · Profile(A9) · Progress(A12) — xem [index](04-screen-briefs/README.md) | ✅ |

---

## 6. Quy ước

- Pattern **map ngược** về `02/04/11` — không định nghĩa token/màu mới.
- Khi áp 1 pattern vào màn thật → ghi vào `11-implementation-mapping.md` "Migration log".
- Bộ này **đồng bộ** với `lib/core/ui/student_mobile_ui.dart` + `lib/core/theme/*`. Lệch → fix theo doc.
- Mọi mockup ASCII chỉ mô tả **bố cục**, không phải pixel; số đo lấy từ `02/03`.
