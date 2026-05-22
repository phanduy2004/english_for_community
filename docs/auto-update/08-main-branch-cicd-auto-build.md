# 08 - Workflow CI/CD tự động khi nhánh main thay đổi

## 1) Nguyên tắc bắt buộc

- Mỗi khi `main` có thay đổi source code, pipeline phải tự chạy.
- Pipeline tự tạo build artifact + release candidate.
- Pipeline **không tự publish cho user**.
- Bước publish chỉ xảy ra sau khi admin duyệt.

## 2) Trigger

- `on: push` cho branch `main`.
- Có thể thêm `paths` để chỉ chạy khi thay đổi source (không chạy khi thay docs).

Ví dụ lọc path:

- `english_for_community/lib/**`
- `english_for_community/android/**`
- `english_for_community/pubspec.*`
- `english_for_community_backend/**` (nếu cần đồng bộ backend)

## 3) Pipeline stages

1. **Checkout**
2. **Detect changed files** (đảm bảo có thay source code)
3. **Setup Flutter**
4. **Flutter pub get**
5. **Lint + test**
6. **Build APK/AAB**
7. **Upload artifact**
8. **Create release candidate via API**
9. **Notify admin channel (Slack/Email)**

## 4) Payload CI -> Backend (candidate)

`POST /api/app/releases/ci-candidates`

Body tối thiểu:

```json
{
  "platform": "android",
  "environment": "production",
  "versionName": "1.2.0",
  "versionCode": 12000,
  "buildSource": "main",
  "gitBranch": "main",
  "gitSha": "abc123...",
  "ciRunId": "github-actions-run-id",
  "artifactUrlApk": "https://...",
  "artifactUrlAab": "https://...",
  "changelog": "Auto-generated from commits"
}
```

Backend set mặc định:

- `status = pending_approval`
- `isActive = false`

## 5) Chính sách lỗi

- Build fail -> pipeline fail, không tạo candidate.
- Build ok nhưng create candidate fail -> pipeline fail để tránh release thất lạc.
- Notify admin kèm trạng thái fail/success.

## 6) Workflow mẫu (rút gọn)

```yaml
name: Main Auto Build Candidate
on:
  push:
    branches: [main]
    paths:
      - "english_for_community/lib/**"
      - "english_for_community/android/**"
      - "english_for_community/pubspec.yaml"
      - "english_for_community/pubspec.lock"

jobs:
  build-candidate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
        working-directory: english_for_community
      - run: flutter test
        working-directory: english_for_community
      - run: flutter build apk --release
        working-directory: english_for_community
      - name: Upload artifact
        # upload apk/aab
      - name: Create candidate in backend
        # curl POST /api/app/releases/ci-candidates
```

## 7) Môi trường bí mật cần có

- `BACKEND_BASE_URL`
- `CI_RELEASE_TOKEN`
- `ANDROID_KEYSTORE_*`
- `SLACK_WEBHOOK_URL` (optional)

## 8) Kết quả kỳ vọng

- Team luôn có candidate mới ngay sau mỗi thay đổi ở `main`.
- Admin luôn có hàng chờ duyệt rõ ràng.
- User chỉ nhận bản đã kiểm soát.
