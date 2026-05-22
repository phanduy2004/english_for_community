# 11 — Detailed feature implementation plan (Teacher exam + UI/UX)

## Product direction (single exam type)

- **One** teacher-facing exam builder: **skills exam** — teacher **selects which skills** (listening / speaking / reading / writing) are in the test; each enabled skill picks **one** CMS resource.
- **Grammar** (optional): **MCQ only**, stored on the exam, **auto-scored**.
- Legacy **classic** free-form templates are **not** a parallel product track for new features (code may remain for old data).

## Recent implementation notes (repo)

- **F2 / F5:** Classroom detail **Assign** opens a picker of **published** exams, then `TeacherAssignmentWizardPage` with **`initialClassroomId`** (pre-selected class). Route passes `extra: { initialClassroomId }` from `app_router.dart`.
- **F6:** `ExamRunnerPage` walks **all sections** for legacy classic snapshots (flattening nested reading/listening like backend `walkItems`), **Previous / Next** navigation, supports **`mcq_single`**, **`mcq_multi`**, **`fill_blank`**, **`essay`**; submitted score shows **`totalAwarded` / `totalMax`** when present. **Target student UX** for the standard product is **skills hub + Grammar MCQ** per UI [`05`](../ui-ux-system/05-teacher-integrated-four-skill-exam.md).

This document is the **execution-grade plan**: each capability is broken into **backend**, **Flutter**, **realtime (if any)**, **UI/UX alignment**, and **acceptance criteria**. It extends [`09-implementation-roadmap.md`](09-implementation-roadmap.md) with **task-level** detail and maps to the numbered specs **01–08** and [`docs/ui-ux-system/`](../ui-ux-system/README.md).

**UI/UX guardrails (apply to every Flutter deliverable)**

- Read [`../ui-ux-system/01-design-language-and-tokens.md`](../ui-ux-system/01-design-language-and-tokens.md) (typography ladder, outlined icons).
- Read [`../ui-ux-system/02-layout-architecture-and-responsive-rules.md`](../ui-ux-system/02-layout-architecture-and-responsive-rules.md) (padding, list rhythm, one primary CTA).
- Follow [`../ui-ux-system/04-ai-implementation-guardrails.md`](../ui-ux-system/04-ai-implementation-guardrails.md) (no hardcoded strings; `ExamSystemUi` + `AppCard` for teacher/student exam surfaces).
- Integrated skills exam UX + Grammar: [`../ui-ux-system/05-teacher-integrated-four-skill-exam.md`](../ui-ux-system/05-teacher-integrated-four-skill-exam.md).

---

## Legend

| Status | Meaning |
|--------|---------|
| **Done (partial)** | Exists in repo but incomplete vs spec |
| **Gap** | Missing or diverges from `01`–`08` |
| **Polish** | Works but needs UX, edge cases, or tests |

---

## F1 — Teacher onboarding & admin review

**Specs:** [`01-business-requirements.md`](01-business-requirements.md) UC-1, UC-2; [`02-teacher-role-and-permissions.md`](02-teacher-role-and-permissions.md); [`08-flutter-ui-specification.md`](08-flutter-ui-specification.md) §3 A1.

| Track | Tasks |
|--------|--------|
| **Backend** | Ensure `TeacherApplication` lifecycle + audit log on approve/reject if required by `01` §9; rate-limit apply endpoint; block role self-escalation on profile APIs. |
| **Flutter** | Applicant form validation + pending state on profile/home; admin inbox filters (`pending` / `approved` / `rejected`), detail sheet, reject reason. |
| **UI/UX** | Admin list: section titles **w500**, filters in `Wrap` or bottom sheet per **02** §6; destructive actions with confirm + consequence copy (l10n). |
| **Acceptance** | Apply → admin approve → JWT `role=teacher` → `/teacher` reachable; reject shows reason to applicant where spec requires. |

---

## F2 — Classrooms (teacher + student)

**Specs:** [`03-classroom-system-design.md`](03-classroom-system-design.md); [`01`](01-business-requirements.md) UC-3, UC-4; roadmap Phase 2.

| Track | Tasks |
|--------|--------|
| **Backend** | Join-by-code idempotency; optional **rotate invite** + **archive class** if in `03`; membership list + remove member; authorization on all classroom routes. |
| **Flutter** | **T2/T3** in [`08`](08-flutter-ui-specification.md): classroom detail **tabs** — Overview (code copy, QR optional), **Members**, **Assignments**; remove “assign first exam only” shortcut — open **assignment wizard** with exam picker (`examId`). |
| **UI/UX** | Dashboard cards use **02** vertical rhythm; invite code row uses `captionMuted` + copy icon outlined. |
| **Acceptance** | Teacher creates class → student joins → both see same class; teacher assigns chosen published exam to that class. |

---

## F3 — Skills exam builder (single product: selectable skills + Grammar MCQ)

