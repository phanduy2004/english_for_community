# 04 — Exam Builder Design (Mixed Types)

> **Product alignment (2026):** New teacher exams follow the **skills exam** model in [`01-business-requirements.md`](01-business-requirements.md) UC-5 and [`../ui-ux-system/05-teacher-integrated-four-skill-exam.md`](../ui-ux-system/05-teacher-integrated-four-skill-exam.md): selectable CMS-linked skills + optional **Grammar (MCQ)**. This document still describes the **generic `Exam.sections` item polymorphism** used by legacy “classic” templates and shared MCQ mechanics; implementers should prefer extending the **skills + Grammar** contract for new APIs rather than growing classic-only surface area.

## 1) Goals

- Teachers author **one exam** composed of **multiple sections** and **heterogeneous question items**.
- The exam definition is a **versioned template** (`Exam`) independent from student attempts.
- Support **media** (audio, images) consistent with existing Cloudinary usage patterns in the backend.

> **Ghi chú (VI)**: Tách `Exam` (đề) khỏi `ExamSession` (ca thi) để tái sử dụng đề cho nhiều lớp/kỳ thi.

## 2) Core entities

### 2.1 `Exam` (template)

| Field | Type | Notes |
|-------|------|------|
| `teacherId` | ObjectId | Owner |
| `title` | string | |
| `description` | string | optional |
| `status` | enum | `draft | published | archived` |
| `sections` | array | ordered |
| `settings` | object | see §4 |
| `contentVersion` | number | bump on breaking edits (optional) |
| `createdAt` / `updatedAt` | date | |

### 2.2 `ExamSection`

| Field | Type | Notes |
|-------|------|------|
| `sectionId` | string (uuid) | stable client reference |
| `title` | string | optional |
| `instructions` | string | optional |
| `order` | number | |
| `items` | array of `ExamItem` | polymorphic discriminator |

## 3) `ExamItem` polymorphism

Use a discriminator field:

```json
{ "kind": "mcq_single", "id": "...", "...": "..." }
```

### 3.1 Supported kinds (v1 scope)

| `kind` | Description |
|--------|-------------|
| `mcq_single` | One correct option |
| `mcq_multi` | Multiple correct options; partial scoring policy in settings |
| `fill_blank` | One or more blanks; normalization rules for answers |
| `essay` | Rich text response; manual/AI grading |
| `reading` | Passage + nested items (usually MCQ) |
| `listening` | `audioUrl` + transcript (optional visibility) + nested items |
| `speaking` | Prompt text + max duration; audio upload response |

### 3.2 Common item fields

| Field | Notes |
|-------|------|
| `itemId` | uuid |
| `order` | number within section |
| `points` | number (default 1) |
| `tags` | string[] optional (analytics) |

### 3.3 MCQ schema

```json
{
  "kind": "mcq_single",
  "itemId": "q1",
  "order": 1,
  "points": 2,
  "stem": "Choose the best answer.",
  "options": ["A", "B", "C", "D"],
  "correctOptionIndexes": [1],
  "shuffleOptions": true
}
```

For `mcq_multi`, `correctOptionIndexes` has length > 1; define **partial credit** in exam settings.

### 3.4 Fill-blank schema

```json
{
  "kind": "fill_blank",
  "itemId": "q2",
  "order": 2,
  "points": 1,
  "template": "I ___ to school every day.",
  "blanks": [
    { "blankId": "b1", "acceptedAnswers": ["go", "walk"], "caseInsensitive": true, "trim": true }
  ]
}
```

> **Ghi chú (VI)**: Chuẩn hoá Unicode, bỏ dấu có thể là optional flag (cẩn thận với tiếng Việt/Anh).

### 3.5 Reading / Listening container

```json
{
  "kind": "reading",
  "itemId": "passage1",
  "order": 3,
  "points": 0,
  "passage": "...markdown or plain...",
  "nestedItems": [ /* mcq_single objects without kind? or reuse kind */ ]
}
```

Listening:

```json
{
  "kind": "listening",
  "itemId": "lst1",
  "order": 4,
  "points": 0,
  "audioUrl": "https://...",
  "showTranscriptDuringExam": false,
  "transcript": "...",
  "nestedItems": [ /* mcq */ ]
}
```

### 3.6 Essay

```json
{
  "kind": "essay",
  "itemId": "e1",
  "order": 10,
  "points": 10,
  "prompt": "Write 150-180 words...",
  "minWords": 120,
  "maxWords": 220,
  "allowRichText": false
}
```

### 3.7 Speaking

```json
{
  "kind": "speaking",
  "itemId": "s1",
  "order": 11,
  "points": 10,
  "prompt": "Describe your hometown...",
  "prepSeconds": 30,
  "recordSeconds": 120,
  "maxAttemptsRecord": 3
}
```

## 4) Exam `settings` (template-level)

| Key | Type | Purpose |
|-----|------|---------|
| `shuffleSections` | boolean | |
| `shuffleItems` | boolean | within section |
| `defaultItemPoints` | number | |
| `timeLimitSeconds` | number? | null = untimed template default |
| `allowBackNavigation` | boolean | |
| `showResultsPolicy` | enum | `never | after_submit | after_release` |
| `allowMultipleSubmissions` | boolean | usually false for exams |
| `negativeMarking` | boolean | default false |
| `multiSelectGrading` | enum | `all_or_nothing | partial_by_correct_ratio` |

## 5) Media handling

- **Upload**: reuse existing multer + Cloudinary endpoints (or add `POST /api/teacher/media` scoped upload).
- **Store URLs** on exam items; validate MIME types server-side.
- **Transcript policy**: default hide during attempt unless exam allows.

> **Ghi chú (VI)**: Giới hạn dung lượng audio để tránh chi phí lưu trữ và timeout upload.

## 6) Versioning & edit safety

- If a published exam is edited while sessions exist:
  - Either **block edits** when active sessions reference version, or
  - Implement `contentVersion` snapshot on `ExamSession` (recommended).

## 7) API contract (template CRUD)

Base: `/api/teacher/exams` (owner-scoped)

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/teacher/exams` | create draft |
| `GET` | `/api/teacher/exams` | list mine |
| `GET` | `/api/teacher/exams/:examId` | detail |
| `PATCH` | `/api/teacher/exams/:examId` | update draft / patch sections |
| `POST` | `/api/teacher/exams/:examId/publish` | validate then publish |
| `POST` | `/api/teacher/exams/:examId/archive` | archive |

**Validation (Zod)**

- Ensure each `itemId` unique within exam.
- Ensure `correctOptionIndexes` in range.
- Ensure listening has `audioUrl`.

## 8) Flutter builder UX (summary)

See `08-flutter-ui-specification.md` for screens. Data-wise:

- Local draft state machine in BLoC; periodic autosave optional (v1: explicit Save).

## 9) Acceptance criteria

- Teacher can create mixed exam with at least one item per kind in pilot checklist.
- Publish blocks invalid exams (missing correct answers, missing audio).
- Published exam snapshot can be bound to sessions (see `05`).
