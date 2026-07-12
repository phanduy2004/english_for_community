# Work-Order — BUG: Learning Progress — card "Bài học" ≠ danh sách & filter không khớp trên detail

- **Task ID:** `20260711-progress-lesson-count-range`
- **Loại:** BUG · **Platform:** backend (student mobile đọc) · **Cỡ:** T1 (backend-only)
- **Mục tiêu:** (F6) Con số card "Bài học hoàn thành" LUÔN bằng số dòng khi bấm vào (hết cảnh 8 vs 7). (F7) Bộ lọc Ngày/Tuần/Tháng áp cho card & danh sách chi tiết trên CÙNG một khoảng thời gian.
- **Người phân tích + implement:** Opus (user cho phép code trong session). **Status:** IMPLEMENTED — unit + node --check PASS; smoke chờ máy thật.
- **Liên quan:** nối tiếp `20260711-progress-6card-fixes` (F1–F5). Quyết định nghiệp vụ: user chọn **"card = số bài trong danh sách"** (đếm distinct doc bài học đã hoàn thành; làm lại tính 1; luyện nói tự do không tính là "bài học").

---

## 1. Vấn đề + nguyên nhân gốc (dẫn chứng code)

**F6 — Card "Bài học hoàn thành" (8) ≠ số dòng danh sách (7).**
- Card đọc `statsGrid.lessonsCompleted` = tổng **counter sự kiện** `lessonsCompleted.{listening,reading,speaking,writing}` (`progressService.js:140-143` cộng từ `UserDailyProgress`). Counter được `$inc` mỗi lần `isLessonJustFinished` (`progressTracker.js:29,44,54,66`).
- Danh sách chi tiết (`getStatDetailData` nhánh `isLessonMode`, `progressService.js:265-292`) lại **liệt kê document nguồn**: `ReadingProgress(status:completed)`, `WritingSubmission(status:reviewed)`, `SpeakingEnrollment(isCompleted)`, `Enrollment(isCompleted)`, `ListeningCompAttempt(mọi attempt)`.
- **2 nguồn lệch nhau theo cấu trúc** ⇒ card ≠ list:
  - **Luyện nói tự do** `speakingService.js:662-666` gọi `trackUserProgress('speaking',{isLessonJustFinished:true})` → counter `speaking` +1 **nhưng KHÔNG tạo `SpeakingEnrollment`** → có ở card, KHÔNG có ở list. (card > list)
  - **Writing** counter +1 khi nộp (`writingTopicService.js:225-228` `isLessonJustFinished:true`); list lessons lọc `status:'reviewed'` → bài chưa chấm bị loại. (card > list)
  - **Làm lại** 1 bài reading/dictation → counter +1 mỗi lần, list chỉ 1 dòng (1 enrollment/progress doc). (card > list)
  - Ngược lại **Comprehension** làm lại → list hiện mỗi attempt, counter chỉ +1 lần đầu (`listeningCompService.js:136 previousAttempts===0`). (list > card)

**F7 — Bộ lọc không khớp giữa card và detail (đặc biệt 'day').**
- Range **có** truyền xuống backend đúng: FE `progress_report_page.dart:126,446-480` → `StatDetailDialog` → `FetchStatDetail(statKey,range)` → `GET /progress/detail?range=` → `getStatDetailData(userId,statKey,range)`. Bloc KHÔNG cache detail (`progress_bloc.dart:90-123` luôn fetch tươi). ⇒ **không phải lỗi FE**.
- Lỗi là **ngữ nghĩa range lệch nhau** trong `progressService.js`:
  - Card (stats/vocab) 'day' = **chỉ hôm nay** (`getSummaryData:197` `startDateString = range==='day' ? todayString : ...`; vocab override `:221` `range==='day' ? userTodayStart`).
  - Detail 'day' = **7 ngày** (`_calculateDateRange:41-43` `startDate = userTodayStart - 6 ngày`).
  - ⇒ chọn "Ngày": card ra số nhỏ (hôm nay) còn list ra 7 ngày → "nhấn vào vẫn thấy nhiều bài". Week/month thì start khớp nên đỡ lộ.

---

## 2. Audit downstream (consumer `statsGrid.lessonsCompleted` — override có an toàn?)

> Grep `statsGrid.lessonsCompleted` / `.lessonsCompleted` toàn repo (bỏ test).

