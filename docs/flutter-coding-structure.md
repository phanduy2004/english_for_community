# Flutter — Cấu trúc code & quy tắc coding (E4C)

> Tài liệu này bổ sung [`.cursor/rules/project.mdc`](../.cursor/rules/project.mdc).
> Mục tiêu: **AI và dev mới đọc xong biết file đặt ở đâu, import từ đâu, tránh lỗi compile lặp lại** (thiếu import, type sai file, xóa code dở, l10n chưa gen).

---

## 1. Nguyên tắc vàng

| # | Quy tắc |
|---|---------|
| 1 | **Đọc file lân cận trước khi viết** — cùng feature đã có page tương tự (vd `teacher_calendar_page.dart`) thì copy pattern import/layout, không đoán. |
| 2 | **Widget dùng ở đâu → import đúng file định nghĩa** — tên giống nhau không có nghĩa cùng file (xem §3). |
| 3 | **Một page = một luồng rõ** — `Page` (route) → `View` (BlocBuilder) → widget con/private; logic nghiệp vụ trong BLoC, không `setState` cho data API. |
| 4 | **Không xóa class bằng cắt file** — luôn xóa cả class; nếu PowerShell/`truncate` dễ để sót `{` không đóng. |
| 5 | **Chuỗi UI → ARB** — thêm **cả** `app_en.arb` và `app_vi.arb`, rồi `flutter gen-l10n` (hoặc build app). |
| 6 | **Type domain** — entity/state class nằm ở `bloc/..._state.dart` hoặc `core/entity/`; file helper **phải import** file đó. |
| 7 | **Sau khi sửa** — chạy analyze ít nhất trên file vừa đổi; Hot Restart nếu đổi cấu trúc class. |

---

## 2. Cây thư mục `lib/feature/teacher/`

```
feature/teacher/
├── layout/                    # Shell, scaffold, widget dùng chung teacher web
│   ├── teacher_shell.dart       # Sidebar + child route
│   ├── teacher_page_scaffold.dart  # TeacherPageScaffold, TeacherKpiGrid, TeacherCardGrid
│   ├── teacher_web_ui.dart      # Token UI web: cardDecoration, button styles, typography
│   ├── teacher_widgets.dart     # TeacherKpiCard, TeacherListRow, TeacherFilterChip, …
│   ├── teacher_action_bar.dart  # TeacherRetryButton, TeacherFilledButton, …
│   ├── teacher_dashboard_layout.dart  # Panel dashboard, inbox card, quick actions
│   └── teacher_dashboard_queue_panel.dart
├── bloc/
│   └── {feature}/
│       ├── {feature}_bloc.dart
│       ├── {feature}_event.dart
│       └── {feature}_state.dart   # ← TeacherGradingQueueItem, enum status, …
├── teacher_dashboard_page.dart      # Route + BlocProvider + View mỏng
├── teacher_dashboard_overview.dart  # Body/layout dashboard (tách khỏi page)
├── teacher_dashboard_inbox_builder.dart  # Pure functions + enum filter inbox
├── teacher_inbox_page.dart
├── teacher_calendar_page.dart
└── …
```

**Quy ước đặt file mới**

| Loại | Đặt ở |
|------|--------|
| Màn có route (`static routePath`) | `teacher_{name}_page.dart` ngang `feature/teacher/` |
| Layout chỉ 1 màn, >150 dòng | `teacher_{name}_overview.dart` hoặc `teacher_{name}_view.dart` |
| Widget dùng ≥2 màn teacher | `layout/teacher_widgets.dart` hoặc `layout/teacher_{domain}_layout.dart` |
| Helper không UI (build list, parse) | `teacher_{domain}_builder.dart` / `teacher_{domain}_utils.dart` |
| BLoC | `bloc/{domain}/` — **không** nhét logic API vào page |

---

## 3. Bảng widget teacher — **file phải import**

> Lỗi hay gặp: dùng `TeacherKpiGrid` nhưng chỉ import `teacher_widgets.dart` (chỉ có `TeacherKpiCard`).

