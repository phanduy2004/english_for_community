# 03 — Học Nghe hiểu (Listening Comprehension)

> **Một câu:** Học viên nghe một đoạn audio dài rồi trả lời trắc nghiệm trong thời gian giới hạn; sau khi nộp được xem transcript, giải thích và có thể "nghe lại đúng đoạn chứa đáp án".

---

## 1. Mục đích nghiệp vụ
Kiểm tra khả năng **nghe-hiểu ý** (khác với nghe-chép bắt từng từ): học viên nghe cả đoạn rồi trả lời các câu hỏi trắc nghiệm nhiều lựa chọn, có tính giờ. Sau đó được xem lại transcript, giải thích và **mốc thời gian** chứa câu trả lời để học sâu hơn.

## 2. Vai trò & tiền điều kiện
- **Học viên** (đã đăng nhập).
- Cần một bài `ListeningComprehension` có audio, transcript, thời lượng cho phép, và mảng câu hỏi (mỗi câu có đáp án đúng + phần giải thích: lý do, mốc thời gian gợi ý, câu khoá).

## 3. Luồng nghiệp vụ chính
1. Mở bài → nếu **đã từng làm** thì vào thẳng chế độ Review (không tính giờ); nếu **chưa** thì vào chế độ làm bài và bắt đầu **đếm ngược**.
2. Nạp audio + khởi động đồng hồ = `thời lượng cho phép × 60` giây; có nút tua ±5s, play/pause. **Transcript bị khoá** cho tới khi nộp.
3. Học viên chọn đáp án từng câu (phân trang nếu nhiều câu).
4. Nộp bài (hoặc **hết giờ tự nộp**); client gom đáp án (bỏ trống = -1) gửi lên server.
5. Server chấm, tạo bản ghi kết quả, trả điểm + đúng/sai từng câu.
6. Client sang Review: hiện đúng/sai, mở transcript, confetti + dialog kết quả. Có thể bấm chip **"nghe tại giây X"** (nhảy đến mốc thời gian gợi ý) và bật **dịch toàn bộ sang tiếng Việt**.

## 4. Quy tắc nghiệp vụ quan trọng
- **Chấm ở SERVER:** đúng khi chỉ số đáp án chọn = chỉ số đáp án đúng; bỏ trống luôn sai.
- **Điểm thang %** = số câu đúng / tổng câu × 100.
- **Mỗi lần nộp = một bản ghi mới** (giữ lịch sử, cho làm lại nhiều lần).
- **Hoàn thành lần đầu** (chưa từng làm) mới tính vào "bài đã hoàn thành".
- Thống kê thời lượng bị **kẹp tối đa 2 giờ** để chống dữ liệu rác.

## 5. Cách làm (kỹ thuật)
- **Model dữ liệu:** `ListeningComprehension` (đề + câu hỏi nhúng phần giải thích), `ListeningCompAttempt` (đáp án, điểm %, số câu đúng, thời lượng).
- **Đồng hồ & auto-submit:** đếm ngược ở client; hết giờ tự nộp phần đã chọn.
- **Bản dịch tiếng Việt:** dịch **tại thời điểm xem (runtime) qua Google Translate ở client**, dịch song song transcript + câu hỏi + đáp án + giải thích rồi cache lại.
- Không có realtime/comment ở kỹ năng này.

## 6. Điểm nhấn để trình bày
- **Mốc thời gian gợi ý** cho phép "nghe lại đúng đoạn chứa đáp án" — trải nghiệm học rất tốt.
- Transcript khoá đến khi nộp → **ép nghe thật** thay vì đọc.
- Đã làm rồi thì mở ra là Review luôn (không vô tình làm lại tính giờ).

## 7. Giới hạn & lưu ý trung thực
- **KHÔNG có AI:** chấm bằng so chỉ số đáp án; phần "giải thích" là **nội dung admin soạn sẵn trong DB**, không phải AI sinh khi chấm.
- Bản dịch tiếng Việt phụ thuộc **dịch vụ Google Translate không chính thức** (client) → có thể lỗi/timeout, không lưu vào DB.
- Thời lượng do client gửi (chỉ dùng cho thống kê, đã kẹp trần); **điểm thì server tự tính** nên đáng tin.

## 8. Dẫn chứng mã nguồn
- Chấm + quy tắc: `services/listeningCompService.js:40-147`; controller `controllers/listeningCompController.js:46-64`.
- Model: `models/ListeningComprehension.js`, `ListeningCompAttempt.js`.
- Client: `feature/listening_comp/listening_comp_page.dart:120-352` (đồng hồ, dịch, review); bloc `listening_comp_bloc.dart:13-58`.
