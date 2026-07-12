# 08 — Trợ lý học tập AI (AI Assistant chatbot)

> **Một câu:** Chatbot "cố vấn học tập" trả lời câu hỏi về **chính dữ liệu học tập của người dùng** bằng cách tự quyết định gọi các công cụ (function-calling) truy vấn DB thật, thay vì trả lời chung chung.

---

## 1. Mục đích nghiệp vụ
Cho học viên một cố vấn ảo trả lời được các câu như *"hôm nay tôi học gì?"*, *"điểm yếu của tôi là gì?"*, *"bài tập lớp nào sắp tới hạn?"*, *"điểm bài thi gần nhất?"*. AI **tự chọn công cụ** trong bộ ~20 công cụ để truy vấn dữ liệu thật của người dùng rồi tổng hợp câu trả lời — không bịa, không trả lời chung chung.

## 2. Vai trò & tiền điều kiện
- **Học viên** (đã đăng nhập). Cần cấu hình AI (Groq API key).

## 3. Luồng nghiệp vụ chính
1. Mở dialog trợ lý (✨) và gõ câu hỏi. Client gửi `{message, history}`.
2. Server lấy `userId` **từ token** (không tin id do client/AI đưa) và dựng system prompt = vai trò cố vấn + chiến lược chọn công cụ + **bối cảnh người dùng** (hồ sơ + tiến độ hôm nay).
3. **Vòng lặp function-calling (tối đa 5 vòng):** gọi AI với danh sách công cụ; nếu AI **không** yêu cầu công cụ → trả câu trả lời. Nếu có → server thực thi từng công cụ với `userId` do server tiêm, đưa kết quả về cho AI, rồi lặp lại (AI có thể gọi thêm công cụ hoặc chốt).
4. Nếu hết 5 vòng vẫn đòi công cụ → gọi **một lần chốt** không kèm công cụ để ép AI tổng hợp câu trả lời cuối.
5. Client nhận câu trả lời (Markdown) và render trong bong bóng chat.

## 4. Quy tắc nghiệp vụ quan trọng
- **AI tự chọn công cụ** (`tool_choice: auto`), lặp tối đa 5 vòng, mỗi vòng có thể gọi nhiều công cụ.
- **An toàn dữ liệu (mấu chốt):** `userId` **không bao giờ là tham số** của công cụ — server tự truyền `userId` (từ JWT) làm đối số đầu tiên khi thực thi. Mọi truy vấn đều lọc theo `userId` này. → Dù AI có "bịa" id trong tham số cũng **không thể** đọc dữ liệu người khác. Các công cụ đều **chỉ đọc** (không ghi/xoá DB).
- **Xử lý múi giờ khi hỏi "hôm nay/tuần này":** prompt cấm AI tự bịa ngày; ưu tiên công cụ có tham số `range` để **server tự tính ngày theo múi giờ người dùng** (mặc định `Asia/Ho_Chi_Minh`), kể cả "tuần này/tuần trước/tháng này".
- **AI không bịa số:** các công cụ tính toán (điểm trung bình, %, streak…) **bằng code** rồi mới đưa cho AI.

## 5. Cách làm (kỹ thuật)
- **AI provider:** **Groq** (`openai/gpt-oss-120b`) — dùng chung với chấm Viết/Nói.
- **~20 công cụ** theo chuẩn function-calling, chia 6 nhóm: Hồ sơ (`get_profile`), Tiến độ (`get_daily_activity`, `analyze_weaknesses`, `get_progress_trend`…), Kỹ năng (`get_reading_details`, `get_speaking_details`…), Từ vựng (`get_vocab_review`…), Lớp học (`get_classrooms`, `get_classroom_assignments`, `get_exam_results` — chỉ hiện điểm khi đã phát hành), Đề xuất/xếp hạng (`get_leaderboard`…).
- **Tính ngày theo múi giờ:** resolve range theo lịch múi giờ + tra mốc UTC đầu/cuối ngày bằng binary-search để query chính xác.
- **Bối cảnh tiết kiệm token:** đưa thông tin người dùng dạng **văn bản thuần** (không JSON) vào system prompt.
- **Cấu trúc trả lời:** prompt ép AI xuất Markdown 3 phần (Tổng quan → Chi tiết theo kỹ năng → Lời khuyên & kế hoạch) và *"thiếu dữ liệu thì nói rõ, không bịa"*.

## 6. Điểm nhấn để trình bày
- **Function-calling thật** (không phải RAG nhồi prompt): AI tự chọn công cụ, lặp nhiều vòng, tự tổng hợp — trả lời được câu hỏi phức tạp đa kỹ năng.
- **Bảo mật theo thiết kế:** userId server-injected + công cụ chỉ đọc → không rò rỉ dữ liệu học sinh khác ngay cả khi bị prompt-injection.
- **Xử lý múi giờ công phu** → không sai lệch "hôm nay/tuần trước".
- Có **fallback chốt** khi hết 5 vòng để không bao giờ trả rỗng.

## 7. Giới hạn & lưu ý trung thực
- Thực tế **20 công cụ** (con số "21" trong một số tài liệu là làm tròn/đếm cũ).
- Chỉ dùng **1 provider Groq** (comment "Gemini SDK" ở client datasource là tàn dư lỗi thời, không phản ánh backend).
- **Không streaming:** người dùng chờ hết vòng lặp công cụ mới thấy trả lời (có typing indicator).
- Lịch sử hội thoại gửi lên là **toàn bộ** từ client (chưa cắt ngữ cảnh) — dài dần theo phiên. Chat có rate-limit riêng (theo tài liệu ~60 req/phút).

## 8. Dẫn chứng mã nguồn
- Vòng lặp + tiêm userId + prompt: `services/chatService.js:7-10, 25-95, 97-151`; controller `controllers/chatController.js:7-13`.
- Công cụ: `services/.../tools/definitions.js:14-229` (20 công cụ), `tools/implementations.js:118-1090` (lọc userId + timezone); mốc UTC theo tz `utils/localDayBounds.js:26-54`.
- Provider Groq: `services/aiService.js:11`.
- Client: `feature/home/ai_assistant_dialog.dart`, `bloc_ai/ai_chat_bloc.dart:19-57`.
