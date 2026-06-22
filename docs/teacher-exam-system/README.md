# Teacher Role & Online Examination System — Documentation Set

This documentation set is the **single implementation reference** for adding a **Teacher** role, **classrooms**, **skills-based online exams** (configurable listening/speaking/reading/writing + optional Grammar MCQ), and **grading** (auto + AI + manual) to English for Community (E4C).

## Goals

- Provide a **source of truth** for product, backend, Flutter, and real-time (Socket.IO) work.
- Split delivery into **phases** so the team can ship safely without breaking existing `user` / `admin` flows.
- Align with existing project conventions: Express + Mongoose services, JWT auth, RBAC in [`english_for_community_backend/src/constants/permissions.js`](../../english_for_community_backend/src/constants/permissions.js), Flutter BLoC + repositories.

## Language convention

- **Primary**: English (identifiers, API names, headings in numbered docs).
- **Notes**: Vietnamese is used for nuanced business rules, edge cases, and operational guidance where it reduces ambiguity.

## Scope summary

| Area | Summary |
|------|---------|
| Teacher onboarding | User **self-applies**; **Admin** approves or rejects; role becomes `teacher`. |
| Classrooms | Teachers create classes; students join via **invite code**, **link**, or **invitation**; optional **public exam** links without class membership. |
| Exams | **One** teacher exam type: **skills exam** — pick which of listening/speaking/reading/writing to include (CMS-linked), optional **Grammar** (MCQ only, auto-scored); three delivery modes. |
| Modes | **Real-time** (live session), **Scheduled** (time window), **Self-paced** (deadline). |
| Grading | **Auto** (objective), **AI** (essay/speaking), **Manual** (teacher rubric / per-question feedback). |

## Document index

| File | Purpose |
|------|---------|
| [`../product/nghiep-vu-tong-hop-va-khoang-trong.md`](../product/nghiep-vu-tong-hop-va-khoang-trong.md) | **Tóm tắt nghiệp vụ** (giáo viên–lớp–thi + cập nhật app) và **ma trận chức năng còn thiếu**; đọc trước khi lên kế hoạch sprint. |
| [`01-business-requirements.md`](01-business-requirements.md) | Problem, actors, use cases, NFRs, acceptance at business level. |
| [`02-teacher-role-and-permissions.md`](02-teacher-role-and-permissions.md) | Role lifecycle, RBAC permissions, backend/Flutter touchpoints. |
| [`03-classroom-system-design.md`](03-classroom-system-design.md) | Classroom model, membership, join flows, APIs. |
| [`04-exam-builder-design.md`](04-exam-builder-design.md) | Exam template structure, question types, media, settings. |
| [`05-exam-execution-and-modes.md`](05-exam-execution-and-modes.md) | Sessions, attempts, three modes, Socket.IO, anti-cheat notes. |
| [`06-grading-system-design.md`](06-grading-system-design.md) | Scoring pipelines, grade release, aggregation. |
| [`../exam-scoring/integrated-skill-scoring.md`](../exam-scoring/integrated-skill-scoring.md) | Integrated/skills exams: per-skill 0–10, average, no `pts` UI. |
| [`14-writing-prompt-for-skills-exam.md`](14-writing-prompt-for-skills-exam.md) | Đề Writing cố định (`fixedWritingPrompt`) khi soạn đề kỹ năng. |
| [`07-technical-architecture.md`](07-technical-architecture.md) | Collections, routes, diagrams, integrations, scale notes. |
| [`08-flutter-ui-specification.md`](08-flutter-ui-specification.md) | Screens, navigation, states, localization guardrails. |
| [`09-implementation-roadmap.md`](09-implementation-roadmap.md) | Phased delivery, dependencies, risk list. |
| [`10-ai-implementation-prompts.md`](10-ai-implementation-prompts.md) | Copy-paste prompts for AI-assisted implementation. |
| [`11-detailed-feature-implementation-plan.md`](11-detailed-feature-implementation-plan.md) | **Chi tiết từng chức năng**: task BE/Flutter, UI/UX, acceptance, map tới `01–08` + `docs/ui-ux-system`. |
| [`12-teacher-feature-catalog-and-dashboard-spec.md`](12-teacher-feature-catalog-and-dashboard-spec.md) | **Catalog tính năng giáo viên** + nghiệp vụ tóm tắt + map Flutter route / API + **chính sách nộp bài** (integrated vs classic) + vision Teacher Dashboard vs code hiện tại. |
| [`13-partial-submit-and-grading-hub-spec.md`](13-partial-submit-and-grading-hub-spec.md) | **Nộp bài chưa hoàn thành** + **Grading Hub** (danh sách bài làm HS, chấm tay / AI, công bố điểm) — nghiệp vụ chi tiết + kế hoạch Phase A–D. |

## Recommended reading order (implement)

0. **`../product/nghiep-vu-tong-hop-va-khoang-trong.md`** — bản tóm tắt nghiệp vụ + gap tổng thể (nếu làm việc đa miền).
1. `01-business-requirements.md`
2. `02-teacher-role-and-permissions.md`
3. `07-technical-architecture.md` (skim data model + route map)
4. **`12-teacher-feature-catalog-and-dashboard-spec.md`** — tra nhanh route/API và policy nộp bài khi codegen / sprint teacher.
5. `03-classroom-system-design.md`
6. `04-exam-builder-design.md`
7. `05-exam-execution-and-modes.md`
8. `06-grading-system-design.md`
9. `08-flutter-ui-specification.md`
10. `09-implementation-roadmap.md`
11. **`11-detailed-feature-implementation-plan.md`** (kế hoạch chi tiết theo chức năng + UI/UX)
12. Run tasks from `10-ai-implementation-prompts.md`

## Assumptions

- **Monorepo**: Flutter app `english_for_community/`, API `english_for_community_backend/`.
- **Auth**: JWT access token today; teacher endpoints use `authenticate` + permission checks (not only `requireAdmin`).
- **Realtime**: Socket.IO exists ([`socketManager.js`](../../english_for_community_backend/src/socket/socketManager.js)); exam rooms extend the same pattern (`exam_{sessionId}`).
- **AI**: Backend already integrates generative AI ([`aiService.js`](../../english_for_community_backend/src/services/aiService.js) pattern); exam grading reuses service layer with **exam-scoped prompts** and quotas.

## Out of scope (unless explicitly added later)

- Full LMS (full gradebook export to SIS, attendance legal compliance).
- Proctored browser lockdown (third-party proctoring).
- Offline-first exam attempts (sync when online).

## Related project rules

- Follow [`.cursor/rules/project.mdc`](../../.cursor/rules/project.mdc): BLoC, repositories, Either, no hardcoded UI strings (ARB `en` + `vi`).