**Specs:** [`01-business-requirements.md`](01-business-requirements.md) UC-5; [`../ui-ux-system/05-teacher-integrated-four-skill-exam.md`](../ui-ux-system/05-teacher-integrated-four-skill-exam.md); [`04-exam-builder-design.md`](04-exam-builder-design.md) where still relevant for MCQ shape / settings keys.

| Track | Tasks |
|--------|--------|
| **Backend** | Schema/settings: `enabledSkills` (subset of four) + optional `grammar` block (array of MCQ items with answer key); **publish** validates only **enabled** skills have ids; at least one of (any enabled skill **or** grammar with ≥1 question); scoring includes Grammar auto-sum; migrate or alias current `integrated_four_skills` if needed. |
| **Flutter** | Single create entry → editor: **toggles** per skill; hide/disable pickers for off skills; **Grammar** section: add/remove/reorder MCQ; l10n labels; publish errors mapped from server. |
| **UI/UX** | Clear “included in this test” summary; Grammar uses same MCQ patterns as objective items elsewhere (`ExamSystemUi`). |
| **Acceptance** | Teacher can publish exam with e.g. only Reading + Grammar; student never sees prompts for disabled skills. |

**Status:** **Done (partial)** — four-slot integrated editor + hub exist; **Gap** — per-skill toggles, Grammar block, publish/attempt/score rules for subsets + grammar.

---

## F4 — *(Merged into F3)*

Per product decision **May 2026**, integrated vs classic is no longer a dual track: **F4 tasks roll into F3** (skills + Grammar). Keep this stub for doc links; do not add new F4-only scope.

---

## F5 — Assignments (classroom + public link)

**Specs:** [`05-exam-execution-and-modes.md`](05-exam-execution-and-modes.md) §2.1; [`01`](01-business-requirements.md) UC-6; [`08`](08-flutter-ui-specification.md) §4 T6.

| Track | Tasks |
|--------|--------|
| **Backend** | Public link: `maxUses`, `expiresAt`, rotate token, **close assignment**; enforce caps per `09` Phase 8 if not done. |
| **Flutter** | Assignment wizard: **audience** segmented control already — add **public link** branch UI (copy link, expiry, max uses) if backend ready; classroom detail **Assign** → wizard with **exam dropdown** (published exams only). |
| **UI/UX** | Danger: closing assignment or rotating link → confirm dialog with l10n body **04** guardrails. |
| **Acceptance** | Class assignment appears in student **My exams**; public link join respects limits and expiry. |

**Status:** **Done (partial)** — classroom assign + public routes exist in backend; **Gap** — full public-link UX + teacher “close” action + class assign from detail with exam picker.

---

## F6 — Exam execution — student (skills hub + Grammar MCQ)

**Specs:** [`05-exam-execution-and-modes.md`](05-exam-execution-and-modes.md) §2.3, self-paced rules; [`08`](08-flutter-ui-specification.md) student flows; UI [`05`](../ui-ux-system/05-teacher-integrated-four-skill-exam.md).

| Track | Tasks |
|--------|--------|
| **Backend** | Submit rules: only **enabled** skills + grammar completion gates; patch answers for **grammar** items on attempt payload; weights for partial skill sets + grammar total = 100 (or documented policy). |
| **Flutter** | **Primary path:** hub lists **only enabled** parts; Grammar answered with **MCQ UI** (reuse objective patterns); CMS skills unchanged (open / mark done). **Legacy:** `ExamRunnerPage` remains for old classic-only snapshots until retired. |
| **UI/UX** | Sticky bottom bar for Grammar MCQ where applicable; timer chip per assignment policy. |
| **Acceptance** | Any allowed subset (e.g. Writing + Grammar) completable end-to-end; autosave visible for MCQ. |

**Status:** **Done (partial)** — hub + classic runner exist; **Gap** — skill toggles + grammar block end-to-end, scoring for subsets.

---

## F7 — Scheduled mode

**Specs:** [`05`](05-exam-execution-and-modes.md) scheduled window + `lateEntryPolicy`; roadmap Phase 5.

| Track | Tasks |
|--------|--------|
| **Backend** | Implement `lateEntryPolicy` if in schema; unify error messages for opens/closes vs timer. |
| **Flutter** | Assignment wizard + student list: show **window** in local time zone; disable **Start** with tooltip/snackbar reason; countdown to `opensAt` optional. |
| **Acceptance** | Cannot start outside window; server rejects with same semantics UI shows. |

**Status:** **Done (partial)** — backend window checks exist; **Gap** — student-facing window copy and disabled states.

---

## F8 — Realtime mode + Socket.IO

**Specs:** [`05`](05-exam-execution-and-modes.md) §4 state machine; [`07-technical-architecture.md`](07-technical-architecture.md); roadmap Phase 6.

