# WORK-ORDER — Màn Writing: redesign dialog "Save draft?" (nút dồn dọc) + font ô nhập essay quá to/lệch tài liệu

| | |
|---|---|
| **Task ID** | `20260703-writing-save-dialog-and-editor-font` |
| **Loại** | BUG (UI polish / token-consistency) |
| **Platform** | student mobile (mobile-first) |
| **Cỡ** | MICRO (1 file · 2 dialog + 1 dòng style editor) |
| **Mục tiêu** | (1) Dialog "Save draft?" hiển thị **2 nút nằm ngang** gọn gàng, đúng token (bg/radius/typography), body chữ `textPrimary` — không còn 3 nút dồn dọc canh phải như lỗi tràn. (2) Font ô nhập essay nhỏ lại + thống nhất với bộ tài liệu (về token `bodyLg` 15sp thay vì 16 lệch scale). |
| **Kỳ vọng đầu ra** | `dart analyze` 0 lỗi · 360×640: dialog Save draft 2 nút ngang (Discard + Save), title/body đọc rõ `textPrimary`, bo góc `sheet` · font ô nhập = 15sp, không còn "to" hơn phần đọc · không regression luồng save/discard/exit. |
| **Xác nhận từ user** | (a) Font ô nhập → **15sp (bodyLg)** — đã chọn qua AskUserQuestion. (b) Vấn đề dialog = **"các button xếp dọc, chữ không hiển thị hàng ngang do dài quá"** → user muốn **sửa cho ra hàng ngang**. Cách đúng chuẩn mobile: giảm còn 2 nút ngang (doc `04 §6.1`), Cancel = dismiss. |
| **Trạng thái** | 📝 Work-order sẵn sàng — chờ implement |

---

## 1. Vấn đề + nguyên nhân gốc (dẫn chứng code)

**File duy nhất:** `english_for_community/lib/feature/writing/writing_task_page.dart`

### 1A. Dialog "Save draft?" — 3 nút bị dồn dọc + sai token

Code hiện tại (`_onWillPop`, `:252-281`):
```dart
final shouldSave = await showDialog<bool>(
  context: context,
  builder: (ctx) {
    final t = ctx.l10n;
    return AlertDialog(
    backgroundColor: Colors.white,          // ❌ hardcode màu (guardrail 12 §2.1)
    surfaceTintColor: Colors.white,         // ❌ hardcode
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),  // card=12; dialog nên sheet=16 (04 §6.1)
    title: Text(t.writingSaveDraftTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
    content: Text(
      t.writingSaveDraftMessage,
      style: const TextStyle(color: AppColors.textSecondary),   // ❌ body dùng textSecondary (guardrail 12 §2.2 → reject)
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, null),  child: Text(t.cancel, ...textSecondary)),      // Cancel
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.writingDiscardButton, ...danger)),// Discard
      TextButton(onPressed: () => Navigator.pop(ctx, true),  child: Text(t.saveChanges, ...bold primary)),   // Save Changes
    ],
  );
  },
);
```

**Nguyên nhân "nút dồn dọc" (chính xác):** `AlertDialog` bọc `actions` trong `OverflowBar` — xếp **ngang nếu vừa**, không vừa thì **tự xuống dọc, canh phải**. 3 nút text "Cancel / Discard / Save Changes" quá dài cho content-width ~272px (320 − 2×24 pad) trên điện thoại → tràn → rớt dọc → đúng hiện tượng trong ảnh. Đây **không phải bug logic**, là hành vi tự-wrap của Material khi nhồi 3 action dài vào 1 hàng hẹp.

**Các lỗi tuân thủ kèm theo:** `Colors.white` hardcode (×2), radius `card`(12) thay vì `sheet`(16), body `textSecondary` (vi phạm guardrail — body phải `textPrimary`), 3 nút toàn `TextButton` phẳng → không có phân cấp (không thấy đâu là hành động chính).

**Result-handling (`:283-296`) — GIỮ NGUYÊN logic:**
- `null` → return (ở lại màn). ← đạt được qua **dismiss** (tap ra ngoài / Back): `showDialog` mặc định `barrierDismissible: true`, dialog không set khác → tap ngoài trả `null`. **Bỏ nút Cancel không đổi hành vi "ở lại".**
- `false` → `Navigator.pop()` (thoát, không lưu). ← nút **Discard**.
- `true` → set `_shouldCloseAfterSave=true` + `SaveDraftEvent` (lưu rồi đóng). ← nút **Save**.

