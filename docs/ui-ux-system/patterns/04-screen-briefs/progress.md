# Screen Brief — Progress / Stats (student)

> Áp blueprint **A12 · Stats / Progress** ([`../01-screen-archetypes.md`](../01-screen-archetypes.md)) vào màn thật.
> **Màn:** Tiến độ học sinh · **File:** `lib/feature/progress/progress_report_page.dart` + chart `feature/progress/widgets/weekly_activity_bars_chart.dart`.
> **Trạng thái:** màu đã Editorial-Black (chart `chartBar` đen, highlight `chartHighlight` amber). Brief này lo **thứ tự & nhịp dọc** — đưa KPI/streak lên đầu (A12 đặt KPI row trước), tách "celebrate amber" khỏi "skill color", và thêm **empty (no activity)** đang thiếu.

---

## 1. Hiện trạng (đo theo token)

```
┌──────────────────────────────────────────┐  appBar (StudentMobileUi.appBar) + flag action
│  Tiến độ học tập                    🚩      │  appBar title (h2)              :227–237
│  Tổng quan                                 │  sectionHeader(progressOverview) :311
│   ↕ s1                                      │
│  Các chỉ số hiệu suất               (body) │  Text(performanceMetrics)        :313
│   ↕ s3                                      │
│ (Ngày)(Tuần)(Tháng)                        │  filterRow (range, skill:null)   :315
│   ↕ s4                                      │
│ ┌────────────────────────────────────────┐│  AppCard(outline) — study time   :322
│ │ Tuần này                    ⏱(box 36)  ││   cardTitle + skillIconBox       :334,346
│ │ 5h 30m                       (kpi to)   ││   kpi()                          :339–342
│ │ ███████░░░░░  (bar 6dp, accent amber)   ││   skillProgressBar color:accent  :350–357
│ │ Mục tiêu 10h          55% hoàn thành    ││   goal/percent caption           :360–372
│ └────────────────────────────────────────┘│
│   ↕ s4                                      │
│  Thống kê chi tiết                  (h2)   │  Text(detailedStats) sectionTitle:378
│   ↕ s3                                      │
│ ┌─────┐┌─────┐┌─────┐                      │  GridView 3 cột, ratio 1.12      :380–430
│ │🃏 50 ││📖78%││🎧80%│   _StatBox skill col ││   skillIconBox(skill:)+kpi value :388–428
│ │ Từ  ││Đọc ││Nghe │                       │   (rainbow 6 skill — xem Đánh giá)
│ │📝 12││✏️7.5││🗣75%│                       │
│ └─────┘└─────┘└─────┘                      │
│   ↕ s4                                      │
│  Bảng xếp hạng                      (h2)   │  sectionHeader(leaderboard)      :433
│ ┌────────────────────────────────────────┐│  AppCard(outline) _LeaderRow     :435–439
│ │ #1 (av) Duy …                 320 XP    ││   #1 rank=accent amber           :587–592
│ └────────────────────────────────────────┘│
│   ↕ s4                                      │
│ ┌────────────────────────────────────────┐│  AppCard — weekly activity       :442
│ │ Hoạt động              📊                ││   sectionTitle + bar_chart icon  :450
│ │  ▁ ▃ ▅ ▂ ▇ ▄ ▮(amber)   (h=120)         ││   WeeklyActivityBarsChart        :455–463
│ └────────────────────────────────────────┘│   highlight cột cuối = chartHighlight
│   ↕ s4                                      │
│ ┌────────────────────────────────────────┐│  AppCard callout (success)       :469–492
│ │ 🎉 Title              ›                  ││
│ └────────────────────────────────────────┘│
│   ↕ s5                                      │
└──────────────────────────────────────────┘  pagePadding = LTRB(12,10,12,20)  :307
```

**Đo:** KPI thật (streak/points/level — A12 muốn "KPI row" lên đầu) **không có** ở đầu màn; thay vào là **2 dòng tiêu đề** (`sectionHeader` "Tổng quan" + body "Các chỉ số hiệu suất") rồi filter rồi card study-time. → người dùng phải cuộn để thấy điểm/streak (đang nằm trong leaderboard + grid). Chart hoạt động (signature của A12) **nằm gần cuối** màn, sau cả grid + leaderboard.

