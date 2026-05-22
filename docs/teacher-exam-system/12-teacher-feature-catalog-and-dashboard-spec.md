# 12 — Teacher feature catalog & dashboard spec (for AI implementation)

This document is a **single catalog** of teacher-facing capabilities in E4C: **what exists in code**, **business rules**, **Flutter routes**, and **HTTP API paths** (relative to `/api`). Use it with [01-business-requirements.md](01-business-requirements.md), [05-exam-execution-and-modes.md](05-exam-execution-and-modes.md), [06-grading-system-design.md](06-grading-system-design.md), [11-detailed-feature-implementation-plan.md](11-detailed-feature-implementation-plan.md), and [10-ai-implementation-prompts.md](10-ai-implementation-prompts.md).

**Language**: headings and identifiers in English; Vietnamese used where it clarifies policy for local operators.

---

## 1) Scope & actors

| Actor | Scope |
|-------|--------|
| **Teacher** | `role === 'teacher'` (after admin approval). Manages own classrooms, exams, assignments, sessions, grading for **own** data only. |
| **Student** | `role === 'user'`. Joins classes, starts attempts from assignments or public links, submits attempts. |
| **Admin** | Approves teacher applications; CMS content is **global** — teachers **reuse** CMS assets in exams (they do not replace admin CMS for platform-wide content). |

**Monorepo**: Flutter `english_for_community/`, API `english_for_community_backend/`.

---

## 2) Feature matrix (catalog)

Status: **Implemented** = usable end-to-end in app + API; **Partial** = exists but UX/policy gaps or optional fields missing; **Planned** = documented intent, not in codebase.

| Feature | Purpose | Preconditions | Main flow | Flutter routes (primary) | API (base) | Status |
|---------|---------|---------------|-----------|---------------------------|------------|--------|
| Teacher application | User requests teacher role | Logged-in user | Submit → pending → admin approves | `/teacher/apply` | `POST /api/teacher/applications`, `GET …/applications/me`, `POST …/applications/withdraw` | Implemented |
| Admin review applications | Approve / reject teachers | Admin | List / approve / reject | `/admin/teacher-applications` | Admin routes (see `adminController` / `adminRoutes`) | Implemented |
| Create classroom | Teacher-owned cohort | Teacher role | Create → invite code | `/teacher` (FAB), `/teacher/classroom/:id` | `POST /api/classrooms`, `GET /api/classrooms/mine` | Implemented |
| Join classroom (student) | Enrol in class | Active user | Code / token join | `/student/classes` (`MyClassesHubPage`) | `POST /api/classrooms/join-by-code`, `join-by-token`, `GET /api/classrooms/enrolled` | Implemented |
| List / manage members | Roster control | Teacher owns class | List / remove | Classroom detail | `GET /api/classrooms/:id/members`, `POST …/members/:userId/remove` | Implemented |
| Create exam draft | Author skills exam | Teacher | Draft → edit sections + grammar | `/teacher/exams`, `/teacher/exams/:id/integrated-edit`, `/teacher/exams/:id/edit` (classic) | `POST /api/teacher/exams`, `GET /api/teacher/exams`, `GET|PATCH /api/teacher/exams/:examId` | Implemented |
| Publish exam | Freeze content for assignment | Draft valid | Publish | Same editors | `POST /api/teacher/exams/:examId/publish` | Implemented |
| Archive exam | Retire template | Owner | Archive | Exams list | `POST /api/teacher/exams/:examId/archive` | Implemented |
| Create assignment | Attach published exam to class or public | Published exam | Wizard / API body | `/teacher/exams/:id/assign` | `POST /api/teacher/exams/assignments` | Implemented |
| List assignments (teacher) | Ops overview | Teacher | Dashboard / list | `/teacher` | `GET /api/teacher/exams/assignments` | Implemented |
| Self-paced attempt | Student works to deadline | Class member or public rules | Start → patch answers → submit | `/student/exams` → start → `/student/exam-run/:attemptId` (`ExamRunnerPage` embeds `IntegratedExamRunnerPage` when `examFormat` is `skills_exam` or `integrated_four_skills`) | `POST /api/exams/assignments/:assignmentId/start`, `PATCH /api/exams/attempts/:attemptId`, `POST …/submit`, `GET …/attempts/:attemptId` | Implemented |
| Scheduled attempt | Window + optional timer | Window open | Same as self-paced with time rules | Same | Same + assignment `config.opensAt` / `closesAt` / `timeLimitSeconds` | Implemented |
| Realtime session | Live cohort exam | `mode === realtime` | Create session → lobby → start → end | Teacher: `/teacher/exam-console/:assignmentId`; student: `/student/exam-session/:sessionId` | `POST /api/teacher/exams/assignments/:id/sessions`, `POST …/sessions/:id/start|end`, `POST /api/exams/sessions/:sessionId/join`, `GET …/my-attempt` | Implemented |
| Public exam link | Non-class audience | Assignment `audience: public_link` | Preview → start with token | `/student/exams/join` (`PublicExamJoinPage`) | `GET /api/exams/public/:token/preview`, `POST …/start` (preview/start use stricter rate limit `examPublicJoinLimiter`) | Implemented |
| Rotate / close public assignment | Invalidate or stop new joins | Teacher owns assignment | Dashboard actions or API | Teacher dashboard (public filter) | `POST /api/teacher/exams/assignments/:assignmentId/public-join/rotate`, `POST …/close` | Implemented |
| Grading list | See attempts per assignment | Teacher owns assignment | Open grading | `/teacher/exam-grading/:assignmentId` | `GET /api/teacher/exams/assignments/:assignmentId/attempts` | Implemented |
| Per-attempt grade | Manual adjust + AI assist | Submitted / in policy | Detail grade | `/teacher/exam-grading/:assignmentId/attempt/:attemptId` | `GET /api/teacher/exams/grading-attempts/:attemptId`, `POST …/ai-suggestions`, `PATCH …/manual-grade`, `POST …/release-results` | Implemented |
| Student attempt context | Show class, teacher, mode, deadlines on runner | Backend populates | Load attempt | Integrated runner | `GET /api/exams/attempts/:attemptId` returns `runtimeContext` when service attaches it | Implemented |
| Grammar JSON import | Bulk grammar items | Draft exam | Import file in integrated editor | Integrated exam editor | N/A (client-side merge into PATCH body) | Implemented |
| Teacher content create | New CMS item from teacher | Teacher route | Navigate to editor | `/teacher/content/:type/new` | Same as admin (`reading`, `listening`, etc.) | Partial (reuse admin pages; ensure backend allows teacher role on those POSTs — verify permissions in deployment) |
| Full teacher analytics dashboard | Gradebook, export, trends | — | — | — | — | Planned |
| Partial submit (early hand-in) | Submit incomplete integrated exam | `allowPartialSubmit` on exam/assignment | Wizard + runner + server `submit` | Same as attempts | Same submit path | Implemented (see `examAttemptService.submit`, assignment wizard toggle; doc §3.5 / `13-partial-submit…` for policy) |

