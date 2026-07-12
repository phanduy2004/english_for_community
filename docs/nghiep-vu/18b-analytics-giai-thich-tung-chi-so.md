# 18b — Teacher Analytics: giải thích từng chỉ số & bảng

> **Mục đích:** giải thích **ý nghĩa · cách tính · lưu ý** của mọi con số, biểu đồ, bảng trên màn **Teacher Analytics (web)**, để bạn đọc hiểu và trình bày cho người khác.
> Bám mã nguồn: UI `lib/feature/teacher/teacher_analytics_page.dart`; tính toán `english_for_community_backend/src/services/teacherAnalyticsChartsService.js` + `teacherDashboardService.js`.
> (Xem thêm tổng quan nghiệp vụ ở [`18-thong-ke-lop-hoc-analytics.md`](18-thong-ke-lop-hoc-analytics.md).)

---

## 0. Áp dụng cho TOÀN màn (đọc trước)

| Khái niệm | Ý nghĩa |
|---|---|
| **Phạm vi (scope)** | Gồm **lớp giáo viên sở hữu** (chưa archive) **∪ lớp đang đồng-dạy (co-teacher active)**. Bài giao xét = do chính GV tạo **hoặc** thuộc các lớp đó. |
| **Khung thời gian** | Nút `7d / 14d / 30d`. Cửa sổ N ngày tính theo **lịch Việt Nam (+07:00)** và **GỒM hôm nay**. "Kỳ trước" (để so sánh xu hướng) = **N ngày liền trước** đó. |
| **Nguồn điểm** | Điểm bài thi thang **0–10**. Các chỉ số điểm chỉ tính bài **đã có điểm cuối** (finalized), bỏ bài còn chờ chấm. |

Màn chia **4 khu**: **A. Overview** · **B. Activity & scores** · **C. Students & questions** · **D. Integrity & submissions**.

---

## A. OVERVIEW — dải 6 ô KPI + câu tóm tắt

Mỗi ô = **một con số cốt lõi** để nhìn phát biết ngay "sức khỏe lớp".

| Ô (KPI) | Ý nghĩa | Cách tính | Lưu ý |
|---|---|---|---|
| **Active students** | Số học sinh **đang hoạt động** trong phạm vi | Đếm thành viên `active`, `roleInClass = student` | Không tính co-teacher |
| **Avg score** `x/10` | **Điểm trung bình** của lớp trong kỳ (thang 10) | Trung bình `finalScore` các bài đã chấm trong kỳ | Badge `↗0.3` = **chênh lệch tuyệt đối** so kỳ trước (band điểm, KHÔNG phải %) |
| **Completion** `%` | Tỷ lệ **lượt làm đã NỘP** trên tổng lượt đã **BẮT ĐẦU** | `nộp / (nộp + đang làm) × 100` | ⚠️ **KHÔNG** phải "% bài được giao đã làm". VD 96% = trong các lượt đã mở, 96% đã bấm nộp, chỉ 4% còn dở |
| **Submissions** | Số bài **nộp trong kỳ** | Tổng số nộp mỗi ngày (biểu đồ Submissions per day) | Badge `↗125%` = **% thay đổi** so kỳ trước. Con số này (trong kỳ) **khác** `submitted` all-time dùng ở Completion |
| **In progress** | Số lượt **đang làm dở** (chưa nộp) | `attempts.inProgress` | |
| **Pending grading** | Số bài **cần chấm** | Bài đã `submitted` mà (chờ chấm tay/AI) **hoặc** đã chốt điểm nhưng **chưa phát hành** | Cả ô **bấm được** → sang màn chấm (Dashboard). Định nghĩa dùng chung với inbox/summary để 3 nơi không lệch |

**Câu tóm tắt "14-day summary"** (dưới dải KPI): ghép tự động các mẩu: điểm TB lớp · **kỹ năng yếu nhất** (nếu < 6.5) · số HS **chưa nộp** · số bài **chờ chấm**. Nếu không có gì đáng nói → câu mặc định.

---

## B. ACTIVITY & SCORES — hoạt động & điểm

### B1. Submissions per day (cột)
- **Ý nghĩa:** số bài **nộp mỗi ngày** trong kỳ → thấy ngày nào lớp nộp nhiều/ít.
- **Cách tính:** đếm bài `submitted` theo **ngày lịch VN**; ngày không có bài **điền 0** (để trục ngày liền mạch). Phụ đề = **TB bài/ngày**.
- **Lưu ý:** đã **bỏ đường gạch đỏ** phủ lên cột (trước gây rối) — giờ chỉ đọc **1 nghĩa: chiều cao cột = số bài**.

### B2. Score distribution (histogram)
- **Ý nghĩa:** **phân phối điểm** — có bao nhiêu bài rơi vào từng khoảng điểm.
- **Cách tính:** 5 khoảng thang 10: **0–2 · 2–4 · 4–6 · 6–8 · 8–10** (`bucket = min(4, floor(finalScore/2))`). Vạch **nét đứt** = **điểm TB lớp** (`avg x`). Phụ đề = **số bài đã chấm**. *(Nếu đề cũ chỉ có thang %, tự fallback sang các mốc %.)*
- **Lưu ý:** cột giờ dùng **màu trung tính brand** (trước dùng đỏ→xanh gây cảm giác "báo động").

