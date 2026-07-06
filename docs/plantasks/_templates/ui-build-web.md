# Template — XÂY UI TEACHER/ADMIN WEB (E4C)

> Template để **dựng/redesign 1 màn web** (teacher/admin) đúng compact density v3 + Editorial Black, đủ perf + a11y + save-state + destructive-guard.
> Nguồn sự thật: `docs/ui-ux-system/{00,06,07,08,13,14,17,18,19,21}` (doc thắng nguyên tắc) + code `TeacherWebUi`/`AdminWebUi` (chốt SỐ density).
> Cách dùng: đọc **A. Standards** → điền **B. Build-spec** → soi **C. Perf** → tick **D. Pre-ship** → nối **E. Handoff**.
> Task student mobile → `ui-build-mobile.md`. Kick-off nhanh → `uiux-layout-prompt.md`.
>
> ⚠️ **DRIFT doc↔code:** vài ASCII cũ trong `06/07` còn ghi số **v2** (top bar 56, sidebar 240, table row 44) — **SAI**. Số CHỐT lấy từ code `TeacherWebUi` (top bar 44, sidebar 212, row 40). `00` ghi page padding 20×14 nhưng code = **20×16** → theo code.
> ⚠️ **Teacher = bộ chuẩn đầy đủ nhất.** `AdminWebUi` là bản nhân bản HẸP hơn (thiếu nhiều helper) — xem §B7 Admin-delta.

---

## A. STANDARDS — BẤT DI

### A0. 4 nguyên tắc lõi (web)
1. **Editorial Black.** Brand = đen `#0A0A0A` (`AppColors.primary`) — filled button/chevron/link/logo đều đen, KHÔNG teal/indigo. Body mặc định đen `#1C1917`, weight w400, chỉ w600 cho tiêu đề/nhãn. **Amber `#F59E0B` chỉ celebrate** (streak/KPI nổi/chart highlight) — không tô heading. **Skill color KHÔNG dùng cho teacher/admin** (chỉ student).
2. **Token-only.** Màu→`AppColors`/`AppScoreScale`/`AdminStatusPalette`; radius→`AppRadius`; spacing→`AppSpacing`; alpha→overlay token (`hoverOverlay`/`pressOverlay`/`focusRing`/`scrim`/`shadowCard`); duration→`AppMotion`. `Color(0x…)`/radius-literal/`Duration(ms:N)` trong `lib/feature/{teacher,admin}/**` = **reject** (CI `tool/ui_audit.sh`).
3. **Server là sự thật → 4 states** (loading=skeleton đúng khung · empty+CTA · error · success) + **save-state** cho editor.
4. **Tái dùng, không dựng lại.** `TeacherWebUi`/`AdminWebUi` + `TeacherPageScaffold` + `TeacherSkeleton`. Cấm fork (`content_widgets`/`ShadcnCard`/`kBgPage`).

### A1. COLOR TOKENS — `AppColors` (chung với mobile, `lib/core/theme/app_color.dart`)
Editorial Black + warm stone (verbatim): `primary #0A0A0A` · `primaryDark #000000` · `onPrimary #FFFFFF` · `accent #F59E0B` (celebrate-only) · `surface #FAFAF9` (bg main) · `surfaceCard #FFFFFF` (sidebar/card) · `surfaceSubtle #F5F5F4` (hover row) · `outline #E7E5E4` · `outlineMuted #F1F0EE` · `outlineStrong #D6D3D1` · `textPrimary #1C1917` · `textSecondary #57534E` (meta) · `textMuted #A8A29E` (placeholder/disabled). Semantic: `success #16A34A` · `warning #D97706` · `danger #DC2626` (tên là **danger**) + `successBg #ECFDF5`/`warningBg #FFFBEB`/`dangerBg #FEF2F2`/`infoBg #EEF2FF`. Overlay: `primaryTint` đen@6% (active/selected row) · `primaryStrong` @10% · `hoverOverlay` @4% (row hover) · `pressOverlay` @8% · `focusRing`=primary · `scrim 0x66000000` · `shadowCard 0x0A000000`. `chartBar #0A0A0A`, `chartHighlight #F59E0B`.
**Score scale** `AppScoreScale`: fail(`danger`,<4) · weak(`#EA580C`,4–5.5) · mid(`warning`,5.5–7) · good(`#65A30D`,7–8.5) · strong(`success`,≥8.5) → `forScore10(x)`. **Hợp nhất mọi "xanh đạt" về 1 nguồn.**
**Admin status** `AdminStatusPalette` (`lib/core/theme/admin_status_palette.dart`): pending→warning · approved/published→success · rejected→danger · scheduled→info · archived→surfaceSubtle/textSecondary; priority high→danger/med→warning/low→success. Resolvers: `releaseStatusBg/Fg(status)`, `priorityBg/Fg(level)`, `csvSemanticColors(raw)`.

