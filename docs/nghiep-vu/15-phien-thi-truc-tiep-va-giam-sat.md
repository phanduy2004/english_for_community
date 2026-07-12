# 15 — Phiên thi trực tiếp & Giám sát (Live Session + Proctoring)

> **Một câu:** Giáo viên tổ chức buổi thi đồng bộ realtime, "soi" màn hình từng học viên bằng **đồng bộ trạng thái có cấu trúc (không quay video)**, phiên tự đóng đúng giờ, kèm cơ chế chống rút mạng né nộp bài. ⭐ *Đây là phần độc đáo và khó nhất của dự án.*

---

## 1. Mục đích nghiệp vụ
Cho phép một buổi thi **đồng bộ theo thời gian thực**: GV mở phòng, học viên vào "sảnh chờ" (lobby), GV bấm bắt đầu cho cả lớp cùng lúc, **giám sát tiến độ + màn hình từng học viên realtime**, nhắc nhở/loại học viên, và phiên tự đóng đúng giờ ngay cả khi GV không mở app.

## 2. Vai trò & tiền điều kiện
- **GV chủ phiên:** sở hữu assignment chế độ realtime.
- **Học viên:** thuộc lớp hoặc có token public hợp lệ.
- Hạ tầng: Socket.IO + cron.

## 3. Luồng nghiệp vụ chính
1. **Mở phiên:** tạo phiên trạng thái `lobby` với **mã phòng 6 ký tự**; đóng băng snapshot đề. (Đã có phiên lobby thì trả về phiên cũ — idempotent.)
2. **Học viên vào lobby:** thêm vào danh sách tham gia (atomic, chống lỗi khi nhiều người vào cùng lúc).
3. **Đánh dấu sẵn sàng (ready).**
4. **Bắt đầu thi:** chuyển `live`, và **tạo lượt làm cho từng học viên đang trong lobby**; gửi thông báo "phiên đã live".
5. **Giám sát realtime:** mỗi thay đổi đáp án/điều hướng của học viên → server dựng lại payload có cấu trúc và phát cho GV.
6. **Kết thúc:** chuyển `grading` → **cưỡng chế nộp + chấm** mọi lượt còn đang làm → `closed`.

## 4. Quy tắc nghiệp vụ quan trọng
- **State machine:** `lobby → live → grading → closed` (+ `canceled`).
- **Vào khi đã live:** học viên **chỉ vào được nếu đã có lượt làm** (tức đã ở lobby lúc bắt đầu); vào muộn bị chặn.
- **Chống rút mạng né nộp (void + không rejoin):** rời chủ động hoặc rớt socket khi đang làm → lượt bị đánh dấu **void** (mất bài) + **cấm rejoin** phiên đó. Khi join lại phát hiện lượt void do "tự thoát" → chặn 403.
- **Kick:** chỉ ở lobby/live, không kick chủ phiên; lý do "teacher_kicked" (khác với tự thoát).
- **Đóng phiên đúng giờ:** thời điểm auto-end = min(giờ kết thúc cứng, `bắt đầu + thời lượng`).

## 5. Cách làm (kỹ thuật)
- **"Soi màn hình" bằng đồng bộ trạng thái có cấu trúc (điểm hay nhất):** học viên chỉ gửi **"đang xem phần nào"** (UI focus) lên server; server dựng payload đầy đủ gồm: tiến độ (đã trả lời/tổng, %), từng câu Grammar (đúng/sai), **dải câu hỏi từng kỹ năng** (xanh đúng / đỏ sai / xám chưa), đáp án, snapshot đề, và tín hiệu liêm chính. GV xem qua một **bản sao chỉ-đọc** của màn hình học viên. → **Không quay video/WebRTC** — nhẹ băng thông, chính xác realtime từng câu.
- **Presence chống "ghost" (tinh vi):** presence lưu ở DB; socket layer đếm số kết nối per (phiên, user); chỉ khi user **không còn kết nối nào** mới lên lịch dọn presence với **thời gian ân hạn 10 giây** (để reload/nhiều tab không bị đá). Phân biệt rõ **"rời lobby"** (chỉ dọn presence, không void) vs **"rời khi đang thi"** (void).
- **Đóng phiên đúng giờ (lazy + cron):** khi ai đó đọc payload realtime mà đã quá giờ → tự đóng; đồng thời có **cron mỗi phút** quét mọi phiên live quá hạn.
- **Reconnect tự động:** sau mỗi lần socket kết nối lại, client tự phát lại đăng ký + join phiên với token/sessionId đã lưu.
- **Nhắc nhở:** GV gửi cảnh báo → server phát tới **room cá nhân của học viên** → client hiện dialog. GV có sẵn các mẫu nhắc (chuyển tab / copy-paste / mất tập trung).

## 6. Điểm nhấn để trình bày
- **Giám sát không-video** bằng structured state sync — rẻ, nhẹ, thấy đúng/sai realtime từng câu + đang làm phần nào.
- **Presence chống ghost** rất tinh vi (đếm socket + ân hạn 10s + phân biệt rời lobby vs rời khi thi).
- **Void + no-rejoin** chốt chặt chống rút mạng né nộp.
- **Phiên tự đóng đúng giờ** kể cả khi GV không online (lazy + cron).

## 7. Giới hạn & lưu ý trung thực
- Mirror phụ thuộc học viên gửi trạng thái lên → mạng học viên chập chờn thì mirror trễ (best-effort).
- Ranh giới "reload lành" vs "rút mạng" dựa vào việc còn kết nối socket nào không.
- Cron mỗi phút → độ trễ đóng phiên tối đa ~60s nếu không ai đọc payload.

## 8. Dẫn chứng mã nguồn
- `services/examSessionService.js` (state machine `352-594`, chống rejoin `391-425`, void `190-233`, auto-end `79-137`).
- Mirror/progress: `services/examLiveMonitorService.js`, `examAttemptProgress.js`, `examLiveSkillStrips.js`.
- Socket: `socket/socketManager.js` (presence/void `20-41, 232-392`), `examSocketEmit.js`; cron `jobs/examSessionExpireJob.js`.
- Client: `feature/student/exams/exam_live_session_guard.dart`, `student_exam_live_mirror_view.dart`; `feature/teacher/teacher_exam_session_console_page.dart`.