| Điểm | file:line | Nguồn | Ảnh hưởng |
|---|---|---|---|
| Card Progress | `progress_report_page.dart:464` | `getSummaryData.statsGrid.lessonsCompleted` | **ĐÍCH sửa** — nhận số mới (= list). |
| Admin user detail | `admin_user_details_dialog.dart:271` | endpoint admin `userController.getUserDetailsForAdmin` (tính riêng `totalLessons`, `userController.js:44-47,77`) | **KHÔNG đổi** — khác endpoint. |
| AI tools | `tools/implementations.js:518-521,880-881,1000-1003` | đọc **raw** `rec.lessonsCompleted.*` từ `UserDailyProgress` | **KHÔNG đổi** — không đọc statsGrid. |
| userController home | `userController.js:44-47,193-196` | raw records | **KHÔNG đổi**. |
| Pure test | `progressService.test.js:134-142` | `aggregateProgressRecords(...).statsGrid.lessonsCompleted===7` | **KHÔNG đổi** — vẫn giữ `lessonsSum` trong pure fn; override ở `getSummaryData`. |

**Kết luận:** override `statsGrid.lessonsCompleted` trong `getSummaryData` (giống pattern F2 vocab) chỉ chạm đúng card Progress; write-path + consumer raw + admin + pure test đều KHÔNG bị ảnh hưởng.

---

## 3. Hướng fix (thiết kế) + quyết định

**Nguyên tắc:** *con số trên card = số dòng khi bấm vào, cùng một khoảng thời gian.* ⇒ card & detail phải lấy từ **cùng 1 nguồn** trên **cùng 1 range**.

- **F6 — tách hàm dùng chung `_fetchCompletedLessons(userId, startDate, endDate)`** trả về đúng mảng item mà detail `isLessonMode` đang dựng (logic bê nguyên, chạy song song `Promise.all`). Dùng cho CẢ HAI:
  - `getStatDetailData` (isLessonMode): `queryResult = await _fetchCompletedLessons(...)` — hành vi list **giữ y nguyên** (chỉ nhanh hơn).
  - `getSummaryData`: `statsGrid.lessonsCompleted = (await _fetchCompletedLessons(...)).length`.
  - ⇒ card == số dòng **theo cấu trúc** (cùng rows), không thể drift.
- **F7 — sửa `_calculateDateRange('day')` = CHỈ hôm nay** (bỏ nhánh −6 ngày). Card lessons/vocab và detail cùng gọi `_calculateDateRange(range)` ⇒ chung `[startDate,endDate]` cho cả day/week/month. %-card 'day' (=today qua `startDateString`) cũng khớp detail 'day' (=today).
- Vocab card 'day' bỏ ternary override (`_calculateDateRange('day')` đã = today) → gọn.
- **Loại** phương án "đổi write-path/counter": counter còn dùng bởi AI tools + userController (raw) → rủi ro; và không thể tái dựng lịch sử từng lượt cho reading/dictation để list khớp counter. Đọc-gộp an toàn hơn.

**Cảnh báo:** card lessons giờ **KHÔNG** đếm buổi luyện nói tự do (đúng lựa chọn user — không có "bài" trong list). Perf: `getSummaryData` chạy thêm 5 query (song song) — xem §6.

---

## 4. Scope IN / OUT

**IN:**
- `english_for_community_backend/src/services/progressService.js` — F7 (`_calculateDateRange`), thêm `_fetchCompletedLessons`, F6 (getSummaryData override lessons + gộp range vocab), refactor isLessonMode dùng helper.
- `english_for_community_backend/src/services/progressService.summary.test.js` — mock 5 model lesson cho test cũ + thêm test F6 (card==list) & F7.

**OUT (chạm là DỪNG & hỏi):**
- ❌ `progressTracker.js`, `speakingService.js`, `writingTopicService.js`, các controller ghi stats — GIỮ write-path counter.
- ❌ `aggregateProgressRecords` (pure) — giữ `lessonsSum` (test + có thể tái dùng); chỉ override ở getSummaryData.
- ❌ `_getDateRangeConfig` (chart 'day' vẫn 7 bar — context nhìn, không phải "count"). Ghi nhận là inconsistency nhỏ ngoài scope.
- ❌ Frontend (không cần đổi — số + range đều do backend).
- ❌ userController / tools/implementations / admin dialog.

---

## 5. CONTEXT BUNDLE ⭐

