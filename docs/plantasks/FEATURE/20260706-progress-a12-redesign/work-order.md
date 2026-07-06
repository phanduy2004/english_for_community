# Work-Order — FEATURE: Progress screen redesign A12 + bug/dead-data cleanup

- **Task ID:** `20260706-progress-a12-redesign`
- **Loại:** FEATURE · **Platform:** student mobile (Flutter) · **Cỡ:** T1 (~5 file: page + entity + state + bloc + l10n)
- **Mục tiêu:** Đưa màn Progress về đúng blueprint **A12** (KPI row lên đầu, chart tuần lên sớm, 1-amber-rule, empty state) + dọn toàn bộ bug/dead-data (callout chết, field bị bỏ phí, "You #X/Y", cached avatar, refresh thật). **0 đụng backend.**
- **Người phân tích:** Opus (brain). **Implementer:** Cursor/Codex. **Status:** ĐÃ AUDIT — chờ implement.
- **Liên quan:** brief `docs/ui-ux-system/patterns/04-screen-briefs/progress.md` (A12) — **doc thắng code**. Archetype `patterns/01-screen-archetypes.md` A12. Guardrail `12-ai-guardrails.md`.

---

## 1. Vấn đề + nguyên nhân gốc (dẫn chứng code)

Màn hiện tại (`progress_report_page.dart`) lệch A12 và mang nhiều bug/dead-data. Tất cả xác minh từ code thật:

**Layout (brief A12):**
- **A1 — Không có KPI row** (streak/points/level) đầu màn; mở bằng 2 dòng chữ `progressOverview` + `progressPerformanceMetrics` (`:316-318`). A12 yêu cầu KPI row trước (brief `:68,94`). Data đã có sẵn qua `UserBloc` (`:299-301` `userState.userEntity`).
- **A2 — Chart tuần (signature A12) nằm gần cuối** (`:447-472`), sau grid + leaderboard. A12 muốn chart lên ngay sau filter (brief `:60,150`).
- **A3 — Vi phạm "1 amber rule":** goal-progress bar dùng `AppColors.accent` (`:359`) — amber chỉ dành cho streak/cột-hôm-nay/#1 (brief `:102,133`, guardrail `12:28`).
- **A4 — Thiếu empty state:** user mới → toàn `0h 0m`/`0%`, chart vẽ lưới rỗng (screenshot chính là ca này). Brief `:143` yêu cầu `emptyState(insights_outlined,…)`; guardrail `12:48,59`.

**Bug / dead-data (ngoài brief):**
- **B1 — Callout card có `chevron_right` nhưng KHÔNG `onTap`** (`:474-497`) → affordance chết.
- **B2 — `readingWpm` chết hoàn toàn:** backend tính & gửi (`progressService.js:159`) nhưng `StatsGridEntity` không parse.
- **B3 — `speakingFluency` parse nhưng không hiển thị** (`progress_summary_entity.dart:60`; grid chỉ dùng `speakingAccuracy`).
- **B4 — `myRank`+`totalUsers` không hiện "Bạn #X/Y":** `LeaderboardResultEntity` đã parse `totalUsers` (`leaderboard_entity.dart:52-53`) nhưng bloc chỉ đẩy `myRank` vào state (`progress_bloc.dart:40-42`), UI không render dòng nào.
- **B5 — Avatar leaderboard dùng `NetworkImage` trực tiếp** (`:627`) → không cache, lệch guardrail perf (`cached_network_image` đã dùng ở chat).
- **B6 — RefreshIndicator đóng theo `Future.delayed` cố định** (`:218`), không theo lúc data thật load xong.

---

## 2. Audit downstream + Không regression

