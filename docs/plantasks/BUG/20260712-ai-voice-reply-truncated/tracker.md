# Tracker — 20260712-ai-voice-reply-truncated

- **Loại/Cỡ:** BUG · MICRO · student mobile (Vapi voice)
- **Status:** `F1 (app-side maxTokens) REVERTED — Vapi 400 (cần provider+model). F2 (de-overlap) giữ. Fix cụt câu = Vapi DASHBOARD (maxTokens + đổi model reasoning). dart analyze PASS.`
- **Work-order:** [`work-order.md`](work-order.md)

## Nguyên nhân (đọc code thật)
- Hội thoại "Drew" = **Vapi** voice AI (`real_vapi_service.dart`), KHÁC chatService (companion Markdown).
- **RC1:** `maxTokens` KHÔNG set ở đâu trong repo → độ dài reply do Vapi dashboard. `toVapiOverrides` chỉ override `model.messages`; free-chat còn không truyền override. → reply cụt ở "would you like to" (nghi model reasoning ăn token).
- **RC2 (hiển thị):** `_ConversationTurn.combinedText` ghép mảnh transcript trùng → lặp "Would you like to Would".

## Fix
| # | Fix | Trạng thái |
|---|---|---|
| ~~F1~~ | ~~set maxTokens qua `toVapiOverrides`~~ | ❌ **REVERTED** — Vapi trả 400: `assistantOverrides.model.provider must be one of...`. Vapi BẮT BUỘC kèm `provider`+`model` cho mọi tham số model (maxTokens). App chỉ có publicKey+assistantId (`vapi_env_config.dart`), KHÔNG biết model/provider → không set maxTokens từ app được (hardcode sẽ đè model dashboard). ⇒ maxTokens **CHỈ** cấu hình trên Vapi dashboard. |
| F2 | `_mergeOverlap` trong `combinedText` — bỏ phần đầu mảnh sau trùng đuôi mảnh trước (theo từ, ≥2 từ) | ✅ GIỮ (độc lập, an toàn) |

> **Lưu ý Vapi:** override `model.messages` (system prompt) được chấp nhận KHÔNG cần provider (scenario vẫn chạy); nhưng thêm `maxTokens`/tham số model khác → bắt buộc provider+model → 400.

## Bằng chứng
- [x] `dart analyze` 2 file (sau revert): **No issues found**; không còn 400.
- [x] `_mergeOverlap` scratch test: **4/4** (merge overlap; giữ câu thường; contained→giữ prev; 1-từ KHÔNG merge).
- [ ] Smoke máy thật: sau khi tăng maxTokens trên **dashboard** → AI nói trọn "Would you like to …?"; bong bóng hết lặp.

## ⚠️ Lever CHÍNH (Vapi dashboard — user phải làm)
Free-chat không override được model; reasoning-model ăn token. Trên **Vapi dashboard** của assistant: tăng `model.maxTokens` (≥500) VÀ nếu là model **reasoning** (gpt-oss/o1/deepseek-r1) → đổi voice-agent sang model chat thường. Code F1 chỉ đảm bảo override từ app.

## Follow-up
- Nếu sau khi tăng maxTokens vẫn cụt → gần như chắc là reasoning-model trên dashboard.
- Cân nhắc dùng Vapi `conversation-update` message (transcript sạch) thay vì ghép mảnh `transcript`.
