# 04 — Học Nói (Speaking)

> **Một câu:** Ba luồng luyện nói trong một — đọc theo mẫu chấm phát âm bằng thuật toán chạy trên máy, hội thoại giọng nói realtime với AI (VAPI), và AI nhận xét bài nói theo rubric IELTS + quy đổi CEFR.

---

## 1. Mục đích nghiệp vụ
Giúp học viên: (1) **luyện phát âm từng câu** và tự chấm độ chính xác miễn phí; (2) **luyện phản xạ hội thoại tự do** với AI giọng nói như một gia sư; (3) nhận **nhận xét kiểu giám khảo IELTS Speaking** và biết **lỗi hay lặp lại** qua nhiều buổi để sửa.

Chức năng chia làm 3 luồng con dùng chung "sổ tay" + dashboard tiến độ:
- **A. Read-aloud / Shadowing / Pronunciation** — đọc theo câu mẫu, chấm phát âm bằng **WER tính trên máy**.
- **B. Free Speaking + Scenario** — hội thoại giọng nói realtime qua **VAPI**, kết thúc thì **AI (Groq) chấm rubric 4 tiêu chí + CEFR**.
- **C. Sổ tay lỗi lặp lại (Notebook)** + dashboard tiến độ.

## 2. Vai trò & tiền điều kiện
- **Học viên** (đã đăng nhập). Admin quản lý bộ câu/kịch bản.
- Luồng A cần quyền micro + STT của thiết bị.
- Luồng B cần backend đã cấu hình VAPI (thiếu → trả 503).

## 3. Luồng nghiệp vụ chính

**A. Read-aloud (chấm phát âm trên máy)**
1. Học viên chọn mode (readAloud/shadowing/pronunciation) + level; server trả danh sách bộ câu kèm tiến độ + điểm tốt nhất.
2. Với mỗi câu: bấm loa để **máy đọc mẫu (TTS)**, rồi bấm mic để **STT ghi lại lời đọc**.
3. Khi dừng ghi, **client tự tính WER** (so câu mẫu với lời đọc) → đổi ra % → gửi lên server.
4. Server lưu attempt, cập nhật tiến độ (`averageWer`, câu đã hoàn thành), và **cộng điểm gamification chỉ khi câu vừa hoàn thành lần đầu** (chống cộng trùng).

**B. Free Speaking + Scenario (VAPI + AI chấm)**
1. Mở màn nói tự do (có thể kèm kịch bản). App lấy cấu hình VAPI **từ backend** (có JWT), rồi bấm mic để bắt đầu cuộc gọi.
2. STT + LLM + TTS realtime chạy **trên hạ tầng VAPI**; transcript về theo từng lượt (user/AI).
3. Kết thúc cuộc gọi → nếu đủ dài (≥3 lượt user **hoặc** ≥30s) mở màn nhận xét.
4. Server tính **số liệu bằng code** (số từ, WPM, từ đệm "um/uh", số câu hỏi…) rồi gọi **AI chấm**; lưu kết quả, tính xu hướng so với buổi trước.
5. UI hiển thị 4 tab: Tổng quan (CEFR + overall + 4 band + số liệu), Chi tiết, Sửa lỗi, Bài mẫu.

**C. Sổ tay + dashboard**
- Sổ tay gom các lỗi/từ vựng từ các buổi đã chấm, **đếm lỗi lặp** và chỉ giữ lỗi xuất hiện **>1 lần**.
- Dashboard dựng chuỗi tiến độ theo ngày (theo múi giờ người dùng): điểm trung bình các tiêu chí, WPM, phút học.

