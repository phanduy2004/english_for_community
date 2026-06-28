# Work Order — Student Classroom Detail Redesign

**Task ID:** `20260628-student-classroom-detail-redesign`  
**Loại:** FEATURE  
**Cỡ:** T1 (work-order + tracker)  
**Ngày:** 2026-06-28

---

## 1. Vấn đề + nguyên nhân gốc

### Vấn đề (user-facing)
Màn **Student Classroom Detail** (`/student/classroom/:id`) thiếu các chức năng cơ bản của một lớp học: không xem thành viên, không có cài đặt/thông tin lớp đầy đủ, chat che nội dung, layout rối khi có nhiều bài tập.

### Nguyên nhân gốc (dẫn chứng code)
| # | Nguyên nhân | Dẫn chứng |
|---|-------------|-----------|
| R1 | **Single-scroll, không tab** — mọi thứ xếp dọc | `student_classroom_detail_page.dart:331-361` — chỉ `ListView` hero + assignments |
| R2 | **Bloc chỉ load classroom + assignments** — không members | `student_classroom_detail_bloc.dart:18-48` |
| R3 | **FAB chat che tile cuối** | `student_classroom_detail_page.dart:283-308` — `FloatingActionButton.extended` |
| R4 | **Hero card trùng AppBar title** + quá dài (desc full) | `_classHero` + `skillAppBar` cùng hiện tên lớp |
| R5 | **Assignment card quá nặng** trên mobile | `exam_assignment_card.dart` — metadata dài (room code, session, tags…) |
| R6 | **Không parity với teacher** — teacher có 5 tab | `teacher_classroom_detail_page.dart:61` — Overview/Assignments/Members/Activity/Settings |

### So sánh Teacher vs Student

| Khả năng | Teacher | Student hiện tại |
|----------|---------|------------------|
| Tab navigation | 5 tab | Không |
| Overview KPI | Có | Hero card thô |
| Assignments segment (active/history) | Có | Flat list |
| Members | Có (manage) | Không |
| Settings (invite, policy, archive) | Có | Không |
| Activity log | Có | Không |
| Chat entry | Action bar | FAB (che content) |

---

## 2. Audit downstream

| Consumer | Ảnh hưởng |
|----------|-----------|
| `my_classes_hub_page.dart` | Navigate vào detail — không đổi route |
| `app_router.dart` | Giữ `StudentClassroomDetailPage.routePath` |
| `notification_navigation.dart` | Deeplink classroom — không đổi |
| `TeacherExamRepository.getClassroom` | Dùng chung — OK |
| `listClassroomMembers` | **Teacher-only permission** hiện tại — student cần API read-only mới hoặc endpoint mở |
| `ClassroomChatRepository.getChatMembers` | **Có sẵn** — dùng cho tab Thành viên (chat members) |

**Blocker API:** `GET /classrooms/:id/members` yêu cầu `TEACHER_CLASSROOM_MEMBERS_MANAGE`. Student không gọi được.  
**Giải pháp P0:** dùng `ClassroomChatRepository.getChatMembers(classroomId)` cho danh sách thành viên read-only.  
**Giải pháp P1 (backend):** thêm `GET /classrooms/:id/members/roster` cho student enrolled.

---

## 3. Quyết định thiết kế (đề xuất — Phương án B Medium)

### Chọn: **3 tab + AppBar actions** (không full 5 tab như teacher)

Lý do:
- Student không cần Activity log / Settings quản trị
- 3 tab đủ: **Tổng quan | Bài tập | Thành viên**
- Chat + Info → **AppBar actions** (icon), không FAB
- Rời lớp / mã lớp → **Bottom sheet "Thông tin lớp"** từ icon ℹ️

### Wireframe (mobile)

