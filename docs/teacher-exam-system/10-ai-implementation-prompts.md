# 10 — AI Implementation Prompts (Teacher Exams)

Copy/paste the blocks below into your AI coding agent. Each prompt references docs in `docs/teacher-exam-system/`.

> **Ghi chú (VI)**: Sau mỗi phase, chạy test + manual smoke theo acceptance criteria trong tài liệu tương ứng.

## 0) Global constraints (append to every prompt)

```text
Repo: English for Community monorepo (Flutter app english_for_community/, Node backend english_for_community_backend/).

Hard rules:
- Follow .cursor/rules/project.mdc.
- Backend: ES modules, thin controllers, business logic in services, zod validation, mongoose models.
- Flutter: BLoC + repository + datasource + GetIt registration + go_router + AppLocalizations (en+vi ARB).
- Never allow clients to self-elevate role; teacher promotion only via admin-approved workflow.
- Use Either<Failure,T> in Flutter repositories; no unhandled exceptions crossing repository boundary.

Docs are the source of truth:
- docs/teacher-exam-system/01-business-requirements.md
- docs/teacher-exam-system/02-teacher-role-and-permissions.md
- docs/teacher-exam-system/03-classroom-system-design.md
- docs/teacher-exam-system/04-exam-builder-design.md
- docs/teacher-exam-system/05-exam-execution-and-modes.md
- docs/teacher-exam-system/06-grading-system-design.md
- docs/teacher-exam-system/07-technical-architecture.md
- docs/teacher-exam-system/08-flutter-ui-specification.md
- docs/teacher-exam-system/09-implementation-roadmap.md
```

## 1) Prompt — Phase 1 (Teacher role + applications + RBAC)

```text
Implement Phase 1 from docs/teacher-exam-system/09-implementation-roadmap.md.

Backend:
- Add TeacherApplication mongoose model + teacherApplicationService + controller + routes exactly as described in docs/teacher-exam-system/02-teacher-role-and-permissions.md and route table in 07.
- Extend User.role enum to include teacher (english_for_community_backend/src/models/User.js).
- Extend permissions.js with teacher permissions + VALID_ROLES + ROLE_PERMISSIONS mapping.
- Secure admin review endpoints with authenticate + requireAdmin.
- Add migration script if needed for existing users (no-op).

Flutter:
- Ensure UserEntity parses role=teacher.
- Add go_router routes for /admin/teacher-applications and /teacher (placeholder dashboard ok).
- Add minimal UI: apply-to-teach form + admin list/detail approve/reject.
- Add ARB strings en+vi.

Tests:
- Service tests for application state transitions (pending->approved updates user role).
```

## 2) Prompt — Phase 2 (Classrooms)

```text
Implement Phase 2 per docs/teacher-exam-system/03-classroom-system-design.md and route map in 07.

Backend:
- Classroom + ClassroomMember models with indexes (inviteCode unique, inviteToken unique).
- Services enforce ownership and join policies.
- Implement join-by-code and join-by-token endpoints.

Flutter:
- Teacher: create/list/detail classroom + rotate invite + archive.
- Student: join class + enrolled list.

Acceptance:
- Teacher creates class, student joins, both can read class detail per membership rules.
```

## 3) Prompt — Phase 3 (Exam templates / builder API)

```text
Implement Phase 3 per docs/teacher-exam-system/04-exam-builder-design.md.

Backend:
- Exam model with polymorphic items + settings + publish validation (zod).
- Teacher CRUD endpoints under /api/teacher/exams with ownership checks.

Flutter:
- Minimal exam builder: create draft, edit sections/items for mcq + essay first; extend to all kinds in a second PR if needed, but backend must validate all kinds from doc.

Acceptance:
- Cannot publish invalid exam; draft saves work.
```

## 4) Prompt — Phase 4 (Self-paced assignments + attempts + auto grade)

```text
Implement Phase 4 per docs/teacher-exam-system/05-exam-execution-and-modes.md (self_paced only) and grading auto rules in 06.

Backend:
- ExamAssignment model for audience=classroom and mode=self_paced.
- Start/submit attempt endpoints with server time authority.
- Persist answers with PATCH throttling guidance (document server-side rate limit).
- Objective auto grading immediately on submit (or queued, but must finalize same request if small).

Flutter:
- Student sees assignment, takes exam, submits, sees results per showResultsPolicy for objective-only exam.

Acceptance:
- End-to-end self-paced objective exam works.
```

## 5) Prompt — Phase 5 (Scheduled mode)

```text
Implement scheduled mode per docs/teacher-exam-system/05-exam-execution-and-modes.md.

Backend:
- Enforce opensAt/closesAt + merge timer deadline logic.
- Add auto-submit expiration path (pick worker vs lazy finalize, document choice in README for ops).

Flutter:
- UX for locked assignment outside window.

Acceptance:
- Cannot start outside window; auto-expire works reliably.
```

## 6) Prompt — Phase 6 (Realtime sessions + Socket.IO)

```text
Implement realtime mode per docs/teacher-exam-system/05-exam-execution-and-modes.md and socket notes in 07.

Backend:
- ExamSession with examSnapshot binding.
- REST transitions for start/end; socket broadcasts for session state + countdown.
- Authenticate socket joins using existing verifyTokenSocket.js patterns.

Flutter:
- Teacher session console + student lobby/live.

Acceptance:
- Teacher start event reaches connected clients; attempts lock appropriately on end.
```

## 7) Prompt — Phase 7 (AI grading + manual release)

```text
Implement Phase 7 per docs/teacher-exam-system/06-grading-system-design.md.

Backend:
- examGradingService: AI draft for essay/speaking; store model metadata; failures -> pending_manual.
- Teacher endpoints for overrides + finalize + release.

Flutter:
- Grading queue + attempt detail editor.

Acceptance:
- Teacher can adjust AI draft and release results; student visibility obeys policy.
```

## 8) Prompt — Phase 8 (Hardening + analytics hooks)

```text
Implement Phase 8 per docs/teacher-exam-system/09-implementation-roadmap.md.

Include:
- rate limits on join/start/public token endpoints
- basic audit logs for admin teacher approvals
- optional Firebase analytics events from 08

Acceptance:
- Pilot checklist passes: teacher apply, class, mixed exam, 3 modes (smoke), grading release, no regressions for normal user/admin.
```

## 9) Prompt — Full-stack vertical slice (pilot demo)

```text
Build a demo path only (still production quality): teacher approved seed user creates a classroom, publishes a mixed exam (mcq + essay), assigns self-paced due in 24h, student completes, AI+manual grading releases results.

Keep scope tight; mark optional features behind flags.
```

## 10) “AI done” checklist (for humans)

- [ ] RBAC: teacher cannot access unrelated teacher resources by ID tampering.
- [ ] Admin cannot accidentally publish teacher exams (unless explicitly allowed).
- [ ] Exam edits do not mutate in-flight attempts (snapshot/versioning).
- [ ] Localization complete for all new UI.
- [ ] Socket reconnect UX does not corrupt attempt state.
- [ ] AI failures degrade gracefully.
