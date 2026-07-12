# 20 — Tự cập nhật app & Quản lý phát hành (App Update / Release)

> **Một câu:** App tự phát hiện bản mới và cài APK ngay trong app (có %, huỷ được); phía admin quản lý vòng đời phát hành bằng state machine có duyệt + hẹn giờ + chống hạ cấp + rollback, và CI tự tạo bản ứng viên.

---

## 1. Mục đích nghiệp vụ
Vì app phân phối **ngoài CH Play** (domain riêng), cần cơ chế **tự cập nhật trong app** và **quy trình phát hành có kiểm soát**: thông báo đúng mức độ (khuyến nghị vs bắt buộc), tách "CI build" khỏi "quyết định cho user nhận bản nào" (admin duyệt), và an toàn khi có sự cố (rollback).

## 2. Vai trò & tiền điều kiện
- **App client** (mọi user, kể cả chưa đăng nhập): gọi kiểm tra phiên bản.
- **Admin phát hành:** duyệt/từ chối/hẹn giờ/publish/rollback.
- **CI/CD:** tạo bản ứng viên qua token bí mật.

## 3. Luồng nghiệp vụ chính

**Phía client (tự cập nhật):**
1. `AppUpdateGuard` kiểm tra phiên bản khi khởi động / khi quay lại app / khi đổi trạng thái đăng nhập (bỏ qua web, throttle 30 phút).
2. Server trả trạng thái: `up_to_date` / `soft_update` (khuyến nghị) / `force_update` (bắt buộc — không cho tắt).
3. Bấm "Cập nhật": Android + có link tải → **tải + cài APK trong app**; ngược lại mở URL ngoài.

**Phía phát hành (release lifecycle):**
1. CI build xong → tạo **bản ứng viên** ở trạng thái `pending_approval`.
2. Admin **duyệt** → `approved`; hoặc **từ chối** (kèm lý do).
3. Admin **hẹn giờ** (`scheduled`) hoặc **publish** ngay.
4. Cron mỗi phút **auto-publish** các bản đã tới giờ.
5. Khi publish: lưu trữ bản cũ, kích hoạt bản mới; **rollback** được về bản cũ khi lỗi.

## 4. Quy tắc nghiệp vụ quan trọng
- **State machine hợp lệ:** `pending_approval → approved | rejected`; `approved → scheduled | published | rejected`; `scheduled → published | rejected`; `published → archived`. Vi phạm → lỗi 400.
- **soft vs force:** `versionCode < minSupportedVersionCode` → **force**; cờ force + cũ hơn latest → **force**; cũ hơn latest → **soft**; còn lại → up-to-date.
- **Chống hạ cấp:** publish bản có `versionCode ≤ bản đang active` → bị chặn; thêm unique index (platform, môi trường, versionCode).
- **Hẹn giờ phải ở tương lai** (nếu quá khứ, cron sẽ publish ngay, bỏ qua xác nhận).
- **Chỉ 1 bản active** mỗi platform/môi trường.

## 5. Cách làm (kỹ thuật)
- **So sánh phiên bản theo `versionCode` (số nguyên)** trên server — không so chuỗi versionName (tránh lỗi semver).
- **Rollback đúng đắn:** chọn bản trước theo `versionCode`, **không** theo thời điểm publish (tránh flip-flop).
- **Enforce state machine ở service** trước khi lưu; mọi hành động ghi **audit log** (kèm trạng thái trước/sau).
- **Tải & cài APK:** xin quyền cài đặt, tải với báo **%**, **huỷ được** (huỷ giữa chừng coi là "thành công mềm"), tự **dọn file cũ**, cài bằng mở file APK; force thì không cho huỷ tải.

## 6. Điểm nhấn để trình bày
- Cron biến "scheduled" thành cơ chế **phát hành theo lịch** không cần thao tác tay; ràng buộc "tương lai" bảo vệ khỏi bỏ qua xác nhận force.
- **Chống hạ cấp 2 lớp** (guard lúc publish + unique index) + rollback theo versionCode tránh flip-flop.
- In-app APK updater với %, huỷ, dọn file cũ, fallback browser — phù hợp phân phối ngoài store.

## 7. Giới hạn & lưu ý trung thực
- Cài trong app **chỉ Android**; iOS/khác chỉ mở URL. Web bỏ qua hoàn toàn.
- **Không kiểm tra checksum/chữ ký APK** sau tải — tin cậy hoàn toàn link tải.
- Không tìm thấy release → trả `up_to_date` (fail-open); cấu hình sai thì client không được nhắc (chỉ log cảnh báo).
- `rejected`/`archived` là ngõ cụt (muốn dùng lại phải tạo ứng viên mới).

## 8. Dẫn chứng mã nguồn
- `services/appVersionService.js` (version-check `384-441`, publish/anti-downgrade `258-313`, rollback `315-360`); `releaseStateMachine.js:10-30`.
- Model `models/AppRelease.js`; job `jobs/appReleaseSchedulerJob.js`; routes `appVersionRoutes.js`, `adminAppReleaseRoutes.js`.
- Client: `feature/app_update/app_apk_updater.dart`, `app_update_guard.dart`.
- Doc: `docs/auto-update/`.
