# Tài khoản seed — Giáo viên Đồ Đàng Hoàng & 15 học sinh

> Dữ liệu tạo bởi `npm run seed:teacher-hoangdong` (backend).  
> Dùng để test **Schedule**, **Analytics**, giao bài, chấm điểm.

**Chạy lại seed:**

```bash
cd english_for_community_backend
npm run seed:teacher-hoangdong
npm run seed:student-app    # Home, Progress, History + Admin activity (xem seed-student-app-accounts.md)
```

Hoặc một lệnh: `npm run seed:full-demo` (admin + hoangdong + student-app).

---

## 1. Giáo viên


| Trường    | Giá trị                         |
| --------- | ------------------------------- |
| Họ tên    | Đồ Đàng Hoàng                   |
| Email     | `hoangdong.teacher@e4c.dev`     |
| Username  | `hoangdong_teacher`             |
| Mật khẩu  | `Teacher@123456`                |
| Role      | `teacher`                       |
| Đăng nhập | App / Web → khu vực **Teacher** |


---

## 2. Lớp học (của giáo viên trên)


| Tên lớp                               | Mã mời (invite) | Ghi chú                                                    |
| ------------------------------------- | --------------- | ---------------------------------------------------------- |
| `[SEED:HoangDong] Lớp 10A — Sáng`     | `KH4EZS`        | Lần seed gần nhất (Atlas) — xem log `invite:` nếu seed lại |
| `[SEED:HoangDong] Lớp 11B — Nâng cao` | `2H4ZNH`        | Học sinh seed đã được ghi danh sẵn cả 2 lớp                |


> Nếu xóa lớp trong DB rồi seed lại, **mã mời có thể đổi** — xem dòng `invite:` trong log console khi chạy seed.

---

## 3. Học sinh (15 tài khoản)

**Mật khẩu chung:** `Student@123456` (có chữ **S** viết hoa và `@`)  
**Role:** `user` · **Đăng nhập:** đúng **email cột bảng** (không dùng Gmail `user2@gmail.com` — đó là bộ seed khác)

> ⚠️ **Không nhầm với `seedAdmin.js`:** `user1@gmail.com` … `user8@gmail.com` / mật khẩu `123456` là user demo cũ, **không** map với `seed.hd.student01@e4c.dev`.


| STT | Họ tên         | Email                       | Username      |
| --- | -------------- | --------------------------- | ------------- |
| 1   | Nguyễn Minh An | `seed.hd.student01@e4c.dev` | `seed_hd_s01` |
| 2   | Trần Thu Hà    | `seed.hd.student02@e4c.dev` | `seed_hd_s02` |
| 3   | Lê Quốc Bảo    | `seed.hd.student03@e4c.dev` | `seed_hd_s03` |
| 4   | Phạm Ngọc Linh | `seed.hd.student04@e4c.dev` | `seed_hd_s04` |
| 5   | Hoàng Văn Đức  | `seed.hd.student05@e4c.dev` | `seed_hd_s05` |
| 6   | Vũ Thị Mai     | `seed.hd.student06@e4c.dev` | `seed_hd_s06` |
| 7   | Đặng Hữu Phúc  | `seed.hd.student07@e4c.dev` | `seed_hd_s07` |
| 8   | Bùi Thảo My    | `seed.hd.student08@e4c.dev` | `seed_hd_s08` |
| 9   | Ngô Kiên Cường | `seed.hd.student09@e4c.dev` | `seed_hd_s09` |
| 10  | Dương Lan Chi  | `seed.hd.student10@e4c.dev` | `seed_hd_s10` |
| 11  | Lý Gia Hân     | `seed.hd.student11@e4c.dev` | `seed_hd_s11` |
| 12  | Mai Hoàng Nam  | `seed.hd.student12@e4c.dev` | `seed_hd_s12` |
| 13  | Tôn Nhật Minh  | `seed.hd.student13@e4c.dev` | `seed_hd_s13` |
| 14  | Chu Bảo Trân   | `seed.hd.student14@e4c.dev` | `seed_hd_s14` |
| 15  | Phan Đức Anh   | `seed.hd.student15@e4c.dev` | `seed_hd_s15` |


---

## 4. Đề kiểm tra seed (tham khảo)

Tất cả đề có tiền tố `[SEED:HoangDong]` trong tiêu đề:


| Đề                                   | Kỹ năng                       |
| ------------------------------------ | ----------------------------- |
| Kiểm tra Nghe + Đọc + Ngữ pháp       | Nghe, Đọc, Grammar            |
| Luyện Viết + Nói                     | Viết, Nói                     |
| Giữa kỳ — Nghe Đọc Viết + Grammar    | Nghe, Đọc, Viết, Grammar      |
| Đọc hiểu + Viết tóm tắt              | Đọc, Viết                     |
| Ôn tập 4 kỹ năng (Nghe Đọc Viết Nói) | Nghe, Đọc, Viết, Nói, Grammar |


Kèm **15 bài giao** và **151 bài nộp + 9 đang làm** (một phần chờ chấm) để xem **Lịch** & **Phân tích**.

