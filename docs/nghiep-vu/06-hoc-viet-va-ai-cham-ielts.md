# 06 — Học Viết & AI chấm IELTS (Writing)

> **Một câu:** Học viên viết bài IELTS Task 2, AI chấm band 4 tiêu chí, **sửa lỗi inline ngay trong bài** (bấm để xem lý do) và sinh bài mẫu — kèm cơ chế **tự kiểm tra AI có gian dối không** và phục hồi JSON nhiều tầng.

---

## 1. Mục đích nghiệp vụ
Luyện viết IELTS Writing Task 2 có phản hồi chất lượng cao: hệ thống **sinh đề** theo chủ đề, học viên viết, **AI chấm band 4 tiêu chí + overall**, **sửa lỗi inline** ngay trong bài văn (không chỉ cho điểm chung chung), và sinh **2 bài mẫu** để học theo. Admin/giáo viên quản lý chủ đề viết có **duyệt + phiên bản hoá (versioning) + rollback** như một CMS thật.

## 2. Vai trò & tiền điều kiện
- **Học viên:** viết + nộp bài (bài ≥ 50 từ mới cho nộp — kiểm ở client).
- **Admin/Teacher:** CRUD chủ đề + duyệt + rollback version (gắn permission `CONTENT_*`).
- Chủ đề phải đang `isActive`.

## 3. Luồng nghiệp vụ chính
1. Học viên chọn chủ đề → server: nếu có bản nháp dở thì tiếp tục, không thì **AI sinh đề** (tiêu đề + đề bài) theo cấu hình chủ đề. Nếu là **bài thi** thì dùng đề cố định do giáo viên gán (mọi học viên chung 1 đề).
2. Học viên viết; client **tự lưu nháp (autosave) mỗi 4 giây**, đếm từ, đo thời gian viết.
3. Nộp → server gọi **AI chấm**, lưu bài với trạng thái `reviewed`, cập nhật thống kê + gamification + tiến độ.
4. Client mở màn nhận xét 4 tab:
   - **Tổng quan:** đề + overall band + 4 điểm thành phần + mẹo chính.
   - **Chi tiết:** từng tiêu chí có gạch đầu dòng + nhận xét.
   - **Viết lại (Rewrites):** từng đoạn với **sửa lỗi inline**.
   - **Bài mẫu:** bài mẫu band 7–8 và band 9.
5. **Quản trị chủ đề:** tạo → mỗi lần sửa **chụp lại phiên bản cũ** → gửi duyệt → duyệt/phát hành → có thể **rollback** về phiên bản trước.

## 4. Quy tắc nghiệp vụ quan trọng
- **Rubric:** 4 tiêu chí IELTS band 0–9 — `tr` (Task Response), `cc` (Coherence & Cohesion), `lr` (Lexical Resource), `gra` (Grammar) + `overall`. Kẹp 0–9, làm tròn 0.5.
- **Ngôn ngữ:** phần phân tích/nhận xét bằng **tiếng Việt**; phần viết lại + bài mẫu bằng **tiếng Anh**.
- **Triết lý chấm "không bắt bẻ":** chỉ sửa lỗi THẬT (chính tả, ngữ pháp, sai từ, dấu câu gây sai nghĩa); câu đúng dù chưa "văn vẻ" thì **giữ nguyên**; bài tốt có thể **0 lỗi** và đó là kết quả đúng.
- **Sửa lỗi inline bắt buộc theo định dạng** `{{từ_cũ||từ_mới||lý_do_tiếng_Việt}}`; **cấm sửa ngầm** (đổi chữ mà không gắn dấu).
- **Bài mẫu:** bản band 7–8 viết lại theo ý học viên; bản band 9 viết mới; tối thiểu 250 từ.
- Bài quá ngắn/spam → band 0.

## 5. Cách làm (kỹ thuật)
- **AI provider:** duy nhất **Groq** (`openai/gpt-oss-120b`) cho cả sinh đề, chấm, sinh mẫu, sửa chữa.
- **Guard chống AI "gian dối" (điểm hay nhất):** sau khi AI trả về, hệ thống **dựng lại "bản gốc"** từ các đoạn viết lại (bỏ dấu sửa về phía từ cũ) rồi so **độ tương đồng từ (Jaccard)** với bài thật. Nếu độ tương đồng **< 0.6** (AI đã paraphrase/tóm tắt thay vì chép nguyên + đánh dấu) hoặc thiếu đoạn → **gọi AI lần 2 để ép đúng định dạng**. (Guard đã nới: bài tốt 0 lỗi không bị ép sửa.)
- **Phục hồi JSON 3 tầng:** `JSON.parse` → thư viện `jsonrepair` → hàm tự viết quét bracket/stack (tôn trọng chuỗi/escape) để cứu JSON bị cụt.
- **Fallback bài mẫu:** nếu call chính bỏ trống bài mẫu, gọi riêng một lần để tab Bài mẫu luôn có nội dung.
- **Render inline diff (client):** dò dấu `{{cũ||mới||lý do}}` → gạch đỏ (cũ) → xanh (mới), bấm mở popup lý do. Nếu AI quên gắn dấu → **client tự diff** đoạn viết lại với bản gốc (khớp đoạn gần nhất bằng Jaccard) và gắn nhãn "Auto Diff".
- **Model dữ liệu:** `WritingSubmission` (đề snapshot + nội dung + feedback đầy đủ + điểm), `WritingTopic` (cấu hình AI + trạng thái duyệt + thống kê), `WritingTopicVersion` (ảnh chụp phiên bản để rollback).

## 6. Điểm nhấn để trình bày
- **Tự kiểm tra độ trung thực của AI** bằng Jaccard 0.6 + auto-repair — chống AI paraphrase ngầm làm mất bài gốc. Đây là chi tiết kỹ thuật độc đáo.
- **Phục hồi JSON 3 tầng** — sản phẩm thật vẫn chạy khi AI trả JSON lỗi.
- Inline diff **tương tác**: bấm vào lỗi xem lý do; có fallback tự diff.
- CMS chủ đề thật: state-machine duyệt + version history + rollback + audit log.

## 7. Giới hạn & lưu ý trung thực
- Chỉ **1 AI (Groq)**; không có Gemini/OpenAI được dùng (dù có trong dependency).
- Điểm band là **AI gợi ý**, không phải giám khảo người. Guard Jaccard chỉ chống paraphrase, **không** kiểm chứng độ đúng của con số band.
- Ngưỡng nộp tối thiểu 50 từ là ở **client**; backend không chặn số từ tối thiểu (chỉ chặn bài quá ngắn qua điểm 0 của AI).

## 8. Dẫn chứng mã nguồn
- Chấm viết + rubric + prompt inline: `services/aiService.js:440-609`.
- Guard Jaccard 0.6 + repair: `aiService.js:91-197` (đặc biệt `105-132`); phục hồi JSON `24-84`; sinh đề/mẫu `202-227, 384-437`.
- Luồng submission (start/draft/submit) + versioning/duyệt/rollback: `services/writingTopicService.js:81-232, 280-433`.
- Model: `models/WritingSubmission.js`, `WritingTopics.js`, `WritingTopicVersion.js`.
- Client: `feature/writing/widgets/interactive_diff_text.dart:24-201`; `writing_feedback_page.dart:457-524`; autosave/min-words `writing_task_page.dart:144-145, 340-366`.
