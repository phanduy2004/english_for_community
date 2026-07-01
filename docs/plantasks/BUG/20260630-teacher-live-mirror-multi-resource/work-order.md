# WORK-ORDER — Teacher Live Mirror không hiển thị bài làm khi skill có nhiều bài (multi-resource)

| | |
|---|---|
| **Task ID** | `20260630-teacher-live-mirror-multi-resource` |
| **Loại** | BUG |
| **Platform** | teacher web (fix chính) · student mobile (chỉ đọc, không sửa) · backend (không sửa) |
| **Cỡ** | T1 (1 file chính + l10n) |
| **Mục tiêu** | Màn giám sát quá trình làm bài (live mirror) phải hiển thị đúng **bài làm của học sinh ở MỌI bài/exercise trong cùng 1 kĩ năng**, không chỉ bài đầu tiên. |
| **Kỳ vọng đầu ra** | `dart analyze` 0 lỗi · Reading skill có ≥2 resource: teacher thấy bài làm của tất cả resource (không còn trống/đứng yên khi học sinh chuyển bài) · không regression skill 1-resource. |
| **Trạng thái** | ✅ Opus tự code — IMPLEMENT + self-AUDIT xong (chờ smoke E2E của user) |

---

## 1. Vấn đề + nguyên nhân gốc (dẫn chứng code)

### Triệu chứng (user)
1. Màn giám sát **không hiển thị bài làm** của học sinh.
2. Khi học sinh **chuyển sang bài khác trong cùng 1 kĩ năng** thì màn giám sát **vẫn không hiển thị** (đứng yên ở bài cũ / trống).

### Ground-truth: 1 skill section có thể chứa NHIỀU resource (bài)
- Backend lưu mảng resources cho mỗi skill section:
  `english_for_community_backend/src/services/examSkillSectionResources.js:5` — `resourcesFromSkillSection(sec)` trả về **mảng** `sec.resources[]` (fallback `resourceId` đơn lẻ).
- Student runner cho phép **chuyển giữa nhiều bài trong 1 skill** bằng resource switcher:
  `lib/feature/student/exams/exam_embedded_skill_panel.dart:93` (`_resourceIndex`), `:298-299` (next), `:523-532` (UI chips chọn resource — chỉ hiện khi `resources.length > 1`).
- Đáp án được student lưu **gộp theo section**, key theo `questionId` (reading) / `cueIndex` (listening), KHÔNG tách theo resource:
  `lib/feature/student/exams/integrated_exam_runner_page.dart:617-630` (`readingAnswers` map gộp), `:652-674` (`listeningCues` map gộp, index toàn cục).
- Student tự lọc đáp án theo resource hiện tại đúng cách:
  `exam_embedded_skill_panel.dart:181-192` — `_filteredReadingAnswers()` lọc `initialReadingAnswers` theo `reading.questions.map((q) => q.id)`.

### Root cause: teacher live mirror chỉ render `resources.first`
File: `lib/feature/student/exams/student_exam_live_mirror_view.dart`

- `_buildReadingMirror` **chỉ dùng resource đầu tiên**:
  ```dart
  // :564-581
  final readingId = resources.isNotEmpty ? (resources.first['id'] as String?)?.trim() ?? '' : '';
  ...
  return _ReadingLiveMirrorBody(readingId: readingId, selectedAnswers: selected);
  ```
  → Mirror load đúng **1 bài reading** (resource[0]) và chỉ match `selectedAnswers[q.id]` cho câu hỏi của bài đó.

- `readingAnswers` là map gộp toàn section. Khi học sinh đang làm **bài #2** (Reading Part 2 — question id khác), không id nào khớp câu hỏi của bài #1 đang hiển thị → tất cả câu hiện **trống** → "không hiển thị bài làm" (triệu chứng 1).
- Mirror **không có cách nào** để xem/chuyển sang bài #2 trong cùng skill (không có resource switcher, không follow resource của học sinh) → "chuyển bài vẫn không hiển thị" (triệu chứng 2).
- `_ReadingLiveMirrorBody` còn chặn hiển thị khi map đáp án-rỗng-cho-bài-này:
  `:777-779` `if (widget.selectedAnswers.isEmpty) return Text(...readingEmpty)` — nhưng vì `selectedAnswers` là map gộp toàn section, khi học sinh đã trả lời bài #2 thì map **không rỗng**, mirror render câu hỏi bài #1 nhưng **không câu nào được chọn** → teacher thấy bài trống dù học sinh đang làm.

