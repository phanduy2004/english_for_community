# Seed dữ liệu analytics (teacher + student) — Runbook

Mục tiêu: lấp **đầy đủ** dữ liệu cho các màn thống kê/phân tích (teacher analytics, student progress, admin) bằng dữ liệu **trông như thật** — tên/email học sinh thật, điểm thật, tín hiệu proctoring thật, trải theo thời gian.

> ⚠️ **DB hiện tại là production/Atlas.** Vì thế mình **KHÔNG chạy tự động** — bạn tự chạy theo runbook này. **Sao lưu trước:** `npm run backup:pre-migrate`.

---

## Đã chuẩn bị sẵn

- **`seedTeacherHoangDongData.js` (đã nâng cấp):** tạo 1 giáo viên + 15 học sinh (tên VN thật, email `@thptchuyene4c.edu.vn`), 3 lớp, nhiều đề tích hợp + bài giao **trải -28 / -14 / -3 ngày** (để biểu đồ trend có dữ liệu), và bài nộp có `scores` đầy đủ (per-skill, finalScore, một số `pending_manual` để có "chờ chấm", vài bài `in_progress`).
  - **Mới bổ sung:** mỗi bài nộp/đang làm giờ có **integrity đầy đủ** (`tabSwitchCount`, `copyPasteAttempts`, `focusLossSeconds`, `fullscreenExited`, `riskLevel`) tương quan theo mức rủi ro → **lấp hết panel chống gian lận** (trước đây chỉ có tab switches).
- **`cleanupDemoSeed.js` (mới):** xoá **đúng** dữ liệu seed (theo email GV + domain HS), **không bao giờ** `deleteMany({})`. Dry-run mặc định.

---

## ⛔ TUYỆT ĐỐI KHÔNG chạy trên prod

Các lệnh sau dùng `deleteMany({})` → **xoá SẠCH mọi lớp/đề/bài giao/bài nộp THẬT**:

- `npm run seed:purge-classroom`
- `npm run seed:reset-classroom`
- `npm run seed:full-demo`  ← (gọi reset-classroom bên trong)
- `node src/seeds/seedTeacherHoangDongData.js --purge`
- đặt biến `SEED_PURGE_CLASSROOM=1`

---

## Chạy seed (an toàn cho prod — KHÔNG purge)

```bash
cd english_for_community_backend

# 0) (khuyến nghị) sao lưu trước
npm run backup:pre-migrate

# 1) seed giáo viên + lớp + đề + bài nộp (feed teacher analytics)
node src/seeds/seedTeacherHoangDongData.js        # KHÔNG có --purge

# 2) seed hoạt động học của học sinh (Home/Progress/History + admin activity)
node src/seeds/seedStudentLearningData.js
```

> **Muốn email GV trông thật hơn:** đặt env trước khi chạy, ví dụ
> `HOANGDONG_TEACHER_EMAIL="dong.hoang@thptchuyene4c.edu.vn" node src/seeds/seedTeacherHoangDongData.js`
> (nếu đổi, phải dùng đúng env đó khi cleanup).

### ⚠️ Idempotency
`seedTeacherHoangDongData.js` **upsert** giáo viên/lớp/học sinh, nhưng **tạo mới** đề/bài giao/bài nộp mỗi lần chạy → **chạy lại nhiều lần sẽ nhân đôi** đề/bài nộp. Muốn seed lại sạch: chạy **cleanup `--confirm`** trước rồi seed lại.

---

## Đăng nhập demo

| Vai trò | Email | Mật khẩu |
|---|---|---|
| Giáo viên | `hoangdong.teacher@e4c.dev` (hoặc env đã đặt) | `Teacher@123456` |
| Học sinh | `<ten>.<ho>@thptchuyene4c.edu.vn` | `Student@123456` |

Đăng nhập GV → sidebar **Schedule & Analytics** để xem thống kê.

---

## Panel analytics được lấp

- **Teacher charts** (`teacherAnalyticsChartsService`, cửa sổ 7–30 ngày): submissions-by-day, score distribution (0–10), skill average (listening/reading/writing/speaking/grammar), **integrity/proctoring** (tab switch / copy-paste / focus loss / fullscreen), at-risk students, hardest items, on-time vs late, pending grading, avg score + trend %.
- **Student progress:** streak/daily progress, per-skill history, vocab (từ `seedStudentLearningData`).
- **Admin:** số user, hoạt động lớp học.

---

## Dọn dữ liệu seed (khi cần)

```bash
# xem trước (không xoá gì)
node src/seeds/cleanupDemoSeed.js
# hoặc: npm run seed:cleanup-demo

# xoá dữ liệu lớp/đề/bài nộp + học tập của học sinh seed (GIỮ tài khoản)
node src/seeds/cleanupDemoSeed.js --confirm

# xoá cả tài khoản GV + HS seed
node src/seeds/cleanupDemoSeed.js --confirm --with-users

# giữ lại dữ liệu học tập của HS (chỉ xoá lớp/đề/bài nộp)
node src/seeds/cleanupDemoSeed.js --confirm --keep-learning
```

Cleanup chỉ khớp theo `HOANGDONG_TEACHER_EMAIL` + domain `thptchuyene4c.edu.vn` (dùng đúng env nếu bạn đã đổi khi seed).
