# 09 — Gamification & Tiến độ học tập (Progress)

> **Một câu:** Tạo động lực học bằng XP, streak, level, mục tiêu ngày và bảng xếp hạng; đồng thời cung cấp màn "Learning Progress" 6 thẻ thống kê theo kỹ năng.

---

## 1. Mục đích nghiệp vụ
Giữ chân người học và cho họ thấy sự tiến bộ: **cộng điểm XP** theo hoạt động, duy trì **streak** (chuỗi ngày học), **lên level**, đặt **mục tiêu học hằng ngày**, thi đua qua **bảng xếp hạng**, và xem **màn tiến độ 6 thẻ** (theo kỹ năng) + biểu đồ hoạt động.

## 2. Vai trò & tiền điều kiện
- **Học viên** (đã đăng nhập); múi giờ lưu ở hồ sơ người dùng (mặc định `Asia/Ho_Chi_Minh`).
- Nguồn dữ liệu: bảng tiến độ theo ngày (`UserDailyProgress`) và các bản ghi bài học thật (reading/writing/speaking/listening/vocab).

## 3. Luồng nghiệp vụ chính
1. **Khi hoàn thành hoạt động:** service của từng kỹ năng gọi 2 hàm song song — một để cập nhật gamification trên hồ sơ (streak, XP, level, tiến độ ngày), một để `$inc` số liệu chi tiết vào bảng tiến độ theo ngày.
2. **Streak:** mỗi lần lấy hồ sơ đều "chạm" streak — chỉ cần **hoạt động ≥1 lần/ngày** là giữ chuỗi.
3. **Màn Learning Progress 6 thẻ:** chọn khoảng thời gian (ngày/tuần/tháng) → server tổng hợp theo múi giờ người dùng → hiển thị 6 thẻ + hero Level/XP/streak + biểu đồ tuần. Bấm thẻ → xem danh sách bản ghi thật.
4. **Leaderboard:** lấy tất cả học viên sắp theo XP giảm dần; hiển thị **Top 3 + cửa sổ hàng xóm quanh vị trí của mình**.

## 4. Quy tắc nghiệp vụ quan trọng
- **XP mỗi hoạt động:** Viết **100**; Nói tự do `30 + thưởng thời lượng + thưởng điểm`; bộ nói thường **25**; Nghe-chép **20**; Đọc **15**.
- **Level:** `floor(tổng XP / 1000) + 1` — mỗi 1000 XP lên 1 cấp.
- **Streak:** +1 nếu học liên tiếp mỗi ngày; **reset về 1** nếu bỏ lỡ; hiển thị 0 nếu ngày học cuối không phải hôm nay/hôm qua.
- **Mục tiêu ngày:** `dailyMinutes` (mục tiêu phút/ngày) dùng cho phần trăm tiến độ; `dailyLessonGoal` (mục tiêu số bài/ngày, mặc định 5).
- **6 thẻ — đơn vị:** Reading/Dictation/Speaking = **%**, Writing = band **/9**, Vocab/Lessons = số nguyên.
- **Trung bình có trọng số:** khi gộp nhiều ngày, dùng tổng/số-lần (không phải "trung bình của trung bình") để không sai số.

## 5. Cách làm (kỹ thuật)
- **Streak & XP tính ở SERVER;** client chỉ đọc và hiển thị.
- **Nguồn 6 thẻ:** chủ yếu từ bảng tiến độ theo ngày; riêng **Vocab** và **Lessons** đọc trực tiếp bản ghi bài học thật để **số trên thẻ khớp với danh sách chi tiết** (dùng chung nguồn với dialog chi tiết).
- **Đúng múi giờ:** mọi mốc ngày quy về `YYYY-MM-DD` theo múi giờ người dùng, tránh lệch 1 ngày trên host UTC.
- **Logic thuần, test được:** phần tổng hợp tách khỏi DB để chạy unit test.
- **Leaderboard** tính ở server, ghép Top 3 + hàng xóm ±1, chèn separator "..." khi rank không liền nhau.

## 6. Điểm nhấn để trình bày
- Thiết kế "tổng/số-lần" cho **trung bình có trọng số** — tránh sai số khi gộp nhiều ngày.
- Thẻ Speaking gộp cả bộ nói (1−WER) lẫn nói tự do (fluency/9) về cùng thang để không hiện "0%" oan.
- "Thẻ == danh sách": lessons & vocab dùng chung nguồn với dialog chi tiết → số liệu nhất quán.

## 7. Giới hạn & lưu ý trung thực
- **Hai hệ tiến độ song song, dễ lệch:** thông tin gamification (XP/level/streak) nằm trên hồ sơ `User`, còn thống kê chi tiết nằm ở `UserDailyProgress`. **XP không lưu trong bảng tiến độ ngày** → leaderboard/level độc lập với 6 thẻ. Một hoạt động phải nhớ gọi **cả hai** hàm; nếu chỉ gọi một, dữ liệu vênh.
- Nhiều lời gọi cộng điểm là **fire-and-forget** (không await) → lỗi chỉ log, có thể mất điểm âm thầm.
- **Streak "dễ":** tăng chỉ nhờ mở app/lấy hồ sơ (không bắt buộc học thật).
- Bảng xếp hạng chỉ gồm học viên (loại teacher/admin) và tải toàn bộ user vào bộ nhớ rồi mới cắt cửa sổ (chưa phân trang).

## 8. Dẫn chứng mã nguồn
- Gamification: `services/gamificationService.js` (streak `19-59`, XP/level `92-137`); `utils/progressTracker.js`.
- Progress: `services/progressService.js` (summary `217-289`, aggregate `151-213`, detail `291-407`, leaderboard `409-459`); model `models/UserDailyProgress.js`.
- Client: `feature/progress/progress_report_page.dart` (6 thẻ `440-483`, hero `685-820`, leaderboard `536-682`); `core/entity/user_entity.dart:72-74`.
