# Tài khoản seed — Giáo viên Đồ Đàng Hoàng & 15 học sinh

> Dữ liệu tạo bởi `npm run seed:teacher-hoangdong` (backend).  
> Dùng để test **Schedule**, **Analytics**, giao bài, chấm điểm.

**Chạy lại seed:**

```bash
cd english_for_community_backend
npm run seed:teacher-hoangdong
```

---

## 1. Giáo viên

| Trường | Giá trị |
|--------|---------|
| Họ tên | Đồ Đàng Hoàng |
| Email | `hoangdong.teacher@e4c.dev` |
| Username | `hoangdong_teacher` |
| Mật khẩu | `Teacher@123456` |
| Role | `teacher` |
| Đăng nhập | App / Web → khu vực **Teacher** |

---

## 2. Lớp học (của giáo viên trên)

| Tên lớp | Mã mời (invite) | Ghi chú |
|---------|----------------|---------|
| `[SEED:HoangDong] Lớp 10A — Sáng` | `KH4EZS` | Lần seed gần nhất (Atlas) — xem log `invite:` nếu seed lại |
| `[SEED:HoangDong] Lớp 11B — Nâng cao` | `2H4ZNH` | Học sinh seed đã được ghi danh sẵn cả 2 lớp |

> Nếu xóa lớp trong DB rồi seed lại, **mã mời có thể đổi** — xem dòng `invite:` trong log console khi chạy seed.

---

## 3. Học sinh (15 tài khoản)

**Mật khẩu chung:** `Student@123456`  
**Role:** `user` · **Đăng nhập:** email + mật khẩu

| STT | Họ tên | Email | Username |
|-----|--------|-------|----------|
| 1 | Nguyễn Minh An | `seed.hd.student01@e4c.dev` | `seed_hd_s01` |
| 2 | Trần Thu Hà | `seed.hd.student02@e4c.dev` | `seed_hd_s02` |
| 3 | Lê Quốc Bảo | `seed.hd.student03@e4c.dev` | `seed_hd_s03` |
| 4 | Phạm Ngọc Linh | `seed.hd.student04@e4c.dev` | `seed_hd_s04` |
| 5 | Hoàng Văn Đức | `seed.hd.student05@e4c.dev` | `seed_hd_s05` |
| 6 | Vũ Thị Mai | `seed.hd.student06@e4c.dev` | `seed_hd_s06` |
| 7 | Đặng Hữu Phúc | `seed.hd.student07@e4c.dev` | `seed_hd_s07` |
| 8 | Bùi Thảo My | `seed.hd.student08@e4c.dev` | `seed_hd_s08` |
| 9 | Ngô Kiên Cường | `seed.hd.student09@e4c.dev` | `seed_hd_s09` |
| 10 | Dương Lan Chi | `seed.hd.student10@e4c.dev` | `seed_hd_s10` |
| 11 | Lý Gia Hân | `seed.hd.student11@e4c.dev` | `seed_hd_s11` |
| 12 | Mai Hoàng Nam | `seed.hd.student12@e4c.dev` | `seed_hd_s12` |
| 13 | Tôn Nhật Minh | `seed.hd.student13@e4c.dev` | `seed_hd_s13` |
| 14 | Chu Bảo Trân | `seed.hd.student14@e4c.dev` | `seed_hd_s14` |
| 15 | Phan Đức Anh | `seed.hd.student15@e4c.dev` | `seed_hd_s15` |

---

## 4. Đề kiểm tra seed (tham khảo)

Tất cả đề có tiền tố `[SEED:HoangDong]` trong tiêu đề:

| Đề | Kỹ năng |
|----|---------|
| Kiểm tra Nghe + Đọc + Ngữ pháp | Nghe, Đọc, Grammar |
| Luyện Viết + Nói | Viết, Nói |
| Giữa kỳ — Nghe Đọc Viết + Grammar | Nghe, Đọc, Viết, Grammar |
| Đọc hiểu + Viết tóm tắt | Đọc, Viết |
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

| Biến | Mặc định |
|------|----------|
| `HOANGDONG_TEACHER_EMAIL` | `hoangdong.teacher@e4c.dev` |
| `HOANGDONG_TEACHER_PASSWORD` | `Teacher@123456` |
| `HOANGDONG_TEACHER_USERNAME` | `hoangdong_teacher` |

---

*Cập nhật theo `src/seeds/seedTeacherHoangDongData.js`.*
