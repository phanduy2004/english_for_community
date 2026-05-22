# 03 - CI/CD Release Pipeline (Push -> Build APK -> Candidate chờ duyệt)

## 1) Mục tiêu

Tự động hóa luồng:

`push code -> build apk/aab -> create release candidate -> admin duyệt -> app client nhận update signal`

## 2) Trigger strategy đề xuất

- Nhánh `main`: build tự động và tạo release candidate `pending_approval`.
- Chỉ admin mới có quyền publish để user nhận cập nhật.

## 3) Output artifact

- Android:
  - `apk` cho internal test.
  - `aab` cho Google Play release.
- Artifact naming:
  - `e4c-android-v{versionName}+{versionCode}.apk`

## 4) Biến môi trường cần thiết

- `APP_ENV=production|staging`
- `BACKEND_BASE_URL`
- `ADMIN_RELEASE_TOKEN` (gọi endpoint publish)
- Android signing secrets:
  - `ANDROID_KEYSTORE_BASE64`
  - `ANDROID_KEY_ALIAS`
  - `ANDROID_KEYSTORE_PASSWORD`
  - `ANDROID_KEY_PASSWORD`

## 5) Pipeline stages

1. **Checkout**
2. **Setup Flutter SDK**
3. **Install dependencies**
4. **Run tests** (unit/widget smoke)
5. **Build APK/AAB**
6. **Upload artifact** (GitHub Actions artifacts hoac cloud storage)
7. **Call backend create release candidate**
8. **Notify team** (Slack/Discord optional)

## 6) Publish metadata strategy

Sau khi build thành công:

- Lấy version từ `pubspec.yaml` hoặc build config.
- Tạo payload release.
- `POST /api/app/releases/ci-candidates`.

Nếu tạo candidate thất bại:

- Mark pipeline fail.
- Không thông báo build hoàn chỉnh.

## 7) Lưu ý và rủi ro

- Build thành công nhưng không tạo candidate -> admin không thể duyệt bản đó.
- Metadata sai `minSupportedVersionCode` có thể gây force update sai.
- Cần có check duplicate `versionCode`.

## 8) Mau pseudo workflow

```yaml
name: Main Auto Build Candidate
on:
  push:
    branches:
      - "main"

jobs:
  build-and-create-candidate:
    steps:
      - checkout
      - setup-flutter
      - flutter pub get
      - flutter test
      - flutter build apk --release
      - upload artifact
      - call backend /api/app/releases/ci-candidates
```

> Ghi chú: file này là đặc tả nghiệp vụ CI/CD. Khi implement thật, cần tạo workflow thực tế theo hệ thống CI đang dùng.
