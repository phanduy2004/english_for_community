# WORK-ORDER — Speaking mất bài sau crash khi làm bài kiểm tra (resume)

**Task ID:** 20260712-exam-speaking-resume-lost · **Loại:** BUG · **Platform:** full-stack (student mobile + backend)
**Ngày:** 2026-07-12 · **Người làm:** Opus (tự code + tự audit) · **Trạng thái:** ✅ DONE (chưa commit)

## 1. Triệu chứng
Trong bài kiểm tra tích hợp (integrated), app crash → vào lại (resume attempt `in_progress`): phần **Speaking trắng** (mất bài đã làm), còn **Grammar vẫn còn**.

## 2. Nguyên nhân gốc (KHÔNG phải mất data — là bug rehydrate)
- Grammar/Reading/Writing/Listening: ghi **nội dung thật** vào `attempt.answers[...]` (patch tức thời mỗi thao tác), resume nạp lại qua `initial*`.
- Speaking: nội dung (transcript/score) submit sang **collection RIÊNG `SpeakingAttempt`** (route `speaking/submit`, mỗi câu nói xong) → data VẪN CÒN trên server. Nhưng vào exam attempt chỉ ghi **con số đếm** (`speakingSaved/Index/Total`, `completed`). Khi resume:
  1. Backend `getAttemptForStudent` chỉ trả `attempt.answers` thô + runtimeContext — **KHÔNG dựng lại transcript** (việc dựng `attachSkillWorkForGrading` chỉ dành cho teacher grading).
  2. Frontend runner **không truyền `initialSpeaking*`** xuống panel (khác reading/writing/listening).
  3. `SpeakingSkillsPage` ở exam mode init `_historyMap` **rỗng** (`speaking_skills_page.dart:489`, cố tình để không lẫn history luyện tập ngoài kỳ thi).
→ UI speaking trắng dù data còn trong `SpeakingAttempt`.

## 3. Giải pháp (rehydrate từ nguồn sẵn có — không đổi luồng save)
Backend dựng lại speaking records **trong cửa sổ bài thi** (như teacher grading) → đính vào attempt resume → frontend truyền xuống → `SpeakingSkillsPage` nạp `_historyMap` từ đó.

### Backend — `src/services/examAttemptService.js`
- Thêm `attachSpeakingResumeHistory(attemptDoc, plain)` (lean, **chỉ query speaking**, tái dùng `examTimeBounds`/`skillSectionsFromExam`/`resourcesFromSkillSection`/`batchFetchSpeakingRecordsMap` với `examOnly:true`). Chỉ chạy khi `status==in_progress` + có speaking section. Gắn `plain.speakingHistory[sectionId] = [records]`. **Bọc try/catch** → lỗi rehydrate không chặn resume.
- `getAttemptForStudent`: `const plain = await attachRuntimeContextToAttempt(attempt); await attachSpeakingResumeHistory(attempt, plain); return plain;`

### Frontend
- `integrated_exam_runner_page.dart`: getter `_speakingInitialHistory(sectionId)` đọc `_attempt['speakingHistory'][sectionId]`; truyền `initialSpeakingHistory` vào `ExamEmbeddedSkillPanel` (song song reading/writing initial*).
- `exam_embedded_skill_panel.dart`: + field `initialSpeakingHistory`; pass `initialExamHistory: widget.initialSpeakingHistory` vào `SpeakingSkillsPage`.
- `speaking_skills_page.dart`: + param `initialExamHistory` (thread qua `SpeakingSkillsPage`→`_SpeakingSkillsView`); helper `_groupExamHistoryBySentence()` (parse `SpeakingAttemptEntity.fromJson`, gom theo `sentenceId`, mới nhất trước); ở exam mode init `_historyMap[s.id] = examHist[s.id] ?? []` thay vì rỗng.

## 4. Scope
IN: 1 backend service + 3 frontend file (runner, embedded panel, speaking page). OUT: luồng save speaking (giữ nguyên `speaking/submit`); practice mode (giữ `List.from(s.history)`); các skill khác.

## 5. Verify
- Backend: `node --check` OK; `npm test` → **102/102 pass** (module load + no regression).
- Frontend: `flutter analyze` (3 file) → **0 error** (chỉ warning/info pre-existing).
- Smoke thủ công (đề xuất): thi integrated có speaking → nói vài câu → kill app → mở lại attempt → speaking hiển thị lại các câu đã làm + đếm "saved" đúng; grammar vẫn còn; practice speaking (ngoài thi) không đổi.

## 6. Shape contract (đã đối chiếu)
`SpeakingAttempt` record `{_id, sentenceId, userTranscript, score{wer,confidence}, submittedAt, createdAt}` → JSON (ObjectId→hex, Date→ISO) → `SpeakingAttemptEntity.fromJson` (id←_id, sentenceId required, score/submittedAt tolerant). `record.sentenceId` == `sentence.id` (cùng hex _id lúc submit `_currentSentence.id`). Chỉ lấy `examOnly` (bỏ `latest_linked` practice cũ).

## 7. Self-audit (Phase 4) — ✅ APPROVED
- [x] Root cause đúng: bug rehydrate, không mất data (verify `speaking/submit`→`speakingService.submitAttempt` persist thật).
- [x] Backend chỉ query speaking (không kéo query listening/reading/writing như grading path); gate `in_progress`+có-speaking; **try/catch** không chặn resume; không đổi payload shape các phần khác.
- [x] Frontend: thread initial* đúng pattern; parse tolerant (try/catch bỏ record lỗi); **practice mode KHÔNG đổi** (nhánh `examPracticeMode ? … : List.from(s.history)`).
- [x] Cận biên: chưa làm speaking → speakingHistory absent → `_historyMap` rỗng (như cũ); resume cũng re-sync `speakingSaved` qua `_notifyExamSpeakingProgress`.
- [x] `node --check` + `npm test` 102/102 + `flutter analyze` 0 error.
- ⚠️ Chưa chạy smoke E2E thật (cần seed attempt in_progress + speaking submissions + crash) — đề xuất user smoke theo §5.
