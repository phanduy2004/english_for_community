# 01 — Design philosophy & audience split

## 1. Khán giả & nền tảng chủ đạo

| Vai trò | Nền tảng chủ đạo | Lý do | Hỗ trợ phụ |
|---------|------------------|-------|------------|
| **Học sinh (`user`)** | **Mobile (Android, iOS)** | Học mọi lúc, tai nghe, ghi âm, micro-luyện tập | Web có thể chạy nhưng không đầu tư đặc tả riêng |
| **Giáo viên (`teacher`)** | **Web (≥1024 dp)** | Soạn đề, chấm hàng loạt, theo dõi lớp = nhiều dữ liệu | Mobile chỉ làm “lite”: xem dashboard, duyệt nộp khẩn |
| **Admin** | **Web (≥1280 dp)** | Quản trị nền tảng, audit, release management | Không cần mobile |

> **Hệ quả thiết kế:** thiết kế cho mỗi vai trò **không pha trộn**. Một màn “teacher trên mobile” chỉ là phiên bản tối giản của màn web — **không** thiết kế ngược lại từ mobile lên web.

## 2. Năm nguyên tắc gốc

### P1. Chữ đen, mảnh, vừa đủ — và brand cũng **đen**
- Body mặc định: **#1C1917** (`textPrimary`). Không dùng `textSecondary`/`textMuted` cho body chính.
- **Brand mark = `#0A0A0A`** (Editorial black). Filled button, chevron, "Open class" link, AppBar logo đều dùng đen — không teal, không indigo.
- Accent duy nhất là **amber `#F59E0B`** dành cho ăn mừng (streak, KPI nổi, chart highlight). Không bao giờ tô heading bằng accent.
- Trọng số mặc định **w400**; chỉ tăng w500/w600 cho **tiêu đề** hoặc **nhãn nhấn**.
- Mobile body chuẩn **14sp**, không phải 15–16. Web body chuẩn **13px**.
- Letter-spacing âm nhẹ (`-0.1` đến `-0.3`) cho heading, **0** cho body.

### P2. Khoảng trắng tử tế hơn nhiều màu sắc
- Ưu tiên padding/spacing chính xác > viền/màu trang trí.
- Card thường: **viền 1px** thay vì shadow dày. Shadow chỉ dành cho dialog/sheet/floating button.
- Không bao giờ dùng cùng lúc shadow + viền đậm trên cùng một surface.

### P3. State phải nhìn thấy
- Mọi thao tác đều có 4 state: **idle / hover (web) / pressed / disabled**, và 3 status: **loading / empty / error**.
- Empty state **luôn** có illustration hoặc icon + 1 dòng giải thích + 1 CTA gợi ý.
- Loading dùng skeleton (mobile + web), không spinner toàn màn nếu đã có layout.

### P4. Một component, một mục đích
- Không tạo 3 kiểu “card” na ná. Nếu có 3 → gộp về 1 với `variant`.
- Không có “custom button đẹp” trong feature folder; mọi button dùng `FilledButton` / `OutlinedButton` / `TextButton` qua theme.

### P5. Server quyết định, UI phản chiếu
- Hết hạn, đóng phiên, quota — luôn lấy từ server.
- Toast/snackbar dùng đúng level: `info` / `success` / `warning` / `error`. Không lạm dụng emoji/màu mè.

## 3. Cảm hứng tham chiếu (chỉ định danh, không sao chép)

### Mobile (cho học sinh)
| App | Lấy cảm hứng | Dùng cho |
|-----|--------------|----------|
| **Duolingo** | Streak chip, progress ring, micro-feedback | Home, gamification, dialog “xong bài” |
| **Headway / Blinkist** | Card nội dung text-heavy, line-height thoáng | Reading detail, vocab card |
| **Robinhood / Revolut** | List dày, số liệu tinh tế, chart mảnh | Progress, history |
| **iOS HIG / Material 3** | Native pattern (sheet, segmented, navigation bar) | Toàn app |
| **Lingvist / Drops** | Card flip, chuyển động ngắn | Vocab review |
| **Notion mobile** | Header rỗng, scroll mượt | Profile, settings |

### Web (cho teacher & admin)
| App | Lấy cảm hứng | Dùng cho |
|-----|--------------|----------|
| **Linear** | Sidebar hẹp, list dày, command palette `Cmd+K`, keyboard-first | Layout, list view |
| **Notion** | Page header rộng thoáng, hover reveal | Editor, settings page |
| **Vercel Dashboard** | Card dạng tile, viền 1px subtle | Overview, classroom card |
| **Stripe Dashboard** | Bảng số liệu, filter bar, drawer chi tiết | Grading hub, release list |
| **Cal.com / Cron** | Lịch dày, dropdown gọn | Exam schedule, sessions |
| **GitHub** | Diff, code, audit log | Audit trail, diff release |

## 4. Anti-patterns (cấm)

- ❌ Body chữ #57534E hoặc nhạt hơn cho nội dung chính.
- ❌ Heading tô màu primary để “nổi”. Heading luôn `textPrimary`.
- ❌ Card tròn 24+ trên mobile (tủn mủn). Mobile card radius **12**.
- ❌ Border `0.5px` trên Android. Tối thiểu **1px** để render đều.
- ❌ Dialog dùng background gradient. Surface phẳng `surfaceCard`.
- ❌ Đặt 2 màu primary cạnh nhau (đen + amber). Brand là **đen**, `accent` (amber) chỉ dùng cho ăn mừng / KPI nổi, không cho thao tác chính.
- ❌ Animation > 250ms trên mobile cho transition trang chuẩn. Quá lâu = chậm.
- ❌ “Long shadow” / blur-glow / glassmorphism. App học, không phải app trang trí.

## 5. Thứ tự ưu tiên khi review thiết kế

1. **Đọc được** trên màn 6” ngoài nắng → contrast, font weight.
2. **Bấm trúng** với ngón tay → hit target ≥ 44dp mobile / ≥ 32px web.
3. **Hiểu được** không cần text → icon + label nhất quán.
4. **Đẹp** — đến cuối; đẹp đi sau ba tiêu chí trên.
