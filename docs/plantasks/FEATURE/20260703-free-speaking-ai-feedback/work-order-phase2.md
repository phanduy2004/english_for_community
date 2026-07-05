# Work Order — Free Speaking Phase 2: Tình huống + Theo dõi tiến bộ + Sổ tay cải thiện

> Tuân theo [`docs/AI-Working-Process-vi.md`](../../../AI-Working-Process-vi.md). **Loại:** FEATURE · **Platform:** full-stack (student mobile + backend) · **Cỡ:** T2 (>5 file, nhiều màn) → nên tách role-folder khi thực thi.
>
> ⚠️ **Bắt buộc trước khi code:** chạy lại **Phase 1 — Ground-truth analysis** (Opus/Explore đọc code THẬT của các artifact Phase 1 đã land: `SpeakingConversation`, endpoint `evaluate`, `SpeakingFeedbackPage`, entity/bloc, `progressTracker`, `UserDailyProgress`, `updateGamificationStats`, hệ Vocab + `smartNotificationJob`). Tài liệu này là **nghiệp vụ + kế hoạch định hướng**, chưa phải diff cuối.

---

## 1. Bối cảnh & nghiệp vụ (vì sao cần Phase 2)

Sau Phase 1, mỗi buổi nói có báo cáo riêng lẻ — nhưng người học **chưa có mục tiêu rõ ràng khi vào nói**, **chưa thấy mình tiến bộ ra sao theo thời gian**, và **lỗi/từ cần cải thiện trôi qua từng buổi** không được gom lại để ôn. Phase 2 vá 3 khoảng trống đó → biến các buổi rời rạc thành **một hành trình học có mục tiêu và đo lường được**.

**User stories:**
- *"Tôi muốn luyện phỏng vấn xin việc bằng tiếng Anh"* → chọn kịch bản, AI đóng vai nhà tuyển dụng, chấm sát mục tiêu.
- *"Tôi muốn biết tháng này nói tốt hơn tháng trước không"* → dashboard xu hướng điểm.
- *"Tôi hay bị nhắc lỗi mạo từ, muốn ôn lại"* → sổ tay lỗi hay gặp + flashcard.
- *"Tôi cần động lực nói mỗi ngày"* → streak nói + huy hiệu.

---

## 2. Các module (nghiệp vụ chi tiết)

### 2A. Thư viện tình huống + mục tiêu CEFR
**Nghiệp vụ:** trước khi vào phòng nói, user chọn **tình huống** (nhóm gợi ý: *Đời sống* — gọi món, mua sắm, hỏi đường, small talk; *Công việc* — phỏng vấn, họp, thuyết trình; *Học thuật/Thi* — IELTS Speaking Part 1/2/3, mô tả tranh, tranh luận chủ đề; *Du lịch* — sân bay, khách sạn) và **trình độ CEFR mục tiêu** (A2/B1/B2/C1). AI **đóng đúng vai** + điều chỉnh tốc độ, độ khó từ vựng, và câu mở đầu. "Free chat" vẫn là một lựa chọn mặc định. Feedback cuối buổi chấm thêm **mức độ hoàn thành nhiệm vụ** của kịch bản.

**Dữ liệu 1 tình huống:** `title`, `group`, `levelSuggested`, `roleForAI` (system prompt/persona), `firstMessage` (câu AI mở đầu), `goals[]` (tiêu chí thành công), `evalEmphasis` (trọng số/điểm nhấn chấm), `icon`.

**Kỹ thuật:** truyền `roleForAI`/`firstMessage` vào Vapi qua `assistantOverrides` (đã có cơ chế override ở `real_vapi_service.dart`); lưu `scenario`/`level` vào `SpeakingConversation` (Phase 1 đã chừa field). Feedback prompt nhận `scenario.goals` để chấm task achievement.

### 2B. Dashboard tiến bộ Speaking
**Nghiệp vụ:** người học xem tiến bộ theo thời gian: **biểu đồ điểm từng tiêu chí** (fc/lr/gra/ia) qua các buổi/tuần/tháng; tổng **số phút nói**, **số buổi**, **streak nói**, **phân bố CEFR**; **so sánh buổi này vs trung bình gần đây** (đây là dữ liệu cho **mũi tên xu hướng** ở màn feedback mà Phase 1 đã chừa chỗ). Xem nhanh 3 buổi gần nhất + link Lịch sử.

**Kỹ thuật:** aggregation từ `SpeakingConversation` theo `userId` + khoảng thời gian → endpoint `GET /api/speaking/progress/summary?range=week|month`. **Tách bucket** `stats.speakingFluency` trong `UserDailyProgress` (Phase 1 tạm dùng chung `speakingScore` với WER drill — Phase 2 tách để không trộn) + tile/khối riêng ở Progress. Dùng `fl_chart` (đã có trong pubspec).

