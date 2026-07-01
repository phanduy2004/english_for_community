# Sơ đồ Use Case UML — English for Community

> Định dạng UML chuẩn: **Actor** ↔ use case chính (mũi tên liền), use case mở rộng `<<extend>>` (mũi tên đứt, từ extension → base).  
> Preview Markdown để render Mermaid. Cập nhật theo backend + Flutter hiện tại (2026).

**Liên quan:** [use-cases-diagrams.md](./use-cases-diagrams.md) (flowchart / sequence).

**Sơ đồ CSDL (Mermaid):** [database/database-diagrams-uml.md](../database/database-diagrams-uml.md) — cùng format preview Markdown.

**PlantUML (PlantText / tuỳ chọn):** copy file trong [plantuml/](./plantuml/) — ví dụ [teacher-use-case.puml](./plantuml/teacher-use-case.puml).  
⚠️ PlantText **không** chạy code Mermaid bên dưới; cần `@startuml` … `@enduml`.

---

## 2.4.1.1 Phía Guest (chưa đăng nhập)

```mermaid
usecaseDiagram
    actor Guest as "Guest"

    Guest --> (Tra cứu từ điển offline)
    Guest --> (Kiểm tra phiên bản ứng dụng)
    Guest --> (Xem trước bài thi công khai)

    (Đăng ký tài khoản) ..> (Đăng nhập) : <<extend>>
    note right of Guest
        Từ điển: SQLite trên app,
        không qua API backend.
    end note
```

---

## 2.4.1.2 Phía Người dùng (User / Học viên)

```mermaid
usecaseDiagram
    actor User as "User"

    User --> (Đăng nhập)
    User --> (Xem dữ liệu hoạt động ở DashboardHome)
    User --> (Trợ lý AI)
    User --> (Quản lý tài khoản)
    User --> (Xem kết quả quá trình học)
    User --> (Luyện tập nói)
    User --> (Luyện tập từ vựng)
    User --> (Luyện tập kĩ năng đọc)
    User --> (Luyện tập kĩ năng viết)
    User --> (Luyện tập kĩ năng nghe)
    User --> (Tham gia lớp học)
    User --> (Làm bài thi)
    User --> (Quản lý thông báo)
    User --> (Báo cáo sự cố)
    User --> (Nộp đơn trở thành giáo viên)

    (Quên mật khẩu) ..> (Đăng nhập) : <<extend>>
    (Đăng ký tài khoản) ..> (Đăng nhập) : <<extend>>
    (Đăng nhập bằng Google) ..> (Đăng nhập) : <<extend>>

    (Thiết lập nhắc nhở và mục tiêu) ..> (Quản lý tài khoản) : <<extend>>
    (Đổi mật khẩu) ..> (Quản lý tài khoản) : <<extend>>
    (Sửa đổi thông tin cá nhân) ..> (Quản lý tài khoản) : <<extend>>
    (Xóa tài khoản) ..> (Quản lý tài khoản) : <<extend>>

    (Xem lịch sử học bài) ..> (Xem kết quả quá trình học) : <<extend>>
    (Xem thông tin user trong leaderboard) ..> (Xem kết quả quá trình học) : <<extend>>
    (Xem chi tiết thống kê kỹ năng) ..> (Xem kết quả quá trình học) : <<extend>>

    (Làm bài nói read-aloud) ..> (Luyện tập nói) : <<extend>>
    (Luyện nói tự do VAPI) ..> (Luyện tập nói) : <<extend>>
    (Tra từ vựng trong bài nói) ..> (Luyện tập nói) : <<extend>>

    (Tra từ điển) ..> (Luyện tập từ vựng) : <<extend>>
    (Lưu và học từ mới) ..> (Luyện tập từ vựng) : <<extend>>
    (Ôn tập từ SRS) ..> (Luyện tập từ vựng) : <<extend>>

    (Đọc bài và làm câu hỏi) ..> (Luyện tập kĩ năng đọc) : <<extend>>
    (Nộp bài đọc và xem AI feedback) ..> (Luyện tập kĩ năng đọc) : <<extend>>

    (Chọn chủ đề writing) ..> (Luyện tập kĩ năng viết) : <<extend>>
    (Lưu nháp bài viết) ..> (Luyện tập kĩ năng viết) : <<extend>>
    (Nộp bài viết để AI chấm) ..> (Luyện tập kĩ năng viết) : <<extend>>
    (Xem lịch sử bài viết) ..> (Luyện tập kĩ năng viết) : <<extend>>

    (Luyện nghe chép chính tả) ..> (Luyện tập kĩ năng nghe) : <<extend>>
    (Luyện nghe hiểu MCQ) ..> (Luyện tập kĩ năng nghe) : <<extend>>
    (Làm và nộp bài nghe) ..> (Luyện tập kĩ năng nghe) : <<extend>>
    (Bình luận cue bài nghe) ..> (Luyện tập kĩ năng nghe) : <<extend>>

    (Tham gia lớp bằng mã mời) ..> (Tham gia lớp học) : <<extend>>
    (Tham gia lớp bằng link token) ..> (Tham gia lớp học) : <<extend>>
    (Xem danh sách lớp đã ghi danh) ..> (Tham gia lớp học) : <<extend>>

    (Làm bài thi được giao) ..> (Làm bài thi) : <<extend>>
    (Tham gia phiên thi realtime) ..> (Làm bài thi) : <<extend>>
    (Tham gia thi qua link công khai) ..> (Làm bài thi) : <<extend>>
    (Xem kết quả bài thi) ..> (Làm bài thi) : <<extend>>

    (Đọc thông báo) ..> (Quản lý thông báo) : <<extend>>
    (Phản hồi lời mời co-teacher) ..> (Quản lý thông báo) : <<extend>>

    (Gửi báo cáo kèm ảnh) ..> (Báo cáo sự cố) : <<extend>>

    (Xem trạng thái đơn) ..> (Nộp đơn trở thành giáo viên) : <<extend>>
    (Rút đơn) ..> (Nộp đơn trở thành giáo viên) : <<extend>>
```

