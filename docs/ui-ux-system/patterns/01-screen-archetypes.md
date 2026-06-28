# 01 — Screen Archetypes (blueprint màn hình)

> Catalog khung layout cho từng *loại* màn mobile học sinh, kiểu Mobbin — **map ngược** về token (`02`), component (`04`) và widget thật (`student_mobile_ui.dart`).
> Mỗi archetype: **khi nào dùng · reference apps · anatomy · zones · states · Editorial-Black notes · build with · don't**.
>
> **Quy ước màu:** màn **kỹ năng học** (hub/runner/detail của listening/reading/…) ĐƯỢC dùng skill color (`AppSkillColors`) cho icon/progress/accent. Màn **phi-kỹ-năng** (home chrome, messages, profile, settings, auth) dùng **primary (Editorial Black)** + neutral. Amber `accent` chỉ cho **celebrate** (streak/KPI nổi/level-up).

Tham chiếu nền: [`02-design-tokens`](../02-design-tokens.md) · [`03-mobile-foundations`](../03-mobile-foundations.md) · [`04-mobile-components`](../04-mobile-components.md) · [`15-mobile-smart-patterns`](../15-mobile-smart-patterns.md) · [`20-student-mobile-audit`](../20-student-mobile-audit-and-standards.md).

---

## A1 · Home / Dashboard

**Khi nào dùng:** màn đầu sau đăng nhập — chào, tóm tắt tiến độ, "tiếp tục học", lối tắt.
**Reference apps:** Duolingo (home gamified), Headway (today + continue), Robinhood (KPI-forward), Cron.

### Anatomy
```
┌──────────────────────────────────────────┐
│  Xin chào, Duy 👋            🔔(badge) 🤖 │  ← greeting row (h1) + header actions
│  Hôm nay học gì nào?                       │  ← subtitle (body, textSecondary)
│ ┌───────┐ ┌───────┐ ┌───────┐             │
│ │🔥 5   │ │⭐ 320 │ │Lv. 3  │             │  ← stat row (statCard compact ×3)
│ └───────┘ └───────┘ └───────┘             │
│ ┌────────────────────────────────────────┐│
│ │ Tiếp tục: Listening · Unit 4    ▸ 60%  ││  ← "Continue" card (skillAccentCard)
│ └────────────────────────────────────────┘│
│  Kỹ năng                                   │  ← sectionHeader
│ ┌──────┐┌──────┐┌──────┐┌──────┐┌──────┐  │
│ │🎧 ││🗣 ││📖 ││✏️ ││🃏 │             │  ← quickActionButton ×5 (skill colors)
│ └──────┘└──────┘└──────┘└──────┘└──────┘  │
└──────────────────────────────────────────┘
```

### Zones
| Zone | Nội dung | Token |
|------|----------|-------|
| Greeting | `greeting()` h1 + `headerIconButton` (notif/AI) | textPrimary; badge `danger` |
| Stats | 3× `statCard(compact)` — streak/points/level | streak→`accentTint`; còn lại neutral |
| Continue | 1 card nổi tiến độ + `skillProgressBar` | skill color của bài dở |
| Skill grid | `quickActionButton` mỗi skill | skill color riêng từng nút |

### States
- **Loading** → skeleton: stat row + 1 continue + grid (`StudentMobileSkeleton`).
- **Empty (user mới)** → ẩn "Continue", grid + CTA "Bắt đầu bài đầu tiên".
- **Error** → `errorBanner` trên cùng, vẫn giữ grid (degrade mềm).

### Build with
`StudentMobileUi.greeting/statCard/quickActionButton/skillProgressBar/sectionHeader`, `skillAccentCard`, `headerIconButton`.

### Don't
- Đừng nhồi quá 3 stat. Đừng dùng amber cho nút (chỉ streak/KPI). Đừng để grid skill cuộn ngang nếu ≤5 (đủ 1 hàng).

---

## A2 · Hub / Browse list (skill hub)

**Khi nào dùng:** danh sách bài trong 1 kỹ năng (Listening/Reading/…), có banner + search + filter.
**Reference apps:** Duolingo (path/units), Quizlet (set list), Linear (list density), Headway (library).