### 1B. Font ô nhập essay — 16sp lệch scale + to hơn phần đọc

`_Editor.build` (`:703-705`), nhánh non-compact (màn writing thường):
```dart
style: compact
    ? ExamSystemUi.embeddedBodyStyle.copyWith(color: AppColors.textPrimary)   // exam-embedded: 13 — giữ nguyên
    : const TextStyle(fontSize: 16, height: 1.6, color: AppColors.textPrimary),// ❌ 16 = cỡ heading h1, lệch scale body
```

Đối chiếu:
- Text **prompt/tài liệu** đọc (`_PromptCard`, `:665`) = `fontSize: 14, height: 1.5` → ô nhập (16) **to hơn phần đọc 2pt**, đúng phàn nàn của user "phông nhập hơi to, chưa thống nhất bộ tài liệu".
- Token bộ tài liệu (`02 §2.1` mobile scale): `body` = **13**, `bodyLg` = **15** (reading excerpt). **16 không thuộc scale body** (16 là `h1`). → hardcode lệch token.
- Helper sẵn có: `StudentMobileUi.bodyLg(context)` = `AppTypography.body(large:true)` = **fontSize 15, height 1.5, weight 400, color textPrimary** (verified: `student_mobile_ui.dart:53-54`, `app_typography.dart:305-313,18`). File đã import `StudentMobileUi` (đang dùng `skillAppBar`/`bottomActionBar`/`pageHPadding`).

---

## 2. Audit downstream (consumer dùng chung)

| Nơi | File:line | Ảnh hưởng |
|---|---|---|
| Dialog "Save draft?" | `:252-281` (build) + `:283-296` (result) | **Sửa chính.** Đổi style + còn 2 nút. Logic result `null/false/true` **giữ nguyên** (chỉ bỏ nút Cancel; `null` vẫn đạt qua dismiss). |
| Dialog "Resume writing?" (`_showResumeConflictDialog`) | `:355-404` | **Đồng bộ style** (cùng lỗi `Colors.white`/`AppRadius.card`/body `textSecondary`/nút phẳng). Vốn **chỉ 2 nút** (Start new + Resume) nên **không bị dồn dọc** — chỉ nâng cấp visual. Giữ `barrierDismissible: false` (`:357`) và toàn bộ callback bloc (`DiscardDraftAndStartNew`, Resume) **nguyên vẹn**. |
| `_Editor` font | `:703-705` | Chỉ đổi nhánh **non-compact** (16→15 qua `bodyLg`). Nhánh **compact/exam-embedded giữ nguyên** (`embeddedBodyStyle` 13 — đã đúng cho ngữ cảnh exam). |
| `_PromptCard` text 14 (`:665`) | — | **Không đổi.** Là text tài liệu tham chiếu; 14 đã trong-scale. Sau khi ô nhập về 15, phân cấp tự nhiên (nhập 15 ≥ đọc 14) — hợp lý, không cần đụng. |
| `_ClassicBottomBar`, `SaveDraftEvent`, `PopScope`/`_onWillPop` flow | `:410-412`, `:717-781`, bloc | **Không đụng.** Chỉ đổi phần UI trong dialog + 1 dòng style editor. |

→ Grep xác nhận `writingSaveDraftTitle/Message`, `writingDiscardButton`, `saveChanges`, editor style chỉ ở file này. `t.cancel` là key dùng chung toàn app → bỏ nút Cancel **không tạo orphan l10n**.

---

## 3. Quyết định thiết kế + cảnh báo

### 3A. Dialog Save draft → 2 nút ngang, token-first (theo `04 §6.1`)

`04 §6.1 AlertDialog`: *"body 14/400 textPrimary; radius 16; **2 actions: Outlined + Filled. Không 3 nút trở lên.**"* → khớp đúng ý user (muốn nút hàng ngang).

