# Flutter — Cheat sheet lệnh terminal

> Chạy app **bằng terminal** (không cần Android Studio). Copy-paste trực tiếp trên **PowerShell** (Windows).

---

## 0. Thư mục & Flutter SDK

```powershell
# Vào app Flutter (chạy mọi lệnh flutter từ đây)
cd D:\Workspace\english_for_community\english_for_community

# Flutter SDK ổn định trên máy (đặt PATH nếu `flutter` báo lỗi merge conflict)
$env:PATH = "D:\Download\flutter_windows_3.32.1-stable\flutter\bin;" + $env:PATH

flutter --version
flutter doctor -v
```

---

## 1. Thiết bị (devices)

```powershell
flutter devices              # Danh sách thiết bị đang dùng được
flutter emulators            # Emulator có sẵn
flutter emulators --launch <emulator_id>   # Mở emulator

# Bật web (chỉ cần 1 lần / máy mới)
flutter config --enable-web
```

| Device thường thấy | Ý nghĩa |
|--------------------|---------|
| `edge (web)` | Microsoft Edge |
| `chrome (web)` | Google Chrome |
| `windows (desktop)` | App Windows |
| `GM1900` (hoặc tên máy) | Android thật qua USB |
| `sdk gphone64 ...` | Android Emulator |

---

## 2. Chạy app (`flutter run`)

```powershell
cd D:\Workspace\english_for_community\english_for_community

# --- Web (Teacher / Admin console) ---
flutter run -d edge
flutter run -d chrome
flutter run -d edge --web-port=8080
flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8080   # LAN: http://<ip-máy>:8080

# --- Android (Student mobile) ---
flutter run -d GM1900          # thay bằng id từ `flutter devices`
flutter run                    # tự chọn nếu chỉ có 1 device

# --- Windows desktop ---
flutter run -d windows

# --- Release (test hiệu năng) ---
flutter run -d edge --release
flutter run -d GM1900 --release
```

**Chọn device khi có nhiều máy:**

```powershell
flutter run -d <device_id>
# Ví dụ: flutter run -d edge
```

---

## 3. Hot reload / restart (khi `flutter run` đang chạy)

Gõ **trong cùng terminal** đang chạy app — không gõ lệnh shell mới.

| Phím | Tác dụng |
|------|----------|
| **`r`** | Hot reload — nhanh, giữ state |
| **`R`** | Hot restart — chạy lại `main()`, reset state |
| **`q`** | Thoát app / dừng session |
| **`h`** | Help — xem thêm phím |
| **`c`** | Xóa màn hình console |
| **`p`** | Bật/tắt performance overlay |
| **`w`** | In widget tree |
| **`t`** | In render tree |

**Khi nào cần `R` thay vì `r`:** đổi `main()`, init DI, route guard, theme global, native config.

---

## 4. Dependencies & codegen

```powershell
cd D:\Workspace\english_for_community\english_for_community

flutter pub get              # Sau khi đổi pubspec.yaml
flutter pub upgrade            # Nâng dependency (cẩn thận)
flutter gen-l10n               # Sinh lại file localization (sau sửa app_en.arb / app_vi.arb)
dart analyze lib               # Kiểm tra lỗi tĩnh
flutter test                   # Chạy test
```

---

## 5. Build (không cần `run` treo terminal)

```powershell
cd D:\Workspace\english_for_community\english_for_community

# Web
flutter build web
flutter build web --release

# Android APK debug (cài tay lên máy)
flutter build apk --debug
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# Windows
flutter build windows --release
```

APK debug thường nằm ở: `build\app\outputs\flutter-apk\app-debug.apk`

---

## 6. Android / Gradle (khi build Android OOM hoặc daemon crash)

Máy ~13 GB RAM — đã tinh chỉnh `android/gradle.properties`. Nếu vẫn lỗi bộ nhớ:

```powershell
# Dừng daemon Gradle cũ (sau khi sửa gradle.properties)
cd D:\Workspace\english_for_community\english_for_community\android
.\gradlew.bat --stop

# Clean rồi chạy lại
cd D:\Workspace\english_for_community\english_for_community
flutter clean
flutter pub get
flutter run -d GM1900
```

**Trước khi build:** đóng Chrome tab thừa, emulator không dùng — để trống ≥ 3–4 GB RAM.

Build Gradle trực tiếp (không qua flutter):

```powershell
cd D:\Workspace\english_for_community\english_for_community\android
.\gradlew.bat assembleDebug
```

---

## 7. Backend local (API cho app)

Terminal **riêng** — giữ chạy nền:

```powershell
cd D:\Workspace\english_for_community\english_for_community_backend
npm run dev
# → http://localhost:3000
```

App Flutter: bật local API trong `lib/core/api/api_config.dart` (`_useLocal = true`).

Seed / tài khoản test: [`seeds/README.md`](seeds/README.md) · [`seeds/seed-hoangdong-accounts.md`](seeds/seed-hoangdong-accounts.md)

---

## 8. Workflow hàng ngày (gợi ý)

**Teacher web trên Edge:**

```powershell
# Terminal 1 — backend
cd D:\Workspace\english_for_community\english_for_community_backend; npm run dev

# Terminal 2 — Flutter web
cd D:\Workspace\english_for_community\english_for_community
flutter run -d edge
# Sửa code → Save → gõ `r` (hoặc `R` nếu cần)
```

**Student Android:**

```powershell
flutter devices
flutter run -d GM1900
```

---

## 9. Xử lý lỗi thường gặp

| Triệu chứng | Thử |
|-------------|-----|
| `Gradle build daemon disappeared` / OOM | Đóng app nặng, `.\gradlew.bat --stop`, `flutter clean`, chạy lại |
| `Unable to create dart snapshot for flutter tool` / `<<<<<<< HEAD` | Flutter SDK hỏng — sửa `$env:PATH` trỏ SDK sạch (mục 0) |
| `Waiting for another flutter command...` | Xóa file lock: `%LOCALAPPDATA%\Pub\Cache\...\flutter_tools.stamp` hoặc tắt process `dart`/`flutter` cũ |
| Device không thấy (Android) | Bật USB debugging, `adb devices`, cắm lại cáp |
| Web trắng / font lỗi (CDN chặn) | Xem [`flutter-web-local-assets.md`](flutter-web-local-assets.md) |
| Sau đổi `.arb` mà UI vẫn chữ cũ | `flutter gen-l10n` rồi `R` |

---

## 10. Lệnh nhanh copy 1 dòng

```powershell
# Web Edge — dev
cd D:\Workspace\english_for_community\english_for_community; flutter run -d edge

# Android — dev
cd D:\Workspace\english_for_community\english_for_community; flutter run -d GM1900

# Analyze trước commit
cd D:\Workspace\english_for_community\english_for_community; dart analyze lib

# Full clean rebuild
cd D:\Workspace\english_for_community\english_for_community; flutter clean; flutter pub get; flutter run -d edge
```

---

**Liên quan:** [`flutter-coding-structure.md`](flutter-coding-structure.md) · [`flutter-web-local-assets.md`](flutter-web-local-assets.md) · [`../ui-ux-system/`](../ui-ux-system/README.md)