### Anatomy
```
┌──────────────────────────────────────────┐
│  Listening                                 │  ← greeting (tên skill)
│  Luyện nghe theo chủ đề                    │  ← subtitle
│ ┌────────────────────────────────────────┐│
│ │ Mẹo: nghe 2 lần trước khi chép   🎧(box)││  ← skillHubBanner (skill tint)
│ └────────────────────────────────────────┘│
│ [🔍 Tìm bài...                           ] │  ← searchField
│ (Tất cả)(Chưa làm)(Đã xong)                │  ← filterRow (skill color selected)
│  Bài học                              12   │  ← _SectionHeader (count pill)
│ ┌────────────────────────────────────────┐│
│ │🎧 Unit 1 · A2        ●●●○○ 60%   ▸     ││  ← list card (skillAccentCard) + progress
│ ├────────────────────────────────────────┤│
│ │🎧 Unit 2 · A2        ○○○○○ 0%    ▸     ││
│ └────────────────────────────────────────┘│
└──────────────────────────────────────────┘
```

### Zones
| Zone | Nội dung | Token |
|------|----------|-------|
| Header | greeting + subtitle | textPrimary/Secondary |
| Banner | tip/overview + skill icon box | `AppSkillColors.of(skill)` tint |
| Search + filter | searchField + filterRow | filter selected = skill color |
| List | row có icon/title/meta/progress + trailing state | surfaceCard, divider/gap |

### States
- **Loading** → `StudentMobileUi.listLoading()` (skeleton skill list).
- **Empty** → `emptyState(skill: …)` icon skill, CTA tuỳ.
- **Search empty** → `emptyState(icon: search_off)`.
- **Done item** → đổi trailing sang `skillCardReviewButton/RetakeButton`.

### Build with
`skillHubBanner`, `searchField`, `filterRow`, `skillAccentCard` + `skillProgressBar`, `listLoading`, `emptyState`.

### Don't
- Đừng bỏ 1 trong 3 state. Đừng để list không phân trang nếu dài (lazy). Đừng trộn 2 skill color trong 1 row.

---

## A3 · Runner / Focused task (làm bài)

**Khi nào dùng:** môi trường tập trung 1 việc — MCQ, dictation, speaking, exam. Tối giản chrome, 1 CTA chính dưới.
**Reference apps:** Duolingo (1 câu/màn, bottom CTA), Quizlet (flashcard), Headway (reader runner).

### Anatomy
```
┌──────────────────────────────────────────┐
│ ✕            3 / 12              45%        │  ← exit + mcqPagerHeader (progress)
│ ───────────────────────────────────        │  ← thin progress line
│                                            │
│   Nghe và chọn đáp án đúng                 │  ← prompt (h2/h3)
│   [▶︎ audio player ───────────────]        │
│  ┌─────────────────────────────────────┐  │
│  │ A.  option text                      │  │  ← mcqOption (single/multi)
│  ├─────────────────────────────────────┤  │
│  │ B.  option text            ✓/✗(review)││
│  └─────────────────────────────────────┘  │
│                                            │
│ ┌────────────────────────────────────────┐│
│ │ Câu 3/12                    [ Tiếp ▸ ] ││  ← bottomActionBar (sticky)
│ └────────────────────────────────────────┘│
└──────────────────────────────────────────┘
```

### Zones
| Zone | Nội dung | Token |
|------|----------|-------|
| Top bar | `✕` (exit-confirm) + `mcqPagerHeader` | textSecondary; line = skill@55% |
| Body | prompt + media + `mcqOption`(s) | option selected `infoBg`; correct `successBg`; wrong `dangerBg` |
| Bottom CTA | `bottomActionBar` progress + primary button | button = primary (đen) |

### States
- **In-progress** → `runnerPopScope(blockExit:true)` chặn thoát + confirm (`20` §5.8).
- **Loading** → `runnerLoading()`.
- **Review** → mcqOption `showReviewCorrect/Wrong`.
- **Submit** → CTA loading spinner; xong → A11 (result).

### Build with
`mcqPagerHeader`, `mcqQuestionPager`, `mcqOption`, `bottomActionBar`, `runnerPopScope`, `confirmRunnerExit`.

### Don't
- Đừng để nhiều CTA cạnh tranh. Đừng cho thoát không confirm khi đang làm. Đừng tô đáp án bằng skill color (dùng semantic info/success/danger).

