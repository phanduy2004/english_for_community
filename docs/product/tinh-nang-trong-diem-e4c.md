# E4C — Tính năng trọng điểm & điểm nhấn kỹ thuật

> Tài liệu tổng hợp những chức năng **hay, hữu ích, có chiều sâu kỹ thuật** nhất của dự án
> English for Community (E4C), phục vụ báo cáo với giáo viên.
> Mọi khẳng định đã đối chiếu trực tiếp với mã nguồn (dẫn chứng `file:dòng`).
> Kiểm chứng: 2026-07-08. Repo: `english_for_community` (Flutter) + `english_for_community_backend` (Node.js).

---

## TL;DR — 3 điểm nhấn lớn nhất

1. **Thi trắc nghiệm/tự luận REALTIME có chống gian lận** — giáo viên "soi" trực tiếp bài làm từng học sinh, hệ thống tự chấm điểm rủi ro gian lận, chống cả race-condition khi giao link công khai. *(Đây là phần khó và độc đáo nhất.)*
2. **AI đi vào tận khâu chấm bài** — chấm Viết IELTS (band + sửa lỗi inline + bài mẫu) và nhận xét Nói, với **cơ chế tự kiểm tra độ trung thực của AI**; trợ lý học tập dùng **function-calling 21 công cụ** truy vấn đúng dữ liệu của người dùng.
3. **Chất lượng kỹ thuật kiểu sản phẩm thật** — kiến trúc sạch, từ điển offline 225MB, tự cập nhật app (APK), quy trình phát hành app có state machine + duyệt + rollback, bảo mật nhiều lớp, 4 cron job vận hành.

---

## 1. Thi realtime + chống gian lận  ⭐ *(điểm nhấn số 1)*

Không chỉ là "làm bài rồi nộp" — đây là một hệ thống thi trực tuyến có giám sát, chạy trên Socket.IO.

- **Phòng thi realtime có state machine rõ ràng:** `lobby → live → grading → closed`. Phiên thi **tự đóng đúng giờ** kể cả khi giáo viên không mở app: vừa kiểm tra "lười" (lazy) khi có người truy cập, vừa có cron quét mỗi phút.
  *(Dẫn chứng: `models/ExamSession.js:12`, `examSessionService.js:95-136`, `jobs/examSessionExpireJob.js:9`)*

- **"Soi" màn hình học sinh theo thời gian thực (live screen mirror):** giáo viên thấy đúng câu học sinh đang làm, đáp án đã chọn, đúng/sai từng câu — **không phải quay video màn hình** mà là **đồng bộ trạng thái UI có cấu trúc** (structured state sync), nhẹ và chính xác. Kèm bảng tổng quan: số đang làm / đã nộp / bị gắn cờ rủi ro / % tiến độ.
  *(Dẫn chứng: `teacher_student_live_screen_page.dart:17`, `examLiveMonitorService.js:14-62`, `examAttemptProgress.js:208-325`)*

- **Đo hành vi gian lận bằng nhiều tín hiệu và chấm mức rủi ro:**
  - Đếm **rời tab/app** (`tabSwitchCount`, có khử nhiễu để không tính nhầm khi có thông báo/cuộc gọi), **thời gian mất tập trung** (`focusLossSeconds`), **copy-paste** (bắt cả phím tắt lẫn menu chuột phải/long-press), **thoát fullscreen**.
  - Quy đổi ra `riskLevel`: **high** nếu ≥5 lần rời tab HOẶC ≥120s mất focus HOẶC ≥3 lần copy-paste; **medium** nếu ≥2 lần rời tab / ≥45s / ≥1 copy-paste / từng thoát fullscreen; còn lại **low**. Khi "high" tự ghi cờ vào nhật ký lớp cho giáo viên.
  - Dữ liệu gửi dạng **delta cộng dồn** để không mất số liệu khi mạng chập chờn.
  *(Dẫn chứng: `exam_integrity_tracker.dart:71-155`, `examIntegrityService.js:6-68`)*

