# 2.4 Mô hình hóa yêu cầu — Danh sách Use Case chính

> Mục đích: **gom** các chức năng nhỏ lẻ (≈36 chức năng trong bản cũ) thành **các Use Case chính** theo từng tác nhân.
> Mỗi UC chính đại diện cho một **mục tiêu nghiệp vụ hoàn chỉnh**; các thao tác con được mô hình hóa bằng quan hệ `<<extend>>` / `<<include>>` thay vì tách thành use case riêng.
> Dùng kèm sơ đồ: [use-cases-uml.md](./use-cases-uml.md).

## Tác nhân (Actors)

| Tác nhân | Mô tả |
|----------|-------|
| **Guest** | Người dùng chưa đăng nhập. |
| **User (Học viên)** | Người dùng đã đăng nhập, tự học 4 kỹ năng + từ vựng. |
| **Teacher (Giáo viên)** | Kế thừa toàn bộ quyền của User, bổ sung nghiệp vụ lớp học & thi cử. |
| **Admin (Quản trị viên)** | Quản trị người dùng, nội dung, hệ thống. |
| **System (Hệ thống)** | Tác nhân tự động: gửi thông báo, hết hạn bài thi, phát hành app theo lịch. |

---

## 2.4.1 Lược đồ Use Case (tổng hợp)

### A. Guest — 3 use case chính

| Mã | Use case chính | Mô tả ngắn | Chức năng con (`<<extend>>`) |
|----|----------------|-----------|------------------------------|
| UC-G01 | **Xác thực tài khoản** | Tạo tài khoản & vào hệ thống | Đăng ký (OTP email), Đăng nhập, Đăng nhập Google, Quên mật khẩu |
| UC-G02 | **Tra cứu từ điển offline** | Tra nghĩa/phiên âm bằng SQLite nhúng, không cần mạng | Xem chi tiết từ |
| UC-G03 | **Xem trước bài thi công khai** | Mở link thi public để xem trước/khởi động | Kiểm tra phiên bản ứng dụng |

### B. User (Học viên) — 10 use case chính

| Mã | Use case chính | Mô tả ngắn | Chức năng con gom vào (`<<extend>>` / `<<include>>`) |
|----|----------------|-----------|-----------------------------------------------------|
| UC-U01 | **Quản lý tài khoản** | Xem/cập nhật hồ sơ, bảo mật, cài đặt học tập | Xem & sửa thông tin cá nhân, Đổi mật khẩu, Cài mục tiêu hằng ngày, Cài nhắc nhở học tập, Xóa tài khoản, Đăng xuất |
| UC-U02 | **Xem Dashboard & tiến độ học tập** | Tổng quan hoạt động và kết quả học | Xem Dashboard trang chủ, Xem báo cáo tiến độ, Xem lịch sử làm bài, Xem chi tiết thống kê theo kỹ năng, Xem bảng xếp hạng |
| UC-U03 | **Luyện Nghe (Listening)** | Nghe hiểu & chép chính tả | Lọc/chọn bài nghe, Nghe–chép chính tả (Dictation), Nghe hiểu trắc nghiệm (MCQ), Nộp bài, Bình luận/thảo luận theo câu |
| UC-U04 | **Luyện Nói (Speaking)** | Luyện phát âm & hội thoại AI | Đọc theo câu mẫu (read-aloud, ghi âm tính giờ), Hội thoại tự do với AI (VAPI voice-to-voice), Tra từ trong câu speaking |
| UC-U05 | **Luyện Đọc (Reading)** | Đọc hiểu & làm bài tập | Lọc/chọn bài đọc, Làm câu hỏi trắc nghiệm, Nộp bài & xem nhận xét AI, Xem lại bài (giải thích & dịch song ngữ) |
| UC-U06 | **Luyện Viết (Writing)** | Viết luận theo chủ đề, AI chấm | Chọn chủ đề, Soạn thảo, Tự lưu nháp (Autosave), Nộp bài để AI chấm, Xem phản hồi & sửa lỗi, Xem lịch sử/bài mẫu |
| UC-U07 | **Học từ vựng (Vocabulary)** | Tra – lưu – ôn tập từ | Tra từ điển, Xem chi tiết & ghi lịch sử, Lưu từ (bookmark), Thêm từ vào lộ trình học, Ôn tập Flashcard theo SRS (lặp lại ngắt quãng) |
| UC-U08 | **Trợ lý AI** | Hỏi đáp kiến thức & tra cứu tiến độ bằng chat | Hỏi đáp ngữ pháp/từ vựng, Truy vấn tiến độ học |
| UC-U09 | **Tham gia lớp học & làm bài thi** | Vào lớp, làm bài được giao | Tham gia lớp bằng mã/link, Xem lớp đã ghi danh, Làm bài được giao, Tham gia phiên thi realtime, Thi qua link công khai, Xem kết quả bài thi |
| UC-U10 | **Tương tác hệ thống** | Thông báo, báo lỗi, đăng ký giáo viên | Nhận & đọc thông báo, Phản hồi lời mời co-teacher, Gửi báo cáo sự cố (kèm ảnh), Nộp/rút đơn trở thành giáo viên & xem trạng thái |

