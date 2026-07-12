# 14 — Làm bài thi (Student Exam Runner)

> **Một câu:** Học viên làm bài tích hợp nhiều phần, hệ thống tự lưu tiến độ liên tục, đồng hồ do **server** quyết định, nộp thủ công hoặc **hết giờ tự nộp**, và xem lại đáp án khi được phát hành.

---

## 1. Mục đích nghiệp vụ
Cho học viên làm bài thi được giao gồm nhiều phần (Grammar + các kỹ năng), **không mất bài** khi mạng chập chờn hay reload, làm bài công bằng theo thời gian do server kiểm soát, và xem lại kết quả khi giáo viên phát hành.

## 2. Vai trò & tiền điều kiện
- **Học viên** thuộc lớp hoặc có token public hợp lệ; assignment còn `active`.

## 3. Luồng nghiệp vụ chính
1. **Bắt đầu:** tạo lượt làm (attempt). Nếu đã có lượt đang làm dở → **trả lại lượt cũ** (chống tạo trùng khi reload). Kiểm tra cửa sổ thời gian + chính sách lượt.
2. **Nạp bài:** lấy đề đã "đóng băng" + bối cảnh (tên lớp/GV, các mốc giờ, chính sách hiển thị điểm…).
3. **Làm bài — tự lưu (autosave) theo từng thay đổi:** mỗi lần gõ dictation / chọn reading / viết writing / trả lời grammar → gửi ngay lên server, lưu vào lượt làm.
4. **Nộp:** nếu không cho nộp một phần thì bắt buộc hoàn thành mọi phần mới cho nộp; chấm tự động Grammar/Listening/Reading, để Writing/Speaking chờ chấm.
5. **Hết giờ tự nộp:** đồng hồ client kiểm tra mỗi giây, quá hạn → tự nộp (cưỡng chế). Server cũng tự cưỡng chế khi truy cập lần kế hoặc qua cron.
6. **Xem lại:** chỉ khi chính sách cho phép (điểm ngay / chờ phát hành / không bao giờ), và xem đáp án chi tiết chỉ khi đã phát hành + mức chi tiết là "đầy đủ".

## 4. Quy tắc nghiệp vụ quan trọng
- **Server là nguồn thời gian:** deadline = min(`bắt đầu + thời lượng`, `giờ đóng lớp`), tính lúc bắt đầu và lưu ở lượt làm. Client chỉ hiển thị/đếm dựa trên mốc này.
- **Autosave:** lưu ngay theo từng thay đổi (chỉ live-view mới debounce), điều kiện đang làm + chưa quá hạn.
- **Nộp bài (tích hợp):** nếu không cho nộp một phần và không cưỡng chế → phải hoàn thành hết mới nộp.
- **Điểm tổng hợp nhiều kỹ năng:** mỗi thành phần thang **0–10**, điểm cuối = **trung bình cộng** các thành phần đã chấm xong (Listening 2 phần thì gộp; Writing quy đổi band IELTS → thang 10).

## 5. Cách làm (kỹ thuật)
- **Bắt đầu idempotent:** reload không tạo bài mới, không mất tiến độ.
- **Autosave lưu ở `ExamAttempt.answers`** (không có collection riêng); mỗi lần merge nông theo phần/câu.
- **Hết giờ:** khi truy cập một lượt đã quá hạn, server tự nộp (`force`) và **chấm phần đã làm** thay vì cho 0; cron quét các lượt quá hạn ngoài phiên live.
- **Đề "đóng băng":** lượt làm không giữ snapshot, mà lấy từ assignment → học viên thấy đúng đề đã đóng băng dù GV sửa đề gốc.
- **Realtime live-view:** ngoài đáp án, client đẩy "đang xem phần nào" lên server để GV soi màn hình (xem file `15`).

## 6. Điểm nhấn để trình bày
- **Không mất bài:** idempotent start + autosave từng thay đổi + đề đóng băng.
- **Hết giờ vẫn công bằng:** chấm phần đã làm, không cho 0 cả bài.
- Giữ state panel khi chuyển tab (không mất bản nháp writing).

## 7. Giới hạn & lưu ý trung thực
- Autosave **mỗi thay đổi = 1 request** (chỉ live-view debounce) → thao tác nhanh sinh nhiều round-trip.
- **Điểm tổng là trung bình cộng KHÔNG trọng số** — GV **không** đặt được trọng số riêng cho từng kỹ năng (đây là giới hạn thật; nếu ai hỏi "có đặt trọng số không" thì trả lời trung thực là chưa).
- Đồng hồ client chỉ để hiển thị + kích auto-submit; nếu đóng máy, cưỡng chế nộp phụ thuộc lần truy cập kế/cron (độ trễ nhỏ).

## 8. Dẫn chứng mã nguồn
- `services/examAttemptService.js` (start `1479-1548`, autosave `1550-1580`, submit `1582-1739`, deadline `239-273`, hết giờ `278-297`).
- Chấm tổng hợp: `services/examIntegratedScoring.js` (final `508-540`, gộp listening `469-506`, band→10 `34-38`).
- Client: `feature/student/exams/integrated_exam_runner_page.dart` (autosave `581-755`, đồng hồ/auto-submit `84-152`, xem điểm `387-407`).
- Doc: `docs/exam-scoring/integrated-skill-scoring.md`.