### Không có sync resource-index
`integrated_exam_runner_page.dart:310-318` — student chỉ sync `activePartIndex`, `activePartKey`, `grammarNavIndex`, `currentGrammarItemId`. **`_resourceIndex` của từng section KHÔNG được sync** → backend/mirror không biết học sinh đang ở bài nào trong skill.

---

## 2. Audit downstream (consumer dùng chung)

| Nơi dùng | resources nhiều bài? | Kết luận |
|---|---|---|
| `teacher_exam_skill_work_panel.dart` (chấm bài sau nộp) | ✅ render **mỗi resource 1 block** (`_buildResourceBlock`) | Đã đúng — là khuôn mẫu để bám theo |
| `examLiveSkillStrips.js` (question strip) | ✅ lặp `resourcesFromSkillSection(sec)`, nối câu hỏi mọi resource | Đã đúng |
| `student_exam_live_mirror_view.dart` (LIVE mirror) | ❌ chỉ `resources.first` (reading) | **Đây là chỗ lỗi — outlier duy nhất** |

→ Backend đã trả đủ data (mọi resource có trong `examSnapshot.sections[].resources`); answers đã gộp đủ. **Chỉ cần sửa phía teacher mirror, KHÔNG đụng backend/student/schema.**

---

## 3. Quyết định thiết kế + cảnh báo

**Phương án CHỌN (teacher-side, additive, rủi ro thấp):**
Trong live mirror, với skill section có **nhiều resource**, render **TẤT CẢ resource** dưới dạng các block xếp chồng (giống pattern `_buildMergedListeningMirror` / sub-mirror đã có sẵn trong file), mỗi block có header "Bài i/N · <title>". Mỗi block tự lọc đáp án theo câu hỏi của resource đó (map gộp truyền nguyên vào `_ReadingLiveMirrorBody`, nó tự match theo `q.id`).

**Vì sao chọn:**
- Deterministic: teacher luôn thấy bài làm ở **mọi** bài, không phụ thuộc việc biết "học sinh đang ở bài nào" (không cần sync resource-index — tránh đụng student runner + backend liveView).
- Bám pattern có sẵn (merged listening sub-block), không phát sinh widget lạ.
- Không schema/migration, không đổi public signature, không đụng socket.

**Phạm vi bắt buộc:** chỉ **reading** (skill bị lỗi xác nhận; reading nhiều passage là cấu trúc thi phổ biến).
**Tùy chọn (nếu exam có nhiều resource comprehension):** áp cùng cách cho **listening comprehension** — xem mục 5b. Không bắt buộc cho lần fix này.

**KHÔNG làm trong scope này (defer):**
- Sync `_resourceIndex` student → liveView để mirror highlight đúng bài học sinh đang làm (nice-to-have; cần đụng student runner + `examAttemptProgress.js`). Ghi nhận follow-up, KHÔNG làm.
- Đổi hành vi auto-follow part (`_syncStudentPartIndex` :144-150) — giữ nguyên.
- Listening dictation: **giữ nguyên** (cue dùng index toàn cục `_dictationCueOffsets`, mirror đã hiển thị toàn bộ text cue — không lỗi).

---

## 4. Scope IN / OUT

**IN (được sửa):**
- `lib/feature/student/exams/student_exam_live_mirror_view.dart` — `_buildReadingMirror` + `_ReadingLiveMirrorBody` (+ thêm 1 widget header nhỏ).
- `lib/l10n/app_en.arb` + `lib/l10n/app_vi.arb` — string mới (nếu thêm). Chạy `flutter gen-l10n`.

**OUT (chạm là DỪNG & hỏi):**
- Mọi file backend (`examAttemptProgress.js`, `examLiveSkillStrips.js`, `examLiveMonitorService.js`, …).
- `exam_embedded_skill_panel.dart`, `integrated_exam_runner_page.dart` (student runner).
- `teacher_student_live_screen_bloc.dart`, `teacher_live_monitor_bloc.dart`, `mergeTeacherLivePayload`.
- `teacher_exam_question_strip.dart`, `teacher_page_scaffold.dart`.

