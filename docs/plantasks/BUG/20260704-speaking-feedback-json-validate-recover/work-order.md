# Work-Order — BUG: Speaking feedback 502 (Groq `json_validate_failed` không được cứu)

- **Task ID:** 20260704-speaking-feedback-json-validate-recover
- **Loại:** BUG · **Platform:** backend (Node/ESM) · **Cỡ:** MICRO (1 file logic + `package.json`, ~35 LOC)
- **Mục tiêu:** Khi Groq trả `400 json_validate_failed` cho `generateSpeakingFeedback`, **cứu lại** JSON gần-hợp-lệ trong `failed_generation` thay vì để văng thành `502 AI_FAILED`. User phải nhận được feedback thay vì màn lỗi.
- **Người phân tích:** Opus (brain). **Implementer:** Cursor. **Status:** ROOT CAUSE XÁC ĐỊNH — chờ implement.
- **Liên quan:** feature `docs/plantasks/FEATURE/20260703-free-speaking-ai-feedback`. Cùng lỗi tiềm ẩn ở 4 call-site Groq khác (xem mục 10 — follow-up, OUT scope này).

---

## 1. Vấn đề + nguyên nhân gốc (dẫn chứng code)

**Triệu chứng:** `POST /api/speaking/conversation/evaluate` → `502` body `{code:"AI_FAILED"}`. Log backend:
```
Groq Error Detail: { error: { code: 'json_validate_failed',
  message: "Failed to generate JSON. Please adjust your prompt...",
  failed_generation: '{"overall":3.0,"cefr":"A2",... ,"nextSteps":[...]}' } }
status: 400
```

**Root cause — repair fallback là dead-code cho đúng lỗi đang xảy ra:**

- `generateSpeakingFeedback` gọi Groq với `response_format: { type: 'json_object' }`, model `openai/gpt-oss-120b` (`aiService.js:535-543`, model tại `:10`).
- `gpt-oss-120b` là reasoning model; ở `json_object` mode Groq **validate JSON phía server**. Lần này model sinh JSON **gần hợp lệ nhưng sai đuôi** (kết mảng `nextSteps` bằng `}` + token thừa `"}` thay vì `]}`), nên Groq trả **`400 json_validate_failed`**.
- Lỗi 400 này do **SDK `throw` ngay trong `await groq.chat.completions.create(...)` (`:535`)** — TRƯỚC khi tới `:545` (`completion.choices[0].message.content`).
- Vì vậy khối cứu JSON tại `:547-558` (`JSON.parse(cleanJson(content))` → `repairSpeakingFeedbackJson`) **KHÔNG BAO GIỜ chạy** cho ca này. Nó chỉ bắt trường hợp Groq trả `200` kèm text không parse được — mà `json_object` mode gần như không tạo ra (hoặc JSON hợp lệ 200, hoặc 400 `json_validate_failed`).
- Lỗi 400 rơi thẳng xuống outer catch `:565-569` → `throw new Error('Failed to generate speaking feedback from AI')` → `speakingService.evaluateConversation` (`:644-660`) vào catch, lưu conversation `status:'failed'` → controller trả `502 AI_FAILED`.

**Mấu chốt:** Groq **đã trả lại nguyên văn** bản sinh gần-đúng ở `error.error.error.failed_generation`. Dữ liệu KHÔI PHỤC ĐƯỢC nhưng đang bị vứt đi.

**Vị trí `failed_generation` trong object lỗi (đã verify SDK):**
`groq-sdk/error.mjs:6-11` — `APIError` chỉ set `this.status / this.headers / this.error`, KHÔNG set `.code`. `this.error` = **nguyên body response** = `{ error: { message, type, code, failed_generation } }`. Suy ra chính xác:
- `err.status === 400`
- `err.error.error.code === 'json_validate_failed'`
- `err.error.error.failed_generation` === chuỗi JSON cần cứu

---

## 2. Audit downstream

| Điểm | File:line | Ghi chú |
|---|---|---|
| Call site 502 | `aiService.js:535-543` | Nơi throw 400. |
| Dead-code fallback | `aiService.js:547-558` | Chỉ cho ca 200-không-parse-được; không chạy cho 400. |
| Normalize | `aiService.js:118-175` | **Rất lenient** — điền default mọi field, filter item rỗng. Parse được 1 phần vẫn ra feedback hợp lệ → an toàn để nhận JSON đã repair. |
| LLM repair sẵn có | `aiService.js:186-252` | Nhận `badContent`, gọi lại Groq temp 0 → trả JSON. Dùng làm fallback tầng 2. |
| Consumer | `speakingService.js:644-673` | `try` bọc `generateSpeakingFeedback`; success → `status:'reviewed'` + `trackUserProgress`/`updateGamificationStats`; throw → catch lưu `failed`. **Fix chỉ cần trả feedback bình thường → nhánh success tự chạy, KHÔNG sửa service.** |

