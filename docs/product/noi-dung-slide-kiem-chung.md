# Nội dung slide khóa luận E4C

> Nội dung đã được đối chiếu với mã nguồn thực tế. Cập nhật: 2026-07-07.
> Repo: English for Community (Flutter) + Backend (Node.js).

---

## ⚠️ BẢNG ĐÍNH CHÍNH (những chỗ slide/báo cáo cũ ghi sai)

| # | Slide/báo cáo cũ ghi | Thực tế |
|---|---|---|
| 1 | AI dùng Gemini + OpenAI + Whisper | Chỉ dùng Groq (model `openai/gpt-oss-120b` chạy trên Groq). Không có Whisper. Gemini/OpenAI chỉ nằm trong dependency nhưng không được sử dụng |
| 2 | AI chấm phát âm | AI không chấm phát âm; phát âm read-aloud do STT trên máy + thuật toán WER |
| 3 | 32 models CSDL | 34 models |
| 4 | 412 file Dart · 14 module · 30 BLoC | 542 file Dart · 16 module · 46 BLoC |
| 5 | 21 route · 46 service | 20 route · 49 service · 21 controller |
| 6 | Học sinh nộp đơn → admin duyệt → thành giáo viên | Không có luồng này. Admin cấp quyền giáo viên trực tiếp cho user |
| 7 | Admin kiểm duyệt báo cáo vi phạm | "Report" là phản hồi/báo lỗi app (bug/feature/improvement) — không phải tố cáo vi phạm |
| 8 | Phát hành app 4 trạng thái | 6 trạng thái: chờ duyệt → đã duyệt → lên lịch → phát hành → lưu trữ (+ từ chối) |
| 9 | Thi realtime: sảnh → thi → đóng | Sảnh → thi → chấm điểm → đóng |
| 10 | LOC ~110.200 (89.800 Flutter / 20.400 Node) | Flutter ~141.500 dòng / 542 file; Backend ~30.100 dòng / 188 file |
| 11 | Vai trò "student/teacher/admin" | Vai trò học sinh trong hệ thống tên là "user" (không phải "student") |

**Ghi chú khác:** Kiểu `Either<Failure,T>` là tự viết tay chứ không dùng package dartz. "Grammar MCQ" thực ra hỗ trợ cả cloze/gap/matching/reorder. Từ điển offline ~225 MB.

---

## NỘI DUNG 17 SLIDE

### Slide 1 — Bìa
- English for Community (E4C) — Nền tảng học tiếng Anh cộng đồng tích hợp AI.
- Web & Mobile, đa vai trò: Học sinh (user) · Giáo viên · Admin.
- SVTH / GVHD / Đơn vị / Thời gian (điền).

### Slide 2 — Đặt vấn đề & Mục tiêu
- **Vấn đề:** học 4 kỹ năng rời rạc; ít gắn lớp–giáo viên; AI chưa vào khâu chấm bài.
- **Mục tiêu:** nền tảng full-stack 4 kỹ năng + từ vựng; 3 vai trò; AI chấm + thi realtime; đã deploy thật.

### Slide 3 — Khảo sát & Điểm khác biệt
- Duolingo (tự học), ELSA (phát âm), Google Classroom (quản lớp) → E4C gộp cả 3 + AI trong 1 app.

### Slide 4 — Kiến trúc đa vai trò (RBAC)
- 1 app Flutter → sau đăng nhập, hệ thống đọc vai trò và điều hướng đúng workspace.
- 3 vai trò: user (Học sinh) · teacher · admin.
- Bảo mật 2 lớp: Server kiểm tra xác thực + phân quyền (admin = toàn quyền, teacher = 7 quyền, user = không có quyền quản trị); Client chặn truy cập sai route.

### Slide 5 — Kiến trúc tổng thể
- **Flutter Client** (Mobile & Web): Clean Architecture UI → BLoC → Repository → Datasource; kiểu `Either<Failure,T>` tự viết; điều hướng go_router; dependency injection (85 đăng ký); tự động làm mới token khi hết hạn; realtime qua Socket.IO; lưu offline bằng SQLite.
- **Node.js Backend**: Express (MVC + Service Layer); Mongoose; Socket.IO; cron job; bảo mật helmet + nén dữ liệu + giới hạn tần suất.
- **Hạ tầng ngoài:** MongoDB Atlas · Cloudinary (upload media) · Firebase (xác thực + push thông báo) · Groq (AI).

