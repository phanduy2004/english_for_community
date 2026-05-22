# 01 — Business Requirements (Teacher Role & Online Exams)

## 1) Problem statement

E4C today is optimized for **self-study** and **admin-managed global content**. Schools and tutors need a **class-centric** workflow: create a cohort, assign a **mixed-skill exam**, run it **online** (live or async), and **grade** with a combination of automation and teacher judgment.

**Gap**: No `teacher` role, no classroom primitive, no first-class “exam session” product separate from existing skill modules.

## 2) Business goals

- Enable **verified teachers** to run classes and assessments without admin CMS overhead.
- Support **three delivery modes** to match real classrooms: live quiz, scheduled window, take-home deadline.
- Support **one standard exam product**: teacher-configurable **skills** (listening / speaking / reading / writing, each backed by existing CMS content where applicable) plus an optional **Grammar** block made of **MCQ only** (auto-scored).
- Provide **transparent grading**: objective auto-score + AI assist + teacher finalization where required.
- Preserve **trust**: teacher onboarding requires **admin approval** (self-apply).

> **Ghi chú (VI)**: Mục tiêu là “lớp học + bài thi”, không phải thay thế toàn bộ nội dung học global của admin.

## 3) Actors

| Actor | Description |
|-------|-------------|
| **Learner (Student)** | `role = user` (default). Joins class, takes assigned exams, views released results. |
| **Teacher** | `role = teacher` after approval. Creates classes/exams, runs sessions, grades manually when needed. |
| **Admin** | Approves teacher applications, moderates abuse, retains platform governance. |
| **System** | Timers, auto-submit, scoring jobs, notifications (FCM optional), audit logs. |

## 4) Definitions

- **Exam template (`Exam`)**: Reusable definition for the **single supported authoring flow** (“skills exam”): which **skills** are included, links to CMS resources per enabled skill, optional **Grammar** (MCQ list), and delivery settings (duration, modes, results policy). Legacy “classic” free-form section builders, if still present in code, are **not** part of the forward product surface.
- **Exam session (`ExamSession`)**: A single “run” of an exam (especially for real-time / scheduled cohort attempts).
- **Attempt (`ExamAttempt`)**: One learner’s submission for a session (or self-paced assignment instance).
- **Classroom (`Classroom`)**: Teacher-owned space with members and optional assignments.

## 5) Core use cases

### UC-1 Teacher applies for teacher access

1. Authenticated user submits application (profile fields + optional credentials text).
2. Status: `pending` → admin `approved` / `rejected`.
3. On approval: user `role` becomes `teacher` (or stays `user` with `teacher` capability flag — see technical doc for chosen model).

### UC-2 Admin reviews teacher applications

1. Admin lists pending applications, opens detail, approves/rejects with reason.
2. Audit log records action.

### UC-3 Teacher creates a classroom

1. Teacher creates class (name, description, optional cover).
2. System generates **invite code** + **invite link**.
3. Teacher can **invite** users by email/username (optional v1.1).

### UC-4 Student joins a classroom

1. Student enters code or opens deep link.
2. Join request auto-approved OR teacher approval required (configurable per class — default: auto).

### UC-5 Teacher builds a skills exam (single product)

1. Teacher creates one exam using the **skills exam** flow (no parallel “classic-only” exam type for new work).
2. **Selects which skills to assess** among: **Listening**, **Speaking**, **Reading**, **Writing** — each enabled skill must reference one existing CMS asset (same family as today’s integrated flow: dictation set, read-aloud set, reading passage, writing topic/task).
3. Optionally enables **Grammar** and attaches **one or more multiple-choice questions** (single- or multi-select per product rules); Grammar is scored **automatically** against a fixed answer key.
4. **Publish rules**: at least **one** of (any enabled skill **or** Grammar with ≥1 question) must be present; all **enabled** skills must have a valid resource id before publish.
5. Sets policies: duration, attempts cap (if any), delivery mode compatibility, show-answers / results-release policy.

### UC-6 Teacher assigns exam to class (or publishes public link)

- **Class assignment**: visible to class members in “Assignments”.
- **Public link**: tokenized URL; optional cap on attempts; optional require login.

### UC-7 Student takes exam (mode-dependent)

- **Self-paced**: start anytime before deadline; timer starts on start.
- **Scheduled**: can enter only within `[opensAt, closesAt]`; timer rules defined by template.
- **Real-time**: student enters lobby; teacher starts; synchronized countdown; forced end.

### UC-8 Grading & result release

1. **Grammar (MCQ)** and other objective parts scored immediately where applicable.
2. AI proposes scores/feedback for writing/speaking outputs (if enabled by policy).
3. Teacher reviews manual queue, adjusts, releases results to students.

## 6) Business rules (high level)

- **Single authoring product**: new teacher exams follow the **skills exam** model (selectable listening/speaking/reading/writing + optional Grammar MCQ). Any legacy classic template support in code is for backward compatibility only unless explicitly re-scoped.
- **Teacher-only authoring**: only `teacher` (and `admin` for support) can create/edit exams they own.
- **Ownership**: exams belong to a `teacherId`; classrooms belong to `teacherId`.
- **Student visibility**: students only see exams they are entitled to (class membership or valid public token).
- **Integrity**: server is source of truth for time windows, deadlines, and submission state.

> **Ghi chú (VI)**: Client timer chỉ để UX; server phải chốt `submittedAt` và từ chối nộp bài khi hết cửa sổ.

## 7) Non-functional requirements (NFR)

| Category | Requirement |
|----------|-------------|
| **Availability** | Exam taking endpoints degrade gracefully; if AI grading fails, attempt remains `pending_grading` and teacher can still score manually. |
| **Latency (live)** | Socket broadcast for “exam started” should reach connected clients within **~1s p95** under normal load. |
| **Concurrency** | Support **N concurrent sessions** (define SLO per deployment); avoid single global lock in DB design. |
| **Security** | Tokenized public links rotate-able; rate limit join/start endpoints; audit teacher promotions. |
| **Privacy** | Speaking audio stored with retention policy; only class teacher + admin can access for moderation. |
| **Observability** | Metrics: sessions started, submissions, AI grading failures, average queue time for manual grading. |

## 8) KPIs (product)

- Time-to-first-class **< 10 minutes** for a new teacher (happy path).
- % exams fully auto-graded (objective-only) vs mixed.
- Teacher satisfaction: median time to release grades for mixed exams.

## 9) Business “done” checklist

- Teacher can apply, admin can approve, teacher dashboard accessible.
- Classroom create/join works (code + link).
- Skills exam (subset of four skills + optional Grammar MCQ) creation + assign + take (three modes) works end-to-end for a pilot class.
- Grading: auto + AI draft + manual finalize + release.
- No regression for existing `user` and `admin` flows.
