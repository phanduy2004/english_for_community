# 15 — Schedule / Calendar Feature

> **Target users:** Teachers (and co-teachers) in the E4C teacher workspace.
> **Route:** `/teacher/calendar`
> **Sidebar label:** Schedule

---

## 1. Business Objective

Teachers manage multiple classrooms, each with several active assignments. Without a visual overview it is easy to miss overlapping due dates, forget to open an assignment, or fail to notice that an exam closed before everyone submitted. The Schedule feature gives teachers:

- A **month-grid calendar** with colour-coded event dots so a full month of activity is visible at a glance.
- A **list view** for a scrollable, date-grouped timeline of upcoming events.
- Quick navigation from any event directly to the relevant assignment or grading hub.

---

## 2. Event Types

| Kind | Meaning | Colour token |
|------|---------|-------------|
| `opens` | Assignment becomes available to students | `AppColors.success` (green) |
| `live` | Assignment is currently open (today is between opensAt and closesAt) | `AppColors.info` (indigo) |
| `due` | Soft deadline — students should finish by this date | `AppColors.warning` (amber) |
| `closes` | Hard close — no more submissions accepted | `AppColors.danger` (red) |

> **How "live" is computed:** The backend detects assignments where `opensAt ≤ now ≤ closesAt` and injects a synthetic `live` event anchored at `opensAt` with `kind = "live"`. This requires no extra DB writes.

---

## 3. Data Model (API Response)

`GET /api/teacher/dashboard/calendar?from=<ISO>&to=<ISO>`

```json
{
  "from": "2026-05-01T00:00:00.000Z",
  "to": "2026-07-01T00:00:00.000Z",
  "events": [
    {
      "assignmentId": "...",
      "examId": "...",
      "kind": "opens",
      "title": "Midterm · Class 10A",
      "classroomName": "Class 10A",
      "classroomId": "...",
      "at": "2026-05-25T08:00:00.000Z",
      "status": "active",
      "mode": "homework"
    }
  ]
}
```

**Query range:** The Flutter page loads **3 months** (current + next 2) on first open so navigation to adjacent months is instant.

---

## 4. Calendar Grid — Business Rules

1. **Month grid** shows 6 rows × 7 columns (Mon–Sun or Sun–Sat, matching device locale). Cells outside the current month are dimmed.
2. **Event dots** — up to 3 coloured dots shown beneath the day number; a `+n` overflow badge if more than 3 events fall on the same day.
3. **Today highlight** — today's cell has a filled circle behind the day number using `AppColors.primary`.
4. **Day tap** — tapping any cell that has ≥ 1 event opens a bottom panel listing events for that date.
5. **Month navigation** — `<` / `>` chevron buttons change the displayed month. Navigating to a month not yet loaded triggers a background fetch.
6. **"Today" button** — appears in the top-right actions bar; scrolls/snaps back to the current month.

---

## 5. List View — Business Rules

1. Events are sorted ascending by `at`.
2. Grouped by **date heading** (e.g. "Thu, May 21").
3. Each row shows:
   - **Kind badge** (coloured pill with label: Opens / Due / Closes / Live)
   - **Title** (exam · classroom name)
   - **Time** (local time, 12-hour with am/pm)
   - **"Go to assignment" action button** (pushes to `TeacherExamGradingPage`)
4. Past events (before today) are shown with reduced opacity (`0.5`) to indicate they have passed.
5. An empty state appears if no events exist in the loaded range.

---

## 6. UI Layout

```
┌───────────────────────────────────────────────────────────┐
│  HEADER  "Schedule"    [Today] [↺ Refresh]  [⊞ Month | ≡ List] │
├───────────────────────────────────────────────────────────┤
│                        MONTH VIEW                         │
│  ← May 2026 →                                             │
│  Su  Mo  Tu  We  Th  Fr  Sa                               │
│  ...  ...  ...  ...  1   2   3                            │
│                       ●        (event dot)                │
│  4   5   6   7   8   9   10                               │
│          ●           ●●                                   │
│  (today = filled circle)                                  │
│  ...                                                      │
│                                                           │
│  ─── Event panel (appears below grid when day tapped) ─── │
│  📌 Opens · Midterm · Class 10A · 8:00 AM  [→ Grade]     │
└───────────────────────────────────────────────────────────┘
```

---

## 7. Interaction Flow

```
Teacher opens /teacher/calendar
   ↓
Load events for current month + next 2 months
   ↓
Display month grid with coloured dots
   ↓
Teacher taps a day cell with dots
   ↓
Bottom panel slides up showing events for that day
   ↓
Teacher taps "Go to assignment" on an event
   ↓
Router pushes to TeacherExamGradingPage for that assignmentId
```

---

## 8. Intelligence / Smart Features

- **Conflict detection:** If two assignments for the same classroom have overlapping `opensAt–closesAt` windows, both appear with an amber warning icon in the day panel. *(Future enhancement — backend flag)*
- **Empty weeks highlight:** Weeks with zero events show a subtle "No exams this week" tooltip on hover (web only).
- **"Busy" visual:** Days with 5+ events display a bolder dot cluster to indicate high workload.

---

## 9. Acceptance Criteria

- [ ] Month grid shows correct weekday alignment for any month/year.
- [ ] Event dots are colour-coded by kind.
- [ ] Tapping a day cell shows all events for that date.
- [ ] "Today" button navigates back to the current month.
- [ ] List view and month view toggle correctly.
- [ ] Navigating to an event's assignment works.
- [ ] Empty state shown when no events exist.
- [ ] Loading and error states handled gracefully.
