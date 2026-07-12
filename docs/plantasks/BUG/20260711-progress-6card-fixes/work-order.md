# Work-Order — BUG: Learning Progress — sửa nghiệp vụ 3 card (Speaking / Vocabulary / parse null-safe)

- **Task ID:** `20260711-progress-6card-fixes`
- **Loại:** BUG · **Platform:** full-stack · **Cỡ:** T1
- **Mục tiêu:** Card Speaking không còn hiện "0%" khi học sinh chỉ luyện free-speaking; card Vocabulary đếm **số từ distinct đã ôn** (không đếm trùng lượt); màn Progress không crash nếu backend thiếu 1 field stat.
- **Người phân tích:** Opus (brain). **Implementer:** Cursor/Codex. **Status:** ROOT CAUSE XÁC ĐỊNH — chờ implement.
- **Liên quan:** Audit 6 card progress (chat) · test đã có: `progressService.test.js`, `test/progress_summary_entity_test.dart`.

---

## 1. Vấn đề + nguyên nhân gốc (dẫn chứng code)

Màn `ProgressReportPage` hiển thị 6 card lấy từ `statsGrid` (endpoint `GET progress/summary`). 3 lỗi nghiệp vụ:

**F1 — Card Speaking hiện "0%" cho người luyện nói tích cực + nhãn "fluency" sai nghĩa.**
- Có 2 luồng nói ghi vào 2 bucket KHÁC nhau của `UserDailyProgress.stats`:
  - Speaking-set (`speakingController.js:70`): `score = 1 - WER` → bucket `speakingScore`.
  - Free-speaking (`speakingService.js:662-666`): `score = feedback.overall/9`, `metric:'fluency'` → bucket `speakingFluency` (thực chất là **điểm band tổng**, KHÔNG phải fluency).
- `progressService.js` (hàm `aggregateProgressRecords`) tính `speakingAccuracy` **chỉ từ `speakingScore`**; `speakingFluency` để riêng làm subtitle.
- **Hệ quả:** học sinh chỉ luyện **free-speaking** → `speakingScore.count = 0` → card hiện **"Speaking 0%"** dù nói tốt; ngược lại người chỉ làm speaking-set thì subtitle "Trôi chảy 0%".

**F2 — Card Vocabulary đếm số LƯỢT ôn (good/easy), không phải số TỪ.**
- `progressTracker.js:75-77` + `vocabController.js:117-119`: mỗi lần chấm SRS **'good'/'easy'** → `$inc vocabLearned += 1` (kể cả ôn lại cùng 1 từ nhiều ngày; 'hard' không tính).
- `aggregateProgressRecords` cộng dồn `rec.vocabLearned` → card "Từ vựng" = **số lượt ôn đạt**, không phải số từ distinct.

**F3 — `StatsGridEntity.fromJson` không null-safe → crash cả màn nếu thiếu 1 field.**
- `progress_summary_entity.dart:75-85`: 6 field parse thẳng `json["x"]` KHÔNG có `?? 0` (chỉ `speakingFluency`/`readingWpm` có). Thiếu bất kỳ field nào (backend đổi/thiếu) → `TypeError` → `ProgressState.error` → cả màn Progress hỏng. (Đã khoá bằng test `throwsA` hiện tại.)

---

## 2. Audit downstream (consumer / đường dùng chung)

> Grep: `speakingFluency`, `progressStatFluencyInline`, `vocabLearned`, `metric: 'fluency'`.

| Điểm | file:line | Ảnh hưởng sau thay đổi |
|---|---|---|
| Bucket `speakingFluency` (raw stats) đọc bởi userController | `userController.js:33,64-66,82` | **KHÔNG đổi** — F1 chỉ gộp ở phía ĐỌC trong `progressService`, KHÔNG đụng write-path → bucket vẫn được free-speaking ghi như cũ. |
| Bucket `speakingFluency` đọc bởi AI tools | `tools/implementations.js:509,528,544,889,994` | **KHÔNG đổi** — cùng lý do trên; đặc biệt `:994` gộp speaking qua fluency bucket vẫn nguyên. |
| `stats.speakingFluency` (statsGrid) → subtitle card | `progress_report_page.dart:484` | Subtitle **bị gỡ** (F1). Field entity giữ nguyên (không xoá). |
| l10n `progressStatFluencyInline` | `app_en.arb:541`, `app_vi.arb:430` | Trở thành **unused** — GIỮ NGUYÊN (không xoá, ngoài scope). |
| `statsGrid.vocabLearned` | entity + `progress_report_page.dart:448` | Card đọc số mới (distinct) — chỉ đổi **giá trị**, không đổi shape/label. |

