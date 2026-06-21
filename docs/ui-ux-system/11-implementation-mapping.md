# 11 — Implementation mapping (Flutter)

> Ánh xạ token / component trong tài liệu sang code Flutter hiện có. Khi token thay đổi → cập nhật cả mã trong cùng PR.

## 1. Token → Code

### 1.1 Color (`lib/core/theme/app_color.dart`) — **Editorial Black**

> 🚨 **Big change:** brand chuyển từ teal `#0D9488` sang **đen `#0A0A0A`**. Mọi reference đến teal phải gỡ. Accent (amber) là **token riêng**, không phải `secondary` cũ.

| Doc token | Flutter |
|-----------|---------|
| `primary` (#0A0A0A) / `primaryDark` (#000000) / `onPrimary` (#FFFFFF) | `AppColors.primary` / `primaryDark` / `onPrimary` |
| `primaryTint` (rgba(10,10,10,.06)) | getter `AppColors.primaryTint` |
| `primaryStrong` (rgba(10,10,10,.10)) | getter `AppColors.primaryStrong` |
| `accent` (#F59E0B) / `accentDark` (#D97706) / `onAccent` (#1C1917) | `AppColors.accent` / `accentDark` / `onAccent` |
| `accentTint` (rgba(245,158,11,.14)) | getter `AppColors.accentTint` |
| `surface` | `AppColors.surface` (#FAFAF9) |
| `surfaceCard` | `AppColors.surfaceCard` (#FFFFFF) |
| `surfaceSubtle` | `AppColors.surfaceSubtle` (#F5F5F4) |
| `surfaceInverse` | `AppColors.surfaceInverse` (#1C1917) |
| `outline` / `outlineMuted` / `outlineStrong` | `AppColors.outline` (#E7E5E4) / `outlineMuted` (#F1F0EE) / `outlineStrong` (#D6D3D1) |
| `textPrimary` / `textSecondary` / `textMuted` / `textInverse` | `AppColors.textPrimary` / `textSecondary` / `textMuted` (#A8A29E) / `textInverse` |
| Semantic + bg | `success` / `warning` / `danger` / `info` + `successBg` / `warningBg` / `dangerBg` / `infoBg` (const colors, 50-tone) |
| Chart | `chartBar` (#0A0A0A — đen) / `chartHighlight` (#F59E0B amber) / `chartTrend` (#EF4444) / `chartGrid` (#E7E5E4) |
| Legacy alias | `AppColors.secondary` = `accent` (amber). Dần migrate gọi trực tiếp `AppColors.accent`. |

### 1.2 Typography — **Inter** (`app_fonts.dart`, `app_typography.dart`, `app_theme.dart`)

| File | Nội dung |
|------|----------|
| `AppFonts.fontFamily` | `'Inter'` |
| `AppFonts.fontFamilyIpa` | `'NotoSans'` |
| `AppTypography.mobileTextTheme` | Body 13/400, h2 14 AppBar, display 18 |
| `AppTypography.webTextTheme` | Body 13/400, pageTitle 16/600, kpi 15/600 tabular |
| `TeacherWebUi.webPageTitle` / `webKpiValue` | Page header & KPI (không dùng webH1 cho số) |
| `AppTheme.getTheme()` | **Luôn** `mobileTextTheme` — học sinh là mặc định toàn app |
| `AppTheme.mergeWorkspaceWeb(context)` | Gộp `webTextTheme` + input/button chữ cho vùng workspace |
| `WorkspaceLayoutScope(useWebDensity: …)` | `true` trong `TeacherShell` / `AdminShell` (+ apply web khi `kIsWeb`) |
| `AppTypography.useWebScale(context)` | `WorkspaceLayoutScope.isWebWorkspace(context)` — học sinh luôn `false` |
| `AppTypographyContext` | `context.bodyStyle`, `h2Style`, `useWebTypography` |
| `TeacherWebUi` / `AdminWebUi` | Delegate → `AppTypography.webTextTheme` |

**Mobile Material slots**

| Doc | Slot | Spec |
|-----|------|------|
| `body` | `bodyMedium` | 14 / **400** |
| `bodyLg` | `bodyLarge` | 16 / **400** |
| `h2` (AppBar) | `titleLarge` | 16 / **600** |
| `h3` | `titleMedium` | 14 / **600** |
| `h1` | `headlineMedium` | 18 / **600** |
| `display` | `displaySmall` | 22 / **700** |

**Web Material slots (v3)**

| Doc | Slot | Spec |
|-----|------|------|
| `web.body` | `bodyMedium` | 13 / **400** |
| `web.pageTitle` | `headlineMedium` | 16 / **600** |
| `web.h2` | `titleLarge` | 14 / **600** |
| `web.kpi` | `AppTypography.kpiValue` | 15 / **600** tabular |

### 1.3 Spacing & radius

Thêm `lib/core/theme/app_spacing.dart` (mới):

```dart
abstract final class AppSpacing {
  static const double s1 = 2;
  static const double s2 = 4;
  static const double s3 = 8;
  static const double s4 = 12;
  static const double s5 = 16;
  static const double s6 = 20;
  static const double s7 = 24;
  static const double s8 = 32;
  static const double s9 = 40;
  static const double s10 = 56;
  static const double s11 = 80;
}

abstract final class AppRadius {
  static const double chip = 6;
  static const double input = 10;
  static const double card = 12;
  static const double sheet = 16;
  static const double pill = 999;
}
```

### 1.4 Motion

Thêm `app_motion.dart`:

```dart
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 180);
  static const page = Duration(milliseconds: 220);
  static const web = Duration(milliseconds: 160);
  static const celebrate = Duration(milliseconds: 380);
}
```

## 2. ExamSystemUi refactor

`lib/core/ui/exam_system_ui.dart` — nhiều style cứng giờ phải hợp với token mobile:

- `hPadding` 24 → **16** (mobile). Web teacher dùng helper riêng (`webHPadding = 32`).
- `cardGap` 10 → **12**.
- `blockGap` 14 → **16**.
- `sectionGap` 28 → **24** (mobile) / **32** (web).
- `cardRadius` 14 → **12**.
- `sectionTitle` size 13 → giữ; **đổi color** từ `textSecondary` → `textPrimary`.
- `listTitle` size 15 → **14**.
- `questionStem` size 15 → **14**.
- `captionSecondary` color textSecondary chỉ dùng cho meta; **không dùng cho body**.
- `embeddedBodyStyle` color textSecondary → **textPrimary**.

## 3. Component code mapping

| Doc component | File hiện có | Hành động |
|---------------|--------------|-----------|
| **Web form wizard (§7.4)** | `feature/teacher/layout/teacher_web_ui.dart` | `formFieldLabel`, `formInputDecoration`, `formInputContentPadding`, `segmentedControlStyle` — dùng cho màn nhiều section (giao bài, …) |
| Button (Filled / Outlined / Text) | `app_theme.dart` | Padding/height đã ổn nhưng `padding` 14 → **12** dọc cho mobile (h 48 chuẩn) |
| Card | `core/ui/widget/app_card.dart` | Đổi `radius` mặc định 16 → **12**; `elevated` shadow nhẹ hơn `e.1` thay vì `0x1A000000`; outline border 0.5 → **1** |
| Navigation bar | `core/ui/widget/app_navigation_bar.dart` | Height 60dp, `primaryTint` indicator, `surfaceCard` bg |
| **Student mobile UI** | `core/ui/student_mobile_ui.dart` | Section header, appBar, skillAppBar, skillAccentCard, skillIconBox, skillProgressBar, skillHubBanner, quickActionButton, statCard, bottomActionBar, mcqOption, filterChip/filterRow, streakChip, StudentBottomSheet, StudentDialogShell |
| **Skill palette** | `core/theme/app_skill_colors.dart` | `SkillType`, `SkillColorSet`, `AppSkillColors.of(skill)` — Listening/Speaking/Reading/Writing/Vocabulary |
| Skeleton | `core/ui/widget/app_skeleton.dart` | Đảm bảo dùng gradient `outlineMuted ↔ outline` |
| Chip / status pill | chưa có file riêng | Tạo `core/ui/widget/app_chip.dart` với 3 variant: `filter`, `tag`, `status` |
| **Live participant status** | `teacher_exam_session_console_page` (ready only lobby) | `TeacherExamParticipantStatusChip` — [`16`](16-teacher-live-participant-status.md); dùng cả Session control + Live monitor |
| MCQ review tile | `feature/student/exams/exam_answer_review_widgets.dart` | Đổi border 1.25 → **1**, padding 12 → **14**, text 14/500 → **14/400 textPrimary** (giữ semantic fg) |
| Grading footer | cùng file | Label 13/600 textPrimary; ô input height **48 mobile / 36 web** (truyền qua param) |

## 4. Refactor list cụ thể (PR plan đề xuất)

### PR 1 — Tokens
1. Thêm token mới: `surfaceSubtle`, `surfaceInverse`, `outlineStrong`, `danger`, `info`, `*Bg`, `primaryTint`, `primaryStrong`.
2. Đổi `textMuted` → `#A8A29E`.
3. Tạo `app_spacing.dart`, `app_radius.dart`, `app_motion.dart`.

### PR 2 — Typography
1. Cập nhật `app_theme.dart` `baseText` theo spec ở §1.2.
2. Đổi `bodyMedium` color về `textPrimary`.
3. Sửa `AppTypography.body` mặc định color `textPrimary`.

### PR 3 — ExamSystemUi
1. Sửa numeric tokens (hPadding, cardGap, …).
2. Đổi color caption styles trong embedded panel sang `textPrimary` cho body.
3. Thêm `webHPadding = 32`, `webCardGap = 16`.

### PR 4 — AppCard / Skeleton / Chip
1. Card: radius 12, border 1px, shadow theo `e.0/e.1`.
2. Skeleton: shimmer 1.4s, gradient mới.
3. Tạo `AppChip` 3 variant.

### PR 5 — Touch-up các màn nóng
- Reading detail, exam runner, vocabulary review: thay `textSecondary` body → `textPrimary`.
- Profile, home: dùng `body 14/400 textPrimary` thay vì 15.

### PR 6 — Web specifics
- Sidebar `core/layout/web_sidebar.dart` (mới).
- `web_page_header.dart`, `web_data_table.dart` skeleton classes.

## 5. Migration log

> Khi xoá / đổi token, ghi vào đây với commit hash & ngày.

| Ngày | Thay đổi | Commit |
|------|----------|--------|
| 2026-05-16 | Khởi tạo bộ doc UI/UX mới (mobile + web split) | _(this PR)_ |
| 2026-06-14 | Teacher web remediation (`18-teacher-web-audit`): token sweep, skeleton, sticky gradebook, save-state editors, inline validate, focusableTile, empty CTA | _(pending commit)_ |
| 2026-06-21 | Student chat reverse list + scroll polish (`22-student-chat-scroll-and-conversation-list` §3A) | `eca074e` |
| 2026-06-21 | Student conversation list redesign — shared ConversationTile web+mobile (`23`) | `0c9ac90`, `9ed4cfb`, `503bc2b`, `66d05fb`, `c478cb9` |
| 2026-06-21 | Teacher live mirror — full-height shell (`24` §S1) | `b8b80ac` |
| 2026-06-21 | Teacher live mirror — active-section question map + collapse (`24` §S2) | `146910b` |

## 5.1 Teacher dialogs (`14-teacher-dialogs.md`)

| Doc | Flutter |
|-----|---------|
| `TeacherDialogShell` | `lib/feature/teacher/layout/teacher_dialog_shell.dart` |
| `TeacherDialogs.*` | `lib/feature/teacher/layout/teacher_dialogs.dart` |
| Account hub | `teacher_account_menu.dart` → `showTeacherAccountMenu` |
| Edit profile modal | `teacher_edit_profile_dialog.dart` (teacher only; student: `EditProfilePage`) |
| Change password modal | `teacher_change_password_dialog.dart` |
| Assign exam modal | `teacher_assign_exam_dialog.dart` → `TeacherDialogs.showAssignExam` |
| Edit assignment modal | `teacher_edit_assignment_dialog.dart` |
| Corner toast | `teacher_corner_toast.dart` |
| Footer actions | `TeacherDialogFooterActions` — `compactOutlinedStyle` + `compactFilledStyle` |
| Grading hub context card | `teacher_grading_hub_context_header.dart` |
| Grading hub labels (mode/format/schedule) | `teacher_grading_hub_labels.dart` |
| Grading hub page | `teacher_exam_grading_page.dart` + `teacher_assignment_grading_hub_view.dart` |

## 5.2 Teacher dashboard v4 (`17-teacher-dashboard-layout.md`)

| Doc | Flutter |
|-----|---------|
| Dashboard page | `lib/feature/teacher/teacher_dashboard_page.dart` |
| Dashboard body (stats-only) | `lib/feature/teacher/teacher_dashboard_overview.dart` |
| Inbox / action queue page | `lib/feature/teacher/teacher_inbox_page.dart` |
| Inbox entry builder | `lib/feature/teacher/teacher_dashboard_inbox_builder.dart` |
| Layout primitives | `lib/feature/teacher/layout/teacher_dashboard_layout.dart` |
| Queue / live panels (dialog) | `lib/feature/teacher/layout/teacher_dashboard_queue_panel.dart` |
| **KPI grid** | `lib/feature/teacher/layout/teacher_page_scaffold.dart` → `TeacherKpiGrid` |
| **KPI card** | `lib/feature/teacher/layout/teacher_widgets.dart` → `TeacherKpiCard` |
| Dashboard BLoC | `lib/feature/teacher/bloc/dashboard/teacher_dashboard_bloc.dart` |
| Grading queue item type | `lib/feature/teacher/bloc/dashboard/teacher_dashboard_state.dart` → `TeacherGradingQueueItem` |

> **Import:** file dùng cả grid + card cần **hai** import: `teacher_page_scaffold.dart` và `teacher_widgets.dart`. Xem [`flutter-coding-structure.md`](../dev/flutter-coding-structure.md) §3.

## 6. Lint / guardrail tự động

Đề xuất bổ sung `dart_code_metrics` rules:

```yaml
prefer_no_color_literals:
  exclude_files:
    - "lib/core/theme/app_color.dart"
prefer_no_text_color_textSecondary:
  description: "Body text must use textPrimary."
```

(Implement bằng custom lint hoặc grep-based PR check ban đầu.)

## 7. Mobile vs Web detection

- Trong app Flutter cùng codebase, dùng `MediaQuery.sizeOf(context).width >= 1024 && kIsWeb` để quyết định layout web.
- Hoặc widget riêng `core/layout/responsive_scope.dart` exposing `isWebDense` cho widget bên dưới chọn token.
- KHÔNG đặt 2 layout chen vào 1 widget — tách `Mobile…Page` vs `Web…Page` qua `LayoutBuilder` + `if/else` ở entry route.
