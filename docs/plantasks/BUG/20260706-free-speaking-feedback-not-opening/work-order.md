# Work-Order — BUG: Free Speaking không chuyển sang màn chấm điểm khi hội thoại kết thúc "tự nhiên"

- **Task ID:** 20260706-free-speaking-feedback-not-opening
- **Loại:** BUG · **Platform:** student mobile (Flutter) · **Cỡ:** MICRO (1 file, ~1 LOC)
- **Mục tiêu:** Sau khi trò chuyện Free Speaking kết thúc theo **bất kỳ cách nào** (AI tự dừng / silence-timeout / max-duration / bấm Stop), app phải mở `SpeakingFeedbackPage`. Hiện chỉ mở khi user bấm nút Stop đỏ thủ công.
- **Người phân tích:** Opus (brain). **Implementer:** Cursor. **Status:** ROOT CAUSE XÁC ĐỊNH — chờ implement.
- **Liên quan:** feature `docs/plantasks/FEATURE/20260703-free-speaking-ai-feedback`.

---

## 1. Vấn đề + nguyên nhân gốc (dẫn chứng code)

**Triệu chứng:** Trò chuyện xong không chuyển sang màn chấm điểm/nhận xét — user ở lại màn chat.

**Root cause:** Việc mở feedback bị gate sau cờ `_evaluateAfterCallEnds`, mà cờ này **chỉ** set `true` khi user bấm Stop thủ công.

`english_for_community/lib/feature/speaking/free_speaking_page.dart`:

- `_onVapiEvent`, `case 'status'` (`:229-239`): khi call `ended`/`disconnected` và `prev == active` → **chỉ** gọi `_openFeedbackIfEligible()` nếu `_evaluateAfterCallEnds == true`.
- Khi call vào `active` (`:223-228`) cờ bị đặt `= false` (`:226`).
- Cờ chỉ được set `true` ở **một chỗ duy nhất**: nhánh bấm Stop thủ công `_handleBottomButtonPress` case 3 (`:340-343`).

⇒ Mọi cách kết thúc KHÔNG phải bấm Stop (AI tự `call-end`, silence timeout, max-duration timeout của Vapi) đều để cờ `false` → `_openFeedbackIfEligible()` không chạy → không điều hướng. Đúng triệu chứng "trò chuyện xong không chuyển màn".

> Đường bấm Stop thủ công về mặt code là đúng (`stop()` phát `status: ended`, `real_vapi_service.dart:182-187`). Fix này giữ nguyên đường đó, chỉ mở thêm các đường kết thúc khác.

---

## 2. Audit downstream (các đường call kết thúc)

| Cách kết thúc | Event tới `_onVapiEvent` | `prev` | Sau fix |
|---|---|---|---|
| Bấm Stop đỏ | `ended` (từ `stop()` + có thể cả SDK `call-end`) | `active` | eval ✓ (như cũ) |
| AI tự kết thúc / timeout | `ended` (SDK `call-end`, `real_vapi_service.dart:110-112`) | `active` | eval ✓ **(fix)** |
| Bấm Back / thoát màn | `stop()` phát `ended` **NHƯNG** `dispose()` đã `_vapiSub?.cancel()` trước (`:287-294`) → event bị nuốt | — | **không** eval ✓ |
| Lỗi khi đang connect | `disconnected` | `connecting` | guard `prev == active` chặn → **không** eval ✓ |
| Hội thoại quá ngắn | `ended` | `active` | `_isLongEnoughForFeedback` lọc → toast "quá ngắn", **không** điều hướng ✓ (chủ đích) |

**Không regression:** double-emit `ended` (SDK `call-end` + explicit trong `stop()`) vẫn an toàn — nhánh `ended` set `_evaluateAfterCallEnds = false` sau khi eval (`:237`), nên lần `ended` thứ 2 có `prev == ended` → bỏ qua → chỉ điều hướng 1 lần.

---

## 3. CONTEXT BUNDLE ⭐ (Codex đọc là đủ — KHÔNG grep lại)

### Site 1 — `english_for_community/lib/feature/speaking/free_speaking_page.dart` · `_onVapiEvent` → `case 'status'`
- **Locator (anchor):** search chuỗi unique `_evaluateAfterCallEnds = false;` — chỉ xuất hiện **1 lần** trong file, ở nhánh call chuyển sang `active`. _Số dòng ~`:226` chỉ tham khảo, KHÔNG neo._
- **BEFORE → AFTER:**

