# Tài khoản demo — Giáo viên Đồ Đàng Hoàng & 15 học sinh

> Dữ liệu lớp học / đề kiểm tra tạo bởi `npm run seed:reset-classroom` (backend).  
> Đặt tên theo quy ước trường THPT — không dùng tiền tố `seed_*` trên UI.

**Reset & seed lại (xóa hết lớp, đề, bài giao, bài nộp):**

```bash
cd english_for_community_backend
npm run seed:listening-comp    # CMS ListeningComprehension (chạy 1 lần nếu chưa có)
npm run seed:reset-classroom   # purge + Hoàng Đông + 5 giáo viên phụ
npm run seed:student-app       # Home, Progress, History (xem seed-student-app-accounts.md)
```

Hoặc một lệnh: `npm run seed:full-demo` (admin + listening-comp + reset-classroom + student-app).

Chỉ xóa dữ liệu lớp (không seed): `npm run seed:purge-classroom`

---

## Quy ước đặt tên


| Loại          | Mẫu                             | Ví dụ                                    |
| ------------- | ------------------------------- | ---------------------------------------- |
| Lớp chủ nhiệm | `{Khối}{Lớp} — Ca sáng · HK2`   | `10A1 — Ca sáng · HK2`                   |
| Lớp nâng cao  | `{Khối} — {Nhóm} · HK2`         | `11B — Nâng cao · HK2`                   |
| KT nhanh      | `KT 15' · Unit {n} — {Kỹ năng}` | `KT 15' · Unit 5 — Nghe chép & Ngữ pháp` |
| Giữa kỳ       | `Giữa HK2 · Đề {n} — {Kỹ năng}` | `Giữa HK2 · Đề 1 — Nghe · Đọc · Viết`    |
| BTVN          | `BTVN · Tuần {n} — {Kỹ năng}`   | `BTVN · Tuần 8 — Writing & Speaking`     |
| Mock          | `Mock lần {n} — {Kỹ năng}`      | `Mock lần 2 — Nghe hiểu MCQ & Đọc`       |


---

## 1. Giáo viên


| Trường    | Giá trị                         |
| --------- | ------------------------------- |
| Họ tên    | Đồ Đàng Hoàng                   |
| Email     | `hoangdong.teacher@e4c.dev`     |
| Username  | `hoangdong_teacher`             |
| Mật khẩu  | Teacher@123456                  |
| Role      | `teacher`                       |
| Đăng nhập | App / Web → khu vực **Teacher** |


---

## 1b. Giáo viên bổ sung (`npm run seed:extra-teachers`)

Mật khẩu chung: `**Teacher@123456`**


| Họ tên           | Email                           | Username           | Lớp mẫu                         |
| ---------------- | ------------------------------- | ------------------ | ------------------------------- |
| Trần Ngọc Lan    | `seed.teacher.trannl@e4c.dev`   | `trannl_teacher`   | Lớp 9/3 — Giao tiếp hàng ngày   |
| Phạm Minh Tuấn   | `seed.teacher.phammt@e4c.dev`   | `phammt_teacher`   | IELTS Foundation — Khóa T5/2026 |
| Lê Thị Hương     | `seed.teacher.lethi@e4c.dev`    | `lethi_huong`      | Lớp 12A1 — Luyện đề THPTQG      |
| Võ Quốc Khánh    | `seed.teacher.voqk@e4c.dev`     | `voqk_teacher`     | English Club — THPT Chuyên      |
| Nguyễn Bích Thảo | `seed.teacher.nguyenbt@e4c.dev` | `nguyenbt_teacher` | Starter English — Khối 6        |


> **Co-teacher demo:** Sau `seed:reset-classroom`, **Lê Thị Hương** được gắn sẵn làm GV phụ lớp **10A1 — Ca sáng · HK2** của Hoàng Đông.

---

## 2. Lớp học (của giáo viên trên)


| Tên lớp                | Ghi chú                             |
| ---------------------- | ----------------------------------- |
| `10A1 — Ca sáng · HK2` | 12 học sinh — lớp chủ nhiệm khối 10 |
| `11B — Nâng cao · HK2` | 12 học sinh (9 em học cả 2 lớp)     |


> Mã mời (invite) sinh ngẫu nhiên mỗi lần seed — xem dòng `invite:` / `code` trong log console.

---

## 3. Học sinh (15 tài khoản)

Mật khẩu chung: `**Student@123456`** — email domain `@thptchuyene4c.edu.vn`

> ⚠️ Tài khoản cũ `seed.hd.student01@e4c.dev` … bị xóa khi chạy `seed:reset-classroom`.


