# WORK-ORDER WO-3 — Luồng report cheat/risk cho giáo viên

**Task ID:** 20260712-exam-integrity-anticheat-audit / WO-3 · **Loại:** BUG (feature-gap, UI) · **Platform:** teacher web
**Ngày:** 2026-07-12 · **Nguồn:** `audit.md` finding C1, C3, C4 · **Spec:** §7.1, §7.2, §7.3
**Ưu tiên:** TB · **Phụ thuộc:** độc lập WO-1/WO-2 (dùng data đã có). C1 hiển thị số chi tiết realtime tốt hơn sau khi client gửi đủ (WO-2) nhưng không bắt buộc.

---

## 1. Vấn đề + nguyên nhân gốc

| ID | Vấn đề | Root cause |
| --- | --- | --- |
| **C1** | Live monitor chỉ hiện cờ ⚑ + mức; KHÔNG hiện số chi tiết per-student (rời tab / focus / paste). Realtime KHÔNG repaint khi chỉ count đổi. | `_StudentMonitorTile` (`teacher_live_monitor_panel.dart:249-348`) chỉ đọc `integrityRiskLevel`; `_rosterUiPatchKeys` (`teacher_live_monitor_derived.dart:4-16`) THIẾU 3 count → `liveMonitorRowVisualChanged` bỏ qua. Data ĐÃ có trong Map (payload `examAttemptProgress.js:236-239`). |
| **C3** | Tổng hợp integrity per-bài-giao (high/medium/total) không hiển thị. API 3 tầng có sẵn nhưng KHÔNG UI nào gọi. | `getAssignmentIntegritySummary` chỉ tồn tại ở datasource/repo/impl; `TeacherGradingHubBloc._onLoad` không gọi. |
| **C4** | Nhật ký hoạt động lớp hiển thị record `integrity_flag` như mọi type (chỉ message), không icon/nhấn mạnh. | `_ActivityTab` itemBuilder (`teacher_classroom_detail_page.dart:1838-1853`) render generic, không switch theo `m['type']`. |

---

## 2. Audit downstream
- **C1:** thêm 3 key vào `_rosterUiPatchKeys` → `liveMonitorRowVisualChanged` + `liveMonitorPatchAffectsRosterUi` (cùng dùng set này) sẽ trigger repaint khi count đổi. Kiểm tra: 2 hàm này còn dùng ở test B4 (thêm). Không đổi shape socket.
- **C3:** thêm field `integritySummary` vào `TeacherGradingHubState` (copyWith + props) → mọi `state.copyWith(...)` cũ vẫn hợp lệ (param optional). Fetch best-effort (lỗi không làm hỏng trang grading).
- **C4:** chỉ thêm nhánh render theo `type` → không đổi data/bloc.

---

## 3. Quyết định thiết kế + cảnh báo
1. **C1:** hiển thị dòng chi tiết **chỉ khi có tín hiệu** (>0) để tile gọn; đọc `tabSwitchCount/focusLossSeconds/copyPasteAttempts` từ `student` Map; dùng 3 l10n key "chết" sẵn có (`teacherLiveMonitorTabSwitches/FocusLoss/CopyPaste`). Thêm 3 count vào `_rosterUiPatchKeys`.
2. **C3:** fetch `getAssignmentIntegritySummary` trong `_onLoad` (await TRƯỚC `fold` để tránh async-trong-fold); best-effort (fold lỗi → null, không chặn trang). Render 1 card nhỏ (high/medium/total) trên đầu danh sách attempt. Ẩn card nếu `total == 0`.
3. **C4:** khi `type == 'integrity_flag'` → `leading` = `Icon(Icons.flag, color: AppColors.danger)` + giữ message. (Tùy) badge "Integrity" dùng key `teacherLiveMonitorIntegrityLabel` sẵn có.
4. ⚠️ **Chạm là DỪNG & hỏi:** không đổi cấu trúc `_StudentMonitorTile` ngoài việc chèn 1 dòng chi tiết; không refactor grading hub state sang typed entity (giữ Map như repo hiện tại).

---

## 4. Scope IN / OUT

**IN:**
- `lib/feature/teacher/bloc/live_monitor/teacher_live_monitor_derived.dart` (C1 — `_rosterUiPatchKeys`)
- `lib/feature/teacher/widgets/teacher_live_monitor_panel.dart` (C1 — dòng chi tiết trong `_StudentMonitorTile`)
- `lib/feature/teacher/bloc/grading_hub/teacher_grading_hub_state.dart` (C3 — field mới)
- `lib/feature/teacher/bloc/grading_hub/teacher_grading_hub_bloc.dart` (C3 — fetch trong `_onLoad`)
- `lib/feature/teacher/teacher_assignment_grading_hub_view.dart` (C3 — card)
- `lib/feature/teacher/teacher_classroom_detail_page.dart` (C4 — `_ActivityTab` icon)
- `lib/l10n/app_en.arb` + `app_vi.arb` (C3 key mới) + `flutter gen-l10n`
- Test B4 (xem §8).