### Slide 6 — Tích hợp Trí tuệ nhân tạo (AI)  ⭐
- **Nền tảng AI: Groq** — model `openai/gpt-oss-120b` (có thể đổi qua cấu hình).
- **Chấm bài Viết (IELTS Writing Task 2):** điểm band TR/CC/LR/GRA + overall, nhận xét tiếng Việt, sửa lỗi inline, viết bài mẫu band 7–9.
- **Tạo đề Viết tự động.**
- **Nhận xét bài Nói (free-talk):** rubric FC/LR/GRA/IA + CEFR từ transcript — AI không chấm phát âm.
- **Chấm nháp tự luận trong bài thi** → giáo viên chốt điểm.
- **Trợ lý AI (chatbot):** dùng function-calling để truy vấn dữ liệu học tập của người dùng.
- **Voice AI (VAPI):** hội thoại nói tự do thời gian thực.
- **Read-aloud:** STT trên thiết bị + thuật toán WER (Levenshtein) — không phải AI/Whisper.

### Slide 7 — Thiết kế CSDL
- **34 Mongoose models**, chia nhóm:
  - Tài khoản: User
  - Lớp học: Classroom, ClassroomMember, ClassroomMessage, ClassroomChatReadState, ClassroomActivityLog
  - Thi: Exam, ExamAssignment, ExamAttempt, ExamSession
  - Nội dung kỹ năng: Listening, ListeningComprehension, Reading, WritingTopics, WritingSubmission, SpeakingSet, SpeakingScenario, Word, …
  - Vận hành: Notification, Report, AppRelease, AdminAuditLog, UserDailyProgress
- Không có model dành cho "nộp đơn làm giáo viên".

### Slide 8 — Giao diện Học sinh
- **Bố cục:** app học sinh (mobile & web) — trang chủ tổng quan tiến độ/streak/điểm; điều hướng tới 4 kỹ năng, từ vựng, lớp học; thông báo; hồ sơ + lịch sử bài làm.
- **Nghe:** dictation (chấm WER/CER) + nghe hiểu MCQ.
- **Nói:** read-aloud STT-trên-máy + WER; free-talk qua VAPI + nhận xét AI (Groq).
- **Đọc:** bài đọc + phản hồi AI.
- **Viết:** AI (Groq) chấm band + sửa lỗi inline + bài mẫu.
- **Từ vựng:** từ điển offline SQLite (~225MB) + phiên ôn tập lặp lại ngắt quãng (SRS).
- **Lớp học & Thi cử:** lớp của tôi, chat lớp, bài được giao; vào phòng thi realtime (sảnh chờ → làm bài) hoặc tham gia đề công khai qua link.
- **Gamification:** điểm, streak, level, bảng xếp hạng.

### Slide 9 — Giao diện Giáo viên
- **Bố cục:** workspace giáo viên riêng — giao diện web có thanh điều hướng bên + bản mobile responsive; menu tài khoản (chỉnh hồ sơ, đổi mật khẩu).
- **Dashboard:** tổng quan các lớp + hàng đợi bài cần chấm + hộp thư nhanh.
- **Quản lý lớp:** trang chi tiết lớp — danh sách thành viên, các bài đã giao, tiến độ nộp.
- **Ngân hàng đề:** danh sách đề (lọc/tìm) + trình soạn đề tích hợp đa kỹ năng.
- **Giao bài:** wizard giao bài từng bước (chọn đề → lớp hoặc link công khai → hạn/lượt).
- **Phòng thi realtime:** console phiên thi (sảnh chờ + bảng live monitor) và màn hình xem trực tiếp bài làm của từng học sinh.
- **Chấm bài:** grading hub (auto MCQ + AI nháp + GV chốt điểm) + panel chấm Viết.
- **Sổ điểm:** bảng điểm theo lớp/bài, export Excel.
- **Phân tích:** trang thống kê kết quả học tập của lớp.
- **Lịch & Hộp thư:** lịch các phiên thi realtime; chat với học sinh trong lớp.

### Slide 10 — Giao diện Admin
- **Bố cục:** workspace quản trị riêng — giao diện web có thanh điều hướng bên + bản mobile responsive; menu tài khoản (chỉnh hồ sơ, đổi mật khẩu).
- **Dashboard:** tổng quan hệ thống.
- **CMS nội dung:** trung tâm nội dung 4 kỹ năng — danh sách + trình soạn cho Listening, Listening Comprehension, Reading, Speaking, Writing (kèm quản lý chủ đề Viết).
- **Quản lý người dùng:** danh sách user (thẻ user + huy hiệu vai trò), xem chi tiết, ban/unban (kể cả hàng loạt), cấp quyền giáo viên.
- **Phản hồi/báo lỗi:** hàng đợi Report — thẻ báo lỗi + hộp thoại chi tiết + menu xử lý.
- **Phát hành app:** trang quản lý bản phát hành theo quy trình chờ duyệt → phát hành → lưu trữ.
- **Lịch sử hoạt động:** tra cứu bài nộp của học sinh theo từng kỹ năng (chi tiết Listening/Reading/Speaking/Writing…), tìm theo người dùng.
- **Trung tâm vận hành (Ops center):** theo dõi tình trạng hệ thống.