---

## A4 · Detail / Reader

**Khi nào dùng:** đọc nội dung dài (bài đọc, transcript, giải thích, review chi tiết).
**Reference apps:** Headway/Blinkist (reader), Matter, Notion (doc), iOS Books.

### Anatomy
```
┌──────────────────────────────────────────┐
│ ‹ Back          Tiêu đề bài        ⋯/🔖   │  ← skillAppBar (accent line)
│  Chủ đề · A2 · 8 phút                      │  ← meta row (caption, textMuted)
│                                            │
│  Heading                                   │  ← h2
│  Body văn bản dài, line-height thoáng,     │  ← body, maxWidth đọc tốt
│  đoạn cách s4…                             │
│  ┌──────────────────────────────────────┐ │
│  │ 💡 Từ vựng / chú thích inline         │ │  ← callout card (surfaceSubtle)
│  └──────────────────────────────────────┘ │
│ ┌────────────────────────────────────────┐│
│ │              [ Làm bài tập ▸ ]          ││  ← bottom CTA (nếu có)
│ └────────────────────────────────────────┘│
└──────────────────────────────────────────┘
```

### Zones / notes
- Header `skillAppBar` (accent line 2px theo skill). Meta = caption/textMuted.
- Thân: typography-forward, đoạn cách `s4`, callout = `surfaceSubtle` + outline.
- CTA dưới chỉ khi có hành động tiếp (làm bài/đánh dấu xong).

### States
Loading skeleton dòng văn bản · Error `errorRetry` · (không có "empty" — detail luôn có nội dung).

### Build with
`StudentMobileUi.skillAppBar`, `sectionTitle/body/caption`, `AppCard` callout, `bottomActionBar`.

### Don't
- Đừng bo full-width chữ sát mép (giữ padding đọc). Đừng dùng card lồng card nhiều tầng.

---

## A5 · Conversation list (Messages)

**Khi nào dùng:** danh sách hội thoại/nhóm lớp. **Phi-kỹ-năng → primary, KHÔNG skill color.**
**Reference apps:** Messenger, Telegram, Slack, WhatsApp, iMessage.

### Anatomy
```
┌──────────────────────────────────────────┐
│  Messages                                  │  ← greeting (primary)
│  Nhóm chat các lớp                         │
│ ┌────────────────────────────────────────┐│
│ │ Kết nối với lớp           💬(box đen)   ││  ← banner (neutral + icon primary)
│ └────────────────────────────────────────┘│
│ [🔍 Tìm lớp...                           ] │
│ (Tất cả)(Chưa đọc)                         │  ← filter (primary selected)
│  Cuộc trò chuyện                      1    │  ← section (pill primary)
│ ───────────────────────────────────────── │
│ (A) 10A1 — Ca sáng        12:30           │  ← ConversationTile (flat row)
│     Cô Lan: Nộp bài…           ● 3        │     unread: tên w700, time/badge primary
│ ───────────────────────────────────────── │  ← divider inset (sau avatar)
└──────────────────────────────────────────┘
```

### Zones / rule (theo `23`)
- **Inset grouped card** (chuẩn 06/2026): cả list trong 1 thẻ bo tròn (`surfaceCard`, radius `card+2`, shadow 2 lớp `shadowCard`+`shadowAmbient`, `ClipRRect`), divider **inset** giữa hàng. *(Override "hàng phẳng" của doc 23 — row internals giữ nguyên.)*
- Avatar **màu-theo-tên** (identity hash) khi không ảnh — không icon xám.
- Time **căn phải** ngang tên; preview hàng 2; unread = **đậm + badge pill primary**; **KHÔNG chevron**.
- Banner/filter/section = **primary** (đã sửa 06/2026), không emerald.

### States
Loading → `ConversationTileSkeleton` ×5 · Empty → `emptyState(forum)` · Search empty → `search_off`.

### Build with
`ConversationTile`, `ConversationTileSkeleton`, `skillHubBanner`(skill:null), `searchField`, `filterRow`(skill:null).

### Don't
- Đừng tô nền cả row unread. Đừng dùng skill/emerald. Đừng thêm chevron.

---

## A6 · Chat thread