---

## 3) Detailed business domains & acceptance criteria

### 3.1 Teacher application

- **AC1**: Only authenticated users may create an application; duplicate pending rules per `teacherApplicationController` / service.
- **AC2**: User can read own application status via `GET /api/teacher/applications/me`.
- **AC3**: Withdraw clears or marks withdrawn per service rules.

### 3.2 Classrooms

- **AC1**: Teacher creates classroom → receives `inviteCode` (and related token if used by join flows).
- **AC2**: `GET /api/classrooms/mine` returns teacher’s non-archived classes with member counts where implemented.
- **AC3**: Student join requires valid code/token and membership rules (`ClassroomMember` active).
- **AC4**: Teacher may list/remove members only with `TEACHER_CLASSROOM_MEMBERS_MANAGE` (see permissions).

### 3.3 Exams (skills exam product)

- **AC1**: Exam has `status`: `draft` | `published` | `archived`.
- **AC2**: **Publish** requires every **enabled** skill section to reference at least one CMS resource (`resourceId` legacy or `resources[]`); grammar optional but validated for points cap when combined with skills (see Flutter editor validation messages).
- **AC3**: `examSnapshot` on `ExamAttempt` is a copy of exam at start time — later edits to template do not mutate past attempts.
- **AC4**: `settings.examFormat` values include `skills_exam` and legacy `integrated_four_skills` / classic flows where still present; scoring branch in `examAttemptService.submit` depends on format.

### 3.4 Assignments & delivery modes

| `mode` | Meaning | Typical `config` keys |
|--------|---------|------------------------|
| `self_paced` | Take-home style | `dueAt` (ISO), optional per-attempt `timeLimitSeconds` |
| `scheduled` | Calendar window | `opensAt`, `closesAt`, optional `timeLimitSeconds` from first interaction |
| `realtime` | Live session | Session lifecycle; attempts created on `start` for joined students |