### 2C. Sổ tay cải thiện (Error bank + Vocab) + Ôn tập
**Nghiệp vụ:** tự động gom `corrections` (lỗi đã sửa) + `vocabUpgrades` qua các buổi thành **sổ tay cá nhân**; **phát hiện lỗi lặp lại** theo `type` (vd "hay quên mạo từ", "sai thì quá khứ") và làm nổi bật; cho **ôn tập flashcard** (spaced repetition nhẹ). Nối với **hệ Vocab + nhắc hằng ngày** sẵn có để nhắc ôn.

**Kỹ thuật:** gom từ các `SpeakingConversation.feedback.corrections/vocabUpgrades` (aggregation hoặc bảng phụ `SpeakingErrorBank` để đếm tần suất theo type). Ôn tập **tái dùng cơ chế Vocab review + `smartNotificationJob`** thay vì tự xây spaced-repetition mới.

### 2D. Gamification (XP, huy hiệu, streak nói)
**Nghiệp vụ:** thưởng động lực: **XP** mỗi buổi (theo thời lượng + điểm overall), **huy hiệu** ("10 buổi nói", "Lần đầu có turn đạt B2+", "7 ngày nói liên tiếp"), **streak nói** riêng cho speaking. Hiển thị trên màn feedback + hub speaking.

**Kỹ thuật:** nối `updateGamificationStats` sẵn có (Phase 1 đã gọi khi chấm xong); định nghĩa badge/threshold; streak theo ngày có buổi nói hợp lệ.

---

## 3. Quyết định thiết kế + cảnh báo

| Quyết định | Lý do / cảnh báo |
|-----------|------------------|
| Tình huống **data-driven** (collection `SpeakingScenario` + CMS admin, giống `SpeakingSet`) | Admin thêm/sửa kịch bản không cần build lại app. Cảnh báo: cần màn admin CRUD (có thể defer, seed cứng trước). |
| **Tách** `stats.speakingFluency` khỏi `speakingScore` (WER drill) | Tránh trộn 2 loại điểm khác bản chất. Cảnh báo: cập nhật cả nơi đọc (Progress tile) — AUDIT DOWNSTREAM `progressTracker`, `progress_report_page`, tool `get_speaking_details`. |
| Ôn tập **tái dùng Vocab** (không tự xây SRS) | Giảm nợ kỹ thuật; nhất quán trải nghiệm nhắc học. |
| Streak nói **riêng** khỏi streak học chung | Tránh phá logic streak hiện có; kiểm tra model streak trước khi thêm. |
| Dashboard dùng `fl_chart` đã có | Không thêm dependency chart mới. |

---

## 4. Scope

**IN:** 2A tình huống (seed + chọn + override Vapi + chấm task), 2B dashboard + endpoint summary + tách bucket, 2C sổ tay + ôn tập (nối Vocab), 2D gamification cơ bản; l10n song ngữ; loading/empty/error mọi màn mới.

**OUT (chạm là DỪNG & hỏi):** chấm phát âm / ghi audio (Phase 3), độ khó thích ứng tự động (Phase 3), teacher view (Phase 3), làm lại kiến trúc Vapi, đổi schema Phase 1 ngoài field đã chừa, CMS admin đầy đủ cho scenario nếu chưa chốt (seed cứng trước).

---

## 5. Kế hoạch file-level (Ý ĐỊNH — Codex tự viết code; chốt lại sau ground-truth)

> Đường dẫn dự kiến; **verify lại sau Phase 1**. Mỗi mục: ý định + ràng buộc + nghiệm thu.