**Khi nào dùng:** màn nhắn tin trong 1 nhóm lớp.
**Reference apps:** Telegram, Messenger, Slack thread.

### Anatomy
```
┌──────────────────────────────────────────┐
│ ‹ (avatar) 10A1 — Ca sáng        ⌄        │  ← ClassroomChatHeader (tap→settings)
│            32 thành viên · Nhóm lớp        │
│ ─────────────────────────────────────────│
│        ── Hôm nay ──                       │  ← date separator
│  (av) Cô Lan                               │  ← teacher highlight
│       ┌─────────────────────┐             │  ← bubble (in) surfaceCard/subtle
│       │ Các em nộp bài nhé   │             │
│       └─────────────────────┘ 12:30        │
│                      ┌────────────────┐    │  ← bubble (me) primary tint/đen
│                      │ Dạ vâng ạ       │    │
│              12:31 ✓✓└────────────────┘    │
│ ─────────────────────────────────────────│
│ [+] [ Nhập tin nhắn…            ] [ ↑ ]    │  ← ChatInputBar (composer)
└──────────────────────────────────────────┘
```

### Zones / rule (theo `22`)
- **`reverse: true` list** — tin mới ở đáy, không jumpTo/anchor.
- Bubble: nhận = `surfaceCard` + viền `outline`; gửi = `primary`; GV = `accentTint` + viền accent. Nhóm theo người gửi (tail/avatar chỉ ở last-in-group); date separator đầu ngày; timestamp dưới bubble; `RepaintBoundary` mỗi bubble; ảnh cố định kích thước.
- Header dùng cover avatar + subtitle sĩ số; tap mở settings sheet.
- Composer: `+` đính kèm, ô đa dòng, nút gửi tròn **primary**; reply preview + attachment strip phía trên.

### States
Loading lịch sử (skeleton bubble) · Empty (nhóm mới) · Sending/optimistic · Upload progress.

### Build with
`ClassroomChatHeader`, `ClassroomChatBody`(reverse), `chat_message_bubble`, `ChatInputBar`, `ChatReplyPreview`, `AppFeedback`.

### Don't
- Đừng forward-list + tự cuộn đáy (gây flash/giật — xem `22`). Đừng để send button không phải primary.

---

## A7 · Search & Filter

**Khi nào dùng:** lọc/tìm trong hub hoặc messages. Thường **nhúng** trong A2/A5, không phải màn riêng.
**Reference apps:** Linear (filter chips), Things (search), iOS search bar.

### Pattern
```
[🔍 Tìm…                          ✕]   ← searchField, clear khi có query
(Tất cả)(Chưa làm)(Đã xong)            ← filterRow cuộn ngang, 1 chọn
```
- Search **debounce** ~250ms; clear button khi có text.
- Filter chip **1 selected**; selected màu skill (A2) hoặc primary (A5).
- Kết quả rỗng → `emptyState(icon: search_off, title/body "không tìm thấy")`.

### Build with
`StudentMobileUi.searchField` + `filterRow` + `_filteredRooms`-style memo (cache theo `(data, query, filter)` như hub).

### Don't
- Đừng filter rebuild cả trang mỗi tick (memo + `ListenableBuilder`). Đừng nhiều filter cùng-selected mơ hồ.

---

## A8 · Empty / Loading / Error (3 state bắt buộc)

**Khi nào dùng:** MỌI màn fetch data. Đây là "công dân hạng nhất", không phải afterthought.
**Reference apps:** Linear (empty tinh tế), Headway (skeleton), iOS (graceful error).

### Patterns
```
LOADING (skeleton khung giống nội dung thật):
 ▭▭▭   ▭▭▭▭▭▭▭▭            EMPTY:                 ERROR:
 ▭▭▭   ▭▭▭▭▭▭                  (icon tròn)            ☁️ (cloud-off)
 ▭▭▭   ▭▭▭▭▭▭▭▭▭             Tiêu đề ngắn            Tiêu đề
                            Mô tả 1 dòng            Mô tả lỗi
                            [ CTA (tùy) ]           [ ↻ Thử lại ]
```

