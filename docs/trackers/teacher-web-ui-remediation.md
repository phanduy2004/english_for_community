# Tracker — Teacher web UI/UX remediation

> **Spec (source of truth):** [`../ui-ux-system/18-teacher-web-audit-and-standards.md`](../ui-ux-system/18-teacher-web-audit-and-standards.md)  
> **Audit script:** `english_for_community/tool/ui_audit.sh`  
> **Code scope:** `lib/feature/teacher/**`  
> **Cập nhật lần cuối:** 2026-06-14

---

## Tóm tắt nhanh

| Hạng mục | Trạng thái |
|----------|------------|
| Phase 0 — Audit tool | ✅ Done |
| Phase 1 — Token foundation | ✅ Done |
| Phase 2 — Sweep cơ học | ✅ Done |
| Phase 3 — UX theo màn | 🟡 Partial |
| Phase 4 — Polish a11y & motion | 🟡 Partial |
| Cổng 6.6 — Sign-off | 🟡 Partial |

**Audit tự động (grep/script):** hex · radius literal · Duration literal · `AppLoadingIndicator.center` → **0** (chỉ comment trong `teacher_skeleton.dart`).

**Chưa sign-off:** `dart analyze lib` (Flutter SDK local lỗi), smoke-test thủ công 1280/768, CI gắn `ui_audit`.

---

## Phase 0 — Công cụ audit

| # | Việc | Trạng thái | Ghi chú |
|---|------|------------|---------|
| 0.1 | `tool/ui_audit.sh` đếm 4 loại vi phạm | ✅ | `english_for_community/tool/ui_audit.sh` |
| 0.2 | Baseline in trong doc §6 | ✅ | `18-…md` §6.1 |
| 0.3 | CI chặn merge nếu số tăng | ⬜ | Chưa gắn pipeline |

---

## Phase 1 — Token foundation

| # | Việc | Trạng thái | File / helper |
|---|------|------------|---------------|
| 1.1 | Overlay tokens (`hoverOverlay`, `pressOverlay`, `focusRing`, …) | ✅ | `core/theme/app_color.dart` |
| 1.2 | `AppScoreScale` | ✅ | `core/theme/app_score_scale.dart` |
| 1.3 | `AppMotion` (micro, pulse, stagger, autosave, …) | ✅ | `core/theme/app_motion.dart` |
| 1.4 | `TeacherWebUi.formFieldError()` | ✅ | `layout/teacher_web_ui.dart` |
| 1.5 | `TeacherWebUi.focusableTile()` | ✅ | `layout/teacher_web_ui.dart` |
| 1.6 | `TeacherSkeleton.*` | ✅ | `layout/teacher_skeleton.dart` |
| 1.7 | Radius nội bộ `TeacherWebUi` → `AppRadius` | ✅ | Phase 2 sweep |

---

## Phase 2 — Sweep cơ học

| Metric | Baseline | Mục tiêu | Hiện tại |
|--------|----------|----------|----------|
| Hex `Color(0x…)` | 13 | 0 | **0** |
| `BorderRadius.circular(<số>)` | 144 | 0 | **0** |
| `Duration(milliseconds:…)` rời | nhiều | 0 | **0** |
| `AppLoadingIndicator.center` | 22 | 0 | **0** |

| # | Việc | Trạng thái |
|---|------|------------|
| 2.1 | Hex → `AppColors` / `AppScoreScale` | ✅ |
| 2.2 | Radius → `AppRadius` | ✅ |
| 2.3 | Alpha rời → overlay tokens | ✅ |
| 2.4 | `flutter analyze` sạch | 🟡 | SDK local lỗi `dds: 5.0.3` — chưa xác nhận CI |

---

## Phase 3 — UX theo màn

### 3a — Dashboard, analytics, gradebook, exams-list

| # | Việc | Trạng thái | Ghi chú |
|---|------|------------|---------|
| 3a.1 | Spinner → `TeacherSkeleton` (dashboard, analytics, gradebook, …) | ✅ | |
| 3a.2 | Empty + CTA — inbox | ✅ | → dashboard |
| 3a.3 | Empty + CTA — calendar (list empty) | ✅ | → exams list |
| 3a.4 | Empty + CTA — calendar (no day events) | ✅ | → exams list |
| 3a.5 | Empty + CTA — exams-list | ✅ | Tạo đề mới |
| 3a.6 | Empty + CTA — gradebook (no assignments) | ✅ | → classroom |
| 3a.7 | Empty + CTA — analytics (2 empty cards) | ✅ | → dashboard |
| 3a.8 | Empty + CTA — classroom recent assignments | ✅ | Gộp vào `TeacherEmptyCard` |
| 3a.9 | Empty + CTA — dashboard overview (nếu có) | ⬜ | Chưa rà soát từng widget con |

### 3b — Gradebook

| # | Việc | Trạng thái | Ghi chú |
|---|------|------------|---------|
| 3b.1 | Sticky cột tên + header | ✅ | `_StickyGradebookTable` |
| 3b.2 | Số căn phải + tabular figures | ✅ | |
| 3b.3 | Zebra hàng lẻ | ✅ | |
| 3b.4 | `ListView.builder` >100 hàng | ✅ | |
| 3b.5 | Spacing magic → `AppSpacing` (toàn gradebook) | 🟡 | Một số padding legacy còn |

### 3c — Exam editors

