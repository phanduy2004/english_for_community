# 08 — Flutter UI Specification (Teacher / Student / Admin)

## 1) Principles

- **BLoC** for business logic; repositories return `Either<Failure, T>`.
- **No hardcoded UI strings** — add keys to `english_for_community/lib/l10n/app_en.arb` and `app_vi.arb`.
- Use existing theme tokens: `AppColors`, `AppFonts`, `AppTheme`.
- Register new BLoCs/repos in [`english_for_community/lib/core/get_it/get_it.dart`](../../english_for_community/lib/core/get_it/get_it.dart).
- Routes live in [`english_for_community/lib/core/router/app_router.dart`](../../english_for_community/lib/core/router/app_router.dart) with `static const routePath` / `routeName` per page.

> **Ghi chú (VI)**: Teacher UI là module mới; tránh nhét logic vào `feature/admin` trừ khi là màn hình admin duyệt teacher.

## 2) Navigation model

### 2.1 Role-based shells

| Role | Shell |
|------|-------|
| `user` | Student shell + new **My Classes** / **Exams** entries |
| `teacher` | Adds **Teacher** tab or side entry (product choice) |
| `admin` | Existing admin console + link to **Teacher Applications** |

### 2.2 Suggested route prefixes

- `/teacher` — teacher dashboard subtree
- `/student/classes` — enrollment + class detail
- `/student/exams` — take exam flow
- `/admin/teacher-applications` — admin review

## 3) Admin screens

### A1 — Teacher applications inbox

- **List**: filters `pending | approved | rejected`
- **Detail**: applicant profile summary, message, attachments
- **Actions**: Approve / Reject (modal with reason)
- **States**: loading, empty, error toast

### A2 — Audit (optional)

- Timeline of decisions (reuse patterns from other admin modules if available).

## 4) Teacher screens

### T0 — Become a teacher (applicant)

Shown to `role == user`:

- Form: bio, institution, subjects (chips), optional links
- Submit → pending banner on home/profile

### T1 — Teacher dashboard

Cards:

- **My Classrooms**
- **My Exams**
- **Grading queue** (count badge)

### T2 — Classroom list / create

- FAB **Create classroom**
- List: name, member count, invite code copy button

### T3 — Classroom detail

Tabs:

1. **Overview** — description, join policy, QR/code
2. **Members** — list, remove
3. **Assignments** — linked exams + status

Actions:

- Rotate invite token (confirm dialog)
- Archive class

### T4 — Exam list / create

- List: title, status `draft/published`, last updated
- Create exam → opens builder

### T5 — Exam builder (wizard)

Steps:

1. **Metadata** — title, description, default settings (timer, shuffle)
2. **Sections** — add/reorder sections
3. **Items** — pick kind per item; nested editor for reading/listening
4. **Media** — upload/listen preview for audio
5. **Review** — points totals, validation errors list
6. **Publish** — confirm

**Autosave**: v1 manual **Save draft** button (simpler).

### T6 — Assignment wizard

After publish:

- Choose **audience**: classroom vs public link
- Choose **mode**: self-paced / scheduled / realtime
- Configure fields per `05`

### T7 — Realtime session control

- Lobby monitor: connected students, “Start”, “End early”
- Live timer display (read-only; server drives)

### T8 — Grading

- Queue list filters: `needs_manual`, `ai_failed`
- Attempt detail:
  - split view: prompt left, answer right
  - per-item rubric sliders
  - **Finalize** + **Release results**

## 5) Student screens

### S1 — My classes

- Cards of enrolled classes + CTA **Join class**

### S2 — Join class

- Input invite code OR handle deep link route ` /join-class?token=...`

### S3 — Class detail (student)

- Assignments list with due dates and status chips: `not_started | in_progress | submitted | graded`

### S4 — Exam instructions

- Show rules, timer policy, integrity notice (soft)

### S5 — Exam runner

- Top bar: timer, submit
- Bottom navigation: question list drawer
- Autosave indicator (subtle)
- Submit confirmation dialog

### S6 — Results

- Respect `showResultsPolicy` — may show partial results or “awaiting teacher release”

## 6) Socket UX (student + teacher)

- On losing socket: banner **“Reconnecting…”**; freeze submit until reconnected (or allow offline draft only if product allows — default **block submit**).

> **Ghi chú (VI)**: Socket chủ yếu để UX đồng bộ; không dùng socket payload làm nguồn sự thật điểm số.

## 7) Accessibility & education UX

- Large tap targets for MCQ options
- Support dynamic type scaling
- Provide high-contrast mode compatibility (Material 3)

## 8) Analytics (client)

Optional Firebase Analytics events:

- `teacher_apply_submitted`
- `classroom_created`
- `exam_published`
- `exam_attempt_submitted`

## 9) Acceptance criteria

- All listed screens have: loading / empty / error states.
- All strings localized EN+VI.
- Role guards prevent unauthorized deep links.