> **Gọn hơn bao nhiêu:** từ ~30 use case rời của User → còn **10 use case chính**. Các thao tác như *“Lưu từ”, “Thêm từ vào lộ trình”, “Xem chi tiết từ”* không còn là use case độc lập mà là `<<extend>>` của **UC-U07 Học từ vựng**.

### C. Teacher (Giáo viên) — 6 use case chính

> Teacher **kế thừa toàn bộ** use case của User; phần dưới là **bổ sung** khi `role = teacher`.

| Mã | Use case chính | Mô tả ngắn | Chức năng con (`<<extend>>`) |
|----|----------------|-----------|------------------------------|
| UC-T01 | **Quản lý lớp học** | Vòng đời lớp & thành viên | Tạo/sửa lớp, Lưu trữ lớp & đổi mã mời, Duyệt học sinh, Quản lý co-teacher, Xem hoạt động lớp |
| UC-T02 | **Quản lý ngân hàng đề thi** | Soạn & quản lý đề | Tạo đề nháp, Xuất bản/lưu trữ đề, AI gợi ý đề writing, Nhân bản đề |
| UC-T03 | **Giao bài thi** | Phân phối đề cho học sinh | Giao bài cho lớp, Tạo link thi công khai, Đóng/sửa assignment, Lưu preset giao bài |
| UC-T04 | **Điều hành phiên thi realtime** | Tổ chức thi trực tiếp | Tạo phiên & lobby, Bắt đầu/kết thúc, Live monitor, Xem màn hình học sinh, Đuổi học sinh khỏi phiên |
| UC-T05 | **Chấm điểm & công bố kết quả** | Chấm và trả điểm | Xem bài nộp, Chấm thủ công, AI hỗ trợ chấm, Chấm hàng loạt, Công bố/chốt điểm, Xuất sổ điểm CSV/XLSX, Xem báo cáo gian lận (integrity) |
| UC-T06 | **Xem dashboard giáo viên** | Tổng quan giảng dạy | Việc cần làm (action items), Analytics lớp/bài thi, Lịch deadline & phiên thi |

### D. Admin (Quản trị viên) — 6 use case chính

| Mã | Use case chính | Mô tả ngắn | Chức năng con (`<<extend>>`) |
|----|----------------|-----------|------------------------------|
| UC-A01 | **Quản lý người dùng** | Kiểm soát tài khoản & quyền | Xem danh sách/chi tiết user, Ban/gỡ ban, Xóa mềm & khôi phục, Đổi role (user/teacher/admin) |
| UC-A02 | **Quản lý nội dung học tập** | CMS toàn bộ học liệu | CRUD Listening (dictation & comprehension), Reading, Speaking set, Writing topic; Duyệt/rollback version; Khôi phục nội dung đã xóa |
| UC-A03 | **Xử lý báo cáo người dùng** | Tiếp nhận & xử lý report | Xem danh sách báo cáo, Cập nhật trạng thái, Xử lý hàng loạt |
| UC-A04 | **Duyệt đơn giáo viên** | Xét duyệt nâng quyền | Duyệt đơn, Từ chối đơn |
| UC-A05 | **Giám sát hoạt động hệ thống** | Theo dõi & kiểm toán | Dashboard thống kê, Lịch sử hoạt động học viên, Hàng đợi moderation, Audit log, Export CSV, Theo dõi user online |
| UC-A06 | **Quản lý phát hành ứng dụng** | Quản lý version app | Duyệt bản release, Lên lịch & publish, Rollback phiên bản |

