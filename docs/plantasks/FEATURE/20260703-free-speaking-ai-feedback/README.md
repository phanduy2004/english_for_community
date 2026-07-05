# Free Speaking — AI Feedback & Coaching · Roadmap 3 Phase

> Bộ tài liệu nghiệp vụ + work-order cho việc nâng cấp **Free Speaking** từ "chỗ nói chuyện" thành **vòng lặp học có phản hồi**. Tuân theo [`docs/AI-Working-Process-vi.md`](../../../AI-Working-Process-vi.md) (Brain/Implement/Audit).

## Nghiệp vụ tổng (bức tranh lớn)

Người học nói tiếng Anh với AI (voice, qua Vapi). Sau **mỗi** cuộc trò chuyện, hệ thống **thu lại nội dung đã nói**, dùng AI **chấm điểm + góp ý cải thiện** dựa trên chính lời người học, **lưu lại để theo dõi tiến bộ**, và dần **cá nhân hoá** việc luyện tập theo điểm yếu.

```
⚙️ Chọn tình huống & mục tiêu → 🎙️ Nói với AI → 📊 Báo cáo đánh giá
      ↑                                                     ↓
   🔁 Luyện điểm yếu  ← 📈 Theo dõi tiến bộ ← 📓 Sổ tay lỗi/từ
```

## Ba phase

| Phase | Tên | Giá trị nghiệp vụ | Trạng thái | Tài liệu |
|------|-----|-------------------|-----------|----------|
| **1 — MVP** | Feedback sau hội thoại | Nói xong có ngay báo cáo 4 tiêu chí (song ngữ) + góp ý before/after + chữa lỗi + nâng cấp từ + lưu buổi + cộng Progress. **Đủ đáp ứng yêu cầu gốc.** | ✅ Sẵn sàng giao Cursor | [`work-order.md`](work-order.md) · [`cursor-prompt.md`](cursor-prompt.md) |
| **2 — Học sâu** | Tình huống + Tiến bộ + Sổ tay | Buổi nói **có mục tiêu** (kịch bản/CEFR), **theo dõi tiến bộ** theo thời gian, **sổ tay lỗi/từ** + ôn tập, gamification. Biến các buổi rời rạc thành hành trình học. | 📋 Đã lên kế hoạch | [`work-order-phase2.md`](work-order-phase2.md) |
| **3 — Chuyên sâu** | Phát âm + Thích ứng + Giáo viên | **Chấm phát âm** (audio + Azure/Google), độ khó **thích ứng**, drill tự sinh theo điểm yếu, **giáo viên** theo dõi trong lớp. | 📋 Đã lên kế hoạch | [`work-order-phase3.md`](work-order-phase3.md) |

## Phụ thuộc & thứ tự
- **Phase 1 là nền móng bắt buộc** (bắt transcript + model `SpeakingConversation` + endpoint chấm). Phase 2 & 3 xây trên đó.
- Làm **tuần tự 1 → 2 → 3**. Khuyến nghị: hoàn tất Phase 1, cho user dùng thật, thu phản hồi rồi mới bắt Phase 2.
- Trong Phase 2, ưu tiên **Dashboard tiến bộ + Tình huống** trước (giá trị cao); **Gamification** làm sau.

## ⚠️ Lưu ý dùng tài liệu Phase 2 & 3
Đây là **bản nghiệp vụ + kế hoạch định hướng**. Vì Phase 1 sẽ thêm/đổi code (model, endpoint, entity, màn feedback), **trước khi implement Phase 2 hoặc 3 phải chạy lại Phase 1 "Ground-truth analysis"** theo `AI-Working-Process-vi.md` (Opus/Explore đọc code THẬT tại thời điểm đó) để chốt mục 5 (diff cụ thể) và các GATE. Không code Phase 2/3 chỉ từ tài liệu này mà chưa verify code hiện trạng.

## Quyết định đã khoá (áp cho cả 3 phase)
- Feedback **song ngữ**: nhận xét/giải thích tiếng Việt, ví dụ/từ/câu mẫu tiếng Anh.
- Model chấm hội thoại: **Groq `gpt-oss-120b`**, JSON mode (Phase 3 thêm Azure/Google cho phát âm).
- Không lưu audio ở Phase 1–2; **chỉ Phase 3** mới ghi/lưu audio (kèm chính sách riêng tư).
