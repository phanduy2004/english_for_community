# Screen Brief — Home / Dashboard (student)

> Áp blueprint **A1 · Home / Dashboard** ([`../01-screen-archetypes.md`](../01-screen-archetypes.md)) vào màn thật.
> **Màn:** tab Home học sinh · **File:** `lib/feature/home/home_page.dart` (`_HomeContentView`) + `lib/feature/home/widgets/home_study_dashboard.dart`.
> **Trạng thái:** chrome đã primary/neutral (Editorial Black), amber chỉ ở streak/points/chart highlight (`home_page.dart:591`,`602`; `home_study_dashboard.dart`). Brief này lo **nhịp dọc & thứ tự khối** — màn hiện **6 khối dọc liên tiếp** (goal + chart + stats + lessons + grid) ⇒ scroll dài, lặp số liệu (daily goal hiện **3 lần**).

---

## 1. Hiện trạng (đo theo token)

```
┌──────────────────────────────────────────┐  pagePadding = LTRB(12,10,12,20)  [student_mobile_ui.dart:31]
│ Xin chào, Duy          🔔  🤖  (avatar)   │  _buildHeader Row  [home_page.dart:489]
│ Hôm nay học gì nào?                         │   greeting h1 + subtitle  (↕ s3 :502)
│   ↕ s4  [home_page.dart:452]                │
│ ┌────────────────────────────────────────┐│
│ │ Mục tiêu hôm nay            🏆(amber)   ││  _buildDailyGoalCard  [home_page.dart:541]
│ │ 2 / 5 bài                               ││   AppCard.outline · ↕ s3 · skillProgressBar h6
│ └────────────────────────────────────────┘│
│   ↕ s5  [home_page.dart:454]                │
│ ┌────────────────────────────────────────┐│
│ │ Hoạt động tuần  [🔥3]   2/5 bài         ││  HomeStudyDashboard → _ChartCard
│ │ ▁▃▅▂▇▄▁  (bar chart 120dp)              ││   [home_study_dashboard.dart:102]
│ │                       Thống kê đầy đủ ▸ ││   neutral outline card + progressBar
│ └────────────────────────────────────────┘│
│   ↕ s5  [home_page.dart:460]                │
│ ┌──────┐ ┌──────┐ ┌──────┐                 │
│ │🔥 3  │ │⭐ 320│ │Lv.3  │                 │  _buildStatsRow  [home_page.dart:580]
│ └──────┘ └──────┘ └──────┘                 │   statCard compact ×3 (streak/points amber)
│   ↕ sectionGap(14)  [home_page.dart:462]    │
│ Bài học hôm nay              Xem tất cả     │  sectionHeader  [home_page.dart:632]
│   ↕ s4                                       │
│ ┃🎧 Listening …                       ▸    │  _LessonCard skillAccentCard ×3..5
│ ┃📖 Reading …                         ▸    │   (emphasized listening) [home_page.dart:646]
│ ┃🃏 Vocabulary …                      ▸    │
│   ↕ sectionGap(14)  [home_page.dart:464]    │
│ Truy cập nhanh                              │  _buildQuickActionsSection [home_page.dart:695]
│ (♥)(🃏) (📊)(🕘) (🏫)(🌐)                   │  GridView 2col ×6, aspect 1.85 (:707)
└──────────────────────────────────────────┘
```

**Đo:** từ đỉnh tới hàng stats: header + `s4` + **goal card** + `s5` + **chart card (~220dp)** + `s5` + stats. → **3 khối "tiến độ"** liên tiếp trước khi tới list bài. Daily-goal (`progress/goal`) render **3 lần**: goal card (`:563`), chart subtitle (`home_study_dashboard.dart:132`), progress bar trong chart (`:143`). Streak render **3 lần**: chart chip (`:138`), stat card (`:589`), celebrate host (`:434`).

### Đánh giá
| ✅ Giữ | ⚠️ Sửa |
|--------|--------|
| Header A1 chuẩn: greeting + `headerIconButton` notif/AI + avatar tap (`home_page.dart:489`–`536`) | **Daily goal lặp 3 nơi** (goal card `:563`, chart `home_study_dashboard.dart:132`, progress bar `:143`) — chrome thừa |
| Màu đúng rule: chrome neutral, amber chỉ streak/points/chart (`:591`,`602`,`611` primary) | **Streak hiển thị 3 lần** (stat card `:589` + chart chip `:138` + celebrate) |
| Stats ≤3 (đúng "Đừng nhồi >3 stat" A1) (`home_page.dart:580`) | **Goal card + chart card** cạnh nhau ⇒ 2 progress bar liền kề, chart ~220dp đẩy list bài xuống quá sâu |
| skill color đúng chỗ: lesson cards + quick grid dùng `SkillType` (`:646`,`713`) | A1 đặt stats **trên** "Continue/Tiến độ"; hiện stats nằm **dưới** chart (`:455`→`:461`) — thứ tự ngược blueprint |
| 3 state đủ: skeleton/error/empty (`:386`–`477`) | "Continue học tiếp" (A1 cốt lõi) **thiếu** — lesson cards là slot tĩnh, không phải bài-đang-dở |
| Loading skeleton riêng (`HomeContentSkeleton` `app_skeleton.dart:153`) + RefreshIndicator (`:421`) | Quick grid **6 nút** (`:708`) — 2 nút amber (`:741`) cạnh skill color, dày hơn "1 hàng ≤5" của A1 |

