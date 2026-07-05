# Prompt giao Cursor — Free Speaking AI Feedback (Phase 1)

> Copy phần trong khung dưới dán vào Cursor.

---

Bạn hãy implement **Phase 1** của tính năng **"Free Speaking — AI Feedback sau hội thoại"**.

## 0. ĐỌC TRƯỚC KHI CODE (bắt buộc, đọc kỹ theo thứ tự)
1. **Work-order (nguồn sự thật):** `docs/plantasks/FEATURE/20260703-free-speaking-ai-feedback/work-order.md` — đọc HẾT, làm đúng phạm vi §3, rubric §4, màn §5, backend §6, frontend §7, edge cases §8, acceptance §8b, thứ tự §10.
2. **Free Speaking hiện tại (nơi bắt transcript):** `english_for_community/lib/feature/speaking/free_speaking_page.dart` (chú ý `_messages`, hook `status → ended/disconnected`, `_handleTranscript`), `.../speaking/vapi/vapi_service.dart`, `.../speaking/vapi/real_vapi_service.dart`.
3. **Template backend CHẤM (clone cái này):** `english_for_community_backend/src/services/aiService.js` (`generateFeedback` + `repairParagraphRewrites`), `src/models/WritingSubmission.js` (`FeedbackSchema`), `src/services/writingTopicService.js` (`submitForReview`), `src/controllers/writingTopicController.js`, `src/routes/writingTopicRoutes.js`.
4. **Template UI kết quả (clone cái này):** `english_for_community/lib/feature/writing/writing_feedback_page.dart` (tabs, `_ScoreRow`, `_CriteriaCard`), `lib/feature/writing/widgets/interactive_diff_text.dart` (diff `{{old||new||reason}}`), `lib/core/entity/writing_submission_entity.dart`.
5. **Speaking hiện có + pattern submit:** `english_for_community_backend/src/routes/speakingRoutes.js`, `src/controllers/speakingController.js`, `src/models/SpeakingAttempt.js`, `src/models/SpeakingSet.js`; client `lib/feature/speaking/speaking_lesson_bloc/*` (mẫu "submit → nhận kết quả về state").
6. **Progress:** `english_for_community_backend/src/utils/progressTracker.js`, `src/models/UserDailyProgress.js`, `english_for_community/lib/feature/progress/progress_report_page.dart`.
7. **Hạ tầng client (bám đúng):** `lib/core/get_it/get_it.dart` (DI), `lib/core/api/api_client.dart` (dio + JWT), repo pattern `Either<Failure,T>` (dartz), `lib/core/ui/student_mobile_ui.dart`, theme (`lib/core/theme/app_color.dart`, `app_typography.dart`, `app_spacing.dart`, `app_skill_colors.dart` → `SkillType.speaking`), `lib/core/ui/feedback/app_feedback.dart`.
8. **l10n:** `lib/l10n/app_en.arb` + `lib/l10n/app_vi.arb`, dùng `context.l10n.<key>` (`lib/core/locale/l10n_context.dart`). Sau khi sửa `.arb` phải chạy `flutter gen-l10n`.
9. **Cho nút "Lưu vào sổ từ":** tự tìm cơ chế lưu từ vựng hiện có (backend `Word` model + route/service liên quan; feature Vocab phía client) và tái dùng, đừng tạo mới.

## 1. Quyết định đã KHOÁ (không được đổi)
- **Song ngữ:** mọi nhận xét/giải thích (`*Note`, `*Bullets`, `explain`, `reason`, `note`, `summary`, `issue`, `nextSteps`) viết **tiếng Việt**; mọi ví dụ/câu mẫu/từ (`before/after/said/better/yourTurn/modelTurn`) giữ **tiếng Anh**.
- **Model:** Groq `gpt-oss-120b`, `response_format: json_object`, `temperature 0.3`, có self-repair như Writing.
- **Chỉ Phase 1** (§3 work-order). **KHÔNG** làm chấm phát âm, KHÔNG lưu audio, KHÔNG làm thư viện tình huống/dashboard (đó là Phase 2/3).
- **Nền móng số 1:** bắt & lưu transcript khi kết thúc hội thoại (hiện đang bị vứt đi).

## 2. Nguyên tắc
- **Clone khung Writing** thay vì viết mới; đặt tên/tiền tố nhất quán (`speakingFb*` cho l10n, `SpeakingConversation`, `SpeakingFeedbackPage`, `SpeakingFeedbackBloc`...).
- **Không phá** Free Speaking đang chạy hay bất kỳ feature nào khác; không đổi hành vi Vapi.
- Chỉ chấm **lời USER**; lời AI chỉ là ngữ cảnh. **Không để AI bịa số thống kê** — tính bằng code (§4 work-order) rồi truyền vào.
- Chặn hội thoại quá ngắn ở cả client + server; AI lỗi → giữ transcript, cho "Thử lại".
- Đăng ký DI trong `get_it.dart`. Thêm route mới trong `AppRouter`.

## 3. Thứ tự thực hiện (theo §10 work-order)
1. Backend: model `SpeakingConversation` + hàm `computeStats` + `aiService.generateSpeakingFeedback` (+ prompt §6.3) + endpoint `POST /api/speaking/conversation/evaluate` (+ `history`, `:id`). Test bằng transcript mẫu trước.
2. Client: datasource + repository + entity/DTO + `SpeakingFeedbackBloc` + DI.
3. Hook bắt transcript ở `free_speaking_page.dart` + nút **"Kết thúc & nhận đánh giá"** + điều hướng sang màn loading.
4. `speaking_feedback_page.dart` (clone Writing, 4 tab) + route + l10n (`gen-l10n`).
5. Nút "Lưu vào sổ từ" + màn Lịch sử + cộng điểm vào Progress (`trackUserProgress('speaking', {score: overall/9})`).
6. Chạy acceptance §8b.

## 4. Xong khi đạt Acceptance §8b của work-order
Nói ≥30s → "Kết thúc & nhận đánh giá" → báo cáo 4 tab dữ liệu thật; `improvements` trích đúng câu user (before→after); nhận xét VN/ví dụ EN; "Lưu vào sổ từ" hoạt động; buổi lưu DB + xem lại từ Lịch sử; Progress Speaking đổi; hội thoại ngắn báo nhẹ; AI lỗi có "Thử lại".

## 5. Sau khi code xong
- **Tự audit** lại toàn bộ theo work-order (đúng phạm vi, đúng convention, không rò rỉ regression), liệt kê file đã tạo/sửa và những chỗ còn nghi ngờ.
- **KHÔNG tự commit/push** — để lại working tree cho mình review.
- Nếu có điểm nào trong work-order chưa rõ/không khả thi → dừng lại hỏi, đừng tự chế hướng khác.