- **AC1**: Assignment references `examId` (published) and `teacherId`.
- **AC2**: `audience`: `classroom` requires `classroomId`; `public_link` uses `publicJoin.token` (+ optional max uses / expiry).
- **AC3**: Optional `config.subject` is surfaced to students as `runtimeContext.subject` when present (otherwise UI default string).

### 3.5 Student: integrated / skills exam runner & submit policy

**Relevant files**

- Flutter: `english_for_community/lib/feature/student/exams/integrated_exam_runner_page.dart`
- Backend: `english_for_community_backend/src/services/examAttemptService.js` → `submit()` for `skills_exam` / `integrated_four_skills`

**Policy (current — must stay consistent FE + BE)**

1. **Skill sections**: For each included skill section, `answers[sectionId].completed === true` is required before submit. Students mark completion after opening CMS-linked activities (honor system + progress UX).
2. **Grammar**: For each `settings.grammarItems[]` entry, `grammarAnswerComplete(item, answers[itemId])` must be true (MCQ selection, blanks filled, matching map complete, reorder order length).
3. **Frontend**: Submit button disabled until local `doneCount == total`; `_submit()` also shows snackbar if any gate fails.
4. **Backend**: Rejects with `400` if incomplete — prevents bypass via API.

**Rationale**: Objective grammar scoring + fixed skill pool (100-point model when skills present) assumes a closed set of “done” parts; partial submit would need explicit scoring rules (see §7).

**Contrast — classic exam runner**

- `english_for_community/lib/feature/student/exams/exam_runner_page.dart` calls `submitExamAttempt` without the same “all parts done” UI gate; backend uses different `walkItems` scoring path.

### 3.6 Realtime session

- **AC1**: Only `realtime` assignments use `createExamSession`.
- **AC2**: Students `join` while session `lobby`; teacher `start` → attempts created for joined users (see `examSessionService.startSession`).
- **AC3**: Teacher `end` → force submit in-progress attempts (`submit(..., { force: true })` pattern).

### 3.7 Grading & results

- Follow [06-grading-system-design.md](06-grading-system-design.md).
- **AC1**: Teacher may run AI suggestions and patch manual grades where permitted by `gradingState` and permissions.
- **AC2**: `release-results` transitions visibility per exam `showResultsPolicy` / attempt flags.

---

## 4) Teacher Dashboard — vision vs current implementation

### 4.1 Current (`TeacherDashboardPage`)

**Route**: `/teacher` — [`teacher_dashboard_page.dart`](../../english_for_community/lib/feature/teacher/teacher_dashboard_page.dart)

**Data loaded**: `GET /api/classrooms/mine`, `GET /api/teacher/exams/assignments`

**UI blocks today** (Flutter `TeacherDashboardPage`)

1. **Overview**: stat tiles — class count, assignment count, realtime-mode assignments, draft/published exam counts, **grading queue size** (client-side aggregate from `listAssignmentAttempts` per assignment, batched).
2. **Shortcuts**: Exam bank, new skills exam draft, sample MCQ, teacher application.
3. **Live sessions**: horizontal strip for `mode === realtime` → session console.
4. **Grading queue**: submitted attempts with `pending_manual` / `pending_ai` / `finalized` & `!resultsReleased` (cap 15, newest first) → per-attempt grading route.
5. **My classrooms**: cards with copy invite code.
6. **Assignment hub**: search, filter chips (mode + public link), per-row actions: assign wizard, grading list, console (realtime only); due / window line when `config` dates exist.

### 4.2 Recommended dashboard sections (target UX — for AI / future sprints)

Map each tile to **existing** route first; only add routes when a feature is new.

| Section | User goal | Map to current |
|---------|-----------|----------------|
| Overview | Counts: active classes, open assignments, attempts awaiting action | *Implemented* — client-side from `GET /classrooms/mine`, `GET /teacher/exams/assignments`, `GET /teacher/exams`, plus batched `GET /teacher/exams/assignments/:id/attempts` for queue size |
| Classes | CRUD + invite | `/teacher`, `/teacher/classroom/:id` |
| Exam bank | Draft / published | `/teacher/exams` |
| Assignments hub | Filter by mode, due, class | `/teacher` — search + filter chips + rich assignment cards |
| Live now | Active realtime sessions | Horizontal strip → console per assignment |
| Grading queue | Ungraded / needs release | Dashboard queue → `/teacher/exam-grading/:assignmentId/attempt/:attemptId` |
| Apply / profile | Teacher onboarding | `/teacher/apply`; profile link if present |