```
┌─────────────────────────────────────┐
│ ←  10A1 — Ca sáng · HK2    💬  ℹ️  │  AppBar + accent line
├─────────────────────────────────────┤
│ [ Tổng quan ] [ Bài tập ] [ Thành viên ] │ TabBar (scrollable)
├─────────────────────────────────────┤
│ TAB 0 — Tổng quan                   │
│  ┌─ Quick actions (row) ─────────┐ │
│  │ 💬 Chat  │ 📋 Bài tập │ 👥 HS  │ │
│  └─────────────────────────────────┘ │
│  ┌─ Class summary (compact) ───────┐ │
│  │ GV · 12 HS · Open join          │ │
│  │ Mô tả (max 3 dòng + "xem thêm")│ │
│  └─────────────────────────────────┘ │
│  ┌─ Cần làm (≤3 assignment) ──────┐ │
│  │ compact tiles                   │ │
│  └─────────────────────────────────┘ │
│                                     │
│ TAB 1 — Bài tập                     │
│  [ Đang mở | Đã nộp | Hết hạn ]     │ segment chips
│  ┌─ assignment compact card ─────┐ │
│  └─────────────────────────────────┘ │
│                                     │
│ TAB 2 — Thành viên                  │
│  search (optional P1)               │
│  list avatar + name + role chip     │
└─────────────────────────────────────┘
```

### Cải thiện assignment card (mobile compact mode)
Thêm prop `compact: true` vào `ExamAssignmentCard`:
- Ẩn: room code, session timestamps chi tiết (collapse vào "Chi tiết")
- Giữ: title, mode badge, status hint, 1 CTA
- Giảm chiều cao ~40%

### AppBar actions
| Icon | Hành vi |
|------|---------|
| `Icons.chat_bubble_outline` | Push `ClassroomChatPage` |
| `Icons.info_outline` | Bottom sheet: mô tả đầy đủ, join policy, created/updated, **copy class code** (nếu có), **Rời lớp** (P1 — cần API) |

---

## 4. Scope IN / OUT

### IN (P0 — implement lần 1)
- [ ] Refactor `student_classroom_detail_page.dart` → TabBar 3 tab
- [ ] Bỏ FAB; chat → AppBar action
- [ ] Tab Tổng quan: quick actions + summary compact + 3 bài gần nhất
- [ ] Tab Bài tập: segment active/submitted/closed + compact cards
- [ ] Tab Thành viên: load `getChatMembers`
- [ ] Bottom sheet Thông tin lớp (ℹ️)
- [ ] `ExamAssignmentCard(compact: true)` variant
- [ ] Bloc mở rộng: members list, assignment segments (client-side filter)
- [ ] l10n keys mới (tab labels, quick actions, segments)
- [ ] Screen brief `docs/ui-ux-system/patterns/04-screen-briefs/student-classroom-detail.md`

### OUT (defer)
- Backend `leave classroom` API
- Backend student roster API (dùng chat members thay thế P0)
- Tài liệu lớp / materials
- Push notification settings per class
- Activity log tab
- Web/desktop layout riêng

### Chạm là DỪNG & hỏi
- Đổi schema MongoDB Classroom
- Teacher classroom detail page
- Exam runner / grading flows

---

## 5. Diff cụ thể (file plan)

| File | Thay đổi |
|------|----------|
| `lib/feature/student/classes/student_classroom_detail_page.dart` | TabController, tách `_OverviewTab`, `_AssignmentsTab`, `_MembersTab`; AppBar actions; bỏ FAB |
| `lib/feature/student/bloc/classroom_detail/student_classroom_detail_bloc.dart` | Load chat members; expose assignment segments |
| `lib/feature/student/bloc/classroom_detail/student_classroom_detail_state.dart` | `members`, `assignmentSegment` |
| `lib/feature/student/bloc/classroom_detail/student_classroom_detail_event.dart` | `LoadMembersRequested`, `SegmentChanged` |
| `lib/feature/student/exams/exam_assignment_card.dart` | `compact` mode |
| `lib/feature/student/exams/student_exam_assignment_tile.dart` | Pass `compact: true` |
| `lib/feature/student/classes/student_classroom_info_sheet.dart` | **NEW** — bottom sheet info |
| `lib/feature/student/classes/student_classroom_member_tile.dart` | **NEW** — member row |
| `lib/l10n/app_en.arb`, `app_vi.arb` | Tab + sheet strings |
| `lib/core/get_it/get_it.dart` | Inject `ClassroomChatRepository` vào bloc nếu cần |

---

## 6. Lệnh verify

```bash
cd english_for_community
dart analyze lib/feature/student/classes lib/feature/student/bloc/classroom_detail lib/feature/student/exams/exam_assignment_card.dart
flutter test test/feature/student/   # nếu có
```

Manual:
1. Mở lớp 10A1 → thấy 3 tab
2. Tab Bài tập → segment filter hoạt động
3. Tab Thành viên → list tên + avatar
4. Icon chat → vào chat, không FAB che card
5. Icon ℹ️ → sheet thông tin lớp