**Không regression:** fix nằm trọn trong `generateSpeakingFeedback`; hợp đồng trả về (object đã `normalizeSpeakingFeedback` + `.stats/.modelInfo/.evaluatedAt`) giữ nguyên.

---

## 3. Hướng fix (thiết kế)

Trong `catch` của `generateSpeakingFeedback`: nếu là `json_validate_failed`, **cứu `failed_generation` theo 2 tầng rồi normalize**; chỉ throw khi cả 2 tầng fail.

1. **Tầng 1 — `jsonrepair` (deterministic, offline, ~0ms, không tốn API):** sửa đuôi bracket/token thừa → `JSON.parse`. Đây là fix chính cho lỗi log này.
2. **Tầng 2 — `repairSpeakingFeedbackJson` sẵn có (LLM temp 0):** chỉ chạy khi tầng 1 vẫn parse fail. Đưa `failed_generation` vào `badContent`.
3. Có `parsed` (từ tầng nào cũng được) → `normalizeSpeakingFeedback(parsed)` (đã lenient) + gắn `stats/modelInfo/evaluatedAt` **giống hệt `:560-564`** → `return`.
4. Cả 2 tầng fail → log + throw như cũ (giữ nhánh `failed` cũ, không mất hành vi an toàn).

**Quyết định dùng `jsonrepair`:**
- Lỗi thuộc lớp "bracket lệch / token đuôi thừa" — `jsonrepair` xử đúng lớp này, deterministic, không round-trip Groq (tránh thêm 1 call vào rate-limit `8000 tok/min` đang thấy trong header log).
- Alt zero-dep: chỉ dùng `repairSpeakingFeedbackJson`. **Không chọn làm tầng 1** vì tốn thêm 1 Groq call (latency + token + có thể chính nó lại `json_validate_failed`). Vẫn giữ nó làm **tầng 2** dự phòng.
- `jsonrepair` là lib nhỏ, ESM, không native dep → hợp `"type":"module"` của backend.

**Không đổi:** prompt, model, `response_format`, `speakingService`, `normalizeSpeakingFeedback`, `repairSpeakingFeedbackJson`, 4 call-site Groq khác.

---

## 4. Scope IN / OUT

**IN:**
- `english_for_community_backend/package.json` — thêm dependency `jsonrepair`.
- `english_for_community_backend/src/services/aiService.js` — thêm helper `extractFailedGeneration` + nhánh cứu trong catch của `generateSpeakingFeedback`.

**OUT (chạm là DỪNG & hỏi):**
- ❌ `speakingService.js`, controller, model, route.
- ❌ Đổi prompt / model / `temperature` / bỏ `response_format`.
- ❌ Sửa `normalizeSpeakingFeedback`, `cleanJson`, `repairSpeakingFeedbackJson`.
- ❌ Áp helper sang 4 call-site khác (`:85, :248, :294, :433`) — để follow-up mục 10.
- ❌ Migrate sang `json_schema` structured outputs — follow-up mục 10.

---

## 5. Diff cụ thể (Cursor tự viết code; code mẫu ở chỗ dễ sai — property path)

### (a) `package.json` — thêm dep
```bash
cd english_for_community_backend
npm install jsonrepair
```
Xác nhận `dependencies.jsonrepair` xuất hiện + `package-lock.json` cập nhật.

### (b) `aiService.js` — import (đầu file, cạnh `import Groq`)
```js
import { jsonrepair } from 'jsonrepair';
```

### (c) `aiService.js` — helper module-level (đặt gần `cleanJson`, ~sau `:18`)
Phần **nguy hiểm nhất là property path** — bám ĐÚNG theo verify ở mục 1:
```js
// Groq json_object mode có thể trả 400 code 'json_validate_failed' khi model sinh JSON
// gần-hợp-lệ (lệch bracket / token đuôi thừa). SDK throw ngay ở .create(), và trả nguyên
// văn bản sinh trong error.error.error.failed_generation (APIError.error === body {error:{...}}).
const extractFailedGeneration = (error) => {
  const body = error?.error?.error; // = response body.error = { code, failed_generation, ... }
  if (body?.code !== 'json_validate_failed') return null;
  return typeof body.failed_generation === 'string' ? body.failed_generation : null;
};
```

