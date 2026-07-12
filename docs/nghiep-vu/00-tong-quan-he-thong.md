# 00 — Tổng quan hệ thống E4C (English for Community)

> **Mục đích thư mục này:** mỗi file mô tả **một chức năng chính** của dự án theo góc nhìn **nghiệp vụ** (chức năng để làm gì, ai dùng, luồng chạy ra sao, quy tắc gì) **kèm cách làm kỹ thuật** ở mức đủ để bạn tự tin trình bày cho người khác. Mọi khẳng định bám mã nguồn thật; các chỗ quan trọng có **dẫn chứng `file:dòng`**.
>
> Cách đọc: đọc file **00** này trước để nắm bức tranh lớn, sau đó vào từng file chức năng theo nhu cầu.

---

## 1. E4C là gì?

**English for Community (E4C)** là một **nền tảng học tiếng Anh full-stack cho lớp học thật**, kết nối 3 vai trò trong cùng một hệ sinh thái:

- **Học viên (Student)** — học 4 kỹ năng (Nghe, Nói, Đọc, Viết) + Từ vựng, làm bài thi được giao, tham gia lớp, chat lớp, được chấm điểm + gamification.
- **Giáo viên (Teacher)** — tạo lớp, soạn đề, giao bài, **mở phiên thi trực tuyến có giám sát**, chấm điểm (tự động + AI + tay), xem thống kê.
- **Quản trị viên (Admin)** — duyệt đơn giáo viên, quản lý người dùng, quản lý nội dung (CMS), quản lý phát hành bản app, nhật ký kiểm toán.

Điểm khác biệt so với app học tiếng Anh thông thường: E4C không chỉ là "học tự chủ" mà còn là **hệ thống lớp học + thi cử trực tuyến có chống gian lận**, và **AI đi vào tận khâu chấm bài**.

---

## 2. Ba "mặt tiền" từ một mã nguồn

| Mặt tiền | Nền tảng | Đối tượng |
|---|---|---|
| **App học viên** | Flutter (Android/iOS) | Học viên |
| **Web Giáo viên** | Flutter Web (Firebase Hosting) | Giáo viên |
| **Web Admin** | Flutter Web (Firebase Hosting) | Quản trị viên |

Cùng **một codebase Flutter** phục vụ cả 3 mặt tiền, phân luồng theo **vai trò** (role-based routing). Backend là **một** server Node.js (Express REST API + Socket.IO realtime), deploy trên Render, dùng MongoDB Atlas.

---

## 3. Kiến trúc tổng thể

```
Flutter (mobile app + web teacher/admin)
   UI  →  BLoC  →  Repository (Either<Failure,T>)  →  DataSource (Dio + SQLite)
                         │  HTTPS + JWT                    │  WebSocket
                         ▼                                 ▼
        Node.js Backend:  Express REST API (20 route module)
                          Socket.IO (realtime: thi live, chat, presence)
                          Service layer (nghiệp vụ + AI)
                          node-cron (4 job vận hành)
                          MongoDB Atlas (~33 model)
                         │
   Dịch vụ ngoài:  Firebase (Auth Google · FCM push · Hosting)
                   Groq (AI ngôn ngữ: chấm Viết/Nói + trợ lý học tập)
                   VAPI (Voice AI hội thoại realtime)
                   Cloudinary (lưu ảnh/audio/tệp)
```

**Kiến trúc client "sạch" (Clean Architecture + BLoC):** UI → BLoC → Repository → DataSource, dùng kiểu `Either<Failure, T>` (tự viết tay, không dùng package `dartz`) để xử lý lỗi kiểu functional; DI bằng `get_it`.

**Backend phân lớp:** `routes` (khai báo endpoint + RBAC) → `controllers` (mỏng) → `services` (chứa toàn bộ nghiệp vụ + AI) → `models` (Mongoose). Socket.IO tách riêng trong `socket/`, tác vụ định kỳ trong `jobs/`.

---

## 4. Công nghệ chính

- **Frontend:** Flutter/Dart, `flutter_bloc`, `get_it`, `go_router` (điều hướng theo vai trò), `dio` (có interceptor tự làm mới JWT), `socket_io_client`, Firebase Auth + Google Sign-In, `flutter_secure_storage`/`sqflite` (từ điển offline), `speech_to_text`/`flutter_tts`, `fl_chart`, i18n ARB (EN/VI).
- **Backend:** Node.js (ES Modules) + Express 4, Mongoose 8 (MongoDB), JWT dual-token + bcrypt + OTP, Socket.IO 4, **Groq SDK** (AI), Cloudinary, Zod (validate), Nodemailer (email OTP), Firebase Admin (push), `node-cron`, ExcelJS (xuất điểm).

---

## 5. Danh mục chức năng (mỗi mục = 1 file trong thư mục này)

