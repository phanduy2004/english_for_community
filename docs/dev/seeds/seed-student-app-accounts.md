# Seed dữ liệu học sinh + Admin (Student App & Console)

> Script: `npm run seed:student-app`  
> Tag trong DB: `[SEED:StudentApp]`

---

## 1. Chạy seed (thứ tự khuyến nghị)

```bash
cd english_for_community_backend

# 1) Admin + user demo cũ
npm run seed:admin

# 2) Giáo viên Hoàng + 15 HS + lớp + đề thi + bài nộp
npm run seed:teacher-hoangdong

# 3) Hoạt động học tập (Home, Progress, History, Admin activity)
npm run seed:student-app
```

**Một lệnh gộp:**

```bash
npm run seed:full-demo
```

Cần file `.env` với **`MONGO_URI`** trỏ đúng database bạn đang test.

---

## 2. Tài khoản học sinh đăng nhập app

### Bộ HoangDong (sau `seed:teacher-hoangdong`)

| | |
|---|---|
| **Mật khẩu** | `Student@123456` |
| **Email mẫu** | `seed.hd.student01@e4c.dev` … `seed.hd.student15@e4c.dev` |
| **Chi tiết** | [`seed-hoangdong-accounts.md`](seed-hoangdong-accounts.md) |

**Tài khoản demo đầy đủ nhất:** `seed.hd.student01@e4c.dev` (30 ngày tiến độ, đủ 5 kỹ năng, 20 từ vựng, thông báo).

### Bộ demo (nếu chưa chạy HoangDong)

| Email | Mật khẩu |
|---|---|
| `seed.demo.student01@e4c.dev` | `Student@123456` |
| `seed.demo.student02@e4c.dev` | `Student@123456` |
| `seed.demo.student03@e4c.dev` | `Student@123456` |

---

## 3. Tài khoản Admin

| Email | Mật khẩu |
|---|---|
| `admin@englishapp.com` | `adminpassword123` |
| `testuser@example.com` | `Test@1234` |

Chi tiết: [`seed-test-accounts.md`](seed-test-accounts.md)

---

## 4. Dữ liệu `seed:student-app` tạo ra

### Trên app học sinh (`role: user`)

| Khu vực | Dữ liệu |
|---|---|
| **Home / Progress** | `UserDailyProgress` 14–30 ngày; streak, level, điểm trên `User` |
| **Nghe (dictation)** | `DictationAttempt` + `Enrollment` theo bài Listening |
| **Nghe hiểu** | `ListeningCompAttempt` |
| **Đọc** | `ReadingAttempt` + `ReadingProgress` |
| **Nói** | `SpeakingAttempt` + `SpeakingEnrollment` |
| **Viết** | `WritingSubmission` (có feedback AI mẫu cho HS chính) |
| **Từ vựng** | 10–20 từ / user (`Word`) |
| **Thông báo** | 4 notification (chỉ HS `student01`) |

Nếu DB **chưa có CMS**, script tự tạo bài mẫu có tiền tố `[SEED:StudentApp]` (Listening, Reading, Speaking, Listening Comp, Writing topic).

### Trên Admin console

| Màn hình | Dữ liệu |
|---|---|
| **Activity history / Submissions** | Writing, Reading, Speaking, Listening từ `historyService` |
| **Reports** | 3 báo cáo mẫu (`pending` / `reviewed`) |
| **User management** | 15 học sinh HoangDong (từ seed giáo viên) |

Kết hợp `seed:teacher-hoangdong`: admin/giáo viên còn thấy **bài thi lớp**, **chấm điểm**, **analytics**.

---

## 5. Chạy lại (idempotent)

- Script **xóa** dữ liệu học tập cũ của các user seed (progress, attempts, vocab, notification/report có tag) rồi **tạo lại**.
- **Không** xóa user, lớp, đề thi HoangDong (do script khác).
- Chạy lại an toàn: `npm run seed:student-app`

---

## 6. Biến môi trường (tùy chọn)

| Biến | Mặc định |
|---|---|
| `MONGO_URI` | *(bắt buộc)* |
| `SEED_STUDENT_PASSWORD` | `Student@123456` |

---

## 7. Xử lý lỗi thường gặp

| Triệu chứng | Cách xử lý |
|---|---|
| Login `Invalid credentials` | `npm run repair:seed-logins` hoặc chạy lại seed tương ứng |
| Home trống, không có biểu đồ | Chạy `npm run seed:student-app` |
| **Lịch sử bài tập trống** (Profile → Lịch sử) | Xem mục **8** bên dưới |
| Admin Activity trống | `npm run seed:student-app` + chọn user trong admin |
| Đề thi / lớp trống | Chạy `npm run seed:teacher-hoangdong` |
| Section Nghe/Đọc đề thi `no_content` | Có CMS trên DB: `npm run migrate:cms` hoặc thêm bài trong admin |

---

## 8. Đăng nhập `seed.hd.student01@e4c.dev` mà không thấy bài đã làm?

### Hai loại dữ liệu khác nhau

| Loại | Seed | Xem ở đâu trên app |
|---|---|---|
| **Luyện 4 kỹ năng** (nghe/đọc/viết/nói) | `npm run seed:student-app` | **Profile → Lịch sử bài tập** |
| **Bài thi lớp** (exam) | `npm run seed:teacher-hoangdong` | **Lớp học / Bài thi** — **không** nằm trong Lịch sử kỹ năng |

Chỉ chạy `seed:teacher-hoangdong` → có lớp + đề thi, **chưa** có dòng trong Lịch sử kỹ năng.

### Kiểm tra DB (backend)

```bash
cd english_for_community_backend
npm run check:seed-student-data
```

Kỳ vọng: `total: 4` hoặc hơn (Nghe dictation, Nghe hiểu, Đọc, Viết, Nói…).

### Chạy lại seed đúng DB

```bash
npm run seed:student-app
```

Đảm bảo `MONGO_URI` trong `.env` **trùng** DB mà app đang gọi (local vs Atlas).

### Trên app

1. **Profile → Lịch sử bài tập** (không phải màn Bài thi).
2. Bộ lọc ngày: mặc định **30 ngày** (đã chỉnh trong code).
3. Kéo refresh / thoát app mở lại sau khi seed.
