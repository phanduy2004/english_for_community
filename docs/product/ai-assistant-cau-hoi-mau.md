# AI Assistant — Tổng hợp nội dung có thể hỏi

> Danh mục câu hỏi mẫu mà **AI Assistant** (nút ✨ ở màn Home) có thể trả lời, ánh xạ theo **20 native tool** backend đang expose. Dùng để test, viết hướng dẫn người dùng, hoặc onboard.

| | |
|---|---|
| **Cập nhật** | 2026-07-08 |
| **Backend** | `chatService.js` (Groq native tool-calling) · `tools/definitions.js` · `tools/implementations.js` |
| **Số tool** | 20 (read-only, `userId` server-injected) |
| **Mới thêm** | 🆕 `get_classroom_assignments`, `get_classroom_activity` |
| **Ngôn ngữ trả lời** | AI tự sinh (Markdown), thường theo ngôn ngữ câu hỏi |

---

## Cách hoạt động (tóm tắt)

- Người dùng hỏi → model Groq tự chọn & gọi tool phù hợp (nhiều vòng, tối đa 5) → tổng hợp câu trả lời.
- Mọi dữ liệu **chỉ của chính người dùng** (lọc theo `userId` từ token, không nhận id từ câu hỏi) → không xem được dữ liệu học sinh khác.
- Ngày/giờ tính theo **timezone của user**; các mốc "hôm nay / tuần này / tuần trước / tháng này" do server tự resolve.
- **Read-only:** AI không sửa/xoá dữ liệu, không nộp bài, không chấm điểm hộ.

---

## A. Hồ sơ & mục tiêu cá nhân

**Tool:** `get_profile`

- "Thông tin tài khoản của tôi?"
- "Mục tiêu học tập của tôi là gì?"
- "Level / trình độ CEFR của tôi hiện tại?"
- "Streak của tôi được bao nhiêu ngày rồi?"
- "Tôi đang đặt mục tiêu bao nhiêu phút/bài mỗi ngày?"
- "Tôi tham gia app từ khi nào? Tổng điểm (XP) bao nhiêu?"

---

## B. Tiến độ & lịch sử học tập

| Tool | Dùng khi |
|---|---|
| `get_daily_activity` | Hỏi về **một ngày** cụ thể / hôm nay |
| `get_learning_history_period` | Tổng quan **hôm nay / tuần này / tuần trước / tháng này** |
| `get_learning_history` | Khi đã biết **chính xác** startDate–endDate |
| `get_progress_trend` | Xu hướng theo **chuỗi ngày** + streak |
| `get_skill_statistics` | Thống kê **một kỹ năng** theo kỳ |
| `analyze_weaknesses` | Tìm **điểm yếu / kỹ năng bỏ bê** |

- "Hôm nay tôi đã học được những gì?"
- "Ngày 05/07/2026 tôi làm bài gì?"
- "Tuần này tôi học thế nào?" · "Tuần trước tôi học bao nhiêu phút?"
- "Tổng quan việc học tháng này của tôi?"
- "Xu hướng học tập mấy ngày gần đây của tôi ra sao?"
- "Thống kê kỹ năng Reading của tôi tuần này?" · "Điểm trung bình Writing tháng này?"
- "Điểm yếu của tôi là gì? Tôi nên cải thiện kỹ năng nào?"

---

## C. Chi tiết theo kỹ năng

| Tool | Kỹ năng |
|---|---|
| `get_reading_details` | Reading — bài đã hoàn thành, điểm, độ khó |
| `get_listening_details` | Listening / Dictation — độ chính xác |
| `get_speaking_details` | Speaking — Read-aloud / Shadowing, accuracy |
| `get_writing_details` | Writing — bài đã nộp, điểm, nhận xét tổng |
| `get_lesson_detail` | Chi tiết **một bài học** + số lần làm |

- "5 bài đọc gần nhất của tôi điểm thế nào?"
- "Những bài đọc khó (hard) tôi đã làm?"
- "Các bài nghe/dictation gần đây của tôi?"
- "Bài Speaking Shadowing gần đây tôi làm ra sao?"
- "Các bài viết tôi đã nộp — điểm và nhận xét?"
- "Bài viết nào của tôi đang chờ chấm?"

---

## D. Từ vựng

| Tool | Dùng khi |
|---|---|
| `get_vocab_list` | Danh sách từ theo trạng thái (learning / saved / recent) |
| `get_vocab_review` | Từ **đến hạn ôn tập** hôm nay |

- "Danh sách từ tôi đang học?"
- "Những từ tôi đã lưu?"
- "Hôm nay tôi cần ôn lại bao nhiêu từ? Là những từ nào?"

---

## E. Lớp học & bài tập 🆕

| Tool | Dùng khi |
|---|---|
| `get_classrooms` | Lớp đang tham gia + giáo viên + sĩ số |
| 🆕 `get_classroom_assignments` | **Bài tập/đề thi trong lớp**: hạn nộp + trạng thái của bạn + điểm |
| 🆕 `get_classroom_activity` | **Thông báo/hoạt động lớp** (bài mới giao, kết quả đã trả…) |
| `get_exam_results` | Điểm các **bài thi đã nộp/đã chấm** |