**OUT (DỪNG & hỏi):** backend; typed entity refactor; đổi API shape; live mirror page; analytics page.

---

## 5. CONTEXT BUNDLE

### TS-1 — `teacher_live_monitor_derived.dart` (C1): thêm 3 count vào patch keys

**anchor:** `const _rosterUiPatchKeys = {`
**BEFORE (verbatim dòng 4-16):**
```dart
/// Keys that affect live-monitor roster tiles (ignore answers-only socket payloads).
const _rosterUiPatchKeys = {
  'status',
  'progressPercent',
  'answeredCount',
  'totalItems',
  'integrityRiskLevel',
  'skillStrips',
  'fullName',
  'email',
  'username',
  'attemptId',
};
```
**AFTER:** thêm 3 dòng sau `'integrityRiskLevel',`:
```dart
  'integrityRiskLevel',
  'tabSwitchCount',
  'focusLossSeconds',
  'copyPasteAttempts',
```
**GOTCHA:** giữ nguyên các key khác. Đây là điều kiện để tile cập nhật realtime khi HS rời tab thêm mà risk chưa đổi mức.

### TS-2 — `teacher_live_monitor_panel.dart` (C1): dòng chi tiết trong tile

**file:** `english_for_community/lib/feature/teacher/widgets/teacher_live_monitor_panel.dart`
**anchor (chèn sau block progress):** `style: ExamSystemUi.captionMuted.copyWith(fontSize: 11),` (kết thúc `Text` progress, ngay trước `],` đóng block `if (inProgress) ...[`)
**BEFORE (verbatim block progress, dòng ~322-335):**
```dart
              const SizedBox(height: 3),
              Text(
                l10n.teacherLiveMonitorProgressLabel(
                  (student['answeredCount'] as num?)?.toInt() ?? 0,
                  (student['totalItems'] as num?)?.toInt() ?? 0,
                  (student['progressPercent'] as num?)?.toDouble() ?? 0,
                ),
                style: ExamSystemUi.captionMuted.copyWith(fontSize: 11),
              ),
            ],
```
**AFTER:** thêm dòng chi tiết integrity ngay sau `Text(...progress...)`:
```dart
              const SizedBox(height: 3),
              Text(
                l10n.teacherLiveMonitorProgressLabel( /* ... giữ nguyên ... */ ),
                style: ExamSystemUi.captionMuted.copyWith(fontSize: 11),
              ),
              _integrityDetailLine(context, l10n, student),
            ],
```
Thêm hàm helper trong `_StudentMonitorTile` (hoặc top-level trong file):
```dart
  Widget _integrityDetailLine(BuildContext context, AppLocalizations l10n, Map<String, dynamic> student) {
    final tabs = (student['tabSwitchCount'] as num?)?.toInt() ?? 0;
    final focus = (student['focusLossSeconds'] as num?)?.toInt() ?? 0;
    final paste = (student['copyPasteAttempts'] as num?)?.toInt() ?? 0;
    if (tabs == 0 && focus == 0 && paste == 0) return const SizedBox.shrink();
    final parts = <String>[
      if (tabs > 0) '${l10n.teacherLiveMonitorTabSwitches}: $tabs',
      if (focus > 0) '${l10n.teacherLiveMonitorFocusLoss}: ${focus}s',
      if (paste > 0) '${l10n.teacherLiveMonitorCopyPaste}: $paste',
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        parts.join('  ·  '),
        style: ExamSystemUi.captionMuted.copyWith(fontSize: 11, color: AppColors.warning),
      ),
    );
  }
```
**GOTCHA:** dùng 3 key l10n "chết" sẵn có (không thêm key). `AppColors.warning` khớp accent flagged. Ẩn khi tất cả = 0 (tile HS bình thường không đổi).

### TS-3 — `teacher_grading_hub_state.dart` (C3): field `integritySummary`

