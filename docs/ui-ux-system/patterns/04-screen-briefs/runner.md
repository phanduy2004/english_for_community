# Screen Brief — Runner / Focused task (student)

> Áp blueprint **A3 · Runner / Focused task** ([`../01-screen-archetypes.md`](../01-screen-archetypes.md)) vào màn thật.
> **Màn:** Runner làm bài (ví dụ **exam runner**) · **File:** `lib/feature/student/exams/exam_runner_page.dart` (+ biến thể `integrated_exam_runner_page.dart`, helper `StudentMobileUi.mcqPagerHeader/mcqQuestionPager/mcqOption/bottomActionBar/runnerPopScope`).
> **Trạng thái:** chạy được; option states đã dùng **semantic info/success/danger** đúng (`student_mobile_ui.dart:1062`), CTA đã **primary** (`exam_runner_page.dart:849`). Brief này lo phần **tối giản chrome + exit-guard chuẩn hoá** — gom về helper dùng chung thay vì dựng tay.
> **Tổng quát hoá:** cùng khung cho MCQ / dictation / speaking runner (chỉ đổi body + skill accent line); ở đây minh hoạ bằng exam runner (mcq_single/multi, fill_blank, essay).

---

## 1. Hiện trạng (đo theo token)

```
┌──────────────────────────────────────────┐  appBar h=46, surface, BACK ‹ (không phải ✕)
│ ‹  Bài kiểm tra            Còn lại: 4:12  │  StudentMobileUi.appBar + remaining (caption, phải)  :685
│                                            │
│  Câu 3 / 12                       (caption) │  progress text  :719
│   ↕ 8                                       │
│  ███████████░░░░░░░░░  (line, listening)    │  LinearProgressIndicator, color=skill  :735
│   padding LTRB(24,12,24,0)                  │  ← chrome riêng, KHÔNG dùng mcqPagerHeader  :714
│ ┌────────────────────────────────────────┐│
│ │ (AppCard outline)                       ││  pagePadding = LTRB(12,10,12,20)  :801
│ │ Stem câu hỏi…              (cardTitle)  ││
│ │   ↕ cardGap(8)                          ││
│ │ ┌────────────────────────────────────┐ ││  mcqOption (single/multi)  :526
│ │ │ A.  đáp án          [info nếu chọn] │ ││   selected→infoBg/info  :1072
│ │ │ B.  đáp án          [success/danger]│ ││   review→successBg/dangerBg  :1062
│ │ └────────────────────────────────────┘ ││
│ └────────────────────────────────────────┘│
│ ┌────────────────────────────────────────┐│  bottom bar TỰ DỰNG (Container+Row)  :817
│ │ Câu 3/12 (cardTitle)   [‹Trước][Tiếp ▸]││  FilledButton primary/onPrimary  :843
│ └────────────────────────────────────────┘│  padding s5/s4 + safe-area bottom  :823
└──────────────────────────────────────────┘
```

**Đo:** top bar (back + remaining) → progress block `padding(24,12,24,0)` + `8` + line → body `pagePadding(12,10,12,20)` → bottom bar `s5/s4`. Exit-guard = **`PopScope` viết tay** (`:669`) gọi `confirmRunnerExit` (`:677`), KHÔNG dùng `runnerPopScope`. Body swipe qua `mcqQuestionPager` (`:793`); loading = `runnerLoading()` (`:703`).

### Đánh giá
| ✅ Giữ | ⚠️ Sửa |
|--------|--------|
| Option states **semantic** info/success/danger, KHÔNG skill (`student_mobile_ui.dart:1062`–`1076`) | **Progress block tự dựng** (`:714`–`:744`) thay vì `mcqPagerHeader` → lệch padding (`24` vs `pageHPadding 12`) & không có `%` chuẩn (`:989`) |
| CTA = **primary (đen)** + minSize 44 (`exam_runner_page.dart:843`–`851`) | **Bottom bar tự dựng** (`:817`–`:860`) lặp lại y hệt `bottomActionBar` helper (`:898`) — bỏ lỡ loading spinner sẵn có (`:928`) |
| Loading = `runnerLoading()` skeleton, không spinner (`:703`) | **Exit-guard viết tay** `PopScope` (`:669`) lặp logic `runnerPopScope` (`:849`); dễ lệch khi sửa |
| Progress line = **skill accent** (`AppSkillColors.listening.color`, `:739`) đúng quy ước A3 | Header **không có ✕** (chỉ back ‹); A3 yêu cầu nút thoát rõ + remaining gắn vào header progress |
| `mcqQuestionPager` swipe 1 câu/màn (`:793`) + haptic (`:324`) | Review (locked) render `ListView` riêng (`:747`) — ổn nhưng tách khỏi khung pager, 2 nhánh layout |

---

## 2. Target layout (refined) — chrome mỏng, exit rõ, 1 CTA