---

## 2. Target layout (refined)

Theo A1: **stats lên trên Continue**, gộp tiến độ về **1 khối** (đừng 2 card progress cạnh nhau), thêm **"Continue"** thật, để list bài + grid lên sớm hơn.

```
TRƯỚC (3 khối tiến độ chồng)            SAU (A1-forward: stats → continue → list)
┌───────────────────────────┐         ┌───────────────────────────┐
│ Xin chào, Duy  🔔 🤖 (av)  │         │ Xin chào, Duy  🔔 🤖 (av)  │  header (giữ)
│ Hôm nay học gì nào?        │         │ Hôm nay học gì nào?        │
│ ┌ Mục tiêu hôm nay 🏆 ──┐ │         │ ┌🔥3┐┌⭐320┐┌Lv.3┐         │  stats lên TRƯỚC (≤3)
│ │ 2/5 bài  ▁▃ bar       │ │         │ ┌── Tuần này [🔥3] ─────┐ │  1 card tiến độ gộp:
│ └───────────────────────┘ │         │ │ 2/5 bài · ▁▃▅▂▇ chart  │ │   goal+streak+chart 1 chỗ
│ ┌ Tuần này [🔥3] chart ─┐ │         │ │            Thống kê ▸  │ │   (bỏ goal card rời)
│ │ 2/5 bài  ▁▃▅ bar       │ │         │ └───────────────────────┘ │
│ │           Thống kê ▸   │ │         │ Tiếp tục học               │  Continue (skillAccentCard
│ └───────────────────────┘ │         │ ┃🎧 Listening · dở   ▸60% │   emphasized) — bài đang dở
│ ┌🔥3┐┌⭐320┐┌Lv.3┐        │         │ Kỹ năng hôm nay   Xem all  │  sectionHeader
│ Bài học hôm nay  Xem all   │         │ ┃📖 Reading …        ▸    │  list bài lên sớm
│ ┃🎧 ┃📖 ┃🃏 …              │         │ ┃🃏 Vocabulary …     ▸    │
│ Truy cập nhanh             │         │ Truy cập nhanh             │
│ (6 nút grid)               │         │ (≤5 nút grid)              │  gọn về 1 ý
└───────────────────────────┘         └───────────────────────────┘
                                       ↳ tiết kiệm ~140dp: bỏ 1 card progress + 1 progress bar trùng
```

### Zones (target)
| Zone | Nội dung | Token | Ghi chú |
|------|----------|-------|---------|
| Header | `greeting()` h1 + subtitle + `headerIconButton`(notif/AI) + avatar tap | textPrimary/Secondary; badge `danger`; AI btn primary | giữ nguyên `_buildHeader` (`home_page.dart:489`) — đã đúng A1 |
| Stats | 3× `statCard(compact)` streak/points/level | streak+points→`accent`/`accentTint`; level→`primary`/`primaryTint` | **chuyển lên ngay sau header** (đúng thứ tự A1) |
| Progress | **1** card gộp = `HomeStudyDashboard` (chart + goal line + streak chip) | neutral outline card, chart `chartBar` (đen), today highlight `chartHighlight` | **bỏ `_buildDailyGoalCard` rời** — daily-goal đã có trong chart subtitle (`home_study_dashboard.dart:132`) + bar (`:143`) |
| Continue | 1× `skillAccentCard(emphasized:true)` bài-đang-dở + `skillProgressBar(skill:)` | skill color của bài dở | A1 "Continue" — thay slot listening tĩnh `emphasized` bằng bài thực sự dở (nếu có data) |
| Lessons | `sectionHeader` + `skillAccentCard` ×3 (mở rộng ×5 qua "Xem tất cả") | surfaceCard + viền skill trái | giữ `_buildLessonsSection` (`home_page.dart:625`); spacing `cardGap` giữa card |
| Quick grid | `quickActionButton` ×≤5 | skill color/ amber (My Classes) | gộp/cắt còn ≤5 để hợp "1 hàng" A1; `childAspectRatio 1.85` (`:707`) giữ |

> **Rule màu (A1):** chrome (greeting/stats/grid label, card border) = primary/neutral; lesson cards + quick grid icon = **skill color**; amber **chỉ** ở streak/points/level-amber-stat + chart highlight. Đừng đổi amber sang nút hoặc viền card.

---

## 3. Build diff (đường dẫn cụ thể cho Cursor)

File: `home_page.dart`, `_HomeContentView._homeBodyForState()` — Column con của `SingleChildScrollView` (`home_page.dart:440`–`467`).