**Chọn:**
- **bg** `Colors.white` → `AppColors.surfaceCard`; `surfaceTintColor` → `AppColors.surfaceCard` (chặn M3 tint).
- **radius** `AppRadius.card`(12) → `AppRadius.sheet`(16).
- **title** → `StudentMobileUi.sectionTitle(context)` (token h2, textPrimary — thay `TextStyle(w600)` trần).
- **body** → `StudentMobileUi.body(context)` (textPrimary — **sửa vi phạm** `textSecondary`; đồng bộ với `StudentDialogShell`).
- **actions (2 nút, ngang):**
  - **Discard** = `OutlinedButton`, `foregroundColor: AppColors.danger` → `Navigator.pop(ctx, false)`.
  - **Save changes** = `FilledButton`, bg `AppColors.primary` / fg `AppColors.onPrimary` → `Navigator.pop(ctx, true)`. ← **CTA chính** (1 Filled/dialog, `04 §1.3`).
  - **Bỏ nút Cancel** → dismiss (tap ngoài / Back) = `null` = ở lại (giữ nguyên hành vi). Giữ `barrierDismissible: true`.
- Nhãn dùng key l10n sẵn có: `writingDiscardButton` ("Discard"), `saveChanges` ("Save Changes"). **Không thêm l10n mới.**

**Vì sao bỏ Cancel thay vì nhồi 3 nút cho vừa:** 3 action dài không thể xếp ngang gọn trên 360px (đó chính là lý do Material dồn dọc). Doc chỉ định 2 action/dialog. Cancel về mặt hành vi = dismiss (đã có sẵn, an toàn, không mất dữ liệu). → 2 nút ngang là cách vừa đúng doc vừa đúng ý user, vừa giữ nguyên logic.

> **DRY (khuyến khích, không bắt buộc):** vì Save-draft và Resume dialog dùng **cùng shell** (bg/radius/title/body), nên tách 1 helper nhỏ trong file trả `AlertDialog` đã style, nhận `title`/`message`/`actions`. Mỗi call-site truyền `actions` riêng + `showDialog` riêng (giữ `barrierDismissible` khác nhau). Nếu implementer thấy rủi ro, được phép restyle **inline từng dialog** (vẫn phải đủ token như trên) — miễn kết quả visual giống nhau.

### 3B. Font editor → `bodyLg` (15)

**Chọn:** nhánh non-compact `const TextStyle(fontSize: 16, height: 1.6, textPrimary)` → `StudentMobileUi.bodyLg(context)` (15/1.5/w400/textPrimary). Bỏ `const` (helper cần `context`).

**Vì sao 15 (bodyLg) chứ không 14:** user chốt 15 (giảm 1pt, "hơi thôi") — token `bodyLg` là size "reading excerpt" chính thức của hệ thống cho mặt đọc/viết dài; tokenize thay cho 16 off-scale; giữ phân cấp nhẹ so với prompt 14. (14 khớp-y-hệt prompt là phương án user **không** chọn.)

**KHÔNG làm trong scope:** không đổi nhánh compact/exam-embedded (13, đúng); không đổi prompt text 14; không đổi `_ClassicBottomBar`/progress/CTA; không tạo `AppCard2`/widget mới; không đổi luồng save/exit.

---

## 4. Scope IN / OUT

**IN (được sửa):** chỉ `english_for_community/lib/feature/writing/writing_task_page.dart`
- `_onWillPop` dialog Save draft (`:252-281`) — restyle + 2 nút ngang, bỏ Cancel.
- `_showResumeConflictDialog` (`:355-404`) — **chỉ đồng bộ style** (giữ 2 nút, giữ `barrierDismissible:false`, giữ mọi callback).
- `_Editor` (`:703-705`) — nhánh non-compact: 16 → `StudentMobileUi.bodyLg(context)`.
- (Tuỳ chọn) 1 helper private/top-level dựng `AlertDialog` đã style dùng chung 2 dialog.

**OUT (chạm là DỪNG & hỏi):**
- Logic result-handling `:283-296`, `PopScope`/`_onWillPop` flow, `SaveDraftEvent`, các event bloc Resume.
- Nhánh compact/exam-embedded của `_Editor` (`embeddedBodyStyle`).
- `_PromptCard` text 14 (`:665`), icon/collapse, `_ClassicBottomBar`, progress bar, CTA Submit.
- Thêm/đổi key l10n; đổi `barrierDismissible` của Resume (giữ `false`).
- Mọi file khác (writing bloc, feedback page, exam_system_ui, student_mobile_ui…).

---

## 5. Diff cụ thể (ý định + ràng buộc; Cursor tự viết code)

**File:** `english_for_community/lib/feature/writing/writing_task_page.dart`

