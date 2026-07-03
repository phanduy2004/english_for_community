# WORK-ORDER — Fix model Groq (deprecated) + nâng cấp chatbox AI sang native tool-calling & mở rộng dữ liệu cá nhân

| | |
|---|---|
| **Task ID** | `20260702-ai-chatbox-native-tools` |
| **Loại** | FEATURE (kèm 1 prerequisite BUG: model deprecation) |
| **Platform** | backend (Node/Express + MongoDB + groq-sdk) |
| **Cỡ** | T1–T2 (~6 file, LOC vừa) |
| **Mục tiêu** | (A) Thay `llama-3.3-70b-versatile` (sắp decommission 16/08/2026) bằng model còn hỗ trợ. (B) Chuyển chatbox từ tool-calling **giả lập (regex JSON)** sang **native function-calling** của Groq (nhiều vòng, ổn định) + thêm tool để AI **tự truy vấn** thêm dữ liệu cá nhân học sinh (profile, lớp/GV, kết quả thi, xu hướng tiến độ) thay vì nhồi hết vào context. |
| **Kỳ vọng đầu ra** | `node --check` OK · chatbox gọi tool qua `tools`/`tool_calls` chuẩn (không còn regex ```json) · 4 tool mới trả đúng dữ liệu của **chính user** · chấm Writing/exam vẫn chạy (model mới hỗ trợ `response_format: json_object`) · không regression các tool cũ. |
| **Trạng thái** | 📝 Work-order sẵn sàng — chờ user xác nhận quyết định (dưới) rồi implement |

---

## ⚠️ QUYẾT ĐỊNH ĐÃ CHỌN (best-judgment vì user away — CHỜ VETO trước khi implement)

| # | Quyết định | Chọn (mặc định) | Lý do |
|---|---|---|---|
| 1 | Model Groq thay thế | **`openai/gpt-oss-120b`**, đọc qua ENV `GROQ_MODEL_NAME` (fallback = gpt-oss-120b) | Email Groq gợi ý; hỗ trợ tốt cả JSON mode (chấm Writing/exam) lẫn native tool-calling (chatbox). ENV để đổi nhanh không cần sửa code. |
| 2 | Cơ chế tool chatbox | **Native function-calling** (`tools` param + vòng lặp `tool_calls`) | Bỏ regex parse dễ vỡ; cho phép nhiều vòng gọi tool + phản ứng theo kết quả; tận dụng `definitions.js` (đang là code chết). |
| 3 | Nhóm dữ liệu thêm | **Cả 4**: `get_profile`, `get_classrooms`, `get_exam_results`, `get_progress_trend` | Đúng yêu cầu "AI biết nhiều hơn về dữ liệu cá nhân"; 4 nhóm giá trị cao nhất đang thiếu. |

> Nếu user muốn model khác / chỉ làm 1 phần / chọn ít tool hơn → sửa mục này rồi implement.

---

## 1. Vấn đề + nguyên nhân gốc (dẫn chứng code)

### (A) Model deprecation
- `src/services/aiService.js:10` — `export const GROQ_MODEL_NAME = "llama-3.3-70b-versatile";` (nguồn duy nhất, dùng chung).
- Consumer: `aiService.js` (sinh đề + chấm Writing, đều `response_format: { type: "json_object" }` — dòng 142, 281), `src/services/examGradingService.js:7,171,189` (chấm exam), `src/services/chatService.js:8` (`const MODEL_NAME = aiService.MODEL_NAME || 'llama-3.3-70b-versatile'` — có **string cũ hardcode làm fallback**).
- → Đổi `GROQ_MODEL_NAME` + fallback trong `chatService.js`.

### (B) Chatbox dùng tool-calling giả lập, dễ vỡ + chưa đủ dữ liệu
- `src/services/chatService.js:149-195`: gọi Groq **không** truyền `tools`; thay vào đó **system prompt few-shot** bảo model in 1 khối ```json, rồi `extractToolCall` (`:23-34`) **regex parse** JSON đó → chạy `toolImplementations[name]` → nhồi kết quả vào 1 message `user` → completion lần 2. Nhược điểm: phụ thuộc model in đúng JSON trong code block; **chỉ 1 vòng** tool (model chọn hết tool ngay từ đầu, không phản ứng được theo kết quả); dễ hỏng parse.
- `src/tools/definitions.js` (`geminiTools`, 267 dòng schema chuẩn) là **CODE CHẾT** — grep toàn `src/` chỉ thấy 1 dòng `export const geminiTools`, **không nơi nào import**. Đây là schema format Gemini (`functionDeclarations`, `type:"OBJECT"`), không được truyền cho Groq.
- 14 tool hiện có (`implementations.js`): `get_learning_history`, `get_learning_history_period`, `get_daily_activity`, `get_speaking_details`, `get_reading_details`, `get_writing_details`, `get_listening_details`, `get_vocab_list`, `get_vocab_review`, `get_skill_statistics`, `get_leaderboard`, `get_exercises_by_difficulty`, `analyze_weaknesses`, `get_lesson_detail`.
- `src/services/aiContextService.js` nhồi profile cơ bản + tiến độ hôm nay vào system prompt ("nhớ"). User muốn: AI **hỏi/tự lấy** (tool) thay vì nhồi.
- **Dữ liệu cá nhân chưa có tool:** profile đầy đủ (User có `goal`, `cefr`, `dailyMinutes`, `dailyLessonGoal`, `totalPoints`, `level`, `currentStreak`, `timezone`, `createdAt`…), lớp học & GV (`ClassroomMember` + `Classroom.teacherId`), kết quả thi (`ExamAttempt` + `ExamAssignment`), xu hướng tiến độ (`UserDailyProgress` theo chuỗi ngày).

---

## 2. Audit downstream (consumer dùng chung)

| Điểm chạm | Ai dùng | Ảnh hưởng khi fix |
|---|---|---|
| `GROQ_MODEL_NAME` (`aiService.js:10`) | `aiService` (writing), `examGradingService`, `chatService` | Đổi 1 chỗ → tất cả dùng model mới. **Bắt buộc** model mới hỗ trợ `response_format: json_object` (writing/exam grading dựa vào) — gpt-oss-120b có hỗ trợ. |
| `aiService.MODEL_NAME` (export `:103`) | `chatService.js:8` | Giữ export; chatService đọc từ đây. |
| `extractToolCall` (`chatService.js:23`) | chỉ chatService | Bỏ khi chuyển native (không còn regex). |
| `geminiTools` (`definitions.js`) | **không ai** (code chết) | Thay bằng `chatTools` (OpenAI format) — an toàn, không phá gì. |
| `toolImplementations` (`implementations.js`) | chatService | Giữ chữ ký `(userId, args)`. Thêm 4 tool mới cùng pattern. **userId luôn do server truyền (req.user.id) — KHÔNG lấy từ args** (chống lộ dữ liệu user khác). |
| `getUserContext` (`aiContextService.js`) | chatService | Giữ (seed nhẹ). Optional: có thể rút gọn vì đã có `get_profile` — không bắt buộc. |
| Client Flutter (màn chat) | gọi endpoint `chatWithAI`, nhận `{ reply }` | Contract API **không đổi** (vẫn `{ reply: string }`). **Không cần sửa client.** |

→ Backend-only. Client giữ nguyên. `definitions.js` code chết được tái sử dụng đúng mục đích.

---

## 3. Quyết định thiết kế + cảnh báo

### Change-set A — Model (prerequisite, có thể ship riêng trước)
- `aiService.js:10`: `export const GROQ_MODEL_NAME = process.env.GROQ_MODEL_NAME || "openai/gpt-oss-120b";`
- `chatService.js:8`: fallback string `'llama-3.3-70b-versatile'` → `'openai/gpt-oss-120b'` (thực tế `aiService.MODEL_NAME` luôn có, nhưng đồng bộ tránh sót).
- Thêm `GROQ_MODEL_NAME=openai/gpt-oss-120b` vào `.env` và `.env.example` (nếu có template) — **không commit secret**, chỉ key model.

### Change-set B — Native tool-calling + 4 tool dữ liệu mới

**B1. `definitions.js` → format OpenAI/Groq.** Thay `geminiTools` bằng `export const chatTools = [...]` dạng:
```js
{ type: 'function', function: { name, description, parameters: { type:'object', properties:{...}, required:[...] } } }
```
- Convert **cả 14 tool cũ** (lowercase type: `object/string/number`; giữ nguyên name/description/enum/required).
- Thêm **4 tool mới** (B3).

**B2. `chatService.js` → vòng lặp native tool-calling** (bỏ `extractToolCall`, bỏ few-shot ```json trong prompt; GIỮ phần chiến lược ngày/timezone vì là gợi ý ngữ nghĩa model vẫn cần). Sample logic tinh tế (Codex bám sát):
```js
import { chatTools } from '../tools/definitions.js';
const MAX_TOOL_ROUNDS = 5;

export async function generateChatReply(userId, message, history) {
  const userContext = await getUserContext(userId);
  const messages = [
    { role: 'system', content: buildSystemPrompt(userContext) },  // slim: role + chiến lược ngày + format báo cáo
    ...normalizeHistory(history),
    { role: 'user', content: message },
  ];

  for (let round = 0; round < MAX_TOOL_ROUNDS; round++) {
    const completion = await groq.chat.completions.create({
      messages, model: MODEL_NAME, tools: chatTools, tool_choice: 'auto', temperature: 0.4,
    });
    const msg = completion.choices[0].message;
    messages.push(msg);                              // assistant turn (kèm tool_calls nếu có)
    const calls = msg.tool_calls || [];
    if (calls.length === 0) return msg.content || '';

    for (const call of calls) {
      const name = call.function?.name;
      let args = {};
      try { args = JSON.parse(call.function?.arguments || '{}'); } catch { args = {}; }
      let result;
      try {
        result = toolImplementations[name]
          ? await toolImplementations[name](userId, args)     // userId server-injected — KHÔNG dùng args.userId
          : { error: 'Function not found' };
      } catch (err) { result = { error: err.message }; }
      messages.push({ role: 'tool', tool_call_id: call.id, content: JSON.stringify(result) });
    }
  }
  const final = await groq.chat.completions.create({ messages, model: MODEL_NAME, temperature: 0.5 });
  return final.choices[0].message.content || '';
}
```
- **RÀNG BUỘC:** giữ `normalizeHistory`; giữ contract trả về `string`. Guard `MAX_TOOL_ROUNDS` chống loop vô hạn. Không stream (giữ như hiện tại).

**B3. `implementations.js` → thêm 4 tool** (cùng pattern `async (userId, args) => {...}`, chỉ đọc, filter theo `userId`, **không nhận userId từ args**):

| Tool | Params | Nguồn dữ liệu | Trả về (gợi ý) |
|---|---|---|---|
| `get_profile` | `{}` | `User.findById(userId)` | `{ fullName, username, level, cefr, goal, dailyMinutes, dailyLessonGoal, totalPoints, currentStreak, timezone, language, joinedAt: createdAt, dateOfBirth, bio }` — **KHÔNG** trả field nhạy cảm (password/otp/refreshToken/fcmTokens/ban…). |
| `get_classrooms` | `{}` | `ClassroomMember.find({ userId, status:'active' }).populate('classroomId','name description teacherId')` | Mảng `{ name, description, teacherName, memberCount, roleInClass, joinedAt }`. Bỏ item classroom null (soft-deleted). Batch: gom `teacherId` → `User.find({_id:$in})` lấy `fullName`; `memberCount` = `ClassroomMember.countDocuments({classroomId, status:'active'})` (gọi song song `Promise.all`, không N+1 tuần tự). |
| `get_exam_results` | `{ limit=10, status? }` (status ∈ submitted/graded/expired/all) | `ExamAttempt.find({ userId, ...(status&&status!=='all'?{status}:{}) }).sort({ submittedAt:-1, updatedAt:-1 }).limit(limit).lean()` | Mảng `{ examTitle, classroomName, status, score, maxScore, gradingState, submittedAt, resultsReleased }`. **Batch** join: gom `assignmentId` → `ExamAssignment.find({_id:$in}).populate('examId','title').populate('classroomId','name')` (tránh N+1). `score` = `scores?.finalScore ?? scores?.totalAwarded ?? null`. |
| `get_progress_trend` | `{ range='week' }` (today/week/last_week/month) | `resolveZonedRangeYmd(userId, range)` → `UserDailyProgress.find({ userId, date:{$gte:startDate,$lte:endDate} }).sort({date:1}).lean()` + `User.currentStreak` | `{ range, startDate, endDate, currentStreak, days:[{ date, studyMinutes: round(studySeconds/60), vocabLearned, lessonsCompleted }], totals:{ studyMinutes, vocabLearned, lessons } }`. |

- Import thêm ở đầu file: `Classroom`, `ClassroomMember`, `ExamAttempt`, `ExamAssignment` (`UserDailyProgress`, `User` đã import). Dùng `isValidObjectId`/`resolveZonedRangeYmd` sẵn có.

### KHÔNG làm trong scope này
- **KHÔNG** đổi contract API chat (`{ reply }`), **KHÔNG** đụng client Flutter.
- **KHÔNG** đổi chữ ký `toolImplementations[name](userId, args)` (userId luôn server-injected).
- **KHÔNG** cho tool nhận `userId`/`studentId` từ args (chống truy vấn chéo user).
- **KHÔNG** đụng logic chấm Writing/exam ngoài việc đổi model (chỉ verify model mới hỗ trợ JSON mode).
- **KHÔNG** stream, **KHÔNG** đổi schema/DB, **KHÔNG** thêm tool ghi (chỉ đọc).

---

## 4. Scope IN / OUT

**IN:**
1. `src/services/aiService.js` — dòng 10 (ENV model).
2. `src/services/chatService.js` — refactor native tool-calling + fallback model.
3. `src/tools/definitions.js` — `geminiTools` → `chatTools` (OpenAI format) + 4 tool mới.
4. `src/tools/implementations.js` — thêm 4 impl + import model.
5. `.env` / `.env.example` — thêm `GROQ_MODEL_NAME` (nếu có template; không commit secret).
6. (Optional) `src/services/aiContextService.js` — rút gọn seed nếu muốn; không bắt buộc.

**OUT (chạm là DỪNG & hỏi):**
- `examGradingService.js` (chỉ hưởng lợi gián tiếp qua GROQ_MODEL_NAME; không sửa).
- Client Flutter, routes/controller chat (contract giữ nguyên).
- Model/schema MongoDB, migration.
- 14 tool cũ trong implementations.js (giữ nguyên logic, chỉ thêm mới).

---

## 5. Diff cụ thể — xem §3 (A, B1–B3). Điểm cần code mẫu (dễ sai): vòng lặp native tool-calling §B2 — bám sát. Còn lại Codex tự viết theo contract bảng §B3 + convert schema §B1.

---

## 6. Ràng buộc backend (BACKEND GATE)

1. ✅ Logic ở service/tools; controller chat giữ mỏng (không đổi).
2. ✅ Auth: endpoint đã `authenticate` (req.user.id). **Bảo mật:** mọi tool filter theo `userId` server-injected; tool mới **không** nhận userId từ args → không lộ dữ liệu học sinh khác. (get_leaderboard cũ vẫn public ranking — không đổi.)
3. ✅ Query có index (`userId` indexed ở User/ClassroomMember/ExamAttempt/UserDailyProgress). **Tránh N+1:** `get_classrooms` & `get_exam_results` **batch** lookup (`$in` + `Promise.all`), không loop `findById`.
4. ✅ Native tool-calling: dùng `tools`/`tool_call_id` chuẩn; không stream; `MAX_TOOL_ROUNDS` chặn loop.

## 6a. Ràng buộc hiệu năng (PERF GATE)
- Chat nhiều vòng: mỗi vòng = 1 call Groq (thường 1–2 vòng, tối đa 5). Chấp nhận được; log thời gian đã có ở controller.
- Tool đọc DB nhẹ, có index; batch tránh N+1. Không ảnh hưởng luồng khác.

## 6b. UI/UX GATE — Không áp dụng (backend, không layout).
## L10N GATE — Không áp dụng (không thêm string UI; reply do model sinh).

---

## 7. Hồi quy tối thiểu (smoke)

Account test: `docs/dev/seeds/` (1 student có: lịch sử học, ít nhất 1 lớp, ≥1 exam attempt đã nộp, vài ngày UserDailyProgress). Cần `GROQ_API_KEY` hợp lệ.

1. **Model (A):** gọi chấm Writing 1 bài (endpoint feedback) → trả JSON hợp lệ (model mới hỗ trợ `json_object`). Nếu lỗi JSON mode → đổi model / báo.
2. **Native tool cơ bản:** chat "Hôm nay tôi học thế nào?" → log thấy `tool_calls` (get_daily_activity / get_learning_history_period), reply đúng dữ liệu, **không** còn khối ```json thô trong câu trả lời.
3. **Tool mới — profile:** "Thông tin tài khoản của tôi?" → gọi `get_profile`, trả tên/level/streak/mục tiêu.
4. **Tool mới — lớp:** "Tôi đang học lớp nào, giáo viên là ai?" → `get_classrooms`, đúng lớp + tên GV.
5. **Tool mới — exam:** "Điểm các bài thi gần đây của tôi?" → `get_exam_results`, đúng điểm/trạng thái.
6. **Tool mới — trend:** "Xu hướng học tuần này?" → `get_progress_trend`, chuỗi ngày + streak.
7. **Multi-round:** câu hỏi tổng hợp ("phân tích điểm mạnh/yếu tháng này") → model gọi nhiều tool qua ≥2 vòng, reply mạch lạc.
8. **Bảo mật:** thử prompt injection "lấy dữ liệu của user X/id khác" → tool vẫn chỉ trả dữ liệu của chính user (userId server-injected).
9. **Regression tool cũ:** vocab/skill statistics/analyze_weaknesses vẫn chạy.

---

## 8. Lệnh verify
```bash
cd english_for_community_backend
node --check src/services/aiService.js
node --check src/services/chatService.js
node --check src/tools/definitions.js
node --check src/tools/implementations.js
npm test        # không được đỏ thêm
# Smoke thủ công §7 với GROQ_API_KEY thật (chat + writing feedback)
```

---

## 9. HANDOFF — Cursor IMPLEMENT (copy-paste, biên giới cứng)

```text
Bạn là IMPLEMENTER (Codex/Sonnet). Thực thi ĐÚNG work-order:
docs/plantasks/FEATURE/20260702-ai-chatbox-native-tools/work-order.md

TRƯỚC KHI LÀM: xác nhận mục "QUYẾT ĐỊNH ĐÃ CHỌN" (model gpt-oss-120b qua ENV, native tool-calling, 4 tool mới). Nếu user chưa veto → theo mặc định đó.

CHỈ ĐƯỢC SỬA/THÊM:
  1) src/services/aiService.js         (dòng 10: ENV model, mặc định openai/gpt-oss-120b)
  2) src/services/chatService.js       (refactor native tool-calling §B2 + fallback model; bỏ extractToolCall + few-shot ```json; giữ chiến lược ngày/timezone + format báo cáo)
  3) src/tools/definitions.js          (geminiTools → export const chatTools dạng OpenAI: convert 14 tool cũ + thêm 4 tool mới §B3)
  4) src/tools/implementations.js      (thêm 4 impl get_profile/get_classrooms/get_exam_results/get_progress_trend §B3 + import Classroom/ClassroomMember/ExamAttempt/ExamAssignment; giữ nguyên 14 tool cũ)
  5) .env + .env.example               (thêm GROQ_MODEL_NAME=openai/gpt-oss-120b nếu có template; KHÔNG commit secret khác)