### Đánh giá
| ✅ Giữ | ⚠️ Sửa |
|--------|--------|
| Chart `chartBar` đen + 1 highlight `chartHighlight` amber, cột cuối (đúng A12 "1 highlight") `progress_report_page.dart:457–462` + `weekly_activity_bars_chart.dart:127–130` | **Không có KPI row đầu màn**: A12 mở bằng statCard streak/points/level; ở đây phải cuộn `:311–313` |
| `kpi()` cho số to study-time + _StatBox `:341, :677` | **Amber dùng cho goal-progress thường** `skillProgressBar(color: AppColors.accent)` `:355` — đây là tiến-độ-mục-tiêu (không phải "today highlight"), nên là 1 chỗ amber gây nhiễu với chart-highlight |
| Per-skill icon dùng skill color qua `skillIconBox(skill:)` (hợp lệ A12) `:388–428` | **Rainbow grid**: 6 ô, 5 skill color cạnh nhau → ngược "1 highlight thôi"; nên giữ skill color cho icon nhưng đừng để cả lưới đua màu |
| Chart card có nhãn + trục + trend line `weekly_activity_bars_chart.dart` | **Thứ tự A12 lệch**: chart (signature) ở gần cuối, sau grid + leaderboard `:442` |
| Loading skeleton + error banner `:242, :262` | **Thiếu empty "chưa có hoạt động"**: chart 0 phút vẫn vẽ lưới trống, không có copy hướng dẫn |
| `_StatBox` tap → `StatDetailDialog` (drill-down tốt) `:393` | **2 dòng chrome đầu** (`sectionHeader`+body) đẩy nội dung xuống, lặp ý "tổng quan/chỉ số" |

---

## 2. Target layout (refined) — KPI lên đầu, chart lên sớm, 1 amber

Theo A12 + Robinhood/Copilot (KPI-forward, chart sớm). **Mở bằng KPI row** (streak/points/level) → filter → **chart tuần** (signature) → study-time → grid skill → leaderboard. Amber chỉ ở **streak KPI + cột hôm nay**; goal-bar đổi sang non-amber.

```
TRƯỚC (title-heavy, chart cuối)        SAU (KPI-forward, chart sớm)
┌───────────────────────────┐        ┌───────────────────────────┐
│ Tổng quan          (h2)    │        │ Tiến độ              (h1)   │  greeting 1 dòng
│ Các chỉ số hiệu suất       │        │ ┌────┐┌────┐┌────┐         │  KPI row: statCard ×3
│ (Ngày)(Tuần)(Tháng)        │        │ │5 🔥││320⭐││Lv3 │         │  streak→accentTint
│ ┌───────────────────────┐ │        │ └────┘└────┘└────┘         │
│ │ Tuần này   ⏱  5h30m   │ │        │ (Ngày)(Tuần)(Tháng)        │  filterRow
│ │ ███████░░ (amber bar) │ │        │ ┌───────────────────────┐ │
│ └───────────────────────┘ │        │ │ ▁▃▅▂▇▄▮(amber today) │ │  chart tuần — lên sớm
│ Thống kê chi tiết          │        │ └───────────────────────┘ │
│ ┌──┐┌──┐┌──┐ (rainbow)     │        │ │ Tuần này 5h30m        │ │  study-time + goal bar
│ Bảng xếp hạng              │        │ │ ███████░░ (primary)   │ │   (non-amber: 1 amber rule)
│ ┌───────────────────────┐ │        │ Theo kỹ năng               │
│ │ ▁▃▅▂▇▄▮ chart (cuối)  │ │        │ 🎧 Nghe   ●●●●○ 80%       │  skillProgressBar(skill:)
│ └───────────────────────┘ │        │ 📖 Đọc    ●●○○○ 40%       │
│ 🎉 callout                 │        │ Bảng xếp hạng              │
└───────────────────────────┘        └───────────────────────────┘
                                      ↳ KPI + chart thấy ngay, không cần cuộn
```

### Zones (target)
| Zone | Nội dung | Token / Widget | Ghi chú |
|------|----------|----------------|---------|
| Greeting | `Tiến độ` (h1) | `greeting()` | bỏ body "Các chỉ số hiệu suất" (thừa) |
| KPI row | streak / points / level | `statCard(compact:true)` ×3 | streak → `iconBg: accentTint`, `iconColor: accent` (amber celebrate hợp lệ); points/level neutral |
| Filter | Ngày/Tuần/Tháng | `filterRow(skill:null)` | selected = primary (đúng) |
| Chart | bar tuần + trend | `WeeklyActivityBarsChart` | `barColor: chartBar`, `highlightColor: chartHighlight`, `highlightIndex: last` — giữ nguyên |
| Study-time | period + `kpi()` + goal bar | AppCard(outline) + `skillProgressBar` | bar đổi `color: AppColors.primary` (bỏ amber — tránh đua với chart highlight) |
| Per-skill | progress mỗi skill | `skillProgressBar(skill: …)` | skill color hợp lệ ở đây (1 row/skill, không trộn 2 skill/row) |
| Leaderboard | xếp hạng | AppCard(outline) `_LeaderRow` | giữ; #1 amber `accent` ok |

> **1 amber rule (A12 "Don't"):** celebrate amber = **streak KPI + cột hôm nay (chart highlight) + #1 rank**. Goal-progress bar (study-time) → `primary`/neutral; per-skill bar → skill color. Tránh để 4 nguồn amber cạnh tranh.

### Tùy chọn giữ grid _StatBox
Nếu giữ lưới chi tiết: giữ `skillIconBox(skill:)` cho **icon** (nhận diện skill) nhưng **không** thêm màu vào value/label — chữ vẫn `textPrimary`/`caption`. Đó là cách "1 row 1 skill" của A12, không phải rainbow toàn lưới.

---

## 3. Build diff (đường dẫn cụ thể cho Cursor)