### (1) Dialog Save draft (`:252-281`)
- **Ý định:** thay `AlertDialog` bằng bản token-styled (mục 3A): `backgroundColor`+`surfaceTintColor` = `AppColors.surfaceCard`; `shape` radius `AppRadius.sheet`; `title` = `StudentMobileUi.sectionTitle(ctx)`; `content` Text style = `StudentMobileUi.body(ctx)` (**textPrimary**). `actions` = **2 nút**:
  ```dart
  actions: [
    OutlinedButton(
      onPressed: () => Navigator.pop(ctx, false),          // Discard → thoát không lưu
      style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
      child: Text(t.writingDiscardButton),
    ),
    FilledButton(
      onPressed: () => Navigator.pop(ctx, true),           // Save → lưu rồi đóng
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      child: Text(t.saveChanges),
    ),
  ],
  ```
- **RÀNG BUỘC:** giữ `showDialog<bool>` + `barrierDismissible` mặc định (true). **Không** đổi block xử lý `shouldSave` (`:283-296`) — `null`(dismiss)=ở lại, `false`=thoát, `true`=lưu. Bỏ đúng 1 nút Cancel.

### (2) Dialog Resume (`:355-404`) — đồng bộ style
- **Ý định:** áp cùng token shell (bg/surfaceTint `surfaceCard`, radius `sheet`, title `sectionTitle`, body `body`/textPrimary). Nút: **Start new** = `OutlinedButton` fg `danger` (giữ callback `DiscardDraftAndStartNew` nguyên), **Resume** = `FilledButton` primary/onPrimary (giữ callback nguyên).
- **RÀNG BUỘC:** giữ `barrierDismissible: false` (`:357`), giữ `_hasShownResumeDialog` guard, giữ toàn bộ logic trong callback (đọc bloc state, `_resolveUserId`, add event). **Chỉ đổi lớp visual.**

### (3) Editor font (`:703-705`)
```dart
// Trước (nhánh non-compact):
: const TextStyle(fontSize: 16, height: 1.6, color: AppColors.textPrimary),
// Sau:
: StudentMobileUi.bodyLg(context),   // 15/1.5 textPrimary — token bodyLg (02 §2.1)
```
- **RÀNG BUỘC:** giữ nguyên nhánh `compact ? ExamSystemUi.embeddedBodyStyle.copyWith(color: AppColors.textPrimary)`. Bỏ `const` ở expression nếu cần.

### (4) (Tuỳ chọn) helper DRY
- Nếu làm: `AlertDialog _writingConfirmDialog(BuildContext context, {required String title, required String message, required List<Widget> actions})` trả `AlertDialog` đã style (bg/surfaceTint/shape/title/content như trên). 2 call-site truyền `actions` + `showDialog` riêng. Không đổi chữ ký public nào.

---

## 6. GATE áp dụng

### 6b. UI/UX GATE (có chạm visual) — **áp dụng**
- [ ] Token-only: bg `surfaceCard`, radius `AppRadius.sheet`, title `sectionTitle`, body `StudentMobileUi.body`/`bodyLg`. **Không** `Colors.white`/hex/size literal mới (chỉ dùng helper token).
- [ ] Body dialog = `textPrimary` (sửa vi phạm `textSecondary` — guardrail `12 §2.2`).
- [ ] Dialog Save draft: **2 nút nằm ngang** trên 360px, không tràn/dồn dọc; 1 Filled primary (`04 §1.3`); Discard danger outlined.
- [ ] Hit target nút dialog ≥ 44dp (FilledButton/OutlinedButton mặc định Material đạt); `04 §6.1`.
- [ ] Font ô nhập = token `bodyLg` (15), không còn 16 off-scale; hài hoà prompt 14.
- [ ] Không dùng amber/skill color trong dialog (primary đen + danger — đúng `02 §1.7`).
- [ ] Test 360×640 (guardrail `12 §1.6`).

### PERF GATE — **không áp dụng** (không đổi list/rebuild/network/animation).
### BACKEND GATE — **không áp dụng** (không chạm API/socket/DB).
### L10N GATE — **không áp dụng** (dùng key sẵn có: `writingSaveDraftTitle/Message`, `writingDiscardButton`, `saveChanges`, `writingResume*`; không thêm string mới).

---

## 7. Hồi quy tối thiểu (smoke — 360×640)