**Không regression:** F1 **không sửa `speakingService.js`** (giữ luồng ghi `speakingFluency`) nên userController + AI tools đọc bucket này KHÔNG bị ảnh hưởng — chỉ `progressService.aggregateProgressRecords` gộp 2 bucket khi tính card. F2 chỉ override `statsGrid.vocabLearned` trong `getSummaryData` (shape JSON giữ nguyên). F3 nới lỏng parse (giá trị hợp lệ vẫn parse y hệt, chỉ thêm nhánh default khi null).

---

## 3. Hướng fix (thiết kế) + quyết định

**F1 — Gộp ở phía ĐỌC (chọn), KHÔNG đổi write-path (loại).**
- Chọn: trong `aggregateProgressRecords`, `speakingAccuracy = round(avg(speakingScore ∪ speakingFluency) * 100)` — gộp total/count 2 bucket (đều thang 0..1). Gỡ subtitle fluency ở card.
- Vì sao: 2 bucket đều là "chất lượng nói 0..1"; gộp ⇒ mọi hoạt động nói tính vào %, hết "0%".
- Loại phương án "đổi `speakingService.js` metric→speakingScore": sẽ làm **userController + AI tools** (đọc bucket `speakingFluency`) mất tín hiệu free-speaking (xem §2) → downstream risk. Gộp phía đọc an toàn hơn.
- Giữ `statsGrid.speakingFluency` trong response (backward-compat); FE chỉ bỏ hiển thị.

**F2 — Đếm distinct từ đã ôn trong range (chọn).**
- Chọn: `statsGrid.vocabLearned = Word.countDocuments({ user, status:'learning', lastReviewedDate: {range} })`.
- ⚠️ **Cảnh báo dữ liệu (đọc code thật):** model `Word` **không có** status `'learned'` (enum chỉ `recent/learning/saved`) và **không có** timestamp "học xong"; tiến trình học qua `learningLevel` (số, tăng dần, không có mốc tốt nghiệp). Nên "số từ ĐÃ HỌC chính xác trong kỳ" **không có tín hiệu sạch**. Metric khả thi + trung thực nhất = **distinct từ đang học (`status:'learning'`) có `lastReviewedDate` trong range** = "số từ đã ôn trong kỳ" (distinct, không đếm trùng lượt). Đây là cải thiện đúng so với đếm lượt.
- ⚠️ Field là **`user`** (KHÔNG phải `userId`) trong schema `Word`. (Lưu ý: `getStatDetailData` case `'vocab'` đang query nhầm `userId` → detail list vocab luôn rỗng — **follow-up §10**, KHÔNG sửa trong task này.)
- ⚠️ Range 'day': `_calculateDateRange('day')` = **7 ngày**; nhưng các card khác ở 'day' = **chỉ hôm nay**. → Override start = `userTodayStart` cho 'day' để đồng bộ.
- Nhãn card giữ "Từ vựng" (vẫn hợp). Không thêm l10n.

**F3 — Null-safe toàn bộ field số của `StatsGridEntity` + `StudyTimeEntity`.**
- Dùng `(json["x"] as num?)?.toInt() ?? 0` (int) / `?.toDouble() ?? 0` (double) — nhận cả int/double, thiếu → 0, không crash. Giá trị hợp lệ parse y hệt.

---

## 4. Scope IN / OUT