| Khu vực | File dự kiến | Ý định | Nghiệm thu |
|--------|--------------|--------|-----------|
| BE model | `backend/src/models/SpeakingScenario.js` | schema kịch bản (§2A) + soft-delete | tạo/seed được, query theo group/level |
| BE seed | `backend/src/seeds/speakingScenarios.*` | ~12–16 kịch bản khởi tạo (song ngữ mô tả) | seed chạy, đủ nhóm |
| BE route/ctrl/service | `speakingRoutes.js` + `speakingController.js` + `speakingService.js` | `GET /speaking/scenarios`, `GET /speaking/progress/summary`; mở rộng `evaluateConversation` nhận `scenarioId` → chấm task | endpoint trả đúng, auth, `.lean()`, index `userId+createdAt` |
| BE progress | `progressTracker.js` + `UserDailyProgress.js` | thêm bucket `speakingFluency`; XP/badge/streak nói | Progress đọc bucket mới; không phá WER drill |
| Client data | `speaking` datasource/repo/entity (mở rộng) | scenario list, progress summary, error bank | `Either<Failure,T>`, DTO↔entity khớp |
| Client bloc | `speaking_scenario_bloc`, `speaking_progress_bloc` | tải scenario, summary | state loading/empty/error |
| Client UI | màn **Chọn tình huống** (grid theo nhóm + chip CEFR) | trước khi vào Free Speaking; free chat mặc định | archetype + brief `ui-ux-system` |
| Client UI | **Dashboard speaking** trong Progress (hoặc màn riêng) | `fl_chart` line/bar theo tiêu chí + stat boxes + 3 buổi gần nhất | scroll mượt, builder |
| Client UI | màn **Sổ tay luyện nói** (tab Lỗi / Từ) + ôn flashcard | nối Vocab review | empty/loading/error |
| Client UI | badge/XP trên feedback + hub | hiển thị gamification | không phá layout Phase 1 |
| Feedback | `SpeakingFeedbackPage` (mở rộng) | bật **mũi tên xu hướng** (dữ liệu từ summary) | so đúng vs trung bình |
| l10n | `app_en.arb` + `app_vi.arb` | keys `speakingScenario*`, `speakingProgress*`, `speakingNotebook*`, `speakingBadge*` | `flutter gen-l10n`, không hardcode |

---

## 6. GATE áp dụng

- **UI/UX GATE (có — chạm nhiều layout):** đọc `docs/ui-ux-system/` (README, `00`,`02`,`12`,`11` + student `03`,`04`,`05`,`20`). Dashboard đối chiếu màn **Progress** (tham chiếu chrome). Grid tình huống + sổ tay: token-only, component có sẵn, đủ loading/empty/error, hit target ≥44dp.
- **PERF GATE (có):** dashboard chart + list buổi + grid tình huống → `ListView.builder`/pagination, `BlocSelector`/`buildWhen`, không aggregate nặng trong `build()`, cache summary. Aggregation backend phải có **index** (`userId`+`createdAt`), `.lean()`, tránh N+1 khi gom error bank.
- **BACKEND GATE (có):** controller mỏng, logic ở service, **Zod validate** input (`range`, `scenarioId`), auth middleware đúng; aggregation pipeline có index; seed idempotent.
- **L10N GATE (có):** mọi string mới EN+VI, `gen-l10n`.

---

## 7. Hồi quy tối thiểu + account test
- Free Speaking Phase 1 vẫn chạy: nói → feedback → lưu → Progress (không regression khi tách bucket).
- Chọn tình huống → AI đóng đúng vai → feedback có phần task achievement.
- Dashboard hiển thị đúng sau ≥2 buổi; xu hướng so sánh đúng.
- Sổ tay gom đúng lỗi/từ; nút ôn mở Vocab review.
- Account test: `docs/dev/seeds/` (student có sẵn lịch sử buổi nói).

## 8. Lệnh verify
- Client: `flutter analyze`, `flutter test`, chạy app smoke (scroll dashboard, mở tình huống, ôn tập).
- Backend: test endpoint `scenarios` / `progress/summary` / `evaluate(scenarioId)` (Postman) + kiểm tra aggregation có dùng index (explain).

## 9. HANDOFF PROMPT (Phase 3 của quy trình — giao Cursor)
> Sẽ chốt sau ground-truth. Khung: "Implement Free Speaking **Phase 2** theo `work-order-phase2.md`. ĐỌC TRƯỚC: work-order này + artifact Phase 1 đã land (model/endpoint/feedback page/bloc) + `progressTracker`/`UserDailyProgress` + hệ Vocab + `smartNotificationJob` + `docs/ui-ux-system/` (Progress). Giữ nguyên §1–4 quyết định khoá. Chỉ sửa file trong mục 5; ngoài danh sách → DỪNG hỏi. Không chạm Phase 3 (audio/teacher). L10n EN+VI + gen-l10n. Tự audit + liệt kê file, KHÔNG commit/push."

## 10. Checklist OPUS AUDIT (Phase 4)
- [ ] Tách bucket `speakingFluency` không phá Progress/tool cũ (đọc downstream thật).
- [ ] Aggregation có index, không N+1, `.lean()`.
- [ ] Scenario override Vapi đúng, không rò key; free chat vẫn mặc định.
- [ ] Dashboard: builder/pagination, không rebuild rộng, chart không jank.
- [ ] Sổ tay nối Vocab đúng, không tự xây SRS trùng.
- [ ] Gamification không phá streak/gamification hiện có.
- [ ] l10n EN+VI đủ; loading/empty/error đủ; hit target.
- [ ] Verdict: APPROVED | CHANGES REQUESTED (ghi tracker).

## 11. Phụ thuộc
Cần Phase 1 đã land. Thứ tự nội bộ đề xuất: **2B (dashboard) + 2A (tình huống) trước → 2C (sổ tay) → 2D (gamification)**.
