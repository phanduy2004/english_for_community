# 10 - Prompt triển khai đầy đủ cho AI (Admin Approval + Main Auto CI/CD)

## 1) Prompt tổng (full-stack)

Sao chép prompt sau cho AI:

```text
Implement a full release governance system for app updates with admin approval workflow.

Business requirements:
- Every source code change on main branch triggers CI/CD automatically.
- CI/CD builds APK/AAB and creates a release candidate in backend.
- Candidate must be pending_approval by default.
- Only admin can approve/reject/schedule/publish.
- Mobile app version-check endpoint must only expose published + active release.

Backend (Node.js, Express, Mongoose, service-layer):
- Add AppRelease model with lifecycle status and metadata from CI.
- Add AppReleaseAuditLog model.
- Add CI endpoint: POST /api/app/releases/ci-candidates (token auth).
- Add admin endpoints for list/detail/approve/reject/schedule/publish/rollback.
- Add strict state transition validation.
- Add audit logging for all transitions.
- Keep only one active published release per platform+environment.

Flutter Admin:
- Add admin release management pages:
  - release list with filters by status/platform/environment
  - release detail with build metadata and audit timeline
  - actions: approve/reject/schedule/publish/rollback
- Add proper RBAC checks and disabled buttons for invalid transitions.

Flutter User App:
- Keep update-check flow.
- Display update prompt only from published active release.
- Handle soft vs force update.

CI/CD:
- Add GitHub Actions workflow triggered on push to main with source paths.
- Steps: test -> build -> upload artifacts -> call backend candidate endpoint.
- Never auto publish to users.

Deliverables:
- Production-grade code
- API docs and migration notes
- test cases for state transitions and version-check logic
```

## 2) Prompt riêng backend

```text
Implement backend release governance in english_for_community_backend:
- Models: AppRelease, AppReleaseAuditLog
- Service: appReleaseService with status machine guards
- Routes/controllers:
  - POST /api/app/releases/ci-candidates (CI token)
  - GET /api/admin/app-releases
  - GET /api/admin/app-releases/:id
  - POST /api/admin/app-releases/:id/approve
  - POST /api/admin/app-releases/:id/reject
  - POST /api/admin/app-releases/:id/schedule
  - POST /api/admin/app-releases/:id/publish
  - POST /api/admin/app-releases/:id/rollback
  - GET /api/app/version-check
- Validate all payloads with zod.
- Add audit logs and permission checks.
- Add tests for state transitions and active release uniqueness.
```

## 3) Prompt riêng admin Flutter

```text
Implement admin release management UI in Flutter:
- New feature module under feature/admin/release_management
- Use existing architecture: datasource/repository/bloc/pages
- Screens:
  1) release list page with filters
  2) release detail page with actions and audit history
- Actions: approve/reject/schedule/publish/rollback
- Add loading/error/success states
- Add localization keys en+vi
- Respect existing theme/router patterns
```

## 4) Prompt riêng CI/CD

```text
Create GitHub Actions workflow:
- Trigger: push on main branch when source paths change
- Setup Flutter, run tests, build APK/AAB
- Upload artifact
- Parse versionName/versionCode from pubspec.yaml
- Call backend POST /api/app/releases/ci-candidates
- Send notification to team channel
- Fail workflow if candidate creation fails
```

## 5) Tiêu chí “AI làm xong”

- Có candidate tự động sau mỗi lần main thay đổi source.
- Admin duyệt được release bằng UI.
- User app chỉ nhận release đã published.
- Có test state machine và rollback.