**BEFORE (verbatim — constructor + fields + copyWith + props, dòng 6-76 đã đọc):** field list hiện: status/errorMessage/assignment/stats/attempts/batchAiRunning/batchOpsRunning/attemptMutationId/filter/visibleAttempts.
**AFTER — thêm ở 4 chỗ (theo đúng pattern Equatable):**
1. Constructor: `this.integritySummary,`
2. Field: `final Map<String, dynamic>? integritySummary;`
3. `copyWith` param: `Map<String, dynamic>? integritySummary,` và body: `integritySummary: integritySummary ?? this.integritySummary,`
4. `props`: thêm `integritySummary,`
**GOTCHA:** optional nullable → mọi `copyWith` cũ vẫn hợp lệ.

### TS-4 — `teacher_grading_hub_bloc.dart` (C3): fetch trong `_onLoad`

**anchor:** `Future<void> _onLoad(`
**BEFORE (verbatim dòng 35-64):**
```dart
  Future<void> _onLoad(
    TeacherGradingHubLoadRequested event,
    Emitter<TeacherGradingHubState> emit,
  ) async {
    emit(state.copyWith(status: TeacherGradingHubStatus.loading, clearError: true));
    final r = await repository.getAssignmentGradingHub(assignmentId);
    r.fold(
      (f) => emit(state.copyWith(
        status: TeacherGradingHubStatus.error,
        errorMessage: f.message,
      )),
      (hub) {
        final m = Map<String, dynamic>.from(hub as Map);
        final attempts = (m['attempts'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        emit(state.copyWith(
          status: TeacherGradingHubStatus.success,
          assignment: m['assignment'] is Map
              ? Map<String, dynamic>.from(m['assignment'] as Map)
              : null,
          stats: m['stats'] is Map
              ? Map<String, dynamic>.from(m['stats'] as Map)
              : {},
          attempts: attempts,
          visibleAttempts: teacherGradingHubVisibleAttempts(attempts, state.filter),
        ));
      },
    );
  }
```
**AFTER:** await integrity summary TRƯỚC fold (best-effort), rồi đưa vào emit success:
```dart
    emit(state.copyWith(status: TeacherGradingHubStatus.loading, clearError: true));
    final integrityRes = await repository.getAssignmentIntegritySummary(assignmentId);
    final Map<String, dynamic>? integrity =
        integrityRes.fold((_) => null, (v) => Map<String, dynamic>.from(v as Map));
    final r = await repository.getAssignmentGradingHub(assignmentId);
    r.fold(
      (f) => emit(state.copyWith(
        status: TeacherGradingHubStatus.error,
        errorMessage: f.message,
      )),
      (hub) {
        final m = Map<String, dynamic>.from(hub as Map);
        final attempts = (m['attempts'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        emit(state.copyWith(
          status: TeacherGradingHubStatus.success,
          assignment: m['assignment'] is Map ? Map<String, dynamic>.from(m['assignment'] as Map) : null,
          stats: m['stats'] is Map ? Map<String, dynamic>.from(m['stats'] as Map) : {},
          attempts: attempts,
          visibleAttempts: teacherGradingHubVisibleAttempts(attempts, state.filter),
          integritySummary: integrity,
        ));
      },
    );
```
**GOTCHA:** KHÔNG dùng `async` trong callback `fold` (emit-after-await sẽ ném). Await integrity ở ngoài fold. `integrityRes.fold` chỉ dùng để trích giá trị (không side-effect). Lỗi integrity → null → card ẩn, trang vẫn load.

### TS-5 — `teacher_assignment_grading_hub_view.dart` (C3): card summary

