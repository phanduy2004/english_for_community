# 16 — Analytics / Chart Analyze Feature

> **Target users:** Teachers in the E4C teacher workspace.
> **Route:** `/teacher/analytics`
> **Sidebar label:** Analytics

---

## 1. Business Objective

Teachers need data-driven insights to improve their teaching. The Analytics feature provides:

- **At-a-glance KPI cards** with trend indicators vs the previous period.
- **Submissions timeline** chart to see engagement patterns.
- **Score distribution** to identify whether students are clustered at the bottom (intervention needed) or the top.
- **Per-skill breakdown** for integrated exams — which skill drags the average down.
- **Grading backlog** awareness — how many attempts are waiting for manual grading.
- **Assignment mode breakdown** — proportion of homework vs live-proctored vs self-paced exams.

All data is scoped to **the logged-in teacher's assignments** (including assignments in classrooms where they are a co-teacher).

---

## 2. Time Range Filter

Teachers can choose the analysis window:

| Label | `days` param | Description |
|-------|-------------|-------------|
| 7 d | `7` | Last 7 days |
| 14 d | `14` | Last 14 days (default) |
| 30 d | `30` | Last 30 days |

Switching the period reloads all chart data without page navigation. KPI trend arrows compare current period vs the immediately preceding period of equal length.

---

## 3. KPI Cards (Top Row)

| Card | Value | Trend |
|------|-------|-------|
| **Active students** | Count of unique enrolled students in active assignments | vs prev period |
| **Active assignments** | Count of assignments with `status = active` | vs prev period |
| **Submissions** | Count of `submitted` attempts in the period | vs prev period |
| **Pending grading** | Count of attempts with `gradingState = pending_manual` | — (absolute) |

**Trend logic:** `Δ% = (current - prev) / max(prev, 1) × 100`. Up arrow = green, down arrow = red, flat = neutral.

---

## 4. Charts

### 4.1 Submissions per Day (Bar Chart)

- X-axis: date labels (`MM-DD`), one bar per day in the selected range.
- Y-axis: count of submissions.
- Highlight bar: today's bar (if in range) uses `AppColors.chartHighlight` (amber); others use `AppColors.chartBar` (black).
- Tooltip on tap/hover shows exact count and date.
- Empty state: "Not enough data yet" centred message.

### 4.2 Score Distribution (Bar Chart)

Shows how final scores are distributed across all submitted attempts.

**Buckets (10-scale integrated exams):**

| Bucket label | Range |
|---|---|
| 0–2 | 0 ≤ score < 2 |
| 2–4 | 2 ≤ score < 4 |
| 4–6 | 4 ≤ score < 6 |
| 6–8 | 6 ≤ score < 8 |
| 8–10 | 8 ≤ score ≤ 10 |

**For legacy (pts-based) exams:** buckets are `<50%`, `50–70%`, `70–85%`, `≥85%` of max score.

The bar colour transitions from `AppColors.danger` (low) → `AppColors.warning` → `AppColors.success` (high) using a simple 5-step gradient to make outliers immediately obvious.

### 4.3 Per-Skill Average (Horizontal Bar Chart)

Only shown when integrated (`integrated_four_skills` / `skills_exam`) exams are present in the period.

Displays the average score (0–10) for each skill: **Listening**, **Reading**, **Writing**, **Speaking**, **Grammar**. This lets teachers immediately see which skill the class is weakest in and plan remedial activities.

Each bar is coloured by score:
- < 5: `AppColors.danger`
- 5–7: `AppColors.warning`
- ≥ 7: `AppColors.success`

### 4.4 Assignment Mode Breakdown (Chip row / mini stats)

Shows how many assignments fall into each mode:
- `homework` — take-home
- `live` — proctored live session
- `self_paced` — no time pressure