- **Chống race-condition khi giao "link công khai" giới hạn lượt:** dùng cập nhật nguyên tử `findOneAndUpdate` với `$expr` so sánh ngay trong điều kiện MongoDB — nhiều học sinh cùng bấm "bắt đầu" lúc gần hết lượt cũng **không thể vượt quota** (tránh bug kinh điển đọc-rồi-ghi). Giáo viên còn "reset" được link cũ đã phát tán.
  *(Dẫn chứng: `teacherExamAssignmentService.js:348-357, 591-597`)*

- **"Đóng băng" đề thi (frozen snapshot):** đề được copy đông cứng khi phiên bắt đầu — giáo viên lỡ sửa đề gốc giữa chừng **không** làm đổi bài học sinh đang làm.
  *(Dẫn chứng: `examSnapshotStore.js:66-83`)*

- **Chống "rút dây mạng để né nộp bài":** mất kết nối socket trong phòng thi → đánh dấu bài `void` và **không cho rejoin** phiên đó. Ngược lại, khi rớt mạng ngoài ý muốn rồi kết nối lại, client **tự động rejoin** phiên. Hết giờ thì **tự nộp** (giữ nguyên phần đã làm) thay vì treo bài.
  *(Dẫn chứng: `socketManager.js:277-293`, `examSessionService.js:189-232`, `socket_service.dart:103-126`, `examAttemptService.js:278-297`)*

---

## 2. AI đi vào khâu chấm bài  ⭐ *(điểm nhấn số 2)*

Toàn bộ AI ngôn ngữ dùng **một nhà cung cấp duy nhất: Groq** (model `openai/gpt-oss-120b`). *(Trung thực: Gemini/OpenAI SDK có trong dependency nhưng **không file nào import** — không phải "đa nền tảng AI".)*

- **Chấm bài Viết IELTS Task 2 — không chỉ cho điểm:**
  - Điểm band đủ 4 tiêu chí IELTS (TR/CC/LR/GRA) + overall, nhận xét tiếng Việt.
  - **Sửa lỗi inline** ngay trong bài với định dạng `{{từ_cũ||từ_mới||lý_do}}`; UI cho **bấm vào lỗi để xem giải thích**.
  - Sinh **2 bài mẫu** (band ~7–8 viết lại theo ý học viên, và band 9 viết mới).
  - **Điểm kỹ thuật đáng nể:** hệ thống **tự kiểm tra AI có gian dối không** — dựng lại "bản gốc" từ các dấu sửa rồi so sánh độ tương đồng từ (Jaccard, ngưỡng 0.6); nếu AI tự ý paraphrase thay vì chép nguyên + đánh dấu, hệ thống **tự gọi lại một lượt "sửa chữa"** để ép đúng định dạng. Kèm **cơ chế phục hồi JSON 3 tầng** khi AI trả JSON lỗi.
  *(Dẫn chứng: `aiService.js:440-609` (chấm + rubric), `:116-132` (guard trung thực), `:21-84` (phục hồi JSON); UI `interactive_diff_text.dart:23-343`)*

- **Nhận xét bài Nói (free-talk):** rubric 4 tiêu chí (FC/LR/GRA/IA) + quy đổi **CEFR** (A1–C2), chấm **từ transcript** hội thoại. Các số liệu (WPM, số từ đệm "um/uh", số câu hỏi…) được **tính bằng code** rồi mới đưa cho AI để nó không bịa số. Có "sổ tay lỗi lặp lại" qua nhiều buổi.
  *(Trung thực: **AI không chấm phát âm** — ghi rõ trong prompt.)*
  *(Dẫn chứng: `aiService.js:616-636`, `speakingService.js:29-48, 803-873`)*

- **Trợ lý học tập (chatbot) dùng function-calling thật:** AI tự quyết định gọi trong **21 công cụ** (lấy lịch sử học, phân tích điểm yếu, chi tiết từng kỹ năng, bảng xếp hạng, kết quả thi…), lặp tối đa 5 vòng để trả lời câu hỏi phức tạp. **An toàn dữ liệu:** `userId` do server tiêm vào, AI không thể tự truy vấn dữ liệu người khác; xử lý **múi giờ** đúng khi hỏi "hôm nay/tuần này".
  *(Dẫn chứng: `chatService.js:97-150`, `tools/definitions.js:14-229`, `tools/implementations.js:58-1090`)*

