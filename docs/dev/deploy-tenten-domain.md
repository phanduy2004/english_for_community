# Triển khai tên miền Tenten + Web E4C (miễn phí)

> **Mục tiêu:** Người dùng truy cập `https://tenmien-cua-ban.vn` → thấy app Flutter Web.  
> **Backend:** vẫn dùng Render (không cần VPS).  
> **Chi phí thêm:** chỉ phí gia hạn tên miền Tenten (~200–400k/năm).

---

## Kiến trúc (giữ nguyên, không tự host)

| Thành phần | URL | Ai quản lý |
|------------|-----|------------|
| Web Flutter | `https://tenmien-cua-ban.vn` | Firebase Hosting |
| API + Socket | `https://english-for-community.onrender.com` | Render (free) |
| Database | MongoDB Atlas | Atlas (free) |
| File upload | Cloudinary | Cloudinary (free tier) |

Web deploy **tự động** khi merge code vào nhánh `main` (GitHub Actions: `.github/workflows/firebase-hosting-merge.yml`).

---

## Phần A — Bạn làm trên Firebase (15 phút)

### A1. Thêm custom domain

1. Mở [Firebase Console](https://console.firebase.google.com/) → project **`english4community-4c654`**
2. Menu trái → **Hosting** → **Add custom domain**
3. Nhập tên miền (vd. `englishforcommunity.vn`)
4. Chọn redirect `www` ↔ gốc (khuyên: **www → domain gốc** hoặc ngược lại, chọn một làm chính)
5. Firebase hiện **danh sách bản ghi DNS** — **copy nguyên**, đừng tự đoán IP

Thường gồm:

- **TXT** — xác minh sở hữu
- **A** và/hoặc **AAAA** — nếu trỏ domain gốc (`@`)
- **CNAME** — nếu dùng `www` (trỏ về `english4community-4c654.web.app` hoặc host Firebase chỉ định)

6. Chờ trạng thái **Connected** + **SSL provisioning** (vài phút → 48 giờ)

URL mặc định hiện tại (vẫn chạy song song):  
`https://english4community-4c654.web.app`

### A2. Authorized domains (bắt buộc — đăng nhập web)

1. Firebase → **Authentication** → **Settings** → **Authorized domains**
2. **Add domain** → thêm:
   - `tenmien-cua-ban.vn`
   - `www.tenmien-cua-ban.vn` (nếu dùng www)

Thiếu bước này → đăng nhập email/Google trên web có thể báo lỗi `auth/unauthorized-domain`.

### A3. Google Sign-In trên web (nếu dùng nút Google)

1. [Google Cloud Console](https://console.cloud.google.com/) → project liên kết Firebase
2. **APIs & Services** → **Credentials** → OAuth 2.0 Client (Web)
3. **Authorized JavaScript origins** → thêm:
   - `https://tenmien-cua-ban.vn`
   - `https://www.tenmien-cua-ban.vn`
4. Lưu — không cần đổi redirect URI nếu chỉ dùng Firebase Auth popup

---

## Phần B — Bạn làm trên Tenten (10 phút)

1. Đăng nhập [Tenten — quản lý domain](https://id.tenten.vn/list-domain)
2. Chọn tên miền → **Quản lý DNS** / **Bản ghi DNS**
3. Thêm **đúng** các bản ghi Firebase đưa ở bước A1 (TXT, A, CNAME…)
4. **Không xóa** bản ghi email/MX cũ nếu sau này dùng mail `@tenmien`
5. Lưu → kiểm tra propagate: [dnschecker.org](https://dnschecker.org)

**Lưu ý:** Mỗi domain Firebase chỉ định giá trị khác nhau — luôn copy từ Firebase Console, không dùng IP ví dụ trên mạng.

---

## Phần C — Trong repo (dev / CI)

### C1. Deploy web (tự động)

Push merge vào `main` → GitHub Actions:

```text
flutter build web --release
→ Firebase Hosting (project english4community-4c654)
```

Không cần cấu hình thêm trên Tenten cho mỗi lần deploy code.

### C2. Deploy web thủ công (khi cần)

```bash
cd english_for_community
flutter pub get
flutter build web --release
firebase deploy --only hosting --project english4community-4c654
```

(Cần cài Firebase CLI + `firebase login` một lần.)

### C3. Backend

**Không đổi** nếu vẫn dùng Render free. App release đã trỏ API:

```dart
// lib/core/api/api_config.dart
static const String _renderUrl = "https://english-for-community.onrender.com";
```

Chỉ khi sau này có subdomain API riêng (`api.tenmien.vn` trên Render) mới sửa dòng trên.

### C4. Kiểm tra sau khi domain xanh

- [ ] `https://tenmien-cua-ban.vn` mở được, có ổ khóa HTTPS
- [ ] Đăng nhập email + Google (web)
- [ ] Chat lớp / thông báo realtime (Socket.IO qua Render)
- [ ] Upload ảnh trong chat

---

## Phần D — Android APK (đã có CI)

Workflow `Main Auto Build Candidate` build APK khi push `main` (thư mục `lib/`, `android/`, `pubspec.yaml`).

APK tải từ GitHub Releases — **không** gắn tên miền Tenten (CH Play / sideload riêng).

---

## Checklist nhanh

| # | Việc | Ai làm |
|---|------|--------|
| 1 | Firebase Hosting → Add custom domain | **Bạn** |
| 2 | Tenten → thêm DNS theo Firebase | **Bạn** |
| 3 | Firebase Auth → Authorized domains | **Bạn** |
| 4 | Google Cloud → OAuth origins (nếu Google login) | **Bạn** |
| 5 | Merge code `main` → auto deploy web | **CI** |
| 6 | Sửa `ApiConfig` | **Không cần** (giữ Render) |

---

## Gửi dev khi cần hỗ trợ thêm

Ghi rõ:

1. Tên miền chính xác (vd. `example.vn`)
2. Dùng `www` hay không
3. Screenshot trang DNS Tenten + Firebase Hosting (trạng thái domain)
4. Lỗi cụ thể (nếu có) khi mở web / đăng nhập

---

## FAQ

**Có cần VPS Tenten không?**  
Không. Chỉ DNS trỏ về Firebase.

**Backend có chậm không?**  
Render free có thể “ngủ” ~15 phút không ai gọi → request đầu chậm vài giây. Chấp nhận được cho demo/lớp học.

**Tên miền chưa xong SSL?**  
Chờ DNS propagate; Firebase tự cấp certificate Let's Encrypt.