### A2. DENSITY WEB (compact v3) — code `TeacherWebUi`/`AdminWebUi` là CHỐT
| Token | Giá trị | | Token | Giá trị |
|---|---|---|---|---|
| `sidebarWidth` | **212** | | `buttonHeightPrimary` | **32** |
| `sidebarCollapsedWidth` | **48** (icon rail) | | `buttonHeightSecondary` | **28** |
| `topBarHeight` | **44** | | `inputHeight` | **32** |
| `pageHeaderMinHeight` | **52** | | `tableRowDefault` | **40** |
| `sidebarItemHeight` | **30** | | `tableRowCompact` | **32** |
| `minFallbackWidth` | **768** (dưới→fallback) | | tableRow comfortable | **52** |
| `sidebarExpandedMinWidth` | **1024** | | | |
`pagePadding` = `symmetric(h: s6/*20*/, v: s5/*16*/)` · `pageHeaderPadding` = `fromLTRB(20,16,20,12)` · `formInputContentPadding` = `symmetric(10,8)`.
**Content max-width theo loại màn:** Form/settings **720** (`contentMaxForm`) · Editor **960** (`contentMaxEditor`) · Dashboard/analytics **1120** (`contentMaxDashboard`) · Data table full **1280** (`contentMaxTable`).
**Radius:** card=`AppRadius.card`(10) · button/input=`AppRadius.input`(8) · dialog shell hard-code **16** (lệch token `sheet`=14 — biết để raise). **Grid:** 12 cột, gutter 24, margin 32; card grid `minmax(280,1fr)`.

### A3. TYPOGRAPHY WEB — `AppTypography` (font Inter)
`webBody`=13/400 (**default**) · `webBodyLg`=15 · `webH3`/`listTitle`=13/600 (card/list title) · `webH2`=14/600 · `webPageTitle`=16/600 (page title) · `webKpiValue`=15/600 tabular (KPI) · `webDisplay`=18/700 · `webCaption`=11/400 (meta) · `webLabel`=11/600 (button/chip) · `webTableHead`=11 letterSpacing 0.4 textSecondary · `sectionTitle`=11 letterSpacing 0.35 w600 textSecondary. **Cấm:** `webH1`/`headlineMedium` cho số KPI (dùng `webKpiValue`); `fontSize:14+` hardcode cho body (dùng `webBody` 13); textSecondary/textMuted cho body chính.

### A4. RULE UX bắt buộc (web)
- **Loading = skeleton đúng khung** (`TeacherSkeleton.kpiGrid/table/cardList`), KHÔNG spinner toàn vùng (cấm `AppLoadingIndicator.center`).
- **Lỗi field = inline `danger` dưới ô** (`formFieldError`), validate on blur→on change; toast chỉ cho lỗi mạng/máy chủ.
- **Focus-visible toàn cục:** mọi phần tử tap được bọc `focusableTile` → ring 2px `focusRing` khi Tab + hover/press.
- **Save-state machine** cho editor: `idle → saving → saved → error`, debounce 1.5–2s, giữ nháp local khi mất mạng.
- **Destructive:** phá huỷ thường (xoá member/đóng phiên) = `compactDangerOutlinedStyle` + confirm 480 + body hệ quả. **Không thu hồi** (Phát hành kết quả, Kết thúc & nộp tất cả, Rollback release, FORCE-publish) = **filled danger + banner hệ quả + gõ xác nhận** (số HS). Reversible (Release results) = banner cảnh báo `warningBg`, KHÔNG nút đỏ.
- **Bảng:** header + cột đầu sticky khi cuộn ngang; số/điểm/tiền căn phải tabular; >100 hàng → `ListView.builder`/pagination; hover row `surfaceSubtle`, selected `primaryTint`; status → status pill (KHÔNG tô cả row).
- **Điều hướng:** go_router path-URL (`configureWebUrlStrategy`), mỗi màn 1 path; tránh `Navigator.push(MaterialPageRoute)` cho màn chính.