| Điểm | file:line | Ảnh hưởng sau thay đổi |
|---|---|---|
| `ProgressState.totalUsers` (field mới) | `progress_state.dart` | Thêm field optional có default `0`; copyWith/props mở rộng — không ai đọc field cũ bị mất |
| `StatsGridEntity.readingWpm` (field mới) | `progress_summary_entity.dart` | Backend đã gửi key `readingWpm`; parse thêm với default `0` → an toàn khi thiếu |
| `_buildSuccessUI` reorder | `progress_report_page.dart` | Các widget block **giữ nguyên nội dung**, chỉ đổi THỨ TỰ + 1 màu bar + thêm KPI row/empty. Drill-down `_StatBox → StatDetailDialog` giữ nguyên |
| `_LeaderRow` avatar | `:620-634` | Đổi provider `NetworkImage`→`CachedNetworkImageProvider`, cùng `DecorationImage` — hình hiển thị y hệt, chỉ thêm cache |
| `weekly_activity_bars_chart.dart` | — | **KHÔNG đụng** (đã đạt A12) |
| `StudentMobileUi.*` | — | **KHÔNG đụng** (shared); chỉ gọi `statCard/emptyState/greeting/skillProgressBar` sẵn có |

**Không regression:** logic fetch/cache trong `ProgressBloc` giữ nguyên; chỉ thêm `totalUsers` vào 1 `copyWith`. Range filter, StatDetailDialog, report dialog, leaderboard tap → profile: không đổi.

---

## 3. Hướng fix (thiết kế) + quyết định

Bám **build-diff brief §3** (`progress.md:109-137`). Thứ tự Column mới của `_buildSuccessUI`:

```
greeting (bỏ 2 dòng chrome; appBar đã có title)  →  s3
KPI row: statCard(compact) ×3 [streak amber / points / level]  →  s3
filterRow  →  s4
Weekly chart card (di chuyển từ cuối lên)  →  s4
Study-time card (goal bar: accent → primary)  →  s4
Detailed stats grid (thêm 2 tile: readingWpm, speakingFluency)  →  s4
Leaderboard: sectionHeader + dòng "Bạn #X/Y" + card  →  s4
Callout card (bỏ chevron)  →  s5
```

**Empty state (A4):** thêm nhánh trong `build()` body `BlocBuilder`, TRƯỚC nhánh success: nếu `summary != null && _isSummaryEmpty(summary)` → `_buildEmptyUI` = `RefreshIndicator( child: StudentMobileUi.emptyState(icon: insights_outlined, title, body) )`. Theo brief `:143` (chỉ icon+title+body, không CTA).

**Quyết định B1 (callout):** callout chỉ là thông điệp động viên, KHÔNG có màn đích → **bỏ `chevron_right`** (sửa affordance sai), không wire tap giả.

**Quyết định B2/B3 (dead-data):** hiển thị bằng cách **thêm 2 tile vào grid** (Reading WPM, Speaking Fluency) — grid `GridView.count(crossAxisCount:3)` tự xuống hàng (6→8 tile = 3+3+2). Ít rủi ro hơn nhồi subtitle vào tile cũ.

**Quyết định B6 (refresh):** `_onRefresh` await state thật xong thay vì delay cứng — chờ `bloc.stream.firstWhere` tới khi cả `status` và `leaderboardStatus` thoát `loading`.

**Bẫy:** `statCard` trả sẵn `SizedBox(width: double.infinity, child: AppCard(...))` → bọc trong `Expanded` khi để 3 ô/Row. `emptyState` là full-body state (có scrollview riêng) → dùng làm child trực tiếp của RefreshIndicator, KHÔNG lồng trong Column/ListView khác (unbounded height).

---

## 4. Scope IN / OUT

**IN:**
- `english_for_community/lib/feature/progress/progress_report_page.dart` — reorder + KPI row + empty + amber→primary + grid +2 tile + "You #X/Y" + cached avatar + callout chevron + refresh.
- `english_for_community/lib/core/entity/progress_summary_entity.dart` — thêm parse `readingWpm`.
- `english_for_community/lib/feature/progress/bloc/progress_state.dart` — thêm field `totalUsers`.
- `english_for_community/lib/feature/progress/bloc/progress_bloc.dart` — set `totalUsers` trong fold leaderboard.
- `english_for_community/lib/l10n/app_en.arb` + `app_vi.arb` — 8 key mới + `flutter gen-l10n`.

