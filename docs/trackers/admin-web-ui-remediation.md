# Tracker — Admin web UI/UX remediation

> **Spec:** [`../ui-ux-system/19-admin-web-audit-and-standards.md`](../ui-ux-system/19-admin-web-audit-and-standards.md)  
> **Mẫu:** [`../ui-ux-system/18-teacher-web-audit-and-standards.md`](../ui-ux-system/18-teacher-web-audit-and-standards.md)  
> **Audit:** `bash tool/ui_audit.sh admin` · **Scope:** `lib/feature/admin/**`  
> **Cập nhật:** 2026-06-20

---

## Baseline → mục tiêu

| Metric | Baseline | Mục tiêu | Hiện tại |
|--------|----------|----------|----------|
| Hex `Color(0x…)` | 298 | 0 | ✅ 0 (trừ whitelist `admin_skill_palette.dart`) |
| Radius literal | 202 | 0 | ✅ 0 |
| Duration literal | 11 | 0 | ✅ 0 |
| Spinner `AppLoadingIndicator.center` | 29 | 0 | ✅ 0 (còn 1 dòng comment) |
| Skeleton usage | 0 | >0 | ✅ thay spinner diện rộng |

Whitelist: `admin_skill_palette.dart` · `// audit-ignore`

---

## Phase 0 — Audit tool

| # | Việc | Trạng thái |
|---|------|------------|
| 0.1 | `tool/ui_audit.sh admin` | ✅ |
| 0.2 | Baseline doc §6 | ✅ |

---

## Phase 1 — Foundation

| # | Việc | Trạng thái | File |
|---|------|------------|------|
| 1.1 | `AdminStatusPalette` | ✅ | `core/theme/admin_status_palette.dart` |
| 1.2 | `AdminSkeleton` | ✅ | `layout/admin_skeleton.dart` |
| 1.3 | `AdminWebUi.focusableTile()` + `formFieldError()` | ✅ | `layout/admin_web_ui.dart` |
| 1.4 | Shadow → `AppColors.shadowCard/shadowAmbient` | ✅ | `admin_web_ui.dart` |
| 1.5 | Radius nội bộ form → `AppRadius.input` | ✅ | `admin_web_ui.dart` |
| 1.6 | `panelDecoration()` | ✅ | `admin_web_ui.dart` |

**Cổng Phase 1:** IDE lint 0 lỗi trên file mới · `dart analyze` (SDK local chậm).

---

## Phase 2 — Sweep cơ học

| Batch | Việc | Trạng thái |
|-------|------|------------|
| 2A | `content_widgets` → AppColors + AdminWebUi | ✅ |
| 2A | `admin_writing_list_view` gỡ hex trùng | ✅ |
| 2A | `release_management` status → palette | ✅ |
| 2A | Ops Center CSV status + metric chips | ✅ |
| 2A | user/report badges, role chips | ✅ |
| 2B | Radius → AppRadius (toàn admin) | ✅ |
| 2C | Duration → AppMotion | ✅ |

---

## Phase 3 — UX theo màn

| # | Việc | Trạng thái |
|---|------|------------|
| 3a | Spinner → AdminSkeleton | ✅ |
| 3a | Empty + CTA `AdminEmptyCard` | ✅ |
| 3b | Phân trang (`AdminPaginationBar`) | ✅ |
| 3c | CMS editor save-state + inline validate | ✅ (reading editor) |
| 3d | Rollback confirm + reject danger | ✅ |

---

## Phase 4 — Polish

| # | Việc | Trạng thái |
|---|------|------------|
| 4.1 | `focusableTile` sidebar/KPI/skill/nav | ✅ |
| 4.2 | Semantics status pill + tooltip icon | ✅ (release, user, report) |

---

## Nhật ký

| Ngày | Ghi chú |
|------|---------|
| 2026-06-20 | Phase 1 foundation + bắt đầu Phase 2 (content_widgets, release, ops partial) |
| 2026-06-20 | Đóng gate cơ học: hex/radius/duration/spinner đạt 0 theo audit-pattern (trừ whitelist + comment). |
| 2026-06-21 | Phase 3/4 done: AdminPaginationBar, AdminEmptyCard CTA, CMS pagination (20 rows), reading editor save-state + inline validate, focusableTile skill/nav, Semantics pills. |