> **CMS:** Nếu log có `No Listening/Reading in DB`, các section Nghe/Đọc trên đề seed là `no_content` cho đến khi admin thêm bài CMS trên cùng DB (Atlas).

---

## 5. Chuyển bài CMS (Nghe / Đọc / Nói / Viết) từ DB local sang Atlas

Khi seed báo `No Listening/Reading in DB`, cần copy **nội dung admin** từ MongoDB cũ (local) sang DB mới (Atlas).

**Cách 1 — script trong repo (khuyến nghị):**

```bash
cd english_for_community_backend
# .env: MONGO_URI = Atlas (đích), thêm dòng nguồn:
# MONGO_URI_SOURCE=mongodb://localhost:27017/english_community
npm run migrate:cms
```

Script: `src/scripts/migrateCmsContent.js` — upsert theo `_id`, không đụng users/attempts/exams.

**Cách 2 — MongoDB Compass:** Export collection JSON từ local → Import vào Atlas (cùng tên DB `english_community`).

**Cách 3 — mongodump / mongorestore** (chỉ vài collection CMS):

```bash
mongodump --uri="mongodb://localhost:27017/english_community" --collection=listenings --collection=readings --collection=speakingsets --collection=listeningcomprehensions --collection=writing_topics --out=./dump-cms
mongorestore --uri="mongodb+srv://USER:PASS@cluster/english_community" --nsInclude="english_community.*" ./dump-cms
```

Sau khi có CMS trên Atlas, chạy lại `npm run seed:teacher-hoangdong` nếu muốn đề seed gắn đúng bài Nghe/Đọc.

---

## 6. Biến môi trường (tùy chọn)

Có thể ghi trong `english_for_community_backend/.env`:


| Biến                         | Mặc định                    |
| ---------------------------- | --------------------------- |
| `HOANGDONG_TEACHER_EMAIL`    | `hoangdong.teacher@e4c.dev` |
| `HOANGDONG_TEACHER_PASSWORD` | `Teacher@123456`            |
| `HOANGDONG_TEACHER_USERNAME` | `hoangdong_teacher`         |


---

## 7. Khắc phục không đăng nhập được

### Seed có vào Atlas không?

**Có** — nếu log seed/dev giống:

```text
Connected to MongoDB (e4c.yoqkkww.mongodb.net/english_community)
```

Seed **không** ghi vào Mongo cài trên máy trừ khi bạn đổi `MONGO_URI` sang `mongodb://127.0.0.1/...`.

**Không thấy data trên Atlas UI?** Thường do mở sai chỗ:

| Sai | Đúng |
|-----|------|
| Cluster khác | Cluster trong URI (`e4c.yoqkkww...`) |
| Database `test` / `admin` | **`english_community`** (tên trong `MONGO_URI`) |
| Collection `Users` (PascalCase) | **`users`** (chữ thường, Mongoose) |
| Filter trống / project khác | Collection `users` → filter `{ email: /seed\.hd/ }` |

Chạy trên máy (cùng `.env`):

```bash
cd english_for_community_backend
npm run db:inspect
```

In ra số học sinh / lớp / đề trên **đúng DB mà `MONGO_URI` trỏ tới**. Nếu `15` học sinh → data **đã** trên Atlas; Compass chỉ cần chọn đúng database.

### Seed vào database nào?

Log khi chạy seed / `npm run dev` (cùng một dòng):

```text
Connected to MongoDB (e4c.yoqkkww.mongodb.net/english_community)
```

| Thành phần | Giá trị |
|------------|---------|
| Cluster Atlas | `e4c.yoqkkww.mongodb.net` |
| Tên database | `english_community` |
| Biến env | `MONGO_URI` trong `english_for_community_backend/.env` |

**Không** seed vào Mongo local trừ khi bạn đổi `MONGO_URI` sang `mongodb://127.0.0.1/...`.

Kiểm tra mật khẩu trên **cùng DB đó** (backend đang chạy):

```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" -Method POST -ContentType "application/json" -Body '{"email":"seed.hd.student01@e4c.dev","password":"Student@123456"}'
```

Nếu lệnh trên trả về `accessToken` + `user.email` = `seed.hd.student01@e4c.dev` → DB + backend **OK**; lỗi nằm ở **app không gọi đúng URL** (xem §7.3).

### 7.0 Atlas (`mongodb+srv://...`) — checklist

1. **Network Access** (Atlas → Network Access): thêm IP máy bạn hoặc `0.0.0.0/0` (chỉ dev).
2. **Database user** có quyền read/write DB `english_community`.
3. Trên máy Windows, chạy lần lượt trong PowerShell:

```powershell
cd english_for_community_backend
npm run seed:teacher-hoangdong
npm run repair:seed-logins
npm run check:seed-login
```

Kỳ vọng `check:seed-login`: 3 dòng `✅ OK` (teacher + student01 + student15).

4. **Lỗi `querySrv ECONNREFUSED`**: đổi **một dòng** `MONGO_URI` sang chuỗi **Standard** từ Atlas (Connect → Drivers), không dùng biến env thứ hai.