**anchor (chèn sau header):** `TeacherGradingHubContextHeader(`
**BEFORE (verbatim dòng 378-387):**
```dart
                TeacherGradingHubContextHeader(
                  assignment: state.assignment,
                  stats: state.stats,
                  onClassroomTap: classroomId != null && classroomId.isNotEmpty
                      ? () => context.push('${TeacherClassroomDetailPage.routePath}/$classroomId')
                      : null,
                ),
                const SizedBox(height: AppSpacing.s5),
                Text(l10n.teacherGradingStudentAttemptsTitle, style: TeacherWebUi.sectionTitle(context)),
                const SizedBox(height: AppSpacing.s3),
```
**AFTER:** chèn card sau `SizedBox(height: s5)`, trước `Text(...StudentAttemptsTitle...)`:
```dart
                const SizedBox(height: AppSpacing.s5),
                _integritySummaryCard(context, l10n, state.integritySummary),
                Text(l10n.teacherGradingStudentAttemptsTitle, style: TeacherWebUi.sectionTitle(context)),
```
Helper (top-level trong file, ẩn khi null/total 0):
```dart
Widget _integritySummaryCard(BuildContext context, AppLocalizations l10n, Map<String, dynamic>? s) {
  if (s == null) return const SizedBox.shrink();
  final high = (s['high'] as num?)?.toInt() ?? 0;
  final medium = (s['medium'] as num?)?.toInt() ?? 0;
  final total = (s['total'] as num?)?.toInt() ?? 0;
  if (total == 0) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.s4),
    child: AppCard(
      variant: AppCardVariant.outline,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Row(
          children: [
            Icon(Icons.flag_outlined, size: 18, color: AppColors.danger),
            const SizedBox(width: AppSpacing.s2),
            Text(l10n.teacherGradingIntegritySummaryTitle, style: TeacherWebUi.listTitle(context)),
            const Spacer(),
            _integrityChip(l10n.teacherAnalyticsIntegrityHigh, high, AppColors.danger),
            const SizedBox(width: AppSpacing.s2),
            _integrityChip(l10n.teacherAnalyticsIntegrityMedium, medium, AppColors.warning),
            const SizedBox(width: AppSpacing.s2),
            _integrityChip(l10n.teacherGradingIntegrityTotal, total, AppColors.textMuted),
          ],
        ),
      ),
    ),
  );
}

Widget _integrityChip(String label, int value, Color color) => Text(
      '$label: $value',
      style: TeacherWebUi.metaMuted.copyWith(color: color, fontWeight: FontWeight.w600),
    );
```
**GOTCHA:** dùng `AppCard`/`AppCardVariant`/`AppColors`/`AppSpacing`/`TeacherWebUi` đã import trong file (kiểm tra import; nếu thiếu `AppCard` → import `core/ui/widget`). Reuse key analytics high/medium sẵn có; chỉ thêm 2 key title + total.

### TS-6 — `teacher_classroom_detail_page.dart` (C4): icon cho `integrity_flag`

**anchor:** `final msg = (m['message'] as String?) ?? (m['type'] as String?) ?? '';`
**BEFORE (verbatim dòng 1838-1853):**
```dart
            itemBuilder: (context, i) {
              final m = Map<String, dynamic>.from(state.activityRows[i] as Map);
              final msg = (m['message'] as String?) ?? (m['type'] as String?) ?? '';
              final at = DateTime.tryParse(m['createdAt'] as String? ?? '');
              return ListTile(
                tileColor: AppColors.surfaceCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  side: const BorderSide(color: AppColors.outline),
                ),
                title: Text(msg, style: TeacherWebUi.listTitle(context)),
                subtitle: at != null
                    ? Text(DateFormat.yMMMd().add_jm().format(at.toLocal()), style: TeacherWebUi.metaMuted)
                    : null,
              );
            },
```
**AFTER:** thêm `leading` khi `type == 'integrity_flag'`:
```dart
            itemBuilder: (context, i) {
              final m = Map<String, dynamic>.from(state.activityRows[i] as Map);
              final type = m['type'] as String?;
              final isIntegrity = type == 'integrity_flag';
              final msg = (m['message'] as String?) ?? (type) ?? '';
              final at = DateTime.tryParse(m['createdAt'] as String? ?? '');
              return ListTile(
                tileColor: AppColors.surfaceCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  side: BorderSide(color: isIntegrity ? AppColors.danger : AppColors.outline),
                ),
                leading: isIntegrity ? Icon(Icons.flag, color: AppColors.danger) : null,
                title: Text(msg, style: TeacherWebUi.listTitle(context)),
                subtitle: at != null
                    ? Text(DateFormat.yMMMd().add_jm().format(at.toLocal()), style: TeacherWebUi.metaMuted)
                    : null,
              );
            },
```
**GOTCHA:** chỉ đổi khi `integrity_flag`; các type khác giữ nguyên (leading null, viền outline).

### TS-7 — l10n keys mới (C3)

**app_en.arb** (cạnh nhóm `teacherGrading*`):
```json
  "teacherGradingIntegritySummaryTitle": "Integrity flags",
  "teacherGradingIntegrityTotal": "Total",
```
**app_vi.arb:**
```json
  "teacherGradingIntegritySummaryTitle": "Cảnh báo gian lận",
  "teacherGradingIntegrityTotal": "Tổng",
```
Chạy `flutter gen-l10n`. C1/C4 KHÔNG cần key mới (reuse `teacherLiveMonitor*` + `teacherAnalyticsIntegrity*` sẵn có).