**IN (chính xác file được sửa):**
- `english_for_community_backend/src/services/progressService.js` — F1 (gộp speaking trong `aggregateProgressRecords`) + F2 (override vocab distinct trong `getSummaryData`).
- `english_for_community_backend/src/services/progressService.test.js` — cập nhật 2 test speaking (giờ gộp).
- `english_for_community/lib/feature/progress/progress_report_page.dart` — F1 gỡ subtitle fluency.
- `english_for_community/lib/core/entity/progress_summary_entity.dart` — F3 null-safe (`StatsGridEntity` + `StudyTimeEntity`).
- `english_for_community/test/progress_summary_entity_test.dart` — F3 lật 3 test fragility (giờ default 0).

**OUT (chạm là DỪNG & hỏi):**
- ❌ `english_for_community_backend/src/services/speakingService.js` — GIỮ luồng ghi `metric:'fluency'` (downstream userController + AI tools).
- ❌ `userController.js`, `tools/implementations.js` — consumer bucket fluency, không đụng.
- ❌ `UserDailyProgress.js`, `Word.js` (schema) — không migration.
- ❌ l10n `progressStatFluencyInline` — để unused, không xoá.
- ❌ `getStatDetailData` (bug `user`/`userId` vocab) — follow-up §10.
- ❌ F4 (mẫu số goal tuần/tháng) + F5 (progressPercent theo range) — follow-up §10.

---

## 5. CONTEXT BUNDLE ⭐ (bắt buộc)

### Site 1 — `english_for_community_backend/src/services/progressService.js` · hàm `aggregateProgressRecords` (F1)
- **Locator (anchor):** search `const calcAvg = (agg) => agg.count > 0 ? (agg.total / agg.count) : 0;` (bản trong `aggregateProgressRecords` — bản đầu tiên trong file).
- **BEFORE (verbatim):**
  ```js
  const calcAvg = (agg) => agg.count > 0 ? (agg.total / agg.count) : 0;

  const statsGrid = {
    vocabLearned: vocabSum,
    lessonsCompleted: lessonsSum,
    readingAccuracy: Math.round(calcAvg(aggs.readingAcc) * 100),
    dictationAccuracy: Math.round(calcAvg(aggs.dictationAcc) * 100),
    speakingAccuracy: Math.round(calcAvg(aggs.speakingScore) * 100),
    speakingFluency: Math.round(calcAvg(aggs.speakingFluency) * 100),
    avgWritingScore: parseFloat(calcAvg(aggs.writingScore).toFixed(1)),
    readingWpm: Math.round(calcAvg(aggs.readingWpm))
  };
  ```
- **AFTER:**
  ```js
  const calcAvg = (agg) => agg.count > 0 ? (agg.total / agg.count) : 0;

  // F1: card "Speaking" gộp CẢ speaking-set (speakingScore = 1-WER) LẪN free-speaking
  // (speakingFluency = overall/9) — cùng thang 0..1 — để mọi hoạt động nói tính vào %,
  // tránh hiện "0%" khi học sinh chỉ luyện free-speaking.
  const speakingCombined = {
    total: aggs.speakingScore.total + aggs.speakingFluency.total,
    count: aggs.speakingScore.count + aggs.speakingFluency.count,
  };

  const statsGrid = {
    vocabLearned: vocabSum,
    lessonsCompleted: lessonsSum,
    readingAccuracy: Math.round(calcAvg(aggs.readingAcc) * 100),
    dictationAccuracy: Math.round(calcAvg(aggs.dictationAcc) * 100),
    speakingAccuracy: Math.round(calcAvg(speakingCombined) * 100),
    speakingFluency: Math.round(calcAvg(aggs.speakingFluency) * 100),
    avgWritingScore: parseFloat(calcAvg(aggs.writingScore).toFixed(1)),
    readingWpm: Math.round(calcAvg(aggs.readingWpm))
  };
  ```
- **GOTCHA:** GIỮ dòng `speakingFluency:` (backward-compat, FE entity vẫn cần + consumer khác). Chỉ đổi công thức `speakingAccuracy`. Không đụng `vocabLearned: vocabSum` ở đây (F2 override ở Site 3).