**Lớp & giáo viên** (`get_classrooms`)
- "Tôi đang học những lớp nào? Giáo viên là ai?"
- "Lớp của tôi có bao nhiêu thành viên?"

**Bài tập lớp học** 🆕 (`get_classroom_assignments`)
- "Lớp tôi có bài tập nào chưa làm không?"
- "Bài tập nào sắp tới hạn / đã quá hạn?"
- "Điểm các bài tập trong lớp của tôi?"
- "Bài tập của lớp *[tên lớp]* có những gì?"
- "Tôi còn bài nào phải nộp không?"

> `myStatus`: chưa làm / đang làm / đã nộp (chờ chấm) / đã chấm — `score` chỉ hiện khi giáo viên đã trả kết quả.
> `timingStatus`: đang mở / chưa tới giờ / quá hạn / đã đóng / thi trực tiếp / luyện tập.

**Thông báo & hoạt động lớp** 🆕 (`get_classroom_activity`)
- "Lớp có thông báo gì mới không?"
- "Gần đây lớp có giao bài nào không?"
- "Giáo viên đã trả kết quả bài thi chưa?"
- "Tôi có thông báo nào chưa đọc không?"

> Chỉ đọc **thông báo của chính bạn** (không lộ hoạt động học sinh khác); không bao gồm tin nhắn chat lớp (đã có kênh chat riêng).

**Điểm bài thi** (`get_exam_results`)
- "Điểm các bài thi/kiểm tra gần đây của tôi?"
- "Bài thi nào của tôi đã được chấm điểm?"
- "Bài thi gần nhất tôi được bao nhiêu điểm?"

---

## F. Đề xuất & xếp hạng

| Tool | Dùng khi |
|---|---|
| `get_exercises_by_difficulty` | Gợi ý bài **chưa làm** theo kỹ năng + độ khó |
| `get_leaderboard` | Bảng xếp hạng XP + thứ hạng của bạn |

- "Gợi ý cho tôi vài bài đọc mức medium mà tôi chưa làm?"
- "Có bài nghe dễ nào tôi chưa thử không?"
- "Tôi đang xếp hạng thứ mấy?" · "Top học viên là ai?"

---

## G. Câu hỏi tổng hợp (multi-tool, nhiều vòng)

AI có thể gọi nhiều tool trong nhiều vòng để trả lời câu hỏi rộng:

- "Phân tích điểm mạnh/yếu tháng này và đề xuất kế hoạch học tiếp theo."
  → `analyze_weaknesses` + `get_skill_statistics` + `get_*_details` + `get_progress_trend`
- "Tổng kết toàn bộ việc học tuần này của tôi."
  → `get_learning_history_period` + chi tiết từng kỹ năng + `get_classroom_assignments`
- "Tôi nên tập trung vào đâu tuần tới?"
  → `analyze_weaknesses` + `get_classroom_assignments` (bài sắp tới hạn) + `get_vocab_review`

---

## H. Ngoài phạm vi (AI sẽ không làm)

- ❌ Xem dữ liệu/điểm của **học sinh khác** hay lớp mình không tham gia.
- ❌ Xem điểm bài thi **chưa được giáo viên trả kết quả**.
- ❌ Nộp bài, chấm điểm, chỉnh sửa hồ sơ, đổi cài đặt (chỉ **đọc**).
- ❌ Đọc nội dung **chat lớp** (thuộc kênh chat inbox riêng).

---

## Phụ lục — Bảng 20 tool

| # | Tool | Nhóm |
|---|---|---|
| 1 | `get_profile` | Hồ sơ |
| 2 | `get_daily_activity` | Tiến độ |
| 3 | `get_learning_history_period` | Tiến độ |
| 4 | `get_learning_history` | Tiến độ |
| 5 | `get_progress_trend` | Tiến độ |
| 6 | `get_skill_statistics` | Tiến độ |
| 7 | `analyze_weaknesses` | Tiến độ |
| 8 | `get_reading_details` | Kỹ năng |
| 9 | `get_listening_details` | Kỹ năng |
| 10 | `get_speaking_details` | Kỹ năng |
| 11 | `get_writing_details` | Kỹ năng |
| 12 | `get_lesson_detail` | Kỹ năng |
| 13 | `get_vocab_list` | Từ vựng |
| 14 | `get_vocab_review` | Từ vựng |
| 15 | `get_classrooms` | Lớp học |
| 16 | 🆕 `get_classroom_assignments` | Lớp học |
| 17 | 🆕 `get_classroom_activity` | Lớp học |
| 18 | `get_exam_results` | Lớp học |
| 19 | `get_exercises_by_difficulty` | Đề xuất |
| 20 | `get_leaderboard` | Xếp hạng |