Theo A3 (Duolingo/Quizlet): **top = ✕ + progress 1 hàng + line mảnh**, body prompt+media+options, **sticky bottom 1 CTA**, exit-guard khi đang làm.

```
TRƯỚC (chrome tự dựng)                 SAU (helper-driven, A3-clean)
┌───────────────────────────┐          ┌───────────────────────────┐
│ ‹ Bài KT       Còn 4:12   │          │ ✕  Bài KT          4:12   │  appBar: ✕ thoát + remaining
│ Câu 3 / 12                 │          │ 3 / 12               45%  │  mcqPagerHeader (1 hàng, %)
│ ███████░░░ (line 24px pad)│          │ ███████░░░ (line skill)   │  line skill accent, pad=pageH
│ ┌───────────────────────┐ │          │ ┌───────────────────────┐ │
│ │ Stem…                  │ │          │ │ Stem…                  │ │  body: prompt + media
│ │ A. ◻  B. ◻             │ │          │ │ A. ◻  B. ◻ (info/✓/✗) │ │  mcqOption semantic
│ └───────────────────────┘ │          │ └───────────────────────┘ │
│ ┌───────────────────────┐ │          │ ┌───────────────────────┐ │
│ │Câu 3/12 [‹][Tiếp ▸]   │ │          │ │ Câu 3/12     [ Tiếp ▸ ]│ │  bottomActionBar helper
│ └───────────────────────┘ │          │ └───────────────────────┘ │  (loading spinner sẵn)
└───────────────────────────┘          └───────────────────────────┘
  PopScope tự viết                      runnerPopScope(blockExit:…)
```

### Zones (target)
| Zone | Nội dung | Token / widget | Ghi chú |
|------|----------|----------------|---------|
| Top bar | `✕` exit + tiêu đề + remaining | `appBar(showBack:…)`; remaining = `caption` (`:696`) | nút thoát rõ ràng; remaining chỉ khi `in_progress` |
| Progress | `3 / 12 … 45%` + line | `mcqPagerHeader` (`:989`) + `LinearProgressIndicator` | text căn padding `pageHPadding`; line color = **skill accent** (`AppSkillColors`) |
| Body | prompt/stem + media + options | `mcqQuestionPager` (`:1015`) + `AppCard(outline)` + `mcqOption` (`:1043`) | 1 câu/màn, swipe; fill_blank/essay = `TextField` |
| Option states | chọn / đúng / sai | `infoBg`+`info` · `successBg`+`success` · `dangerBg`+`danger` | **semantic, KHÔNG skill** (`:1062`–`1076`) |
| Bottom CTA | `Câu n/N` + `Tiếp/Nộp` | `bottomActionBar` (`:898`) — `FilledButton` **primary/onPrimary** | 1 CTA chính; loading spinner khi submit |
| Exit guard | confirm khi đang làm | `runnerPopScope(blockExit:…)` (`:849`) | thay `PopScope` tay; `onConfirmedExit` dọn realtime |

> **Màu (A3):** option = **semantic** info/success/danger; CTA = **primary (đen)**; progress line = **skill accent** (`AppSkillColors.listening.color` hiện tại); **amber chỉ ở result/celebrate (A11)** — không xuất hiện trong runner.

---

## 3. Build diff (đường dẫn cụ thể cho Cursor)

File: `exam_runner_page.dart`, `build()` (`:651`–`:865`):

1. **Top bar → `✕` + remaining**: giữ `StudentMobileUi.appBar` (`:685`) nhưng đặt leading thành nút thoát (icon `close`) gọi `Navigator.maybePop` (để `PopScope` xử confirm), giữ `actions` remaining (`:689`). Lý do: A3 cần "thoát rõ", không phải back ngầm.
2. **Progress block → `mcqPagerHeader`**: thay `Padding(24,12,24,0)` + `Text(questionProgress)` + `SizedBox(8)` (`:714`–`:723`) bằng
   ```dart
   StudentMobileUi.mcqPagerHeader(context, current: _itemIndex + 1, total: flat.length),
   ```
   rồi đặt `LinearProgressIndicator` (giữ `color: AppSkillColors.listening.color`, `backgroundColor: AppColors.outlineMuted`, radius `AppRadius.xs`, `:735`–`:740`) ngay dưới với padding `pageHPadding`. Giữ `TweenAnimationBuilder` cho animate (`:724`).
