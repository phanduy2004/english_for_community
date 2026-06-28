# Tracker — Student Classroom Detail Redesign (Phase 1–3)

**Task ID:** `20260628-student-classroom-detail-redesign`

| # | Task | Phase | Status | Ghi chú |
|---|------|-------|--------|---------|
| 1 | 3-tab layout + AppBar | base | done | 2026-06-28 |
| 2 | P1: unread badge, pinned, KPI fix, skeleton, live banner | 1 | done | |
| 3 | P2: graded segment, sort, member search, cover, invite gate | 2 | done | |
| 4 | P2: screen brief + mapping log | 2 | done | |
| 5 | P3: POST leave + mute prefs UI | 3 | done | backend + SharedPreferences |
| 6 | l10n EN/VI | all | done | |
| 7 | dart analyze | all | done | 0 errors |
| 8 | Opus audit | 4 | **done** | APPROVED — xem bên dưới |
| 9 | Defer log | — | **done** | work-order §10 |

## Nhật ký

| Ngày | Sự kiện |
|------|---------|
| 2026-06-28 | Base redesign (3 tab) hoàn thành |
| 2026-06-28 | Phase 1–3 implement theo AI-Working-Process |
| 2026-06-28 | Phase 4 Opus audit — APPROVED; defer P4+ ghi §10 work-order |

## Bằng chứng verify

```
cd english_for_community
flutter gen-l10n
dart analyze lib/feature/student/classes lib/feature/student/bloc/classroom_detail lib/feature/student/classes/student_classroom_info_sheet.dart
→ No issues found!
```

### Checklist audit (Phase 4)

| Mục | Kết quả | Bằng chứng |
|-----|---------|------------|
| 3 tab, không FAB | ✅ | `TabController(length: 3)`; không `FloatingActionButton` |
| Chat AppBar + unread badge | ✅ | `ListenableBuilder` + `unreadCountFor` ~L281 |
| Pinned + live banner Overview | ✅ | `ChatPinnedBanner`, `liveOrLobby` ~L634+ |
| KPI `memberCountActive` | ✅ | `state.memberCountActive` ~L277 |
| Silent refresh skeleton | ✅ | `isRefreshing` + `listLoading()` tabs |
| 4 segment + sort | ✅ | `graded` enum + `StudentClassroomDetailSortChanged` |
| Member search | ✅ | `_MembersTabState` + `searchField` |
| Cover + invite gate | ✅ | `ChatGroupCoverAvatar`, `allowStudentInvite` |
| Leave API + UI | ✅ | `POST /:id/leave`, info sheet confirm |
| l10n EN/VI | ✅ | `app_en.arb` / `app_vi.arb` keys P1–3 |
| Exam open flow | ✅ | `_open()` giữ nguyên; `_reload(silent: true)` |
| Scope creep | ✅ | Không sửa teacher detail / exam runner |
| dart analyze | ✅ | 0 issues |

**Manual QA (DEV):** chưa chạy trên thiết bị — checklist dưới để hồi quy thủ công.

- [ ] AppBar chat badge khi có unread inbox
- [ ] Overview: pinned strip + live banner
- [ ] KPI thành viên = memberCountActive
- [ ] Pull refresh: giữ chrome, skeleton list
- [ ] Tab Bài tập: 4 segment + sort toggle
- [ ] Tab Thành viên: search
- [ ] Info sheet: cover, mute, invite chỉ khi allowStudentInvite
- [ ] Rời lớp → quay hub

## Opus audit verdict

**APPROVED** — implement khớp work-order §9; không scope-creep; analyze sạch.

### Findings (non-blocking → defer)

| ID | Mức | File | Mô tả | Xử lý |
|----|-----|------|-------|-------|
| F1 | low | `chat_pinned_banner.dart:51` | Chuỗi hardcoded `"Tin ghim ·"` — EN locale thấy tiếng Việt | **DEFER** D-01 |
| F2 | low | `student_classroom_prefs.dart` | Mute lưu local, chưa filter FCM/local noti | **DEFER** D-02 |
| F3 | low | `student_classroom_detail_page.dart` | Sau leave không gọi `loadRooms(force)` trên dock | **DEFER** D-03 |
| F4 | low | `student_classroom_detail_bloc.dart` | Refresh lỗi silent: giữ data cũ, không toast | Chấp nhận (by design) |
| F5 | info | — | Manual QA chưa có screenshot | DEV hồi quy trước release |

### Việc còn lại của DEV

1. Chạy manual QA checklist (8 mục) trên Edge/device.
2. Deploy backend route `POST /classrooms/:id/leave` lên Render khi release.
3. Các mục defer D-01…D-06 — **không làm trong task này**; mở task mới khi cần.

## Defer register (tóm tắt)

| ID | Mục | Lý do defer |
|----|-----|-------------|
| D-01 | Localize `ChatPinnedBanner` | Component chat dùng chung; task riêng i18n chat |
| D-02 | Mute → notification pipeline | Cần hook `app_notification_listener` + có thể backend prefs |
| D-03 | Invalidate dock/enrolled sau leave | UX minor; hub reload khi vào lại |
| D-04 | `GET /members/roster` student | Chat members đủ P0; roster = parity teacher |
| D-05 | Cache/partial assignment refresh | Silent reload OK; tối ưu 3-call → task PERF |
| D-06 | Automated test leave API | Không có test harness classroom hiện tại |

Chi tiết: `work-order.md` §10.