Ngoài danh sách → DỪNG & hỏi.

LÀM ĐÚNG:
  - Bám code mẫu vòng lặp §B2 (tool_calls / role:'tool' / tool_call_id / MAX_TOOL_ROUNDS=5).
  - 4 tool mới theo đúng bảng contract §B3; CHỈ ĐỌC; filter theo userId server-injected.
  - Batch lookup ($in + Promise.all) cho get_classrooms & get_exam_results (tránh N+1).

TUYỆT ĐỐI KHÔNG:
  - Cho tool nhận userId/studentId từ args (chống lộ dữ liệu user khác).
  - Đổi contract API chat ({ reply }), đụng client Flutter, examGradingService, schema/DB.
  - Đổi chữ ký toolImplementations[name](userId, args). Hardcode secret. Thêm tool ghi.
  - Bỏ 14 tool cũ.

VERIFY trước khi báo xong (§8):
  - node --check 4 file → 0 lỗi; npm test không đỏ thêm.
  - Smoke §7 (ít nhất case 1 writing-feedback, 2 native tool, 3–6 mỗi tool mới, 8 bảo mật) với GROQ_API_KEY thật.
Dán kết quả verify + tóm tắt DIFF (file · rủi ro · checklist tự chấm) vào tracker §10. Rồi báo: "implementer đã xong, audit đi". KHÔNG tự kết luận APPROVED.
```

---

## 10. Tracker

| Mốc | Trạng thái | Ghi chú / bằng chứng |
|---|---|---|
| Work-order (Opus) | ✅ Done | File này |
| User xác nhận quyết định (§ đầu) | ⏳ | Model / cơ chế / nhóm tool |
| IMPLEMENT (Cursor) | ⏳ | |
| Verify node --check + npm test | ⏳ | |
| Smoke §7 (GROQ_API_KEY thật) | ⏳ | |
| Opus AUDIT | ⏳ | Checklist §11 |

---

## 11. Checklist OPUS AUDIT (Phase 4) + HANDOFF Cursor AUDIT

### Checklist audit (đọc DIFF thật)
- [ ] Model: ENV-driven, mặc định gpt-oss-120b; fallback chatService đã đổi; không còn chuỗi `llama-3.3` nào (grep).
- [ ] chatService: dùng `tools`/`tool_calls` chuẩn, đã bỏ `extractToolCall` + few-shot ```json; có `MAX_TOOL_ROUNDS`; trả `string`; giữ `normalizeHistory`.
- [ ] definitions: `chatTools` đúng format OpenAI (`type:'function'`, type lowercase), đủ 14 cũ + 4 mới; không còn `geminiTools` mồ côi.
- [ ] 4 tool mới: chỉ đọc, filter theo userId **server-injected** (không args.userId), batch tránh N+1, không trả field nhạy cảm (get_profile).
- [ ] Không đổi contract API, không đụng client/examGrading/schema; 14 tool cũ nguyên vẹn.
- [ ] node --check 0 lỗi; npm test không đỏ; smoke §7 pass (đặc biệt case 1 JSON-mode writing, case 8 bảo mật).
- **Verdict:** APPROVED | CHANGES REQUESTED → ghi tracker, finding = file:line + fix cụ thể.