---

## 2.4.1.3 Phía Giáo viên (Teacher)

> Teacher **kế thừa** toàn bộ use case User (tự học). Sơ đồ dưới chỉ mô tả **phần bổ sung** khi `role = teacher`.

```mermaid
usecaseDiagram
    actor Teacher as "Teacher"

    Teacher --> (Quản lý lớp học)
    Teacher --> (Quản lý ngân hàng đề thi)
    Teacher --> (Giao bài thi)
    Teacher --> (Điều hành phiên thi realtime)
    Teacher --> (Chấm điểm và công bố kết quả)
    Teacher --> (Xem dashboard giáo viên)

    (Tạo và chỉnh sửa lớp) ..> (Quản lý lớp học) : <<extend>>
    (Lưu trữ lớp và đổi mã mời) ..> (Quản lý lớp học) : <<extend>>
    (Duyệt học sinh vào lớp) ..> (Quản lý lớp học) : <<extend>>
    (Quản lý co-teacher) ..> (Quản lý lớp học) : <<extend>>
    (Xem hoạt động lớp) ..> (Quản lý lớp học) : <<extend>>

    (Tạo đề thi nháp) ..> (Quản lý ngân hàng đề thi) : <<extend>>
    (Xuất bản và lưu trữ đề) ..> (Quản lý ngân hàng đề thi) : <<extend>>
    (AI gợi ý đề writing) ..> (Quản lý ngân hàng đề thi) : <<extend>>
    (Nhân bản đề thi) ..> (Quản lý ngân hàng đề thi) : <<extend>>

    (Giao bài cho lớp) ..> (Giao bài thi) : <<extend>>
    (Tạo link thi công khai) ..> (Giao bài thi) : <<extend>>
    (Đóng hoặc sửa assignment) ..> (Giao bài thi) : <<extend>>
    (Lưu preset giao bài) ..> (Giao bài thi) : <<extend>>

    (Tạo phiên thi) ..> (Điều hành phiên thi realtime) : <<extend>>
    (Lobby chờ học sinh) ..> (Điều hành phiên thi realtime) : <<extend>>
    (Bắt đầu và kết thúc phiên) ..> (Điều hành phiên thi realtime) : <<extend>>
    (Giám sát live monitor) ..> (Điều hành phiên thi realtime) : <<extend>>
    (Xem màn hình học sinh) ..> (Điều hành phiên thi realtime) : <<extend>>
    (Đuổi học sinh khỏi phiên) ..> (Điều hành phiên thi realtime) : <<extend>>

    (Xem danh sách bài nộp) ..> (Chấm điểm và công bố kết quả) : <<extend>>
    (Chấm thủ công) ..> (Chấm điểm và công bố kết quả) : <<extend>>
    (AI hỗ trợ chấm) ..> (Chấm điểm và công bố kết quả) : <<extend>>
    (Chấm hàng loạt) ..> (Chấm điểm và công bố kết quả) : <<extend>>
    (Công bố và chốt điểm) ..> (Chấm điểm và công bố kết quả) : <<extend>>
    (Xuất sổ điểm CSV XLSX) ..> (Chấm điểm và công bố kết quả) : <<extend>>
    (Xem báo cáo integrity) ..> (Chấm điểm và công bố kết quả) : <<extend>>

    (Việc cần làm action items) ..> (Xem dashboard giáo viên) : <<extend>>
    (Analytics lớp và bài thi) ..> (Xem dashboard giáo viên) : <<extend>>
    (Lịch deadline và phiên thi) ..> (Xem dashboard giáo viên) : <<extend>>
```

---

## 2.4.1.4 Phía Quản trị viên (Admin)