| STT | Họ tên         | Email                                | Username        |
| --- | -------------- | ------------------------------------ | --------------- |
| 1   | Nguyễn Minh An | `minhan.nguyen@thptchuyene4c.edu.vn` | `minhan.nguyen` |
| 2   | Trần Thu Hà    | `thuha.tran@thptchuyene4c.edu.vn`    | `thuha.tran`    |
| 3   | Lê Quốc Bảo    | `quocbao.le@thptchuyene4c.edu.vn`    | `quocbao.le`    |
| 4   | Phạm Ngọc Linh | `ngoclinh.pham@thptchuyene4c.edu.vn` | `ngoclinh.pham` |
| 5   | Hoàng Văn Đức  | `vanduc.hoang@thptchuyene4c.edu.vn`  | `vanduc.hoang`  |
| 6   | Vũ Thị Mai     | `thimai.vu@thptchuyene4c.edu.vn`     | `thimai.vu`     |
| 7   | Đặng Hữu Phúc  | `huuphuc.dang@thptchuyene4c.edu.vn`  | `huuphuc.dang`  |
| 8   | Bùi Thảo My    | `thaomy.bui@thptchuyene4c.edu.vn`    | `thaomy.bui`    |
| 9   | Ngô Kiên Cường | `kiencuong.ngo@thptchuyene4c.edu.vn` | `kiencuong.ngo` |
| 10  | Dương Lan Chi  | `lanchi.duong@thptchuyene4c.edu.vn`  | `lanchi.duong`  |
| 11  | Lý Gia Hân     | `gihan.ly@thptchuyene4c.edu.vn`      | `gihan.ly`      |
| 12  | Mai Hoàng Nam  | `hoangnam.mai@thptchuyene4c.edu.vn`  | `hoangnam.mai`  |
| 13  | Tôn Nhật Minh  | `nhatminh.ton@thptchuyene4c.edu.vn`  | `nhatminh.ton`  |
| 14  | Chu Bảo Trân   | `baotran.chu@thptchuyene4c.edu.vn`   | `baotran.chu`   |
| 15  | Phan Đức Anh   | `ducanh.phan@thptchuyene4c.edu.vn`   | `ducanh.phan`   |


---

## 4. Đề kiểm tra (mẫu tên)


| Đề                                        | Kỹ năng                       |
| ----------------------------------------- | ----------------------------- |
| KT 15' · Unit 5 — Nghe chép & Ngữ pháp    | Nghe, Đọc, Grammar            |
| BTVN · Tuần 8 — Writing & Speaking        | Viết, Nói                     |
| Giữa HK2 · Đề 1 — Nghe · Đọc · Viết       | Nghe, Đọc, Viết, Grammar      |
| Ôn cuối tuần · Tuần 6 — Reading & Summary | Đọc, Viết                     |
| Ôn cuối tuần · Tuần 9 — 4 kỹ năng         | Nghe, Đọc, Viết, Nói, Grammar |
| Mock lần 2 — Nghe hiểu MCQ & Đọc          | Nghe (comprehension), Đọc     |


Mỗi đề có 2–3 **bài giao** theo lịch (đã đóng / vừa nộp / đang mở / sắp mở) + bài nộp đa dạng trạng thái chấm.

> **Listening Comprehension:** chạy `npm run seed:listening-comp` trước reset nếu DB chưa có CMS nghe hiểu.

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


| Sai                             | Đúng                                                |
| ------------------------------- | --------------------------------------------------- |
| Cluster khác                    | Cluster trong URI (`e4c.yoqkkww...`)                |
| Database `test` / `admin`       | `**english_community`** (tên trong `MONGO_URI`)     |
| Collection `Users` (PascalCase) | `**users`** (chữ thường, Mongoose)                  |
| Filter trống / project khác     | Collection `users` → filter `{ email: /seed\.hd/ }` |


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


| Thành phần    | Giá trị                                                |
| ------------- | ------------------------------------------------------ |
| Cluster Atlas | `e4c.yoqkkww.mongodb.net`                              |
| Tên database  | `english_community`                                    |
| Biến env      | `MONGO_URI` trong `english_for_community_backend/.env` |


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

1. **Lỗi `querySrv ECONNREFUSED`**: đổi **một dòng** `MONGO_URI` sang chuỗi **Standard** từ Atlas (Connect → Drivers), không dùng biến env thứ hai.
2. **Backend + app cùng Atlas**: `npm run dev` phải in kết nối Mongo OK; Flutter `api_config.dart` `_useLocal = true` và IP LAN trỏ máy chạy `npm run dev` (không gọi Render nếu chỉ seed trên Atlas từ máy local).
3. **Bảo mật**: không gửi password Atlas trong chat/issue — nếu lộ, đổi password user DB trên Atlas.

