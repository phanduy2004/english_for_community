# 02 — Học Nghe: Chép chính tả (Dictation)

> **Một câu:** Học viên nghe từng câu ngắn được cắt sẵn từ một file audio và gõ lại chính xác từng từ; hệ thống chấm đúng/sai theo từng câu và có khu thảo luận realtime cho mỗi câu.

---

## 1. Mục đích nghiệp vụ
Rèn kỹ năng **nghe chi tiết ở mức "bắt từng từ"**: học viên nghe một câu ngắn (cue) và gõ lại **chính xác** những gì nghe được. Đây là bài luyện nghe khó nhất về độ chính xác, đồng thời giúp học chính tả và cấu trúc câu. Kèm khu thảo luận theo từng câu để học viên trao đổi/hỏi đáp.

## 2. Vai trò & tiền điều kiện
- **Học viên** (đã đăng nhập); Admin/CMS tạo bài.
- Cần một bài `Listening` có `audioUrl` và mảng **cues** — mỗi cue có mốc thời gian (`startMs`/`endMs`), đáp án `text`, và nghĩa (tuỳ chọn).

## 3. Luồng nghiệp vụ chính
1. Mở màn luyện tập → nạp audio; lấy bài + toàn bộ cues, **sắp cues theo `startMs`** để chỉ số câu khớp giữa client và server.
2. Nạp lịch sử làm bài trước → đánh dấu câu nào đã "pass", điền lại text cũ, tự nhảy tới câu **chưa hoàn thành đầu tiên**.
3. Với mỗi câu, player **cắt đúng đoạn audio** của cue đó (setClip start→end) và tự phát (nếu bật). Có công tắc "tự động phát câu kế".
4. Học viên gõ đáp án → bấm "Kiểm tra" → **gửi lên server chấm**.
5. Server trả đúng/sai; nếu sai, client hiện **hint che chữ** (hiện đúng tới từ đầu tiên sai rồi che phần còn lại bằng `*****`).
6. Khi tất cả cue đều pass → nút chuyển thành "Hoàn thành".
7. Song song: mở tab **Thảo luận** để bình luận/trả lời/thả cảm xúc theo từng câu (realtime).

## 4. Quy tắc nghiệp vụ quan trọng
- **Chấm đúng/sai tuyệt đối:** một câu chỉ "pass" khi chuỗi gõ vào **giống hệt** đáp án sau khi chuẩn hoá (bỏ dấu câu, về chữ thường, gộp khoảng trắng). Không có điểm từng phần — đúng thì `wer = 0`, sai thì `wer = 1`.
- **Điểm bài** = số câu đúng / tổng số câu.
- **Tiến độ:** mỗi cue đúng được thêm vào danh sách hoàn thành; đạt 100% thì `isCompleted = true`; **chỉ lần đầu** chạm 100% mới tính là hoàn thành 1 bài (cộng lesson).
- **Lưu theo từng cue (upsert):** mỗi (học viên, bài, chỉ số cue) là một bản ghi duy nhất — làm lại thì ghi đè.
- Sau khi nộp: cộng thời gian học + độ chính xác dictation + gamification.

## 5. Cách làm (kỹ thuật)
- **Chấm ở SERVER** (không phải client): client chỉ gửi `{cueId, value}` cho từng câu, server chuẩn hoá + so sánh `===` tuyệt đối rồi trả kết quả.
- **Model dữ liệu:** `Listening` nhúng mảng `cues`; mỗi lần làm lưu ở `DictationAttempt` (text người dùng, bản chuẩn hoá, điểm, chỉ số cue).
- **Realtime + Comment:** mỗi cue có luồng bình luận riêng (`CueComment`), hỗ trợ **reply lồng nhau** và 6 loại reaction; dùng Socket.IO room `listening_<id>` để bắn bình luận/reaction mới, kèm gửi thông báo cho người liên quan.
- **Chế độ nhúng vào bài thi:** khi dùng trong bài thi, bỏ pass/fail — chỉ cần có nội dung là "đã lưu", điểm đẩy về `ExamAttempt` thay vì `DictationAttempt`.

## 6. Điểm nhấn để trình bày
- Cắt audio chính xác theo mốc thời gian từng câu (có "đệm" trước/sau) → nghe từng câu chuẩn.
- Hint che chữ thông minh: lộ đến chỗ sai đầu tiên, không lộ hết đáp án.
- **Có thảo luận realtime theo từng câu** — điểm khác biệt so với các bài luyện khác.

## 7. Giới hạn & lưu ý trung thực
- **KHÔNG có AI:** hoàn toàn là so khớp chuỗi tuyệt đối. Hệ quả: sai 1 ký tự / thiếu 1 từ = "sai cả câu"; đồng nghĩa hoặc viết số ("two" vs "2") đều bị tính sai.
- **Có code chấm nâng cao nhưng KHÔNG được dùng (dead code):** trong repo tồn tại `dictationService.js`/`cueService.js` chấm bằng **WER + Levenshtein + ngưỡng 0.25**, nhưng **không có route nào mount** chúng. Đường chạy thật là so khớp tuyệt đối (`listeningService`). → Khi trình bày, **đừng mô tả WER như tính năng đang hoạt động** cho dictation.

## 8. Dẫn chứng mã nguồn
- Chấm + tiến độ: `services/listeningService.js:9-15, 154-176, 235-275`; controller `controllers/listeningController.js:51-78`.
- Model: `models/Listening.js`, `DictationAttempt.js`, `CueComment.js:14-23`.
- Client: `feature/listening/listening_skill/listening_skills_page.dart:160-266`; `bloc` cue `cue_bloc.dart:111-200`; thảo luận `listening_skills_page.dart:108-145`.
- Dead code (không mount): `services/dictationService.js`, `cueService.js`, `models/Cue.js`, `controllers/dictationController.js`.
