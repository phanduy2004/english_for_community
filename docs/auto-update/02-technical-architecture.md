# 02 - Technical Architecture

## 1) Tổng quan kiến trúc

Thành phần:

- **Flutter App**: đọc version hiện tại + gọi API check update.
- **Backend (Node.js)**: quản lý release metadata + quyết định trạng thái update.
- **CI/CD pipeline**: build APK/AAB + publish metadata.
- **Store/Distribution**: Google Play (ưu tiên), hoặc kênh phát hành nội bộ.

## 2) Data model đề xuất (Backend)

Collection: `AppRelease`

- `platform`: `android` | `ios`
- `environment`: `production` | `staging`
- `versionName`: string (ví dụ `1.5.0`)
- `versionCode`: number (ví dụ `10500`)
- `minSupportedVersionCode`: number
- `forceUpdate`: boolean
- `downloadUrl`: string (nếu không dùng store)
- `storeUrl`: string (Google Play/App Store)
- `changelog`: string
- `publishedAt`: datetime
- `isActive`: boolean

Collection: `AppUpdateEvent` (optional, analytics)

- `userId` (optional)
- `platform`
- `currentVersionCode`
- `result`: `up_to_date` | `soft_update` | `force_update`
- `action`: `view_dialog` | `click_update` | `click_later`
- `createdAt`

## 3) API contract đề xuất

### 3.1 Check update

- `GET /api/app/version-check?platform=android&versionCode=10400`

Response:

```json
{
  "status": "soft_update",
  "latestVersionName": "1.5.0",
  "latestVersionCode": 10500,
  "minSupportedVersionCode": 10450,
  "forceUpdate": false,
  "storeUrl": "https://play.google.com/store/apps/details?id=com.e4c.app",
  "downloadUrl": null,
  "changelog": "Fix speaking feedback and improve performance.",
  "publishedAt": "2026-05-06T08:30:00.000Z"
}
```

### 3.2 Publish release metadata (chỉ admin)

- `POST /api/admin/app-releases`
- Auth: `authenticate + requireAdmin`

Body:

```json
{
  "platform": "android",
  "environment": "production",
  "versionName": "1.5.0",
  "versionCode": 10500,
  "minSupportedVersionCode": 10450,
  "forceUpdate": false,
  "storeUrl": "https://play.google.com/store/apps/details?id=com.e4c.app",
  "downloadUrl": null,
  "changelog": "..."
}
```

## 4) Flutter integration points

- Tạo feature mới: `lib/feature/app_update/`.
- Layer theo pattern dự án:
  - datasource -> repository -> bloc -> UI dialog.
- Kiểm tra version:
  - app launch,
  - app resume,
- sau login thành công.

## 5) Luật so sánh version

Ưu tiên so sánh bằng `versionCode` (số nguyên), tránh so sánh chuỗi `versionName`.

Pseudo:

```text
if currentVersionCode < minSupportedVersionCode => force_update
else if currentVersionCode < latestVersionCode => soft_update
else => up_to_date
```

## 6) Bảo mật và vận hành

- Endpoint publish metadata chỉ admin được gọi.
- Validate đầu vào bằng zod.
- Lưu audit log khi publish.
- Có cơ chế disable release (`isActive = false`) nếu rollback.
