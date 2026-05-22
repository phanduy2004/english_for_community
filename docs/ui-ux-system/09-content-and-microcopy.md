# 09 — Content, tone & microcopy

## 1. Voice & tone

| Khán giả | Voice | Ví dụ |
|----------|-------|-------|
| Học sinh (mobile) | Thân thiện, ngắn, không xưng danh ngôi thứ ba | `Tiếp tục bài học hôm qua nhé` |
| Giáo viên (web) | Trung lập, súc tích, chuyên nghiệp | `Lưu bản nháp · Xuất bản` |
| Admin (web) | Trung lập, kỹ thuật, có context | `Đã ghi audit log: approve release v1.4.2` |

**Quy tắc chung:**
- Xưng `bạn` cho học sinh. Không dùng `quý vị`.
- Câu CTA dùng động từ ở đầu: `Bắt đầu`, `Lưu`, `Phát hành`. Tránh `Hãy bắt đầu`.
- Không dùng dấu `!` trong UI thường (chỉ trong dialog chúc mừng).

## 2. Localization (l10n)

- Hai locale: **`en`**, **`vi`**. Mọi string phải qua `app_en.arb` + `app_vi.arb`.
- Khoá ARB phải mang nghĩa: `homeGreetingMorning`, không `text_1`.
- Số nhiều: dùng ICU MessageFormat `plural`.
- Định dạng ngày: `intl.DateFormat.yMMMd().add_jm()` cho web; `add_jm()` ngắn gọn cho mobile.

## 3. Số & đơn vị

- Số có ngàn: `1.234` (vi) / `1,234` (en).
- Phần trăm: dấu `%` không khoảng cách: `78%`.
- Thời lượng: `7 phút 30 giây` (vi) / `7m 30s` (en mobile) — dùng helper `formatDuration`.

## 4. Microcopy mẫu

### 4.1 Empty states

| Vị trí | Title | Body | CTA |
|--------|-------|------|-----|
| Home không bài | `Bắt đầu hành trình của bạn` | `Chọn một kỹ năng để luyện hôm nay.` | `Khám phá` |
| Vocabulary trống | `Chưa có từ nào trong bộ` | `Lưu từ khi tra để ôn lại sau.` | `Tra từ điển` |
| Notification trống | `Tất cả đã đọc` | `Bạn không bỏ lỡ thông báo nào.` | — |
| Teacher cần chấm trống | `Bạn đã chấm xong` | `Không có lượt làm chờ chấm.` | — |
| Bảng admin trống | `Chưa có dữ liệu` | `Khi có dữ liệu, nó sẽ hiển thị ở đây.` | — |

### 4.2 Errors

| Mã | Mobile | Web |
|----|--------|-----|
| Network | `Không có mạng. Thử lại?` | `Mất kết nối mạng. Thử lại sau ít giây.` |
| 401 | `Phiên đăng nhập đã hết. Đăng nhập lại để tiếp tục.` | giống mobile |
| 403 | `Bạn không có quyền thực hiện việc này.` | giống mobile |
| 500 | `Có lỗi xảy ra. Vui lòng thử lại.` | `Lỗi máy chủ. Đã ghi log.` |
| Validation | `Hãy điền đủ ô bắt buộc.` | `Vui lòng kiểm tra các trường được đánh dấu.` |

### 4.3 Confirmations (destructive)

> Cấu trúc: hệ quả + sự cụ thể.

| Hành động | Title | Body |
|-----------|-------|------|
| Xoá lớp | `Xoá lớp “12A” ?` | `Tất cả thành viên sẽ bị gỡ khỏi lớp. Bài đã giao vẫn được giữ trong lưu trữ.` |
| Phát hành điểm | `Phát hành kết quả?` | `Học sinh sẽ nhận được điểm và phản hồi ngay khi bạn xác nhận.` |
| Force end session | `Kết thúc phiên thi?` | `Mọi học sinh đang làm sẽ bị nộp tự động.` |
| Reject teacher app | `Từ chối đơn?` | `Người dùng sẽ nhận thông báo kèm lý do bạn nhập.` |

### 4.4 Success / done

- **Mobile** học xong: `Hoàn thành! +12 điểm 🎉` (chỉ chỗ này được dùng emoji).
- **Web** lưu xong: `Đã lưu` (toast 1.5s, tự ẩn).
- **Web** phát hành: `Đã phát hành — học sinh có thể xem điểm.`

### 4.5 Onboarding (mobile)

| Bước | Title | Body |
|------|-------|------|
| 1 | `Học theo cách bạn` | `Bốn kỹ năng, một lộ trình rõ ràng.` |
| 2 | `Phản hồi của AI` | `Sửa lỗi nhanh, giải thích đơn giản.` |
| 3 | `Đi đường dài cùng cộng đồng` | `Bạn đồng hành sẽ giúp bạn không bỏ cuộc.` |

## 5. Quy tắc viết

### 5.1 Title
- Ngắn ≤ 6 từ; viết hoa chữ đầu, không Title Case.
- Tên riêng giữ nguyên (`English for Community`).

### 5.2 Body
- 1–2 câu. Nếu cần nhiều hơn → thêm phần `Help` link.
- Không lặp tên app trong body trừ khi cần.

### 5.3 Button label
- Động từ chính + danh từ ngắn: `Save changes`, `Lưu thay đổi`, `Phát hành kết quả`.
- Tránh `Click here`, `OK / Cancel` chung chung trong context có nghĩa rõ.

### 5.4 Tooltip / helper
- 1 dòng, ≤ 80 ký tự. Đứng riêng câu khi giải thích phức tạp.

## 6. Date & time copy

- Thời gian quá khứ: `2 giờ trước`, `3 ngày trước` (≤ 7 ngày). Sau đó dùng ngày cụ thể.
- Thời gian tương lai (đếm ngược): `còn 1 giờ 12 phút`. Dưới 1 phút: `< 1 phút`.

## 7. Kết quả & điểm số

- Tổng điểm: `78 / 100`.
- Phần trăm: `78%`.
- Phân loại (gamification mobile): `Cần cố gắng / Khá / Tốt / Xuất sắc`.

## 8. Cấm dùng

- ❌ Tiếng Anh nguyên văn trong app vi (trừ tên kỹ thuật quen thuộc: `email`, `OTP`, `JWT`, `link`).
- ❌ Slang, viết tắt không chuẩn (`ngon`, `vl`, `tks`).
- ❌ Tiêu đề chứa `…` cuối câu để giả vờ tải.
- ❌ Tô màu chữ rực rỡ (cam/đỏ/xanh tươi) cho nội dung không phải status.