### A. Nền tảng dùng chung
| File | Chức năng | Tóm tắt |
|---|---|---|
| `01` | **Xác thực & Phân quyền** | Đăng ký/OTP, đăng nhập, Google login, JWT dual-token + tự refresh, RBAC 3 vai trò, đơn xin làm giáo viên |
| `08` | **Trợ lý học tập AI** | Chatbot function-calling truy vấn đúng dữ liệu của chính người dùng |
| `09` | **Gamification & Tiến độ học tập** | XP, streak, level, mục tiêu ngày, bảng xếp hạng, màn tiến độ |
| `19` | **Thông báo** | Chuông (hệ thống) vs Chat inbox; push FCM; nhắc học theo múi giờ |

### B. Học kỹ năng (Học viên)
| File | Chức năng | Tóm tắt |
|---|---|---|
| `02` | **Nghe – Chép chính tả (Dictation)** | Nghe audio, chép lại, chấm theo từng cue |
| `03` | **Nghe hiểu (Listening Comprehension)** | Nghe rồi trả lời trắc nghiệm |
| `04` | **Nói (Speaking)** | Read-aloud chấm WER trên máy + Voice AI (VAPI) + AI nhận xét CEFR |
| `05` | **Đọc hiểu (Reading)** | Đọc đoạn văn + làm câu hỏi, lưu tiến độ |
| `06` | **Viết + AI chấm IELTS (Writing)** | AI chấm band 4 tiêu chí, sửa lỗi inline, sinh bài mẫu, guard chống AI gian dối |
| `07` | **Từ vựng · Từ điển offline · SRS** | Tra từ điển 225MB offline, sổ tay, ôn tập ngắt quãng |

### C. Lớp học & Thi (Giáo viên ↔ Học viên)
| File | Chức năng | Tóm tắt |
|---|---|---|
| `10` | **Quản lý lớp học** | Tạo lớp, mã mời/link, thành viên, co-teacher, nhật ký, archive |
| `11` | **Chat lớp học realtime** | Nhóm chat Socket.IO, đã đọc, reaction, media, inbox |
| `12` | **Soạn đề thi (Exam Builder)** | Bật/tắt từng kỹ năng + gắn CMS + Grammar chấm tự động |
| `13` | **Giao bài & Link công khai** | 4 chế độ giao, giới hạn lượt chống race-condition, preset |
| `14` | **Làm bài thi (Student Runner)** | Bài tích hợp, autosave, đồng hồ do server, hết giờ tự nộp |
| `15` | **Phiên thi trực tiếp & Giám sát** | State machine lobby→live→closed, "soi" màn hình học sinh realtime |
| `16` | **Chống gian lận thi** | Đếm rời tab/mất focus/copy-paste → chấm mức rủi ro |
| `17` | **Chấm điểm · Sổ điểm · Trả kết quả** | Tự động + nháp AI + giáo viên chốt, xuất Excel |
| `18` | **Thống kê lớp học (Analytics)** | Biểu đồ kết quả/tham gia, KPI, xử lý múi giờ VN |

### D. Vận hành & Quản trị
| File | Chức năng | Tóm tắt |
|---|---|---|
| `20` | **Tự cập nhật app & Quản lý phát hành** | version-check soft/force, cài APK trong app, state machine release + duyệt + rollback |
| `21` | **Quản trị hệ thống (Admin)** | Quản lý người dùng/nội dung/báo cáo, Ops Center, Audit Log |

---

## 6. Những nguyên tắc xuyên suốt (nên nắm để trình bày)

1. **Server là nguồn sự thật** cho thời gian thi, cửa sổ mở/đóng, trạng thái nộp, tính điểm khách quan. Client chỉ hiển thị.
2. **Phân quyền theo dữ liệu:** học viên chỉ thấy bài được phân quyền (thành viên lớp + assignment, hoặc token link hợp lệ); AI trợ lý chỉ đọc dữ liệu của chính người hỏi (userId do server tiêm).
3. **AI chỉ là trợ lý, con người chốt:** trong bài thi tự luận, AI đưa **điểm nháp**, giáo viên là người **chốt điểm cuối**.
4. **Trung thực về AI:** toàn bộ AI ngôn ngữ dùng **duy nhất Groq** (model `openai/gpt-oss-120b`). Chấm phát âm read-aloud là **STT trên máy + thuật toán WER**, **không phải AI**. VAPI là hạ tầng voice riêng.
5. **Chất lượng kiểu sản phẩm thật:** JWT tự refresh single-flight, từ điển offline có versioning + copy nguyên tử, tự cập nhật app, quy trình phát hành có state machine + duyệt + rollback, bảo mật nhiều lớp, 4 cron job vận hành.

---

## 7. Quy mô tham khảo

- Flutter: ~540 file `.dart`, ~16 module tính năng, ~46 BLoC.
- Backend: ~33 Mongoose model, 20 route module, ~49 service, ~21 controller.
- Đa ngôn ngữ EN/VI (đã i18n rộng); đã deploy thật trên domain riêng `english4community.online`.

> Ghi chú trung thực để tránh bị "bắt bẻ": localization VI ít hơn EN (~100 khoá); mới có một số unit test (chưa phủ E2E đầy đủ); một vài tích hợp là "khung" (ví dụ Google Classroom/LTI hiện là stub). Chi tiết trong từng file chức năng ở mục *Giới hạn & lưu ý trung thực*.
