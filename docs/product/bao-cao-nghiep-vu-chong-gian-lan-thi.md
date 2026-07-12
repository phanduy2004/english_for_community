# Báo cáo nghiệp vụ — Chức năng Chống gian lận trong bài thi (Exam Integrity / Proctoring)

**Sản phẩm:** E4C — English for Community
**Phạm vi:** Module Thi (Exams) · Student mobile + Web · Teacher web · Backend
**Ngày:** 2026-07-08 · **Phiên bản tài liệu:** 1.0
**Ngôn ngữ:** Tiếng Việt (thuật ngữ kỹ thuật giữ tiếng Anh)

> Tài liệu mô tả **nghiệp vụ** (business/functional), không đi sâu code. Mọi quy tắc, ngưỡng và luồng trong tài liệu phản ánh **hành vi thực tế** của hệ thống tại thời điểm viết.

---

## 1. Tổng quan & mục tiêu nghiệp vụ

### 1.1. Bối cảnh
Bài thi trong E4C được làm trực tuyến (mobile & web), giáo viên không giám sát trực tiếp từng học sinh. Điều này tạo nguy cơ **gian lận**: học sinh rời màn hình thi để tra cứu, sao chép/dán đáp án, hoặc thoát chế độ toàn màn hình (web) để mở tài liệu khác.

### 1.2. Mục tiêu
Chức năng **Chống gian lận (Exam Integrity)** thu thập các **tín hiệu hành vi bất thường** trong lúc học sinh làm bài, quy đổi thành **mức độ rủi ro** (thấp / trung bình / cao) để:
- Giúp giáo viên **giám sát realtime** và **rà soát sau khi thi**.
- Làm **căn cứ tham khảo** khi đánh giá tính trung thực của bài làm.

### 1.3. Ranh giới nghiệp vụ (điều chức năng KHÔNG làm)
- **Không tự động** hủy bài, khóa bài, hay trừ điểm.
- **Không kết luận** học sinh gian lận — chỉ **cảnh báo bằng tín hiệu**.
- Quyết định cuối cùng (chấp nhận / nghi vấn / xử lý) **thuộc về giáo viên**.

> **Nguyên tắc:** đây là công cụ **hỗ trợ ra quyết định**, không phải bằng chứng pháp lý tuyệt đối. Một mức rủi ro cao là **tín hiệu cần xem xét**, không đồng nghĩa chắc chắn gian lận.

---

## 2. Đối tượng tham gia (Actors)

| Actor | Vai trò trong nghiệp vụ |
| --- | --- |
| **Học sinh (thí sinh)** | Đối tượng được giám sát trong khi bài đang làm. Hành vi (rời tab, mất focus, copy-paste, thoát fullscreen) được ghi nhận. |
| **Giáo viên** | Người tiêu thụ kết quả: xem cờ rủi ro realtime trên màn giám sát trực tiếp, xem tổng hợp theo bài giao, và ra quyết định. |
| **Hệ thống (Backend)** | Nhận tín hiệu, cộng dồn, tính lại mức rủi ro theo quy tắc, phát realtime cho giáo viên, ghi nhật ký khi rủi ro cao. |

---

## 3. Phạm vi áp dụng

### 3.1. Khi nào giám sát (ON)
- Chỉ khi bài thi ở trạng thái **đang làm** (`in_progress`).
- Áp dụng cho **mọi loại đề**: đề tích hợp 4 kỹ năng / đề kỹ năng (integrated), và đề định dạng thường.
- Áp dụng trên **cả mobile lẫn web** (mỗi nền tảng có tập tín hiệu phù hợp — xem §4).

### 3.2. Khi nào KHÔNG giám sát (OFF)
- Bài đã **nộp** (`submitted`), **hết giờ** (`expired`), hoặc đang ở **chế độ xem lại / chấm** (review).
- Chế độ **luyện tập / xem nhúng** (practice/embedded) không phải bài thi chính thức.

> Về mặt kỹ thuật, backend **từ chối** ghi nhận tín hiệu nếu bài không ở trạng thái `in_progress`, và chỉ chủ nhân bài thi mới được gửi tín hiệu cho bài của mình.

---

## 4. Các tín hiệu giám sát (Business Signals)

Hệ thống theo dõi **4 tín hiệu**. Mỗi tín hiệu được **cộng dồn** trong suốt một lượt làm bài.

