# Tracker — 20260706-progress-a12-redesign

- **Loại/Cỡ:** FEATURE · T1 · student mobile (Flutter)
- **Work-order:** [`work-order.md`](work-order.md) · **Brief:** `docs/ui-ux-system/patterns/04-screen-briefs/progress.md` (A12)
- **Status:** ✅ IMPLEMENTED (Opus tự code theo yêu cầu) — analyze sạch; chờ smoke visual trên thiết bị.

## Trạng thái theo phase
| Phase | Vai | Trạng thái |
|---|---|---|
| 1 — Phân tích ground-truth | Opus | ✅ Xong (2 scout: ui-ux-system + backend; đọc page/bloc/state/entity/brief thật) |
| 2 — Work-order (13 Site CONTEXT BUNDLE) | Opus | ✅ Xong |
| 3 — Implement | Opus (tự code) | ✅ Xong — 13/13 Site, 5 file |
| 4 — Verify tĩnh | Opus | ✅ `dart analyze` progress: 0 lỗi (1 info pre-existing ở report_dialog.dart, không đụng); `flutter analyze lib`: 0 error toàn project |
| 5 — Smoke visual | — | ⏳ Cần chạy `flutter run` + login seed → mở tab Progress |

## Scope chốt
- **IN:** progress_report_page.dart · progress_summary_entity.dart · progress_state.dart · progress_bloc.dart · app_en.arb + app_vi.arb (13 Site, 8 l10n key).
- **OUT (follow-up):** A6 per-skill bars · A7 CelebrateBurst · B7 subtitle đơn vị · B8 progressPercent · backend features (streak calendar / achievements / leaderboard scoping).

## Nhật ký
- 2026-07-06 — Opus: audit màn Progress từ screenshot + code thật. Phát hiện brief A12 đã blueprint sẵn layout. Tổng hợp A1–A7 (layout) + B1–B8 (bug/dead-data) + feasibility feature (backend scout). User chọn gộp P0+P1+all bug → 1 work-order T1. Verify signature helper + accentTint + l10n keys. Ra work-order + tracker.

## Bằng chứng build/test/smoke
- **analyze:** `dart analyze lib/feature/progress lib/core/entity/progress_summary_entity.dart` → 1 issue (info pre-existing, `report_dialog.dart:91`, không đụng). `flutter analyze lib` → 205 issues nhưng **0 error** (baseline lint pre-existing).
- **Downstream check:** grep `StatsGridEntity(` chỉ construct trong entity file → `readingWpm` required an toàn; `ProgressState` totalUsers có default 0.
- **l10n:** `flutter gen-l10n` chạy OK; 8 key mới resolve (analyze không báo undefined getter).
- **smoke 1..6:** ⏳ chưa chạy (cần thiết bị + login).
- **Opus verdict:** static PASS; chờ smoke visual để chốt APPROVED.

## Ghi chú self-audit (§9)
- ✅ Chỉ 5 file Scope IN đổi; không đụng backend/chart widget/shared UI; A6/A7/B7 không lọt vào.
- ✅ KPI row (streak `accent`/`accentTint`, points/level neutral); 2 dòng chrome đã bỏ; chart lên ngay sau filter.
- ✅ Goal bar `AppColors.primary`; chart highlight vẫn `chartHighlight` amber (1-amber-rule).
- ✅ Grid 8 tile (thêm readingWpm/speakingFluency); entity parse `readingWpm ?? 0`.
- ✅ Dòng "Bạn #X/Y" (myRank>0 && totalUsers>0); totalUsers đồng bộ state/bloc/props.
- ✅ Callout hết chevron; avatar `CachedNetworkImageProvider`; refresh chờ `stream.firstWhere`.
- ✅ Empty branch `_isSummaryEmpty` + `_buildEmptyUI(emptyState)` không lồng scroll.
- ⚠️ Lưu ý edge: user có streak/points nhưng 0 hoạt động trong range → empty state che KPI row (đúng brief `:143`, chấp nhận). Muốn giữ KPI trên empty → mở follow-up nhỏ.
- ⏳ Chưa ghi Migration log `11-implementation-mapping.md` (làm sau khi smoke pass).