### Rule (theo `20` §5.4/5.9)
- **Loading = skeleton khung giống thật**, KHÔNG spinner full-màn (trừ chỗ rất nhỏ).
- **Empty** = icon (skill nếu skill-screen, neutral nếu không) + title + body + CTA tùy. Dùng `emptyState`.
- **Error** = `errorRetry`/`errorBanner` + nút **Thử lại** (có haptic confirm).
- Empty do search ≠ empty do chưa-có-data (icon + copy khác nhau).

### Build with
`StudentMobileSkeleton.*`, `StudentMobileUi.emptyState/errorRetry/errorBanner/listLoading/runnerLoading`.

### Don't
- Đừng để màn trắng khi loading. Đừng nuốt lỗi im lặng (luôn có retry). Đừng dùng spinner thay skeleton.

---

## A9 · Profile / Settings

**Khi nào dùng:** hồ sơ, cài đặt tài khoản, mục tiêu/nhắc nhở, đăng xuất.
**Reference apps:** Notion, Things, iOS Settings (grouped), Headway profile.

### Anatomy
```
┌──────────────────────────────────────────┐
│        (avatar lớn)                        │
│        Phan Tất Duy                        │  ← h2
│        duy@…  ·  Lv. 3                      │  ← caption/textMuted
│  ─ Tài khoản ──────────────────────────── │  ← group header (caption uppercase)
│  Chỉnh sửa hồ sơ                      ›    │  ← listTile (chevron OK ở settings)
│  Mục tiêu học · 5 bài/ngày            ›    │
│  Nhắc nhở · 20:00                     ›    │
│  ─ Khác ─────────────────────────────────│
│  Ngôn ngữ · Tiếng Việt                ›    │
│  Đăng xuất                            (đỏ) │  ← destructive
└──────────────────────────────────────────┘
```

### Notes
- **Grouped list** (iOS-style): group header caption, row `listTile` (chevron HỢP LỆ ở settings — khác chat-list).
- Destructive (Đăng xuất/Xoá) = `danger`, có confirm dialog.
- Sửa giá trị → `StudentBottomSheet`/`StudentDialogShell`.

### Build with
`StudentMobileUi.listTile`, `roundIconBox`, `StudentDialogShell`, `StudentBottomSheet`, `AppCard(outline)`.

### Don't
- Đừng để destructive không confirm. Đừng tô skill color ở profile (primary/neutral).

---

## A10 · Auth / Onboarding

**Khi nào dùng:** login, register, OTP, thiết lập mục tiêu/level lần đầu.
**Reference apps:** Duolingo onboarding (progress + 1 câu hỏi/màn), Headway intake, Linear auth (tối giản).

### Anatomy
```
LOGIN                          ONBOARDING STEP
┌──────────────────┐          ┌──────────────────┐
│   (logo đen)      │          │ ──────●○○○        │  ← progress dots/bar
│   Đăng nhập       │          │ Mục tiêu của bạn? │
│ [Email          ] │          │ ( ) Giao tiếp     │  ← chọn 1 (mcqOption-like)
│ [Mật khẩu     👁 ]│          │ ( ) Thi cử        │
│ [ Đăng nhập     ] │          │ ( ) Công việc     │
│ Quên mật khẩu?    │          │ ┌──────────────┐  │
│ ──── hoặc ────    │          │ │  [ Tiếp ▸ ]  │  │  ← bottom CTA
│ [G] Google        │          │ └──────────────┘  │
│ Chưa có tài khoản?│          └──────────────────┘
└──────────────────┘
```

### Notes
- Onboarding = **1 quyết định/màn** + progress + bottom CTA (như runner A3).
- Auth: input có inline-validate, error dưới field; primary button đen; social phụ.
- OTP: 4–6 ô, auto-advance, resend countdown.

### Build with
`FilledButton`(primary), input `04` §4, `mcqOption` cho lựa chọn onboarding, `bottomActionBar`.

### Don't
- Đừng hỏi nhiều thứ 1 màn. Đừng để lỗi auth dạng dialog chặn (inline tốt hơn).

---

## A11 · Result / Celebrate

**Khi nào dùng:** xong bài/exam, streak mới, level-up. **Chỗ DUY NHẤT amber được "khoe".**
**Reference apps:** Duolingo (lesson complete), Headway (finish), Robinhood (milestone).

