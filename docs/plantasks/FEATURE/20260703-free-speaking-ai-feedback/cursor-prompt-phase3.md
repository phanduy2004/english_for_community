# Prompt giao Cursor — Free Speaking Phase 3 (Phát âm + Thích ứng + Giáo viên)

> Copy phần trong khung. **Chỉ chạy sau khi Phase 1 + 2 đã land. POC audio là cổng chặn — làm trước tiên.**

---

Bạn hãy implement **Phase 3** của "Free Speaking — AI Feedback" (Chấm phát âm + Độ khó thích ứng + Giáo viên theo dõi). **Bắt đầu bằng POC audio, chưa POC xong thì DỪNG báo cáo, không code tiếp 3A.**

## 0. GROUND-TRUTH + POC TRƯỚC (bắt buộc)
1. **Tài liệu:** `docs/plantasks/FEATURE/20260703-free-speaking-ai-feedback/work-order-phase3.md` (đọc HẾT: §2 nghiệp vụ, §3 quyết định, §4 scope, §5 file-level, §6 GATE gồm **PRIVACY**) + `README.md` + `docs/AI-Working-Process-vi.md`.
2. **POC AUDIO (cổng chặn):** xác minh nguồn audio buổi nói:
   - Kiểm tra **Vapi có xuất audio/recording** (webhook/end-of-call) không: `lib/feature/speaking/vapi/real_vapi_service.dart`, tài liệu Vapi.
   - Nếu không → thử **ghi âm client** bằng package `record` (đang comment ở `english_for_community/pubspec.yaml`; quyền `RECORD_AUDIO` đã có ở `android/app/src/main/AndroidManifest.xml`; nhớ mô tả mic iOS `ios/Runner/Info.plist`). **Kiểm tra tranh chấp mic với Vapi.**
   - Kết luận rõ hướng khả thi TRƯỚC khi làm tiếp.
3. **Phase 1+2 đã land (đọc thật):** `SpeakingConversation` + `feedback` schema, endpoint evaluate/service, `speaking_feedback_page.dart`, error bank + `SpeakingScenario` (Phase 2), progress/summary.
4. **Shadowing sẵn có (nối luyện từ):** `lib/feature/speaking/speaking_skills_page.dart` (STT + WER + phát âm từng câu).
5. **Classroom (cho teacher):** `ClassroomMember`/`Classroom` model + route/service + teacher web classroom detail; RBAC `middleware/auth.js` (`requirePermissions`).
6. **UI system teacher:** `docs/ui-ux-system/` (`06`,`07`,`08`,`18`) + student mobile cho tab phát âm/audio player.
7. **l10n:** `app_en.arb` + `app_vi.arb`; `flutter gen-l10n`.

## 1. Quyết định KHOÁ (không đổi)
- Model chấm text vẫn **Groq**; điểm **phát âm** dùng **service riêng** (Azure Pronunciation Assessment mặc định, fallback Google) — KHÔNG nhét vào aiService Groq.
- **PRIVACY bắt buộc:** xin **consent** trước khi ghi âm; **audio auto-delete sau khi chấm**; KHÔNG lưu audio vĩnh viễn; teacher chỉ nghe lại khi có quyền + học viên đồng ý; audio ẩn mặc định.
- **Chỉ Phase 3.** KHÔNG làm lại Vapi, không đổi provider LLM text, không mở rộng ngoài speaking.

## 2. Nguyên tắc
- Backend: service layer, **Zod validate**, **RBAC teacher chặt** (không rò dữ liệu học viên chéo lớp), external API có **timeout/retry/xử lý lỗi & quota**, storage tạm + **auto-delete**, tránh N+1 khi list lớp.
- Client: upload audio nền (nén, giới hạn thời lượng), KHÔNG block UI khi chờ chấm phát âm (async + trạng thái), audio player component, đủ loading/empty/error, hit target.
- Từ chối consent → vẫn nói + chấm text bình thường (không ghi âm).
- DI trong `get_it.dart`; route mới; l10n EN+VI gồm chuỗi consent.

## 3. Thứ tự làm (§11 work-order)
1) **POC audio** → kết luận hướng.
2) **3A Phát âm**: ghi/lấy audio → upload tạm → `pronunciationService` (Azure) → ghép `feedback.pron` → tab **Phát âm** (highlight từ sai + nghe lại + luyện từ, nối shadowing) → xoá audio.
3) **3B Thích ứng**: `recommendNext()` + drill tự sinh từ error bank + điểm → màn "Luyện điểm yếu".
4) **3C Giáo viên**: endpoint classroom speaking + assign (RBAC) + UI teacher web trong classroom detail.
5) l10n EN+VI (`gen-l10n`).

## 4. Xong khi đạt Acceptance §7 work-order-phase3
Không regression Phase 1–2; nói có ghi âm → tab Phát âm có điểm + từ sai + audio **đã bị xoá** sau chấm; từ chối consent vẫn chấm text; teacher xem/giao được, student khác không thấy dữ liệu chéo.

## 5. Sau khi xong
- Tự audit theo §10 work-order (POC kết luận rõ; auto-delete + consent; RBAC chặt; external API có retry/timeout; không block UI; không regression), liệt kê file tạo/sửa + chỗ nghi ngờ.
- **KHÔNG tự commit/push.** Chỗ nào chưa rõ/không khả thi (nhất là audio/riêng tư) → DỪNG hỏi, đừng tự chế hướng khác.
