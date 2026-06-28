# Screen Brief — Student classroom detail

> **Màn:** Chi tiết lớp học (học sinh) · **File:** `lib/feature/student/classes/student_classroom_detail_page.dart`
> **Archetype:** A3 · Hub detail + tabs ([`../01-screen-archetypes.md`](../01-screen-archetypes.md))
> **Trạng thái:** ✅ Phase 1–3 (06/2026)

---

## Layout

```
┌─────────────────────────────────────┐
│ ←  Tên lớp                    💬● ℹ️ │  AppBar + accent line + unread badge
├─────────────────────────────────────┤
│  [avatar/cover] GV · policy chip    │  KPI header (emerald accent)
│  [Open][Submitted][Members] stats   │
├─────────────────────────────────────┤
│ Tổng quan | Bài tập | Thành viên    │  TabBar
├─────────────────────────────────────┤
│ TAB 0: live banner, pinned, recent  │
│ TAB 1: 4-segment filter + sort      │
│ TAB 2: search + grouped member list │
└─────────────────────────────────────┘
```

## Tokens & components

| Vùng | Component |
|------|-----------|
| AppBar | `StudentMobileUi.appBar` + emerald accent line |
| KPI | `statCard` compact ×3, `ChatGroupCoverAvatar` |
| Tabs | Material `TabBar` / `TabBarView` |
| Assignments | `StudentExamAssignmentTile(compact: true)` |
| Members | `StudentClassroomGroupedCard` + `StudentClassroomMemberTile` |
| Info | `StudentBottomSheet` — mute (local), invite (gated), leave |

## Data sources

| Data | API |
|------|-----|
| Classroom + counts | `GET /classrooms/:id` |
| Assignments | `GET /exams/classrooms/:id/assignments/available` |
| Members | `ClassroomChatRepository.getChatMembers` |
| Pinned / cover | `ClassroomChatRepository.getChatSettings` |
| Unread chat | `ClassroomChatDockController.unreadCountFor` |
| Leave class | `POST /classrooms/:id/leave` |

## Phase map

| Phase | Scope |
|-------|--------|
| P1 | Unread badge, pinned strip, KPI memberCountActive, silent refresh skeleton, live banner |
| P2 | Graded segment, sort, member search, cover image, invite gate, this brief |
| P3 | Leave class API + local mute prefs |