Displayed as labelled chips with count badges, not a full chart (low data density doesn't warrant a full chart).

### 4.5 Integrity Flags

Risk-level summary from the integrity service:
- **High risk** count (danger chip)
- **Medium risk** count (warning chip)
- **Low risk** count (success chip)
- **Unanalysed** count (neutral chip)

Tapping a chip navigates to the grading hub filtered by that risk level. *(Future enhancement)*

---

## 5. Data Model (API Response)

`GET /api/teacher/dashboard/analytics?days=14`

```json
{
  "summary": {
    "classroomCount": 3,
    "activeStudentCount": 47,
    "totalAssignments": 12,
    "activeAssignments": 5,
    "attempts": {
      "submitted": 89,
      "inProgress": 14,
      "total": 103
    },
    "pendingGradingCount": 11,
    "avgScore": 7.2,
    "completionRate": 0.78,
    "trend": {
      "activeStudents": 4.3,
      "submissions": -12.5,
      "activeAssignments": 0
    }
  },
  "charts": {
    "rangeDays": 14,
    "submissionsByDay": [
      { "date": "2026-05-08", "count": 7 }
    ],
    "scoreDistribution": [
      { "range": "0–2", "count": 3 },
      { "range": "2–4", "count": 8 },
      { "range": "4–6", "count": 22 },
      { "range": "6–8", "count": 39 },
      { "range": "8–10", "count": 17 }
    ],
    "skillScoreAvg": {
      "listening": 7.4,
      "reading": 6.9,
      "writing": 5.8,
      "speaking": 6.2,
      "grammar": 7.1
    },
    "integrityByRisk": {
      "high": 3,
      "medium": 7,
      "low": 79
    },
    "assignmentsByMode": {
      "homework": 8,
      "live": 3,
      "self_paced": 1
    }
  }
}
```

---

## 6. UI Layout

```
┌─────────────────────────────────────────────────────────────────┐
│  HEADER  "Analytics"   [7d | 14d | 30d]   [↺ Refresh]          │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌────────┐ │
│  │ Active       │ │ Active       │ │ Submissions  │ │Pending │ │
│  │ Students     │ │ Assignments  │ │              │ │Grading │ │
│  │ 47  ↑ 4.3%  │ │ 5  → 0%     │ │ 89  ↓ 12.5%  │ │  11    │ │
│  └──────────────┘ └──────────────┘ └──────────────┘ └────────┘ │
├─────────────────────────────────────────────────────────────────┤
│  Submissions per day (bar chart — 14 bars, last bar = today)    │
├─────────────────────────────────────────────────────────────────┤
│  Score distribution (5 bars, colour gradient danger→success)    │
├─────────────────────────────────────────────────────────────────┤
│  Per-skill average (horizontal bars)                            │
│  Listening  ████████░░  7.4                                     │
│  Reading    ███████░░░  6.9                                     │
│  Writing    █████░░░░░  5.8  ◄ needs attention                  │
│  Speaking   ██████░░░░  6.2                                     │
│  Grammar    ████████░░  7.1                                     │
├─────────────────────────────────────────────────────────────────┤
│  Assignment modes    [Homework 8] [Live 3] [Self-paced 1]       │
├─────────────────────────────────────────────────────────────────┤
│  Integrity flags     [High risk 3] [Medium 7] [Low 79]          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 7. Intelligence / Smart Features

- **Weakest skill callout:** If any skill's average is < 5.0, a highlighted callout card is shown above the skill breakdown: *"Writing avg 4.8/10 — consider scheduling extra practice."*
- **Completion rate badge:** Shown as a mini progress ring next to "Submissions" KPI. `completionRate = submitted / (active assignments × enrolled students)`.
- **Trend arrows:** Green ↑ / Red ↓ / Grey → depending on `Δ%` threshold (|Δ| ≥ 5% triggers coloured arrow; below = neutral).
- **No data state:** Each chart section independently shows an empty state message, so a teacher with a new account sees partial data where available.

---

## 8. Interaction Flow

```
Teacher opens /teacher/analytics
   ↓
BLoC dispatches TeacherAnalyticsLoadRequested(period: 14)
   ↓
Backend returns summary + charts
   ↓
UI renders KPI row, all charts
   ↓
Teacher taps "7d" chip
   ↓
BLoC dispatches TeacherAnalyticsPeriodChanged(period: 7)
   ↓
API called again with days=7
   ↓
Charts update in place (loading shimmer on chart areas only)
```

---

## 9. Acceptance Criteria

- [ ] KPIs display correct values from API.
- [ ] Trend arrows show correct direction and percentage.
- [ ] Switching period (7/14/30d) reloads and updates all charts.
- [ ] Submissions chart shows one bar per day for the selected range.
- [ ] Score distribution shows 5 buckets with colour gradient.
- [ ] Skill breakdown section only appears if integrated exam data is present.
- [ ] Weakest-skill callout appears when any skill avg < 5.0.
- [ ] Integrity flags shown as coloured chips.
- [ ] Empty states handled per section.
- [ ] Loading and error states handled gracefully.
