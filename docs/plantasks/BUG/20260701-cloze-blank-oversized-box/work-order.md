# WORK-ORDER — Ô blank Cloze/Gap (grammar) quá to/cao, lệch dòng so với chữ đoạn văn

| | |
|---|---|
| **Task ID** | `20260701-cloze-blank-oversized-box` |
| **Loại** | BUG |
| **Platform** | student mobile (mobile-first; widget dùng chung nếu web cũng render exam) |
| **Cỡ** | MICRO (1 file, 1 widget, ~6 dòng) |
| **Mục tiêu** | Ô nhập blank trong Cloze/Gap (grammar) không còn cao/to bất thường so với chữ đoạn văn xung quanh, dòng chứa blank không bị đẩy cao lệch hẳn. |
| **Kỳ vọng đầu ra** | `dart analyze` 0 lỗi · ảnh chụp 360×640: ô blank cao vừa phải, không "nổi" tách khỏi câu văn · vẫn nhập/sửa được bình thường, không regression Cloze lẫn Gap. |
| **Xác nhận từ user** | Lỗi là **"Ô quá to/cao, lệch dòng so với chữ"** (đã hỏi + chọn qua AskUserQuestion — không phải lỗi tràn/cắt chữ hay lệch tâm badge số). |
| **Trạng thái** | 📝 Work-order sẵn sàng — chờ implement |

---

## 1. Vấn đề + nguyên nhân gốc (dẫn chứng code)

### Triệu chứng (ảnh user)
Câu 16 "Cloze — fill blanks in a passage": 3 ô blank (badge 0/1/2, viền tím/xanh lá/cam) nằm giữa câu văn. Ô blank cao/to rõ rệt so với chữ xung quanh, khiến dòng chứa chúng bị đẩy cao bất thường, ô trông như "nổi" tách khỏi câu văn thay vì hoà vào dòng chữ.

### Ground-truth: kích thước lệch nhau bao nhiêu
File: `english_for_community/lib/feature/student/exams/integrated_exam_grammar_widgets.dart`

- `_GrammarBlankField` (`:127-206`) — ô blank tương tác, cố định:
  ```dart
  static const double _blankHeight = 40;         // :146
  ...
  return SizedBox(width: width, height: _blankHeight, ...)   // :151-153, width mặc định 120 (:134), không nơi nào override
  ```
- Chữ đoạn văn xung quanh dùng `ExamSystemUi.captionSecondary` = `fontSize: 12, height: 1.4` (`lib/core/ui/exam_system_ui.dart:44-49`) → line-box thực tế ≈ **16.8px**.
- → Ô blank cao **40px**, chữ xung quanh cao **~17px** ⇒ chênh lệch **≈2.35 lần**.
- Cả `_ClozeBody` (`:1186-1229`, dùng ở `:1200`) lẫn `_GapBody` (`:1290-1318`, dùng ở `:1302`) đều đặt `_GrammarBlankField` cùng `Text(...)` (đoạn văn) vào chung một `Wrap(crossAxisAlignment: WrapCrossAlignment.center, ...)`. `Wrap` set chiều cao mỗi "run" (dòng) bằng phần tử **cao nhất** trong run đó — tức là ô blank 40px quyết định chiều cao cả dòng, còn chữ 17px chỉ được `center` lọt thỏm giữa khoảng trống ⇒ đúng hiện tượng "dòng bị đẩy cao, ô nổi tách khỏi câu văn" trong ảnh.
- `_blankHeight = 40` là hằng số cục bộ tự đặt (không lấy từ `AppSpacing`/token nào) — không có căn cứ thiết kế, chỉ là số tự chọn.

### Vì sao bản review (không lỗi) không bị vậy
`_grammarAccentAnswerChip` (`:209-245`, dùng trong `GrammarObjectiveGradingReview._buildCloze`/`_clozePassageReviewPieces`, `:427-496`) — biến thể **read-only** cho chấm bài — KHÔNG có `SizedBox` chiều cao cố định, chỉ `Row(mainAxisSize: MainAxisSize.min)` + padding `vertical: 6` ⇒ cao tự nhiên theo nội dung (~28-30px), hài hoà với chữ xung quanh hơn nhiều. Đây là bằng chứng: chỉ biến thể **tương tác** (`_GrammarBlankField`) bị lỗi kích thước cứng, biến thể review thì không.

---