3. **Bottom bar → `bottomActionBar` helper**: thay Container+Row tự dựng (`:817`–`:860`) bằng
   ```dart
   StudentMobileUi.bottomActionBar(
     context: context,
     progressLabel: l10n.studentExamQuestionProgress(_itemIndex + 1, flat.length),
     ctaLabel: _itemIndex < lastIndex ? l10n.studentExamNext : l10n.studentExamSubmit,
     onCta: _itemIndex < lastIndex ? () => _goToIndex(_itemIndex + 1) : _submit,
     loading: _submitting, // thêm cờ để dùng spinner sẵn (:928)
   );
   ```
   Nút "‹ Trước" (`:837`) là CTA cạnh tranh → bỏ khỏi bar, chuyển sang swipe pager (đã có, `:793`) hoặc giữ như icon phụ ngoài bar nếu cần (A3 §Don't: "đừng nhiều CTA cạnh tranh").
4. **Exit-guard → `runnerPopScope`**: thay `PopScope`(`:669`)+`onPopInvokedWithResult`(`:671`) bằng bọc Scaffold trong
   ```dart
   StudentMobileUi.runnerPopScope(
     context: context,
     blockExit: _blocksExitConfirm(), // :638
     onConfirmedExit: () { _clearRealtimeOnExit(); Navigator.of(context).pop(); }, // :643
     child: Scaffold(…),
   );
   ```
   Giữ nhánh `didPop` dọn realtime: gọi `_clearRealtimeOnExit()` khi `canPop` true (chuyển vào logic gọi hoặc giữ `PopScope` ngoài cho nhánh đó nếu helper chưa expose `onDidPop`).
5. **Giữ nguyên**: `mcqQuestionPager` (`:793`), `_buildItemCard`/`_buildReviewItemCard` (`:511`/`:366`), `mcqOption` semantic (`:526`,`:555`), loading `runnerLoading()` (`:703`), `errorRetry` (`:705`), ticker/deadline auto-submit (`:135`), `ExamLiveSessionGuard` bind/unbind (`:171`).
6. **Spacing mới**: appBar(46) → `mcqPagerHeader` (`s3`/`s2` nội tại, `:996`) → line → body `pagePadding` → `bottomActionBar` (`s4`/`s3` + safe-area, `:907`). Bỏ pad `24` lệch token.

> Không đụng `student_mobile_ui.dart` (helper dùng chung — `integrated_exam_runner_page.dart` đã dùng `bottomActionBar`/`confirmRunnerExit`, `:1575`,`:1563`). Không đổi semantic option color sang skill.

---

## 4. States (đã có — kiểm lại + chuẩn hoá)
- **In-progress (exit guard)** → `_blocksExitConfirm()==true` khi `status=='in_progress'` (`:638`) → `runnerPopScope(blockExit:true)` chặn + `confirmRunnerExit` dialog (`:826`). Confirm xong → `_clearRealtimeOnExit()` (`:643`) + pop.
- **Loading** → `StudentMobileUi.runnerLoading()` skeleton câu hỏi (`:703`, `=runnerQuestion()`), KHÔNG spinner full-màn.
- **Review (locked: submitted/expired)** → render `_buildReviewItemCard` (`:366`) với `mcqOption(onTap:null)`; dùng `showReviewCorrect`/`showReviewWrong` (`:1051`) → `successBg`/`dangerBg` (`:1062`). Bottom bar ẩn (`if (!locked …)`, `:817`).
- **Submit → result** → `_submit()` (`:340`) persist → `submitExamAttempt` → set `_attempt`, `unbind` live guard (`:354`), `AppFeedback.success` (`:355`). CTA "Nộp" nên dùng `bottomActionBar(loading:true)` trong lúc gọi. (Result/score summary tại `:768`,`:499`; celebrate đầy đủ → A11.)
- **Deadline** → ticker `_maybeStartTicker` (`:109`) → quá hạn auto `submitExamAttempt(force:true)` (`:135`).
- **Error** → `StudentMobileUi.errorRetry` + `onRetry: _load` (`:705`).

## 5. Checklist
- [ ] Top bar: nút **✕ thoát** rõ + remaining (caption) chỉ khi `in_progress`.
- [ ] Progress dùng **`mcqPagerHeader`** (có `%`), line = **skill accent**, padding `pageHPadding` (bỏ `24`).
- [ ] Bottom = **`bottomActionBar`** helper, **1 CTA primary**; bỏ nút "Trước" cạnh tranh (dùng swipe).
- [ ] Exit-guard = **`runnerPopScope(blockExit:_blocksExitConfirm())`**; vẫn dọn realtime (`_clearRealtimeOnExit`).
- [ ] Option states = **semantic** info/success/danger (0 skill color); CTA = primary (đen); amber không có trong runner.
- [ ] States đủ: in-progress guard / `runnerLoading` / review correct-wrong / submit→result.
- [ ] `dart analyze lib/feature/student/exams` **0 lỗi mới**.
- [ ] Xem 360×640: 1 câu/màn, thoát có confirm, CTA dính đáy trên bàn phím (fill_blank/essay).

> Áp xong ghi vào [`../../11-implementation-mapping.md`](../../11-implementation-mapping.md) "Migration log".