---

## 7. HANDOFF PROMPT (implementer)

```text
Implement work-order: docs/plantasks/FEATURE/20260628-student-classroom-detail-redesign/work-order.md

Phương án B Medium — 3 tab + AppBar actions.

FILES ĐƯỢC SỬA (chỉ các file trong section 5):
- student_classroom_detail_page.dart (+ tab widgets)
- student_classroom_detail_bloc/event/state.dart
- exam_assignment_card.dart (+ compact)
- student_exam_assignment_tile.dart
- student_classroom_info_sheet.dart (new)
- student_classroom_member_tile.dart (new)
- app_en.arb, app_vi.arb
- get_it.dart (nếu cần)

TUYỆT ĐỐI KHÔNG:
- Sửa teacher_classroom_detail_page.dart
- Sửa backend routes/models
- Thêm API leave class
- Đổi route path

Pattern: dùng StudentMobileUi.skillAppBar, TabBar Material 3, StudentBottomSheet cho info sheet.
Members: ClassroomChatRepository.getChatMembers(classroomId).
Assignments segment: client-side filter từ state.assignments (active = canStart or resume; submitted = myAttempt submitted; closed = hint session_ended/already_submitted without canStart).

Verify: dart analyze + manual checklist section 6.
```

---

## 9. Phase 1–3 enhancements (2026-06-28 implement)

| Phase | Deliverables |
|-------|----------------|
| **P1** | Unread badge (dock), pinned strip, KPI `memberCountActive`, silent refresh skeleton, live/lobby banner |
| **P2** | Segment `graded`, sort priority/due, member search, cover avatar, invite gated by `allowStudentInvite`, screen brief |
| **P3** | `POST /classrooms/:id/leave`, mute prefs (`StudentClassroomPrefs`), leave UI in info sheet |

**Backend (P3):** `classroomService.leaveClassroom`, route `POST /:id/leave`.

**Verify:**
```bash
cd english_for_community
flutter gen-l10n
dart analyze lib/feature/student/classes lib/feature/student/bloc/classroom_detail
```

---

## 8. Checklist OPUS AUDIT

- [x] 3 tab render đúng, không FAB
- [x] Chat icon hoạt động, không che content (+ unread badge P1)
- [x] Members load từ chat API, empty state OK (+ search P2)
- [x] Assignment compact card ngắn hơn bản cũ
- [x] Info sheet hiện policy + teacher + dates (+ mute/leave P3)
- [x] l10n EN + VI đầy đủ (P1–3 keys)
- [x] Không regression exam open flow
- [x] dart analyze 0 errors

**Verdict (2026-06-28):** APPROVED — chi tiết + findings → `tracker.md` § Opus audit.

---

## 10. Defer register (P4+ — không làm trong task này)

> Ghi nhận có chủ đích. Mở task mới khi ưu tiên thay đổi.

| ID | Mục | Phạm vi | Lý do defer | Task gợi ý |
|----|-----|---------|-------------|------------|
| **D-01** | i18n `ChatPinnedBanner` | `chat_pinned_banner.dart` | Hardcoded VN; component dùng chung chat thread + overview | `BUG/i18n-chat-pinned` |
| **D-02** | Mute có hiệu lực thật | `StudentClassroomPrefs` → `app_notification_listener.dart` (+ optional backend) | UI toggle đã có; pipeline noti chưa đọc key | `FEATURE/classroom-mute-notifications` |
| **D-03** | Refresh cache sau leave | `ClassroomChatDockController.loadRooms`, hub enrolled list | Pop về hub + reload lần sau đủ MVP | gộp D-03 vào D-02 hoặc hub polish |
| **D-04** | Student roster API | `GET /classrooms/:id/members/roster` | `getChatMembers` đủ read-only P0; teacher API vẫn RBAC | `FEATURE/student-classroom-roster` |
| **D-05** | Giảm 3 API call refresh | Bloc tách refresh assignments-only | Silent refresh đã UX-OK; tối ưu perf | `PERF/classroom-detail-refresh` |
| **D-06** | Test tự động leave | Backend integration test | Chưa có suite classroom routes | gộp khi thêm test harness |

**Không defer (đã xong trong scope):** invite gate, leave endpoint, graded segment, KPI fix, screen brief.