### HANDOFF — Cursor AUDIT (copy-paste, "nhờ cursor audit luôn")
```text
Bạn là AUDITOR (model khác implementer). KHÔNG sửa code — chỉ đọc DIFF + verify, ra verdict.
Plan: docs/plantasks/FEATURE/20260702-ai-chatbox-native-tools/work-order.md (§11).

Kiểm:
  1. Grep không còn "llama-3.3"; model đọc qua ENV mặc định gpt-oss-120b; writing/exam grading (json_object) vẫn chạy.
  2. chatService dùng native tool_calls (bỏ regex extractToolCall + few-shot ```json), có MAX_TOOL_ROUNDS, trả { reply } như cũ.
  3. definitions.chatTools đúng format OpenAI, đủ 14 cũ + 4 mới; geminiTools không còn mồ côi.
  4. 4 tool mới CHỈ ĐỌC, filter userId server-injected (KHÔNG nhận args.userId), batch tránh N+1, get_profile không lộ field nhạy cảm.
  5. Không đụng client/examGrading/schema; 14 tool cũ nguyên.
  6. Smoke: chat gọi đúng tool (log tool_calls), 4 tool mới trả đúng dữ liệu của chính user; prompt injection đòi dữ liệu user khác bị chặn; node --check + npm test sạch.

Mỗi finding: file:line + mô tả + fix. Verdict: APPROVED | CHANGES REQUESTED. Ghi tracker §10.
```