```mermaid
usecaseDiagram
    actor Admin as "Admin"

    Admin --> (Quản lý người dùng)
    Admin --> (Quản lý nội dung học tập)
    Admin --> (Xử lý báo cáo người dùng)
    Admin --> (Duyệt đơn giáo viên)
    Admin --> (Giám sát hoạt động hệ thống)
    Admin --> (Quản lý phát hành ứng dụng)

    (Xem danh sách user) ..> (Quản lý người dùng) : <<extend>>
    (Ban hoặc gỡ ban user) ..> (Quản lý người dùng) : <<extend>>
    (Xóa mềm và khôi phục user) ..> (Quản lý người dùng) : <<extend>>
    (Đổi role user teacher admin) ..> (Quản lý người dùng) : <<extend>>
    (Xem chi tiết user) ..> (Quản lý người dùng) : <<extend>>

    (CRUD Listening dictation) ..> (Quản lý nội dung học tập) : <<extend>>
    (CRUD Listening comprehension) ..> (Quản lý nội dung học tập) : <<extend>>
    (CRUD Reading) ..> (Quản lý nội dung học tập) : <<extend>>
    (CRUD Speaking set) ..> (Quản lý nội dung học tập) : <<extend>>
    (CRUD Writing topic) ..> (Quản lý nội dung học tập) : <<extend>>
    (Duyệt và rollback version writing) ..> (Quản lý nội dung học tập) : <<extend>>
    (Khôi phục nội dung đã xóa) ..> (Quản lý nội dung học tập) : <<extend>>

    (Xem danh sách báo cáo) ..> (Xử lý báo cáo người dùng) : <<extend>>
    (Cập nhật trạng thái báo cáo) ..> (Xử lý báo cáo người dùng) : <<extend>>
    (Xử lý hàng loạt báo cáo) ..> (Xử lý báo cáo người dùng) : <<extend>>

    (Duyệt đơn giáo viên) ..> (Duyệt đơn giáo viên) : <<extend>>
    (Từ chối đơn giáo viên) ..> (Duyệt đơn giáo viên) : <<extend>>

    (Dashboard thống kê) ..> (Giám sát hoạt động hệ thống) : <<extend>>
    (Xem lịch sử hoạt động học viên) ..> (Giám sát hoạt động hệ thống) : <<extend>>
    (Hàng đợi moderation) ..> (Giám sát hoạt động hệ thống) : <<extend>>
    (Audit log) ..> (Giám sát hoạt động hệ thống) : <<extend>>
    (Export CSV) ..> (Giám sát hoạt động hệ thống) : <<extend>>
    (Theo dõi user online) ..> (Giám sát hoạt động hệ thống) : <<extend>>

    (Duyệt bản release) ..> (Quản lý phát hành ứng dụng) : <<extend>>
    (Lên lịch và publish) ..> (Quản lý phát hành ứng dụng) : <<extend>>
    (Rollback phiên bản) ..> (Quản lý phát hành ứng dụng) : <<extend>>
```

---

## 2.4.1.5 Hệ thống (System Actor)

```mermaid
usecaseDiagram
    actor System as "Hệ thống"

    System --> (Gửi thông báo thông minh)
    System --> (Hết hạn bài thi quá deadline)
    System --> (Tự publish app theo lịch)
    System --> (Nhận bản build từ CI)

    (Nhắc từ vựng hàng ngày) ..> (Gửi thông báo thông minh) : <<extend>>
    (Nhắc ôn SRS) ..> (Gửi thông báo thông minh) : <<extend>>
    (Nudge mục tiêu ngày) ..> (Gửi thông báo thông minh) : <<extend>>
    (Cứu streak) ..> (Gửi thông báo thông minh) : <<extend>>
```

---

## Bảng ánh xạ nhanh — User (giống mẫu luận văn)

| Use case chính | Extend | API / Màn hình |
|----------------|--------|----------------|
| Đăng nhập | Quên MK, Đăng ký, Google | `/api/auth/*`, `login_page` |
| DashboardHome | — | `home_page`, `UserBloc`, `ProgressBloc` |
| Trợ lý AI | — | `/api/chat/ask`, `ai_assistant_dialog` |
| Quản lý tài khoản | Nhắc nhở, đổi MK, sửa profile | `/api/users/profile` |
| Kết quả học tập | Lịch sử, leaderboard, stat detail | `/api/progress/*`, `my_exercise_history` |
| Luyện nói | Read-aloud, VAPI, tra từ | `/api/speaking/*` |
| Từ vựng | Dict, SRS, lưu từ | `/api/vocab/*`, SQLite dict |
| Đọc | Làm bài, AI feedback | `/api/reading/*` |
| Viết | Draft, submit, lịch sử | `/api/writing/*` |
| Nghe | Dictation, MCQ, comment | `/api/listening`, `/api/listening-comp` |
| Lớp học | Mã, token, danh sách | `/api/classrooms/*` |
| Bài thi | Giao bài, live, public link | `/api/exams/*` + Socket |
| Thông báo | Đọc, respond | `/api/notifications/*` |
| Báo cáo | Gửi ảnh | `POST /api/reports` |
| Đơn GV | Nộp, rút, xem trạng thái | `/api/teacher/applications` |
