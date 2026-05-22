# Nghiệp vụ chấm điểm tích hợp kỹ năng (Integrated Skill Scoring)

> **Phiên bản:** v2.0 — Thay thế hoàn toàn hệ thống `pts` cũ.  
> **Áp dụng cho:** `examFormat = 'integrated_four_skills'` và `'skills_exam'`

---

## 1. Tổng quan

Bài thi tích hợp gồm **N kỹ năng** (Nghe / Nói / Đọc / Viết) và optionally một **phần Ngữ pháp**.  
Mỗi thành phần được chấm trên thang **0 – 10**.  
Điểm cuối = **trung bình cộng** của tất cả điểm thành phần đã được chấm.

```
finalScore = (score_L + score_R + score_S + score_W + score_Grammar) / tổng_số_thành_phần
```

---

## 2. Thang điểm & quy tắc làm tròn

| Thông số | Giá trị |
|---|---|
| Min | 0.0 |
| Max | 10.0 |
| Làm tròn | 1 chữ số thập phân (0.1) |
| Ví dụ | `17/20 đúng → 17/20 × 10 = 8.5` |

---

## 3. Phương pháp chấm điểm từng thành phần

### 3.1 Ngữ pháp (Grammar) — Tự động

- Được chấm **ngay khi học sinh nộp bài**.
- Mỗi câu hỏi ngữ pháp có điểm tối đa riêng (`it.points`).
- Câu đúng → cộng điểm, sai → 0.
- **Quy tắc tính:**

```
grammarRaw   = Σ awardedPoints_per_item
grammarRawMax = Σ maxPoints_per_item
grammarScore  = round(grammarRaw / grammarRawMax × 10, 1)
```

- Nếu không có phần ngữ pháp → không tính vào trung bình.

### 3.2 Kỹ năng Nghe (Listening) — Tự động

- Được chấm **ngay khi học sinh nộp bài** (hoặc khi GV mở trang chấm — backfill).
- Nguồn đáp án (theo thứ tự): `answers[sectionId].listeningCues` trên attempt → nếu thiếu, **DictationAttempt** trong cửa sổ thời gian bài thi (`fetchListeningRecords`).
- Học sinh điền từ vào chỗ trống (dictation cues).
- Đáp án so sánh theo chuẩn hoá: lowercase, bỏ dấu câu, trim.
- **Quy tắc tính:**

```
correctCues = số cue học sinh điền đúng (so sánh chuẩn hoá)
totalCues   = tổng số cue của bài listening
listeningScore = round(correctCues / totalCues × 10, 1)
```

- **Nguồn dữ liệu:** `attempt.answers[sectionId].listeningCues` (map `{cueIndex: userText}`)
- Nếu không có câu nào → score = 0.

### 3.3 Kỹ năng Đọc (Reading) — Tự động

- Được chấm **ngay khi học sinh nộp bài** (hoặc backfill khi GV mở chấm).
- Nguồn: `answers[sectionId].readingAnswers` (khóa `questionId` hoặc chỉ số câu) → fallback **ReadingAttempt** trong cửa sổ thời gian bài thi.
- Học sinh chọn đáp án MCQ.
- **Quy tắc tính:**

```
correctAnswers = số câu học sinh chọn đúng (so sánh correctAnswerIndex)
totalQuestions = tổng số câu hỏi reading
readingScore   = round(correctAnswers / totalQuestions × 10, 1)
```

- **Nguồn dữ liệu:** `attempt.answers[sectionId].readingAnswers` (map `{questionId: chosenIndex}`)
- Nếu không có câu nào → score = 0.

### 3.4 Kỹ năng Nói (Speaking) — Chờ AI / Thủ công

- **Trạng thái ban đầu:** `pending_ai` (score = null) khi học sinh nộp bài.
- Giáo viên hoặc AI gán điểm 0 – 10.
- Không ảnh hưởng đến `finalScore` cho đến khi được chấm xong.

### 3.5 Kỹ năng Viết (Writing) — Chờ AI / Thủ công

