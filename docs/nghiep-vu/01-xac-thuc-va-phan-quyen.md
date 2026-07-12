# 01 — Xác thực & Phân quyền (Authentication & RBAC)

> **Một câu:** Cấp danh tính cho 3 loại người dùng, bảo vệ API bằng JWT ngắn hạn + refresh dài hạn tự làm mới, phân quyền theo permission, hỗ trợ đăng ký có OTP email và đăng nhập Google.

---

## 1. Mục đích nghiệp vụ
Đây là "cổng vào" của toàn hệ thống. Nó phải: (1) xác định **bạn là ai** (user / teacher / admin), (2) giữ **phiên đăng nhập liền mạch** để người dùng không bị đăng xuất giữa chừng, (3) **chặn truy cập trái phép** vào chức năng của vai trò khác, và (4) đảm bảo **an toàn tài khoản** (mật khẩu băm, xác thực email, refresh token xoay vòng).

## 2. Vai trò & tiền điều kiện
- **Khách (guest):** được đăng ký / đăng nhập / quên mật khẩu.
- **User đã xác thực email** (`isVerified = true`): mới được đăng nhập.
- **Teacher / Admin:** truy cập các API có gắn quyền (`requirePermissions`).
- Hạ tầng cần: khoá bí mật JWT, service account Firebase (verify Google token + gửi FCM), SMTP để gửi OTP.

## 3. Luồng nghiệp vụ chính

**A. Đăng ký + xác thực OTP**
1. Người dùng đăng ký (`accountType` = user/teacher). Server suy ra vai trò: chọn "Teacher" → cấp role `teacher`, chọn "admin" → **từ chối**, còn lại → `user`.
2. Server băm mật khẩu (bcrypt), sinh **OTP 6 số**, lưu user ở trạng thái `isVerified = false`, gửi OTP qua **email**.
3. Màn OTP đếm ngược 60s; nhập đúng OTP → tài khoản được `isVerified = true`. Cho phép gửi lại OTP (cooldown 60s).

**B. Đăng nhập**
1. Đăng nhập bằng **email hoặc username** + mật khẩu.
2. Server chặn nếu: chưa xác thực email, tài khoản tạo bằng Google (bắt "Continue with Google"), sai mật khẩu, hoặc đang bị ban.
3. Thành công → phát **access token + refresh token**; lưu **bản băm SHA-256 của refresh** vào DB; client lưu cả 2 token vào **secure storage** (Keychain/Keystore).

**C. Tự làm mới token (refresh)**
1. Access hết hạn → client gọi `auth/refresh` kèm refresh token.
2. Server đối chiếu **hash** refresh trong DB; hợp lệ → **xoay vòng**: phát access + refresh MỚI, lưu hash mới (refresh cũ vô hiệu ngay).

**D. Đăng nhập Google**
1. Client lấy Firebase ID token (web: popup; mobile: google_sign_in) → gửi lên server.
2. Server verify token qua Firebase Admin; email chưa có → tạo user mới (`isVerified = true`, `loginMethod = google`); rồi phát token như đăng nhập thường.

**E. Quên / đặt lại mật khẩu**
- `forgot-password` luôn trả 200 (chống dò tài khoản); người dùng nhập OTP `forgot` + mật khẩu mới để đặt lại.

## 4. Quy tắc nghiệp vụ quan trọng
- **Thời hạn token:** access **15 phút**, refresh **7 ngày**. Payload chỉ chứa `userId`.
- **OTP:** 6 số, sống **10 phút**, tối đa **5 lần sai**, gửi lại cách nhau 60s.
- **Rate limit theo IP (cửa sổ 15 phút):** login 15 lần, OTP/email 10 lần, refresh/google 40 lần.
- **RBAC — quyền suy ra từ vai trò** (một nguồn sự thật duy nhất `ROLE_PERMISSIONS`):
  - `admin` = `['*']` (toàn quyền).
  - `teacher` = 7 quyền cụ thể: quản lý lớp, quản lý thành viên, quản lý đề, chạy phiên thi, giao bài, đọc chấm, ghi chấm.
  - `user` = không có quyền quản trị.
- **Ẩn dữ liệu nhạy cảm:** khi trả về client, tự xoá `password`, OTP, `refreshToken`… khỏi object user.

## 5. Cách làm (kỹ thuật)
- **Single-flight refresh (điểm hay nhất):** khi access hết hạn mà app đang bắn **nhiều request cùng lúc**, interceptor chỉ cho **một** request đi refresh; các 401 còn lại **xếp hàng chờ**. Refresh xong → **replay** toàn bộ request đang chờ với access mới (theo pattern *snapshot + drain* để tránh lỗi sửa danh sách khi đang duyệt). Nhờ vậy tránh "refresh storm" và tránh các refresh token vô hiệu lẫn nhau. Refresh thất bại → tự đăng xuất về `/login`.
- **Lưu token:** client lưu access + refresh trong FlutterSecureStorage; server chỉ lưu **hash** của refresh (không lưu access, không lưu refresh dạng thô).
- **Middleware:** `authenticate` verify access + nạp `req.user`; `requirePermissions([...])` so quyền được cấp với quyền yêu cầu (wildcard `*` pass tất cả).
- **Chống tự khoá hệ thống:** admin không được tự đổi vai trò của mình, không được hạ cấp **admin cuối cùng**; mọi thay đổi vai trò ghi **audit log**.

## 6. Điểm nhấn để trình bày
- Refresh token **xoay vòng + băm khi lưu** (rotation + hash-at-rest) — chuẩn bảo mật production, không phải chỉ "lưu token rồi dùng lại".
- Interceptor tự refresh **single-flight** xử lý concurrency tinh tế — đây là chi tiết kỹ thuật gây ấn tượng.
- Đăng nhập linh hoạt bằng email **hoặc** username; hỗ trợ cả Google.

## 7. Giới hạn & lưu ý trung thực
- **"Đơn xin làm giáo viên" (pending → approved/rejected) hiện CHƯA có trong code** — mới chỉ nằm ở tài liệu thiết kế. Thực tế: ai đăng ký `accountType = teacher` sẽ **thành teacher ngay sau khi xác thực OTP** (không qua admin duyệt). Con đường thứ hai là admin đổi vai trò user→teacher thủ công. → Khi trình bày nên nói đúng: *"cấp quyền giáo viên qua đăng ký hoặc admin nâng cấp; luồng duyệt đơn là hướng phát triển"*.
- **"Permission tách khỏi role" đúng ở tầng thiết kế** nhưng hiện quyền suy 100% từ vai trò — chưa có override quyền cho từng user.
- OTP lưu dạng thô; `logout` chỉ xoá refresh trong DB (access cũ vẫn hợp lệ đến khi hết 15 phút — không có blacklist).

## 8. Dẫn chứng mã nguồn
- Backend: `services/authService.js` (register `101-145`, verifyOtp `173-222`, login `224-276`, refresh `335-372`, google `373-422`); `lib/jwt_token.js:8-70` (access 15m / refresh 7d); `utils/tokenHash.js`.
- RBAC: `constants/permissions.js:47-66`; `middleware/auth.js:5-51`; `middleware/authRateLimit.js`.
- Firebase: `config/firebase.js`; `models/User.js` (role, OTP, toJSON `92-106`); promote: `controllers/adminController.js:281-330`.
- Flutter: `core/api/app_jwt_interceptor.dart:40-180` (single-flight); `core/api/token_storage.dart`; `feature/auth/bloc/user_bloc.dart`; `feature/auth/register_page.dart:200-228`.
- Thiết kế (chưa code): `docs/teacher-exam-system/02-teacher-role-and-permissions.md`.
