# 01 - Business Requirements (App Update Notification)

## 1) Bài toán

Khi có phiên bản app mới, người dùng cần được thông báo cập nhật sớm, đúng lúc, đúng mức độ bắt buộc.
Hệ thống cần cho phép đội vận hành phát hành nhanh mà không cần sửa code app mỗi lần.

## 2) Mục tiêu nghiệp vụ

- Tăng tỷ lệ người dùng cập nhật lên bản mới nhất.
- Đảm bảo các bản có lỗi nghiêm trọng có thể bắt buộc cập nhật.
- Giảm support issue do người dùng dùng bản quá cũ.

## 3) Actor

- **Người dùng app**: nhận thông báo cập nhật.
- **Admin/Operator**: tạo release metadata, chọn soft/force update.
- **CI/CD system**: build APK, tạo artifact, cập nhật release metadata.

## 4) Use case chính

1. Dev push code lên nhánh release.
2. CI/CD build thành công APK (và có thể AAB).
3. Hệ thống tạo bản ghi release mới trong backend:
   - version, build number, min supported version, force flag, changelog.
4. App client gọi API kiểm tra version khi:
   - mở app,
   - resume app,
   - theo chu kỳ (ví dụ 6 giờ).
5. Nếu có update:
   - Soft update: hiện dialog cho phép bỏ qua.
   - Force update: khóa luồng sử dụng và buộc cập nhật.

## 5) Non-functional requirements

- API kiểm tra version phản hồi < 300ms trong điều kiện bình thường.
- Có cache hợp lý để giảm tải backend.
- Có log và theo dõi:
  - số lượt check,
  - số lượt hiện popup,
  - số lượt click cập nhật.
- An toàn: chỉ admin mới được publish release metadata.

## 6) Policy update đề xuất

- App version < `min_supported_version` => `force_update`.
- App version < `latest_version` và >= `min_supported_version` => `soft_update`.
- App version = `latest_version` => `up_to_date`.

## 7) Định nghĩa done (business)

- Có thể phát hành release metadata không cần release backend code mới.
- Client nhận đúng trạng thái `up_to_date`, `soft_update`, `force_update`.
- Có dashboard/tối thiểu log để theo dõi adoption.
