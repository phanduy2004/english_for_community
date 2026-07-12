# 10 — Quản lý lớp học (Classroom Management)

> **Một câu:** Giáo viên tạo "lớp học" như một không gian tổ chức học viên, phát mã mời/link để tham gia, kiểm soát thành viên, thêm giáo viên phụ, ghi nhật ký hoạt động và lưu trữ lớp.

---

## 1. Mục đích nghiệp vụ
Lớp học là **nền tảng** để giáo viên (GV) tổ chức học viên, **giao bài thi** (lớp là "audience" của assignment), **chat nhóm** và **gửi thông báo**. GV cần: tạo lớp, mời học viên, duyệt/loại thành viên, phân công GV phụ (co-teacher), theo dõi hoạt động, và lưu trữ lớp khi kết thúc.

## 2. Vai trò & tiền điều kiện
- **GV chủ lớp (owner):** toàn quyền.
- **GV phụ (co-teacher):** quản lý được lớp nhưng **không** được archive / xoay mã / thêm-xoá co-teacher.
- **Học viên (student).**
- Tạo lớp cần vai trò teacher/admin + quyền quản lý lớp.

## 3. Luồng nghiệp vụ chính
1. **Tạo lớp:** nhập tên/mô tả/ảnh bìa → hệ thống sinh **mã mời 6 ký tự** + **link mời (token)**; chính sách tham gia mặc định "mở".
2. **Học viên tham gia** bằng mã hoặc link:
   - Chính sách "mở" → vào lớp ngay (active).
   - Chính sách "cần duyệt" → tạo yêu cầu `pending` + gửi thông báo cho owner.
3. **Duyệt/loại thành viên:** owner/co-teacher duyệt (pending→active), từ chối, hoặc loại thành viên; học viên có thể tự rời.
4. **Xoay mã mời:** owner sinh lại mã + token (vô hiệu link cũ khi bị lộ).
5. **Giáo viên phụ (co-teacher):** owner mời (theo username/email) → co-teacher **chấp nhận/từ chối** qua thông báo (luồng 2 chiều).
6. **Nhật ký hoạt động:** ghi các sự kiện (thành viên mới, giao bài, nộp bài, phát kết quả, cờ liêm chính…).
7. **Archive:** owner lưu trữ lớp → **soft-cascade** (ẩn assignment/thành viên/tin nhắn/nhật ký, không xoá vật lý); lớp archived ẩn khỏi danh sách.

## 4. Quy tắc nghiệp vụ quan trọng
- **Chính sách tham gia:** "mở" (vào ngay) vs "cần duyệt" (chờ). Tham gia lớp mở **không tạo thông báo** (đúng nghiệp vụ).
- **Phân quyền quản lý:** owner luôn qua; co-teacher active qua; nhưng **archive/xoay-mã/co-teacher chỉ owner**.
- **Ràng buộc:** mỗi user chỉ 1 bản ghi thành viên/lớp (đổi vai trò/trạng thái thay vì tạo mới).
- **Mã mời:** dùng bảng ký tự bỏ ký tự dễ nhầm (0/O/1/I/L) → dễ đọc/nhập tay.

## 5. Cách làm (kỹ thuật)
- **Sinh mã/link:** mã 6 ký tự (crypto), token 48 ký tự hex, đều unique + retry chống trùng.
- **Nhật ký:** model `ClassroomActivityLog` với enum loại sự kiện, **TTL 365 ngày** tự xoá.
- **Archive:** soft-cascade thống nhất qua service, dọn cả read-state + nhật ký + tin nhắn.
- **Google Classroom / LTI:** hiện là **khung (stub)** — chỉ lưu liên kết `courseId/courseName`, **chưa** đồng bộ roster/bài tập thật với Google.

## 6. Điểm nhấn để trình bày
- Bảng ký tự mã mời loại ký tự dễ nhầm.
- Archive **soft-cascade** giữ được dữ liệu để phục hồi/thống kê.
- Co-teacher là luồng invite **2 chiều** (pending→accept/decline) có thông báo song phương.
- Thông báo membership có nút **Chấp nhận/Từ chối ngay trong chuông**.

## 7. Giới hạn & lưu ý trung thực
- **Google Classroom/LTI chỉ là khung:** không đồng bộ 2 chiều thật.
- **Fan-out cho co-teacher chưa đủ:** một số thông báo (giao bài, có bài nộp, yêu cầu tham gia) hiện chỉ gửi owner, chưa gửi bản sao cho co-teacher active.
- Loại thành viên/tự rời không gửi thông báo cho người bị loại.
- Thông báo là "best-effort" (bọc try/catch) — lỗi thông báo không làm hỏng nghiệp vụ chính.

## 8. Dẫn chứng mã nguồn
- `services/classroomService.js` (mã mời `17-34`, tạo `46-63`, join `409-473`, duyệt/loại `328-407`, xoay mã `311-318`, archive `305-309`, co-teacher `182-288`).
- Model: `models/Classroom.js`, `ClassroomMember.js`, `ClassroomActivityLog.js`.
- `services/ltiGoogleClassroomService.js` (stub); `services/cascadeDeleteService.js:39-54`.
- Client: `feature/student/classes/`, `feature/teacher/teacher_classroom_detail_page.dart`.
