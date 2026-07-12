# 21 — Quản trị hệ thống (Admin Console)

> **Một câu:** Trung tâm vận hành nền tảng — thống kê tổng quan, quản lý người dùng (ban/xoá mềm/khôi phục/đổi vai trò), CMS nội dung có duyệt + version + rollback, ops center, quản lý báo cáo, và nhật ký kiểm toán bất biến (TTL 365 ngày).

---

## 1. Mục đích nghiệp vụ
Cho admin công cụ **vận hành và kiểm soát toàn nền tảng**: nắm số liệu (bài nộp, chi phí AI, người dùng hoạt động, báo cáo), quản lý người dùng, quản lý nội dung học tập (CMS), duyệt/rollback nội dung, xử lý báo cáo người dùng, và giữ **dấu vết mọi hành động quản trị**.

## 2. Vai trò & tiền điều kiện
- **Admin** (toàn quyền `*`); mọi route admin đều kiểm quyền. Content ops cần quyền `CONTENT_*`.

## 3. Luồng nghiệp vụ chính
1. **Dashboard:** thống kê bài nộp / chi phí AI / báo cáo / người dùng hoạt động + biểu đồ; KPI người dùng; đếm nội dung.
2. **Quản lý người dùng:** liệt kê, **ban/unban**, **xoá mềm**, **khôi phục**, thao tác hàng loạt, **đổi vai trò** (nâng user→teacher), export CSV.
3. **CMS nội dung (chủ đề viết):** sửa → tạo snapshot version → gửi duyệt → duyệt/phát hành → xem versions → **rollback**.
4. **Ops Center:** hàng đợi kiểm duyệt (có triage/SLA), ma trận quyền, export CSV.
5. **Báo cáo (report):** người dùng gửi report → admin cập nhật trạng thái.
6. **Audit log:** xem nhật ký hành động quản trị.

## 4. Quy tắc nghiệp vụ quan trọng
- **Ban:** tạm (theo giờ, mặc định 24h) hoặc vĩnh viễn; đều xoá refresh token + **kick realtime** (force_logout).
- **Xoá user = soft-delete** (đánh dấu, không xoá vật lý) + cascade; có màn "deleted users" để khôi phục.
- **Đổi vai trò an toàn:** không được đổi vai trò của chính mình; **không hạ cấp admin cuối cùng**; ghi audit trước/sau.
- **Timezone VN (+07:00):** mọi khoảng ngày/biểu đồ tính theo lịch Việt Nam.
- **CMS duyệt:** `draft → pending_review → approved | published | rejected`; review cần quyền duyệt.
- **Report:** `pending → reviewed | resolved | rejected`.

## 5. Cách làm (kỹ thuật)
- **Audit log bất biến + TTL:** `AdminAuditLog` ghi actor/hành động/đối tượng/IP/thiết bị/before-after; **tự xoá sau 365 ngày** bằng TTL index; ghi best-effort (nuốt lỗi để không chặn hành động chính).
- **Cascade delete an toàn:** soft-delete lan truyền (assignment → attempt/session; classroom → assignment/member/message/log…), **không hard-delete** → giữ toàn vẹn dữ liệu, không tạo bản ghi mồ côi.
- **Content versioning:** mỗi lần sửa chủ đề viết **chụp lại phiên bản cũ** trước khi ghi; rollback chụp bản hiện tại rồi khôi phục.
- **Export CSV:** escape chuẩn CSV; realtime phát `force_logout` + cập nhật trạng thái tới room admin.
- **Ước lượng chi phí AI:** writing theo số từ, speaking/dictation theo thời lượng audio × đơn giá.

## 6. Điểm nhấn để trình bày
- **Audit log bất biến + TTL 365 ngày** — chuẩn compliance; ghi cho mọi hành động nhạy cảm.
- **2 lớp an toàn quản trị:** không tự hạ vai trò mình + không hạ admin cuối → tránh khoá cứng hệ thống.
- **Soft-delete + cascade + restore** giữ toàn vẹn dữ liệu.
- CMS chủ đề viết có **full state machine duyệt + version + rollback** (không chỉ CRUD).

## 7. Giới hạn & lưu ý trung thực
- **Không có "đơn giáo viên" riêng:** GV được tạo bằng admin **đổi vai trò** user→teacher (không có model/queue duyệt đơn). Nếu tài liệu nói "duyệt đơn giáo viên", thực tế chỉ là promotion vai trò.
- **CMS versioning chỉ đầy đủ cho Chủ đề viết** — các môn khác có màn quản trị nhưng chưa có version/approval tương đương ở backend (versioning không đồng nhất).
- Cascade khi xoá user chỉ dọn thông báo (giữ dữ liệu học tập cho lịch sử/analytics).
- Audit ghi best-effort → nếu DB lỗi lúc ghi log, hành động vẫn thành công nhưng thiếu vết.

## 8. Dẫn chứng mã nguồn
- `services/adminService.js`, `adminAuditService.js`, `cascadeDeleteService.js`, `reportService.js`, `writingTopicService.js`.
- Model: `models/AdminAuditLog.js` (TTL `22`), `Report.js`, `WritingTopics.js`, `WritingTopicVersion.js`.
- Quyền: `constants/permissions.js`; routes `adminRoutes.js`, `writingTopicRoutes.js`.
- Client: `feature/admin/` (dashboard_home, user_management, content_management, ops_center, report_management).
