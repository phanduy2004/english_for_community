# 05 — Học Đọc hiểu (Reading)

> **Một câu:** Học viên đọc một bài viết rồi trả lời trắc nghiệm trong thời gian giới hạn; sau khi nộp xem lại đúng/sai kèm giải thích (vị trí đoạn/câu khoá) và bản dịch song ngữ.

---

## 1. Mục đích nghiệp vụ
Rèn **đọc hiểu văn bản**: học viên đọc một bài (article), trả lời câu hỏi trắc nghiệm trong thời gian giới hạn, rồi xem lại đúng/sai kèm giải thích chỉ rõ **đoạn nào / câu nào** chứa đáp án, cùng bản dịch tiếng Việt của bài + câu hỏi.

## 2. Vai trò & tiền điều kiện
- **Học viên** (đã đăng nhập).
- Cần một bài `Reading` gồm nội dung bài, bản dịch, thời lượng đọc, và mảng câu hỏi (mỗi câu có đáp án đúng + giải thích: lý do, chỉ số đoạn, câu khoá, bản dịch).

## 3. Luồng nghiệp vụ chính
1. Mở bài → nếu đã `completed` và không phải làm lại thì vào Review; ngược lại bắt đầu **đếm ngược**.
2. Tab "Bài đọc" hiển thị nội dung; tab "Câu hỏi" cho chọn đáp án (phân trang nếu nhiều câu).
3. Đồng hồ = `thời lượng đọc × 60` giây; **hết giờ tự nộp**.
4. Nộp bài: **client tự chấm** (so đáp án chọn với đáp án đúng), tính số câu đúng + điểm rồi gửi server.
5. Server lưu kết quả + cập nhật tiến độ + gamification.
6. Client vào Review: đánh dấu đúng/sai, mở giải thích, bật bản dịch bài + câu hỏi; confetti + dialog kết quả với nút "Làm lại".

## 4. Quy tắc nghiệp vụ quan trọng
- **Điểm thang %** = số câu đúng / tổng câu × 100.
- **Tiến độ:** đánh dấu `completed`, tăng số lần làm, và **chỉ nâng điểm cao nhất** (`highScore` chỉ tăng — làm lại kém hơn không làm tụt điểm cũ).
- **Mỗi lần nộp = một bản ghi** (giữ lịch sử); Review dùng bản làm đầu tiên.
- Sau khi nộp: cộng thời gian học + độ chính xác đọc + WPM (nếu có) + gamification.

## 5. Cách làm (kỹ thuật)
- **Model dữ liệu:** `Reading` (bài + câu hỏi có giải thích/bản dịch), `ReadingAttempt` (đáp án đã chấm, điểm, thời lượng), `ReadingProgress` (trạng thái/điểm cao nhất/số lần).
- **Bản dịch:** **soạn sẵn trong DB** (khác nghe hiểu là dịch runtime); bật/tắt qua nút, không gọi API ngoài.
- Không audio, không comment/realtime ở kỹ năng này.
- **Tái sử dụng trong bài thi tích hợp:** cùng widget có thể nhúng vào bài thi (chế độ embedded, callback đẩy đáp án về bài thi).

## 6. Điểm nhấn để trình bày
- Giải thích chỉ rõ **vị trí đoạn** + **câu khoá** để học viên tự dò lại trong bài.
- Bản dịch song ngữ chất lượng cao (soạn sẵn) cho cả bài, câu hỏi và đáp án.
- Widget dùng chung cho cả luyện tập và bài thi.

## 7. Giới hạn & lưu ý trung thực
- **KHÔNG có AI:** đúng/sai theo đáp án đúng; giải thích + bản dịch là dữ liệu admin soạn sẵn.
- **Điểm được TÍNH Ở CLIENT rồi server tin payload** — khác Dictation và Listening Comprehension (server tự chấm). Về liêm chính dữ liệu, điểm reading có thể bị chỉnh từ client. → Đây là khác biệt kỹ thuật đáng nói khi trình bày: **luyện tập Reading không có cơ chế chống gian lận điểm** như 2 kỹ năng nghe. (Khi nhúng vào **bài thi** thì việc chấm/kiểm soát do hệ thống thi đảm nhiệm — xem file `14`, `17`.)

## 8. Dẫn chứng mã nguồn
- Lưu kết quả (tin payload client): `services/readingService.js:85-108`; controller `controllers/readingController.js:88-105`.
- Model: `models/Reading.js`, `ReadingAttempt.js`, `ReadingProgress.js`.
- Client: `feature/reading/reading_detail_page.dart:160-322` (đồng hồ/chấm/review), payload `reading_attempt_payload.dart:13-45`.