| # | Tín hiệu | Ý nghĩa nghiệp vụ | Cách ghi nhận (mô tả) | Nền tảng |
| --- | --- | --- | --- | --- |
| 1 | **Số lần rời tab / ứng dụng** (`tabSwitchCount`) | Học sinh chuyển sang app khác hoặc đổi tab trình duyệt — dấu hiệu có thể đang tra cứu ngoài. | Đếm **1 lần mỗi lượt** thực sự rời khỏi màn thi (chuyển nền trên mobile / ẩn tab trên web). Các gián đoạn thoáng qua (kéo thanh thông báo, cuộc gọi, xem app switcher) **không** bị tính. | Mobile + Web |
| 2 | **Tổng thời gian mất focus** (`focusLossSeconds`, giây) | Rời màn thi càng lâu → rủi ro càng cao. | Đo khoảng thời gian **từ lúc rời đến lúc quay lại** màn thi, cộng dồn qua các lần. | Mobile + Web |
| 3 | **Số lần copy-paste** (`copyPasteAttempts`) | Sao chép/dán trong ô làm bài — dấu hiệu chép đáp án từ nguồn ngoài. | Bắt thao tác **"Paste" trên menu chọn văn bản** (long-press ở mobile / chuột phải ở web) trên mọi ô nhập của bài thi, **và** tổ hợp phím **Ctrl+C / Ctrl+V** với bàn phím vật lý. | Mobile + Web |
| 4 | **Thoát toàn màn hình** (`fullscreenExited`) | Trên web, thoát fullscreen thường để mở cửa sổ/tài liệu khác. | Khi vào bài (web) hệ thống **cố gắng bật fullscreen**; nếu học sinh **thoát fullscreen** giữa lúc thi thì đánh dấu. | Web (chỉ web) |

> **Lưu ý nền tảng:** "Thoát fullscreen" là khái niệm của web/desktop; trên mobile không áp dụng. "Copy-paste bằng Ctrl" chỉ có ý nghĩa khi có bàn phím vật lý; trên mobile tín hiệu này đến từ menu long-press "Paste".

---

## 5. Quy tắc đánh giá mức rủi ro (Business Rules)

Sau mỗi lần cập nhật tín hiệu, hệ thống **tính lại** mức rủi ro của lượt thi theo bảng sau. Chỉ cần **một** điều kiện trong cột thỏa mãn là đạt mức tương ứng (ưu tiên mức cao trước).

| Mức rủi ro | Điều kiện (đạt **ít nhất một**) |
| --- | --- |
| 🔴 **Cao (high)** | Rời tab **≥ 5 lần**, HOẶC tổng mất focus **≥ 120 giây**, HOẶC copy-paste **≥ 3 lần** |
| 🟠 **Trung bình (medium)** | Rời tab **≥ 2 lần**, HOẶC tổng mất focus **≥ 45 giây**, HOẶC copy-paste **≥ 1 lần**, HOẶC **đã thoát fullscreen** (web) |
| 🟢 **Thấp (low)** | Không rơi vào các điều kiện trên (mặc định) |

**Đặc điểm nghiệp vụ:**
- Mức rủi ro **chỉ tăng theo thời gian** trong một lượt thi (tín hiệu cộng dồn, không reset).
- Cờ **"đã thoát fullscreen"** một khi bật thì **giữ nguyên** đến hết lượt thi → duy trì tối thiểu mức trung bình.
- Ngưỡng hiện là **cố định toàn hệ thống** (chưa cấu hình riêng theo từng bài giao — xem §9 Đề xuất).

---

## 6. Luồng nghiệp vụ (Business Flow)

```mermaid
flowchart TD
    A[Học sinh bắt đầu làm bài\nstatus = in_progress] --> B[Hệ thống bật giám sát nền\n+ ép fullscreen nếu là web]
    B --> C{Phát hiện sự kiện?}
    C -- Rời tab / mất focus --> D[Ghi nhận sự kiện]
    C -- Copy-paste --> D
    C -- Thoát fullscreen (web) --> D
    D --> E[Gửi về hệ thống\n(cộng dồn vào bản ghi integrity của lượt thi)]
    E --> F[Tính lại mức rủi ro theo quy tắc §5]
    F --> G[Phát realtime tới màn giám sát của giáo viên]
    F --> H{Rủi ro = Cao?}
    H -- Có --> I[Ghi nhật ký hoạt động lớp:\n'Cảnh báo tính trung thực cao']
    H -- Không --> J[Kết thúc chu trình sự kiện]
    C -- Không --> J
    K[Học sinh nộp / hết giờ] --> L[Tắt giám sát\nDừng ghi nhận]
```

**Diễn giải:**
1. Khi học sinh bắt đầu, hệ thống theo dõi **nền** (không cản trở thao tác làm bài).
2. Mỗi sự kiện được **gửi ngay** về hệ thống và **cộng dồn** vào hồ sơ integrity của lượt thi.
3. Hệ thống **tính lại mức rủi ro** và **phát realtime** cho giáo viên đang giám sát.
4. Nếu chạm mức **Cao**, hệ thống ghi thêm một dòng **nhật ký hoạt động lớp** để lưu vết.
5. Khi nộp bài / hết giờ, giám sát **dừng**.

---

## 7. Cách giáo viên sử dụng kết quả

### 7.1. Giám sát trực tiếp (Live Monitor)
- Mỗi học sinh trong danh sách hiển thị **cờ cảnh báo ⚑** khi rủi ro ở mức **Trung bình** hoặc **Cao** (có tooltip nêu rõ mức).
- Có nút **"Xem màn hình"** để theo dõi bài làm của học sinh đang thi.
- Bảng giám sát hiển thị **số học sinh bị gắn cờ** (medium + high) để giáo viên ưu tiên chú ý.