1. **Save draft (case chính):** vào Writing 1 topic → gõ vài chữ (dirty) → bấm Back. Dialog hiện: title/body đọc rõ (đen), bo góc `sheet`, **2 nút ngang** [Discard] [Save]. 
   - Tap **ra ngoài** dialog → dialog đóng, **ở lại màn** (không mất chữ).
   - Bấm **Back** khi dialog mở → dialog đóng, ở lại màn.
   - **Discard** → thoát màn, không lưu.
   - **Save** → auto lưu (SaveDraftEvent) rồi đóng màn; mở lại thấy draft.
2. **Không dirty:** vào màn, không gõ gì → Back → thoát thẳng, **không** hiện dialog (nhánh `!_isDirty`, `:247`).
3. **Font editor:** ô nhập chữ **15sp** — nhỏ hơn trước, không còn "to" hơn phần prompt (14); gõ/xuống dòng/cuộn bình thường.
4. **Resume dialog:** tạo tình huống có draft cũ xung đột (mở lại task đang có draft khác loại) → dialog Resume hiện đã style mới, **2 nút ngang** [Start new] [Resume], **không tap ra ngoài đóng được** (barrierDismissible false); Start new / Resume chạy đúng như cũ.
5. **Exam-embedded (compact):** mở writing trong exam (nếu có route) → ô nhập vẫn 13 (`embeddedBodyStyle`), không đổi.

---

## 8. Lệnh verify

```bash
cd english_for_community
dart analyze lib/feature/writing/writing_task_page.dart
flutter analyze
```
Yêu cầu: **0 lỗi mới**.

---

## 9. HANDOFF — Cursor IMPLEMENT (copy-paste, biên giới cứng)

```text
Bạn là IMPLEMENTER (Codex/Sonnet). Thực thi đúng work-order:
docs/plantasks/BUG/20260703-writing-save-dialog-and-editor-font/work-order.md

CHỈ ĐƯỢC SỬA 1 FILE:
  english_for_community/lib/feature/writing/writing_task_page.dart
  - Dialog "Save draft?" trong _onWillPop (:252-281)
  - Dialog Resume trong _showResumeConflictDialog (:355-404) — chỉ style
  - _Editor style non-compact (:703-705)
  - (tuỳ chọn) 1 helper dựng AlertDialog đã style dùng chung 2 dialog
Ngoài phạm vi trên → DỪNG & hỏi.

LÀM (mục 5):
  1. Save draft dialog: token-styled (bg/surfaceTint = AppColors.surfaceCard; radius AppRadius.sheet;
     title = StudentMobileUi.sectionTitle(ctx); body = StudentMobileUi.body(ctx) → textPrimary).
     actions = 2 NÚT NGANG: OutlinedButton "Discard" (fg danger, pop false) + FilledButton "Save changes"
     (primary/onPrimary, pop true). BỎ nút Cancel (dismiss = null = ở lại). Giữ showDialog<bool> + barrierDismissible mặc định.
     KHÔNG đổi block xử lý shouldSave (:283-296).
  2. Resume dialog: áp CÙNG token shell + nút OutlinedButton(danger) "Start new" + FilledButton "Resume".
     GIỮ barrierDismissible:false, _hasShownResumeDialog, mọi callback bloc nguyên vẹn.
  3. Editor: nhánh non-compact 16/1.6 → StudentMobileUi.bodyLg(context) (15/1.5 textPrimary). Giữ nhánh compact.

TUYỆT ĐỐI KHÔNG:
  - Đổi logic result-handling / PopScope flow / SaveDraftEvent / event bloc Resume.
  - Đổi nhánh compact editor, prompt text 14, bottom bar, progress, CTA Submit.
  - Colors.white / hex / size literal mới; amber/skill color trong dialog.
  - Thêm/đổi key l10n; đổi barrierDismissible của Resume.
  - Đụng file khác (bloc, feedback page, student_mobile_ui, exam_system_ui...).

VERIFY trước khi báo xong:
  - dart analyze lib/feature/writing/writing_task_page.dart → 0 lỗi
  - flutter analyze → 0 lỗi
  - Smoke mục 7 (ít nhất case 1,2,3,4) — chụp 360×640 trước/sau dialog + editor nếu được.
Dán kết quả verify + ảnh vào tracker (mục 10). Sau đó báo: "implementer đã xong, audit đi".
KHÔNG tự kết luận APPROVED.
```

---

## 10. Tracker

