# 03 — Classroom System Design

## 1) Goals

- Give each **teacher** a bounded workspace (**Classroom**) to manage **members** and **assignments**.
- Support **both**:
  - **Class-scoped** distribution (“only my class sees this exam”), and
  - **Public exam links** (see `05-exam-execution-and-modes.md` for token mechanics).

> **Ghi chú (VI)**: Classroom là “đội ngũ học viên”, không nhất thiết map 1:1 với lớp trường học ngoài đời.

## 2) Data model (`Classroom`)

**Collection**: `Classrooms`

| Field | Type | Notes |
|-------|------|------|
| `_id` | ObjectId | |
| `teacherId` | ObjectId | Owner |
| `name` | string | Required |
| `description` | string | Optional |
| `coverImageUrl` | string | Optional (Cloudinary pattern) |
| `inviteCode` | string | Short unique code (e.g. 6–8 chars) |
| `inviteToken` | string | Long unguessable token for deep links |
| `joinPolicy` | enum | `open | approval_required` (default `open`) |
| `archived` | boolean | Soft archive |
| `settings` | object | `{ allowStudentInvite: boolean }` optional |
| `createdAt` / `updatedAt` | date | |

**Indexes**

- Unique `inviteCode`
- Unique `inviteToken`
- `{ teacherId: 1, archived: 1, updatedAt: -1 }` list

### 2.1 Membership (`ClassroomMember`)

**Collection**: `ClassroomMembers`

| Field | Type | Notes |
|-------|------|------|
| `classroomId` | ObjectId | |
| `userId` | ObjectId | Student |
| `roleInClass` | enum | `student` (future: `assistant`) |
| `status` | enum | `active | pending | removed` |
| `joinedAt` | date | |
| `leftAt` | date | optional |

**Indexes**

- Unique compound `{ classroomId: 1, userId: 1 }` for active membership semantics (or allow history rows — pick one; recommended: **single row** + `status`)

## 3) Lifecycle

```text
Created -> Active -> Archived
          |-> Student joins (open) OR requests (approval)
```

- **Archive**: hides from student home; keeps historical attempts (do not hard delete).

## 4) Join mechanisms

### 4.1 Invite code (manual entry)

1. Student enters `inviteCode` in app.
2. Server validates classroom exists + not archived.
3. If `joinPolicy=open` → upsert membership `active`.
4. If `approval_required` → membership `pending` + teacher notification (FCM optional).

### 4.2 Deep link / QR

- URL pattern (example): `https://app.e4c.example/join-class?token={inviteToken}`
- Server resolves token → classroom id.

### 4.3 Teacher-driven invite (optional phase)

- `POST /invite` with `targetUserId` or email lookup — can be **Phase 2.1** if email graph is weak.

> **Ghi chú (VI)**: Phase 1 nên ưu tiên **code + link** để triển khai nhanh.

## 5) Authorization rules

- **List/read classroom**: teacher owner OR member student.
- **Update/delete/archive**: teacher owner only.
- **Remove student**: teacher owner only.
- **Admin**: read/moderate for support (optional endpoints under `/api/admin/...`).

## 6) API contract (proposed)

> Prefix: `/api/classrooms` (alternative: `/api/teacher/classrooms` — choose one globally in `07`).

### 6.1 Teacher

| Method | Path | Permission |
|--------|------|--------------|
| `POST` | `/api/classrooms` | `teacher.classroom.manage` |
| `GET` | `/api/classrooms/mine` | `teacher.classroom.manage` |
| `GET` | `/api/classrooms/:id` | owner OR member |
| `PATCH` | `/api/classrooms/:id` | owner |
| `POST` | `/api/classrooms/:id/archive` | owner |
| `POST` | `/api/classrooms/:id/rotate-invite` | owner (rotates token/code) |
| `GET` | `/api/classrooms/:id/members` | owner |
| `POST` | `/api/classrooms/:id/members/remove` | `teacher.classroom.members.manage` |

### 6.2 Student

| Method | Path | Permission |
|--------|------|--------------|
| `POST` | `/api/classrooms/join-by-code` | `authenticate` |
| `POST` | `/api/classrooms/join-by-token` | `authenticate` |
| `GET` | `/api/classrooms/enrolled` | `authenticate` |

**Bodies (examples)**

`POST /api/classrooms/join-by-code`

```json
{ "inviteCode": "E4C7K2" }
```

`POST /api/classrooms`

```json
{ "name": "IELTS Evening A1", "description": "...", "joinPolicy": "open" }
```

## 7) Classroom ↔ Exam assignment

- `ClassroomAssignment` (or embedded list — prefer separate collection for analytics):

| Field | Notes |
|-------|------|
| `classroomId` | |
| `examId` | template |
| `mode` | `self_paced | scheduled | realtime` |
| `config` | deadlines / window / session id reference |
| `createdBy` | teacher |

Detailed in `05-exam-execution-and-modes.md`.

## 8) Flutter module shape (reference)

- `feature/teacher/classroom/` pages + blocs
- Repositories: `ClassroomRepository` returning `Either<Failure, T>`

## 9) Acceptance criteria

- Teacher can create class, student can join with code + token link.
- Archived class cannot be joined; existing members see archived state.
- Membership uniqueness enforced.