| # | Việc | Trạng thái | Ghi chú |
|---|------|------------|---------|
| 3c.1 | `teacher_exam_editor_page` — save-state + autosave | ✅ | `TeacherSaveStateIndicator` |
| 3c.2 | `teacher_exam_editor_page` — inline validate publish | ✅ | Banner + field errors |
| 3c.3 | `teacher_integrated_exam_editor_page` — save-state + autosave | ✅ | |
| 3c.4 | `teacher_integrated_exam_editor_page` — inline publish errors | ✅ | Banner thay toast |
| 3c.5 | Grammar/writing sub-panels — toast validate | ⬜ | `teacher_skills_exam_grammar_editor_panel.dart` vẫn toast |

### 3d — Dialogs

| # | Việc | Trạng thái | Ghi chú |
|---|------|------------|---------|
| 3d.1 | `teacher_assign_exam_dialog` — inline validate | ✅ | Exam / class / scheduled start |
| 3d.2 | `teacher_edit_profile_dialog` — inline validate | ✅ | Form validators + server error banner |
| 3d.3 | Assign wizard **stepper** (form dài) | ⏸ | P2 — deferred |

### 3e — Destructive / cảnh báo

| # | Việc | Trạng thái | Ghi chú |
|---|------|------------|---------|
| 3e.1 | Release results — banner warning (reversible) | ✅ | `_ConsequenceBanner` |
| 3e.2 | End session — danger + type confirm | ✅ | Gõ số HS |

---

## Phase 4 — Polish a11y & motion

| # | Việc | Trạng thái | Ghi chú |
|---|------|------------|---------|
| 4.1 | `focusableTile` — sidebar nav | ✅ | `teacher_shell.dart` |
| 4.2 | `focusableTile` — KPI card | ✅ | `TeacherKpiCard` |
| 4.3 | `focusableTile` — assign dialog tiles | ✅ | Audience + mode |
| 4.4 | `focusableTile` — edit profile gender chips | ✅ | |
| 4.5 | `TeacherWebUi.headerIconButton()` | ✅ | Integrated editor refresh |
| 4.6 | `AppMotion.effective()` + reduce-motion dashboard | ✅ | enter / hover / live-pulse |
| 4.7 | `focusableTile` — **mọi** icon button header | 🟡 | Một số màn vẫn `IconButton` thuần |
| 4.8 | `focusableTile` — dialog choice tiles còn lại | 🟡 | Policy tiles assign dialog |
| 4.9 | Hover/press đồng bộ mọi cell click | 🟡 | Gradebook `_ScoreCell` vẫn `InkWell` |
| 4.10 | Tab keyboard — smoke test toàn dashboard | ⬜ | Thủ công |

---

## Checklist §7 (18-teacher-web-audit)

| Tiêu chí | Trạng thái |
|----------|------------|
| Không `Color(0x…)` trong `teacher/**` | ✅ |
| Không `BorderRadius.circular(<số>)` | ✅ |
| Không `Duration(milliseconds:…)` rời | ✅ |
| Loading = skeleton, không spinner toàn vùng | ✅ |
| Lỗi field = inline, không toast (validate) | 🟡 | Grammar panel + vài toast success OK |
| Editor save-state (idle/saving/saved/error) | 🟡 | 2 editor chính ✅; sub-panels ⬜ |
| Hành động không thu hồi = danger + gõ xác nhận | ✅ | End session |
| Focus ring + hover/press trên phần tử tap | 🟡 | Sidebar/KPI/dialog chính ✅ |
| Bảng: sticky cột đầu + số tabular | ✅ | Gradebook |

---

## Backlog (P2 / ngoài phase)

| # | Việc | Ưu tiên | Trạng thái |
|---|------|---------|------------|
| B1 | Assign wizard stepper | P2 | ⏸ |
| B2 | Nút disabled + tooltip giải thích | P2 | ⬜ |
| B3 | §5.11 density tiers formal | P2 | ⬜ |
| B4 | Sync doc `06`/`07`/`08` với chuẩn mới | P2 | ⬜ |
| B5 | Grammar editor panel inline validate | P1 | ⬜ |
| B6 | CI: `ui_audit.sh` on PR | P0 | ⬜ |

---

## Foundation đã tạo (tái dùng — không làm lại)

```
core/theme/app_color.dart      → hoverOverlay, pressOverlay, focusRing, scrim, shadowCard
core/theme/app_score_scale.dart
core/theme/app_motion.dart     → micro, staggerStep, pulse, autosave, effective()
layout/teacher_web_ui.dart     → formFieldError, focusableTile, headerIconButton
layout/teacher_skeleton.dart   → kpiGrid, table, cardList, dashboard, page, calendar
layout/teacher_widgets.dart    → TeacherEmptyCard (CTA), TeacherSaveStateIndicator
```

---

## Lệnh xác minh

```bash
cd english_for_community
bash tool/ui_audit.sh          # hoặc --list
dart analyze lib               # cần Flutter SDK OK
```

---

## Nhật ký thay đổi tracker

| Ngày | Thay đổi |
|------|----------|
| 2026-06-14 | Khởi tạo tracker; ghi nhận Phase 0–2 done; Phase 3–4 partial sau các batch remediation |
| 2026-06-14 | Bổ sung 3a.7–3a.8, 3c.3–3c.4, 3d.2, Phase 4 reduce-motion + headerIconButton |
