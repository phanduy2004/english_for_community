# Hướng dẫn cài đặt & chạy thử lần đầu

> ▶ **THAY THẾ** mục "Cách chạy" hiện có ở cuối báo cáo bằng nội dung dưới đây.
> Backend đã chạy sẵn trên server nên **không cần cài đặt máy chủ** — chỉ cần cài ứng dụng và đăng nhập.

## 1. Yêu cầu thiết bị
- Điện thoại/máy tính bảng **Android** (khuyến nghị Android 8.0 trở lên).
- Dung lượng trống tối thiểu **~500 MB** (bộ cài ~214 MB do tích hợp sẵn từ điển offline).
- Kết nối Internet cho các tính năng trực tuyến (AI, lớp học, thi, chat); riêng **Từ điển** dùng được ngoại tuyến.

## 2. Cài đặt ứng dụng Android (APK)

**Bước 1 — Tải APK bản mới nhất.** Chọn một trong hai nguồn:
- **GitHub Releases (khuyến nghị, luôn có bản mới nhất):** truy cập
  `https://github.com/phanduy2004/english_for_community/releases`
  → chọn bản có số build cao nhất (`auto-v1.0.0-buildNN`) → tải tệp `e4c-android-v1.0.0_NN.apk`.
  *(Bản hiện hành: `e4c-android-v1.0.0_35.apk`.)*
- **Google Drive (bản dự phòng):** `https://drive.google.com/drive/folders/1WPWvwdXV9MQh0bs2WGSEOHzCE4u3CPO4`

**Bước 2 — Mở tệp APK vừa tải.**

**Bước 3 — Cho phép cài từ nguồn ngoài.** Vì ứng dụng phân phối trực tiếp (không qua CH Play), Android sẽ cảnh báo và chặn "cài từ nguồn không xác định". Vào **Cài đặt → cho phép cài đặt** cho trình duyệt/trình quản lý tệp đang dùng → quay lại → nhấn **Cài đặt**. (Cảnh báo rủi ro là bình thường với bản APK ngoài chợ — chọn "Vẫn cài đặt".)

**Bước 4 — Mở ứng dụng và cấp quyền khi được hỏi:**
- **Micro** — luyện kỹ năng Nói, hội thoại với AI.
- **Máy ảnh** — chụp/đổi ảnh đại diện, đính kèm hình trong chat/báo cáo.
- **Thông báo** — nhắc học, thông báo lớp học và bài thi.

**Bước 5 — Các lần sau không cần tải tay.** Ứng dụng tự kiểm tra phiên bản; khi có bản mới sẽ hiện hộp thoại **"Cập nhật ngay"** (cập nhật OTA ngay trong app).

## 3. Đăng nhập và dùng thử
- Dùng tài khoản trong bảng **"Danh sách tài khoản dùng thử theo vai trò"** (Học viên / Giáo viên / Quản trị viên).
- Hoặc **đăng ký tài khoản mới** (xác thực OTP qua email) hoặc **đăng nhập bằng Google**.
- Sau khi đăng nhập, ứng dụng tự đưa vào đúng khu vực theo vai trò (Học viên / Giáo viên); vai trò **Khách** có thể tra từ điển mà không cần đăng nhập.

## 4. Truy cập trang Quản trị (Web Admin)
- Mở trình duyệt và truy cập: **`https://english4community.online`**
- Đăng nhập bằng tài khoản **Quản trị viên** (ví dụ `admin@englishapp.com`) để vào bảng điều khiển: quản lý người dùng, nội dung, báo cáo và **phát hành phiên bản ứng dụng**.

## 5. Ghi chú
- **Không cần cài đặt backend:** máy chủ (API, cơ sở dữ liệu, realtime) đã được triển khai sẵn trên nền tảng đám mây.
- **iOS:** bản dùng thử được phân phối dưới dạng APK cho Android; phiên bản iOS không kèm trong gói dùng thử này.
- Lần cài đặt đầu tiên có thể mất thời gian tải do kích thước bộ cài lớn (tích hợp từ điển offline).