### (d) `aiService.js` — nhánh cứu trong catch của `generateSpeakingFeedback` (`:565-569`)
```js
    } catch (error) {
      const failed = extractFailedGeneration(error);
      if (failed) {
        let parsed = null;
        // Tầng 1: repair deterministic, không gọi API.
        try {
          parsed = JSON.parse(jsonrepair(cleanJson(failed)));
        } catch (_) {
          // Tầng 2: nhờ LLM sửa (chỉ khi tầng 1 vẫn fail).
          try {
            parsed = await repairSpeakingFeedbackJson({
              turns, level, stats, scenario,
              badContent: failed,
              parseError: 'json_validate_failed',
            });
          } catch (_) {
            parsed = null;
          }
        }
        if (parsed) {
          const feedback = normalizeSpeakingFeedback(parsed);
          feedback.stats = stats;
          feedback.modelInfo = { provider: 'groq', model: MODEL_NAME };
          feedback.evaluatedAt = new Date();
          return feedback;
        }
      }
      console.error('AI Speaking Feedback Error (Groq):', error);
      if (error.error) console.error('Groq Error Detail:', error.error);
      throw new Error('Failed to generate speaking feedback from AI');
    }
```

**RÀNG BUỘC:**
- Khối build `feedback` phải **khớp `:560-564`** (cùng `stats/modelInfo/evaluatedAt`). Nếu muốn tránh lặp, được phép tách 1 helper nhỏ `finalizeSpeakingFeedback(parsed, stats)` dùng cho cả 2 chỗ — nhưng KHÔNG đổi giá trị field.
- Giữ nguyên 2 dòng `console.error` + `throw` cũ ở nhánh fail (không nuốt lỗi khi không cứu được).
- KHÔNG bọc thêm try/catch quanh cả hàm; chỉ sửa trong catch có sẵn.

---

## 6. Backend GATE
- **Logic ở service, controller mỏng:** ✅ giữ nguyên — chỉ sửa service `aiService.js`.
- **Validate/auth:** không đổi route/middleware.
- **Query/N+1:** không chạm DB.
- **Rate-limit Groq (header log: 8000 tok/min):** tầng 1 `jsonrepair` KHÔNG gọi API → không tăng tải; tầng 2 chỉ chạy khi hiếm khi tầng 1 fail → chấp nhận được.

---

## 7. Lệnh verify
```bash
cd english_for_community_backend
node -e "import('jsonrepair').then(m=>console.log('jsonrepair ok:', typeof m.jsonrepair))"   # in 'function'
node --check src/services/aiService.js   # syntax ESM ok (nếu dự án có lint/test thì chạy thêm)
```
**Repro trực tiếp lỗi (bắt buộc — chứng minh cứu được):** dùng đúng `failed_generation` trong log để test unit tầng 1:
```bash
# Dán chuỗi failed_generation từ log vào biến, kiểm tra jsonrepair khôi phục:
node -e "import('jsonrepair').then(({jsonrepair})=>{const bad=process.env.BAD; const o=JSON.parse(jsonrepair(bad)); console.log('overall=',o.overall,'nextSteps=',o.nextSteps.length);})"
```
(Đặt `BAD` = nguyên văn chuỗi `failed_generation` từ log. Kỳ vọng: parse ra `overall=3`, `nextSteps` có 3 phần tử.)

## 8. Smoke API (bắt buộc)
1. Chạy backend, gọi lại `POST /api/speaking/conversation/evaluate` với chính transcript trong log (girlfriend/new job…) → kỳ vọng **200** + body feedback đầy đủ (không còn 502).
2. Xác nhận conversation lưu `status:'reviewed'` (không phải `failed`) và `trackUserProgress`/gamification vẫn chạy.
3. Case bình thường (JSON hợp lệ ngay từ đầu) vẫn 200 như cũ — không regression.

---

## 9. HANDOFF PROMPT cho Cursor
```text
Bạn là implementer. CHỈ sửa 2 file dưới; ngoài danh sách → DỪNG & hỏi.
Repo: english_for_community_backend (Node ESM).

FILE 1: package.json  -> npm install jsonrepair
FILE 2: src/services/aiService.js

THEO ĐÚNG mục 5 work-order:
  (b) import { jsonrepair } from 'jsonrepair'
  (c) thêm helper extractFailedGeneration(error) — property path CHÍNH XÁC:
        error.error.error.code / error.error.error.failed_generation
  (d) trong catch của generateSpeakingFeedback: nếu extractFailedGeneration != null ->
        tầng1 JSON.parse(jsonrepair(cleanJson(failed)));
        tầng2 (khi tầng1 fail) repairSpeakingFeedbackJson({...,badContent:failed});
        có parsed -> normalizeSpeakingFeedback + gắn stats/modelInfo/evaluatedAt (KHỚP :560-564) -> return;
        cả 2 fail -> giữ nguyên console.error + throw cũ.

TUYỆT ĐỐI KHÔNG: đụng speakingService/controller/model/route; đổi prompt/model/response_format;
  sửa normalizeSpeakingFeedback/cleanJson/repairSpeakingFeedbackJson; áp helper sang call-site khác.

VERIFY:
  - node -e "import('jsonrepair')..." in 'function'
  - node --check src/services/aiService.js
  - REPRO: đặt BAD = failed_generation trong log -> jsonrepair khôi phục ra overall=3, nextSteps=3.
  - SMOKE API: POST /api/speaking/conversation/evaluate với transcript trong log -> 200 + feedback,
    conversation status='reviewed' (không 502/failed).
Xong -> dán kết quả verify/smoke vào chat -> báo Opus audit.
```