- **AI chấm nháp bài thi tự luận, giáo viên chốt điểm:** AI đưa điểm gợi ý (quy đổi band → thang 10), giáo viên xem lại và bấm "Apply AI" hoặc tự sửa rồi mới lưu. Có **chốt an toàn**: không cho phát điểm cuối khi còn phần chưa chấm xong.
  *(Dẫn chứng: `examGradingService.js:81-133, 200-277, 369-372`, `integrated_writing_grading_panel.dart:142-166`)*

- **Voice AI hội thoại thời gian thực (VAPI):** nói chuyện tự do (STT+LLM+TTS realtime) qua nền tảng Vapi; key cấu hình lấy an toàn từ backend (có JWT) chứ không nhúng cứng vào app; kết thúc cuộc gọi thì transcript được gửi về Groq để chấm.
  *(Dẫn chứng: `real_vapi_service.dart:8-202`, `vapi_config_remote_datasource.dart:26-72`)*

---

## 3. Chất lượng kỹ thuật phía client (Flutter)  ⭐ *(điểm nhấn số 3)*

- **Tự làm mới token (JWT) chuẩn production:** khi token hết hạn mà app đang bắn nhiều request cùng lúc, hệ thống **chỉ refresh 1 lần** rồi **replay toàn bộ request đang chờ** (single-flight + hàng đợi) — tránh "refresh storm" và tránh refresh-token bị revoke lẫn nhau. Refresh thất bại thì tự đăng xuất về `/login`.
  *(Dẫn chứng: `app_jwt_interceptor.dart:40-180`)*

- **Kiến trúc sạch:** UI → BLoC → Repository → Datasource; kiểu `Either<Failure,T>` **tự viết tay** (không kéo package `dartz`) — cho thấy hiểu bản chất functional error-handling. DI với `get_it` (**85 lượt đăng ký**).
  *(Dẫn chứng: `core/model/either.dart:1-22`, `core/get_it/get_it.dart`)*

- **Từ điển offline ~225MB (SQLite):** tra cứu **không cần mạng** sau lần cài đầu; app tự copy DB ra vùng ghi được, có **versioning** (asset mới thì thay), và dùng **full-text search (FTS)** khi có. Hữu ích cho học tiếng Anh ở nơi sóng yếu.
  *(Dẫn chứng: `core/sqflite/dict_db.dart:21-122`, `assets/db/dictionary.db` ≈ 225 MB)*

- **Read-aloud chấm phát âm hoàn toàn trên máy:** dùng STT của hệ điều hành (`speech_to_text`) + tự cài **thuật toán WER (Levenshtein)** để so câu mẫu với câu đọc được. **Chi phí bằng 0**, không gửi audio lên cloud/Whisper.
  *(Dẫn chứng: `speaking_skills_page.dart:325-346, 1251-1280`)*

- **Tự cập nhật app trong-app (in-app APK update):** kiểm tra phiên bản khi mở/quay lại app; tải APK có **hiển thị %**, **huỷ được**, tự dọn file cũ, phân biệt **bắt buộc/khuyến nghị** cập nhật.
  *(Dẫn chứng: `app_update/app_apk_updater.dart:26-113`, `app_update_guard.dart:37-79`)*

- **Gamification thực chất:** điểm, streak, level, **mục tiêu hoạt động hằng ngày**, và bảng xếp hạng có UI rút gọn quanh vị trí của mình.
  *(Dẫn chứng: `entity/user_entity.dart:73-74, 251-252`, `entity/leaderboard_entity.dart`)*

---

## 4. Nền tảng vận hành & bảo mật kiểu sản phẩm thật (Backend)

- **Phát hành app có quy trình kiểu CI/CD:** state machine 6 trạng thái (`pending_approval → approved → scheduled → published → archived`, + `rejected`) được kiểm soát chuyển tiếp chặt; endpoint `version-check` trả **force/soft/up-to-date**; **chống hạ cấp phiên bản**; **rollback** an toàn về bản cũ; **cron auto-publish** bản đã lên lịch.
  *(Dẫn chứng: `releaseStateMachine.js:1-30`, `appVersionService.js:271-441`, `jobs/appReleaseSchedulerJob.js`)*

