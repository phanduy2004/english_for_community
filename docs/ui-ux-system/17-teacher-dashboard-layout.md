# 17 — Teacher dashboard layout (v5 — stats-only)

> Spec cho `/teacher`. Bổ sung [`08-web-screens.md`](08-web-screens.md) §A1.
> Coding: xem [`../dev/flutter-coding-structure.md`](../dev/flutter-coding-structure.md).

---

## 1. Mục tiêu UX

Giáo viên mở dashboard trả lời trong **3 giây**:

1. **Tình hình chung?** → 4 KPI + panel Tổng quan (học sinh, lớp, đề, phân loại chấm).
2. **Có việc gấp không?** → Panel Cần xử lý (số + chip) → tap sang `/teacher/inbox`.
3. **Đi đâu tiếp?** → Quick actions + dải lớp (ngang).

**Không** hiển thị list chấm bài / live chi tiết trên dashboard — chuyển sang **Inbox**.

---

## 2. Anatomy (desktop, một viewport — không scroll trang)

```
┌─────────────────────────────────────────────────────────────────┐
│ Header: Chào {name} · subtitle · Refresh | Lịch | + Đề mới      │
├─────────────────────────────────────────────────────────────────┤
│ KPI grid 4 cột                                                │
│ [Cần xử lý] [Live] [Lớp] [Bài giao]                           │
├─────────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────┬─────────────────────────┐           │
│ │ Tổng quan               │ Cần xử lý               │  Expanded │
│ │ 2×2 stat tiles          │ attention chips         │           │
│ │ grading breakdown       │ activity stat rows      │           │
│ └─────────────────────────┴─────────────────────────┘           │
├─────────────────────────────────────────────────────────────────┤
│ Dải lớp (ngang, max 4) — tên + số HS + copy mã                 │
├─────────────────────────────────────────────────────────────────┤
│ Quick actions: +Đề · Ngân hàng · Lịch · Inbox · Tạo lớp        │
└─────────────────────────────────────────────────────────────────┘
```

### 2.1 KPI (4 ô)

| KPI | Ý nghĩa | Tap |
|-----|---------|-----|
| Cần xử lý | Grading queue length | `/teacher/inbox` |
| Live | Phiên realtime | `/teacher/inbox?filter=live` |
| Lớp | Số lớp | Mở lớp đầu / tạo lớp |
| Bài giao | Assignment active | `/teacher/calendar` |

### 2.2 Inbox (`/teacher/inbox`)

- List đầy đủ: chấm tay, live, pending join, due soon.
- Filter: All / Grading / Live.
- Scroll **trong** list — không scroll cả shell.
- **Card anatomy (v5.1):** nền `surfaceCard`, viền trái 4px theo loại (grading/live/due/pending), 3 dòng:
  1. Học sinh / tiêu đề + pill trạng thái
  2. Tên bài / đề
  3. Tên lớp + thời gian nộp
- Khoảng cách giữa card: `AppSpacing.s3` (12px).

---

## 3. File map

| Widget / màn | File |
|--------------|------|
| Page + BLoC shell | `teacher_dashboard_page.dart` |
| Body stats | `teacher_dashboard_overview.dart` |
| Inbox page | `teacher_inbox_page.dart` |
| Inbox builder | `teacher_dashboard_inbox_builder.dart` |
| `TeacherKpiGrid` | `layout/teacher_page_scaffold.dart` |
| `TeacherKpiCard` | `layout/teacher_widgets.dart` |
| Panel, quick actions, inbox card | `layout/teacher_dashboard_layout.dart` |

---

## 4. Anti-patterns

- ❌ List «Today» / grading rows trên dashboard.
- ❌ `TeacherKpiGrid` import nhầm từ `teacher_widgets.dart`.
- ❌ `TeacherDashboardPanel(fillHeight: true)` trong `Expanded` (cố định 360px).
- ❌ `SizedBox(height: 60)` cho inbox row (overflow 5px).
- ❌ Hot reload sau khi xóa/đổi class — cần Hot Restart.

---

## 5. l10n keys chính

| Key | Ghi chú |
|-----|---------|
| `teacherDashboardStatNeedsAction` | KPI |
| `teacherDashboardStatStudents` | Tile tổng quan |
| `teacherDashboardOverview` | Panel trái |
| `teacherDashboardActionItems` | Panel phải + inbox title |
| `teacherDashboardQuickActionsTitle` | Footer chips |
