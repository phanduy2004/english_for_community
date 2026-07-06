# Quy Trình Làm Việc AI — Brain / Implement / Audit (prompt chuẩn)

**Version:** 1.5 · **Ngày:** 2026-07-06 · **Ngôn ngữ:** tiếng Việt (thuật ngữ kỹ thuật giữ tiếng Anh)

> _v1.5: bắt buộc **CONTEXT BUNDLE** trong work-order (code thật + anchor search-string + symbol table) để implementer làm hiệu quả — xem Phase 2 §5, template `_templates/work-order.md` + `_templates/handoff-cursor.md`._

> **Mục đích:** prompt chuẩn để khởi động MỌI task theo quy trình 3 vai:
> **Opus (bộ não) PHÂN TÍCH + PLAN + AUDIT → Codex/Sonnet (Cursor) IMPLEMENT → Opus AUDIT lại khi xong.**
>
> **Nguyên tắc token (giữ chất lượng):** Opus chỉ ôm phần CẦN LÝ LUẬN — phân tích, thiết kế giải pháp, phán quyết cuối. Phần *lấy dữ liệu / gõ code / rà soát lần đầu* → giao model rẻ (Codex/Sonnet, sub-agent Explore). Mục tiêu: **giảm token Opus mà chất lượng đầu ra KHÔNG giảm** — Opus vẫn đọc code thật ở mọi điểm ra quyết định.
>
> **Cân bằng token ≠ bỏ đói implementer (v1.5):** tiết kiệm token chỉ áp cho *retrieval + lý luận của Opus* (delegate scout, không reload full diff). **Handoff cho Codex thì NGƯỢC LẠI — phải DATA-ĐẦY-ĐỦ:** work-order bắt buộc có **CONTEXT BUNDLE** = code THẬT tại từng touch-site + **anchor là chuỗi search unique** (KHÔNG neo số dòng) + **symbol table** (signature/field/enum/l10n/route verbatim). Bắt Codex tự grep lại = tốn token hơn + định vị sai + thêm vòng audit → *kém hiệu quả tổng thể*. Rẻ hơn là Opus dán sẵn đúng đoạn cần.
>
> **Nguyên tắc bắt buộc (mọi loại task):**
> - **Chức năng + không regression** — đúng nghiệp vụ, không phá luồng cũ.
> - **Hiệu năng** — tránh lag UI, load chậm, jank scroll, rebuild thừa, gọi API/socket dồn, memory leak.
> - **UI/UX** (khi chạm layout/visual) — bám `docs/ui-ux-system/`, token/component có sẵn, đủ loading/empty/error.
> - **Backend** (khi chạm API/socket/DB) — controller mỏng, logic ở service, validate Zod, tránh N+1.
>
> Task `PERF` tập trung sửa perf; task `BUG`/`FEATURE` vẫn phải **đánh giá perf + UI/UX + backend** (nếu chạm) trong plan/handoff/audit.
>
> **Cách dùng:**
> 1. Task thường → copy **Khối prompt** → điền **Phần A** → gửi Opus → nhận work-order + handoff.
> 2. Opus viết work-order theo [`plantasks/_templates/work-order.md`](plantasks/_templates/work-order.md) + handoff theo [`plantasks/_templates/handoff-cursor.md`](plantasks/_templates/handoff-cursor.md) — **bắt buộc CONTEXT BUNDLE** (code thật + anchor + symbol table).
> 3. Task **UI (dựng/redesign màn)** → template xây UI: [`plantasks/_templates/ui-build-mobile.md`](plantasks/_templates/ui-build-mobile.md) (student) / [`plantasks/_templates/ui-build-web.md`](plantasks/_templates/ui-build-web.md) (teacher/admin) — Standards + Build-spec + Perf + Pre-ship checklist; kick-off nhanh bằng prompt [`plantasks/_templates/uiux-layout-prompt.md`](plantasks/_templates/uiux-layout-prompt.md).
> 4. Task **MICRO** (≤3 file) → xem mục [Chế độ MICRO](#chế-độ-micro) — gọn hơn, không cần tracker (§5 Context Bundle vẫn giữ).
> 5. Implementer xong → báo Opus *"implementer đã xong, audit đi"* → Phase 4.

---

## Khối prompt (copy nguyên khối)

```text
═══════════════════════════════════════════════════════════════
PHẦN A — INPUT TASK (điền mỗi lần; thiếu trường nào Opus sẽ hỏi lại)
═══════════════════════════════════════════════════════════════
• Task ID:            (vd 20260622-<short-slug>; nếu trống Opus tự sinh theo ngày)
• Loại:               BUG | FEATURE | PERF
• Platform:           student mobile | teacher web | admin web | backend | full-stack
• Mục tiêu:           (1 câu)
• Phạm vi IN:         (file/màn/module được chạm)
• Phạm vi OUT:        (tuyệt đối không chạm / defer)
• Kỳ vọng đầu ra:     (điều kiện nghiệm thu — vd build 0 lỗi, test pass, hành vi X)
• Màn / archetype:    (tuỳ chọn — vd Home A1, Messages A5; mở brief trong ui-ux-system)
• Màn tham chiếu:     (tuỳ chọn — màn anh-em chrome đã chuẩn, vd Progress, Profile)
• Ràng buộc perf:     (tuỳ chọn — trống → Opus tự suy từ phạm vi)
• Ràng buộc UI/UX:    (tuỳ chọn — trống → Opus tự suy nếu chạm layout)
• Hồi quy tối thiểu:  (tuỳ chọn — luồng smoke sau khi sửa; account test: docs/dev/seeds/)
• Bối cảnh/log/lỗi:   (dán log, đường dẫn file, ảnh nếu có)

═══════════════════════════════════════════════════════════════
PHẦN B — QUY TRÌNH LÀM VIỆC (giữ nguyên mọi task)
═══════════════════════════════════════════════════════════════
VAI TRÒ: Bạn là Claude Opus = "BỘ NÃO". Quy trình 3 vai:
  Opus PHÂN TÍCH + PLAN + AUDIT  →  Codex/Sonnet (Cursor) IMPLEMENT  →  Opus AUDIT lại khi xong.
Bạn KHÔNG tự sửa code (trừ khi tôi nói rõ "Opus tự code"). Output của bạn là ARTIFACT để bàn giao.
Audit cuối luôn do Opus (Phase 4). Cursor chỉ IMPLEMENT theo handoff — không tự kết luận APPROVED.

PHASE 0 — READINESS (bắt buộc):
  - Kiểm tra đủ 4 trường: Mục tiêu / Phạm vi IN / Phạm vi OUT / Kỳ vọng đầu ra. Thiếu → DỪNG, hỏi ngược, không đoán.
  - Đọc convention: `.cursor/rules/project.mdc` (bắt buộc).
      Flutter thêm file/import → `docs/dev/flutter-coding-structure.md`.
      Backend → `english_for_community_backend/` theo pattern Route → Controller → Service → Model.
  - Xác định **Platform** (field Phần A) → mở đúng doc (ui-ux-system / backend / cả hai nếu full-stack).
  - Xác định sớm **perf risk**: list dài, tab/nested scroll, realtime, ảnh/audio, search/filter, bloc rebuild rộng.
  - Xác định sớm **UI/UX scope** (nếu chạm layout/visual):
      → Bắt buộc đọc `docs/ui-ux-system/` (bảng cuối doc này).
      → Tối thiểu: `README.md` + `12-ai-guardrails.md` + `11-implementation-mapping.md`.
      → Redesign: + `patterns/` + screen brief `patterns/04-screen-briefs/` nếu có.
      → Doc thắng code khi mâu thuẫn.

PHASE 1 — PHÂN TÍCH GROUND-TRUTH (không hallucinate):
  - TIẾT KIỆM TOKEN — DELEGATE SCOUT: việc dò rộng / đọc số lượng lớn file → giao sub-agent rẻ
      (Explore/Codex) chạy grep/read, trả về BẢN ĐỒ `file:line` + TRÍCH ĐOẠN CODE THẬT ở điểm quyết định
      (các trích đoạn này về sau tái dùng làm **BEFORE** trong §5 CONTEXT BUNDLE của work-order).
      Opus reasoning trên đó + tự đọc KỸ vài file quyết định. (Opus lo suy luận, không ôm retrieval.)
  - CHẤT LƯỢNG BẤT KHẢ XÂM PHẠM: KHÔNG kết luận chỉ từ tóm tắt của sub-agent. Mọi điểm ra quyết định
      (root-cause, field/luồng dùng chung, chỗ sẽ sửa) → Opus phải đọc CODE THẬT tận nơi, verify lại.
  - ĐỌC CODE THẬT trước khi kết luận. Mọi file/field/luồng phải verify (grep/read), không suy đoán từ trí nhớ.
  - Nếu đụng field/hành vi dùng chung: AUDIT DOWNSTREAM (grep consumer) + bằng chứng.
  - **PERF GATE (mọi loại task):** 4 câu — lag/jank? lazy/pagination/debounce/cache? rebuild thừa? memory leak?
    → Có rủi ro → work-order mục "Ràng buộc hiệu năng".
  - **UI/UX GATE (khi chạm layout/visual):** 4 câu — archetype A1–A12 + brief? đúng nhánh mobile/web? widget có sẵn? đủ loading/empty/error + guardrails `12`?
    → Chưa rõ/redesign → work-order mục "Ràng buộc UI/UX" (+ brief mới nếu cần).
  - **BACKEND GATE (khi Platform = backend | full-stack):** 4 câu —
      1) Logic nằm service, controller mỏng?
      2) Validate Zod + auth middleware (`authenticate` / `requireAdmin`) đúng route?
      3) Query MongoDB: index, `.lean()`, tránh N+1 / loop query?
      4) Socket: không duplicate handler; room/event naming khớp client?
    → Có rủi ro → work-order mục "Ràng buộc backend".
  - **L10N GATE (khi có string UI mới):** mọi text → `app_en.arb` + `app_vi.arb`; chạy `flutter gen-l10n`; không hardcode.
  - Phân loại cỡ task:
      • MICRO (≤3 file, <~50 LOC) → 1 work-order; xem chế độ MICRO (ngoài khối prompt).
      • T1 → work-order + tracker tại `docs/plantasks/{Loại}/{Task ID}/`.
      • T2 → role folder (`01-ba` … `06-performance`, `99-tracking`).

PHASE 2 — VIẾT ARTIFACT (đặt tại docs/plantasks/{Loại}/{Task ID}/):
  Work-order PHẢI có:
    1) Vấn đề + nguyên nhân gốc (dẫn chứng code).
    2) Audit downstream (bảng consumer nếu có).
    3) Quyết định thiết kế + cảnh báo.
    4) Scope IN/OUT + "chạm là DỪNG & hỏi".
    5) **CONTEXT BUNDLE (BẮT BUỘC)** — mỗi touch-site: `file:path` + **anchor = chuỗi search unique** (KHÔNG neo số dòng)
         + **BEFORE verbatim** (dán code thật ~5–15 dòng, đủ định vị) + **AFTER / thao tác chính xác** + GOTCHA.
         Kèm **SYMBOL TABLE** (signature/field/enum/l10n/route verbatim, đánh dấu [CÓ]/[THÊM]) + **CLONE-THIS** (mẫu để nhái).
       → Mục tiêu: Codex đọc §5 là ĐỦ code, KHÔNG phải grep lại. Opus không cần viết lại TOÀN BỘ file — chỉ dán đúng
         đoạn touch-site, nhưng đoạn đó phải là CODE THẬT + anchor + symbol, KHÔNG phải chỉ "mô tả ý định".
    6) Ràng buộc hiệu năng (nếu PERF GATE có rủi ro).
    6b) Ràng buộc UI/UX (nếu UI/UX GATE có chạm layout).
    6c) Ràng buộc backend (nếu BACKEND GATE có rủi ro).
    7) Hồi quy tối thiểu + account test (`docs/dev/seeds/` nếu cần login).
    8) Lệnh verify (`dart analyze`, `flutter test`, `node`/API test nếu backend).
    9) HANDOFF PROMPT (Phase 3).
    10) Checklist OPUS AUDIT (Phase 4).
  Tracker (T1/T2): trạng thái + nhật ký + bằng chứng build/test/smoke + kết quả Opus audit.

PHASE 3 — HANDOFF cho Cursor IMPLEMENT (copy-paste, biên giới cứng) — mẫu: `_templates/handoff-cursor.md`:
  - **BƯỚC 0 (bắt buộc):** trỏ Codex ĐỌC work-order file (path đầy đủ) trước; code lấy nguyên từ §5 CONTEXT BUNDLE,
      không tự grep đoán. File thực tế lệch BEFORE hoặc doc mâu thuẫn prompt → DỪNG (doc thắng).
  - Liệt kê CHÍNH XÁC file được sửa; ngoài danh sách → DỪNG & hỏi.
  - "TUYỆT ĐỐI KHÔNG": schema/migration không plan, đổi public signature, mở rộng scope, hardcode secret.
  - PERF: ListView.builder, lazy tab, debounce ≥300ms, BlocSelector/buildWhen, dispose subscription, không API trong build.
  - UI/UX: token-only, component có sẵn, skeleton/empty/error, đối chiếu màn tham chiếu + brief.
  - Backend: service layer, Zod validate, không logic nặng trong controller, index query nếu list lớn.
  - L10n: EN + VI nếu thêm string UI.
  - Verify + smoke (perf + UI + hồi quy) → dán tracker → báo Opus audit.

PHASE 4 — OPUS AUDIT (implementer báo xong):
  - TIẾT KIỆM TOKEN: Codex SELF-AUDIT + tóm tắt DIFF có cấu trúc trước (file đổi · rủi ro · checklist tự chấm).
      Opus audit trên bản cô đọng đó, không nạp lại toàn bộ diff.
  - CHẤT LƯỢNG BẤT KHẢ XÂM PHẠM: Opus VẪN đọc DIFF THẬT ở các hunk rủi ro / điểm quyết định (spot-check);
      KHÔNG APPROVE chỉ dựa vào tóm tắt của Codex. Nghi ngờ → đọc full hunk. Phán quyết cuối luôn do Opus.
  - Đối chiếu plan; không scope-creep.
  - Audit chức năng + perf + UI/UX (+ backend nếu có) — checklist chi tiết xem bảng cuối doc.
  - Finding = BLOCKER; ghi file:line + fix cụ thể.
  - Verdict: APPROVED | CHANGES REQUESTED → ghi tracker.

QUY ƯỚC GIAO TIẾP:
  - Tiếng Việt, ngắn gọn. Chat: Status + Artifacts (path) + Next action.
  - No-regression; no placeholder/TODO trong code bàn giao.
  - Thiếu mục GATE tương ứng trong work-order khi có rủi ro → audit FAIL.
  - Yêu cầu ngoài scope → DỪNG, nêu rõ, chờ quyết.
═══════════════════════════════════════════════════════════════
```

---

## Prompt nhanh theo loại task (1–3 dòng)

**BUG (logic/UI nhỏ):**
```text
Opus, theo docs/AI-Working-Process-vi.md (brain, không code): BUG · [platform] · [mục tiêu 1 câu].
IN: [file]. OUT: [không chạm]. Kỳ vọng: analyze 0 lỗi + [hành vi]. Log: [dán].
```

**FEATURE (có layout):**
```text
Opus, theo docs/AI-Working-Process-vi.md + plantasks/_templates/uiux-layout-prompt.md: FEATURE · [platform] · màn [X] archetype [A?].
Tham chiếu chrome: [màn anh-em]. Ra work-order + handoff Cursor.
```

**PERF / backend:**
```text
Opus, theo docs/AI-Working-Process-vi.md: PERF · [platform] · [triệu chứng lag/chậm/N+1].
IN: [module]. Đo/smoke: [cách verify]. Ra work-order perf/backend gate.
```

---

## Chế độ MICRO

Áp khi ≤3 file, <~50 LOC, thay đổi cơ học (fix typo logic, 1 dialog, 1 prop).

| Thường (T1+) | MICRO |
| --- | --- |
| work-order + tracker | **1 file** work-order |
| 10 mục Phase 2 | Gộp: vấn đề + diff + verify + handoff + audit checklist ngắn |
| GATE đầy đủ | Chỉ GATE có rủi ro (vd UI bug → UI/UX GATE; không chạm backend thì bỏ) |
| Smoke dài | 3 bước hồi quy tối thiểu |

Opus vẫn **đọc code thật**, **handoff biên giới cứng**, và **giữ nguyên §5 CONTEXT BUNDLE** (không bao giờ cắt — MICRO càng cần anchor + BEFORE/AFTER chính xác) — chỉ gộp file, không cắt não.

---

## Bảng phân cỡ task → artifact

| Cỡ | Tiêu chí | Artifact |
| --- | --- | --- |
| **MICRO** | ≤3 file, <~50 LOC | 1 work-order |
| **T1** | task nhỏ, 1 agent | work-order + tracker |
| **T2** | >5 file / nhiều màn / perf+UI phức tạp | role folder `01-ba` … `99-tracking` |

> Chọn mức **nhỏ nhất đủ dùng**. Nội dung audit + ràng buộc GATE luôn giữ — chỉ gộp file.

---

## Đọc `docs/ui-ux-system/` khi nào

| Tình huống | Đọc tối thiểu |
| --- | --- |
| **Mọi task UI** | `README.md`, `00`, `02`, `12`, `11` |
| **Student mobile** | + `03`, `04`, `05`, `20` |
| **Teacher web** | + `06`, `07`, `08`, `18` |
| **Admin web** | + `06`, `07`, `08`, `19` |
| **Redesign layout** | + `patterns/`, brief `patterns/04-screen-briefs/` |
| **Chat / realtime UI** | + `22`, `23`, `26` + code `lib/core/socket/` |
| **Scroll perf teacher** | + `21` |
| **Sheet / haptic** | + `15` |
| **a11y** | + `10` |

**Dựng/redesign UI:** template xây UI [`ui-build-mobile.md`](plantasks/_templates/ui-build-mobile.md) (student) / [`ui-build-web.md`](plantasks/_templates/ui-build-web.md) (teacher/admin); kick-off prompt [`uiux-layout-prompt.md`](plantasks/_templates/uiux-layout-prompt.md).

**Luồng:** archetype → brief → token `02` → component `04`/`07` → map `11` → guardrails `12` → perf overlap.

---

## Đọc backend khi nào

| Tình huống | Kiểm tra |
| --- | --- |
| **API mới/sửa** | Route → `authenticate` → Controller → Service → Model; Zod trong service |
| **List/query chậm** | Index MongoDB, `.lean()`, pagination, tránh loop `findById` |
| **Socket event** | `socketManager.js`, room naming, không duplicate listener client |
| **Auth/RBAC** | `middleware/auth.js`, `requirePermissions` |
| **Full-stack** | Contract API ↔ entity Flutter; field `id` vs `_id` (xem doc `25` nếu grading) |

---

## Checklist audit chi tiết (Phase 4 — tham chiếu)

### Hiệu năng (Flutter)

| Vùng | Làm | Tránh |
| --- | --- | --- |
| List / grid | `ListView.builder`, pagination | `ListView(children: map)` khi N > ~20 |
| State | `const`, `BlocSelector`, `buildWhen` | rebuild cả Scaffold |
| Network | parallel, cache, pull-to-refresh có chủ đích | API trong `build()` |
| Search | debounce ≥300ms | filter mỗi keystroke |
| Realtime | patch tile | rebuild full list mỗi event |
| Media | `cached_network_image` | full-res mọi tile |
| Tab | lazy tab body | load cả tab khi mở màn |
| Loading | skeleton | fullscreen spinner lâu |
| Layout | viewport ~360px, ellipsis | Row overflow web hẹp |
| Lifecycle | dispose controller/subscription | socket listener trùng |

**Verify:** DevTools performance overlay (`p`); scroll, tab, search, socket.

### UI/UX

- [ ] Khớp archetype + brief + màn tham chiếu
- [ ] Token-only; không hex/spacing magic
- [ ] Component có sẵn; không duplicate card/button
- [ ] `textPrimary` body; amber chỉ celebrate
- [ ] loading / empty / error nếu list-page
- [ ] l10n EN + VI
- [ ] hit target ≥44dp (mobile)

### Backend

- [ ] Logic trong service; controller mỏng
- [ ] Zod validate input
- [ ] Auth middleware đúng route
- [ ] Query có index / không N+1
- [ ] Socket handler không leak / duplicate

### Hồi quy

- [ ] Smoke theo mục 7 work-order
- [ ] Account test từ `docs/dev/seeds/` nếu cần login E2E