**OUT (chạm là DỪNG & hỏi):**
- ❌ `english_for_community_backend/**` — 0 đụng backend.
- ❌ `weekly_activity_bars_chart.dart`, `student_mobile_ui.dart` — shared/đã đạt A12.
- ❌ **A6** đổi grid→per-skill progress bars (brief để "tùy chọn") — giữ grid hiện tại (đã compliant: icon skill-color, text neutral). Follow-up.
- ❌ **A7** CelebrateBurst milestone triggers — feature riêng, follow-up.
- ❌ **B7** subtitle đơn vị cho tile, **B8** dọn `progressPercent` — follow-up.
- ❌ Backend features (streak calendar / achievements / leaderboard scoping) — plan riêng.

---

## 5. CONTEXT BUNDLE ⭐

### Site 1 — `progress_report_page.dart` · imports
- **Anchor:** `import 'package:flutter/material.dart';`
- **AFTER:** thêm dưới dòng material:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:cached_network_image/cached_network_image.dart';
  ```
- **GOTCHA:** package đã có trong pubspec (dùng ở `chat_avatar.dart`) — không thêm dependency.

### Site 2 — `_buildSuccessUI` · bỏ chrome + chèn KPI row trước filter
- **Anchor:** `StudentMobileUi.sectionHeader(context, title: t.progressOverview),`
- **BEFORE (verbatim, `:316-324`):**
  ```dart
            StudentMobileUi.sectionHeader(context, title: t.progressOverview),
            const SizedBox(height: AppSpacing.s1),
            Text(t.progressPerformanceMetrics, style: StudentMobileUi.body(context)),
            const SizedBox(height: AppSpacing.s3),
            StudentMobileUi.filterRow(
              labels: rangeLabels,
              selectedIndex: _range.index,
              onSelected: (i) => _onRangeSelected(context, i),
            ),
  ```
- **AFTER:** thay 2 dòng chrome bằng KPI row (dùng `user` đã có từ `BlocBuilder<UserBloc>` bao ngoài `:300`):
  ```dart
            Row(
              children: [
                Expanded(
                  child: StudentMobileUi.statCard(
                    context: context,
                    icon: Icons.local_fire_department_rounded,
                    value: '${user?.currentStreak ?? 0}',
                    label: t.progressStatStreak,
                    iconColor: AppColors.accent,
                    iconBg: AppColors.accentTint,
                    compact: true,
                  ),
                ),
                const SizedBox(width: StudentMobileUi.cardGap),
                Expanded(
                  child: StudentMobileUi.statCard(
                    context: context,
                    icon: Icons.star_rounded,
                    value: '${user?.totalPoints ?? 0}',
                    label: t.progressStatPoints,
                    compact: true,
                  ),
                ),
                const SizedBox(width: StudentMobileUi.cardGap),
                Expanded(
                  child: StudentMobileUi.statCard(
                    context: context,
                    icon: Icons.military_tech_rounded,
                    value: 'Lv ${user?.level ?? 1}',
                    label: t.progressStatLevel,
                    compact: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s3),
            StudentMobileUi.filterRow(
              labels: rangeLabels,
              selectedIndex: _range.index,
              onSelected: (i) => _onRangeSelected(context, i),
            ),
  ```
- **GOTCHA:** `AppColors.accentTint` đã có (`app_color.dart:63`). `user` là biến sẵn trong closure `BlocBuilder<UserBloc>` (`:300` `final user = userState.userEntity`) — KPI row nằm trong Column con của closure đó nên dùng trực tiếp được.

### Site 3 — `_buildSuccessUI` · goal bar amber → primary
- **Anchor:** `value: progress,` (trong `skillProgressBar` của study-time card, `:357-362`)
- **BEFORE:**
  ```dart
                    child: StudentMobileUi.skillProgressBar(
                      context: context,
                      value: progress,
                      color: AppColors.accent,
                      height: 6,
                    ),
  ```
- **AFTER:** `color: AppColors.accent` → `color: AppColors.primary`.
- **GOTCHA:** chỉ đổi đúng bar study-time này; KHÔNG đổi chart highlight.

### Site 4 — `_buildSuccessUI` · di chuyển chart card lên sau filter
- **Thao tác:** CẮT nguyên block chart card (`:447-472`, `AppCard` chứa `WeeklyActivityBarsChart` + `SizedBox(height: AppSpacing.s4)` liền trước nó) và DÁN ngay **sau** `filterRow` + `const SizedBox(height: AppSpacing.s4)` (trước study-time card `:327`). Block giữ nguyên nội dung.
- **Anchor (block cần cắt):** `child: WeeklyActivityBarsChart(`
- **BEFORE (verbatim, block chart `:447-473`):**
  ```dart
            AppCard(
              variant: AppCardVariant.outline,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.progressActivity, style: StudentMobileUi.sectionTitle(context)),
                      const Icon(Icons.bar_chart, color: AppColors.textSecondary, size: 18),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  SizedBox(
                    height: 120,
                    child: WeeklyActivityBarsChart(
                      values: chart.minutes,
                      labels: chart.labels,
                      barColor: AppColors.chartBar,
                      highlightIndex: chart.labels.length - 1,
                      highlightColor: AppColors.chartHighlight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
  ```
- **AFTER:** đặt block trên (nguyên văn) vào vị trí **sau** study-time filter, trước study-time card. Thứ tự cuối: `…filterRow → SizedBox(s4) → [CHART BLOCK] → study-time card → SizedBox(s4) → Detailed stats…`. Xoá block chart ở vị trí cũ (cuối màn).
- **GOTCHA:** giữ đúng 1 `SizedBox(height: s4)` giữa các card — đừng để lệch spacing khi cắt/dán.

### Site 5 — `_buildSuccessUI` · grid thêm 2 tile (dead-data B2/B3)
- **Anchor:** `label: t.progressStatSpeaking,` (tile cuối cùng của grid `:427-433`)
- **BEFORE (tile Speaking, cuối `children` của GridView):**
  ```dart
                _StatBox(
                  icon: Icons.record_voice_over_rounded,
                  value: '${stats.speakingAccuracy}%',
                  label: t.progressStatSpeaking,
                  skill: SkillType.speaking,
                  onTap: () => _showStatDetailDialog(progressBloc, 'speaking', _range),
                ),
  ```
- **AFTER:** thêm 2 tile ngay sau tile Speaking (trong cùng `children`):
  ```dart
                _StatBox(
                  icon: Icons.record_voice_over_rounded,
                  value: '${stats.speakingAccuracy}%',
                  label: t.progressStatSpeaking,
                  skill: SkillType.speaking,
                  onTap: () => _showStatDetailDialog(progressBloc, 'speaking', _range),
                ),
                _StatBox(
                  icon: Icons.speed_rounded,
                  value: '${stats.readingWpm}',
                  label: t.progressStatReadingWpm,
                  skill: SkillType.reading,
                  onTap: () => _showStatDetailDialog(progressBloc, 'reading', _range),
                ),
                _StatBox(
                  icon: Icons.graphic_eq_rounded,
                  value: '${stats.speakingFluency}%',
                  label: t.progressStatSpeakingFluency,
                  skill: SkillType.speaking,
                  onTap: () => _showStatDetailDialog(progressBloc, 'speaking', _range),
                ),
  ```
- **GOTCHA:** cần `stats.readingWpm` (Site 7 thêm field). Grid tự xuống hàng (8 tile / 3 cột).

### Site 6 — `_buildSuccessUI` · dòng "Bạn #X/Y" trên leaderboard (B4)
- **Anchor:** `StudentMobileUi.sectionHeader(context, title: t.progressLeaderboard),`
- **BEFORE (`:438-444`):**
  ```dart
            StudentMobileUi.sectionHeader(context, title: t.progressLeaderboard),
            const SizedBox(height: AppSpacing.s3),
            AppCard(
              variant: AppCardVariant.outline,
              padding: EdgeInsets.zero,
              child: _buildLeaderboardContent(state, t),
            ),
  ```
- **AFTER:** chèn dòng rank giữa header và card (render có điều kiện):
  ```dart
            StudentMobileUi.sectionHeader(context, title: t.progressLeaderboard),
            if (state.myRank > 0 && state.totalUsers > 0) ...[
              const SizedBox(height: AppSpacing.s1),
              Text(
                t.progressLeaderboardYouRank(state.myRank, state.totalUsers),
                style: StudentMobileUi.caption(context).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: AppSpacing.s3),
            AppCard(
              variant: AppCardVariant.outline,
              padding: EdgeInsets.zero,
              child: _buildLeaderboardContent(state, t),
            ),
  ```
- **GOTCHA:** cần `state.totalUsers` (Site 8 + 9).

### Site 7 — `_buildSuccessUI` · callout bỏ chevron (B1)
- **Anchor:** `const Icon(Icons.chevron_right, color: AppColors.success, size: 18),`
- **BEFORE:** dòng `Icon(Icons.chevron_right, …)` (`:494`) là con cuối của `Row` callout.
- **AFTER:** **XOÁ** dòng `const Icon(Icons.chevron_right, color: AppColors.success, size: 18),`. Giữ nguyên phần còn lại của callout.
- **GOTCHA:** không đổi màu/nội dung callout; chỉ bỏ icon gợi-ý-điều-hướng.

### Site 8 — `_LeaderRow` · cached avatar (B5)
- **Anchor:** `? DecorationImage(image: NetworkImage(avatarUrl!), fit: BoxFit.cover)`
- **BEFORE (`:626-628`):**
  ```dart
                  image: (avatarUrl != null && avatarUrl!.isNotEmpty)
                      ? DecorationImage(image: NetworkImage(avatarUrl!), fit: BoxFit.cover)
                      : null,
  ```
- **AFTER:** `NetworkImage(avatarUrl!)` → `CachedNetworkImageProvider(avatarUrl!)`.
- **GOTCHA:** giữ nguyên `DecorationImage` + fallback icon; `CachedNetworkImageProvider` từ import Site 1.

### Site 9 — `build()` body · nhánh empty (A4)
- **Anchor:** `if (state.summary != null) {` (trong `BlocBuilder` body, `:252`)
- **BEFORE:**
  ```dart
              if (state.summary != null) {
                return _buildSuccessUI(context, state, t);
              }
  ```
- **AFTER:**
  ```dart
              if (state.summary != null && _isSummaryEmpty(state.summary!)) {
                return _buildEmptyUI(context, t);
              }
              if (state.summary != null) {
                return _buildSuccessUI(context, state, t);
              }
  ```
- **THÊM 2 method** trong `_ProgressReportPageState`:
  ```dart
  bool _isSummaryEmpty(ProgressSummaryEntity s) {
    final noTime = s.studyTime.totalMinutesInRange == 0 &&
        s.studyTime.todayMinutes == 0;
    final noChart = s.weeklyChart.minutes.every((m) => m == 0);
    final g = s.statsGrid;
    final noStats = g.vocabLearned == 0 &&
        g.lessonsCompleted == 0 &&
        g.readingAccuracy == 0 &&
        g.dictationAccuracy == 0 &&
        g.speakingAccuracy == 0 &&
        g.speakingFluency == 0 &&
        g.readingWpm == 0 &&
        g.avgWritingScore == 0;
    return noTime && noChart && noStats;
  }

  Widget _buildEmptyUI(BuildContext context, AppLocalizations t) {
    return RefreshIndicator(
      onRefresh: () => _onRefresh(context),
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceCard,
      child: StudentMobileUi.emptyState(
        context,
        icon: Icons.insights_outlined,
        title: t.progressEmptyTitle,
        body: t.progressEmptyBody,
      ),
    );
  }
  ```
- **GOTCHA:** import `progress_summary_entity.dart` cho type `ProgressSummaryEntity` (kiểm tra: page hiện chưa import trực tiếp — thêm nếu thiếu). `emptyState` làm child trực tiếp RefreshIndicator (đừng lồng scroll).

### Site 10 — `_onRefresh` · chờ load thật (B6)
- **Anchor:** `await Future.delayed(AppMotion.savedFade);`
- **BEFORE (`:214-219`):**
  ```dart
  Future<void> _onRefresh(BuildContext context) async {
    final bloc = context.read<ProgressBloc>();
    bloc.add(FetchProgressData(range: _rangeToString(_range), forceRefresh: true));
    bloc.add(FetchLeaderboard());
    await Future.delayed(AppMotion.savedFade);
  }
  ```
- **AFTER:**
  ```dart
  Future<void> _onRefresh(BuildContext context) async {
    final bloc = context.read<ProgressBloc>();
    bloc.add(FetchProgressData(range: _rangeToString(_range), forceRefresh: true));
    bloc.add(FetchLeaderboard());
    await bloc.stream.firstWhere((s) =>
        s.status != ProgressStatus.loading &&
        s.leaderboardStatus != LeaderboardStatus.loading);
  }
  ```
- **GOTCHA:** `firstWhere` sẽ resolve khi cả 2 luồng thoát loading; enum đã import qua `progress_state.dart`.

### Site 11 — `progress_summary_entity.dart` · thêm `readingWpm` (B2)
- **Anchor:** `final int lessonsCompleted; // ✍️ THÊM TRƯỜNG MỚI`
- **Thao tác:** thêm field `readingWpm` vào class `StatsGridEntity`: khai báo `final int readingWpm;`, thêm vào constructor `required this.readingWpm,`, và factory `readingWpm: json["readingWpm"] ?? 0,`.
- **GOTCHA:** default `?? 0` phòng backend cũ thiếu key; các field khác giữ nguyên.

### Site 12 — `progress_state.dart` · thêm `totalUsers` (B4)
- **Thao tác:** thêm `final int totalUsers;` cạnh `myRank`; thêm `this.totalUsers = 0` (hoặc `required` + init `totalUsers: 0` trong `initial()`); thêm vào `copyWith` (`int? totalUsers` + `totalUsers: totalUsers ?? this.totalUsers`) và `props`.
- **GOTCHA:** đồng bộ cả 4 chỗ (field · constructor · copyWith · props · initial) — Equatable.

### Site 13 — `progress_bloc.dart` · set `totalUsers` (B4)
- **Anchor:** `myRank: data.myRank,`
- **BEFORE (`:38-42`):**
  ```dart
        emit(state.copyWith(
          leaderboardStatus: LeaderboardStatus.success,
          leaderboardUsers: data.leaderboard,
          myRank: data.myRank,
        ));
  ```
- **AFTER:** thêm `totalUsers: data.totalUsers,` (field đã có ở `LeaderboardResultEntity.totalUsers`).
- **GOTCHA:** `data` là `LeaderboardResultEntity` — đã có `.totalUsers`.

### SYMBOL TABLE

| Symbol | Verbatim | Nguồn | Trạng thái |
|---|---|---|---|
| `statCard` | `statCard({required context, required icon, required value, required label, Color? iconColor, Color? iconBg, SkillType? skill, bool compact=false})` | `student_mobile_ui.dart:782` | [CÓ] |
| `emptyState` | `emptyState(context, {required icon, required title, required body, ctaLabel, onCta, skill, lottie})` | `:165` | [CÓ] |
| `greeting`/`kpi`/`caption`/`cardGap` | có sẵn | `:45/:58/…` | [CÓ] |
| `CachedNetworkImageProvider` | `CachedNetworkImageProvider(String url)` | package `cached_network_image` | [CÓ] |
| `LeaderboardResultEntity.totalUsers` | `final int totalUsers;` | `leaderboard_entity.dart:53` | [CÓ] |
| `user.currentStreak/totalPoints/level` | fields trên `UserEntity` | userState `:301` | [CÓ] |
| `progressStatStreak` | EN "Streak" · VI "Chuỗi ngày" | `.arb` | [THÊM] |
| `progressStatPoints` | EN "Points" · VI "Điểm" | `.arb` | [THÊM] |
| `progressStatLevel` | EN "Level" · VI "Cấp độ" | `.arb` | [THÊM] |
| `progressStatReadingWpm` | EN "Reading WPM" · VI "Tốc độ đọc" | `.arb` | [THÊM] |
| `progressStatSpeakingFluency` | EN "Fluency" · VI "Độ trôi chảy" | `.arb` | [THÊM] |
| `progressEmptyTitle` | EN "No activity yet" · VI "Chưa có hoạt động" | `.arb` | [THÊM] |
| `progressEmptyBody` | EN "Complete your first lesson to start tracking your progress." · VI "Hoàn thành bài học đầu tiên để bắt đầu theo dõi tiến độ." | `.arb` | [THÊM] |
| `progressLeaderboardYouRank` | EN "You: #{rank} of {total}" · VI "Bạn: hạng #{rank}/{total}" — placeholders `rank`(int), `total`(int) | `.arb` | [THÊM] |

### CLONE-THIS
- KPI row: nhái `statCard(compact:true)` như home stats row (brief `:113-128`).
- Grid tile: nhái `_StatBox` sẵn có trong file (`:656`) cho 2 tile mới.
- l10n có placeholder số: nhái `progressPercentCompleted` (`app_en.arb:514`, đã có `{pct}` int) cho `progressLeaderboardYouRank`.

---

## 6. GATE liên quan

- **UI/UX (chạm layout — bắt buộc):** bám brief A12 `progress.md` + guardrail `12`. Checklist: KPI row đầu (streak amber, points/level neutral) · chart lên sớm · **1-amber-rule** (goal bar primary) · empty state · token-only (không hex mới) · `textPrimary` cho value, `caption` cho label. Đối chiếu màn tham chiếu: Home stats row (statCard compact).
- **Perf:** grid vẫn `GridView.count(shrinkWrap, NeverScrollable)` trong 1 `SingleChildScrollView` — N cố định (8 tile), OK. `CachedNetworkImageProvider` giảm network. Không thêm listener/timer. KHÔNG thêm API trong build. Refresh `firstWhere` là 1 lần/refresh.
- **Backend:** N/A (0 đụng).
- **L10n:** 8 key mới → thêm `app_en.arb` + `app_vi.arb` + chạy `flutter gen-l10n`. `progressLeaderboardYouRank` có 2 placeholder int (khai báo `placeholders` trong arb metadata).

---

## 7. Verify + Hồi quy tối thiểu

**Analyze (0 lỗi mới):**
```bash
cd english_for_community && flutter gen-l10n && dart analyze lib/feature/progress lib/core/entity/progress_summary_entity.dart
```

**Smoke (⭐ = nghiệm thu chính):**
1. ⭐ **Layout A12:** mở tab Progress (account có hoạt động) → thấy **KPI row (streak/points/level) đầu màn** + **chart tuần ngay sau filter** (không cần cuộn). Account seed: `docs/dev/seeds/`.
2. ⭐ **Empty state:** account mới / range không có data → hiện `emptyState` "Chưa có hoạt động" (icon insights), KHÔNG vẽ lưới chart trống / lưới 0%.
3. **1-amber-rule:** goal-progress bar study-time màu **primary** (không amber); amber chỉ ở streak KPI + cột hôm nay của chart + #1 leaderboard.
4. **Dead-data:** grid có tile **Reading WPM** + **Fluency** với số thật; dòng **"Bạn: hạng #X/Y"** hiện trên leaderboard.
5. **B1/B5:** callout KHÔNG còn mũi tên `›`; avatar leaderboard load qua cache (đổi range 2 lần không nháy tải lại).
6. **No-regression:** đổi Day/Week/Month vẫn fetch đúng; tap tile → StatDetailDialog mở; tap user leaderboard → profile dialog; pull-to-refresh xoay tới khi data về rồi mới dừng.

> Fail smoke ⭐ sau khi sửa → DỪNG & báo Opus kèm log.

---

## 8. HANDOFF PROMPT cho Cursor/Codex

```text
Bạn là implementer (Cursor/Codex). Làm đúng phạm vi, biên giới cứng.
Repo: english_for_community (Flutter).

━━━ BƯỚC 0 — ĐỌC WORK-ORDER TRƯỚC (bắt buộc) ━━━
Mở & đọc HẾT: docs/plantasks/FEATURE/20260706-progress-a12-redesign/work-order.md
Code lấy NGUYÊN từ §5 CONTEXT BUNDLE (13 Site + anchor + BEFORE/AFTER + symbol table). KHÔNG tự grep đoán.
Bám brief docs/ui-ux-system/patterns/04-screen-briefs/progress.md (A12) — nếu code lệch BEFORE hoặc mâu thuẫn → DỪNG & hỏi (doc thắng).

━━━ PHẠM VI ━━━
SỬA (chỉ 5 file): progress_report_page.dart, core/entity/progress_summary_entity.dart,
  feature/progress/bloc/progress_state.dart, feature/progress/bloc/progress_bloc.dart, l10n/app_en.arb + app_vi.arb.
TUYỆT ĐỐI KHÔNG:
  - Đụng backend, weekly_activity_bars_chart.dart, student_mobile_ui.dart.
  - Đổi grid→per-skill bars (A6), thêm CelebrateBurst (A7), subtitle đơn vị (B7) — OUT, follow-up.
  - Đổi public signature; thêm dependency; hardcode hex/spacing (token-only); hardcode string (l10n EN+VI).

━━━ LÀM ━━━
Theo §5, 13 Site (imports → KPI row → amber→primary → chart lên sớm → grid +2 tile → "You #X/Y" →
callout bỏ chevron → cached avatar → empty branch → refresh thật → entity readingWpm → state totalUsers → bloc totalUsers).
L10n: thêm 8 key EN+VI (progressStatStreak/Points/Level, progressStatReadingWpm, progressStatSpeakingFluency,
progressEmptyTitle/Body, progressLeaderboardYouRank[rank,total]) rồi `flutter gen-l10n`.
GATE: UI/UX (brief A12 + 1-amber-rule) + L10n. Token-only.

━━━ VERIFY (chạy hết, dán kết quả) ━━━
cd english_for_community && flutter gen-l10n && dart analyze lib/feature/progress lib/core/entity/progress_summary_entity.dart
→ smoke 1..6 ở §7 (⭐ = layout A12 KPI+chart lên đầu; empty state).

━━━ XONG ━━━
- Dán analyze + smoke vào chat. Self-audit ngắn (file · rủi ro · checklist §5).
- KHÔNG commit/push. Báo Opus: "implementer đã xong, audit đi".
```

---

## 9. Checklist OPUS AUDIT (Phase 4)
- [ ] `git diff`: chỉ 5 file Scope IN; backend/chart/shared UI không đụng; A6/A7/B7 không lọt vào.
- [ ] Site 2: KPI row đúng (streak amber `accent`/`accentTint`, points/level neutral); 2 dòng chrome đã bỏ.
- [ ] Site 3: goal bar `AppColors.primary` (không còn amber); chart highlight vẫn amber.
- [ ] Site 4: chart card đứng ngay sau filter; spacing s4 đúng; block cũ ở cuối đã xoá.
- [ ] Site 5/11: 2 tile mới hiện số thật; `readingWpm` parse có default 0.
- [ ] Site 6/12/13: dòng "Bạn #X/Y" render khi có rank; `totalUsers` đồng bộ state/bloc/props.
- [ ] Site 7/8: callout hết chevron; avatar dùng `CachedNetworkImageProvider`.
- [ ] Site 9: empty branch đúng điều kiện `_isSummaryEmpty`; emptyState không lồng scroll.
- [ ] Site 10: refresh chờ `firstWhere` (không delay cứng).
- [ ] L10n EN+VI đủ 8 key; `flutter gen-l10n` chạy; không hardcode string; token-only (không hex/spacing lạ).
- [ ] `dart analyze` 0 lỗi mới; smoke ⭐ (layout + empty) pass; no-regression (filter/dialog/refresh) pass.
- [ ] 360×640: KPI + chart thấy ngay không cần cuộn (brief checklist `:156`).
- [ ] Áp xong → ghi Migration log `11-implementation-mapping.md` (brief `:158`).

---

## 10. Follow-up (OUT — task riêng)
- **A6:** section "Theo kỹ năng" bằng `skillProgressBar(skill:)` 1-row/skill (thay/bổ sung grid) — nâng cấp đúng anatomy A12.
- **A7:** `CelebrateBurst` khi đạt mốc streak/level/XP (host đã wire `:302`) — `20-…md §5.3`.
- **B7:** subtitle đơn vị cho tile (Writing "/9", accuracy "%") giảm nhầm lẫn "0.0".
- **B8:** dọn `studyTime.progressPercent` (frontend không dùng) hoặc dùng lại thay vì tự tính.
- **Backend features:** streak calendar (derive từ `UserDailyProgress`), achievements/badges, leaderboard theo lớp/bạn/tuần, per-skill trend chart — cần endpoint mới (plan full-stack riêng).
