# 05 — Mobile screens (đặc tả màn cho học sinh)

> Nguyên tắc: mỗi màn phải có **1 mục tiêu** rõ. Nếu cần “2 mục tiêu” → tách thành tab hoặc 2 màn.

## 1. Onboarding & Auth

### 1.1 Splash
- Logo 80, primary; nền `surface`. Tối đa 1.5s rồi điều hướng.

### 1.2 Onboarding (3 bước)
- Hero illustration 240×240, dưới là `display 22/700` + `body 14/400` textPrimary.
- Indicator 3 chấm 6dp, gap 6, chấm active `primary`.
- Bottom: Filled `Bắt đầu` 48dp full-width. Trên có TextButton `Bỏ qua`.

### 1.3 Login / Register
- Hero gọn (logo 48 + tên app `h1`).
- Form: email + password input 48dp; helper text 12 textSecondary.
- Filled CTA full-width. Bên dưới `Đăng nhập với Google` Outlined có icon Google 18.
- Link `Quên mật khẩu` TextButton bên phải.

## 2. Home (Tab 1)

### 2.1 Cấu trúc dọc
1. **Greeting header** — `h1 18/600` `Chào, Hùng` + subtitle `body 14/400 textPrimary` `Hôm nay học gì?` + avatar 40 phải.
2. **Streak + quick stats** — card `outline` 1 dòng: 3 stat card; streak dùng **accent amber**, points **Reading orange**, level **Writing violet** (Skill Palette §1.8).
3. **Daily goal** — section `Mục tiêu hôm nay` + progress bar **accent** (100% → success green) + icon trophy amber.
4. **Skill grid / lesson list** — mỗi card có **viền trái 3px** + icon box màu kỹ năng (`skillAccentCard`):
   - Listening **blue** · Speaking **emerald** · Reading **orange** · Writing **violet** · Vocabulary **rose**
5. **Continue practice** — section list bài đang làm dở (max 3), card list 2-line + skill accent.
6. **Quick access** — hàng nút tròn 48dp, mỗi nút 1 màu kỹ năng (hoặc accent cho Lớp học).

### 2.2 Quy tắc
- Pull-to-refresh refresh tất cả section song song (hiển thị skeleton từng section, không spinner toàn màn).
- AppBar **không** có title; thay bằng greeting trong body. Icon notification + AI assistant ở phải, 22dp.

## 3. Skill hubs

> **Student Vibrancy:** mỗi hub dùng `skillAppBar` (accent line 2px) + `skillHubBanner(tint)` + filter chip selected theo màu kỹ năng. List item dùng `skillAccentCard`.

### 3.1 Listening hub
- Tab `Theo chủ đề` / `Đã làm` / `Đề xuất`.
- Card content: thumbnail 64×64 trái + title 14/600 + duration micro + level chip.
- Filter chip ngang đầu trang (level / topic / length).

### 3.2 Speaking hub
- Mode selector segmented 3 mục: Read aloud · Free talk · Phát âm.
- Mỗi mode → list set, card có waveform preview 24dp.