```dart
// BEFORE
if (_callStatus == VapiCallStatus.active &&
    prev != VapiCallStatus.active) {
  _callStartedAt = DateTime.now();
  _evaluateAfterCallEnds = false;   // <-- chỉ eval khi bấm Stop
  SpeakingTelemetry.logCallStart();
}

// AFTER
if (_callStatus == VapiCallStatus.active &&
    prev != VapiCallStatus.active) {
  _callStartedAt = DateTime.now();
  _evaluateAfterCallEnds = true;    // eval mọi cách kết thúc: AI tự dừng / timeout / bấm Stop
  SpeakingTelemetry.logCallStart();
}
```

**RÀNG BUỘC:**
- CHỈ đổi giá trị `false` → `true` tại dòng này. KHÔNG đổi logic khác trong `case 'status'`.
- Giữ nguyên nhánh `ended` (guard `prev == active`, `_isLongEnoughForFeedback`, `_evaluateAfterCallEnds = false` cuối nhánh, `_resetState()`).
- Dòng `_evaluateAfterCallEnds = true;` trong `_handleBottomButtonPress` case 3 (`:341`) nay **thừa nhưng vô hại** — **được phép để nguyên** (không bắt buộc xóa). Nếu xóa để cho sạch thì OK, nhưng KHÔNG đổi gì khác trong hàm đó.

### SYMBOL TABLE (verbatim — Codex khỏi tra)

| Symbol | Verbatim | Nguồn `file:line` | Trạng thái |
|---|---|---|---|
| `enum VapiCallStatus` | `{ disconnected, connecting, active, ended }` | `vapi/vapi_service.dart:5` | [CÓ] |
| `_evaluateAfterCallEnds` | `bool` field của `_FreeSpeakingPageState` | `free_speaking_page.dart:111` | [CÓ] |
| `_isLongEnoughForFeedback(turns, duration)` | eligible khi `userTurns ≥ 3 || duration ≥ 30` (giây) | `free_speaking_page.dart:370-374` | [CÓ] |
| `_openFeedbackIfEligible()` | gate `_isLongEnoughForFeedback` → `context.pushNamed(SpeakingFeedbackPage.routeName, extra: ...evaluate())` | `free_speaking_page.dart:376-398` | [CÓ] |
| dispose order | `_vapiSub?.cancel()` **trước** `_vapiService?.dispose()` | `free_speaking_page.dart:287-294` | [CÓ] — giữ nguyên |
| l10n `speakingFbTooShort` | toast "hội thoại quá ngắn" | `app_en.arb` / `app_vi.arb` | [CÓ] |

**CLONE-THIS:** N/A (đổi cơ học 1 dòng). · **Symbol [THÊM]:** không có (không thêm l10n/route/DI/entity field).

---

## 4. Scope IN / OUT

**IN:** `english_for_community/lib/feature/speaking/free_speaking_page.dart` — đúng 1 dòng như mục 3.

**OUT (chạm là DỪNG & hỏi):**
- ❌ `real_vapi_service.dart` / `vapi_service.dart` — không đổi cách phát event.
- ❌ `speaking_feedback_page.dart`, `SpeakingFeedbackBloc`, `app_router.dart` — luồng điều hướng + trang chấm điểm đã đúng.
- ❌ Ngưỡng `_isLongEnoughForFeedback` (≥3 lượt user hoặc ≥30s) — giữ nguyên (nếu muốn chỉnh là task khác).
- ❌ `dispose()` order — đang đúng, đừng đụng.

---

## 5. GATE liên quan
- **Perf:** không rủi ro — chỉ đổi 1 giá trị bool, không thêm rebuild/timer/listener/API.
- **UI/UX:** không chạm layout/visual — không cần đối chiếu archetype/brief.
- **Backend / L10n:** không chạm — bỏ.

---

## 6. Verify + Hồi quy tối thiểu (smoke thủ công trên máy thật/emulator)

**Verify build:**
```bash
cd english_for_community
dart analyze lib/feature/speaking/free_speaking_page.dart
```
Kỳ vọng: 0 lỗi mới.