### B3. Score trend (đường)
- **Ý nghĩa:** **điểm trung bình lớp mỗi ngày** (0–10) → thấy lớp đang lên/xuống.
- **Cách tính:** trung bình `finalScore` theo từng ngày trong kỳ. Chỉ hiện khi có ≥ 2 ngày dữ liệu.

### B4. Skill breakdown (điểm theo kỹ năng)
- **Ý nghĩa:** **điểm TB theo 5 kỹ năng**: Listening · Reading · Writing · Speaking · Grammar → biết lớp yếu kỹ năng nào.
- **Cách tính:** trung bình điểm từng kỹ năng, **chỉ tính phần đã chốt điểm** (`finalized`, có điểm). Kỹ năng không có dữ liệu → ẩn.

---

## C. STUDENTS & QUESTIONS — học sinh & câu hỏi

### C1. Students needing attention (bảng học sinh cần chú ý)
Danh sách **học sinh bị gắn cờ rủi ro** (không phải cả lớp) để GV can thiệp.

| Cột | Ý nghĩa |
|---|---|
| **STUDENT** | Avatar (chữ cái) + tên + email |
| **AVG %** | **Điểm trung bình** của HS (quy %), pill tô màu theo thang (thấp = đỏ) |
| **SUBMITTED** | **Số bài đã nộp / số bài được giao** (VD `4 / 27`) |
| **ALERT** | **Lý do bị gắn cờ** (chip màu) |

**Loại ALERT — theo thứ tự ưu tiên rủi ro:**
1. **Not submitting** (chưa nộp) — nặng nhất.
2. **Low score** (điểm TB < 50%).
3. **Late** (nộp trễ ≥ 2 lần) — màu cam.

> Chỉ xét **bài giao đang mở (`active`)** thuộc lớp GV; mỗi cặp (HS, bài giao) chỉ lấy **lượt mới nhất** (chống đếm trùng).

### C2. Hardest questions / Item analysis (câu khó nhất)
- **Ý nghĩa:** những **câu hỏi cả lớp làm sai nhiều nhất** → biết nội dung nào cần dạy lại.
- **Cách tính:** gộp theo (bài giao, câu); **bỏ câu còn chờ chấm tay** (tránh giả "0% đúng"); chỉ lấy câu có **≥ 3 lượt trả lời**; sắp **% đúng tăng dần**; lấy **top 6**.

---

## D. INTEGRITY & SUBMISSIONS — liêm chính & nộp bài

### D1. Integrity (tín hiệu chống gian lận)
- **Ý nghĩa:** mức độ **hành vi bất thường** khi thi trong kỳ.
- **Cách tính:** phân bố **mức rủi ro** (low / medium / high) + tổng các **tín hiệu**: rời tab, copy-paste, thời gian mất tập trung, thoát fullscreen. *(Chi tiết cơ chế xem [`16-chong-gian-lan-thi.md`](16-chong-gian-lan-thi.md).)*

### D2. Mode breakdown + On-time (chế độ & đúng hạn)
- **Ý nghĩa:** bài giao phân theo **chế độ** (tự học / theo lịch / trực tiếp / luyện tập) và **tỷ lệ nộp đúng hạn**.
- **Cách tính:** **on-time** = `submittedAt ≤ dueAt` (không có hạn → tính đúng hạn); **late** = nộp sau hạn; **missing** = `max(0, số được giao − số đã nộp)`.

---

## ⚠️ Những chỗ DỄ HIỂU NHẦM (nên nắm để giải thích)

1. **"Completion 96%" ≠ 96% bài được giao đã làm.** Nó là **nộp / (nộp + đang làm)** — tức trong các lượt *đã mở*, bao nhiêu % đã bấm nộp. Một lớp mới làm ít bài vẫn có completion cao.
2. **"Submissions" (KPI, trong kỳ) khác `submitted` (all-time)** dùng trong Completion → 2 con số này có denominator khác nhau, đừng cộng/so trực tiếp.
3. **Đơn vị badge trend khác nhau:** *Avg score* = **chênh tuyệt đối** (VD +0.3 band); *Submissions* = **% thay đổi** (VD +125%). `125%` nghĩa là kỳ này gấp ~2,25 lần kỳ trước, không phải "125% của một cái gì".
4. **Số liệu thấp trong ảnh (0.8/10, 9%, 29%) là dữ liệu seed/test**, không phải lỗi hiển thị.
5. **Bảng "needing attention" chỉ xét bài giao đang `active`** — HS yếu ở bài đã đóng sẽ không hiện.
6. **Các biểu đồ gộp mọi lớp của GV** (chưa lọc theo từng lớp riêng ở tầng biểu đồ).

---

## Tham chiếu mã nguồn
- UI: `lib/feature/teacher/teacher_analytics_page.dart` — KPI `_KpiRow` (~415), Completion `submitted/(submitted+inProgress)` (~438), bảng at-risk `_AtRiskTable` (~1216), phân phối điểm `_ScoreDistBars` (~801).
- Backend tính toán: `services/teacherAnalyticsChartsService.js` (window/dedupe/at-risk/hardest/skill/integrity), `teacherAnalyticsScope.js` (scope + pending-grading chuẩn), `teacherDashboardService.js` (summary KPI).