---

## 5. Diff cụ thể

### 5a. `student_exam_live_mirror_view.dart` — Reading mirror render mọi resource

**(1) Sửa `_buildReadingMirror` (:564-581)** — bỏ `resources.first`, lặp mọi reading resource:

```dart
Widget _buildReadingMirror(
  BuildContext context,
  List<Map<String, dynamic>> resources,
  Map<String, dynamic> ans,
) {
  final raw = ans['readingAnswers'];
  final selected = <String, int>{};
  if (raw is Map) {
    raw.forEach((k, v) {
      if (v is num) selected['$k'] = v.toInt();
    });
  }

  final readingResources = resources
      .where((r) => ((r['id'] as String?)?.trim().isNotEmpty ?? false))
      .toList();
  if (readingResources.isEmpty) {
    return _buildGenericSkillMirror(context, 'reading', ans['completed'] == true);
  }
  if (readingResources.length == 1) {
    return _ReadingLiveMirrorBody(
      readingId: (readingResources.first['id'] as String).trim(),
      selectedAnswers: selected,
    );
  }

  // Multi-resource: render từng bài để teacher thấy bài làm dù học sinh đang ở bài nào.
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < readingResources.length; i++) ...[
        if (i > 0) const Divider(height: 24),
        _ReadingResourceHeader(
          index: i + 1,
          total: readingResources.length,
          title: (readingResources[i]['title'] as String?)?.trim() ?? '',
        ),
        const SizedBox(height: 8),
        _ReadingLiveMirrorBody(
          key: ValueKey('reading_mirror_${readingResources[i]['id']}'),
          readingId: (readingResources[i]['id'] as String).trim(),
          selectedAnswers: selected, // body tự lọc theo q.id của bài này
        ),
      ],
    ],
  );
}
```

**(2) Thêm widget header nhỏ** (đặt cạnh `_ReadingLiveMirrorBody`):

```dart
class _ReadingResourceHeader extends StatelessWidget {
  const _ReadingResourceHeader({
    required this.index,
    required this.total,
    required this.title,
  });

  final int index;
  final int total;
  final String title;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.teacherLiveMirrorExerciseLabel(index, total);
    return Row(
      children: [
        Icon(Icons.menu_book_outlined, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(label, style: ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w600)),
        if (title.isNotEmpty) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text('• $title',
                style: ExamSystemUi.captionMuted,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ],
    );
  }
}
```

**(3) Sửa `_ReadingLiveMirrorBody.build` (:763-849)** — đừng chặn cả bài khi map gộp không rỗng; chỉ báo nhẹ khi bài NÀY chưa có đáp án, vẫn render câu hỏi:

```dart
final reading = _reading;
if (reading == null) return const SizedBox.shrink();

// Đáp án thuộc về bài này (lọc theo q.id của chính reading doc này).
final questionIds = reading.questions.map((q) => q.id).toSet();
final answeredHere = widget.selectedAnswers.keys.any(questionIds.contains);

return Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    if (reading.title.isNotEmpty)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(reading.title,
            style: ExamSystemUi.captionSecondary.copyWith(fontWeight: FontWeight.w600)),
      ),
    if (!answeredHere)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(context.l10n.teacherLiveMirrorReadingEmpty,
            style: ExamSystemUi.captionMuted),
      ),
    ...reading.questions.asMap().entries.map((entry) {
      // ... GIỮ NGUYÊN block render câu hỏi hiện tại (:789-846) ...
    }),
  ],
);
```
> Bỏ early-return `if (widget.selectedAnswers.isEmpty) return ...readingEmpty` ở `:777-779` (thay bằng caption `!answeredHere` ở trên). Lý do: học sinh có thể đã làm bài khác cùng section ⇒ map gộp không rỗng nhưng bài này chưa làm; vẫn cần render câu hỏi để teacher thấy đề.

### 5b. (TÙY CHỌN, không bắt buộc) Listening comprehension nhiều resource
Hiện `_buildListeningCompMirror` (:417-459) gộp `listeningCompAnswers` thành Q1..QN không phân resource. Nếu exam có >1 comp resource, cần loader riêng theo từng doc (giống `_ReadingLiveMirrorBody`). **Defer** — chỉ làm nếu nghiệm thu phát hiện exam thực tế có nhiều comp resource. Nếu làm: tạo `_ListeningCompResourceBody(comprehensionId, compAnswers)` load `ListeningComprehension` qua repository tương ứng, map đáp án theo question `_id`.