### Site 1 — `progressService.js` · `_calculateDateRange` (F7)
- **Anchor:** `// "day" tab chart = 7 ngày — detail log phải khớp`
- **BEFORE (verbatim):**
  ```js
  let startDate = userTodayStart;

  // "day" tab chart = 7 ngày — detail log phải khớp (trước đây chỉ hôm nay → list trống dù stats có %).
  if (range === 'day') {
    startDate = new Date(userTodayStart.getTime() - 6 * 24 * 60 * 60 * 1000);
  } else if (range === 'week') {
    const { weekday } = _userWeekdayAndDate(userTodayStart, timezone);
    const offset = (weekday === 0) ? 6 : weekday - 1;
    startDate = new Date(userTodayStart.getTime() - offset * 24 * 60 * 60 * 1000);
  } else if (range === 'month') {
    const { dayOfMonth } = _userWeekdayAndDate(userTodayStart, timezone);
    startDate = new Date(userTodayStart.getTime() - (dayOfMonth - 1) * 24 * 60 * 60 * 1000);
  }
  ```
- **AFTER:**
  ```js
  let startDate = userTodayStart;

  // 'day' = CHỈ hôm nay (khớp card + nhãn "Hôm nay"). Trước đây detail lấy 7 ngày →
  // bấm vào card ra nhiều bài hơn con số hiển thị. week/month = từ đầu kỳ tới hết hôm nay.
  if (range === 'week') {
    const { weekday } = _userWeekdayAndDate(userTodayStart, timezone);
    const offset = (weekday === 0) ? 6 : weekday - 1;
    startDate = new Date(userTodayStart.getTime() - offset * 24 * 60 * 60 * 1000);
  } else if (range === 'month') {
    const { dayOfMonth } = _userWeekdayAndDate(userTodayStart, timezone);
    startDate = new Date(userTodayStart.getTime() - (dayOfMonth - 1) * 24 * 60 * 60 * 1000);
  }
  ```

### Site 2 — `progressService.js` · thêm helper `_fetchCompletedLessons` (đặt sau `_getDateRangeConfig`, trước `aggregateProgressRecords`)
- **Anchor chèn:** trước dòng `// --- Pure aggregation (không đụng DB → test bằng node:test) ---`
- **THÊM:**
  ```js
  // Danh sách "bài học đã hoàn thành" trong [startDate, endDate] — NGUỒN CHUNG cho:
  //   • card "Bài học hoàn thành" (getSummaryData: .length)
  //   • dialog chi tiết Lessons (getStatDetailData isLessonMode: liệt kê)
  // ⇒ con số trên thẻ LUÔN bằng số dòng danh sách. Gộp Dictation + Comprehension vào
  // nhóm Listening (giữ đúng hành vi cũ của detail). Chạy song song cho nhanh.
  const _fetchCompletedLessons = async (userId, startDate, endDate) => {
    const dateRange = { $gte: startDate, $lte: endDate };

    const [readings, writings, speakings, dictations, comprehensions] = await Promise.all([
      ReadingProgress.find({ userId, status: 'completed', lastAttemptedAt: dateRange })
        .populate('readingId', 'title').select('lastAttemptedAt readingId highScore').lean(),
      WritingSubmission.find({ userId, status: 'reviewed', submittedAt: dateRange })
        .select('generatedPrompt.title submittedAt score').lean(),
      SpeakingEnrollment.find({ userId, isCompleted: true, lastAccessedAt: dateRange })
        .populate('speakingSetId', 'title').select('lastAccessedAt speakingSetId averageWer').lean(),
      Enrollment.find({ userId, isCompleted: true, lastAccessedAt: dateRange })
        .populate('listeningId', 'title').select('lastAccessedAt listeningId progress').lean(),
      ListeningCompAttempt.find({ userId, createdAt: dateRange })
        .populate('listeningId', 'title').select('createdAt listeningId score').lean(),
    ]);

    const items = [];
    readings.forEach(r => items.push({ original: r, type: 'Reading', date: r.lastAttemptedAt, title: r.readingId?.title, score: r.highScore || 0 }));
    writings.forEach(w => items.push({ original: w, type: 'Writing', date: w.submittedAt, title: w.generatedPrompt?.title, score: w.score || 0 }));
    speakings.forEach(s => items.push({ original: s, type: 'Speaking', date: s.lastAccessedAt, title: s.speakingSetId?.title, score: Math.round((1 - (s.averageWer || 0)) * 100) }));
    dictations.forEach(l => items.push({ original: l, type: 'Dictation', date: l.lastAccessedAt, title: l.listeningId?.title, score: Math.round((l.progress || 0) * 100) }));
    comprehensions.forEach(c => items.push({ original: c, type: 'Comprehension', date: c.createdAt, title: c.listeningId?.title, score: Math.round(c.score || 0) }));

    items.sort((a, b) => b.date - a.date);
    return items;
  };
  ```