## 4. Quy tắc nghiệp vụ quan trọng
- **Read-aloud:** điểm = `100 × (1 − WER)`, kẹp 0–100. Đạt ≥80% highlight xanh.
- **Free Speaking:** rubric IELTS Speaking 4 tiêu chí band 0–9 — `fc` (Trôi chảy & mạch lạc), `lr` (Vốn từ), `gra` (Ngữ pháp), `ia` (Tương tác); `overall` = trung bình 4 tiêu chí làm tròn 0.5; `cefr` A1–C2 (AI không trả thì suy từ band). `taskAchievement` chỉ có khi có kịch bản.
- **Số liệu không cho AI bịa:** WPM/filler/số câu hỏi được **tính bằng code** rồi mới đưa vào prompt; prompt ghi rõ *"stats đã tính bằng code, không bịa"*.
- **Ngưỡng chấm:** hội thoại quá ngắn (0 từ, hoặc <3 lượt và <30s) → trả lỗi `TOO_SHORT`, không chấm.

## 5. Cách làm (kỹ thuật)
- **AI provider:** duy nhất **Groq** (model `openai/gpt-oss-120b`). File AI chỉ import Groq SDK. Feedback ghi kèm `modelInfo` (provider/model) để truy vết.
- **WER tính ở CLIENT, không phải AI:** thuật toán Levenshtein trên **mảng từ** (chuẩn hoá lowercase + bỏ dấu câu), trả `khoảng_cách / số_từ_câu_mẫu`. STT lấy từ `speech_to_text` của máy. **Không gửi audio lên cloud/Whisper** (chi phí bằng 0).
- **AI chấm nói:** ghép transcript "USER/AI", gọi Groq (`temperature 0.3`, ép trả JSON); có cơ chế **sửa JSON lỗi** (gọi lại lần 2 / parse khoan dung); chuẩn hoá + kẹp band 0–9.
- **VAPI:** key giữ trên server, client lấy qua API có JWT (fallback build-time). Giọng nói map sang voiceId khi khác mặc định.
- **Model dữ liệu:** `SpeakingSet` (các câu), `SpeakingAttempt` (transcript + WER), `SpeakingEnrollment` (tiến độ mỗi bộ), `SpeakingConversation` (hội thoại + feedback đầy đủ), `SpeakingScenario` (kịch bản: vai AI, tin nhắn mở đầu, mục tiêu…).

## 6. Điểm nhấn để trình bày
- Chấm phát âm **local, chi phí 0**, không cần mạng/cloud.
- Số liệu tính bằng code trước rồi mới đưa AI → **AI khó bịa thống kê**.
- Sổ tay **tự phát hiện lỗi lặp** qua nhiều buổi.
- Chống lỗi JSON của AI nhiều tầng; ghi rõ model đã dùng.

## 7. Giới hạn & lưu ý trung thực
- **AI KHÔNG chấm phát âm hội thoại** — prompt ghi rõ, UI hiển thị "phát âm sắp có". Chấm phát âm read-aloud là **STT thiết bị + WER**, không phải AI; độ chính xác phụ thuộc STT của máy.
- **Read-aloud và Free Speaking là 2 cơ chế tách rời:** read-aloud không gọi AI; free speaking không tính WER.
- Chỉ **1 AI provider (Groq)**; VAPI là hạ tầng voice riêng.
- Thời lượng free-speaking đo bằng đồng hồ client; waveform khi AI nói là hiệu ứng mô phỏng (không phải âm lượng thật).

## 8. Dẫn chứng mã nguồn
- Groq model: `services/aiService.js:2,8,11-12`; chấm nói + prompt "không chấm phát âm": `aiService.js:611-745`.
- WER/Levenshtein + STT (client): `feature/speaking/speaking_skills_page.dart:1208-1240, 216-244, 318-334`; submit `:362-388`.
- Số liệu bằng code + evaluate + ngưỡng too-short: `services/speakingService.js:29-48, 591-693`; sổ tay lỗi lặp `:803-873`.
- VAPI: `feature/speaking/vapi/real_vapi_service.dart:67-128`, `controllers/speakingController.js:177-199`, `vapi_config_remote_datasource.dart:31-72`.
- Model: `models/SpeakingSet.js`, `SpeakingAttempt.js`, `SpeakingEnrollment.js`, `SpeakingConversation.js`, `SpeakingScenario.js`.