### E. System (Hệ thống) — 4 use case chính

| Mã | Use case chính | Mô tả ngắn | Chức năng con (`<<extend>>`) |
|----|----------------|-----------|------------------------------|
| UC-S01 | **Gửi thông báo thông minh** | Tự động nhắc học | Nhắc từ vựng hằng ngày, Nhắc ôn SRS, Nudge mục tiêu ngày, Cứu streak |
| UC-S02 | **Hết hạn bài thi quá deadline** | Tự đóng bài quá hạn | — |
| UC-S03 | **Tự publish app theo lịch** | Phát hành theo lịch đã duyệt | — |
| UC-S04 | **Nhận bản build từ CI** | Tiếp nhận artifact build | — |

---

## 2.4.2 Đặc tả tóm tắt các Use Case chính (mẫu)

> Dưới đây là mẫu đặc tả cho UC chính — gộp nhiều chức năng cũ vào **một bảng**, thay vì mỗi chức năng một bảng.

### UC-U07 — Học từ vựng (Vocabulary)

| Mục | Nội dung |
|-----|----------|
| **Tên** | Học từ vựng |
| **Tác nhân** | Học viên (User) |
| **Mô tả** | Người dùng tra cứu, lưu trữ và ôn tập từ vựng theo cơ chế lặp lại ngắt quãng (SRS). |
| **Tiền điều kiện** | Đã đăng nhập; dữ liệu từ điển sẵn sàng. |
| **Hậu điều kiện** | Từ được lưu vào kho cá nhân và/hoặc lịch trình ôn tập được cập nhật. |
| **Luồng chính** | 1) Tra từ → 2) Xem chi tiết (hệ thống tự ghi lịch sử) → 3) Lưu (bookmark) hoặc thêm vào lộ trình → 4) Ôn tập bằng Flashcard theo SRS. |
| **Luồng mở rộng** | `<<extend>>` Tra từ điển · Xem chi tiết & ghi lịch sử · Lưu từ · Thêm vào lộ trình · Ôn tập SRS. |

### UC-T05 — Chấm điểm & công bố kết quả

| Mục | Nội dung |
|-----|----------|
| **Tên** | Chấm điểm & công bố kết quả |
| **Tác nhân** | Giáo viên (Teacher) |
| **Mô tả** | Giáo viên chấm bài nộp (thủ công hoặc có AI hỗ trợ), công bố và xuất điểm. |
| **Tiền điều kiện** | Bài thi đã được giao và có bài nộp. |
| **Hậu điều kiện** | Điểm được chốt và học sinh xem được kết quả. |
| **Luồng chính** | 1) Xem danh sách bài nộp → 2) Chấm (thủ công / AI hỗ trợ / hàng loạt) → 3) Xem báo cáo gian lận → 4) Công bố & chốt điểm → 5) Xuất sổ điểm CSV/XLSX. |
| **Luồng mở rộng** | `<<extend>>` AI hỗ trợ chấm · Chấm hàng loạt · Xem báo cáo integrity · Xuất sổ điểm. |

> Áp dụng đúng mẫu trên cho các UC còn lại; mỗi UC chính chỉ cần **1 bảng đặc tả**.

---

## Tổng kết số lượng

| Tác nhân | Use case chính | (Chức năng con đã gom) |
|----------|:--------------:|:----------------------:|
| Guest | 3 | ~5 |
| User | 10 | ~30 |
| Teacher | 6 | ~28 |
| Admin | 6 | ~30 |
| System | 4 | ~7 |
| **Tổng** | **29 UC chính** | **~100 thao tác con** |

So với bản cũ liệt kê tới ~36 chức năng rời rạc chỉ cho User+Admin, bản gom nhóm giúp **sơ đồ use case dễ đọc**, đúng chuẩn UML (use case = mục tiêu nghiệp vụ, không phải từng nút bấm), và phần đặc tả ngắn gọn hơn nhiều.