### 7.2. Tổng hợp theo bài giao (Assignment Summary)
Giáo viên (chủ bài giao) có thể xem tổng hợp: **số lượt Cao / số lượt Trung bình / tổng số lượt** của một bài giao.

### 7.3. Lưu vết (Audit trail)
Khi một lượt thi đạt rủi ro **Cao**, hệ thống tự động ghi một mục **nhật ký hoạt động lớp** ("Cảnh báo tính trung thực cao trong khi thi") kèm chi tiết chỉ số, phục vụ rà soát về sau.

---

## 8. Dữ liệu nghiệp vụ (Business Data)

Mỗi lượt thi (attempt) lưu một hồ sơ **integrity** gồm:

| Trường | Ý nghĩa |
| --- | --- |
| `tabSwitchCount` | Tổng số lần rời tab/ứng dụng |
| `focusLossSeconds` | Tổng thời gian mất focus (giây) |
| `copyPasteAttempts` | Tổng số lần copy-paste |
| `fullscreenExited` | Đã từng thoát fullscreen hay chưa (web) |
| `riskLevel` | Mức rủi ro hiện tại: `low` / `medium` / `high` |
| `lastEventAt` | Thời điểm sự kiện gần nhất |

---

## 9. Ràng buộc, giới hạn & lưu ý nghiệp vụ

1. **Tín hiệu tham khảo, không phải bằng chứng tuyệt đối.** Một số hành vi hợp lệ vẫn có thể sinh tín hiệu (ví dụ: nhận cuộc gọi khẩn, thiết bị tự chuyển nền). Vì vậy kết quả phục vụ **giám sát & xem xét**, quyết định thuộc giáo viên.
2. **Thu thập kiểu "nỗ lực tốt nhất" (best-effort).** Nếu mất mạng hoặc thiết bị bị hệ điều hành đóng băng đúng lúc chuyển nền, một vài sự kiện có thể **không được gửi**. Con số ghi nhận là **cận dưới**, không đảm bảo tuyệt đối đầy đủ.
3. **Fullscreen trên web phụ thuộc trình duyệt.** Việc tự bật fullscreen cần thao tác người dùng còn hiệu lực; nếu bị trình duyệt chặn, hệ thống vẫn ghi nhận được nếu học sinh tự vào rồi thoát fullscreen.
4. **Khác biệt theo nền tảng.** Tín hiệu 3 (copy-paste bằng phím) và 4 (fullscreen) mạnh trên web/desktop; trên mobile trọng tâm là rời tab, mất focus và paste qua menu.
5. **Minh bạch với học sinh.** Hiện ứng dụng **chưa hiển thị thông báo** cho học sinh biết mình đang được giám sát tính trung thực. Cần cân nhắc bổ sung thông báo/điều khoản để vừa **răn đe** vừa đảm bảo minh bạch (xem §10).
6. **Ngưỡng cố định.** Mức rủi ro dùng ngưỡng chung; chưa cho phép giáo viên tùy chỉnh theo độ khó/tính chất từng bài.

---

## 10. Đề xuất phát triển (Roadmap gợi ý)

| Ưu tiên | Đề xuất | Giá trị nghiệp vụ |
| --- | --- | --- |
| Cao | **Hiển thị số liệu chi tiết** cho giáo viên (số lần rời tab, thời gian mất focus, số lần paste) ngay trên live monitor & trang chấm | Giáo viên đánh giá chính xác thay vì chỉ thấy cờ |
| Cao | **Thông báo/điều khoản cho học sinh** trước khi vào thi ("bài thi được giám sát tính trung thực") | Răn đe + minh bạch + hợp lệ về quyền riêng tư |
| Trung bình | **Ép fullscreen chắc chắn** trên web ngay từ nút "Bắt đầu" | Tăng hiệu lực tín hiệu fullscreen |
| Trung bình | **Ngưỡng cấu hình được** theo bài giao | Linh hoạt theo tính chất kỳ thi |
| Thấp | **Báo cáo/analytics** tổng hợp mức rủi ro theo lớp/kỳ | Nhìn xu hướng, phát hiện sớm |

---

## Phụ lục — Bảng thuật ngữ

| Thuật ngữ | Giải thích |
| --- | --- |
| **Attempt** | Một lượt làm bài thi của một học sinh |
| **Integrity / Proctoring** | Giám sát tính trung thực trong khi thi |
| **Tab switch** | Chuyển sang ứng dụng khác (mobile) hoặc đổi tab trình duyệt (web) |
| **Focus loss** | Khoảng thời gian màn thi không còn ở tiền cảnh |
| **Fullscreen** | Chế độ toàn màn hình của trình duyệt (web) |
| **Risk level** | Mức rủi ro tổng hợp: low / medium / high |
| **Live monitor** | Màn giám sát trực tiếp của giáo viên trong lúc thi |
```