## 2. Audit downstream (consumer dùng chung)

| Nơi dùng `_GrammarBlankField` | File:line | Ảnh hưởng khi sửa |
|---|---|---|
| `_ClozeBody.build` (Cloze — nhiều blank trong 1 đoạn văn) | `:1200` | Sửa áp dụng — mục tiêu chính (ảnh user chụp đúng case này). |
| `_GapBody.build` (Gap — 1 blank giữa `textBefore`/`textAfter`) | `:1302` | Cùng lỗi (cùng `Wrap` + `crossAxisAlignment.center`), cùng hưởng lợi từ fix. |
| `_grammarAccentAnswerChip` / `GrammarObjectiveGradingReview` (review chấm bài) | `:209-245`, `:427-496` | **Không đụng** — widget khác hẳn (`_grammarAccentAnswerChip`), không dùng `_GrammarBlankField`/`_blankHeight`. |
| `IntegratedExamGrammarQuestionCard` (điều phối interactive vs review) | `:846+` | Không đổi logic điều phối, chỉ đổi kích thước bên trong `_GrammarBlankField`. |

→ Không có nơi nào khác import/khởi tạo `_GrammarBlankField` hay tham chiếu `_blankHeight` (đã grep toàn repo, chỉ 1 file). Sửa `_blankHeight` + padding nội bộ là an toàn, blast radius = đúng 1 widget private trong 1 file.

---

## 3. Quyết định thiết kế + cảnh báo

**Chọn:** giảm `_blankHeight` từ `40` → `32`, giảm `TextField.contentPadding` vertical từ `10` → `6` cho vừa khít chiều cao mới (32 − 2×6 = 20px, đủ chứa dòng text 12sp/height 1.4 với `isDense: true`).

**Vì sao chọn 32 (không phải số tuỳ ý, không phải ép sát 17px của chữ):**
- `docs/ui-ux-system/04-mobile-components.md:89` (§5.2 Filter chip) đã định nghĩa **Height 32** cho chip tương tác nhỏ trên mobile — đây là token/precedent kích thước gần nhất đã có sẵn trong hệ thống cho một phần tử tương tác compact dạng inline, dùng lại thay vì tự nghĩ số mới.
- **KHÔNG** ép xuống bằng chiều cao text (~17px): `10-accessibility.md` §2 "Hit target: Mobile tối thiểu 44dp" — dù `TextField` không chặt như button rời, hạ quá thấp (gần 17px) sẽ khó chạm/gõ chính xác trên mobile (nghiệp vụ chính là **học sinh làm bài thi trên di động** — mobile-first). 32 là điểm cân bằng: giảm đáng kể độ chênh lệch (2.35× → ~1.9×) mà vẫn giữ vùng chạm dùng được, đúng tinh thần "component có sẵn" thay vì tự vẽ.
- Badge column (`width: 30`, `:166`) và `width` mặc định (`120`, `:134`) **giữ nguyên** — user xác nhận lỗi là **chiều cao/lệch dòng**, không phải bề ngang badge hay tràn chữ (2 lựa chọn khác đã KHÔNG được chọn) → không mở rộng scope sang các trục đó.

**KHÔNG làm trong scope này:**
- Không đổi `_grammarAccentAnswerChip`/review mode (đã đúng, không lỗi).
- Không đổi badge width (30) hay field width (120).
- Không đổi màu/border/token khác — chỉ 2 con số kích thước.
- Không thêm biến thể "compact"/tham số mới cho `_GrammarBlankField` — sửa trực tiếp hằng số hiện có (đủ, không cần API mới).

---

## 4. Scope IN / OUT

**IN (được sửa):**
- `english_for_community/lib/feature/student/exams/integrated_exam_grammar_widgets.dart` — chỉ trong `_GrammarBlankField`: hằng số `_blankHeight` (`:146`) + `contentPadding` của `TextField` (`:196`).

**OUT (chạm là DỪNG & hỏi):**
- `_grammarAccentAnswerChip`, `GrammarObjectiveGradingReview` (review mode).
- Badge column width (`:166`, giữ `30`), field `width` mặc định (`:134`, giữ `120`).
- Mọi widget khác trong file (MCQ, matching, reorder, …).
- `teacher_skills_exam_grammar_editor_panel.dart` (builder — không có badge preview, không liên quan).

---

## 5. Diff cụ thể