---

## 6. Ràng buộc hiệu năng (PERF GATE — có rủi ro: load nhiều reading doc)

- ✅ Mỗi `_ReadingLiveMirrorBody` đã tự guard refetch: `didUpdateWidget` chỉ `_load()` khi `readingId` đổi (:736-741) → socket patch (đổi `selectedAnswers`) **không** refetch, chỉ rebuild rẻ.
- ✅ Dùng `ValueKey('reading_mirror_<id>')` để giữ state per-resource, tránh load lại khi list rebuild.
- ✅ N resource nhỏ (thường 2–3). Không dùng `ListView` lồng — block nằm trong `SingleChildScrollView` sẵn có ở `:240`, dùng `Column` shrink-wrap.
- ❌ KHÔNG gọi API trong `build()`; chỉ trong `initState/_load`.
- Kiểm tra: mở mirror 1 học sinh có Reading 2 passage, để socket bắn liên tục → không thấy spinner reading nhấp nháy / không refetch lặp.

---

## 6b. Ràng buộc UI/UX + LAYOUT AUDIT (user yêu cầu "audit để tránh lỗi layout")

Bám `docs/ui-ux-system/` (tối thiểu `README.md`, `12-ai-guardrails.md`, `11-implementation-mapping.md`).

- [ ] **Token-only**: dùng `AppColors`, `AppSpacing`, `AppRadius`, `ExamSystemUi.*` (đã có) — không hex/spacing magic. Header mới chỉ dùng style có sẵn.
- [ ] **Overflow web hẹp**: title resource phải `maxLines: 1 + ellipsis` trong `Expanded` (đã ghi trong diff). Không đặt `Text` dài trong `Row` không bọc `Expanded`.
- [ ] **Bounded height**: mirror gốc là `Column > Expanded(SingleChildScrollView)` (:239-247); parent `TeacherPageScaffold(scrollable:false)` cấp bounded height qua `Expanded` (`teacher_page_scaffold.dart:76-93`) → **an toàn**. Block reading mới nằm TRONG `SingleChildScrollView` ⇒ tuyệt đối KHÔNG bọc thêm `Expanded`/`ListView` height-vô-hạn trong block (sẽ vỡ layout). Dùng `Column` shrink-wrap + `Divider(height:)`.
- [ ] **loading/empty/error đủ**: mỗi block reading có loading (`StudentMobileUi.runnerLoading`), error (`Text(_error)`), empty (caption "chưa trả lời") — giữ đủ 3 trạng thái.
- [ ] **Không amber** cho body; amber chỉ celebrate.
- [ ] Audit nhanh các builder anh em trong cùng file (`_buildListeningMirror`, `_buildWritingMirror`, `_buildSpeakingMirror`) xem có chỗ nào `Row` chứa text dài thiếu `Expanded`/ellipsis (rủi ro overflow web). Ghi lại nếu phát hiện, KHÔNG sửa ngoài scope.

---

## 7. L10N GATE (string mới)

Thêm vào **cả** `app_en.arb` và `app_vi.arb`, rồi `flutter gen-l10n`:

```jsonc
// app_en.arb
"teacherLiveMirrorExerciseLabel": "Exercise {index}/{total}",
"@teacherLiveMirrorExerciseLabel": {
  "placeholders": { "index": {"type": "int"}, "total": {"type": "int"} }
},
// app_vi.arb
"teacherLiveMirrorExerciseLabel": "Bài {index}/{total}",
```
(Tái sử dụng `teacherLiveMirrorReadingEmpty` đã có cho caption "chưa trả lời".)

---

## 8. Hồi quy tối thiểu (smoke)

Account test: xem `docs/dev/seeds/` (teacher + student cùng 1 exam realtime). Seed teacher: `seedTeacherHoangDongData.js`.

