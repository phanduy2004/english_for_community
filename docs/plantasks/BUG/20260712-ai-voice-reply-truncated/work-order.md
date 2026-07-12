# Work-Order — BUG: AI (Vapi "Drew") nói/hiện KHÔNG hết câu, cụt ở "would you like to"

- **Task ID:** `20260712-ai-voice-reply-truncated` · **Loại:** BUG · **Platform:** student mobile · **Cỡ:** MICRO
- **Mục tiêu:** AI trợ lý thoại nói TRỌN câu/câu hỏi (hết cảnh cắt ở "Would you like to…"); bỏ artifact lặp "Would you like to Would".

## 1. Nguyên nhân gốc (đọc code thật)
Hội thoại "Drew" chạy bằng **Vapi** (voice AI real-time) — `lib/feature/speaking/vapi/real_vapi_service.dart`. Text hiển thị = transcript assistant.
- **RC1 (chính): reply bị cắt do budget token quá thấp.** `maxTokens` **KHÔNG** được set ở BẤT KỲ đâu trong repo (grep toàn dự án). Độ dài reply hoàn toàn do assistant trên **Vapi dashboard**.
  - `SpeakingScenarioEntity.toVapiOverrides()` (`core/entity/speaking_phase2_entity.dart:64`) override `model` NHƯNG chỉ có `messages` (system prompt) — **không** có `maxTokens`.
  - Free-chat (scenario == null): `free_speaking_page.dart:325` truyền `widget.scenario?.toVapiOverrides()` = **null** → KHÔNG override gì → 100% theo dashboard.
  - Cắt nhất quán ở câu hỏi chốt "Would you like to…" (~30-40 token). Rất có thể assistant dùng **model reasoning** (gpt-oss/o1/deepseek-r1) → token reasoning ăn hết budget, phần nói ra bị cụt.
- **RC2 (phụ, hiển thị): artifact lặp "Would you like to Would".** `_handleTranscript` (`free_speaking_page.dart:401`) ADD message mới khi message cuối đã final; Vapi finalize 1 mảnh GIỮA câu ("…Would you like to") rồi gửi lại câu từ đầu ("Would you like to talk…") → `_ConversationTurn.combinedText` ghép 2 mảnh trùng nhau bằng dấu space → lặp.

## 2. Fix (code — phần app kiểm soát được)
- **F1:** đặt `maxTokens` rộng cho MỖI reply (const `kVapiReplyMaxTokens = 500`), áp cho CẢ scenario lẫn free-chat:
  - `toVapiOverrides()`: thêm `maxTokens` vào `model`; nhánh `id.isEmpty` trả `{model:{maxTokens}}`.
  - `free_speaking_page.dart` start: fallback `?? {model:{maxTokens}}` khi scenario null.
  - Vapi deep-merge override → chỉ set `maxTokens` (+ `messages`), giữ provider/model từ dashboard.
- **F2:** de-overlap trong `_ConversationTurn.combinedText` — bỏ phần đầu mảnh sau trùng với đuôi mảnh trước (theo TỪ, tối thiểu 2 từ trùng → tránh false-merge), hết lặp câu.

## 3. Scope IN/OUT
- **IN:** `core/entity/speaking_phase2_entity.dart`, `feature/speaking/free_speaking_page.dart`.
- **OUT:** ❌ `real_vapi_service.dart` (mapping transcript giữ nguyên) · ❌ backend · ❌ Vapi dashboard (không sửa được từ code — xem §5).

## 4. Verify
```bash
cd english_for_community
dart analyze lib/feature/speaking/free_speaking_page.dart lib/core/entity/speaking_phase2_entity.dart
```
**Smoke (máy thật, ⭐):** mở Free Speaking → AI nói TRỌN câu hỏi "Would you like to …?" (không cụt); bong bóng không còn lặp từ.

## 5. ⚠️ Lever CHÍNH nằm ở Vapi Dashboard (báo user)
Vì free-chat không override được model và reasoning-model có thể ăn token: **trên Vapi dashboard của assistant** → tăng `model.maxTokens` (≥ 500) VÀ nếu model là loại **reasoning** (gpt-oss/o1/deepseek-r1) thì đổi voice-agent sang **model chat thường** (gpt-4o-mini/llama…) hoặc bật budget đủ cho reasoning. Code F1 chỉ đảm bảo override từ app; dashboard là nguồn cuối.
