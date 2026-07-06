# Template — WORK-ORDER (chuẩn, có CONTEXT BUNDLE)

> Template chung để Opus viết work-order cho MỌI task code (BUG/FEATURE/PERF non-layout).
> Task **layout/redesign** dùng thêm [`uiux-layout-prompt.md`](uiux-layout-prompt.md).
>
> **Nguyên tắc số 1 của template này:** work-order phải **DATA-ĐẦY-ĐỦ cho implementer**. Opus tiết kiệm token ở
> *retrieval / lý luận* (delegate scout, không reload full diff), NHƯNG khi bàn giao thì **dán code THẬT + anchor +
> symbol** vào `CONTEXT BUNDLE` — vì Codex tự grep lại tốn token hơn, dễ định vị sai, tăng vòng audit. Neo bằng
> **chuỗi search unique**, KHÔNG neo bằng số dòng (số dòng trôi).
>
> Điền mọi `<...>`. Bỏ mục không áp dụng (ghi "N/A"), KHÔNG bỏ trống mục bắt buộc.
> MICRO (≤3 file, <~50 LOC): vẫn giữ §0/§1/§5/§6/§7/§9/§10, gộp §2–§4 vào 3–5 dòng. Context Bundle **không bao giờ** cắt.

---

# Work-Order — <LOẠI>: <tiêu đề ngắn 1 dòng>

- **Task ID:** `<YYYYMMDD-slug>`
- **Loại:** BUG | FEATURE | PERF · **Platform:** student mobile | teacher web | admin web | backend | full-stack · **Cỡ:** MICRO | T1 | T2
- **Mục tiêu:** <1 câu — điều kiện "đúng" nhìn thấy được>
- **Người phân tích:** Opus (brain). **Implementer:** Cursor/Codex. **Status:** ROOT CAUSE XÁC ĐỊNH — chờ implement.
- **Liên quan:** <task/feature/work-order liên quan, nếu có>

---

## 1. Vấn đề + nguyên nhân gốc (dẫn chứng code)

**Triệu chứng:** <mô tả điều user thấy / log / repro>

**Root cause:** <giải thích cơ chế, trích `file:line` + đoạn code chứng minh — KHÔNG suy đoán từ trí nhớ>

---

## 2. Audit downstream (consumer / đường dùng chung)

> Grep consumer của field/hàm/luồng bị chạm. Bảng: điểm · `file:line` · ảnh hưởng sau fix. Nếu chắc chắn không có downstream → ghi "Không có consumer khác (đã grep `<pattern>`)".

| Điểm | file:line | Ảnh hưởng sau thay đổi |
|---|---|---|
| <...> | <...> | <...> |

**Không regression:** <lập luận vì sao hợp đồng/hành vi cũ giữ nguyên>

---

## 3. Hướng fix (thiết kế) + quyết định

<Thiết kế giải pháp. Nếu có ≥2 lựa chọn: nêu lựa chọn đã chọn + 1 dòng vì sao, alt bị loại + lý do. Cảnh báo bẫy.>

---

## 4. Scope IN / OUT

**IN (chính xác file được sửa):**
- `<path>` — <sửa gì>

**OUT (chạm là DỪNG & hỏi):**
- ❌ `<path/khu vực>` — <lý do giữ nguyên>

---

## 5. CONTEXT BUNDLE ⭐ (bắt buộc — Codex đọc phần này là ĐỦ để code, KHÔNG cần grep lại)

> Mỗi touch-site 1 block. Dán **BEFORE verbatim** (đủ dòng để định vị chắc chắn, không nhầm chỗ trùng). AFTER là code
> cụ thể (hoặc thao tác cơ học rõ ràng nếu quá tầm thường). GOTCHA = bẫy/side-effect/thứ tự/dòng thừa để nguyên.

### Site 1 — `<file path>` · `<hàm / widget / section>`
- **Locator (anchor):** search chuỗi unique `"<exact substring>"` _(số dòng ~`:<n>` chỉ để tham khảo, KHÔNG dùng làm neo)._
- **BEFORE (verbatim):**
  ```<lang>
  <dán code hiện tại quanh chỗ sửa, ~5–15 dòng>
  ```
- **AFTER / THAO TÁC:**
  ```<lang>
  <code mới chính xác, HOẶC: "đổi đúng dòng X → Y">
  ```
- **GOTCHA:** <bẫy; nếu không có ghi "không">

### Site 2 — `<...>`
<lặp cấu trúc như Site 1>

