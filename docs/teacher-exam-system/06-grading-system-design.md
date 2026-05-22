# 06 — Grading System Design (Auto + AI + Manual)

## 1) Goals

- Produce a **fair, explainable** score for mixed exams.
- Support three pipelines:
  1. **Auto** — objective items (MCQ, fill-blank with accepted answers).
  2. **AI-assisted** — essay + speaking (draft score + rationale).
  3. **Manual** — teacher override, rubric-based scoring, per-item feedback.

> **Ghi chú (VI)**: AI chỉ là “bản nháp”; policy nên cho phép giáo viên khóa điểm cuối cùng trước khi publish.

## 2) Grading states

On `ExamAttempt`:

| `gradingState` | Meaning |
|----------------|---------|
| `pending_auto` | Objective not finalized |
| `pending_ai` | Waiting AI job |
| `pending_manual` | Needs teacher review (essay/speaking or dispute) |
| `finalized` | Released to student (if policy allows viewing) |

Parallel sub-states per item are allowed internally (`itemResults[itemId].status`).

## 3) Per-item result object

```json
{
  "itemId": "e1",
  "kind": "essay",
  "maxPoints": 10,
  "awardedPoints": 8.5,
  "status": "finalized",
  "breakdown": {
    "auto": { "points": 0 },
    "ai": { "points": 8, "confidence": 0.62, "rubric": { "task": 3, "coherence": 2.5, "language": 2.5 } },
    "manual": { "points": 8.5, "teacherId": "...", "note": "Strong ideas, minor grammar." }
  }
}
```

## 4) Auto grading rules

### 4.1 MCQ single

- Full points if selected set equals correct set.

### 4.2 MCQ multi

- Use exam setting `multiSelectGrading`:
  - `all_or_nothing`
  - `partial_by_correct_ratio` = \( \text{points} \times \frac{\text{correctChosen} - \text{wrongChosen}}{\text{totalCorrect}} \) (clamp at 0)

### 4.3 Fill blank

- Normalize: trim, case fold if enabled, optional accent fold (feature flag).
- Synonym map optional v2.

## 5) AI grading (essay / speaking)

### 5.1 Service integration

- Implement `examGradingService` in backend service layer calling existing AI provider abstraction (same family as [`aiService.js`](../../english_for_community_backend/src/services/aiService.js)).
- Use **structured output** where possible (JSON schema) to store machine-parseable rubric.

### 5.2 Prompting guidelines

- Include: CEFR target (if provided), rubric weights, anti-bias instruction, “do not invent facts about student”.
- Return: `scores`, `feedback`, `evidence_quotes` from student text only.

### 5.3 Failure handling

- If AI errors/timeouts:
  - mark item `pending_manual`
  - enqueue retry with exponential backoff (bounded)
  - teacher notified (optional)

> **Ghi chú (VI)**: Lưu `aiModel`, `aiPromptVersion` để audit và tái chấm khi đổi model.

## 6) Manual grading (teacher UI + API)

### 6.1 Teacher actions

- Adjust per-item points within `[0, maxPoints]`
- Add textual feedback
- Approve AI draft → finalize

### 6.2 API (proposal)

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/teacher/exams/attempts` | queue filters: pending_manual |
| `GET` | `/api/teacher/exams/attempts/:id` | detail |
| `PATCH` | `/api/teacher/exams/attempts/:id/items/:itemId` | set manual override |
| `POST` | `/api/teacher/exams/attempts/:id/finalize` | finalize whole attempt |
| `POST` | `/api/teacher/exams/attempts/:id/release` | release results to student |

Permissions: `teacher.grading.read` / `teacher.grading.write` with **ownership** checks.

## 7) Aggregation

- `totalAwarded = sum(item.awardedPoints)`
- `totalMax = sum(item.maxPoints)`
- Optional: section subtotals
- Optional: percentile within assignment cohort (compute lazily)

## 8) Result release policy

Controlled by `Exam.settings.showResultsPolicy` and assignment overrides:

- `never`: show only “submitted”
- `after_submit`: show auto parts immediately; hide manual until finalized
- `after_release`: only when teacher `release`

## 9) Admin oversight

- Admin can read attempts for moderation (separate permission) — optional.

## 10) Integrated / skills exams (0–10 per skill)

For `examFormat = integrated_four_skills` or `skills_exam`, scoring **does not** use `totalAwarded / totalMax` or per-question **pts** in the UI.

- Each included skill (and optional Grammar block) is scored **0–10**.
- **finalScore** = arithmetic mean of all **finalized** components; **partial** mean while Speaking/Writing are pending.
- Full business rules, API payloads, and UI wireframes: [`docs/exam-scoring/integrated-skill-scoring.md`](../exam-scoring/integrated-skill-scoring.md).

### 10.1 Teacher grade page layout

| Vùng | Widget / API | Ghi chú |
|------|----------------|--------|
| Đầu trang | `IntegratedGradingScorePanel` | Bảng kỹ năng + TB; đọc `GET …/grading/attempts/:id` |
| Ngữ pháp | `IntegratedGrammarItemResultFooter` | Chỉ `đúng/tổng`, không pts |
| Nghe / Đọc | Footer section | Điểm 0–10 + `detail` (tự động) |
| Nghe / Đọc | Auto | Inline `listeningCues` / `readingAnswers` hoặc CMS attempts trong cửa sổ thời gian |
| Viết | `IntegratedWritingGradingPanel` | AI (`generateFeedback`) hoặc GV nhập 0–10; `PATCH skillScores` |
| Nói | Footer + `PATCH skillScores` | GV nhập 0–10; lưu → tính lại TB |

**Backfill:** Khi mở chấm, backend `ensureIntegratedScoresOnAttempt` tự `buildIntegratedScores` nếu attempt cũ còn `totalAwarded` / thiếu `skillScores`.

### 10.2 Grading hub list

Cột điểm hiển thị `finalScore / 10` (hoặc `—` khi `finalStatus = pending`), không `awarded/max pts`.

## 11) Acceptance criteria

- Objective attempts finalize without teacher intervention.
- AI failure never blocks manual grading path.
- Students cannot see unreleased scores.
- Integrated exams never show legacy `X / Y pts` on grade or result screens.
