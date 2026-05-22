# 04 - Implementation Roadmap For AI

Tài liệu này viết theo task granularity để AI đọc và implement từng bước.

## Phase 0 - Preparation

- [ ] Tạo model `AppRelease` trong backend.
- [ ] Tạo migration/seed có 1 record release mẫu.
- [ ] Xác định route group cho admin APIs.

## Phase 1 - Backend version-check API

- [ ] Tạo service `appVersionService.js`:
  - tìm release active mới nhất theo `platform + environment`.
  - tính `status` theo `versionCode`.
- [ ] Tạo controller `appVersionController.js`.
- [ ] Tạo route:
  - `GET /api/app/version-check`
  - `POST /api/admin/app-releases`
- [ ] Validate input bằng zod.
- [ ] Thêm middleware auth + requireAdmin cho publish endpoint.
- [ ] Viết unit test cho logic compare version.

## Phase 2 - Flutter client integration

- [ ] Tạo feature `lib/feature/app_update/`.
- [ ] Tạo entities:
  - `app_update_info_entity.dart`
- [ ] Tạo datasource:
  - `app_update_remote_datasource.dart`
- [ ] Tạo repository + impl:
  - `app_update_repository.dart`
  - `app_update_repository_impl.dart`
- [ ] Tạo bloc:
  - `app_update_bloc.dart`, event/state.
- [ ] Gắn vào app lifecycle:
  - check khi launch/resume.
- [ ] Hiện UI:
  - soft update dialog (Cập nhật / Để sau)
  - force update dialog (chỉ Cập nhật)

## Phase 3 - CI/CD automation

- [ ] Tạo workflow build Android release.
- [ ] Parse versionName/versionCode từ source.
- [ ] Upload artifact.
- [ ] Gọi endpoint publish release metadata.
- [ ] Báo lỗi rõ ràng nếu publish fail.

## Phase 4 - Observability

- [ ] Log event version check ở backend.
- [ ] Log action người dùng click cập nhật.
- [ ] Tạo dashboard metric tối thiểu:
  - update prompt impressions
  - update click-through-rate
  - force update hit rate

## Phase 5 - Hardening

- [ ] Add rate limiting cho endpoint version check (nếu cần).
- [ ] Add cache release metadata (in-memory/redis).
- [ ] Add rollback script disable release.

## Prompt mẫu cho AI (copy dùng ngay)

### Prompt 1 - Backend

"Implement backend app update module in Node.js service-layer style:
create AppRelease model, app version check API, admin publish API, zod validation,
and versionCode comparison logic for force_update/soft_update/up_to_date.
Follow existing project patterns in routes/controllers/services."

### Prompt 2 - Flutter

"Implement Flutter app update feature with BLoC + repository + datasource.
Create API integration for /api/app/version-check, trigger checks on app launch/resume,
and show soft/force update dialogs with store redirect button.
Use current project architecture and naming conventions."

### Prompt 3 - CI/CD

"Create CI workflow for Android release build on release branch/tag.
After successful build, publish release metadata to backend admin endpoint
with versionName/versionCode, forceUpdate flag, and changelog."
