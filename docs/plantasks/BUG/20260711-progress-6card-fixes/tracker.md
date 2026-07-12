# Tracker — 20260711-progress-6card-fixes

- **Loại/Cỡ:** BUG · T1 · full-stack
- **Status:** `IMPLEMENTED (Opus tự code) — unit + analyze PASS; runtime smoke chờ máy thật`
- **Work-order:** [`work-order.md`](work-order.md)

## Tóm tắt fix
| # | Finding | Fix | File |
|---|---|---|---|
| F1 | Speaking hiện "0%" cho free-speaking + nhãn "fluency" sai | Gộp `speakingScore ∪ speakingFluency` ở phía đọc (`aggregateProgressRecords`); gỡ subtitle | progressService.js, progress_report_page.dart |
| F2 | Vocab đếm số LƯỢT (đếm trùng) | Đổi sang `Word.countDocuments` distinct (`user`, status learning, lastReviewedDate range) | progressService.js |
| F3 | `fromJson` crash nếu thiếu field | Null-safe `(as num?)?.toInt()/toDouble() ?? 0` | progress_summary_entity.dart |

## Nhật ký
- **2026-07-11 — Opus:** Phân tích ground-truth (đọc code thật: progressService, progressTracker, UserDailyProgress, Word, vocabularyService, các controller ghi stats). Audit downstream `speakingFluency` → phát hiện userController + AI tools đọc bucket này ⇒ đổi thiết kế F1 từ "sửa write-path" sang "gộp phía đọc" (an toàn downstream). Viết work-order + CONTEXT BUNDLE 6 Site. Đã có sẵn 2 bộ test (BE 13 case, FE 9 case) làm nền — work-order cập nhật lại phần test bị đổi hành vi.
- **2026-07-11 — Opus tự code (user cho phép):** áp đủ 6 Site theo §5. Dọn thêm dead param `_StatBox.subtitle` (do gỡ chỗ dùng duy nhất) để analyze sạch — cùng file Scope IN.
- **2026-07-11 — Follow-up §10 (cùng session):** xử luôn 3 mục — vocab-detail (`user` field + status learning), F4 (goal = ngày đã trôi), F5 (progressPercent theo range). Đã grep xác nhận F5 không đụng Home/admin (`getSummaryData` chỉ progress page dùng, page bỏ qua field). Verify: `node --check` OK · `node --test` 13/13 · `dart analyze` 0 issue.

## Bằng chứng
- [x] `node --check progressService.js`: OK
- [x] `node --test progressService.test.js`: **13/13** (F1 speaking gộp → 70 & 85)
- [x] `node --test progressService.summary.test.js` (**MỚI**, mock Mongoose): **4/4** — F2 vocabLearned=Word.countDocuments (không phải reps) + filter `user`/status; F5 progressPercent 'day'=0.5 & 'week' theo ngày đã trôi; vocab-detail filter `user`+learning.
- [x] Backend pure-logic tổng: **71/71 pass** (21 suites) — không regression.
- [x] `flutter test` (toàn app): **26/26 pass** (gồm progress entity 9 + teacher analytics …).
- [x] `dart analyze` (entity + progress page): **No issues found**.
- [~] F4 (`_calculateTotalGoalMinutes`) — pure math trong State (phụ thuộc device-date), verify bằng review + analyze; chưa tách unit test.
- [ ] Smoke UI end-to-end (⭐ speaking>0%, vocab distinct+detail, %tuần/tháng): chờ chạy app+DB seed.

## Opus self-audit (§9)
- [x] Chỉ file Scope IN đổi; speakingService/userController/implementations KHÔNG đụng.
- [x] Site 1 speakingCombined; Site 3 dùng `user`+status learning+override 'day'; Site 2 gỡ subtitle (+dead param); Site 4 null-safe cả 2 entity; Site 5/6 test pass.
- [x] Không placeholder/TODO; không đổi shape JSON/schema/l10n.
- **Verdict:** ✅ PASS (unit + analyze). ⚠️ F2 (vocab distinct trong `getSummaryData`) chỉ verify bằng `node --check` + review — KHÔNG có unit test (cần DB); phải chạy **smoke ⭐2** trên máy thật để xác nhận số distinct.