### Site 2 — `english_for_community/lib/feature/progress/progress_report_page.dart` · `_StatBox` Speaking (F1)
- **Locator (anchor):** search `subtitle: t.progressStatFluencyInline(stats.speakingFluency),`
- **BEFORE (verbatim):**
  ```dart
                _StatBox(
                  icon: Icons.record_voice_over_rounded,
                  value: '${stats.speakingAccuracy}%',
                  label: t.progressStatSpeaking,
                  subtitle: t.progressStatFluencyInline(stats.speakingFluency),
                  skill: SkillType.speaking,
                  onTap: () => _showStatDetailDialog(progressBloc, 'speaking', _range),
                ),
  ```
- **AFTER:** xoá đúng dòng `subtitle: ...`:
  ```dart
                _StatBox(
                  icon: Icons.record_voice_over_rounded,
                  value: '${stats.speakingAccuracy}%',
                  label: t.progressStatSpeaking,
                  skill: SkillType.speaking,
                  onTap: () => _showStatDetailDialog(progressBloc, 'speaking', _range),
                ),
  ```
- **GOTCHA:** `_StatBox.subtitle` là optional → gỡ an toàn. KHÔNG xoá field `speakingFluency` ở entity, KHÔNG xoá l10n key.

### Site 3 — `english_for_community_backend/src/services/progressService.js` · hàm `getSummaryData` (F2)
- **Locator (anchor):** search `aggregateProgressRecords(records, { startDateString, todayString });`
- **BEFORE (verbatim):**
  ```js
  const { totalSecondsInRange, todayMinutes, statsGrid } =
    aggregateProgressRecords(records, { startDateString, todayString });

  const chartMinutes = queryDateKeys.map(dateKey => {
    const rec = recordsMap.get(dateKey);
    return rec ? Math.round(rec.studySeconds / 60) : 0;
  });
  ```
- **AFTER:**
  ```js
  const { totalSecondsInRange, todayMinutes, statsGrid } =
    aggregateProgressRecords(records, { startDateString, todayString });

  // F2: "Từ vựng" = SỐ TỪ DISTINCT đã ôn trong range (không phải số lượt good/easy →
  // tránh đếm trùng khi ôn lại cùng 1 từ). LƯU Ý: field là `user` (KHÔNG phải userId).
  // 'day' override start = userTodayStart vì _calculateDateRange('day') = 7 ngày, còn
  // các card khác ở 'day' chỉ tính hôm nay → giữ đồng bộ.
  const { startDate: vocabRangeStart, endDate: vocabRangeEnd } =
    _calculateDateRange(range, userTimezone);
  statsGrid.vocabLearned = await Word.countDocuments({
    user: userId,
    status: 'learning',
    lastReviewedDate: {
      $gte: range === 'day' ? userTodayStart : vocabRangeStart,
      $lte: vocabRangeEnd,
    },
  });

  const chartMinutes = queryDateKeys.map(dateKey => {
    const rec = recordsMap.get(dateKey);
    return rec ? Math.round(rec.studySeconds / 60) : 0;
  });
  ```
- **GOTCHA:** `Word` đã import (`:7`), `_calculateDateRange` đã có (`:34`), `userTodayStart`/`userTimezone`/`range` đều trong scope. `statsGrid` là object → gán `.vocabLearned` hợp lệ (const binding, mutate field). `aggregateProgressRecords` vẫn trả `vocabLearned` (reps) nhưng bị override — đó là chủ ý.

### Site 4 — `english_for_community/lib/core/entity/progress_summary_entity.dart` · `StatsGridEntity.fromJson` + `StudyTimeEntity.fromJson` (F3)
- **Locator (anchor) A:** search `vocabLearned: json["vocabLearned"],`
- **BEFORE A (verbatim):**
  ```dart
  factory StatsGridEntity.fromJson(Map<String, dynamic> json) =>
      StatsGridEntity(
        vocabLearned: json["vocabLearned"],
        avgWritingScore: (json["avgWritingScore"] as num).toDouble(),
        readingAccuracy: json["readingAccuracy"],
        dictationAccuracy: json["dictationAccuracy"],
        speakingAccuracy: json["speakingAccuracy"],
        speakingFluency: json["speakingFluency"] ?? 0,
        lessonsCompleted: json["lessonsCompleted"], // ✍️ THÊM VÀO FACTORY
        readingWpm: json["readingWpm"] ?? 0,
      );
  ```