**Smoke (device có mic + Vapi key):**
1. Vào Free Speaking, nói đủ **≥3 lượt** (hoặc ≥30s). Để hội thoại **kết thúc tự nhiên / để AI tự dừng / chờ timeout** (KHÔNG bấm Stop) → **PHẢI** chuyển sang `SpeakingFeedbackPage` (spinner "analyzing" → kết quả hoặc error+retry). ⭐ Đây là ca fix.
2. Nói ≥3 lượt rồi **bấm nút Stop đỏ** → vẫn chuyển sang màn chấm điểm (không regression).
3. Vừa vào call rồi **bấm Back** ngay (bỏ dở) → **KHÔNG** mở màn chấm điểm, thoát sạch (không crash, không double-push).
4. Hội thoại **rất ngắn** (1 lượt, <30s) rồi kết thúc → hiện toast "quá ngắn", **không** điều hướng (đúng chủ đích).

> Nếu ca (1) hoặc (2) vẫn không chuyển màn sau fix → nghĩa là event `status: ended` không tới `_onVapiEvent` (vấn đề tầng Vapi SDK, ngoài scope này) → DỪNG & báo Opus, kèm log.

---

## 7. HANDOFF PROMPT cho Cursor
```text
Bạn là implementer. CHỈ sửa đúng 1 file, đúng 1 dòng; ngoài phạm vi → DỪNG & hỏi.
Repo: english_for_community (Flutter, student mobile).

BƯỚC 0 — ĐỌC WORK-ORDER TRƯỚC (bắt buộc):
  Mở & đọc đầy đủ: docs/plantasks/BUG/20260706-free-speaking-feedback-not-opening/work-order.md
  Nắm: nguyên nhân gốc (§1), audit downstream các đường kết thúc (§2), **§3 CONTEXT BUNDLE** (anchor + BEFORE/AFTER + symbol table — code lấy từ đây), scope OUT (§4), smoke (§6).
  Nếu file/nội dung mâu thuẫn với prompt này → DỪNG & hỏi Opus (doc thắng prompt).

FILE: lib/feature/speaking/free_speaking_page.dart
Ở _onVapiEvent → case 'status' → nhánh khi call chuyển sang active (prev != active):
  đổi:  _evaluateAfterCallEnds = false;
  thành: _evaluateAfterCallEnds = true;

TUYỆT ĐỐI KHÔNG: đụng real_vapi_service/vapi_service, speaking_feedback_page, SpeakingFeedbackBloc,
  app_router, dispose() order, ngưỡng _isLongEnoughForFeedback, hay bất kỳ logic nào khác trong case 'status'.
  Dòng _evaluateAfterCallEnds = true trong _handleBottomButtonPress (nhánh Stop) để NGUYÊN (không bắt buộc xóa).

VERIFY:
  - cd english_for_community && dart analyze lib/feature/speaking/free_speaking_page.dart  (0 lỗi mới)
  - SMOKE (device có mic + Vapi key):
    (1) nói ≥3 lượt, để AI/timeout tự kết thúc (KHÔNG bấm Stop) -> PHẢI mở màn chấm điểm.
    (2) nói ≥3 lượt rồi bấm Stop đỏ -> vẫn mở màn chấm điểm.
    (3) vào call rồi bấm Back ngay -> KHÔNG mở màn chấm điểm, thoát sạch.
    (4) hội thoại rất ngắn -> toast "quá ngắn", không điều hướng.
Xong -> dán kết quả analyze + smoke (1)-(4) vào chat -> báo Opus audit.
```

## 8. Checklist OPUS AUDIT (Phase 4)
- [ ] `git status`/diff: chỉ `free_speaking_page.dart` đổi, đúng 1 dòng `false → true` tại nhánh active-start.
- [ ] Không đụng file OUT (mục 4); không đổi logic khác trong `case 'status'`.
- [ ] `dart analyze` 0 lỗi mới.
- [ ] Smoke (1) AI/timeout tự kết thúc → mở feedback (ca fix chính).
- [ ] Smoke (2) bấm Stop → mở feedback (no regression); (3) Back → không mở; (4) quá ngắn → toast.
- [ ] Không double-push feedback khi có double-emit `ended`.
