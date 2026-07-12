# 18 — Thống kê lớp học (Teacher Analytics)

> **Một câu:** Bảng điều khiển đo "sức khỏe lớp" cho giáo viên — số bài nộp theo ngày, điểm trung bình + xu hướng, phân phối điểm, điểm theo kỹ năng, học sinh có nguy cơ, câu khó nhất, on-time/late/missing, và tín hiệu liêm chính — tính đúng theo múi giờ Việt Nam.

---

## 1. Mục đích nghiệp vụ
Giúp GV **thấy nhanh ai cần chú ý, bài nào cần chấm, chủ đề nào lớp yếu**: đo lường kết quả và mức độ tham gia của lớp qua nhiều biểu đồ + KPI, lọc theo khoảng thời gian.

## 2. Vai trò & tiền điều kiện
- **GV** (có quyền giao bài), sở hữu ≥1 lớp hoặc là co-teacher active; có assignment + bài nộp để tổng hợp.

## 3. Luồng nghiệp vụ chính
1. Mở màn Analytics, chọn khoảng thời gian (7–30 ngày).
2. Backend gọi song song 2 nguồn: **KPI tổng hợp** và **biểu đồ** — dùng chung phạm vi lớp để không lệch nhau.
3. Chạy ~12 truy vấn tổng hợp song song trên bài nộp, cộng 2 truy vấn phụ (học sinh nguy cơ + câu khó nhất).
4. Trả về dữ liệu; frontend vẽ biểu đồ.

## 4. Quy tắc nghiệp vụ quan trọng
- **Phạm vi = lớp sở hữu ∪ lớp đồng dạy** (owner + co-teacher active).
- **Cửa sổ N ngày theo LỊCH VN, GỒM hôm nay** (múi giờ +07:00); kỳ trước để so sánh xu hướng.
- **Phân phối điểm:** ưu tiên thang 0–10 tích hợp (5 khoảng 0–2…8–10); không có bài tích hợp thì fallback thang % legacy.
- **Điểm theo kỹ năng:** trung bình 5 kỹ năng, **chỉ tính phần đã chốt điểm**.
- **Học sinh nguy cơ:** ưu tiên "không nộp" > "điểm thấp <50%" > "trễ ≥2 lần".
- **Chống đếm trùng:** mỗi cặp (học sinh, assignment) chỉ giữ bài mới nhất trước khi tính.
- **Câu khó nhất:** bỏ câu còn chờ chấm tay, chỉ lấy câu có ≥3 lượt trả lời, sắp theo %đúng tăng dần.
- **"Cần chấm"** dùng **định nghĩa chuẩn chung** với inbox/summary để 3 nơi không lệch.

## 5. Cách làm (kỹ thuật)
- Tổng hợp bằng MongoDB aggregation với `$dateToString` timezone `+07:00`; ~12 pipeline chạy song song.
- Toàn bộ logic "thuần" (tính xu hướng, dedupe, phân loại, bucket…) **tách khỏi DB để unit test tất định** — nhận `now` từ ngoài để test không phụ thuộc thời gian thực.
- Comment trong code đánh số "finding #1..#8" khớp đợt sửa đúng đắn analytics (timezone VN, gồm hôm nay, dedupe, phạm vi co-teacher).

## 6. Điểm nhấn để trình bày
- **Xử lý timezone Việt Nam đúng** (không lệch ngày) — điểm dễ sai ở các dự án khác.
- **Dedupe chống đếm trùng** + **phạm vi co-teacher** — nghiệp vụ tinh tế.
- Logic thuần, có unit test → đáng tin và dễ bảo trì.
- Ưu tiên thang 0–10 tích hợp nhưng vẫn fallback thang % cũ để không vỡ dữ liệu.

## 7. Giới hạn & lưu ý trung thực
- Học sinh nguy cơ chỉ xét assignment **đang active** (bài đã đóng không hiện).
- Biểu đồ **gộp tất cả lớp** của GV (chưa có bộ lọc theo từng lớp riêng ở tầng biểu đồ).
- Khoảng thời gian chỉ nhận 7–30 ngày.

## 8. Dẫn chứng mã nguồn
- `services/teacherAnalyticsChartsService.js`, `teacherAnalyticsScope.js`, `teacherDashboardService.js`.
- Controller `controllers/teacherExamController.js:117-122`.
- Client: `feature/teacher/teacher_analytics_page.dart`.
- Doc: `docs/teacher-exam-system/16-analytics-feature.md`.