- **AFTER A:**
  ```dart
  factory StatsGridEntity.fromJson(Map<String, dynamic> json) =>
      StatsGridEntity(
        vocabLearned: (json["vocabLearned"] as num?)?.toInt() ?? 0,
        avgWritingScore: (json["avgWritingScore"] as num?)?.toDouble() ?? 0,
        readingAccuracy: (json["readingAccuracy"] as num?)?.toInt() ?? 0,
        dictationAccuracy: (json["dictationAccuracy"] as num?)?.toInt() ?? 0,
        speakingAccuracy: (json["speakingAccuracy"] as num?)?.toInt() ?? 0,
        speakingFluency: (json["speakingFluency"] as num?)?.toInt() ?? 0,
        lessonsCompleted: (json["lessonsCompleted"] as num?)?.toInt() ?? 0,
        readingWpm: (json["readingWpm"] as num?)?.toInt() ?? 0,
      );
  ```
- **Locator (anchor) B:** search `todayMinutes: json["todayMinutes"],`
- **BEFORE B (verbatim):**
  ```dart
  factory StudyTimeEntity.fromJson(Map<String, dynamic> json) =>
      StudyTimeEntity(
        todayMinutes: json["todayMinutes"],
        goalMinutes: json["goalMinutes"],
        totalMinutesInRange: json["totalMinutesInRange"],
        // Chuyển đổi linh hoạt từ int hoặc double
        progressPercent: (json["progressPercent"] as num).toDouble(),
      );
  ```
- **AFTER B:**
  ```dart
  factory StudyTimeEntity.fromJson(Map<String, dynamic> json) =>
      StudyTimeEntity(
        todayMinutes: (json["todayMinutes"] as num?)?.toInt() ?? 0,
        goalMinutes: (json["goalMinutes"] as num?)?.toInt() ?? 0,
        totalMinutesInRange: (json["totalMinutesInRange"] as num?)?.toInt() ?? 0,
        progressPercent: (json["progressPercent"] as num?)?.toDouble() ?? 0,
      );
  ```
- **GOTCHA:** kiểu field không đổi (int/double). Chỉ `StatsGridEntity` + `StudyTimeEntity`; `WeeklyChartEntity`/`CalloutEntity` (string/list) để nguyên.

### Site 5 — `english_for_community/test/progress_summary_entity_test.dart` · 3 test fragility (F3)
- **Locator (anchor):** search `THIẾU readingAccuracy → ném lỗi`
- **BEFORE (verbatim):**
  ```dart
    // --- FRAGILITY (findings): các field còn lại KHÔNG có `?? 0` → thiếu là crash.
    // Test này KHOÁ hành vi hiện tại; nếu sau này thêm guard thì sửa expect thành 0.
    test('THIẾU readingAccuracy → ném lỗi (chưa null-safe, nên hardening)', () {
      final j = validStatsJson()..remove('readingAccuracy');
      expect(() => StatsGridEntity.fromJson(j), throwsA(isA<TypeError>()));
    });

    test('THIẾU avgWritingScore → ném lỗi (cast num trên null)', () {
      final j = validStatsJson()..remove('avgWritingScore');
      expect(() => StatsGridEntity.fromJson(j), throwsA(isA<TypeError>()));
    });

    test('THIẾU vocabLearned/lessonsCompleted → ném lỗi', () {
      expect(
        () => StatsGridEntity.fromJson(validStatsJson()..remove('vocabLearned')),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => StatsGridEntity.fromJson(validStatsJson()..remove('lessonsCompleted')),
        throwsA(isA<TypeError>()),
      );
    });
  ```
