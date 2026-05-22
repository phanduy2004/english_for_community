# 06 - Nghiệp vụ duyệt release bởi Admin

## 1) Mục tiêu nghiệp vụ

Hệ thống phải tách rõ 2 việc:

1. **Build kỹ thuật tự động** khi nhánh `main` có thay đổi source code.
2. **Phê duyệt nghiệp vụ** để quyết định có cho user nhận bản cập nhật hay không.

Điều này đảm bảo:

- Dev có thể release nhanh và liên tục.
- Admin kiểm soát chất lượng/pháp lý/vận hành trước khi publish.
- User chỉ nhận update đã được duyệt.

## 2) Vai trò

- **Developer**:
  - Push code lên `main`.
  - Theo dõi build kết quả và ghi chú thay đổi.
- **CI/CD**:
  - Tự động build APK/AAB mỗi khi source code `main` thay đổi.
  - Tạo bản ghi release ở trạng thái `pending_approval`.
- **Admin Release Manager**:
  - Xem danh sách release chờ duyệt.
  - Duyệt / từ chối / lên lịch publish.
  - Chọn chính sách `soft_update` hoặc `force_update`.
- **User app**:
  - Chỉ nhận thông tin update từ các release ở trạng thái `published`.

## 3) Luồng nghiệp vụ chuẩn

1. Developer merge PR vào `main`.
2. CI/CD tự chạy:
   - test,
   - build artifact,
   - tạo release candidate trong backend (`pending_approval`).
3. Admin vào màn hình quản lý phiên bản:
   - kiểm tra changelog, build metadata, commit SHA, kết quả test.
4. Admin quyết định:
   - **Approve + Publish now** -> release chuyển `published`.
   - **Approve + Schedule publish** -> release chuyển `approved`, chờ lịch.
   - **Reject** -> release chuyển `rejected` (không đến user).
5. App client khi gọi `version-check`:
   - Chỉ lấy release `published` mới nhất.

## 4) Quy tắc bắt buộc

- CI/CD **không được tự publish cho user**.
- Mọi release từ CI/CD phải vào hàng chờ duyệt.
- `force_update` chỉ admin mới có quyền bật.
- Mọi thao tác duyệt/từ chối/phát hành phải có audit log.

## 5) Trường hợp đặc biệt

### A. Build thành công nhưng test quality fail thủ công

- Admin `reject` release với lý do.
- Dev sửa và push `main` lại để tạo candidate mới.

### B. Có lỗi production nghiêm trọng

- Admin có thể publish `force_update` cho bản hotfix.
- Nếu cần, admin có thể rollback bản đang published.

### C. Có nhiều candidate cùng lúc

- Admin chỉ được publish 1 bản active mới nhất cho mỗi `platform + environment`.

## 6) KPI vận hành

- Thời gian từ build xong đến duyệt xong (SLA).
- Tỷ lệ release bị reject.
- Tỷ lệ rollback sau publish.
- Tỷ lệ user lên bản mới sau 24h/72h.