5. **Backend + app cùng Atlas**: `npm run dev` phải in kết nối Mongo OK; Flutter `api_config.dart` `_useLocal = true` và IP LAN trỏ máy chạy `npm run dev` (không gọi Render nếu chỉ seed trên Atlas từ máy local).

6. **Bảo mật**: không gửi password Atlas trong chat/issue — nếu lộ, đổi password user DB trên Atlas.

### 7.3 App không đăng nhập được dù seed OK

`check:seed-login` ✅ chỉ chứng minh **MongoDB + mật khẩu** đúng. App Flutter còn phải gọi **đúng API**:

| Chạy app trên | `api_config.dart` cần |
|---------------|------------------------|
| Chrome / Web | `_useLocal = true` → `http://localhost:3000/` |
| Android emulator | `_useLocal = true` → tự `10.0.2.2:3000` |
| Điện thoại thật (Wi‑Fi) | `_useLocal = true` → `_localLanIp` = IP máy chạy `npm run dev` (`ipconfig`, vd. `192.168.x.x`) |
| APK test server online | `_useLocal = false` → Render — **phải seed cùng DB Render dùng** |

**Đăng nhập** (ô *Email hoặc tên đăng nhập*):

| Cách | Ví dụ STT 4 |
|------|----------------|
| **Email** (khuyến nghị) | `seed.hd.student04@e4c.dev` |
| Username | `seed_hd_s04` |

**Mật khẩu chung (tất cả 15 HS):** `Student@123456` (chữ **S** viết hoa, có `@`).

**Không** dùng `seed_hd` một mình — phải đủ `seed_hd_s04` hoặc đủ email.

**Đăng xuất hết** trước khi thử (tránh session user cũ — socket `User Login: 6a102f1f...` có thể **không** phải học sinh seed; student01 trên Atlas có id dạng `6a0f4dac...`).

Khi mở app debug, xem console: `[ApiConfig] ...` và URL phải trỏ `localhost:3000` hoặc IP LAN đúng.

### 7.1 Nguyên nhân hay gặp nhất: **sai database**

Chỉ có **một** biến DB: `MONGO_URI` trong `english_for_community_backend/.env`.  
Server (`npm run dev`), seed, repair — tất cả kết nối đúng URI đó. App phải gọi backend đang dùng cùng `.env`.

| Bạn làm | App kết nối | Kết quả |
|---------|-------------|---------|
| Seed lên **Atlas** (`mongodb+srv://...`) | Flutter `_useLocal = true` → `192.168.x.x:3000` nhưng máy local `.env` trỏ **local Mongo** | ❌ Tài khoản không tồn tại trên DB local → `400 Invalid credentials` |
| Seed lên **local** | App gọi **Render** (`_useLocal = false`) | ❌ Atlas không có user seed |

**Cách xử lý:**

1. Một DB duy nhất: đặt `MONGO_URI` (Atlas hoặc local) trong `.env`.
2. `npm run dev` — backend dùng đúng `.env` đó.
3. Flutter `lib/core/api/api_config.dart`: `_useLocal = true` và IP LAN đúng máy chạy backend (hoặc `_useLocal = false` nếu test Render **và** đã seed lên Atlas trên Render).
4. Chạy lại:

```bash
cd english_for_community_backend
npm run seed:teacher-hoangdong
npm run repair:seed-logins
npm run check:seed-login    # xem từng email: OK / NOT IN DATABASE / password mismatch
```

### 7.2 Các lỗi khác


| Triệu chứng             | Nguyên nhân                         | Cách xử lý                                          |
| ----------------------- | ----------------------------------- | --------------------------------------------------- |
| 500 / `isVerified`      | Bug login cũ (đã sửa `authService`) | Restart backend                                     |
| 400 Invalid credentials | Sai email, sai DB, hoặc mật khẩu cũ | `seed.hd.student01@e4c.dev` + `Student@123456` (chữ **S** hoa) |
| 403 verify email        | `isVerified: false`                 | `npm run repair:seed-logins`                          |
| 400 Google sign-in      | Đăng ký Google trước, không có bcrypt | `repair:seed-logins` + seed lại ghi đè mật khẩu seed |

```bash
cd english_for_community_backend
npm run repair:seed-logins        # ⭐ isVerified + mật khẩu + bỏ _destroy + chuẩn email
npm run seed:teacher-hoangdong   # tạo/cập nhật 15 HS + GV HoangDong
npm run check:seed-login         # kiểm tra nhanh trên đúng MONGO_URI
```

**Lỗi thường gặp khi “đúng mật khẩu” mà vẫn không vào:**

| HTTP / message | Nguyên nhân |
|----------------|-------------|
| `403` verify email | `isVerified: false` trong DB → chạy `npm run repair:seed-logins` |
| `400` Invalid credentials | Sai email (HoangDong ≠ `user2@gmail.com`) hoặc mật khẩu cũ trong DB |
| `400` Google sign-in | Tài khoản tạo bằng Google, không đăng nhập password |
| `500` isVerified null | Backend cũ — đã sửa, **restart** `npm run dev` |

---

*Cập nhật theo `src/seeds/seedTeacherHoangDongData.js`.*