- **AFTER:**
  ```dart
    // --- ROBUSTNESS (F3): thiếu field số → default 0, KHÔNG crash.
    test('THIẾU readingAccuracy → default 0 (null-safe)', () {
      final j = validStatsJson()..remove('readingAccuracy');
      expect(StatsGridEntity.fromJson(j).readingAccuracy, 0);
    });

    test('THIẾU avgWritingScore → default 0', () {
      final j = validStatsJson()..remove('avgWritingScore');
      expect(StatsGridEntity.fromJson(j).avgWritingScore, 0);
    });

    test('THIẾU vocabLearned/lessonsCompleted → default 0', () {
      expect(
        StatsGridEntity.fromJson(validStatsJson()..remove('vocabLearned')).vocabLearned,
        0,
      );
      expect(
        StatsGridEntity.fromJson(validStatsJson()..remove('lessonsCompleted')).lessonsCompleted,
        0,
      );
    });
  ```
- **GOTCHA:** các test happy-path còn lại giữ nguyên (giá trị hợp lệ parse y hệt).

### Site 6 — `english_for_community_backend/src/services/progressService.test.js` · 2 test speaking (F1)
- **Locator (anchor):** search `aggregateProgressRecords — speaking: accuracy vs fluency là 2 nguồn khác nhau`
- **BEFORE (verbatim):**
  ```js
  describe('aggregateProgressRecords — speaking: accuracy vs fluency là 2 nguồn khác nhau', () => {
    // Ghi nhận hành vi HIỆN TẠI (xem findings): speakingScore đến từ luồng speaking-set
    // (1-WER), speakingFluency đến từ luồng free-speaking (overall/9). Có thể lệch nhau.
    it('speakingAccuracy và speakingFluency tính độc lập', () => {
      const records = [
        rec(TODAY, {
          stats: {
            speakingScore: stat(0.6, 1), // 60% accuracy (WER)
            speakingFluency: stat(0.8, 1), // 80% (overall band/9)
          },
        }),
      ];
      const { statsGrid } = aggregateProgressRecords(records, bounds('2026-07-01'));
      assert.equal(statsGrid.speakingAccuracy, 60);
      assert.equal(statsGrid.speakingFluency, 80);
    });

    it('chỉ free-speaking (không có speakingScore) → accuracy = 0% dù có fluency', () => {
      // Đây là điểm gây hiểu nhầm: card hiện "0%" to đùng dù học sinh nói rất tốt.
      const records = [
        rec(TODAY, { stats: { speakingFluency: stat(0.85, 1) } }),
      ];
      const { statsGrid } = aggregateProgressRecords(records, bounds('2026-07-01'));
      assert.equal(statsGrid.speakingAccuracy, 0);
      assert.equal(statsGrid.speakingFluency, 85);
    });
  });
  ```
- **AFTER:**
  ```js
  describe('aggregateProgressRecords — speaking: card gộp cả 2 bucket (F1)', () => {
    // Sau F1: speakingAccuracy = trung bình có trọng số của (speakingScore ∪ speakingFluency).
    it('gộp speaking-set (1-WER) + free-speaking (overall/9) vào 1 %', () => {
      const records = [
        rec(TODAY, {
          stats: {
            speakingScore: stat(0.6, 1), // speaking-set
            speakingFluency: stat(0.8, 1), // free-speaking
          },
        }),
      ];
      const { statsGrid } = aggregateProgressRecords(records, bounds('2026-07-01'));
      // (0.6 + 0.8) / (1 + 1) = 0.7 → 70
      assert.equal(statsGrid.speakingAccuracy, 70);
      assert.equal(statsGrid.speakingFluency, 80); // bucket vẫn được trả (backward-compat)
    });

    it('chỉ free-speaking cũng tính vào Speaking % (KHÔNG còn 0%)', () => {
      const records = [
        rec(TODAY, { stats: { speakingFluency: stat(0.85, 1) } }),
      ];
      const { statsGrid } = aggregateProgressRecords(records, bounds('2026-07-01'));
      assert.equal(statsGrid.speakingAccuracy, 85); // trước F1 là 0
      assert.equal(statsGrid.speakingFluency, 85);
    });
  });
  ```