- **Trạng thái ban đầu:** `pending_manual` khi đã có `writingDraft`; `pending_manual` + không có bài → chờ nộp.
- **AI:** `POST …/grading-attempts/:id/ai-draft` → `aiService.generateFeedback` (cùng engine luyện Writing), quy đổi band IELTS 0–9 → điểm thi 0–10 (`ieltsBandToExamTen`).
- **GV:** nhập 0–10, ghi chú, hoặc **Dùng điểm AI** sau khi chạy AI.
- UI: `IntegratedWritingGradingPanel` (bài viết + band AI + chấm tay).

---

## 4. Tính điểm cuối (finalScore)

### Quy tắc:

```
components = [skillScores[sid].score for sid where status == 'finalized']
             + [grammarScore.score] if grammarScore present

finalScore = round(mean(components), 1)  if components.length > 0  else null
```

### Trạng thái chấm điểm (`finalStatus`):

| Giá trị | Ý nghĩa |
|---|---|
| `finalized` | Tất cả thành phần đã được chấm xong |
| `partial` | Một số thành phần chưa chấm, hiển thị điểm tạm (chỉ tính phần đã có) |
| `pending` | Chưa có thành phần nào được chấm |

---

## 5. Cấu trúc dữ liệu `attempt.scores` (mới)

```json
{
  "examFormat": "integrated_four_skills",

  "skillScores": {
    "<sectionId_listening>": {
      "skill": "listening",
      "score": 8.5,
      "max": 10,
      "detail": "17/20 correct",
      "status": "finalized",
      "gradingSource": "auto"
    },
    "<sectionId_reading>": {
      "skill": "reading",
      "score": 7.0,
      "max": 10,
      "detail": "14/20 correct",
      "status": "finalized",
      "gradingSource": "auto"
    },
    "<sectionId_writing>": {
      "skill": "writing",
      "score": null,
      "max": 10,
      "detail": null,
      "status": "pending_ai",
      "gradingSource": null
    },
    "<sectionId_speaking>": {
      "skill": "speaking",
      "score": null,
      "max": 10,
      "detail": null,
      "status": "pending_ai",
      "gradingSource": null
    }
  },

  "grammarScore": {
    "score": 9.0,
    "max": 10,
    "rawAwarded": 9,
    "rawMax": 10,
    "status": "finalized",
    "items": {
      "<itemId>": {
        "kind": "mcq_single",
        "maxPoints": 1,
        "awardedPoints": 1,
        "status": "finalized"
      }
    }
  },

  "finalScore": null,
  "finalMax": 10,
  "finalStatus": "partial"
}
```

> **Không còn** `totalAwarded` / `totalMax` cho integrated exams.

---

## 6. Luồng chấm điểm đầy đủ

```
Học sinh nộp bài
        │
        ▼
┌─────────────────────────────────────┐
│  Chấm tự động tại nộp bài           │
│  ✓ Grammar  → finalized             │
│  ✓ Listening → finalized (nếu có)   │
│  ✓ Reading  → finalized (nếu có)    │
│  ✗ Speaking → pending_ai            │
│  ✗ Writing  → pending_ai            │
│                                     │
│  finalStatus = partial / finalized  │
└─────────────────────────────────────┘
        │
        ▼  (nếu có Speaking/Writing)
┌─────────────────────────────────────┐
│  Giáo viên xem bài làm và gán điểm  │
│  Speaking: 0–10  Writing: 0–10      │
│  → PATCH /api/exams/grading/:id     │
│    body: { skillScores: { sid: { score: 8.5 } } }
│                                     │
│  Hệ thống tái tính finalScore       │
│  finalStatus → finalized            │
└─────────────────────────────────────┘
```

---

## 7. API thay đổi

### 7.1 Endpoint chấm điểm kỹ năng (Speaking/Writing)

**PATCH** `/api/exams/grading/:attemptId/patch`

```json
{
  "skillScores": {
    "<sectionId>": {
      "score": 8.5,
      "note": "Good fluency, minor pronunciation errors"
    }
  },
  "finalize": true
}
```

