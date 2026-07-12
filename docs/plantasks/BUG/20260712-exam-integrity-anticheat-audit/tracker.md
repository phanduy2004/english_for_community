# TRACKER — 20260712-exam-integrity-anticheat-audit

| Artifact | Trạng thái | Ghi chú |
| --- | --- | --- |
| `audit.md` | ✅ DONE | Phân tích ground-truth 9 finding A + test B + report C |
| `WO-1-correctness-security.md` | ✅ IMPLEMENTED + AUDITED | A1 chống reset + A2 fullscreen→risk + A5 double-count + A6 mọi format; test B1/B2 |
| `WO-2-client-signals.md` | ✅ IMPLEMENTED + AUDITED | A3 web fullscreen + A4 mobile paste; conditional-import + ExamIntegrityScope |
| `WO-3-teacher-report.md` | ✅ IMPLEMENTED + AUDITED | C1 per-student detail + C3 assignment summary + C4 audit-log icon; test B4 |

## Bằng chứng verify (2026-07-12, Opus tự code + tự audit)
- **Backend:** `npm test` → **102/102 pass** (thêm `src/services/examIntegrityService.test.js` 12 test B1/B2).
- **Frontend:** `flutter analyze` toàn project → **0 error** (166 warning/info đều pre-existing, không từ code mới). `flutter test` → **38/38 pass** (thêm `test/teacher_live_monitor_derived_test.dart` 7 test B4).
- **l10n:** `flutter gen-l10n` OK, 2 key mới (`teacherGradingIntegritySummaryTitle`, `teacherGradingIntegrityTotal`) EN+VI.

## Files đã đổi
**Backend (1+1 test):** `services/examIntegrityService.js` (+ export `computeRiskLevel`/`mergeIntegrity`, Zod, monotonic, latch, prev.toObject()); `services/examIntegrityService.test.js` (mới).
**Frontend client (WO-1/WO-2):** `exam_integrity_tracker.dart` (A5 _isAway+hidden, A3 fullscreen hook, ExamIntegrityScope, examContextMenuBuilder, _flush +fullscreenExited); `exam_runner_page.dart` (A6 wrap tracker); mới: `exam_fullscreen.dart`/`_web.dart`/`_stub.dart`; datasource/repo/impl `reportExamAttemptIntegrity` +fullscreenExited; 4 ô nhập +contextMenuBuilder (`integrated_exam_grammar_widgets.dart`, `exam_embedded_fixed_writing_panel.dart`, `listening/widget/practice_tab.dart`, `writing/writing_task_page.dart`).
**Frontend teacher (WO-3):** `teacher_live_monitor_derived.dart` (+3 patch key); `teacher_live_monitor_panel.dart` (_integrityDetailLine); grading_hub `state.dart`+`bloc.dart` (integritySummary); `teacher_assignment_grading_hub_view.dart` (card); `teacher_classroom_detail_page.dart` (integrity_flag icon); `app_en.arb`+`app_vi.arb`+generated; mới: `test/teacher_live_monitor_derived_test.dart`.

## Quyết định user (2026-07-12)
- Làm cả 3 WO. Fullscreen: làm ĐẦY ĐỦ (client A3 + backend A2).

## Nhật ký
- 2026-07-12 — Opus: audit + viết 3 work-order (CONTEXT BUNDLE đầy đủ). Chờ Cursor implement từng WO. Thứ tự đề xuất: **WO-1 → WO-2 → WO-3** (WO-2 phụ thuộc A2 của WO-1; WO-3 độc lập, hưởng lợi từ WO-2 khi có đủ tín hiệu).

## Khi implement xong (mỗi WO)
1. Cursor self-audit: file đổi · rủi ro · checklist §10 tự chấm.
2. Dán bằng chứng build/test vào đây.
3. Báo Opus audit (Phase 4) → cập nhật Verdict.

### Verdict Opus (Phase 4 — 2026-07-12)
- **WO-1: ✅ APPROVED.** computeRiskLevel khớp §5 + fullscreen→medium (B1 boundary pass); mergeIntegrity monotonic + latch (B2 pass, absolute không hạ được counter); Zod chặn payload rác; prev.toObject() đảm bảo cộng dồn đúng dù prev là Mongoose subdoc; A5 _isAway 1-lần/chu-kỳ + hidden; A6 wrap legacy runner chỉ khi in_progress, KHÔNG double-wrap (nhánh integrated return sớm). Guard ownership/status còn nguyên; schema Mongoose không đổi.
- **WO-2: ✅ APPROVED.** Conditional-import nhái file_download (web dart:html, io stub — analyze sạch cả 2 nhánh, không kéo dart:html vào mobile); fullscreen enter best-effort + listener gỡ ở dispose + latch client; examContextMenuBuilder hook paste chỉ khi có ExamIntegrityScope (practice mode = null → no-op, không đếm); param fullscreenExited xuyên suốt datasource/repo/impl/_flush.
- **WO-3: ✅ APPROVED.** 3 count vào _rosterUiPatchKeys → realtime repaint khi count đổi (B4 pass); tile detail ẩn khi 0 tín hiệu; card summary ẩn khi total 0/null; bloc fetch integrity NGOÀI fold (best-effort, lỗi không chặn trang); copyWith giữ integritySummary qua filter change; integrity_flag có cờ đỏ.

### Lưu ý minor (không blocker, ghi để theo dõi)
1. `MAX_FOCUS_DELTA=3600`: 1 report focus-loss >1h bị Zod từ chối (400, client nuốt lỗi) → mất đúng event đó. Chấp nhận được vì >1h away thường đã expired (status guard chặn). Nếu muốn: clamp thay vì reject.
2. `buildWhen` của grading hub view KHÔNG liệt kê `integritySummary` — nhưng card vẫn hiện vì integritySummary set cùng emit với `status: success` (status đổi → rebuild). An toàn ở luồng hiện tại.
3. `fullscreenExited` chưa vào payload live-screen (chỉ nâng riskLevel → teacher thấy cờ). Hiển thị số fullscreen riêng cho teacher là việc tương lai (ngoài scope).
4. **Manual smoke đề xuất (chưa chạy):** `flutter build web` để xác nhận web bundle + thử thoát fullscreen thật; thi mobile paste qua menu long-press. (Analyze đã cover phần compile Dart.)