### 3.3 Reading list
- List card 2-line: title 14/600 + meta `· · ·` (level · phút · #đã làm) 12/400 textSecondary.
- Bookmark icon trailing, 18.

### 3.4 Writing topics
- List card có **task type chip** (Discussion / Argumentative / etc.) bên trên title.
- Trailing arrow chevron 18.

## 4. Lesson / activity runner (Listening / Reading / Writing / Speaking)

### 4.1 Header
- AppBar mỏng: back + title 16/600 + (tuỳ) timer chip phải.
- KHÔNG dùng tile gradient hoặc banner màu — header phẳng.

### 4.2 Body
- Reading detail: `Article` tab + `Question` tab (2 tab thôi).
- Article: title `h1 18/600`, body **14/400 textPrimary line-height 1.6**. Phân đoạn cách 12.
- Question: card outline 12 mỗi câu; option dùng spec MCQ ở `04-mobile-components` §11.

### 4.3 Bottom action bar
- 1 hàng cố định, padding 16, border top `outlineMuted`.
- Trái: progress text `2/10`. Phải: Filled `Tiếp` 44dp.

### 4.4 Review mode (sau khi nộp)
- Đáp án đúng: bg success-50 + icon `check_circle`.
- Đáp án sai (chosen): bg danger-50 + icon `cancel`. Đồng thời đáp án đúng vẫn xanh.
- Hiển thị thêm card `Giải thích` filled với `body 14/400 textPrimary`.

## 5. Exam runner (skills exam)

> Tham chiếu nghiệp vụ: `docs/teacher-exam-system/`. Spec UI ở đây bổ sung **mobile guidance**.

### 5.1 Lobby (realtime / scheduled)
- Hero: tên đề `h1` + countdown lớn 28/700 textPrimary.
- 3 card meta: lớp · giáo viên · thời lượng (mỗi card 1-line).
- Filled `Tham gia` 48dp full-width khi đã sẵn sàng; Disabled khi chưa tới giờ.

### 5.2 Hub bài thi (4 phần + Grammar)
- List 4–5 card 1 cột:
  - Icon kỹ năng 22 + tên kỹ năng `h3` + status chip (Đã làm / Chưa làm).
  - CTA `OutlinedButton` `Mở` bên phải.
- Section `Ngữ pháp` riêng dưới, card list từng câu MCQ thu gọn.

### 5.3 In-skill embed
- Mỗi kỹ năng mở **inline panel** trong sheet 90% chiều cao (không full-screen) — học xong ấn `Hoàn thành` để đóng.
- Sheet có handle + close icon trái + tiêu đề kỹ năng phải.

### 5.4 Submit
- Button submit ở bottom action bar, Filled primary.
- Trước khi submit → AlertDialog confirm với checklist các phần còn thiếu (nếu có) — copy theo `09`.

### 5.5 Result
- Sau khi giáo viên phát hành: hero `body 14/400 textPrimary` `Bạn đạt 78/100` + ring 88 progress + breakdown từng kỹ năng dưới list outline.

## 6. Vocabulary (Tab 2)

### 6.1 Trang chính
- 3 tile lớn (grid 2×2 + 1): Bộ từ của tôi · Tra từ điển · Ôn tập SRS.
- Mỗi tile: icon 24 + title h3 + dòng phụ 13/400 textPrimary mô tả ngắn.

### 6.2 Dictionary search
- Search bar 44 ở top sticky.
- List word dạng list 2-line: từ + phiên âm small + nghĩa main 14/400.
- Tap → detail page (định nghĩa, ví dụ, audio).

### 6.3 SRS review
- Card flip 280×360, font từ 24/700, phiên âm 14/400, ví dụ 13/400.
- 4 nút đáy: `Lại` / `Khó` / `Vừa` / `Dễ` (Outlined chip 32 cao, font 12/600).
- Cấm dùng nhiều màu sắc rực rỡ — chỉ accent primary cho nút đang focus.

## 7. Progress

- Hero card: tổng điểm tuần + chart line **chartPrimary**, 120dp cao.
- Bên dưới: 4 card 1-line breakdown kỹ năng (số liệu tabular-nums).
- Lịch sử bài làm (list 1 cột) — thumbnail kỹ năng + tên + ngày.

## 8. Profile (Tab 3)

### 8.1 Hero
- Avatar 64 + tên `h1` + email `body textPrimary` (KHÔNG textSecondary).
- Nút `Chỉnh sửa hồ sơ` Outlined 36 toàn chiều rộng.

### 8.2 Sections
- **Tài khoản**: ngôn ngữ, đổi mật khẩu, thông báo.
- **Học tập**: mục tiêu hằng ngày, quyền micro.
- **Khác**: gửi phản hồi, điều khoản, đăng xuất (destructive).
- Mỗi item là list 1-line 56dp; trailing chevron 18.

### 8.3 Đăng ký làm giáo viên (Teacher apply)
- Section riêng cuối profile với badge `info` + dòng giải thích.
- CTA Outlined `Đăng ký làm giáo viên` → mở form đầy đủ trong route con.

## 9. Notification center

- **Presentation:** dialog overlay (không full-screen route) — `NotificationDialog` + `showAppNotificationsDialog`.
- Mobile: chiều cao ~75% viewport, bo góc `sheet+2`, nền mờ phía sau; đóng bằng nút **Đóng** hoặc tap outside.
- Header dialog: title `Thông báo` 16/600 + action `Đánh dấu đã đọc`.
- List 1 cột; mỗi item: avatar/icon 40 + title 14/600 1 dòng + body 13/400 textSecondary + thời gian 12/400 textSecondary.
- Item chưa đọc: dot 8dp `accent` bên phải; nền `primaryTint`.

## 10. Dialog đặc thù

- **Permission**: dialog có icon 48, title h2, body 14/400, 2 actions.
- **Force update**: dialog không thể đóng; 1 CTA Filled `Cập nhật ngay`; có thay đổi build version 12/400 textSecondary phía dưới.
- **Soft update**: banner top page (không dialog).

## 11. Mật độ & layout đặc biệt cho `tablet` (600+)

- Trên iPad/foldable: chuyển grid 2 cột cho list khám phá.
- Content max-width 560 cho text; canh giữa.
- Vẫn dùng bottom navigation (KHÔNG side rail) — giữ trải nghiệm phone consistent.
