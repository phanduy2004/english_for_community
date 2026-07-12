# 19 — Thông báo (Notifications)

> **Một câu:** Hệ thống thông báo đa kênh (in-app, realtime socket, push FCM) phân biệt rõ **"chuông"** (việc hệ thống/quan trọng) với **"chat inbox"** (tin nhắn/reaction lớp), kèm nhắc học thông minh theo múi giờ.

---

## 1. Mục đích nghiệp vụ
Đưa đúng thông tin đến đúng người đúng lúc: được giao bài, có yêu cầu tham gia lớp, trả kết quả thi, và **nhắc học** cá nhân hoá. Quan trọng: **tách bạch 2 loại** để không làm phiền người dùng — chuông chỉ dành cho hệ thống/việc quan trọng, còn tin nhắn/reaction lớp đi kênh chat inbox riêng.

## 2. Vai trò & tiền điều kiện
- **Người nhận:** bất kỳ user. **Người gửi:** user khác hoặc hệ thống (`null`).
- Push FCM cần token thiết bị; realtime cần user đang đăng nhập (đã join room cá nhân).

## 3. Luồng nghiệp vụ chính
1. **Tạo & phát:** sự kiện phát sinh → lưu `Notification` vào DB → emit realtime tới room người nhận → gửi push FCM (nếu có token). **Chặn tự-thông-báo** (recipient = sender).
2. **Đọc/đánh dấu:** xem danh sách (phân trang, kèm số chưa đọc); đánh dấu đã đọc / đọc tất cả.
3. **Thông báo hành động (accept/decline):** với lời mời co-teacher và yêu cầu tham gia lớp — trả lời **ngay trong chuông**; xong thì khoá nút.
4. **Bấm để điều hướng:** mỗi loại thông báo map tới một màn đích (giao bài → chi tiết lớp; trả kết quả → bài thi; phiên live → sảnh chờ; nhắc học → từ vựng…).
5. **Trình bày theo ngữ cảnh:** student mobile → banner (hoặc im nếu đang ở đúng màn) / local push khi nền; teacher web → toast góc; teacher mobile → toast/khay hệ thống.

## 4. Quy tắc nghiệp vụ quan trọng — Chuông vs Chat inbox
- **Chuông (bell)** = model `Notification` + sự kiện `new_notification`. Dành cho: membership lớp, co-teacher, exam, nhắc học hệ thống. Có push FCM.
- **Chat inbox** = model tin nhắn/read-state + sự kiện `classroom_chat_inbox_updated`. Dành cho: tin nhắn + reaction lớp. **Không bao giờ ghi vào `Notification`**, không có FCM khi app đóng.
- Hai badge **độc lập**: badge chuông vs badge chat.

## 5. Cách làm (kỹ thuật) — Nhắc học thông minh (Smart Notification Job)
Một cron chạy **mỗi phút**, duyệt user có token FCM, tính giờ **theo múi giờ từng người**, và có 4 khung nhắc:
- **Nhắc từ vựng** tại giờ cá nhân người dùng đặt (kèm tối đa 3 từ cần ôn).
- **Nhắc ôn tập lúc 19:00** nếu còn từ đến hạn.
- **Nhắc mục tiêu ngày lúc 20:00** nếu chưa đạt số bài mục tiêu.
- **Cứu streak lúc 22:00** nếu chưa học hôm nay mà đang có streak.

Chống gửi trùng: job **tự gửi FCM** rồi lưu DB với cờ bỏ qua gửi lại → không double-send. Push xong tự **dọn token FCM hỏng**.

## 6. Điểm nhấn để trình bày
- Nhắc học **tôn trọng múi giờ từng người** → nhắc đúng "đến giờ học" cục bộ.
- Cơ chế tách "ai gửi FCM" khỏi "lưu DB" tránh double-send.
- Trả lời lời mời **ngay trong chuông**; trình bày thông báo khác nhau theo từng app.
- Tự dọn token hỏng theo phản hồi từ FCM.

## 7. Giới hạn & lưu ý trung thực
- **Sai lệch enum:** 3 loại nhắc (ôn tập/mục tiêu/streak) lưu DB với type chung `SYSTEM_ANNOUNCEMENT`, còn "loại thật" nằm trong `data.type` (vì các loại này chưa có trong enum). Icon/điều hướng vẫn map đúng theo `data.type`, nhưng type gốc trong DB không phản ánh đúng.
- Các nhắc này là **fire-and-forget** và bỏ qua socket → **không** cập nhật chuông realtime khi app đang mở (chỉ hiện khi fetch lại inbox hoặc qua FCM).
- Cron mỗi phút quét toàn bộ user có token → chi phí tăng theo quy mô; lệch phút thì bỏ (không bù).
- Chưa có: tắt từng loại thông báo, digest gộp, nhắc hạn bài tập. Thông báo có **TTL 365 ngày** tự xoá.

## 8. Dẫn chứng mã nguồn
- `services/notificationService.js:34-141`; `notificationActionService.js:104-131`; `teacherNotificationHelper.js`.
- Nhắc học: `jobs/smartNotificationJob.js:170-208`.
- Model: `models/Notification.js`.
- Client: `core/notification/app_notification_listener.dart`, `notification_navigation.dart`, `feature/home/bloc_noti/notification_bloc.dart`.