### 7.3 App không đăng nhập được dù seed OK

`check:seed-login` ✅ chỉ chứng minh **MongoDB + mật khẩu** đúng. App Flutter còn phải gọi **đúng API**:


| Chạy app trên           | `api_config.dart` cần                                                                          |
| ----------------------- | ---------------------------------------------------------------------------------------------- |
| Chrome / Web            | `_useLocal = true` → `http://localhost:3000/`                                                  |
| Android emulator        | `_useLocal = true` → tự `10.0.2.2:3000`                                                        |
| Điện thoại thật (Wi‑Fi) | `_useLocal = true` → `_localLanIp` = IP máy chạy `npm run dev` (`ipconfig`, vd. `192.168.x.x`) |
| APK test server online  | `_useLocal = false` → Render — **phải seed cùng DB Render dùng**                               |


**Đăng nhập** (ô *Email hoặc tên đăng nhập*):


| Cách                    | Ví dụ STT 4                 |
| ----------------------- | --------------------------- |
| **Email** (khuyến nghị) | `seed.hd.student04@e4c.dev` |
| Username                | `seed_hd_s04`               |


**Mật khẩu chung (tất cả 15 HS):** `Student@123456` (chữ **S** viết hoa, có `@`).

**Không** dùng `seed_hd` một mình — phải đủ `seed_hd_s04` hoặc đủ email.

**Đăng xuất hết** trước khi thử (tránh session user cũ — socket `User Login: 6a102f1f...` có thể **không** phải học sinh seed; student01 trên Atlas có id dạng `6a0f4dac...`).

Khi mở app debug, xem console: `[ApiConfig] ...` và URL phải trỏ `localhost:3000` hoặc IP LAN đúng.

### 7.1 Nguyên nhân hay gặp nhất: **sai database**

Chỉ có **một** biến DB: `MONGO_URI` trong `english_for_community_backend/.env`.  
Server (`npm run dev`), seed, repair — tất cả kết nối đúng URI đó. App phải gọi backend đang dùng cùng `.env`.


| Bạn làm                                  | App kết nối                                                                                | Kết quả                                                             |
| ---------------------------------------- | ------------------------------------------------------------------------------------------ | ------------------------------------------------------------------- |
| Seed lên **Atlas** (`mongodb+srv://...`) | Flutter `_useLocal = true` → `192.168.x.x:3000` nhưng máy local `.env` trỏ **local Mongo** | ❌ Tài khoản không tồn tại trên DB local → `400 Invalid credentials` |
| Seed lên **local**                       | App gọi **Render** (`_useLocal = false`)                                                   | ❌ Atlas không có user seed                                          |


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


| Triệu chứng             | Nguyên nhân                           | Cách xử lý                                                     |
| ----------------------- | ------------------------------------- | -------------------------------------------------------------- |
| 500 / `isVerified`      | Bug login cũ (đã sửa `authService`)   | Restart backend                                                |
| 400 Invalid credentials | Sai email, sai DB, hoặc mật khẩu cũ   | `seed.hd.student01@e4c.dev` + `Student@123456` (chữ **S** hoa) |
| 403 verify email        | `isVerified: false`                   | `npm run repair:seed-logins`                                   |
| 400 Google sign-in      | Đăng ký Google trước, không có bcrypt | `repair:seed-logins` + seed lại ghi đè mật khẩu seed           |


```bash
cd english_for_community_backend
npm run repair:seed-logins        # ⭐ isVerified + mật khẩu + bỏ _destroy + chuẩn email
npm run seed:teacher-hoangdong   # tạo/cập nhật 15 HS + GV HoangDong
npm run check:seed-login         # kiểm tra nhanh trên đúng MONGO_URI
```

**Lỗi thường gặp khi “đúng mật khẩu” mà vẫn không vào:**


| HTTP / message            | Nguyên nhân                                                         |
| ------------------------- | ------------------------------------------------------------------- |
| `403` verify email        | `isVerified: false` trong DB → chạy `npm run repair:seed-logins`    |
| `400` Invalid credentials | Sai email (HoangDong ≠ `user2@gmail.com`) hoặc mật khẩu cũ trong DB |
| `400` Google sign-in      | Tài khoản tạo bằng Google, không đăng nhập password                 |
| `500` isVerified null     | Backend cũ — đã sửa, **restart** `npm run dev`                      |


---

*Cập nhật theo `src/seeds/seedTeacherHoangDongData.js`.*