### Site 3 — `progressService.js` · `getSummaryData` gộp range + override lessons (F6/F7)
- **Anchor:** `const { startDate: vocabRangeStart, endDate: vocabRangeEnd } =`
- **BEFORE (verbatim):**
  ```js
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
  ```
- **AFTER:**
  ```js
  // Vocab + Lessons dùng CHUNG [rangeStart, rangeEnd] với danh sách chi tiết
  // (getStatDetailData → _calculateDateRange) ⇒ con số trên thẻ LUÔN khớp list.
  const { startDate: rangeStart, endDate: rangeEnd } =
    _calculateDateRange(range, userTimezone);

  // F2: "Từ vựng" = số từ DISTINCT đã ôn trong range (field `user`, KHÔNG phải userId).
  statsGrid.vocabLearned = await Word.countDocuments({
    user: userId,
    status: 'learning',
    lastReviewedDate: { $gte: rangeStart, $lte: rangeEnd },
  });

  // F6: "Bài học hoàn thành" = ĐÚNG số dòng danh sách chi tiết (đếm doc bài học thật đã
  // hoàn thành trong range), KHÔNG dùng counter lessonsCompleted.* (counter cộng cả luyện
  // nói tự do + mỗi lần làm lại → lệch list, gây "8 vs 7"). Dùng chung _fetchCompletedLessons
  // với detail nên card == list.
  statsGrid.lessonsCompleted = (await _fetchCompletedLessons(userId, rangeStart, rangeEnd)).length;
  ```
- **GOTCHA:** `userTodayStart` vẫn dùng ở `todayString` (`:193`) → không thành biến thừa. `aggregateProgressRecords` vẫn trả `lessonsCompleted: lessonsSum` (bị override sau — chủ ý, như vocab).

### Site 4 — `progressService.js` · `getStatDetailData` isLessonMode dùng helper (F6)
- **Anchor:** `if (isLessonMode) {`
- **BEFORE (verbatim):** (khối 5 query + forEach + sort — `progressService.js:265-292`)
  ```js
  if (isLessonMode) {
    const readings = await ReadingProgress.find({
      userId, status: 'completed', lastAttemptedAt: { $gte: startDate, $lte: endDate }
    }).populate('readingId', 'title').select('lastAttemptedAt readingId highScore').lean();
    readings.forEach(r => queryResult.push({ original: r, type: 'Reading', date: r.lastAttemptedAt, title: r.readingId?.title, score: r.highScore || 0 }));

    const writings = await WritingSubmission.find({
      userId, status: 'reviewed', submittedAt: { $gte: startDate, $lte: endDate }
    }).select('generatedPrompt.title submittedAt score').lean();
    writings.forEach(w => queryResult.push({ original: w, type: 'Writing', date: w.submittedAt, title: w.generatedPrompt?.title, score: w.score || 0 }));

    const speakings = await SpeakingEnrollment.find({
      userId, isCompleted: true, lastAccessedAt: { $gte: startDate, $lte: endDate }
    }).populate('speakingSetId', 'title').select('lastAccessedAt speakingSetId averageWer').lean();
    speakings.forEach(s => queryResult.push({ original: s, type: 'Speaking', date: s.lastAccessedAt, title: s.speakingSetId?.title, score: Math.round((1 - (s.averageWer || 0)) * 100) }));

    // 🔥 1. GỘP CẢ DICTATION VÀ COMPREHENSION VÀO "LISTENING" TRONG CHẾ ĐỘ LESSONS
    const dictations = await Enrollment.find({
      userId, isCompleted: true, lastAccessedAt: { $gte: startDate, $lte: endDate }
    }).populate('listeningId', 'title').select('lastAccessedAt listeningId progress').lean();
    dictations.forEach(l => queryResult.push({ original: l, type: 'Dictation', date: l.lastAccessedAt, title: l.listeningId?.title, score: Math.round((l.progress || 0) * 100) }));

    const comprehensions = await ListeningCompAttempt.find({
      userId, createdAt: { $gte: startDate, $lte: endDate }
    }).populate('listeningId', 'title').select('createdAt listeningId score').lean();
    comprehensions.forEach(c => queryResult.push({ original: c, type: 'Comprehension', date: c.createdAt, title: c.listeningId?.title, score: Math.round(c.score || 0) }));

    queryResult.sort((a, b) => b.date - a.date);

  } else if (statKey === 'dictation' || statKey === 'listening') {
  ```