### SYMBOL TABLE
| Symbol | Trạng thái | Ghi chú |
| --- | --- | --- |
| `_rosterUiPatchKeys` | [ĐỔI] | +3 count |
| `_integrityDetailLine` | [THÊM] | tile detail row (reuse dead l10n) |
| `TeacherGradingHubState.integritySummary` | [THÊM] | `Map<String,dynamic>?` |
| `getAssignmentIntegritySummary` | [CÓ] | trả `{high, medium, total}` |
| `teacherGradingIntegritySummaryTitle/Total` | [THÊM] l10n | EN+VI |
| `teacherLiveMonitorTabSwitches/FocusLoss/CopyPaste` | [CÓ, đang chết→dùng] | C1 |
| `teacherLiveMonitorIntegrityLabel` | [CÓ] | (tùy) C4 badge |

---

## 6b. Ràng buộc UI/UX
- Token-only (`AppColors`/`AppSpacing`/`TeacherWebUi`/`AppCard`); không hex/magic. Card ẩn khi total 0 (empty state). Dòng detail tile ẩn khi không tín hiệu. l10n EN+VI đủ.

## 6. Ràng buộc hiệu năng
- C1: dòng detail nằm trong tile đã `RepaintBoundary`+`ValueKey`; thêm 3 patch key → repaint đúng tile khi count đổi (không rebuild list). C3: 1 API call thêm/lần load (không trong build). Không N+1.

---

## 7. Hồi quy tối thiểu + account test
1. Live monitor: HS rời tab 3 lần → tile hiện "Tab switches: 3" cập nhật realtime (không cần reload).
2. HS bình thường (0 tín hiệu) → tile KHÔNG có dòng detail.
3. Mở grading hub 1 assignment có ≥1 attempt risk cao → card "Integrity flags: High x / Medium y / Total z". Assignment sạch (total 0) → không card.
4. Grading hub khi API integrity lỗi → trang vẫn load bình thường, chỉ ẩn card.
5. Tab Activity lớp có record `integrity_flag` → hiện cờ đỏ + viền đỏ; record khác không đổi.
- Account: `docs/dev/seeds/` (teacher sở hữu assignment + student đã thi có risk).

## 8. Lệnh verify
- `cd english_for_community && flutter gen-l10n && flutter analyze && flutter test`
- Test **B4** (pure, `test/teacher_live_monitor_derived_test.dart`): `summaryFromLiveMonitorStudents` đếm flagged = high+medium; `filterLiveMonitorStudents(flagged)` đúng; sau TS-1, `liveMonitorRowVisualChanged` trả `true` khi chỉ `tabSwitchCount` đổi.
- (Tùy) **B6** widget test tile: risk high/medium render cờ; có tín hiệu → render dòng detail.

---

## 9. HANDOFF PROMPT (Phase 3)

```text
BƯỚC 0: Đọc trọn docs/plantasks/BUG/20260712-exam-integrity-anticheat-audit/WO-3-teacher-report.md. Code lấy từ §5 CONTEXT BUNDLE. File lệch BEFORE → DỪNG, hỏi (doc thắng).
Sửa: teacher_live_monitor_derived.dart (+3 patch key), teacher_live_monitor_panel.dart (dòng detail tile), teacher_grading_hub_state.dart (field integritySummary), teacher_grading_hub_bloc.dart (fetch trong _onLoad, KHÔNG async-trong-fold), teacher_assignment_grading_hub_view.dart (card), teacher_classroom_detail_page.dart (icon integrity_flag), app_en.arb+app_vi.arb (2 key) + gen-l10n. Ngoài danh sách → DỪNG & hỏi.
TUYỆT ĐỐI KHÔNG: async trong Either.fold; typed-entity refactor; đổi API shape; đụng backend/mirror/analytics page; hardcode string (l10n EN+VI).
UI: token-only, AppCard/AppColors/TeacherWebUi; card ẩn khi total 0; dòng detail ẩn khi 0 tín hiệu.
Thêm test B4 (pure). Verify: gen-l10n + analyze + test.
Xong → self-audit → tracker.md → báo Opus.
```

## 10. Checklist OPUS AUDIT
- [ ] C1: `_rosterUiPatchKeys` +3 count; tile hiện detail khi >0, ẩn khi 0; realtime repaint khi count đổi.
- [ ] C3: `_onLoad` await integrity NGOÀI fold (không async-trong-fold); card ẩn khi total 0 / lỗi; state field + copyWith + props khớp.
- [ ] C4: `integrity_flag` có cờ đỏ; type khác không đổi.
- [ ] l10n EN+VI đủ 2 key mới; gen-l10n chạy; không hardcode.
- [ ] Token-only; no regression grading hub load khi integrity lỗi.
- [ ] Test B4 pass.
- Verdict: __ APPROVED / CHANGES REQUESTED.
