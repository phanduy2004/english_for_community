# 02 — Teacher Role & Permissions

## 1) Goals

- Introduce a **`teacher`** role with **least-privilege** access: classroom + exam + grading, **not** full admin CMS.
- Keep **admin** as the authority for **promoting** users to teacher via an application workflow.
- Extend RBAC using the existing `ROLE_PERMISSIONS` / `requirePermissions` pattern in [`english_for_community_backend/src/middleware/auth.js`](../../english_for_community_backend/src/middleware/auth.js).

> **Ghi chú (VI)**: Tránh “teacher = admin lite” không kiểm soát; teacher chỉ quản lý tài nguyên **do họ sở hữu** (class, exam).

## 2) Role model (recommended)

### 2.1 `User.role` enum extension

Update [`english_for_community_backend/src/models/User.js`](../../english_for_community_backend/src/models/User.js):

- Extend `role.enum` from `['user','admin']` → `['user','admin','teacher']`.

**Semantics**

- `user`: learner (default).
- `teacher`: approved educator; can access teacher APIs/UI.
- `admin`: platform operator; retains wildcard permissions.

### 2.2 Teacher application record

Add `TeacherApplication` collection (separate from `User`) to store onboarding workflow without overloading `User` with many nullable fields.

**Suggested fields**

- `userId` (ObjectId, ref User, unique for active pipeline rules)
- `status`: `pending | approved | rejected | withdrawn`
- `payload`: `{ bio, organization, subjects[], proofUrls[] }` (optional)
- `review`: `{ reviewerAdminId, decisionAt, reason }`
- `createdAt`, `updatedAt`

**Rules**

- Only **one** `pending` application per user at a time.
- On `approved`: set `User.role = 'teacher'` (transaction or two-phase with rollback).
- On `rejected`: user remains `user`; optional cooldown before re-apply.

> **Ghi chú (VI)**: Nếu sau này cần “teacher bị thu hồi”, có thể hạ role về `user` + khóa quyền; không nhất thiết xóa dữ liệu lớp.

## 3) Permission catalog (new)

Update [`english_for_community_backend/src/constants/permissions.js`](../../english_for_community_backend/src/constants/permissions.js):

| Permission | Meaning |
|------------|---------|
| `teacher.application.create` | Submit / withdraw own application |
| `teacher.application.read_own` | Read own application status |
| `teacher.classroom.manage` | CRUD classrooms owned by teacher |
| `teacher.classroom.members.manage` | Invite/remove students in owned classrooms |
| `teacher.exam.manage` | CRUD exams owned by teacher |
| `teacher.exam.session.run` | Start/end real-time sessions for owned exams |
| `teacher.exam.assign` | Assign exams to classrooms / generate public links |
| `teacher.grading.read` | Read attempts for entitled exams |
| `teacher.grading.write` | Manual score adjustments + release |
| `admin.teacher.application.review` | List/review applications (admin-only) |

**Default grants**

- `admin`: keep `*` wildcard.
- `teacher`: all `teacher.*` above **except** admin review permissions.
- `user`: unchanged (empty for admin/teacher routes).

Also update:

- `VALID_ROLES` → include `teacher`
- `ROLE_PERMISSIONS.teacher` → array of teacher permissions

## 4) Middleware helpers (backend)

In [`english_for_community_backend/src/middleware/auth.js`](../../english_for_community_backend/src/middleware/auth.js):

- Prefer **`requirePermissions([...])`** over ad-hoc role checks.
- Optional sugar:
  - `requireTeacher = requirePermissions(['teacher.classroom.manage'])` (example — tune to smallest permission per route)
  - `requireAdminOrTeacherOwner` implemented in **service layer** (not middleware) because ownership needs DB lookup.

> **Ghi chú (VI)**: “Owner check” nên ở service: `assertExamOwnedByTeacher(examId, req.userId)`.

## 5) API surface (teacher + admin)

### 5.1 Teacher application (user)

- `POST /api/teacher/applications` — create (idempotent rules)
- `GET /api/teacher/applications/me` — latest status
- `POST /api/teacher/applications/withdraw` — withdraw pending

### 5.2 Admin review

- `GET /api/admin/teacher-applications?status=pending`
- `POST /api/admin/teacher-applications/:id/approve`
- `POST /api/admin/teacher-applications/:id/reject` body `{ reason }`

**Auth**

- User endpoints: `authenticate`
- Admin endpoints: `authenticate + requireAdmin` (or `requirePermissions` if admin is migrated off wildcard later)

## 6) Flutter integration points

### 6.1 Domain model

Update [`english_for_community/lib/core/entity/user_entity.dart`](../../english_for_community/lib/core/entity/user_entity.dart):

- Accept `role == 'teacher'` from API JSON (already string-based).

### 6.2 Routing

Update [`english_for_community/lib/core/router/app_router.dart`](../../english_for_community/lib/core/router/app_router.dart):

- Add **teacher shell route** (similar pattern to admin redirect):
  - If `role == teacher` → allow `/teacher/*`
  - If `role == user` → block teacher routes
  - If `role == admin` → allow admin; optionally allow teacher routes if admins should tutor (product decision: default **yes** for convenience)

### 6.3 Entry UX

- Profile/settings: **“Apply to become a teacher”** when `role == user` and no pending application.
- Banner: **“Application pending”** / **“Rejected: reason”**.

> **Ghi chú (VI)**: Mọi chuỗi UI mới phải thêm `app_en.arb` + `app_vi.arb`.

## 7) Security notes

- Prevent privilege escalation: users cannot PATCH their own `role` via profile update endpoints.
- Admin audit: log approve/reject with admin id + IP (reuse `AdminAuditLog` if present).

## 8) Acceptance criteria (this document)

- Permission list is complete enough to gate every teacher route in `07-technical-architecture.md`.
- Teacher promotion cannot occur without admin review.
- Flutter routing rules are explicit for `user` / `teacher` / `admin`.