- **GOTCHA:** các describe khác trong file GIỮ NGUYÊN. Chỉ thay block describe speaking này.

### SYMBOL TABLE (verbatim)

| Symbol | Verbatim | Nguồn `file:line` | Trạng thái |
|---|---|---|---|
| `Word` (model) | `mongoose.model('Word', UserWordSchema)`; field khoá user = **`user`**; `status enum ['recent','learning','saved']`; `learningLevel:Number`; `lastReviewedDate:Date` | `models/Word.js` | [CÓ] |
| `_calculateDateRange` | `const _calculateDateRange = (range, timezone) => ({ startDate, endDate })` | `progressService.js:34` | [CÓ] |
| `Word.countDocuments(filter)` | mongoose static → `Promise<number>` | mongoose | [CÓ] |
| `_StatBox.subtitle` | `final String? subtitle;` (optional) | `progress_report_page.dart:848` | [CÓ] |
| `StatsGridEntity` fields | `int vocabLearned; double avgWritingScore; int readingAccuracy/dictationAccuracy/speakingAccuracy/speakingFluency/lessonsCompleted/readingWpm` | `progress_summary_entity.dart:54-73` | [CÓ] |

### CLONE-THIS
- Query vocab distinct: nhái pattern range-query có sẵn ở `getStatDetailData` case `'vocab'` (`progressService.js`) — NHƯNG sửa `userId`→`user` cho đúng schema `Word` (bản gốc đang sai, xem §10).

---

## 6. GATE liên quan

- **Perf:** F2 thêm 1 `Word.countDocuments` mỗi lần load summary — có index `{user:1,status:1}` (`Word.js:25`) phủ `user+status`, range `lastReviewedDate` lọc thêm; 1 query/summary, không N+1. OK.
- **UI/UX:** Chỉ gỡ 1 subtitle optional ở card Speaking — không đổi layout/token/loading-empty-error. Không thêm string. N/A phần lớn.
- **Backend:** Logic ở service (`progressService`), controller mỏng (giữ nguyên). Không schema/migration. Không socket. Query có index.
- **L10n:** N/A — không thêm string. `progressStatFluencyInline` để unused (không xoá).

---

## 7. Verify + Hồi quy tối thiểu (copy-paste)

**Backend:**
```bash
cd english_for_community_backend
node --check src/services/progressService.js
node --test src/services/progressService.test.js   # kỳ vọng: pass hết (speaking 70 & 85)
```
**Frontend:**
```bash
cd english_for_community
dart analyze lib/core/entity/progress_summary_entity.dart lib/feature/progress/progress_report_page.dart
flutter test test/progress_summary_entity_test.dart  # kỳ vọng: pass; 3 test F3 giờ trả 0
```

**Smoke (⭐ = ca nghiệm thu chính):**
1. ⭐ Tài khoản chỉ luyện **free-speaking** (chưa làm speaking-set) → mở Progress → card **Speaking > 0%** (trước đây 0%), **không còn** subtitle "Trôi chảy".
2. ⭐ Ôn 1 từ vựng nhiều lần trong ngày (good/easy nhiều lượt cùng từ) → card **Từ vựng đếm 1** (distinct), không cộng theo số lượt.
3. Tài khoản có cả speaking-set + free-speaking → Speaking % là số hợp lý (trung bình gộp), không NaN/null.
4. (No-regression) Reading/Listening/Writing/Lessons card giữ nguyên giá trị như trước.
5. (Edge) Backend trả thiếu 1 field stat (giả lập) → màn Progress KHÔNG crash, hiện 0.

**Account test:** `docs/dev/seeds/` — student seed.

> Smoke fail sau fix → DỪNG & báo Opus kèm log.

---

## 8. HANDOFF PROMPT cho Cursor/Codex