- **Phân quyền RBAC gọn, dễ mở rộng:** 3 vai trò `user`/`teacher`/`admin`; permission tách rời khỏi role (admin = toàn quyền `*`, teacher = 7 quyền cụ thể, user = không có quyền quản trị) — thêm vai trò mới chỉ cần sửa 1 map.
  *(Dẫn chứng: `constants/permissions.js:47-65`, `middleware/auth.js:5-51`)*

- **Nhật ký kiểm toán admin (Audit log):** ghi actor/hành động/đối tượng/IP/thiết bị, **tự xoá sau 365 ngày** bằng TTL index.
  *(Dẫn chứng: `models/AdminAuditLog.js:4-22`)*

- **Xuất sổ điểm Excel (exceljs):** file `.xlsx` có header đóng băng, định dạng đẹp, **sắp tên theo tiếng Việt** đúng dấu.
  *(Dẫn chứng: `teacherAssignmentScoresExportService.js:95-186`)*

- **Nội dung có version history + rollback + duyệt** (như một CMS thật), bảo vệ bằng permission riêng.
  *(Dẫn chứng: `models/WritingTopicVersion.js`, `routes/writingTopicRoutes.js:42-45`)*

- **Bảo mật nhiều lớp:** helmet, nén gzip, **rate-limit 2 tầng** (600 req/15 phút toàn cục + 60 req/phút cho chat), CORS whitelist, và **middleware chống NoSQL-injection tự viết** (lọc key `$`).
  *(Dẫn chứng: `app.js:32-102`, `middleware/sanitize.js:1-27`)*

- **4 cron job vận hành liên tục:** nhắc học **cá nhân hoá theo múi giờ** (nhắc từ vựng, ôn tập 19h, mục tiêu ngày 20h, cảnh báo mất streak 22h), auto-publish release, và 2 job tự dọn trạng thái thi quá hạn.
  *(Dẫn chứng: `jobs/smartNotificationJob.js:168-206`, `server.js:48-51`)*

- **Tích hợp dịch vụ ngoài thật (không mock):** Cloudinary (upload media, tự phân loại ảnh/audio), Firebase (đăng nhập Google + push FCM), MongoDB Atlas (connection pool 5–20).
  *(Dẫn chứng: `config/cloudinary.js`, `config/firebase.js`, `server.js:23-30`)*

---

## 5. Quy mô (tham khảo nhanh)

- Flutter: **542 file `.dart`**, **16** module tính năng, **46** BLoC, ~141.500 dòng.
- Backend: **34** Mongoose models, **20** route · ~**49** service · **21** controller, ~30.100 dòng.
- Đa ngôn ngữ: **~2.100 khoá EN / ~2.000 khoá VI** (đã i18n hoá rất rộng).
- 3 vai trò · 4 kỹ năng + từ vựng · đã deploy thật trên domain riêng.

*(Số liệu chi tiết & bảng đính chính đầy đủ ở `noi-dung-slide-kiem-chung.md`.)*

---

## 6. Những điểm nên trình bày TRUNG THỰC với giáo viên

Để tránh bị "bắt bẻ" khi bảo vệ, nên chủ động nói rõ:

- **Chỉ dùng 1 AI (Groq)** cho mọi tác vụ ngôn ngữ; Gemini/OpenAI/Whisper **không được dùng** (chỉ nằm trong dependency).
- **AI không chấm phát âm.** Chấm phát âm read-aloud là **STT trên máy + thuật toán WER**, không phải AI.
- **Thuật toán lặp lại ngắt quãng (SRS)** chạy ở **backend**; client chỉ gửi mức phản hồi (hard/good/easy) và hiển thị lịch ôn.
- **AI chỉ chấm nháp** bài thi; **giáo viên là người chốt điểm cuối**.
- **Report** là kênh **phản hồi/báo lỗi app** (bug/feature/improvement), **không phải** tố cáo vi phạm.
- Localization EN và VI **chưa đồng bộ tuyệt đối** (VI ít hơn EN ~100 khoá).
- Kiểm thử mới có **một số unit test**, chưa có bộ E2E/độ phủ đầy đủ.