| Widget | File import |
|--------|-------------|
| `TeacherPageScaffold`, `TeacherBreadcrumb`, `TeacherKpiGrid`, `TeacherCardGrid`, `TeacherResponsiveColumns` | `layout/teacher_page_scaffold.dart` |
| `TeacherKpiCard`, `TeacherListRow`, `TeacherEmptyCard`, `TeacherFilterChip`, `TeacherStatusPill` | `layout/teacher_widgets.dart` |
| `TeacherWebUi` (styles, `cardDecoration`, `compactFilledStyle`, …) | `layout/teacher_web_ui.dart` |
| `TeacherRetryButton`, `TeacherFilledButton`, `TeacherOutlinedButton` | `layout/teacher_action_bar.dart` |
| `TeacherDashboardPanel`, `TeacherDashboardQuickActions`, `TeacherDashboardInboxCard`, `TeacherDashboardAttentionStrip` | `layout/teacher_dashboard_layout.dart` |
| `TeacherGradingQueueItem`, `TeacherDashboardState`, `TeacherDashboardStatus` | `bloc/dashboard/teacher_dashboard_state.dart` |
| `teacherDashboardExamTitleFromAssignment` (helper) | `bloc/dashboard/teacher_dashboard_derived.dart` |
| `buildTeacherDashboardInboxEntries`, `TeacherInboxFilter`, `openFirstTeacherClassroom` | `teacher_dashboard_inbox_builder.dart` |
| `AppCornerToast` | `core/ui/widget/app_corner_toast.dart` |
| `AppColors`, `AppSpacing`, `AppRadius` | `core/theme/app_color.dart`, `app_spacing.dart` |

**Cặp hay dùng cùng nhau**

```dart
import 'package:english_for_community/feature/teacher/layout/teacher_page_scaffold.dart'; // TeacherKpiGrid
import 'package:english_for_community/feature/teacher/layout/teacher_widgets.dart';       // TeacherKpiCard
```

---

## 4. Template page teacher (chuẩn dự án)

```dart
// teacher_example_page.dart
class TeacherExamplePage extends StatelessWidget {
  const TeacherExamplePage({super.key});

  static const String routePath = 'example'; // child của /teacher
  static const String routeName = 'TeacherExamplePage';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TeacherExampleBloc>()..add(const TeacherExampleLoadRequested()),
      child: const _TeacherExampleView(),
    );
  }
}

class _TeacherExampleView extends StatelessWidget {
  const _TeacherExampleView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<TeacherExampleBloc, TeacherExampleState>(
      listenWhen: (prev, curr) => curr.errorMessage != null && prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        final msg = state.errorMessage;
        if (msg != null) AppCornerToast.show(context, msg, error: true);
      },
      builder: (context, state) {
        final loading = state.status == TeacherExampleStatus.loading && state.items.isEmpty;
        final error = state.status == TeacherExampleStatus.error ? state.errorMessage : null;

        return TeacherPageScaffold(
          scrollable: false, // dashboard/calendar: false; list dài: true hoặc Expanded+ListView
          title: l10n.someTitle,
          body: loading
              ? const Center(child: AppLoadingIndicator.center())
              : error != null
                  ? Center(child: TeacherRetryButton(onPressed: () => ...))
                  : _ExampleBody(state: state),
        );
      },
    );
  }
}
```

**Checklist trước khi commit page mới**

- [ ] `routePath` / `routeName` static
- [ ] Route đăng ký trong `core/router/app_router.dart` (under `TeacherShell`)
- [ ] BLoC factory trong `core/get_it/get_it.dart`
- [ ] Import đủ widget (§3)
- [ ] Không hardcode string UI
- [ ] `scrollable: false` chỉ khi body có `Column` + `Expanded` — không nhồi `ListView` không giới hạn chiều cao

---

## 5. Routing (`go_router`)

Teacher routes nằm **trong** `ShellRoute` → `TeacherShell`:

```
/teacher                          → TeacherDashboardPage
/teacher/calendar                 → TeacherCalendarPage
/teacher/inbox                    → TeacherInboxPage
/teacher/inbox?filter=grading     → TeacherInboxPage(initialFilter: …)
/teacher/classroom/:classroomId   → TeacherClassroomDetailPage
```

**Helper location** (tránh nối chuỗi tay):

```dart
// Trong page class
static String location({TeacherInboxFilter filter = TeacherInboxFilter.all}) {
  if (filter == TeacherInboxFilter.all) return '${TeacherDashboardPage.routePath}/inbox';
  return '${TeacherDashboardPage.routePath}/inbox?filter=${filter.name}';
}
```

Đăng ký route con dùng `path: TeacherInboxPage.routePath`, **không** hardcode `'inbox'` rải rác.

---

## 6. BLoC & repository