## 10. Checklist OPUS AUDIT (Phase 4)
- [ ] Chỉ sửa `package.json` + `aiService.js`; file OUT không đụng (`git status`).
- [ ] `extractFailedGeneration` đọc đúng `error.error.error.code/.failed_generation`; guard non-string.
- [ ] Nhánh cứu: tầng1 jsonrepair → tầng2 LLM → normalize; build feedback KHỚP `:560-564`.
- [ ] Cả 2 tầng fail → vẫn `console.error` + `throw` (không nuốt lỗi).
- [ ] Repro: `jsonrepair` khôi phục đúng `failed_generation` trong log (overall=3, nextSteps=3).
- [ ] Smoke API: transcript log → 200 + `status:'reviewed'`; case JSON-hợp-lệ vẫn 200 (no regression).

---

## 11. Follow-up (OUT scope này — mở task riêng khi cần)
1. **Systemic:** cùng lỗ hổng ở 4 call-site `json_object` khác — `:85` (writing feedback), `:248/:251` (chính `repairSpeakingFeedbackJson`), `:294`, `:433`. Có thể tái dùng `extractFailedGeneration` + `jsonrepair` bọc chung 1 helper `parseGroqJsonOrRecover(promiseOrError)` cho tất cả. → 1 task T1 refactor.
2. **Diệt tận gốc:** chuyển `response_format` sang **Groq Structured Outputs** `{ type: 'json_schema', json_schema: { name, schema, strict: true } }` (gpt-oss-120b hỗ trợ) — grammar-constrained decoding ⇒ **không thể** sinh JSON sai ⇒ hết `json_validate_failed`. Chi phí: phải khai báo full JSON schema (~30 field, `additionalProperties:false`, mọi key vào `required`). → 1 task T1 hardening; sau khi có, tầng-cứu này thành lưới an toàn.

---

## 12. KẾT QUẢ IMPLEMENT (Opus tự code — 2026-07-04)

**Status: DONE.** User yêu cầu "tự sửa luôn" → Opus implement trực tiếp.

**Sai lệch so với plan (quan trọng):** test thực tế cho thấy **`jsonrepair` KHÔNG cứu được** đúng ca trong log — nó throw `JSONRepairError: Unexpected character '"' at position 3009` với đuôi `}"}`. Vì vậy tầng-1 deterministic được nâng cấp:

- Thêm helper `recoverJsonObject(raw)` — quét tôn trọng string/escape + stack bracket, cắt tại ranh giới value hợp lệ cuối rồi đóng bracket còn mở. **Đây mới là bộ sửa chính** cho `json_validate_failed`.
- Thêm `parseLenient(text)` — thang 3 bậc: `JSON.parse` thẳng → `jsonrepair` (giữ lại, tốt cho trailing-comma / thiếu quote) → `recoverJsonObject`.
- Catch dùng `parseLenient(cleanJson(failed))` cho tầng-1; tầng-2 LLM `repairSpeakingFeedbackJson` giữ nguyên.

**File đã đổi:**
- `package.json` — thêm `jsonrepair: ^3.15.0`.
- `aiService.js` — import jsonrepair (`:2`); helper `extractFailedGeneration`/`recoverJsonObject`/`parseLenient` (`:24-84`); nhánh cứu trong catch `generateSpeakingFeedback` (`:631-659`).

**Verify đã chạy:**
- `node --check src/services/aiService.js` → OK; dry import module → loaded ok.
- REPRO trên đúng `failed_generation` trong log: `JSON.parse` fail + `jsonrepair` fail → `recoverJsonObject` khôi phục ra `overall=3, cefr=A2, nextSteps=3, improvements=3, corrections=3, vocabUpgrades=2, modelAnswers=1`; đuôi `}"}` → `]}`.
- Sanity ladder: valid JSON / cụt-giữa-array / trailing-comma / rác-sau-root đều parse đúng.

**CÒN LẠI (chưa chạy được ở đây):** smoke API thật `POST /api/speaking/conversation/evaluate` với transcript trong log → kỳ vọng 200 + conversation `status:'reviewed'` (cần backend chạy + Groq key). Đề nghị chạy trước khi coi là đóng hoàn toàn.
