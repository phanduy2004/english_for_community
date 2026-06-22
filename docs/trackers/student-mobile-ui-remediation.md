# Student Mobile UI Remediation Tracker

Spec: [`docs/ui-ux-system/20-student-mobile-audit-and-standards.md`](../ui-ux-system/20-student-mobile-audit-and-standards.md)

Audit: `bash tool/ui_audit.sh student`

## Metrics (baseline → final)

| Metric | Baseline | Final | Target |
|--------|----------|-------|--------|
| Hex `Color(0x…)` | 30 | **0** | 0 |
| Radius `BorderRadius.circular(n)` | 141 | **0** | 0 |
| Duration `milliseconds:n` | 35 | **0**¹ | 0 |
| Spinner `AppLoadingIndicator.center` | 30 | **0** | 0 |

¹ `listening_common_widgets.dart` audio divisor — `// audit-ignore`

## Phase status

| Phase | Status |
|-------|--------|
| **1 Foundation** | ✅ Done |
| **2 Mechanical sweep** | ✅ Done |
| **3 UX by screen** | ✅ Done |
| **4 Polish** | ✅ Done |

## Phase 4 deliverables

- [x] `StudentMobileUi.mcqPagerHeader` + `mcqQuestionPager` (swipe MCQ)
- [x] PageView swipe: `exam_runner_page`, `reading_detail_page`, `listening_comp_page`
- [x] Audio player §5.10: `ListeningPlayer` — Semantics, tooltip, duration labels, disabled opacity
- [x] `GamificationCelebrateHost` on `progress_report_page`
- [x] Animated progress on progress overview card

## Checklist §7 (student mobile)

- [x] Touch-target ≥44dp (home header, nav 60, join card)
- [x] Haptic `AppHaptics` on MCQ / SRS / flashcard / header
- [x] No hex/radius/duration literals (whitelist only)
- [x] Loading = skeleton; error = retry block
- [x] MCQ Semantics; audio play/pause labels
- [x] Animation `AppMotion.effective` (key runners; partial remainder non-critical)
- [x] Exit-confirm `PopScope` on runners
- [x] Celebrate streak/level/XP (home + progress + vocab complete)
