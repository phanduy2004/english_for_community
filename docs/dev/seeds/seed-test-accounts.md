# Tài khoản test — Admin & user demo

> Tạo/cập nhật bằng: `npm run seed:admin` (trong `english_for_community_backend`).  
> Sửa login lỗi: `npm run repair:seed-logins`

---

## Admin (vào **Admin console**)

| Họ tên | Email | Mật khẩu | Username | Role |
|--------|-------|----------|----------|------|
| Super Admin | `admin@englishapp.com` | `adminpassword123` | `admin` | `admin` |
| Test Admin | **`testuser@example.com`** | **`Test@1234`** | `testuser_admin` | `admin` |
| Test Admin (email cũ) | `test@example.com` | `Test@1234` | `test_admin` | `admin` |

Sau đăng nhập, app redirect tới **`/admin`** (không phải Home học sinh).

> ⚠️ **`testuser@example.com` không có sẵn trong DB** cho đến khi bạn chạy `npm run seed:admin` hoặc `npm run repair:seed-logins`. Trước đó login sẽ báo `Invalid credentials`.

---

## User demo (`seedAdmin.js` — role `user`)

Mật khẩu chung: **`123456`**

| Email |
|-------|
| `user1@gmail.com` … `user8@gmail.com` |

---

## Không nhầm với

| Email | Ghi chú |
|-------|---------|
| `seed.hd.student01@e4c.dev` | Học sinh HoangDong — MK `Student@123456` — xem `seed-hoangdong-accounts.md` |
| `hoangdong.teacher@e4c.dev` | Giáo viên — MK `Teacher@123456` |

---

## `npm run seed` (userSeeder.js) — **lỗi thời**

Script `seed` cũ dùng field không tồn tại (`emailVerified`, `isActive`) và MK `Test@123` — **không dùng**. Dùng `seed:admin` thay thế.