| Track | Tasks |
|--------|--------|
| **Backend** | Session transitions `lobby → live → grading → closed`; broadcast events; snapshot consistency on `ExamSession` create. |
| **Socket** | Room naming `exam_{sessionId}`; auth on join; reconnect strategy documented. |
| **Flutter** | Teacher console + student lobby: loading/reconnect banners; mirror server state (no client-only “started”). |
| **Acceptance** | Teacher start reaches students ≤ ~1s p95 on dev/staging per **01** NFR (best effort). |

**Status:** **Done (partial)** — scaffolding exists; **Gap** — hardening, edge cases, E2E test checklist.

---

## F9 — Grading (auto + AI + manual + release)

**Specs:** [`06-grading-system-design.md`](06-grading-system-design.md); roadmap Phase 7.

| Track | Tasks |
|--------|--------|
| **Backend** | `mcq_multi` partial scoring per `settings.multiSelectGrading`; AI for speaking/writing where applicable; persist `aiPromptVersion` / model id per **06** §5.3 notes; manual grade totals recompute including **skills exams** (subset + Grammar auto). |
| **Flutter** | Grading queue on teacher dashboard (badge **T1**); attempt detail: per-item editors, AI suggestion panel, release results batch optional. |
| **UI/UX** | Grading screen: avoid bold soup; rubric numbers in `InputDecoration` with helper text **w400**. |
| **Acceptance** | Grammar MCQ: auto score visible to teacher; essay/writing: AI draft → teacher adjust → student sees score when `resultsReleased` + policy. |

**Status:** **Done (partial)** — MCQ auto + essay AI draft path; **Gap** — skills subset + Grammar in grading UI, per-skill overrides, batch release.

---

## F10 — Integrity, rate limits, audit

**Specs:** [`01`](01-business-requirements.md) §6 integrity; [`09`](09-implementation-roadmap.md) Phase 8.

| Track | Tasks |
|--------|--------|
| **Backend** | Optional `integrity` fields on patch (tab blur count); rate limit public join/start; admin audit for teacher promotion already partially elsewhere. |
| **Flutter** | Optional: warn on app background during live exam (policy). |

---

## F11 — Analytics & polish

**Specs:** [`01`](01-business-requirements.md) §7 KPIs; [`09`](09-implementation-roadmap.md) Phase 8.

| Track | Tasks |
|--------|--------|
| **Product** | Minimal metrics: assignments created, attempts submitted, AI grading failures (log + counter). |
| **Flutter** | Empty states for exam list, assignment list, grading queue — one soft illustration + short copy per **04** UI kit. |

---

## Cross-cutting checklist (every PR touching this domain)

1. **l10n**: `app_en.arb` + `app_vi.arb` + `flutter gen-l10n`.
2. **Routes**: `static const routePath` / `routeName` in [`app_router.dart`](../../english_for_community/lib/core/router/app_router.dart).
3. **DI**: register new repos/BLoCs in [`get_it.dart`](../../english_for_community/lib/core/get_it/get_it.dart).
4. **API errors**: map to `Failure` / snackbar; no raw exception strings to users.
5. **Scripts**: destructive DB scripts live under `english_for_community_backend/src/scripts/` with header comment (e.g. `clearAllExamData.js`).

---

## Suggested delivery order (sprints)

| Sprint | Focus | Primary docs |
|--------|--------|--------------|
| S1 | F2 classroom detail + F5 assign from class with exam picker | `03`, `05`, `08` T3/T6 |
| S2 | **F3** skill toggles + Grammar MCQ + publish validation; **F6** hub + runner for grammar | `01`, UI `05`, `05` execution |
| S3 | F9 scoring weights for subsets + grammar; F3 polish (pickers, empty states) | `06`, UI `05` |
| S4 | F7 scheduled UX + F5 public link UX | `05`, `08` |
| S5 | F8 realtime hardening + tests | `05`, `07` |
| S6 | F9 grading completeness + auto-complete from skill attempts (optional) | `06`, UI `05` |
| S7 | F10–F11 + performance pass | `01`, `09` |

---

## Traceability matrix (spec file → features)

| Doc | Primary features |
|-----|-------------------|
| `01` | Actors, UC, NFR, KPI, integrity expectations |
| `02` | RBAC, teacher lifecycle |
| `03` | Classroom, membership, join |
| `04` | Exam template, item polymorphism, settings |
| `05` | Assignment, session, attempt, three modes |
| `06` | Scoring pipelines, release |
| `07` | Routes, collections, socket naming |
| `08` | Screen-by-screen Flutter contract |
| `09` | Phase order (this doc refines into tasks) |
| `10` | AI prompts for implementation |
| UI `01–02,04` | Visual/typography/layout rules |
| UI `05` | Skills exam (selectable four skills + Grammar MCQ) + code map |

---

## Maintenance

When a feature ships, update this file: change **Gap** → **Done** and link the PR or commit range. Keep [`09-implementation-roadmap.md`](09-implementation-roadmap.md) exit criteria in sync for stakeholder reporting.
