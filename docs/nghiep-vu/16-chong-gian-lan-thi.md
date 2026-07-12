# 16 — Chống gian lận thi (Exam Integrity / Anti-cheat)

> **Một câu:** Thu thập tín hiệu hành vi bất thường khi làm bài (rời tab, mất tập trung, copy-paste, thoát fullscreen), quy đổi thành mức rủi ro low/medium/high để giáo viên giám sát — dữ liệu gửi dạng delta cộng dồn để không mất khi mạng chập chờn.

---

## 1. Mục đích nghiệp vụ
Cung cấp cho GV **tín hiệu khách quan** về hành vi đáng ngờ trong lúc thi, để giám sát realtime và rà soát sau. **Không tự huỷ bài/trừ điểm** — chỉ là công cụ **hỗ trợ quyết định** cho GV.

## 2. Vai trò & tiền điều kiện
- **Học viên:** đối tượng bị giám sát; chỉ khi lượt làm đang diễn ra. Chỉ chủ bài mới gửi được tín hiệu cho bài của mình.
- **GV:** tiêu thụ (giám sát realtime + tổng hợp + nhật ký lớp).

## 3. Luồng nghiệp vụ chính
1. Vào bài → bật theo dõi; trên web ép fullscreen (best-effort).
2. Phát hiện sự kiện → client gửi **delta** ngay lập tức.
3. Server validate, **cộng dồn**, tính lại mức rủi ro, lưu, phát cho GV, và **ghi cờ nhật ký lớp nếu rủi ro cao**.
4. Nộp/hết giờ → dừng theo dõi.

## 4. Quy tắc nghiệp vụ quan trọng

**4 tín hiệu đo được:**
- **Số lần rời tab/app** (có khử nhiễu để không đếm gấp đôi).
- **Thời gian mất tập trung** (giây rời khỏi màn thi).
- **Số lần copy-paste** (bắt cả phím tắt lẫn nút "Paste" trên menu chuột phải/long-press).
- **Thoát fullscreen** (chỉ web).

**Ngưỡng mức rủi ro (cụ thể):**
- 🔴 **high:** rời tab ≥ 5 **HOẶC** mất focus ≥ 120s **HOẶC** copy-paste ≥ 3.
- 🟠 **medium:** rời tab ≥ 2 **HOẶC** mất focus ≥ 45s **HOẶC** copy-paste ≥ 1 **HOẶC** từng thoát fullscreen.
- 🟢 **low:** còn lại.

**Quy tắc cộng dồn:**
- **Monotonic (chỉ tăng):** nhận delta thì cộng thêm; nhận giá trị tuyệt đối thì lấy max (chống lùi số).
- **Latch fullscreen:** đã thoát một lần thì giữ trạng thái đó (duy trì tối thiểu medium).

## 5. Cách làm (kỹ thuật)
- **Delta cộng dồn (điểm hay):** client gửi **từng sự kiện dạng delta**, không tự tích luỹ ở client. Server nhận và cộng dồn → **không mất số liệu** khi client reload/mất trạng thái, tránh race.
- **Chống spam:** validate schema, loại field lạ, **kẹp trần** mỗi request (chống bơm số khổng lồ).
- **Ghi cờ nhật ký lớp:** khi rủi ro cao → ghi sự kiện `integrity_flag` vào nhật ký lớp (dấu vết audit).
- **Phát realtime cho GV:** payload giám sát có mức rủi ro + các con số; console tô cờ ⚑ khi medium/high; tổng hợp theo bài giao (đếm high/medium).
- **Công thức rủi ro là hàm thuần**, tách riêng để **unit test**.

## 6. Điểm nhấn để trình bày
- **Delta + cộng dồn monotonic + kẹp trần:** kiến trúc chống mất/lặp/spam rất chắc.
- **Bắt copy-paste 2 đường** (phím vật lý + menu Paste) → phủ cả mobile lẫn web.
- Thoát fullscreen đưa vào medium + "latch" → một khi thoát là "dính" cả lượt.

## 7. Giới hạn & lưu ý trung thực
- Best-effort: mất mạng/OS đóng băng lúc chuyển nền có thể mất event → con số là **cận dưới**.
- Ngưỡng **cố định toàn hệ thống**, chưa cấu hình được cho từng bài giao.
- Chưa hiển thị thông báo cho học viên biết đang bị giám sát.
- Fullscreen phụ thuộc trình duyệt; mobile không có tín hiệu này.
- **Không tự động trừng phạt** — quyết định vẫn ở GV.

## 8. Dẫn chứng mã nguồn
- `services/examIntegrityService.js` (ngưỡng `29-41`, cộng dồn `44-75`, validate/ghi cờ `78-126`).
- Client: `feature/student/exams/exam_integrity_tracker.dart:28-136`.
- Console GV: `feature/teacher/teacher_exam_session_console_page.dart:608-709`; tổng hợp `examLiveMonitorService.js`.
- Doc: `docs/product/bao-cao-nghiep-vu-chong-gian-lan-thi.md`.