1. **Reading 1 resource** (regression): mirror hiển thị đúng như cũ, không trống.
2. **Reading ≥2 resource** (bug chính): học sinh trả lời bài #2 → teacher mirror thấy block "Bài 1/2" (caption chưa trả lời + câu hỏi) **và** block "Bài 2/2" có đáp án học sinh vừa chọn. Học sinh chuyển qua lại giữa bài 1↔2 và trả lời → teacher thấy cập nhật ở đúng block, **không còn đứng yên/trống**.
3. **Grammar / Listening / Writing / Speaking**: không regression (chỉ reading đổi).
4. **Web hẹp (~360–800px)** + **mobile workspace**: không overflow, title resource ellipsis gọn.
5. Socket bắn liên tục khi học sinh gõ: reading không refetch lặp (không nhấp nháy spinner).

---

## 9. Lệnh verify

```bash
cd english_for_community
flutter gen-l10n
dart analyze lib/feature/student/exams/student_exam_live_mirror_view.dart lib/l10n
flutter analyze
# (nếu có) flutter test test liên quan teacher exam
```
Yêu cầu: `dart analyze` / `flutter analyze` **0 lỗi**.

---

## 10. HANDOFF — Cursor IMPLEMENT (copy-paste, biên giới cứng)

```text
Bạn là IMPLEMENTER (Codex/Sonnet). Thực thi đúng work-order:
docs/plantasks/BUG/20260630-teacher-live-mirror-multi-resource/work-order.md

CHỈ ĐƯỢC SỬA:
  - english_for_community/lib/feature/student/exams/student_exam_live_mirror_view.dart
  - english_for_community/lib/l10n/app_en.arb
  - english_for_community/lib/l10n/app_vi.arb
Ngoài 3 file trên → DỪNG & hỏi.

LÀM:
  1. Sửa _buildReadingMirror: render MỌI reading resource (mục 5a-(1)), bỏ `resources.first`.
  2. Thêm widget _ReadingResourceHeader (mục 5a-(2)).
  3. Sửa _ReadingLiveMirrorBody.build: bỏ early-return readingEmpty, render câu hỏi luôn + caption khi bài này chưa làm (mục 5a-(3)).
  4. Thêm string teacherLiveMirrorExerciseLabel (EN+VI), chạy flutter gen-l10n.

TUYỆT ĐỐI KHÔNG:
  - Đụng backend, student runner, bloc, mergeTeacherLivePayload, question_strip, page_scaffold.
  - Đổi public signature / thêm schema / hardcode màu-spacing / hardcode string UI.
  - Bọc Expanded/ListView height-vô-hạn trong block reading (nằm trong SingleChildScrollView).

PERF: không API trong build(); giữ ValueKey per-resource; không refetch khi chỉ đổi đáp án.
UI/UX: token-only; title resource maxLines:1 + ellipsis trong Expanded; đủ loading/empty/error.

VERIFY trước khi báo xong:
  - flutter gen-l10n OK
  - dart analyze / flutter analyze 0 lỗi
  - Smoke mục 8 (ít nhất case 1, 2, 4)
Dán kết quả verify + diff vào tracker (mục 11). Sau đó báo: "implementer đã xong, audit đi".
KHÔNG tự kết luận APPROVED.
```

---

## 11. Tracker

| Mốc | Trạng thái | Ghi chú / bằng chứng |
|---|---|---|
| Work-order (Opus) | ✅ Done | File này |
| IMPLEMENT (Opus tự code) | ✅ Done | Sửa `student_exam_live_mirror_view.dart` (`_buildReadingMirror` lặp mọi resource, `_ReadingResourceHeader`, `_ReadingLiveMirrorBody` bỏ early-return + `super.key`, gỡ `l10n` thừa ở `_buildMergedListeningMirror`) + `app_en.arb`/`app_vi.arb` (`teacherLiveMirrorExerciseLabel`) + `flutter gen-l10n`. |
| Verify analyze | ✅ Pass | `dart analyze lib/feature/student/exams/student_exam_live_mirror_view.dart lib/l10n` → **No issues found!**. Analyze 2 thư mục teacher+student exams: 38 issue đều **pre-existing ở file khác**, không có file đã sửa. |
| Opus self-AUDIT | ✅ APPROVED (code) | Đối chiếu plan: không scope-creep, không đụng file OUT, không đổi signature/schema, token-only, ellipsis chống overflow, không refetch khi socket patch (guard `didUpdateWidget`), l10n EN+VI đủ. |
| Smoke E2E (user) | ⏳ | Cần chạy app với exam Reading ≥2 resource — xem mục 8. |
| Cross-AUDIT Cursor (tùy chọn) | ⏳ | Handoff mục 12 — chạy nếu muốn cross-model gate. |