- **AFTER:**
  ```js
  if (isLessonMode) {
    // Dùng CHUNG với card "Bài học hoàn thành" (getSummaryData) → số trên thẻ == số dòng.
    queryResult = await _fetchCompletedLessons(userId, startDate, endDate);

  } else if (statKey === 'dictation' || statKey === 'listening') {
  ```
- **GOTCHA:** Khối format phía dưới (`item.original/date/title/type/score`) KHÔNG đổi — shape helper khớp. `let queryResult = []` giữ nguyên (được gán lại).

### SYMBOL TABLE
| Symbol | Verbatim | Nguồn | Trạng thái |
|---|---|---|---|
| Models | `ReadingProgress, WritingSubmission, SpeakingEnrollment, Enrollment, Word, ListeningCompAttempt` | import `progressService.js:2-9` | [CÓ] |
| `_calculateDateRange` | `(range, timezone) => ({ startDate, endDate })` | `:34` | [CÓ] |
| `_fetchCompletedLessons` | `(userId, startDate, endDate) => Promise<Array<{original,type,date,title,score}>>` | mới | [THÊM] |
| filter fields | Reading `status:'completed'/lastAttemptedAt`; Writing `status:'reviewed'/submittedAt`; Speaking/Enrollment `isCompleted/lastAccessedAt`; Comp `createdAt` | detail cũ | [CÓ] |

---

## 6. GATE

- **Backend/Perf:** `getSummaryData` thêm 5 query lesson (song song `Promise.all`) mỗi lần load summary (mở trang + đổi filter). Bằng đúng chi phí khi bấm card Lessons trước đây; có index `userId` trên các collection. 1 lần/summary, không N+1, không loop. Chấp nhận cho màn Progress. (Tối ưu sâu hơn = countDocuments-only, defer.)
- **UI/UX:** N/A (backend-only; card/list layout giữ nguyên, có empty-state khi list rỗng).
- **L10n:** N/A.

---

## 7. Verify + Hồi quy tối thiểu

**Backend:**
```bash
cd english_for_community_backend
node --check src/services/progressService.js
node --test src/services/progressService.summary.test.js   # F6 card==list + F7
node --test src/services/progressService.test.js            # pure fn giữ nguyên (lessons=7)
node --test                                                 # toàn bộ pure-logic, no-regression
```

**Smoke (⭐ ca nghiệm thu):**
1. ⭐ Mở Progress (Tuần) → đếm số dòng khi bấm card "Bài học" == con số trên card.
2. ⭐ Đổi filter Ngày/Tuần/Tháng → con số card đổi VÀ bấm vào list ra đúng khoảng đó (Ngày = chỉ hôm nay).
3. Tài khoản có luyện nói tự do → card Lessons KHÔNG cộng buổi tự do (chỉ đếm bài trong list).
4. (No-regression) Card % (Reading/Listening/Speaking/Writing) + Vocab giữ giá trị hợp lý; list các card đó khớp khoảng lọc (Ngày = hôm nay).

**Account test:** `docs/dev/seeds/` — student seed.

---

## 8. HANDOFF (nếu giao Cursor) / 9. OPUS AUDIT

Xem tracker. Checklist audit:
- [ ] Chỉ 2 file Scope IN đổi; write-path/counter/aggregateProgressRecords KHÔNG đụng.
- [ ] `_calculateDateRange('day')` = today (bỏ nhánh −6 ngày).
- [ ] `getSummaryData.statsGrid.lessonsCompleted` = `_fetchCompletedLessons(...).length`, dùng chung rangeStart/rangeEnd với vocab.
- [ ] `getStatDetailData` isLessonMode gọi `_fetchCompletedLessons` — format phía dưới không đổi.
- [ ] Test: summary.test.js mock 5 model, F6 (card==list) + no-regression cũ pass; pure test lessons=7 vẫn pass.