---

## B. BUILD-SPEC — điền cho MÀN

**Màn:** `<tên>` · **File:** `lib/feature/{teacher|admin}/<...>.dart` · **Loại màn:** `<dashboard|table|form|editor|dialog|live-console>` · **Role:** `<teacher|admin>` · **Màn anh-em tham chiếu:** `<...>`

### B1. LAYOUT ANATOMY
`Sidebar(212/48) → Top bar(44, sticky) → Page header(52 min: breadcrumb → title 16/600 → actions 32 → meta-row) → Content(max theo loại màn, centered/left)`. Bọc bằng `TeacherPageScaffold`. Sidebar: item 30h icon 18, active `primaryTint`+`primaryDark 13/600`. Top bar: breadcrumb trái, search global (admin) giữa mở Cmd+K, notif+avatar phải.

### B2. BREAKPOINTS + max-width
| Width | Hành vi |
|---|---|
| < **768** | teacher → mobile shell (`TeacherMobileUi`, bottom nav 60); admin → "dùng desktop" |
| 768–1023 | sidebar **collapse** icon rail 48 |
| 1024–1279 | sidebar full, content max **960** |
| 1280–1599 | content max **1120** (+ aside) |
| 1600+ | content max **1280**, aside 320 |

### B3. Chọn LOẠI MÀN + build-with
| Loại | Khung | max-width | Build-with (THẬT) |
|---|---|---|---|
| **Dashboard** (`17`) | KPI grid **4 ô** + panels; **không** list chấm/live (→ Inbox route `/teacher/inbox`) | 1120 | `TeacherKpiGrid`, `TeacherDashboardPanel(fillHeight=340)`, `AttentionStrip`, `TeacherCardGrid`(min 280), `TeacherSkeleton.dashboard()` |
| **Data table** (`07 §2`,`18 §5.5`) | toolbar 56 → header(11/600 uppercase) → rows 40/compact 32 → footer pagination | 1280 | `DataTable`+`_PaginationBar`, `panelDecoration`, sticky header+col1, `TeacherSkeleton.table(rows:6)` |
| **Form/settings** (`07 §7`) | label-trên-ô + section card 24 + save bar sticky | 720 | `formFieldLabel`+`formInputDecoration`, `segmentedControlStyle`, `formFieldError`, CTA cuối Filled 48 |
| **Editor** (`07 §13`) | 2 cột 640/480 + toolbar 40 + save-state | 960 | drawer 720, `cardDecoration`, save-state machine |
| **Dialog** (`14`) | `TeacherDialogShell` (icon40+title h2+×18) → body scroll → footer 32 | 480/560/640 | `TeacherDialogShell.show(context, child:)`, `choiceTileDecoration`, `TeacherDialogFooterActions(destructive?)` |
| **Live console** (`13`) | **tabs-first**: TabBar ngay dưới header → TabBarView `Expanded`; metadata `CompactStrip` mặc định đóng; toolbar ~56 + list HS scroll | full | `TeacherExamSessionConsolePage`, `TeacherExamSessionCompactStrip`, `TeacherExamParticipantStatusChip` |

### B4. ZONES (điền)
| Zone | Nội dung | Token/widget | Ghi chú |
|---|---|---|---|
| `<...>` | `<...>` | `<...>` | `<...>` |

### B5. STATES (điền đủ) — Loading `TeacherSkeleton.<kpiGrid/table/cardList/dashboard/calendar/analytics>` · Empty `<TeacherEmptyCard + action Filled 32>` · Error `<inline/banner + retry>` · Success · Save-state (editor).