**File:** `english_for_community/lib/feature/student/exams/integrated_exam_grammar_widgets.dart`

**(1) Dòng 146** — giảm chiều cao cố định:
```dart
// Trước
static const double _blankHeight = 40;
// Sau
static const double _blankHeight = 32; // khớp Filter chip height token — docs/ui-ux-system/04-mobile-components.md §5.2
```

**(2) Dòng ~190-197** — giảm padding dọc TextField cho vừa chiều cao mới:
```dart
// Trước
decoration: const InputDecoration(
  isDense: true,
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  disabledBorder: InputBorder.none,
  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
),
// Sau
decoration: const InputDecoration(
  isDense: true,
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  disabledBorder: InputBorder.none,
  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
),
```

**Ý định:** chỉ đổi 2 con số kích thước, giữ nguyên toàn bộ cấu trúc widget (`Material` → `Container` border → `Row` badge+`TextField`). Không đổi field/tham số công khai (`width`, `blankId`, `accent`, …).

**RÀNG BUỘC:** không đổi `width: 30` của badge column (`:166`) — chữ số badge (0/1/2, tối đa 2 ký tự trong đề hiện tại) vẫn đủ chỗ ở chiều cao 32.

---

## 6. Ràng buộc hiệu năng (PERF GATE)

Không áp dụng — đổi 2 hằng số kích thước, không đổi logic/rebuild/network.

## 6b. Ràng buộc UI/UX (UI/UX GATE — có chạm layout)

- [ ] Token/precedent: dùng chiều cao 32 theo Filter chip đã có (`04-mobile-components.md §5.2`), không tự nghĩ số mới — đúng `12-ai-guardrails.md` mục 1.3/2.3.
- [ ] Không đổi màu/`AppColors`, không hex literal mới.
- [ ] Test trên **360×640** (mobile, theo `12-ai-guardrails.md` mục 1.6): đoạn văn Cloze nhiều blank liên tiếp không vỡ dòng bất thường; badge số (0/1/2, cả số 2 chữ số nếu đề dài) vẫn đọc được rõ trong cột 30px ở chiều cao 32.
- [ ] Vẫn nhập/xoá/sửa được text trong ô sau khi giảm `contentPadding` (không bị cắt caret/chữ khi gõ).
- [ ] Không đụng review mode (`_grammarAccentAnswerChip`) — giữ nguyên như hiện tại.
- [ ] Hit target: 32dp thấp hơn khuyến nghị 44dp (`10-accessibility.md` §2) nhưng cao hơn nhiều so với chữ chạy (~17px) và dùng đúng precedent Filter-chip 32dp sẵn có trong hệ thống cho phần tử tương tác compact trên mobile — chấp nhận trade-off này cho use-case inline-in-text (không phải nút CTA rời); nếu audit thấy khó chạm trên thiết bị thật, quay lại thảo luận thay vì tự nâng số.

---

## 7. L10N GATE

Không áp dụng — không thêm string UI mới.

---

## 8. Hồi quy tối thiểu (smoke)

1. **Case chính (Cloze, ảnh user):** mở 1 exam có câu Grammar `grammar_cloze` với ≥2 blank trong cùng đoạn văn (đề mẫu tương tự câu 16 trong ảnh). Xác nhận: ô blank không còn "nổi" cao hẳn so với chữ, dòng không bị đẩy cao bất thường.
2. **Gap (`grammar_gap`, 1 blank giữa `textBefore`/`textAfter`):** cùng kiểm tra, không regression.
3. **Nhập liệu:** gõ đáp án dài (vd "discouraged"), backspace, xoá hết — vẫn hoạt động bình thường, không cắt/tràn hiển thị trong ô.
4. **Review mode** (khi `canReview`/chấm bài, hiển thị `_grammarAccentAnswerChip`): xác nhận **không đổi** (không thuộc scope sửa).
5. **Kích thước màn hình:** test tại 360×640 (mobile chuẩn theo guardrail) — không tràn/vỡ dòng khi đoạn văn dài nhiều blank.

---

## 9. Lệnh verify

```bash
cd english_for_community
dart analyze lib/feature/student/exams/integrated_exam_grammar_widgets.dart
flutter analyze
```
Yêu cầu: `dart analyze` / `flutter analyze` **0 lỗi**.

---

## 10. HANDOFF — Cursor IMPLEMENT (copy-paste, biên giới cứng)