| Mốc | Trạng thái | Ghi chú / bằng chứng |
|---|---|---|
| Work-order (Opus) | ✅ Done | File này |
| IMPLEMENT (Cursor) | ✅ Done | Diff khớp plan 3/3 chỗ |
| Verify analyze | ✅ Pass | `dart analyze` file: 0 lỗi mới (2 info còn lại ở `:479`/`:524` là **pre-existing**, ngoài hunk sửa) |
| Smoke (user, 360×640) | ⏳ | Chờ user chụp — nhãn EN+VI đều ngắn → 2 nút xác nhận nằm ngang |
| Opus AUDIT | ✅ **APPROVED** | 2026-07-03 — xem kết quả mục 11 |

---

## 11. Checklist OPUS AUDIT (Phase 4) + HANDOFF Cursor AUDIT

### Checklist audit (đọc DIFF thật, đối chiếu plan) — Opus, 2026-07-03
- [x] Save draft: đúng 2 nút ngang (Discard `OutlinedButton` danger fg + Save `FilledButton` primary/onPrimary), bỏ Cancel; block xử lý `shouldSave` (`:291-304`) **đọc code thật — nguyên vẹn**: `null`(dismiss)=ở lại · `false`=thoát · `true`=SaveDraftEvent+đóng.
- [x] Dialog bg/radius/title/body = token (`surfaceCard`/`AppRadius.sheet`/`sectionTitle`/`body`-textPrimary); **0 `Colors.white`, 0 `textSecondary`** còn sót ở cả 2 dialog.
- [x] Resume dialog: style đồng bộ; đọc diff — GIỮ `barrierDismissible:false` (context ngoài hunk), `_hasShownResumeDialog` guard, và **2 callback bloc nguyên verbatim** (`DiscardDraftAndStartNew` + Resume `setState`); không đổi hành vi.
- [x] Editor non-compact = `StudentMobileUi.bodyLg(context)` (15/1.5 textPrimary); nhánh compact giữ `embeddedBodyStyle` (13) — không đụng.
- [x] Không lan ra file khác (chỉ `writing_task_page.dart`; `pbxproj`/`gradle.properties` chỉ line-ending, không nội dung); không key l10n mới; không đụng luồng save/exit/PopScope.
- [x] Nhãn EN ("Discard"/"Save Changes", "Start new"/"Resume") + VI ("Bỏ qua"/"Lưu thay đổi", "Viết mới"/"Tiếp tục") đều ngắn → 2 nút **nằm ngang** cả 2 locale trên 360px (không tái diễn dồn dọc).
- [x] `dart analyze` file: **0 lỗi mới** (2 info `use_build_context_synchronously` `:479` + `prefer_conditional_assignment` `:524` là **pre-existing**, ngoài phạm vi sửa).
- **Verdict:** ✅ **APPROVED** — implementer bám plan chính xác, không scope-creep, logic bảo toàn. Còn lại: user smoke thực tế 360×640 (mục 7) để đóng task.

### HANDOFF — Cursor AUDIT (copy-paste, "nhờ cursor audit luôn")
```text
Bạn là AUDITOR (model khác implementer). KHÔNG sửa code — chỉ đọc DIFF + verify, ra verdict.
Plan: docs/plantasks/BUG/20260703-writing-save-dialog-and-editor-font/work-order.md (mục 11 checklist).

Kiểm (360×640):
  1. Writing → gõ chữ → Back: dialog Save draft có 2 NÚT NGANG [Discard][Save], title/body đen đọc rõ, bo góc sheet.
     Tap ngoài / Back → ở lại (không mất chữ). Discard → thoát không lưu. Save → lưu rồi đóng.
  2. Không gõ gì → Back → thoát thẳng, không dialog.
  3. Font ô nhập = 15sp (nhỏ hơn trước, không to hơn prompt 14); gõ/cuộn bình thường.
  4. Resume dialog (draft xung đột): style mới, 2 nút ngang [Start new][Resume], KHÔNG tap-ngoài-đóng-được; 2 nhánh chạy đúng.
  5. Diff chỉ trong writing_task_page.dart; không key l10n mới; không đổi logic save/exit/bloc.
  6. dart analyze / flutter analyze 0 lỗi.

Mỗi finding: file:line + mô tả + fix. Verdict: APPROVED | CHANGES REQUESTED. Ghi tracker mục 10.
```
