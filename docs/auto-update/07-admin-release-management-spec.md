# 07 - Đặc tả quản lý phiên bản cho Admin

## 1) Mô hình dữ liệu đề xuất

Collection: `AppRelease`

- `platform`: `android | ios`
- `environment`: `production | staging`
- `versionName`
- `versionCode`
- `minSupportedVersionCode`
- `updateType`: `soft | force`
- `status`: `pending_approval | approved | rejected | scheduled | published | archived`
- `buildSource`: `main`
- `gitSha`
- `gitBranch`
- `ciRunId`
- `artifactUrlApk`
- `artifactUrlAab`
- `storeUrl`
- `downloadUrl`
- `changelog`
- `qaNotes`
- `releaseNotes`
- `approvedBy`
- `approvedAt`
- `rejectedBy`
- `rejectedAt`
- `rejectReason`
- `scheduledPublishAt`
- `publishedBy`
- `publishedAt`
- `isActive`

Collection: `AppReleaseAuditLog`

- `releaseId`
- `action`: `created_by_ci | approve | reject | schedule | publish | rollback | archive`
- `actorId`
- `actorRole`
- `beforeStatus`
- `afterStatus`
- `metadata`
- `createdAt`

## 2) API backend cần có

### 2.1 API cho CI/CD

- `POST /api/app/releases/ci-candidates`
  - Auth bằng CI token riêng.
  - Tạo release ở trạng thái `pending_approval`.

### 2.2 API cho admin

- `GET /api/admin/app-releases`
  - Filter theo `status`, `platform`, `environment`, `fromDate`, `toDate`.
- `GET /api/admin/app-releases/:id`
  - Chi tiết release + audit log.
- `POST /api/admin/app-releases/:id/approve`
  - Chuyển `pending_approval -> approved`.
- `POST /api/admin/app-releases/:id/reject`
  - Chuyển `pending_approval -> rejected`.
- `POST /api/admin/app-releases/:id/schedule`
  - Chuyển `approved -> scheduled`.
- `POST /api/admin/app-releases/:id/publish`
  - Chuyển `approved|scheduled -> published`.
  - Tự hạ `isActive=false` với bản published trước đó cùng platform/environment.
- `POST /api/admin/app-releases/:id/rollback`
  - Dừng bản hiện tại và kích hoạt bản an toàn trước đó.

### 2.3 API cho app client

- `GET /api/app/version-check?platform=android&versionCode=xxx&environment=production`
  - Chỉ trả dữ liệu từ release `published` và `isActive=true`.

## 3) Màn hình admin cần có (Flutter Admin Console)

### 3.1 Danh sách release

- Tabs trạng thái: Pending, Approved, Scheduled, Published, Rejected.
- Cột quan trọng: version, build, updateType, trạng thái, thời gian tạo, người thao tác.

### 3.2 Chi tiết release

- Thông tin build:
  - branch, commit SHA, CI run, artifact links.
- Thông tin phát hành:
  - changelog, minSupportedVersionCode, updateType.
- Lịch sử audit đầy đủ.

### 3.3 Actions

- Approve
- Reject (bắt buộc nhập lý do)
- Schedule publish (datetime)
- Publish now
- Rollback

## 4) Phân quyền

- `release.read`
- `release.approve`
- `release.reject`
- `release.schedule`
- `release.publish`
- `release.rollback`

Quy tắc:

- Chỉ role admin có các quyền trên.
- `force update` cần quyền cao hơn (ví dụ `release.publish.force`).

## 5) Validation nghiệp vụ

- Không cho publish release có `status=rejected`.
- `minSupportedVersionCode <= versionCode`.
- Không cho 2 release `published + isActive=true` cùng `platform + environment`.
- Khi publish, nếu là `force`, phải có xác nhận 2 bước ở UI admin.
