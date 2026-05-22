# 14 — Đề Writing trong bài kiểm tra kỹ năng (Skills / Integrated exam)

> Áp dụng khi `examFormat = skills_exam` hoặc `integrated_four_skills` và phần **Writing** được bật.

---

## 1. Mục tiêu

- Mọi học sinh làm **cùng một đề Writing** trong một lần giao bài / một đề thi.
- Giáo viên gán đề khi **soạn đề**; học sinh **không** tự đổi đề (không gọi AI tạo đề mới trong lúc thi).
- Chấm điểm Writing trong bài thi: **GV chấm tay 0–10** hoặc **AI** (cùng engine luyện Writing), xem [`../exam-scoring/integrated-skill-scoring.md`](../exam-scoring/integrated-skill-scoring.md).

---

## 2. Dữ liệu lưu trên đề (Exam draft)

Trong `sections[]`, section có `skill: "writing"`:

| Trường | Ý nghĩa |
|--------|---------|
| `resources[]` | Một hoặc nhiều **Writing topic** từ thư viện CMS (chỉ để gắn rubric / metadata; không bắt buộc cho đề cố định). |
| `fixedWritingPrompt` | Đề cố định cho cả lớp — **bắt buộc trước khi Publish**. |

### Cấu trúc `fixedWritingPrompt`

```json
{
  "title": "Technology and education",
  "text": "Some people believe that technology has made education worse...",
  "taskType": "Essay",
  "level": "Intermediate"
}
```

| Trường | Bắt buộc | Ghi chú |
|--------|----------|---------|
| `text` | Có | Nội dung đề đầy đủ (ngữ cảnh + yêu cầu). |
| `title` | Không | Hiển thị trên UI; trống → dùng nhãn “Custom prompt”. |
| `taskType` | Không | Mặc định `Essay`; dùng khi AI chấm (`generateFeedback`). |
| `level` | Không | Mặc định `Intermediate`. |

---

## 3. Luồng giáo viên (soạn đề)

1. Mở editor **Skills exam** / **Four-skill exam**.
2. Bật kỹ năng **Writing** → **Thêm bài tập** (chọn topic từ thư viện).
3. Trong khối **Writing Prompt**:
   - **Generate with AI** — gọi API tạo 3 đề gợi ý từ topic đã chọn → GV chọn một đề.
   - **Write manually** — dialog *Write your own prompt* (title, task type, nội dung đề) → **Save**.
4. **Save draft** / **Publish** — `fixedWritingPrompt` nằm trong section Writing của snapshot.
5. **Publish:** nếu Writing được bật mà chưa có `fixedWritingPrompt.text` → chặn, báo lỗi.

**Code:** `teacher_integrated_exam_editor_page.dart` — `_showWritingPromptManualDialog`, `_generateWritingPromptOptions`.

**API AI gợi ý đề:** `POST /api/teacher/exams/.../writing-prompt-options` (topicId).

---

## 4. Luồng học sinh (làm bài)

1. Mở phần Writing trong runner tích hợp.
2. `ExamEmbeddedSkillPanel` truyền `fixedWritingPrompt` vào `WritingTaskPage`.
3. Bloc **không** gọi `generateWritingPrompt` — hiển thị đúng `title` + `text` từ GV.
4. Học sinh gõ bài → lưu draft vào `answers[sectionId].writingDraft` (+ `wordCount`).
5. Nộp bài → Writing ở trạng thái `pending_manual` cho đến khi GV/AI chấm (0–10).

---

## 5. Chấm điểm (giáo viên)

| Cách | Hành vi |
|------|---------|
| **Chấm bằng AI** | `runAiSuggestions` → `aiService.generateFeedback` → điểm 0–10 (`IELTS band / 9 × 10`). |
| **Chấm tay** | Nhập 0–10 + ghi chú → `PATCH` `skillScores[sectionId]`. |
| **Dùng điểm AI** | Áp `aiDraftScore` đã lưu sau lần chạy AI. |

UI: `IntegratedWritingGradingPanel` trên `TeacherExamAttemptGradePage`.

---

## 6. Acceptance criteria

- [ ] GV có thể lưu đề viết tay (dialog Save) và thấy preview ngay trên editor.
- [ ] Publish bị chặn nếu thiếu đề Writing khi skill Writing bật.
- [ ] HS thấy đúng đề GV đã gán; không đổi đề khi làm bài thi.
- [ ] Draft `writingDraft` được lưu trên attempt; GV chấm được trên trang grade.