### B6. WIDGET QUICK-REF — `TeacherWebUi` (signature thật, `lib/feature/teacher/layout/teacher_web_ui.dart`)
- Layout: `pagePadding` · `pageHeaderPadding` · `pageScrollPadding(context)` · `pagePaddingFor(context)`
- Surface: `cardDecoration({bg})` (elevated: dialog/popover/floating) · `panelDecoration({bg})` (**flat list/dashboard** — dùng cái này trong list cuộn) · `cardShadow` (1 lớp blur 6)
- Typography (context): `webPageTitle` · `webH2` · `webH3`/`listTitle` · `webKpiValue` · `webBody`/`webBodyLg` · `webLabel` · `webCaption` · `webTableHead` · `webBreadcrumb` · `sectionTitle` · `metaMuted`
- Form: `formFieldLabel(context, text)` · `formControlLabelStyle(context)` · `formInputDecoration(context, {hintText})` · `formInputContentPadding` · `formFieldError(context, msg)`
- Button: `compactFilledStyle` · `compactOutlinedStyle` · `compactDangerOutlinedStyle` · `compactHeaderIconStyle` · `headerIconButton({context, icon, onPressed, tooltip?})` · `linkActionStyle` (inline table action)
- Choice/segment: `choiceTileDecoration({selected})` · `choiceTileTitleColor/IconColor/IconBoxColor({selected})` · `segmentedControlStyle`
- A11y: `focusableTile({child, onTap, borderRadius?, tooltip?, semanticLabel?})` — **bọc MỌI phần tử tap được**
- Avatar: `networkAvatar(url, {logicalSize})` (decode tại display size) · `userAvatarCircle({avatarUrl, displayName, radius})`
- Scaffold: `TeacherPageScaffold({title, body, subtitle?, breadcrumbs, actions, maxWidth, scrollable, showBack, bottomActions?})` — ⚠️ **KHÔNG lồng ListView trong SingleChildScrollView** (vỡ hit-test); `scrollable:false` khi body tự scroll (list dài).
- Grids: `TeacherKpiGrid` · `TeacherCardGrid` (min 280) · `TeacherResponsiveColumns`
- Skeleton: `TeacherSkeleton.kpiGrid({count:4})` · `.table({rows:6})` · `.cardList({n:3,height:76})` · `.dashboard()` · `.calendar()` · `.analytics()` · `.page(child)`
- Dialog: `TeacherDialogShell.show<void>(context, child:…)` / `TeacherDialogs.showEditProfile(context)` — width 480 (hub 440, profile 520, assign 560), radius 16, close 18, footer 32.

### B7. ADMIN-DELTA (`AdminWebUi`, `lib/feature/admin/layout/admin_web_ui.dart`)
Nhân bản teacher **cùng dimension/typography/button**, nhưng KHÁC/THIẾU:
- `cardShadow` = **2 lớp** (blur 12 + blur 1) — nặng hơn teacher (còn hex-literal, doc `19 §3.1d`).
- `formInputDecoration` radius `AppRadius.input` (teacher dùng `.card`) + **KHÔNG có errorBorder**.
- **THIẾU** (dùng pattern teacher hoặc bù): `linkActionStyle`, `choiceTile*`, `segmentedControlStyle`, `compactDangerOutlinedStyle`, `headerIconButton`, `webBodyLg`, `listTitle`-alias.
- **CÓ:** `focusableTile`, `formFieldError`, `formInputDecoration`, `compactFilledStyle/OutlinedStyle/HeaderIconStyle`, `cardDecoration/panelDecoration`, `AdminSkeleton.*`, `AdminStatusPalette`.
- Nợ kỹ thuật admin (audit 6.1/10): gỡ fork `content_widgets` (`kBgPage/ShadcnCard/ShadcnInput`), tokenize ~304 hex, thay 29 spinner bằng `AdminSkeleton`, nối search/filter thật hoặc ẩn, rollback/reject destructive-guard.

---

## C. PERF GATE (web) — doc `21`, 3 tầng. Đo: `flutter run -d chrome --profile` → DevTools Performance (raster <16ms), Highlight repaints, Track widget builds; Network waterfall; Mongo `explain()`.

**Render/scroll:**
- Card trong list cuộn dùng `panelDecoration()` (**phẳng, không blur**); chỉ KPI strip + dialog giữ shadow (blur 6, 1 lớp).
- Hover: đổi nền `hoverOverlay` qua decoration (**không** `AnimatedScale`+setState); tắt hover khi đang cuộn (`NotificationListener<ScrollNotification>` + debounce ~120ms).
- `RepaintBoundary` mỗi card/section/row (mẫu `teacher_assignment_grading_hub_view.dart:247`); list dài → `ListView.builder`/`SliverList`, KHÔNG `SingleChildScrollView+Column`.
- Animation vĩnh viễn (`livePulse .repeat()`) chỉ animate dot 8px + `RepaintBoundary` + pause khi cuộn/ngoài viewport.
- Avatar/ảnh có `cacheWidth`/`memCacheWidth`.