```text
Bạn là implementer (Cursor/Codex). CHỈ sửa file trong Scope IN; ngoài danh sách → DỪNG & hỏi.
Repo: english_for_community (Flutter) + english_for_community_backend (Node ESM).

BƯỚC 0 — ĐỌC WORK-ORDER TRƯỚC (bắt buộc):
  Mở & đọc HẾT: docs/plantasks/BUG/20260711-progress-6card-fixes/work-order.md
  Code lấy NGUYÊN từ §5 CONTEXT BUNDLE (anchor + BEFORE/AFTER + symbol table) — KHÔNG tự grep đoán.
  File thực tế lệch BEFORE hoặc doc mâu thuẫn prompt → DỪNG & hỏi (doc thắng).

LÀM: theo §5 từng Site (tìm anchor → áp AFTER → xử lý GOTCHA), tôn trọng §4 Scope OUT, §6 GATE.
  - Site 1,3: progressService.js (F1 gộp speaking, F2 override vocab distinct).
  - Site 2: progress_report_page.dart (gỡ subtitle fluency).
  - Site 4: progress_summary_entity.dart (null-safe StatsGrid + StudyTime).
  - Site 5: test/progress_summary_entity_test.dart (lật 3 test F3 → default 0).
  - Site 6: progressService.test.js (2 test speaking → gộp).
TUYỆT ĐỐI KHÔNG: sửa speakingService.js / userController.js / tools/implementations.js;
  xoá l10n progressStatFluencyInline; đổi schema Word/UserDailyProgress; đổi shape JSON statsGrid;
  đụng getStatDetailData; mở rộng sang F4/F5.

VERIFY: chạy §7 (node --check + node --test + dart analyze + flutter test + smoke 1..5). Dán kết quả.
Xong → dán verify/smoke vào chat → báo Opus audit. KHÔNG tự commit/push.
```

---

## 9. Checklist OPUS AUDIT (Phase 4)
- [ ] `git status`/diff: chỉ 5 file Scope IN đổi; speakingService/userController/implementations KHÔNG đụng.
- [ ] Site 1: `speakingAccuracy` dùng `speakingCombined`; `speakingFluency` vẫn được trả.
- [ ] Site 3: query dùng `user` (không `userId`), `status:'learning'`, override 'day' start; `statsGrid.vocabLearned` bị gán sau aggregate.
- [ ] Site 2: chỉ gỡ dòng `subtitle:`; không xoá field/l10n.
- [ ] Site 4: cả `StatsGridEntity` + `StudyTimeEntity` null-safe; kiểu int/double đúng.
- [ ] Site 5 + 6: test cập nhật, **pass** (FE 3 test → 0; BE speaking 70 & 85).
- [ ] §7 verify: `node --test` pass, `flutter test` pass, `dart analyze` 0 lỗi mới; smoke ⭐1,⭐2 đạt.
- [ ] Không placeholder/TODO; không nuốt lỗi.

---

## 10. Follow-up
> ✅ 3 mục dưới ĐÃ XỬ LÝ luôn trong session này (Opus tự code, user cho phép) — verify: `node --check` OK, `node --test` 13/13, `dart analyze` 0 issue. Runtime smoke chờ máy thật.
- ✅ **[BUG] vocab detail rỗng:** `getStatDetailData` — thêm `userField = 'user'` cho vocab (+ `status:'learning'` khớp card). Trước đây query `userId` → list rỗng.
- ✅ **F4:** `_calculateTotalGoalMinutes` — mẫu số = `dailyGoal × số ngày đã trôi` (week=`now.weekday`, month=`now.day`); bỏ `_daysInMonth`.
- ✅ **F5:** `getSummaryData.progressPercent` — theo range (`totalMinutesInRange / (dailyGoal × rangeDays)`). Đã grep: chỉ `progress/summary` (page bỏ qua field) đọc getSummaryData; `user.progressSummary` do `userController` tính riêng → KHÔNG bị ảnh hưởng.

**Còn treo (chưa làm — cần schema/migration):**
- **Vocab "đã học" chính xác:** schema `Word` thiếu mốc "học xong" (không có status 'learned'/`learnedAt`). Muốn card đúng nghĩa "số từ THUỘC" thì cần thêm trạng thái tốt nghiệp + `learnedAt` (schema change + migration).