```text
Bạn là IMPLEMENTER (Codex/Sonnet). Thực thi đúng work-order:
docs/plantasks/BUG/20260701-cloze-blank-oversized-box/work-order.md

CHỈ ĐƯỢC SỬA:
  - english_for_community/lib/feature/student/exams/integrated_exam_grammar_widgets.dart
    (chỉ trong class `_GrammarBlankField`: hằng số `_blankHeight` và `contentPadding` của TextField)
Ngoài phạm vi trên → DỪNG & hỏi.

LÀM (mục 5):
  1. Đổi `static const double _blankHeight = 40;` → `= 32;` (dòng ~146).
  2. Đổi `contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10)` →
     `EdgeInsets.symmetric(horizontal: 8, vertical: 6)` trong `InputDecoration` của TextField (dòng ~196).

TUYỆT ĐỐI KHÔNG:
  - Đổi badge column width (giữ `30`) hay field `width` mặc định (giữ `120`).
  - Đụng `_grammarAccentAnswerChip` / `GrammarObjectiveGradingReview` (review mode — không lỗi).
  - Đụng widget MCQ/matching/reorder khác trong cùng file.
  - Thêm tham số/biến thể mới cho `_GrammarBlankField`.
  - Hardcode màu/spacing mới ngoài 2 con số đã chỉ định.

VERIFY trước khi báo xong:
  - dart analyze lib/feature/student/exams/integrated_exam_grammar_widgets.dart → 0 lỗi
  - flutter analyze → 0 lỗi
  - Smoke mục 8 (ít nhất case 1, 2, 3) — chụp ảnh 360×640 so sánh trước/sau nếu được.
Dán kết quả verify + ảnh so sánh (nếu có) vào tracker (mục 12). Sau đó báo: "implementer đã xong, audit đi".
KHÔNG tự kết luận APPROVED.
```

---

## 11. Tracker

| Mốc | Trạng thái | Ghi chú / bằng chứng |
|---|---|---|
| Work-order (Opus) | ✅ Done | File này |
| IMPLEMENT (Cursor) | ⏳ | |
| Verify analyze | ⏳ | |
| Smoke (user, 360×640) | ⏳ | So sánh ảnh trước/sau — xem mục 8. |
| Opus AUDIT | ⏳ | Xem checklist mục 12 |

---

## 12. Checklist OPUS AUDIT (Phase 4) + HANDOFF Cursor AUDIT

### Checklist audit (đọc DIFF thật, đối chiếu plan)
- [ ] Chỉ đổi đúng 2 giá trị (`_blankHeight` → 32, `contentPadding.vertical` → 6) trong `_GrammarBlankField`.
- [ ] Không đụng badge width, field width, review mode, widget khác.
- [ ] Ảnh 360×640 (Cloze + Gap): ô blank không còn "nổi" tách dòng như ảnh gốc; vẫn đọc được badge số.
- [ ] Gõ/xoá text trong ô vẫn mượt, không bị cắt.
- [ ] `dart analyze` 0 lỗi.
- **Verdict:** APPROVED | CHANGES REQUESTED → ghi tracker, finding = file:line + fix cụ thể.

### HANDOFF — Cursor AUDIT (copy-paste, "nhờ cursor audit luôn")
```text
Bạn là AUDITOR (model khác implementer). KHÔNG sửa code — chỉ đọc DIFF + verify, ra verdict.
Plan: docs/plantasks/BUG/20260701-cloze-blank-oversized-box/work-order.md (mục 12 checklist).

Kiểm:
  1. Mở câu Grammar Cloze nhiều blank (giống câu 16 trong ảnh gốc bug) ở 360×640 —
     ô blank không còn cao/to bất thường so với chữ đoạn văn, dòng không bị đẩy lệch.
  2. Câu Grammar Gap (1 blank) — tương tự, không regression.
  3. Gõ/xoá đáp án trong ô — vẫn hoạt động bình thường, không cắt chữ/caret.
  4. Review mode (chấm bài) — không đổi, vẫn dùng `_grammarAccentAnswerChip` như cũ.
  5. Diff chỉ trong `_GrammarBlankField` (2 giá trị), không lan ra file/widget khác.
  6. dart analyze / flutter analyze 0 lỗi.

Mỗi finding: file:line + mô tả + fix đề xuất. Verdict: APPROVED | CHANGES REQUESTED. Ghi vào tracker mục 11.
```