1. **Đổi thứ tự: stats lên trên tiến độ.** Trong Column (`:442`–`466`), di chuyển `_buildStatsRow(...)` (`:461`) lên **ngay sau** `_buildHeader(...)` (kết thúc `:451`). Spacing: header → `SizedBox(s4)` → `_buildStatsRow` → `SizedBox(s5)` → `HomeStudyDashboard`.
2. **Bỏ `_buildDailyGoalCard` rời** (`:453` gọi; định nghĩa `:541`–`578`). Daily-goal đã hiển thị trong `HomeStudyDashboard` (subtitle `home_study_dashboard.dart:132` + `skillProgressBar` `:143`). Xoá luôn `SizedBox(height: s4)` ở `:452`. → giảm 1 card + 1 progress bar trùng.
3. **Thêm "Continue" (A1 cốt lõi).** Sau `HomeStudyDashboard` (+`s5`), nếu có bài-đang-dở thì render 1 `_LessonCard(emphasized:true)` (hoặc `StudentMobileUi.skillAccentCard` + `skillProgressBar(skill:…, value:…)`) cho bài đó; nếu **không** có ⇒ ẩn (đừng dựng card trống — theo A1 "Empty: ẩn Continue"). Hiện code chỉ có slot tĩnh listening `emphasized:true` (`:651`) — tách nó thành block Continue có điều kiện thay vì luôn-bật.
4. **Quick grid về ≤5 nút.** `_buildQuickActionsSection` (`:701`) đang dựng 6 `quickActionButton` (`:709`–`751`). Gộp/bỏ 1 (vd "Public exam" `:745` trùng route My Classes `:743`,`:750`) để còn ≤5 — đúng "Đừng để grid skill cuộn ngang nếu ≤5" của A1.
5. **Spacing mới (gọn):** header → `s4` → stats → `s5` → progress card → `s5` → [Continue → `sectionGap`] → lessons section → `sectionGap` → quick grid. (Giữ token hiện có: `s4`/`s5`/`sectionGap`/`cardGap` — đừng px thô.)
6. Giữ nguyên: `_buildHeader` (`:480`), `_LessonCard`/`skillAccentCard` (`:761`), `HomeStudyDashboard` (chart đã đúng màu), `RefreshIndicator` (`:421`), `GamificationCelebrateHost` (`:433`).

> Không đụng `student_mobile_ui.dart` / `app_card.dart` (shared). Không đổi `home_study_dashboard.dart` về màu (amber/chart đúng rule). Daily-goal **chỉ** còn 1 nguồn = chart.

---

## 4. States (đã có — kiểm lại)
- **Loading** → `HomeContentSkeleton` (`home_page.dart:387`, def `app_skeleton.dart:153`) ✔ — khung giống thật, không spinner. Chart con có `WeeklyStudyChartSkeleton` riêng (`home_study_dashboard.dart:44`) ✔.
- **Empty (user mới / 0 data)** → hiện rơi vào `homeNoData` text center (`home_page.dart:475`) — **thiếu** empty-state A1 ("ẩn Continue + CTA Bắt đầu bài đầu tiên"). Chart có `_emptyCard` "noStudyWeek" (`home_study_dashboard.dart:187`) ✔ nhưng goal/Continue chưa có empty riêng. **Bổ sung:** khi `dailyProgress==0 && no continue` → ẩn Continue, giữ grid + nhấn 1 lesson card đầu (degrade mềm).
- **Error** → `SoftErrorBanner` + retry `GetProfileEvent` (`home_page.dart:393`, def `animated_status_container.dart:41`) ✔; chart lỗi → `StudentMobileUi.errorBanner` + retry (`home_study_dashboard.dart:46`) ✔ — degrade mềm (grid vẫn còn nếu chỉ chart lỗi).
- **Unauthenticated** → text "please sign in" (`home_page.dart:400`) ✔.

## 5. Checklist
- [ ] Stats chuyển lên **trên** card tiến độ (đúng thứ tự A1).
- [ ] Bỏ `_buildDailyGoalCard` rời — daily-goal chỉ còn trong chart (hết lặp 3 nơi).
- [ ] Thêm block **Continue** có điều kiện (bài-đang-dở `emphasized`); ẩn khi không có.
- [ ] Quick grid về **≤5 nút** (1 hàng, hết trùng route).
- [ ] Màu giữ rule: chrome neutral, amber chỉ streak/points/level/chart; lesson+grid = skill color (0 amber-nút).
- [ ] Empty user-mới: ẩn Continue, giữ grid + CTA, không màn trắng.
- [ ] `dart analyze lib/feature/home` 0 lỗi mới.
- [ ] Xem trên 360×640: list bài lên cao hơn ≥ ~140dp; không còn 2 progress bar cạnh nhau.

> Áp xong ghi vào [`../../11-implementation-mapping.md`](../../11-implementation-mapping.md) "Migration log".