---

## 5) Flutter route reference (teacher)

| Path | Widget / purpose |
|------|------------------|
| `/teacher/apply` | `TeacherApplyPage` |
| `/teacher` | `TeacherDashboardPage` |
| `/teacher/classroom/:classroomId` | `TeacherClassroomDetailPage` |
| `/teacher/exams` | `TeacherExamsListPage` |
| `/teacher/exams/:examId/edit` | `TeacherExamEditorPage` (classic) |
| `/teacher/exams/:examId/integrated-edit` | `TeacherIntegratedExamEditorPage` |
| `/teacher/exams/:examId/assign` | `TeacherAssignmentWizardPage` |
| `/teacher/exam-console/:assignmentId` | `TeacherExamSessionConsolePage` |
| `/teacher/exam-grading/:assignmentId` | `TeacherExamGradingPage` |
| `/teacher/exam-grading/:assignmentId/attempt/:attemptId` | `TeacherExamAttemptGradePage` |
| `/teacher/content/:type/new` | Reuses admin content editors (`reading` \| `listening` \| `speaking` \| `writing`) |

Student exam (reference):

| Path | Purpose |
|------|---------|
| `/student/exams` | `ExamAssignmentsPage` — list available assignments, start attempt |
| `/student/exams/join` | `PublicExamJoinPage` — token-based public exam |
| `/student/exam-session/:sessionId` | `ExamSessionLobbyPage` — realtime lobby / join flow |
| `/student/exam-run/:attemptId` | `ExamRunnerPage` — classic items **or** delegates to `IntegratedExamRunnerPage` when snapshot `settings.examFormat` is `skills_exam` or `integrated_four_skills` |

---

## 6) HTTP API quick reference

Prefix: **`/api`** from app config.

**Teacher** (`/api/teacher/...`)

- Applications: `POST /applications`, `GET /applications/me`, `POST /applications/withdraw`
- Exams: `POST /exams`, `GET /exams`, `GET /exams/:examId`, `PATCH /exams/:examId`, `POST /exams/:examId/publish`, `POST /exams/:examId/archive`
- Assignments: `POST /exams/assignments`, `GET /exams/assignments`, `GET /exams/assignments/:assignmentId/attempts`
- Sessions: `POST /exams/assignments/:assignmentId/sessions`, `POST /exams/sessions/:sessionId/start`, `POST /exams/sessions/:sessionId/end`
- Grading: `GET /exams/grading-attempts/:attemptId`, `POST /exams/attempts/:attemptId/ai-suggestions`, `PATCH /exams/attempts/:attemptId/manual-grade`, `POST /exams/attempts/:attemptId/release-results`

**Classrooms** (`/api/classrooms/...`)

- Teacher: `POST /`, `GET /mine`, `GET /:id`, `PATCH /:id`, `POST /:id/archive`, `POST /:id/rotate-invite`, `GET /:id/members`, `POST /:id/members/:userId/remove`
- Student: `GET /enrolled`, `POST /join-by-code`, `POST /join-by-token`

**Student exams** (`/api/exams/...`)

- `GET /assignments/available`, `POST /assignments/:assignmentId/start`
- `POST /sessions/:sessionId/join`, `GET /sessions/:sessionId/my-attempt`
- `GET /attempts/:attemptId`, `PATCH /attempts/:attemptId`, `POST /attempts/:attemptId/submit`
- Public: `GET /public/:token/preview`, `POST /public/:token/start`

---

## 7) Backlog (intentional extensions)

| Item | Notes |
|------|--------|
| **Partial submit + Grading Hub** | Xem chi tiết **[13-partial-submit-and-grading-hub-spec.md](13-partial-submit-and-grading-hub-spec.md)** (Phase A–D). |
| **Dashboard summary API** | Server-side counts to avoid N+1 client calls. |
| **Notifications** | Assignment published, session starting, grade released. |
| **Class analytics** | Completion rate, average score, time-on-task. |
| **Export** | CSV gradebook per assignment. |

---

## 8) References

- [01-business-requirements.md](01-business-requirements.md)
- [05-exam-execution-and-modes.md](05-exam-execution-and-modes.md)
- [06-grading-system-design.md](06-grading-system-design.md)
- [10-ai-implementation-prompts.md](10-ai-implementation-prompts.md)
- [11-detailed-feature-implementation-plan.md](11-detailed-feature-implementation-plan.md)
- Project rules: [`.cursor/rules/project.mdc`](../../.cursor/rules/project.mdc)
