# Tracker — 20260711-web-list-to-table

| Field | Value |
|-------|-------|
| **Status** | **AUDITED + PATCHED** — ✅ APPROVED (P0–P3). F1–F7 đã xử lý (Opus, 2026-07-11). `dart analyze` touched files = No issues |
| **Loại / Cỡ** | FEATURE · T2 (teacher + admin web) |
| **Người phân tích** | Opus (2 sub-agent scout + Opus verify #1 user_card / grading attempt) |
| **Implementer** | Codex |
| **Date** | Audit 2026-07-11 |

## Phạm vi (audit 2 scout)
- **Convert:** teacher T1 grading hub · T2 exams list · T3 inbox. Admin A1 users · A2 submissions · A3 reports · A4–A8 content(5) · A9 releases.
- **Cleanup:** A10 Ops Center (`_PaginationBar` private → `AdminPaginationBar`).
- **KEEP:** live monitor · session console roster · calendar · dashboards.
- **ALREADY:** classroom_detail (mẫu) · gradebook · analytics.

## Quyết định chốt
- **KHÔNG có bảng dùng chung** → **P0: tạo `lib/core/ui/widget/web_data_table.dart`** (trích từ classroom_detail bespoke), rồi mọi màn nhái. Reuse: `*WebUi.panelDecoration/webTableHead/userAvatarCircle`, `*Skeleton.table`, `AdminPaginationBar`, status pills, action menus.
- Action dồn vào **⋯ menu** mỗi row; row-tap = hành động chính; số căn phải tabular; kẻ dọc `outlineMuted`.

## Phase (leverage order — chi tiết §5 work-order)
| Phase | Nội dung | Trạng thái |
|---|---|---|
| P0 | `WebDataTable` primitive + refactor classroom_detail dùng lại | ☑ xong |
| P1 | Teacher: grading hub · exams list · inbox | ☑ xong |
| P2 | Admin: users · submissions · reports · content×5 · releases | ☑ xong |
| P3 | Admin: Ops Center pagination cleanup | ☑ xong |

## Verify mỗi phase
```
cd english_for_community/english_for_community
bash tool/ui_audit.sh teacher --list
bash tool/ui_audit.sh admin --list
dart analyze lib
flutter gen-l10n   # nếu thêm header string
```
Smoke §7 work-order + account test `docs/dev/seeds/`.

## Opus audit (Phase 4) — 2026-07-11 (5 sub-agent + Opus verify)
- P0: [x]  P1: [x]  P2: [x]  P3: [x]
- **Verdict: ✅ APPROVED** (merge-ready). Không có MAJOR, không dropped action, không sai alignment, không đổi bloc/event/state/entity/query. Destructive guard (releases) NGUYÊN VẸN. KEEP-list KHÔNG bị đụng. l10n EN/VI parity. `dart analyze lib` = 0 lỗi (169 info style cũ, không phải file bảng). `ui_audit teacher/admin` = 0 hex/0 radius (2-3 duration literal đều ở dashboard/motion ngoài scope).

### Checklist §9
- [x] P0 `WebDataTable` đúng API §3.1; classroom_detail ĐÃ refactor dùng lại (1 nguồn — bespoke `_AssignmentRow`/`_MemberTableRow`/`_vCellDivider` đã xoá, chỉ còn wrapper trả `WebDataTable`).
- [x] Mỗi màn: cột đúng §5, kẻ dọc/ngang thẳng (header+row chung `_buildCells`), số căn phải tabular, status = pill (không tô row), hover `surfaceSubtle`.
- [x] Data/bloc/toolbar/search/filter/pagination KHÔNG đổi; skeleton = table; empty/error đủ.
- [x] Action dồn trong ⋯; row-tap đúng; grading Open/AI/Release + users ban/role + releases destructive-guard còn nguyên.
- [x] Token-only; ui_audit teacher+admin = 0; dart analyze 0 lỗi mới; l10n EN+VI.
- [x] KEEP-list (live/console/calendar/dashboard) KHÔNG bị đụng (grep `WebDataTable` = 13 file, 0 keep-list).
- [x] Migration log `docs/ui-ux-system/11-implementation-mapping.md` (L182) đã ghi.

### Findings — MINOR follow-up (không block merge; giao Codex sweep)
**Nhóm A — user-visible (nên fix trước khi demo):**
- **F1 · encoding** — placeholder null bị mojibake `'â€"'` (bytes C3A2 E282AC E2809D) thay vì em-dash `—`. Verified: `teacher_assignment_grading_hub_view.dart:237,250` + `teacher_inbox_page.dart:275,276`. → thay bằng `'—'`.
- **F2 · label** — A1 Users header cột 1 = `teacherClassColMember` → hiện **"Member"** thay vì "User". `user_management_page.dart:476`. → dùng `adminTableUser` (đã có, A2 đang dùng).
- **F3 · label** — T3 Inbox: cột "Loại" đang dùng `teacherClassColStatus` (→ "Status"), cột "Thời gian" dùng `teacherClassColSchedule` (→ "Schedule"). `teacher_inbox_page.dart:260,262`. → thêm/đổi key "Type/Loại" + "Time/Thời gian".
- **F4 · label** — A1 "Last active" header sinh bằng `adminUserLastActive('').replaceAll(': ','')` (chuỗi surgery mong manh). `user_management_page.dart:479`. → thêm key header riêng.

**Nhóm B — hygiene (dead code, defer OK):**
- **F5 · dead code** — xoá widget/khối card cũ đã superseded: T1 `TeacherGradingAttemptCard` (492-696); A2 `AdminHistoryCard` (promote public + @Deprecated, không ai gọi); A6 `admin_listening_comp_list_page.dart` khối `ListView`/`ShadcnCard` comment (~311-363); A9 khối comment (679-694) + `ReleaseItemLegacyCard`/`_MetaText`/`_ActionButton`; file rời `user_card.dart` + `report_card.dart` (không dùng).
- **F6 · reuse** — T1 `_studentCell` tự dựng `CircleAvatar` thay vì `TeacherWebUi.userAvatarCircle` (mất ảnh avatar network). `teacher_assignment_grading_hub_view.dart:185-192`.
- **F7 · consistency** — `classroom_detail` `_MemberTable` dùng width magic 130/170/190 (nên đặt const như `_AssignmentTable`); A4 Reading dùng thumbnail 32×32 trong khi A5–A8 dùng icon 18px.

> Ghi chú: F1–F4 là text-glitch nhìn thấy được. F5–F7 là nợ nhỏ, gom 1 sweep sau. Không có item nào CHANGES-REQUESTED.

### ✅ Đã sửa (Opus, 2026-07-11) — F1–F4
- **F1** — thay byte mojibake `C3A2 E282AC E2809D` → em-dash `—` (E28094) tại grading_hub `237,250` + inbox `275,276`. Verify: 0 sequence còn lại.
- **F2** — `user_management_page.dart:476` → `l10n.adminTableUser` ("User"/"Người dùng").
- **F3** — `teacher_inbox_page.dart:260,262` → key mới `teacherInboxColType` ("Type"/"Loại") + `teacherInboxColTime` ("Time"/"Thời gian").
- **F4** — `user_management_page.dart:479` → key mới `adminTableLastActive` ("Last active"/"Hoạt động lần cuối"), bỏ `replaceAll` string-surgery.
- l10n: thêm 3 key vào app_en.arb + app_vi.arb (parity), `flutter gen-l10n` OK. `dart analyze` 4 file + generated = **No issues found**.
### ✅ Đã sửa tiếp (Opus, 2026-07-11) — F5–F7
- **F5 dead code** — xoá: `TeacherGradingAttemptCard` (grading_hub) + reword dartdoc trỏ tới nó ở `teacher_classroom_assignment_tile.dart:14`; `AdminHistoryCard` (activity_history); `ReleaseItemLegacyCard`+`_MetaText`+`_ActionButton` + khối comment `/* … */` (release); khối comment legacy `ListView`/`ShadcnCard` (listening_comp); xoá file `user_card..dart` + `report_card.dart`. Verify: live helper release (`_StatusPill`/`_ForceBadge`/`_SectionCard`/`_CompactDropdown`/`_IconToggleButton`/`_buildReleaseTable`) còn nguyên; 0 block-comment hở; destructive guard KHÔNG đụng.
- **F6 — KHÔNG áp dụng (đúng nghiệp vụ):** attempt map ở grading hub KHÔNG có field avatar URL (chỉ `_studentLabel`/`_studentEmail`), nên `userAvatarCircle` không "khôi phục" được ảnh network — chỉ đổi logic initials. Giữ avatar initials-only hiện tại là đúng. (Premise của finding sai với data thực tế.)
- **F7a done** — `_MemberTable` width magic 130/170/190 → const `_colMemberStatusW/JoinedW/ActionsW` (đồng bộ với `_colStatusW` của `_AssignmentTable`). **F7b (A4 thumbnail) giữ nguyên** — thumbnail 32×32 là rendering giàu hơn hợp lệ, không phải defect.
- **Verify:** dọn thêm `unused_shown_name AppRadius` sinh ra sau khi xoá card. `dart analyze` 8 file touched = **No issues found**. 0 error toàn `lib`.
- **CHƯA COMMIT / CHƯA STAGE** (no-auto-commit) — toàn bộ ở working tree; xoá file đã unstage.

### ✅ Polish sau khi user xem thật (Opus, 2026-07-11) — F8–F11
- **F8 · góc bảng bị cắt (web):** `web_data_table.dart` `Clip.antiAlias` → `Clip.antiAliasWithSaveLayer`. Gốc: nền header (`surface` #FAFAF9) tràn qua góc bo panel (`surfaceCard` #FFFFFF) trên web → lộ góc vuông. Fix 1 chỗ, áp dụng mọi bảng.
- **F9 · header "AC…":** 7 bảng admin (listening/listening_comp/reading/speaking/writing/release/report) đặt cột hành động 56px = `adminTableActions` ("Actions" → cắt còn "AC…") → đổi `label: ''`, khớp mẫu classroom_detail + user_management. Teacher tables đã đúng sẵn.
- **F10 · Content Manager → bảng:** `content_dashboard_page.dart` grid 4 thẻ `AdminSkillCard` → `WebDataTable` (cột Content flex4 + Topics phải; icon neutral `textSecondary` theo quy ước bảng, KHÔNG skill color; row-tap điều hướng, Listening mở dialog chọn dictation/comp). Bỏ import `admin_widgets` thừa.
- **F13 · status "Lobby open" quá dài + mojibake (classroom detail):** status pill lobby dùng chung `examCardStatusLobby` ("Lobby open — waiting to go live") wrap 2 dòng trong cột 140px → thêm key ngắn `teacherClassStatusLobby` ("Lobby open"/"Phòng chờ") chỉ cho bảng teacher (`_asgStatus:699`), student card giữ nguyên text mô tả. Fix mojibake `â€"`→`—` ở `_asgSchedule`/`memberJoinDate` (1079/1691). **Sweep toàn repo**: 0 mojibake còn lại (grading_hub/inbox/classroom_detail đã sạch). `dart analyze` = No issues.
- **F12 · Live exam session — roster HS → bảng:** `teacher_exam_session_console_page.dart` danh sách "Students in lobby" (`_participantTile` tiles) → `WebDataTable` (Student flex4 avatar+tên+email · Status = `TeacherExamParticipantStatusChip` · ⋯ = "Remove student" danger → `_confirmKick`). Giữ nguyên card title + counts + realtime (data vẫn stream qua bloc). **Live monitor tab (`TeacherLiveMonitorPanel`) KHÔNG đụng** — progress bar chi tiết vẫn ở đó; bảng roster ở Control tab dùng chung cho lobby + live. `dart analyze` = No issues; `ui_audit teacher` 0 hex/0 radius (dọn thêm 1 unused import cũ).
- **F11 · row-tap đổi trạng thái (Releases):** audit toàn bộ `onRowTap` → **chỉ Releases** là mutate-state (`_primaryAction`: approve/schedule/publish theo status), mọi bảng khác row-tap = mở chi tiết/editor. Nguy hiểm (bấm nhầm = publish) + không nhất quán. Sửa: bỏ `_primaryAction`, row-tap Releases = mở **dialog chi tiết read-only** (version/env/git sha·branch/CI/changelog/timestamps). Mọi đổi-trạng-thái CHỈ qua ⋯ menu (giữ nguyên confirm guard). `dart analyze` 2 file = No issues; `ui_audit admin` 0 hex/0 radius.

## Implementer handoff — 2026-07-11
- `dart analyze` trên toàn bộ file P0–P3: **No issues found**.
- `flutter gen-l10n`: đã chạy; header EN/VI đã sinh lại.
- `ui_audit.sh teacher --list`: 0 hex, 0 radius; baseline ngoài scope còn 2 duration + 1 comment spinner.
- `ui_audit.sh admin --list`: 0 hex, 0 radius; baseline ngoài scope còn 1 dashboard duration + 1 comment spinner.
- Smoke build: Flutter web serve `http://127.0.0.1:8090` trả HTTP 200.
- Smoke tương tác §7: **chưa hoàn tất** — browser controller yêu cầu Node >=22.22, runtime hiện tại 22.17.
- KEEP-list không chỉnh sửa; release publish FORCE và rollback vẫn gọi nguyên dialog guard cũ.