### Slide 11 — Giáo viên: Lớp & Thi realtime
- **Quy trình:** Tạo lớp (mã mời + token) → Soạn đề đa kỹ năng (+ Grammar: MCQ/cloze/gap/matching/reorder) → Giao bài (cho lớp hoặc link công khai giới hạn lượt/hạn) → Thi realtime (sảnh → thi → chấm điểm → đóng, qua Socket.IO) → Chấm (auto MCQ + AI nháp + GV chốt) → Phát điểm.
- **Live monitor:** theo dõi trạng thái/tiến độ từng học sinh theo thời gian thực.
- **Chống gian lận:** đếm số lần rời tab + thời gian mất focus + số lần copy-paste + thoát fullscreen → đánh giá mức độ rủi ro.
- **Sổ điểm:** export Excel.

### Slide 12 — Admin & Phát hành app
- **CMS nội dung** 4 kỹ năng: CRUD + versioning + duyệt nội dung (chỉ admin).
- **Quản lý user:** ban/unban (kể cả hàng loạt, force-logout qua socket).
- **Cấp quyền giáo viên:** admin promote trực tiếp user thành teacher (không có luồng nộp đơn).
- **Phản hồi/báo lỗi:** hàng đợi kiểm duyệt cho Report (bug/feature/improvement) — không phải tố cáo vi phạm.
- **Audit log:** ghi mọi hành động admin (lưu 365 ngày).
- **Phát hành app:** quy trình chờ duyệt → đã duyệt → lên lịch → phát hành → lưu trữ (+ từ chối); có kiểm tra phiên bản với chính sách bắt buộc/khuyến nghị cập nhật; CI nạp bản ứng viên; cron tự động phát hành.

### Slide 13 — Điểm nổi bật kỹ thuật
- **Realtime Socket.IO:** phòng thi, live monitor, thông báo, chat lớp.
- **JWT dual-token:** access + refresh; tự động làm mới token khi hết hạn (xếp hàng các request đồng thời); phân quyền theo permission.
- **Hoạt động offline:** từ điển SQLite (~225MB) tra cứu không cần mạng.
- **Đa ngôn ngữ:** 1.746 keys EN + 1.746 VI.
- **Kiến trúc sạch:** BLoC + Repository + Datasource + Either; có một số unit test.

### Slide 14 — Demo
- Đăng nhập HS → làm bài có AI chấm → GV mở phiên thi realtime → chấm & phát điểm. Có video dự phòng.

### Slide 15 — Quy mô & Khối lượng
- **Flutter:** 542 file `.dart` · ~141.500 dòng.
- **Backend:** 188 file `.js` · ~30.100 dòng.
- **34** models · **20** route · **49** service · **21** controller.
- **16** feature module · **46** BLoC.
- ~**1.750** localization keys × 2 ngôn ngữ (EN/VI).
- *Lưu ý:* số dòng là đếm thô (gồm dòng trắng/comment) — nên nói "hơn 170K dòng (raw)".
- *Tránh:* đừng ghi "0 error / 0 warning" nếu chưa chạy lại phân tích để xác nhận.
- Biểu đồ phân bổ: Flutter ~82% · Backend ~18%.

### Slide 16 — Hạn chế & Hướng phát triển
- **Hạn chế:** mới có vài unit test, chưa có bộ E2E/độ phủ đầy đủ; CI/CD một phần; chưa triển khai iOS; analytics còn cơ bản.
- **Hướng phát triển:** bổ sung integration/E2E test + CI/CD đầy đủ; dashboard phân tích học tập; tối ưu hiệu năng (lazy-load, phân trang); mở rộng nội dung & phát hành iOS.

### Slide 17 — Kết luận
- Hoàn thành nền tảng chạy thật (domain riêng); đủ 3 vai trò, 4 kỹ năng + từ vựng, quy trình lớp–thi–chấm realtime khép kín; tích hợp AI (Groq) vào chấm Viết/Nói + trợ lý + Voice AI; năng lực full-stack end-to-end.

---

*Ghi chú: các số liệu quy mô phản ánh trạng thái repo ngày 2026-07-07.*