### Anatomy
```
┌──────────────────────────────────────────┐
│            🎉 (lottie/celebrate)           │  ← celebrate motion (reduce-motion safe)
│            Hoàn thành!                      │  ← h1
│            8/10 đúng · +40 ⭐               │  ← KPI nổi (amber accent)
│ ┌───────┐ ┌───────┐ ┌───────┐             │
│ │ Đúng  │ │ Sai   │ │ Thời gian│           │  ← statCard kết quả
│ └───────┘ └───────┘ └───────┘             │
│  🔥 Streak 6 ngày!                         │  ← streakChip (amber)
│ ┌────────────────────────────────────────┐│
│ │ [ Xem lại ]            [ Bài tiếp ▸ ]   ││  ← 2 CTA: review (outline) + next (primary)
│ └────────────────────────────────────────┘│
└──────────────────────────────────────────┘
```

### Notes
- **Amber** dùng cho điểm/streak/KPI nổi — đây là ngoại lệ "ăn mừng" của Editorial Black.
- Motion: celebrate có, nhưng **reduce-motion** → fallback tĩnh (`20`).
- 2 CTA: primary = bước tiếp; outline = xem lại.

### Build with
`AppLottieView`/celebrate, `statCard`, `streakChip`, `skillCardReviewButton` + `FilledButton`.

### Don't
- Đừng celebrate quá dài chặn người dùng. Đừng dùng amber ở chỗ không phải thành tựu.

---

## A12 · Stats / Progress

**Khi nào dùng:** trang tiến độ — biểu đồ tuần, tổng quan kỹ năng, lịch sử.
**Reference apps:** Robinhood (chart), Copilot (stats), Duolingo (progress), Headway.

### Anatomy
```
┌──────────────────────────────────────────┐
│  Tiến độ                                   │  ← greeting
│ ┌───────┐ ┌───────┐ ┌───────┐             │  ← KPI row (statCard)
│ │ 5 🔥  │ │ 320 ⭐│ │ 12 bài │            │
│ └───────┘ └───────┘ └───────┘             │
│  Hoạt động tuần này                        │  ← sectionHeader
│ ┌────────────────────────────────────────┐│
│ │  ▁ ▃ ▅ ▂ ▇ ▄ ▁     (bar chart 7 ngày) ││  ← weekly_activity_bars_chart
│ └────────────────────────────────────────┘│
│  Theo kỹ năng                              │
│  🎧 Listening   ●●●●○ 78%                  │  ← skillProgressBar mỗi skill
│  📖 Reading     ●●○○○ 40%                  │
└──────────────────────────────────────────┘
```

### Notes
- KPI số to (`kpi()` style), amber cho điểm nổi/streak.
- Chart: bar tuần dùng `fl_chart`; highlight cột hôm nay bằng accent.
- Per-skill progress = `skillProgressBar(skill: …)` (skill color hợp lệ ở đây).

### Build with
`statCard`, `weekly_activity_bars_chart.dart`, `skillProgressBar`, `sectionHeader`.

### Don't
- Đừng quá nhiều chart 1 màn. Đừng tô toàn biểu đồ bằng nhiều skill color (1 highlight thôi).

---

## Bảng tra nhanh archetype → màn E4C → file code

| Archetype | Màn thật | File |
|-----------|----------|------|
| A1 Home | Home học sinh | `feature/home/home_page.dart` |
| A2 Hub | Skill hubs | `feature/{listening,reading,speaking,…}` list pages |
| A3 Runner | MCQ/dictation/exam | runner pages, `mcq*` |
| A4 Detail | Reader/review | reading/listening detail |
| A5 Conv list | Messages | `feature/student/messages/student_classroom_chat_hub_page.dart` |
| A6 Chat | Chat lớp | `feature/classroom_chat/classroom_chat_page.dart` |
| A7 Search | (nhúng A2/A5) | `searchField`/`filterRow` |
| A8 States | mọi màn | `StudentMobileUi.emptyState/errorRetry`, skeletons |
| A9 Profile | Profile/Settings | `feature/profile/*` |
| A10 Auth | Login/onboarding | `feature/auth/*` |
| A11 Result | Kết quả/celebrate | result pages |
| A12 Stats | Tiến độ | `feature/progress/progress_report_page.dart` |

> Khi áp 1 archetype vào màn → ghi commit vào [`../11-implementation-mapping.md`](../11-implementation-mapping.md).
