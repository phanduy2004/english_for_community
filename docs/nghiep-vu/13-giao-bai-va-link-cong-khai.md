# 13 — Giao bài & Link công khai (Assignment)

> **Một câu:** Biến một đề đã publish thành bài giao cho lớp hoặc link công khai, với 4 chế độ thi, khung thời gian, giới hạn lượt chống race-condition, và "đóng băng" đề để sửa đề gốc không ảnh hưởng bài đang giao.

---

## 1. Mục đích nghiệp vụ
Kết nối một **đề thi** với **người làm**: giao cho lớp hoặc phát qua link công khai, đặt chế độ (tự học / theo lịch / phiên trực tiếp / luyện tập), khung thời gian, giới hạn số lượt, và chính sách hiển thị điểm. Có thể lưu cấu hình thành **preset** để tái sử dụng.

## 2. Vai trò & tiền điều kiện
- **GV** sở hữu đề (hoặc quản lý được lớp đích).
- Đề phải ở trạng thái **`published`**; giao cho lớp thì GV phải dạy lớp đó.

## 3. Luồng nghiệp vụ chính
1. Mở dialog "Giao đề"; nạp đề + danh sách lớp + preset.
2. Chọn **đối tượng** (lớp / link công khai), **chế độ** (4 loại), khung giờ, thời lượng, và các "advanced rules" (số lượt, chính sách hiển thị điểm, mức chi tiết kết quả, cho nộp một phần…).
3. Có thể **áp preset** hoặc **lưu preset**.
4. Xác nhận → tạo assignment; nếu là link công khai thì sinh token + hiện dialog copy; nếu là public+realtime thì mở luôn Live Console.

## 4. Quy tắc nghiệp vụ quan trọng
- **Chính sách lượt làm:** `single` (1 lần) / `unlimited` / `limited` (kẹp 2–99 lần). Chế độ **luyện tập** mặc định không tính vào sổ điểm, xem điểm ngay.
- **Điều kiện mở bài theo chế độ:**
  - *Luyện tập*: luôn mở.
  - *Tự học*: mở tới khi quá hạn.
  - *Theo lịch*: chỉ trong `[mở, đóng]`.
  - *Realtime*: phải có phiên do GV mở (xem file `15`).
- **Link công khai:** token có `maxUses` (giới hạn lượt) + `expiresAt` (hết hạn); hết hạn/hết lượt → chặn. GV **xoay token** được (vô hiệu link cũ).

## 5. Cách làm (kỹ thuật)
- **"Đóng băng" đề (frozen snapshot) — điểm hay:** ngay khi tạo assignment, hệ thống copy một bản đề vào assignment. Bài làm học viên **không** lưu snapshot riêng mà **resolve runtime** từ assignment. Nhờ vậy GV **sửa đề gốc về sau không làm đổi** đề của assignment đã giao. (Snapshot tạo **một lần/assignment** để tiết kiệm dung lượng; có cơ chế "heal" để vá nội dung còn thiếu.)
- **Chống race-condition khi giao link giới hạn lượt (điểm hay nhất):** khi nhiều học viên bấm bắt đầu cùng lúc lúc gần hết lượt, hệ thống dùng **cập nhật nguyên tử** `findOneAndUpdate` với điều kiện `$expr` so sánh `usesCount < maxUses` **ngay trong filter** + tăng đếm trong cùng thao tác. Kết quả: **không thể vượt quota** dù đồng thời (tránh bug kinh điển đọc-rồi-ghi).
- **Preset:** lưu cấu hình giao bài để dùng lại, chuẩn hoá qua cùng logic.
- Giao cho lớp → gửi thông báo học viên; public+realtime → tạo sẵn phiên thi.

## 6. Điểm nhấn để trình bày
- **Snapshot 1-bản/assignment + resolve runtime:** tiết kiệm dung lượng khủng (không copy đề vào mỗi bài làm) mà vẫn "miễn nhiễm" với sửa đề gốc.
- **Pattern reservation bằng `$expr`** là cách chuẩn để tránh cấp thừa lượt mà không cần transaction/lock.

## 7. Giới hạn & lưu ý trung thực
- **"Wizard" thực chất là 1 dialog form** (mọi lựa chọn trên cùng màn), không phải nhiều bước.
- Đếm lượt là **lượt bắt đầu**, không phải "số học viên duy nhất".
- Không xoá được assignment đã có bài nộp (buộc **đóng** thay vì xoá).

## 8. Dẫn chứng mã nguồn
- `services/teacherExamAssignmentService.js` (tạo `202-272`, chuẩn hoá config `22-50`, **chống race `348-358`**, xoay token `592-600`, entitlement `602-629`).
- Snapshot: `services/examSnapshotStore.js:66-83`.
- Model: `models/ExamAssignment.js`, `TeacherAssignmentPreset.js`.
- Client: `feature/teacher/layout/teacher_assign_exam_dialog.dart`.
- Doc: `docs/teacher-exam-system/05-exam-execution-and-modes.md`.