### Nhật ký Opus self-audit (Phase 4)
- ✅ `_buildReadingMirror`: bỏ `resources.first`; nhánh 1-resource giữ nguyên hành vi (no regression); nhánh ≥2 resource render từng `_ReadingLiveMirrorBody` với `ValueKey` riêng + header "Bài i/N".
- ✅ `_ReadingLiveMirrorBody`: truyền nguyên map gộp `selectedAnswers`; mỗi body tự match `q.id` của doc → đáp án bài #2 chỉ hiện ở block #2. Bỏ early-return `readingEmpty`; thay bằng caption khi `!answeredHere` nhưng VẪN render câu hỏi (teacher thấy đề dù học sinh chưa làm bài đó).
- ✅ Perf: reading body chỉ `_load()` khi `readingId` đổi (`didUpdateWidget`) → socket patch đổi đáp án không refetch. N resource nhỏ; block nằm trong `SingleChildScrollView` sẵn có, dùng `Column` shrink-wrap + `Divider`, không lồng `Expanded`/`ListView` vô hạn.
- ✅ Layout/UI: title resource `maxLines:1 + ellipsis` trong `Expanded` (chống overflow web hẹp); token-only (`AppColors`/`ExamSystemUi`); đủ loading/error/empty.
- ⚠️ Defer (đã ghi scope): listening comprehension nhiều resource (mục 5b) + sync `_resourceIndex` student→liveView — KHÔNG làm lần này.
- ℹ️ Ghi nhận (ngoài scope, không sửa): `teacher_student_live_screen_page.dart:3` có unused import `app_loading_indicator.dart` (pre-existing).

---

## 12. Checklist OPUS AUDIT (Phase 4) + HANDOFF Cursor AUDIT

### Checklist audit (đọc DIFF thật, đối chiếu plan)
- [ ] `_buildReadingMirror` lặp **mọi** resource, không còn `resources.first`; nhánh 1-resource giữ hành vi cũ (no regression).
- [ ] `_ReadingLiveMirrorBody` truyền `selectedAnswers` gộp, tự lọc theo `q.id` — đáp án bài #2 hiện đúng ở block #2, không lẫn sang #1.
- [ ] Bỏ early-return `readingEmpty`; bài chưa làm vẫn render câu hỏi + caption.
- [ ] `ValueKey` per-resource có mặt; không refetch khi socket patch (đọc `didUpdateWidget`).
- [ ] L10n EN+VI có `teacherLiveMirrorExerciseLabel`; generated cập nhật; không hardcode string.
- [ ] Token-only; không overflow web hẹp (Expanded + ellipsis); không Expanded/ListView vô-hạn trong scroll.
- [ ] Không đụng file OUT-scope; không đổi signature/schema.
- [ ] `dart analyze` 0 lỗi; smoke case 1/2/4 pass.
- **Verdict:** APPROVED | CHANGES REQUESTED → ghi tracker, finding = file:line + fix cụ thể.

### HANDOFF — Cursor AUDIT (copy-paste, "nhờ cursor audit luôn")
```text
Bạn là AUDITOR (model khác implementer). KHÔNG sửa code — chỉ đọc DIFF + verify, ra verdict.
Plan: docs/plantasks/BUG/20260630-teacher-live-mirror-multi-resource/work-order.md (mục 12 checklist).

Kiểm:
  1. Reading multi-resource: mở student có Reading ≥2 passage, học sinh trả lời lần lượt bài 1, bài 2;
     teacher live mirror phải hiện ĐÚNG đáp án ở từng block "Bài i/N", cập nhật realtime, không trống/đứng yên.
  2. Reading 1 resource: không regression.
  3. Skill khác (grammar/listening/writing/speaking): không đổi.
  4. Web hẹp 360–800px + mobile workspace: không overflow; title ellipsis.
  5. dart analyze / flutter analyze 0 lỗi; không refetch reading khi gõ liên tục (xem DevTools/log).
  6. Không đụng file OUT-scope; không hardcode string/màu.

Mỗi finding: file:line + mô tả + fix đề xuất. Verdict: APPROVED | CHANGES REQUESTED. Ghi vào tracker mục 11.
```