**Phản hồi:** Attempt object với `scores.skillScores` đã cập nhật và `finalScore` được tái tính.

### 7.2 Backward compat cho non-integrated exams

- Non-integrated exams (`standard`, `mcq_only`, etc.) vẫn dùng `totalAwarded / totalMax`.
- Gradebook và card vẫn dùng `totalAwarded` cho non-integrated.

---

## 8. Hiển thị điểm

### 8.1 Giáo viên — trang chấm bài

```
┌─────────────────────────────────────────┐
│  Kết quả bài làm                        │
│                                         │
│  🎧 Nghe      8.5 / 10  ✓ finalized    │
│  📖 Đọc       7.0 / 10  ✓ finalized    │
│  ✍️ Viết      ─── / 10  ⏳ pending     │
│  🎤 Nói       ─── / 10  ⏳ pending     │
│  📝 Ngữ pháp  9.0 / 10  ✓ finalized    │
│                                         │
│  Điểm TB (tạm): 8.2 / 10               │
│  (chưa tính Viết + Nói)                 │
└─────────────────────────────────────────┘
```

### 8.2 Học sinh — màn hình kết quả

```
┌─────────────────────────────────────────┐
│  Kết quả tổng hợp                       │
│                                         │
│  🎧 Nghe      8.5 / 10                  │
│  📖 Đọc       7.0 / 10                  │
│  ✍️ Viết      Chờ chấm                  │
│  🎤 Nói       Chờ chấm                  │
│  📝 Ngữ pháp  9.0 / 10                  │
│                                         │
│  Điểm trung bình: 8.2 ★ (tạm tính)    │
└─────────────────────────────────────────┘
```

### 8.3 Danh sách bài làm (Grading Hub)

- Hiển thị `finalScore / 10` nếu `finalStatus == 'finalized'`
- Hiển thị `X.X★` (chữ nghiêng/dim) nếu `finalStatus == 'partial'`
- Hiển thị `⏳` nếu `finalStatus == 'pending'`

### 8.4 Không hiển thị `pts` (bắt buộc)

| Vị trí | Cũ (cấm) | Mới |
|---|---|---|
| Footer từng câu Ngữ pháp (GV) | `0 / 0 pts` | `2 / 3 đúng` hoặc chỉ màu MCQ |
| Thẻ tổng GV chấm bài | `totalAwarded / totalMax pts` | `IntegratedGradingScorePanel` (bảng kỹ năng + TB) |
| Thẻ tổng HS kết quả | `totalAwarded / totalMax pts` | `IntegratedScoreSummaryCard` |
| Kỹ năng Đọc trong panel GV | `score / 100 pts` | `X / 10` + `đúng/tổng` nếu có |
| Bài thi cổ điển (non-integrated) | Giữ `pts` theo câu | Không đổi |

Widget Flutter: `lib/feature/student/exams/integrated_exam_score_widgets.dart` (`IntegratedGradingScorePanel` — GV; `IntegratedScoreSummaryCard` — HS).

**Backfill khi mở chấm:** `examAttemptService.ensureIntegratedScoresOnAttempt` gọi `buildIntegratedScores` nếu attempt thiếu `skillScores`.

---

## 9. Quy tắc nghiệp vụ bổ sung

1. **Listening nhiều resource:** Nếu một section listening có nhiều bài (resources), tính tổng correctCues / totalCues của TẤT CẢ resources.
2. **Reading nhiều resource:** Tương tự, tính tổng correctAnswers / totalQuestions.
3. **Nộp bài không hoàn thành (force_end):** Các skill không `completed` vẫn được chấm dựa trên câu đã làm (chứ không phải 0 như cũ).
4. **Thang điểm Teacher grading:** Giáo viên nhập 0–10 (cho phép 1 chữ số thập phân). Giá trị ngoài [0,10] bị clamp.
5. **Kỹ năng không có câu hỏi (0 cues, 0 questions):** Score = null, status = `no_content`, không tính vào trung bình.
6. **Re-grade:** Khi giáo viên cập nhật lại điểm một kỹ năng, `finalScore` được tái tính ngay lập tức.
