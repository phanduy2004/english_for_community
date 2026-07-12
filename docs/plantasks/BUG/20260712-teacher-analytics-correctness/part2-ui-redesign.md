# Part 2 — Redesign UI màn Teacher Analytics

- **File:** `english_for_community/lib/feature/teacher/teacher_analytics_page.dart` (+ l10n `app_en.arb`/`app_vi.arb`).
- **Loại màn:** Dashboard/analytics (web) · maxWidth 1120 (`contentMaxDashboard`).
- **Mục tiêu (theo phản hồi user):** gọn gàng · dễ hiểu · đầy đủ · tỉ mỉ. KHÔNG phá test overflow hiện có.
- **Nguồn chuẩn:** `_templates/ui-build-web.md` (A0-A4) + doc `17/18`. Editorial Black, token-only, 4 states.

## Chẩn đoán (đã đọc code thật)
1. **Không phân nhóm:** `_AnalyticsContent.build` là 1 Column phẳng (KPI → summary → 2 chart → 2 chart → 2 bảng → 2 panel) không có section header → khó quét, "khó hiểu".
2. **Nhiễu dev-marker:** pill **"NEW"** (`_NewPill`) rải ở panel/KPI/integrity/mode — vô nghĩa với giáo viên → bỏ.
3. **Sparse-data:** panel score-trend/skill/at-risk/item **ẩn khi rỗng** (`if (...isNotEmpty)`) → tài khoản ít data thấy màn trống → "sơ sài".
4. **Hardcode:** loạt `TextStyle(fontSize: 8.5..13)` + spacing lẫn lộn s5/s6.
5. **Robustness:** `_asMapList` (`raw as List?`, `e as Map`) crash nếu backend đổi shape (các chỗ khác đã defensive).

## Đổi (R1-R6)

**R1 — Phân 4 SECTION có header** (thêm widget `_SectionHeader(title,{subtitle})` dùng `TeacherWebUi.webH2` + subtitle `webCaption`/textMuted). Cấu trúc `_AnalyticsContent.build`:
- **A · Tổng quan** (`teacherAnalyticsSectionOverview`, sub = kỳ N ngày): `_KpiRow` → `_SmartSummary`.
- **B · Hoạt động & điểm số** (`teacherAnalyticsSectionActivity`): TwoCol(submissions, score-dist) → (nếu có) TwoCol(score-trend, skill).
- **C · Học sinh & câu hỏi** (`teacherAnalyticsSectionStudents`): at-risk + item. **Nếu CẢ HAI rỗng** → 1 empty-note card gọn (`teacherAnalyticsSectionStudentsEmpty`) THAY VÌ mất hẳn section; nếu có ≥1 → hiện panel có data (bỏ panel rỗng, không show "no data" thừa).
- **D · Tính toàn vẹn & nộp bài** (`teacherAnalyticsSectionIntegrity`): TwoCol(integrity, modes).
- Spacing: giữa section `AppSpacing.s6`; trong section giữa panel `s5`; header→nội dung `s4`.

**R2 — Bỏ hẳn `_NewPill`**: xoá class + mọi `isNew`/`isNew:true`/`_NewPill()` (ở `_Panel`, `_KpiCard`, `_SmartSummary`, `_IntegritySection`, `_ModeSection`). Bỏ param `isNew` khỏi `_Panel`/`_KpiCard`.

**R3 — Empty-note card** (widget nhỏ `_EmptyNote(icon,text)`): nền `surfaceSubtle`/viền `outline`, icon 16 textMuted + text `webBody`/textSecondary — dùng cho Section C rỗng.

**R4 — `_asMapList` null-safe:** đổi thành
```dart
static List<Map<String, dynamic>> _asMapList(dynamic raw) {
  if (raw is! List) return const [];
  return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}
```

**R5 — Tokenize typography (AN TOÀN, không tăng cỡ gây overflow):**
- Header bảng at-risk (`_hdr`, hiện `fontSize:10 ls0.4 w700 muted`) → `TeacherWebUi.webTableHead(context)`.
- Section/panel title → `sectionTitle` (giữ nguyên chỗ đã dùng).
- **KHÔNG đổi** các cỡ micro trong chart (axis 9, bar-label 9.5/10/12, tooltip) — chart cần chữ nhỏ, và tăng cỡ có thể vỡ overflow. Ưu tiên GIỮ cỡ hiện tại; chỉ gom về token khi token **≤** cỡ hiện tại. Nghi ngờ → giữ nguyên + chạy test overflow.

**R6 — l10n (EN + VI, chạy `flutter gen-l10n`):** thêm
`teacherAnalyticsSectionOverview` (Overview / Tổng quan), `teacherAnalyticsSectionActivity` (Activity & scores / Hoạt động & điểm số), `teacherAnalyticsSectionStudents` (Students & questions / Học sinh & câu hỏi), `teacherAnalyticsSectionIntegrity` (Integrity & submissions / Tính toàn vẹn & nộp bài), `teacherAnalyticsSectionStudentsEmpty` (No students need attention yet — insights appear as more work is submitted and graded. / Chưa có học sinh cần chú ý — phân tích sẽ hiện khi có thêm bài nộp và chấm.).

## Scope OUT (chạm là DỪNG)
- ❌ Bloc/state/event/repository/datasource (không đổi data flow).
- ❌ Chart internals (`_SubmissionsChart`/`_ScoreDistBars`/`_ScoreTrendChart`/`_SkillBar`) — GIỮ; chỉ đổi cách bố cục/panel bọc ngoài.
- ❌ Backend (Part 1 xong).
- ❌ Đổi l10n key cũ / xoá panel nội dung.

## Verify (bắt buộc chạy, dán kết quả)
```bash
cd english_for_community
flutter gen-l10n
dart analyze lib/feature/teacher/teacher_analytics_page.dart
flutter test test/teacher_analytics_content_test.dart test/teacher_analytics_derived_test.dart
```
- Test overflow (@1280/960/760/640/420) + content ('Students needing attention','Most-missed questions') PHẢI xanh. Nếu overflow do thay đổi → sửa (thường do header dài; cho ellipsis) rồi chạy lại.
- Không hardcode `Color(0x…)`/`BorderRadius.circular(N)`/`Duration(ms:N)` mới.

## Pre-ship
- [ ] 4 section header rõ ràng; bỏ hết "NEW".
- [ ] Section C rỗng → empty-note (không mất section).
- [ ] `_asMapList` null-safe.
- [ ] l10n EN+VI + gen-l10n; dart analyze 0 lỗi mới; test analytics xanh.
