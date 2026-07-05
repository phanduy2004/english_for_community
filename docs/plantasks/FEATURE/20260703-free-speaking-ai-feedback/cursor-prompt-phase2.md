# Prompt giao Cursor — Free Speaking Phase 2 (Tình huống + Tiến bộ + Sổ tay)

> Copy phần trong khung. **Chỉ chạy sau khi Phase 1 đã land.**

---

Bạn hãy implement **Phase 2** của "Free Speaking — AI Feedback" (Tình huống + Dashboard tiến bộ + Sổ tay cải thiện + Gamification).

## 0. GROUND-TRUTH TRƯỚC (bắt buộc — code đã đổi sau Phase 1)
Trước khi code, ĐỌC CODE THẬT của các artifact Phase 1 đã land rồi mới lập diff, KHÔNG code từ trí nhớ:
1. **Tài liệu:** `docs/plantasks/FEATURE/20260703-free-speaking-ai-feedback/work-order-phase2.md` (đọc HẾT: §2 nghiệp vụ, §3 quyết định, §4 scope, §5 file-level, §6 GATE) + `README.md` + tham chiếu `docs/AI-Working-Process-vi.md`.
2. **Phase 1 đã land (đọc thật):** model `SpeakingConversation` (field `scenario`/`level` đã chừa), endpoint `POST /api/speaking/conversation/evaluate` + service, `speaking_feedback_page.dart`, entity/DTO + `SpeakingFeedbackBloc`, datasource/repo speaking conversation.
3. **Progress:** `english_for_community_backend/src/utils/progressTracker.js`, `src/models/UserDailyProgress.js` (bucket `speakingScore`), `english_for_community/lib/feature/progress/progress_report_page.dart` (+ chart `WeeklyActivityBarsChart` làm mẫu `fl_chart`).
4. **Vapi override (cho tình huống):** `lib/feature/speaking/vapi/real_vapi_service.dart` (`assistantOverrides`), `free_speaking_page.dart` (chỗ start call).
5. **Vocab + nhắc học (cho sổ tay/ôn tập):** `Word` model + route/service vocab, `english_for_community_backend/src/jobs/smartNotificationJob.js`, feature Vocab client.
6. **Gamification/streak:** hàm `updateGamificationStats` + model streak (đọc trước khi thêm streak nói riêng).
7. **Hạ tầng + UI system:** `lib/core/get_it/get_it.dart`, `api_client.dart`, repo `Either<Failure,T>`, `student_mobile_ui.dart`, theme (`app_color/app_typography/app_spacing/app_skill_colors`), `app_feedback.dart`; **`docs/ui-ux-system/`** (README, `00`,`02`,`11`,`12` + student `03`,`04`,`05`,`20`) — dashboard đối chiếu màn **Progress**.
8. **l10n:** `lib/l10n/app_en.arb` + `app_vi.arb`; `flutter gen-l10n` sau khi sửa.

## 1. Quyết định KHOÁ (không đổi)
- Feedback **song ngữ** (nhận xét VN / ví dụ EN), model chấm text vẫn **Groq gpt-oss-120b**.
- **Chỉ Phase 2.** KHÔNG chạm audio/phát âm/teacher (Phase 3), KHÔNG làm lại Vapi.
- Tình huống **data-driven** (collection `SpeakingScenario` + seed ~12–16 kịch bản); "free chat" vẫn là mặc định.
- **Tách bucket** `stats.speakingFluency` khỏi `speakingScore` (WER drill) → phải **AUDIT DOWNSTREAM** mọi nơi đọc `speakingScore` (progressTracker, progress_report_page, tool `get_speaking_details`) và cập nhật cho đúng, KHÔNG phá WER drill.
- Ôn tập **tái dùng Vocab review + smartNotificationJob** — KHÔNG tự xây spaced-repetition mới.

## 2. Nguyên tắc
- Chỉ chấm lời USER; feedback tình huống chấm thêm **task achievement** theo `scenario.goals`.
- Backend: controller mỏng, logic ở service, **Zod validate**, auth; aggregation `progress/summary` phải có **index** (`userId`+`createdAt`), `.lean()`, tránh N+1 khi gom error bank.
- Client: dashboard/list dùng `ListView.builder`/pagination, `BlocSelector`/`buildWhen`, không aggregate trong `build()`, chart không jank; đủ loading/empty/error; hit target ≥44dp.
- Đăng ký DI trong `get_it.dart`; route mới trong `AppRouter`.

## 3. Thứ tự làm (§11 work-order)
1) **2B Dashboard**: endpoint `GET /api/speaking/progress/summary` + tách bucket `speakingFluency` + màn dashboard (fl_chart) + bật mũi tên xu hướng ở feedback.
2) **2A Tình huống**: model `SpeakingScenario` + seed + `GET /speaking/scenarios` + màn chọn tình huống + override Vapi + mở rộng `evaluate` nhận `scenarioId`.
3) **2C Sổ tay**: gom lỗi/từ + phát hiện lỗi lặp + màn sổ tay + nút ôn (nối Vocab).
4) **2D Gamification**: XP/huy hiệu/streak nói (nối `updateGamificationStats`).
5) l10n EN+VI (`gen-l10n`) xuyên suốt.

## 4. Xong khi đạt Acceptance §7 work-order-phase2
Không regression Phase 1; chọn tình huống → AI đóng đúng vai → feedback có task achievement; dashboard đúng sau ≥2 buổi + xu hướng đúng; sổ tay gom đúng lỗi/từ + ôn mở Vocab; gamification không phá streak cũ.

## 5. Sau khi xong
- Tự audit theo §10 work-order (tách bucket không phá downstream, aggregation có index, chart mượt, l10n đủ), liệt kê file tạo/sửa + chỗ nghi ngờ.
- **KHÔNG tự commit/push.** Chỗ nào chưa rõ/không khả thi → DỪNG hỏi, đừng tự chế hướng khác.