### SYMBOL TABLE (verbatim — để Codex khỏi tra; đánh dấu `[CÓ]` sẵn / `[THÊM]` phải tạo)

| Symbol | Verbatim (signature/field/enum/key) | Nguồn `file:line` | Trạng thái |
|---|---|---|---|
| `<enum/type>` | `<...>` | `<...>` | [CÓ] |
| `<hàm gọi tới>` | `<signature đầy đủ>` | `<...>` | [CÓ] |
| `<l10n key>` | EN:"<...>" · VI:"<...>" | `app_en.arb`/`app_vi.arb` | [CÓ]/[THÊM] |
| `<route/DI/entity field>` | `<...>` | `<...>` | [CÓ]/[THÊM] |

### CLONE-THIS (mẫu có sẵn để nhái — đừng viết mới)
- `<tên pattern>`: `<file:construct>` — nhái **<cụ thể cái gì>** (đặt tên/tiền tố nhất quán: `<prefix>`).

---

## 6. GATE liên quan (chỉ ghi GATE có rủi ro; còn lại ghi "N/A")

- **Perf:** <lag/jank? lazy/pagination/debounce/cache? rebuild thừa? leak? dispose?> — hoặc "N/A (không thêm list/timer/listener/API)".
- **UI/UX:** <archetype+brief? token-only? component có sẵn? loading/empty/error? a11y 44dp?> — hoặc "N/A (không chạm layout)".
- **Backend:** <logic ở service? Zod validate + auth middleware? index/N+1/.lean()? socket không leak/dup?> — hoặc "N/A".
- **L10n:** <string UI mới → EN+VI + `flutter gen-l10n`> — hoặc "N/A (không thêm string)".

---

## 7. Verify + Hồi quy tối thiểu (copy-paste chạy được)

**Build/analyze:**
```bash
<lệnh chính xác, vd: cd english_for_community && dart analyze <path>>
```
**Repro/unit (nếu có):** `<lệnh + kỳ vọng cụ thể>`

**Smoke (đánh số, mỗi bước có kỳ vọng rõ; ⭐ = ca nghiệm thu chính):**
1. ⭐ <thao tác> → <kỳ vọng>
2. <no-regression path> → <kỳ vọng>
3. <edge/abort path> → <kỳ vọng>

**Account test (nếu cần login):** `docs/dev/seeds/` — <account>

> Nếu smoke vẫn fail sau fix → DỪNG & báo Opus kèm log (đừng tự chế hướng khác).

---

## 8. HANDOFF PROMPT cho Cursor/Codex

> Copy khối này cho implementer. Chi tiết mẫu ở [`handoff-cursor.md`](handoff-cursor.md). BẮT BUỘC mở đầu bằng "đọc work-order".

```text
Bạn là implementer. CHỈ sửa file trong Scope IN; ngoài danh sách → DỪNG & hỏi.
Repo: <repo>.

BƯỚC 0 — ĐỌC WORK-ORDER TRƯỚC (bắt buộc):
  Mở & đọc HẾT: docs/plantasks/<Loại>/<TaskID>/work-order.md
  Code cần sửa lấy nguyên từ §5 CONTEXT BUNDLE (anchor + BEFORE/AFTER + symbol table). Doc mâu thuẫn prompt → DỪNG & hỏi (doc thắng).

LÀM: theo §5 (từng Site: tìm anchor → áp AFTER), tôn trọng §4 Scope OUT, §6 GATE.
TUYỆT ĐỐI KHÔNG: <schema/migration ngoài plan; đổi public signature; mở rộng scope; hardcode secret; đụng file OUT>.

VERIFY: chạy §7 (analyze + smoke 1..n, dán kết quả).
Xong → dán verify/smoke vào chat → báo Opus audit. KHÔNG tự commit/push.
```

---

## 9. Checklist OPUS AUDIT (Phase 4)
- [ ] `git status`/diff: chỉ file Scope IN đổi; file OUT không đụng.
- [ ] Mỗi Site khớp §5 (anchor đúng chỗ, AFTER đúng, GOTCHA xử lý).
- [ ] Symbol `[THÊM]` đã tạo (l10n EN+VI + gen-l10n; route/DI đăng ký).
- [ ] GATE có rủi ro (§6) đã thoả.
- [ ] Verify §7: analyze 0 lỗi mới; smoke ⭐ pass; no-regression pass.
- [ ] Không nuốt lỗi / không placeholder-TODO trong code bàn giao.

---

## 10. Follow-up (OUT scope này — mở task riêng khi cần)
- <hệ thống hoá / hardening / nợ kỹ thuật phát hiện khi phân tích>