```
UI → Event → BLoC → Repository (Either) → Datasource → API
```

- Repository **bắt buộc** `try/catch` → `Left(Failure)` / `Right(T)`.
- BLoC `emit` state mới; không `throw` ra UI.
- State class + item models (`TeacherGradingQueueItem`) đặt trong `*_state.dart`.
- Parse JSON trong BLoC private static hoặc `*_derived.dart` — không parse trong `build()`.

---

## 7. Localization

1. Thêm key vào `lib/l10n/app_en.arb` **và** `app_vi.arb`.
2. Chạy `flutter gen-l10n` (từ thư mục `english_for_community/`).
3. Dùng `context.l10n` hoặc `AppLocalizations.of(context)`.

**Không** sửa tay `lib/l10n/generated/*.dart` trừ khi tạm thời và sẽ gen lại ngay — file generated bị ghi đè.

---

## 8. Layout teacher web — tránh overflow

| Màn | Pattern |
|-----|---------|
| Dashboard, Calendar (month/week) | `TeacherPageScaffold(scrollable: false)` + `Column` + `Expanded` |
| Calendar list / Inbox | `Expanded` + `ListView` bên trong |
| KPI | `TeacherKpiGrid` + `TeacherKpiCard` |
| Panel co giãn | `TeacherDashboardPanel(expand: true)` — **không** `fillHeight: true` trong `Expanded` (cố định 360px gây overflow) |
| Hàng inbox | **Không** `SizedBox(height: 60)` cố định — để nội dung 2 dòng tự cao |

Tham chiếu: [`docs/ui-ux-system/17-teacher-dashboard-layout.md`](ui-ux-system/17-teacher-dashboard-layout.md), [`00-compact-density-v3.md`](ui-ux-system/00-compact-density-v3.md).

---

## 9. Tách trách nhiệm dashboard (ví dụ thực tế)

| Màn / file | Trách nhiệm |
|------------|-------------|
| `teacher_dashboard_page.dart` | Route, load BLoC, dialog tạo lớp/đề, scaffold header |
| `teacher_dashboard_overview.dart` | KPI + panel thống kê + quick actions (không list chấm bài) |
| `teacher_inbox_page.dart` | Danh sách việc cần làm (scroll được) |
| `teacher_dashboard_inbox_builder.dart` | `buildTeacherDashboardInboxEntries()` — dùng chung inbox + filter |
| `layout/teacher_dashboard_layout.dart` | Component tái sử dụng (panel, inbox card, legend) |

**Anti-pattern đã gặp**

- ❌ List chấm bài dài trên dashboard → overflow + scroll cả trang
- ❌ Import `teacher_widgets` tưởng có `TeacherKpiGrid`
- ❌ Dùng `TeacherGradingQueueItem` mà không import `teacher_dashboard_state.dart`
- ❌ Xóa `_LiveSessionCard` bằng cắt file → syntax error
- ❌ Hot reload sau khi đổi cấu trúc class → cần **Hot Restart**

---

## 10. Checklist cho AI agent (trước khi báo xong)

```
1. Grep tên class/widget vừa dùng → xác nhận file định nghĩa
2. Mở file tương tự (calendar_page) → so import
3. read_lints / flutter analyze trên file đã sửa
4. Không để class/constructor mở `{` không đóng
5. Route mới → app_router + location helper
6. String mới → cả en + vi ARB
7. get_it nếu thêm BLoC/repository
```

---

## 11. Tài liệu liên quan

| Tài liệu | Nội dung |
|----------|----------|
| [`.cursor/rules/project.mdc`](../.cursor/rules/project.mdc) | Stack, architecture tổng |
| [`ui-ux-system/11-implementation-mapping.md`](ui-ux-system/11-implementation-mapping.md) | Token → code, mapping component |
| [`ui-ux-system/07-web-components.md`](ui-ux-system/07-web-components.md) | Spec UI web teacher |
| [`ui-ux-system/17-teacher-dashboard-layout.md`](ui-ux-system/17-teacher-dashboard-layout.md) | Dashboard stats-only + inbox |
| [`teacher-exam-system/08-flutter-ui-specification.md`](teacher-exam-system/08-flutter-ui-specification.md) | Spec Flutter teacher rộng hơn |

---

*Cập nhật: 2026-05-31 — bổ sung sau refactor dashboard + inbox, sửa lỗi import `TeacherKpiGrid`.*