File: `progress_report_page.dart`, `_buildSuccessUI()` (`:271`):

1. **Thêm KPI row đầu màn** — trước `filterRow`, chèn `Row` 3 `statCard(compact: true)`: streak / points / level (lấy từ `UserBloc` `userState.userEntity` đang có ở `:294–296`).
   ```dart
   Row(children: [
     Expanded(child: StudentMobileUi.statCard(
       context: context, icon: Icons.local_fire_department_rounded,
       value: '${user?.currentStreak ?? 0}', label: t.progressStatStreak,
       iconColor: AppColors.accent, iconBg: AppColors.accentTint, compact: true)),
     const SizedBox(width: StudentMobileUi.cardGap),
     Expanded(child: StudentMobileUi.statCard(
       context: context, icon: Icons.star_rounded,
       value: '${user?.totalPoints ?? 0}', label: t.progressStatPoints, compact: true)),
     const SizedBox(width: StudentMobileUi.cardGap),
     Expanded(child: StudentMobileUi.statCard(
       context: context, icon: Icons.military_tech_rounded,
       value: 'Lv ${user?.level ?? 1}', label: t.progressStatLevel, compact: true)),
   ]),
   ```
   (Cần 3 key l10n `progressStatStreak/Points/Level` — thêm vào `.arb`.)
2. **Bỏ 2 dòng chrome** `sectionHeader(progressOverview)` `:311` + `Text(performanceMetrics)` `:313` → thay greeting 1 dòng `Text(t.learningProgressTitle, style: StudentMobileUi.greeting(context))` (hoặc giữ trong appBar và bỏ luôn).
3. **Đưa chart card lên sớm** — cắt block AppCard weekly-activity (`:442–467`) đặt **ngay sau `filterRow`** (trước study-time card). Giữ nguyên `WeeklyActivityBarsChart(barColor: chartBar, highlightColor: chartHighlight, highlightIndex: chart.labels.length - 1)`.
4. **Bỏ amber ở goal-progress bar** — `skillProgressBar(... color: AppColors.accent ...)` `:355` → `color: AppColors.primary` (giữ 1 amber cho chart/streak).
5. **Per-skill rows (tùy chọn nâng cấp A12)** — nếu muốn đúng "Theo kỹ năng" của anatomy A12, thêm 1 section `skillProgressBar(skill: SkillType.x, value: …)` mỗi skill thay vì chỉ grid ô vuông. Grid `_StatBox` có thể giữ làm drill-down (`:380–430`), hoặc thay bằng list progress-bar.
6. Spacing: greeting → `s3` → KPI row → `s3` → filter → `s4` → chart → `s4` → study-time → `s4` → grid/skill → `s4` → leaderboard. (Dùng `AppSpacing.s3/s4`, `StudentMobileUi.cardGap` giữa KPI ô.)

> Không đụng `weekly_activity_bars_chart.dart` (đã đạt A12: 1 highlight, trend dashed). Không đụng `StudentMobileUi` (dùng chung). Giữ `RefreshIndicator` + `GamificationCelebrateHost` `:297–300`.

---

## 4. States (đã có — bổ sung empty)
- **Loading** → `StudentMobileUi.listLoading()` ✔ `:242` (skeleton khung).
- **Empty (chưa có hoạt động)** → **THÊM**: khi `chart.minutes` toàn 0 và stats rỗng → `StudentMobileUi.emptyState(icon: Icons.insights_outlined, title: t.progressEmptyTitle, body: t.progressEmptyBody)` thay vì vẽ lưới chart trống. (Pattern A8.)
- **Error** → `StudentMobileUi.errorBanner` + retry ✔ `:262–267` (gọi `_onRefresh`).
- **Leaderboard riêng** → loading `runnerLoading`, error caption, empty `emptyState(leaderboard_outlined)` ✔ `:504–532` (degrade mềm trong card, không vỡ cả màn).

## 5. Checklist
- [ ] KPI row (streak/points/level) lên **đầu**: `statCard(compact)` ×3; streak amber (`accent`/`accentTint`), còn lại neutral.
- [ ] Bỏ 2 dòng chrome "Tổng quan / Các chỉ số hiệu suất" (gộp về greeting 1 dòng).
- [ ] Chart tuần lên **sớm** (sau filter), không còn nằm gần cuối.
- [ ] **1 amber rule**: goal-progress bar đổi `primary`; amber chỉ streak + cột hôm nay + #1 rank.
- [ ] Per-skill bar dùng `skillProgressBar(skill:)` (1 skill/row, không trộn 2 skill/row); grid không "rainbow value/label".
- [ ] Empty "chưa có hoạt động" thay lưới chart trống.
- [ ] Không đụng chart widget / shared UI; `kpi()` giữ cho số to.
- [ ] `dart analyze lib/feature/progress` 0 lỗi mới.
- [ ] Xem 360×640: KPI + chart thấy ngay không cần cuộn.

> Áp xong ghi vào [`../../11-implementation-mapping.md`](../../11-implementation-mapping.md) "Migration log".