**Data/rebuild (Flutter):**
- `_bootstrap` nhiều API độc lập → **`Future.wait([...])`** (không await tuần tự).
- `BlocBuilder` có `buildWhen`/`BlocSelector` (không rebuild cả trang vì `searchQuery`).
- Parse/sort/filter đẩy vào **Bloc** (emit `filteredRows`/`chartPoints` typed); KHÔNG parse `Map<String,dynamic>` trong `build()`.
- Memo `barGroups`/filter theo identity data; item động có `key: ValueKey(id)`; `const` cho tile tĩnh.

**Backend (Express + Mongoose):**
- Khử N+1: batch bằng `$in` + `Promise.all` → nạp `Map`, loop đọc từ Map (0 query); batch grading fetch 1 lần + `updateMany`.
- **Index** (verify `explain()` thấy `IXSCAN` không `COLLSCAN`): `ExamAttempt {assignmentId,status}`/`{assignmentId,submittedAt:-1}`/`{sessionId,userId,status}`/`{status,attemptDeadlineAt}`; `ExamAssignment {classroomId,audience,status}`.
- `.lean()` cho query chỉ-đọc; populate projection (`populate('examId','title settings')` — loại `sections`); analytics gộp `$facet`+`Promise.all`; list lớn có pagination.

---

## D. PRE-SHIP CHECKLIST (gộp audit `18 §7` teacher / `19 §7` admin + perf `21 §6`)

**Token & UX (mọi màn web):**
- [ ] Không `Color(0x…)` / `BorderRadius.circular(N)` / `Duration(ms:N)` trong `lib/feature/{teacher,admin}/**` (token-only).
- [ ] Loading = **skeleton** đúng khung (không spinner toàn vùng); empty có **CTA**.
- [ ] Lỗi field = inline `danger` dưới ô (`formFieldError`), không toast.
- [ ] Editor có **save-state** (idle/saving/saved/error).
- [ ] Destructive không-thu-hồi = **filled danger + banner hệ quả + gõ xác nhận**; reversible = banner warning không nút đỏ.
- [ ] Mọi phần tử tap được có **focus ring 2px** (Tab + hover/press) qua `focusableTile`.
- [ ] Bảng: header + cột đầu sticky; số căn phải tabular; >100 hàng phân trang/`builder`.
- [ ] "Xanh đạt" về 1 nguồn `AppScoreScale`; status admin qua `AdminStatusPalette`.
- [ ] (Admin) không còn fork `content_widgets`; search/filter nối API thật hoặc ẩn; status pill có `Semantics`.

**Perf (`21 §6`):**
- [ ] Render: raster <16ms khi cuộn; repaint chỉ card mới; card list phẳng (`panelDecoration`); hover không bắn khi cuộn; list dài đã builder/Sliver.
- [ ] Data: `_bootstrap` `Future.wait`; `buildWhen`/`BlocSelector`; parse/sort ở Bloc; item `ValueKey`.
- [ ] Backend: hết vòng lặp `await find` (đã `$in`+Map/aggregation); index đã thêm (`explain()` IXSCAN); readonly `.lean()`; populate không kéo `sections`; list lớn pagination.

**Cổng verify (chạy, dán kết quả):**
```bash
cd english_for_community/english_for_community
bash tool/ui_audit.sh teacher --list      # (hoặc admin) 4 pattern → 0 (trừ whitelist)
dart analyze lib                            # 0 lỗi mới
flutter gen-l10n                            # nếu thêm string
```
- [ ] L10n đủ **EN + VI**. Hồi quy **1280×800** + fallback **768**. Áp pattern mới → ghi `11-implementation-mapping.md`.

---

## E. HANDOFF → nối vào work-order

Viết work-order theo `work-order.md`: **§5 CONTEXT BUNDLE** từng touch-site (anchor + BEFORE/AFTER + symbol) + **SYMBOL TABLE** liệt kê token/helper `TeacherWebUi`/`AdminWebUi` dùng (verbatim từ §A/§B6, đánh dấu [CÓ]/[THÊM]). Handoff theo `handoff-cursor.md` (BƯỚC 0 đọc work-order). Đính kèm: loại màn + màn anh-em tham chiếu, ZONES(B4)+STATES(B5) đã điền; pre-ship §D = tiêu chí nghiệm thu; verify §D = §7 work-order; GATE = UI/UX(§A/§B/§D) + Perf(§C) + Backend (nếu chạm query/index — §C backend).
