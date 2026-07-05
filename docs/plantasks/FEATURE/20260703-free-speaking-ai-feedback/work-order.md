# Work Order — Free Speaking: AI Feedback sau hội thoại (Phase 1 / MVP)

> **Mục tiêu:** biến Free Speaking từ "chỗ nói chuyện" thành **vòng lặp học có phản hồi**: user nói với AI → khi kết thúc, AI đưa ra **báo cáo đánh giá + góp ý cải thiện** dựa trên chính lời user nói, và lưu lại để theo dõi tiến bộ.
>
> **Người lập kế hoạch:** Opus (brain) · **Người thực hiện:** Cursor (implement) · **Ngày:** 2026-07-03

---

## 0. Quyết định đã chốt (KHÓA — không tự đổi)

| # | Quyết định | Chọn |
|---|-----------|------|
| Ngôn ngữ feedback | **Song ngữ**: nhận xét/giải thích **tiếng Việt**, ví dụ/câu mẫu/từ vựng **tiếng Anh** (giống Writing) |
| Phạm vi bản này | **Phase 1 đầy đủ** (chi tiết ở §3) |
| Chấm phát âm | **KHÔNG** làm ở Phase 1 (để Phase 3 — cần ghi audio + Azure/Google) |
| Model chấm | **Groq `gpt-oss-120b`** — tái dùng `aiService` hiện có, JSON mode |

---

## 1. Bối cảnh & hiện trạng (từ khảo sát code)

- Free Speaking dùng **Vapi SDK** (STT→LLM→TTS chạy trong Vapi). Backend chỉ cấp `publicKey`+`assistantId` qua `GET /api/speaking/vapi-config`. **Backend không nằm trong luồng hội thoại.**
- Vapi **có trả transcript** theo lượt (`{text, isFinal, role}`) → app đã render bong bóng, giữ ở `FreeSpeakingPage._messages` (`List<ChatMessage>`), **nhưng bị xoá khi đóng/để lại màn hình**. **Chưa lưu DB, chưa đánh giá, không lưu audio.**
- **Không có** model `Conversation`/`Message`/`SpeakingConversation`, **không có** endpoint nhận transcript hội thoại.
- **Writing đã có sẵn nguyên khung để nhân bản** (submit → AI chấm JSON → màn feedback nhiều tab → lịch sử → cộng Progress). **Bám khung này.**

### File mốc quan trọng (đường dẫn thật)
| Vai trò | File |
|--------|------|
| Màn Free Speaking + `_messages` + hook kết thúc call | `english_for_community/lib/feature/speaking/free_speaking_page.dart` (state ~L87–110; hook `status → ended/disconnected` ~L218–224; `_handleTranscript` L321–346; `logCallEnd()` đã fire ở đây) |
| Vapi service (event stream) | `lib/feature/speaking/vapi/vapi_service.dart`, `real_vapi_service.dart` |
| **Template backend chấm** | `english_for_community_backend/src/services/aiService.js` (`generateFeedback` L161–306, JSON mode, self-repair `repairParagraphRewrites`) |
| **Template model** | `english_for_community_backend/src/models/WritingSubmission.js` (`FeedbackSchema` L6–18) |
| **Template màn kết quả** | `english_for_community/lib/feature/writing/writing_feedback_page.dart` (`DefaultTabController(4)`, `_ScoreRow`, `_CriteriaCard`) + `widgets/interactive_diff_text.dart` (`{{old||new||reason}}`) |
| Submit-then-return-result pattern | `lib/feature/speaking/speaking_lesson_bloc/*` (`SubmitLessonAttemptEvent`, `LessonStatus`) |
| Progress rollup | `english_for_community_backend/src/utils/progressTracker.js`, `models/UserDailyProgress.js` (`stats.speakingScore` = 1−WER) |
| DI | `lib/core/get_it/get_it.dart` |
| Networking | `lib/core/api/api_client.dart` (`getIt<ApiClient>().getDio(authorized:true)`), repo trả `Either<Failure,T>` (dartz) |
| l10n | `lib/l10n/app_en.arb` + `app_vi.arb` → `context.l10n.<key>` (keys `freeSpeaking*`, `writingFb*`) |
| Theme | `app_color.dart`, `app_typography.dart`, `app_spacing.dart`, `app_skill_colors.dart` (`SkillType.speaking`), `student_mobile_ui.dart` |

---

## 2. Luồng nghiệp vụ tổng (Phase 1)

```
[Đang nói với AI] --bấm Kết thúc--> [Kiểm tra đủ dài?]
     |no (quá ngắn) --> toast "Trò chuyện thêm chút để nhận đánh giá nhé" --> về Home speaking
     |yes --> [Màn "Đang phân tích..."] --POST transcript--> Backend
                                                              |-- aiService.generateSpeakingFeedback (Groq JSON)
                                                              |-- lưu SpeakingConversation
                                                              |-- trackUserProgress('speaking', {score})
                                                              '--> trả feedback
                          <-------------------- feedback --------------------'
     --> [SpeakingFeedbackPage: Tổng quan / Chi tiết / Chữa lỗi / Câu mẫu] --> Lưu từ / Nói tiếp / Về
```

Điều kiện tối thiểu để chấm: **≥ 3 lượt user** *hoặc* **≥ 30s nói** (config hằng số `kMinTurnsForFeedback`, `kMinDurationSec`). Không đủ → không gọi AI, hiện thông báo nhẹ.

---

## 3. Phạm vi Phase 1

### TRONG phạm vi
1. **Bắt & lưu transcript** khi kết thúc hội thoại (client gửi `_messages` + thời lượng).
2. **Endpoint + service + model** lưu hội thoại & feedback.
3. **AI chấm song ngữ** theo rubric 4 tiêu chí (§4) → JSON (§6).
4. **Màn báo cáo** `SpeakingFeedbackPage` (§5) với đủ 9 khối nội dung.
5. **Nâng cấp từ vựng → nút "Lưu vào sổ từ"** (tái dùng cơ chế lưu Word hiện có).
6. **Thống kê nói** (words, duration, WPM, filler, số câu hỏi, số lượt) — tính ở backend.
7. **Lịch sử hội thoại** (list các buổi + điểm) & mở lại 1 buổi.
8. **Cộng điểm vào Progress** (ô Speaking).
9. **l10n song ngữ** cho toàn bộ chuỗi UI mới.

### NGOÀI phạm vi (Phase 2/3 — chỉ ghi backlog §9)
- Thư viện tình huống/chủ đề + chọn CEFR mục tiêu (Phase 2).
- Dashboard tiến bộ nâng cao, lỗi lặp lại, huy hiệu, ôn flashcard lỗi/từ (Phase 2).
- **Chấm phát âm** (ghi audio + Azure/Google), độ khó thích ứng, drill tự sinh, view cho giáo viên (Phase 3).

---

## 4. Rubric chấm (4 tiêu chí — bám IELTS Speaking)

| Mã | Tiêu chí | Chấm gì | Thang |
|----|----------|---------|-------|
| `fc` | **Fluency & Coherence** | trôi chảy, ngập ngừng, từ đệm, độ dài lượt, liên kết ý | band 0–9 |
| `lr` | **Lexical Resource** | đa dạng & tự nhiên của từ, collocation, lặp từ, dùng sai | band 0–9 |
| `gra` | **Grammatical Range & Accuracy** | đa dạng cấu trúc, thì, mạo/giới từ, mật độ lỗi | band 0–9 |
| `ia` | **Interaction & Task** | trả lời trúng ý, biết hỏi lại, giữ chủ đề, register | band 0–9 |

- **Overall** = trung bình (làm tròn 0.5) → kèm quy đổi **CEFR** (A1–C2) hiển thị nổi bật.
- **KHÔNG chấm Pronunciation** ở Phase 1. Trong UI để 1 dòng mờ "Phát âm: sắp có (cần bản ghi âm)".
- Chỉ chấm **lời của USER**; lời AI chỉ dùng làm ngữ cảnh.

### Thống kê tính bằng code (không nhờ AI, tránh bịa số)
- `words` = tổng số từ trong các lượt user.
- `durationSec` = client gửi lên (thời lượng call).
- `wpm` = `words / (durationSec/60)` (guard chia 0).
- `fillerCount` = đếm regex `\b(um+|uh+|er+|like|you know|kind of|sort of|actually|basically)\b` (case-insensitive) trên lời user.
- `questionCount` = số lượt user chứa `?` hoặc bắt đầu bằng wh-/aux (đơn giản: đếm `?`).
- `turnCount` = số lượt user.

---

## 5. Màn báo cáo `SpeakingFeedbackPage` (clone `WritingFeedbackPage`)

`DefaultTabController(length: 4)` — 4 tab:

**Tab 1 — Tổng quan**
- Card lớn: **CEFR level** + **overall band** + 1 câu tóm tắt động viên (song ngữ).
- 4 `_ScoreRow` (fc/lr/gra/ia) — điểm + nhãn + (Phase 2: mũi tên xu hướng vs buổi trước; Phase 1 để trống chỗ này).
- Hàng **chip thống kê**: ⏱ thời lượng · 🗣 số từ · ⚡ WPM · 😶 filler · ❓ câu hỏi.
- ✅ **Điểm mạnh** (2–3 bullet, trích câu user nói tốt).

**Tab 2 — Chi tiết**
- 4 `_CriteriaCard` (fc/lr/gra/ia): mỗi card = điểm + note tiếng Việt + các bullet.

**Tab 3 — Chữa lỗi**
- 🎯 **Cần cải thiện** (top 3–5): mỗi mục hiển thị `issue` (VN) · **before** (câu user) → **after** (câu hay hơn) · `explain` (VN). Dùng style diff của `interactive_diff_text.dart`.
- ✍️ **Chữa lỗi cụ thể** (`corrections[]`, gom theo `type`: grammar/vocab/collocation) — render diff `{{before||after||reason}}`.
- ⬆️ **Nâng cấp từ vựng** (`vocabUpgrades[]`): "bạn nói *said* → nên dùng **better**" + note (VN) + **nút "Lưu vào sổ từ"** (lưu `better` vào Word list của user).

**Tab 4 — Câu mẫu**
- 💬 `modelAnswers[]` (1–2): ngữ cảnh + lượt của bạn + **cách người bản xứ nói lại**.

**Footer (mọi tab):** ➡️ `nextSteps[]` (gợi ý luyện tiếp) + 2 nút: **Nói tiếp** (về Free Speaking) · **Về**.

Trạng thái tải: màn/overlay "Đang phân tích cuộc trò chuyện của bạn…" (dùng `AppLoadingIndicator` / `StudentMobileUi.runnerLoading`). Lỗi AI → `StudentMobileUi.errorBanner` + nút Thử lại (gửi lại transcript đã lưu, không mất dữ liệu).

---

## 6. Backend

### 6.1 Model mới `SpeakingConversation.js` (nhân bản `WritingSubmission`)
```js
// FeedbackSchema (mirror WritingSubmission.FeedbackSchema, đổi tiêu chí)
const SpeakingFeedbackSchema = new Schema({
  overall: Number,            // 0..9
  cefr: String,               // 'A1'..'C2'
  summary: String,            // song ngữ, ngắn, động viên
  fc: Number,  fcBullets: [String],  fcNote: String,
  lr: Number,  lrBullets: [String],  lrNote: String,
  gra: Number, graBullets: [String], graNote: String,
  ia: Number,  iaBullets: [String],  iaNote: String,
  strengths: [String],
  improvements:  [{ issue: String, before: String, after: String, explain: String }], // 3..5
  corrections:   [{ type: String, before: String, after: String, reason: String }],
  vocabUpgrades: [{ said: String, better: String, note: String }],
  modelAnswers:  [{ context: String, yourTurn: String, modelTurn: String }],           // 1..2
  nextSteps: [String],
  stats: { words: Number, durationSec: Number, wpm: Number, fillerCount: Number, questionCount: Number, turnCount: Number },
  modelInfo: { provider: String, model: String },
  evaluatedAt: Date,
}, { _id: false });

const SpeakingConversationSchema = new Schema({
  userId: { type: ObjectId, ref: 'User', index: true, required: true },
  mode: { type: String, default: 'freeSpeaking' },
  scenario: { type: String, default: null },   // Phase 2
  level: { type: String, default: null },       // CEFR target, Phase 2
  turns: [{ role: { type: String, enum: ['user','ai'] }, text: String, ts: Number }],
  wordCount: Number,
  durationSeconds: Number,
  status: { type: String, enum: ['evaluating','reviewed','failed'], default: 'evaluating' },
  feedback: SpeakingFeedbackSchema,
  score: Number,               // = overall
  startedAt: Date, endedAt: Date,
}, { timestamps: true });
```

### 6.2 Endpoints (thêm vào `speakingRoutes.js`, đều `authenticate`)
- `POST /api/speaking/conversation/evaluate`
  - body: `{ turns: [{role,text,ts?}], durationSeconds, startedAt?, endedAt?, level? }`
  - controller → `speakingService.evaluateConversation(userId, body)`:
    1. validate độ dài tối thiểu (server cũng chặn); nếu quá ngắn → 422 `{code:'TOO_SHORT'}`.
    2. tính `stats` (§4) từ `turns`.
    3. gọi `aiService.generateSpeakingFeedback({ turns, level, stats })`.
    4. lưu `SpeakingConversation` (status `reviewed`, `score = feedback.overall`).
    5. `trackUserProgress(userId, 'speaking', { duration: durationSeconds, score: feedback.overall/9, isLessonJustFinished: true })` + `updateGamificationStats`.
    6. trả `{ conversation }` (kèm feedback).
  - lỗi AI/parse → lưu status `failed` (giữ turns) + trả 502; client cho "Thử lại".
- `GET /api/speaking/conversation/history?limit=&cursor=` → list (id, createdAt, overall, cefr, durationSeconds, turnCount).
- `GET /api/speaking/conversation/:id` → 1 buổi đầy đủ (chủ sở hữu).

> **Ghi chú Progress:** hiện `stats.speakingScore` = 1−WER (0..1) từ drill. Ta đưa `overall/9` (0..1) vào **cùng bucket** để ô "Speaking %" phản ánh cả hội thoại — chấp nhận trộn ở MVP. Phase 2 tách bucket `speakingFluency` + tile riêng.

### 6.3 `aiService.generateSpeakingFeedback(...)` (clone `generateFeedback`)
- Groq `gpt-oss-120b`, `response_format:{type:'json_object'}`, `temperature:0.3`, có **self-repair pass** (như `repairParagraphRewrites`) để đảm bảo JSON hợp lệ & đủ field.
- **System prompt** (tinh thần): *"Bạn là giám khảo IELTS Speaking kiêm gia sư tiếng Anh cho người Việt. Chấm CHỈ phần lời của học viên (USER) trong hội thoại thoại nói (có thể có lỗi do nhận dạng giọng nói — bỏ qua lỗi chính tả nhỏ của STT). Chấm 4 tiêu chí fc/lr/gra/ia thang 0–9, quy đổi CEFR. **Mọi `*Note`, `*Bullets`, `explain`, `reason`, `note`, `summary`, `issue`, `nextSteps` viết bằng TIẾNG VIỆT**; **mọi `before/after/said/better/modelTurn/yourTurn` và ví dụ giữ nguyên TIẾNG ANH**. `improvements` phải trích ví dụ CÓ THẬT từ lời học viên. Không bịa số liệu thống kê (đã có sẵn). Trả đúng JSON theo schema."*
- **Input cho model**: transcript đánh dấu rõ `USER:` / `AI:` từng lượt + `level` (nếu có) + `stats` (để model tham chiếu, không tự tính).
- **Output**: đúng `SpeakingFeedbackSchema` (trừ `stats`/`modelInfo`/`evaluatedAt` do server gắn).
- Guard: nếu transcript user gần như trống/không phải tiếng Anh → trả feedback nhẹ nhàng, điểm thấp + gợi ý nói nhiều hơn (không crash).

---

## 7. Frontend

### 7.1 Bắt transcript & điều hướng
- Trong `free_speaking_page.dart`, tại nhánh kết thúc call (`status → ended/disconnected`, ~L218–224): **trước khi** `_resetState()`, chụp lại `turns` từ `_messages` (lọc role user/ai, bỏ system, chỉ lấy `isFinal`), tính `durationSeconds` (lưu `_callStartedAt` khi `call-start`).
- Thêm nút/nhãn rõ ràng **"Kết thúc & nhận đánh giá"** (đổi text nút stop khi đang active, hoặc dialog xác nhận khi bấm dừng: "Kết thúc và xem đánh giá?").
- Nếu đủ điều kiện → push màn feedback ở trạng thái loading và gọi bloc; nếu không đủ → `AppFeedback` toast nhẹ.
- (Tuỳ chọn kỹ thuật, ghi chú cho Cursor: Vapi có **server webhook end-of-call-report** cho transcript chuẩn hơn; MVP dùng client-send cho đơn giản & khớp kiến trúc hiện tại.)

### 7.2 Tầng data (theo repo pattern `Either<Failure,T>`)
- `SpeakingConversationRemoteDatasource` (dio: `speaking/conversation/evaluate`, `.../history`, `.../:id`).
- DTO/entity: `lib/core/dtos/speaking_feedback_dto.dart` + `lib/core/entity/speaking_conversation_entity.dart` (+ `SpeakingFeedbackEntity` mirror `writing_submission_entity.dart`).
- `SpeakingConversationRepository` + `Impl`.
- `SpeakingFeedbackBloc` (event `EvaluateConversationEvent(turns,duration,level?)`, `LoadConversationEvent(id)`; state `{status: initial|evaluating|reviewed|error, conversation, errorMessage}`) — theo mẫu `SpeakingLessonBloc`.
- **Đăng ký DI** trong `get_it.dart` (datasource+repo singleton, bloc factory). *(Cũng cân nhắc đưa `RealVapiService`/`VapiConfigRemoteDatasource` vào DI để test được — optional.)*

### 7.3 UI
- `lib/feature/speaking/speaking_feedback_page.dart` (clone `writing_feedback_page.dart`, §5).
- Lịch sử: thêm mục "Lịch sử luyện nói" (list) — có thể gắn vào màn Speaking hub hoặc 1 icon "history" trên app bar Free Speaking.
- Route mới trong `AppRouter`.
- Tái dùng `interactive_diff_text.dart`, `_ScoreRow`, `_CriteriaCard`, card style, `StudentMobileUi`, `AppSkillColors.speaking`.

### 7.4 l10n (thêm keys song ngữ vào `app_en.arb` + `app_vi.arb`, đặt tiền tố `speakingFb*` — nhái `writingFb*`)
Ví dụ keys: `speakingFbTitle, speakingFbTabOverview, speakingFbTabDetails, speakingFbTabCorrections, speakingFbTabSamples, speakingFbOverall, speakingFbCefr, speakingFbStrengths, speakingFbImprovements, speakingFbCorrections, speakingFbVocabUpgrades, speakingFbSaveWord, speakingFbSaved, speakingFbModelAnswers, speakingFbNextSteps, speakingFbAnalyzing, speakingFbTooShort, speakingFbRetry, speakingFbStatWords/Wpm/Duration/Filler/Questions, speakingFbEndAndEvaluate, speakingFbSpeakMore, speakingFbBack, speakingFbPronunciationSoon`.
Nhớ `flutter gen-l10n` sau khi sửa `.arb`.

---

## 8. Edge cases & phi chức năng
- Hội thoại quá ngắn / user không nói gì → chặn cả client + server, thông báo nhẹ, **không** tính là buổi thất bại.
- STT của Vapi có lỗi chính tả → prompt yêu cầu AI bỏ qua lỗi STT nhỏ, không trừ điểm oan.
- AI trả JSON hỏng → self-repair; vẫn hỏng → status `failed`, giữ transcript, cho "Thử lại".
- Mất mạng khi gửi → giữ transcript trong state, cho gửi lại; không mất buổi nói.
- Riêng tư: transcript là dữ liệu nhạy cảm → chỉ chủ sở hữu đọc; cân nhắc cho phép **xoá buổi**.
- Chi phí/độ trễ: 1 lần chấm/hội thoại; hiện loading rõ ràng (vài giây). Không auto-chấm khi thoát ngang do lỗi (chỉ khi user chủ động kết thúc).
- Không lưu audio ở Phase 1 (đã chốt).

## 8b. Acceptance criteria (Phase 1 coi là xong khi)
1. Nói ≥30s rồi "Kết thúc & nhận đánh giá" → hiện báo cáo 4 tab với dữ liệu thật từ hội thoại.
2. `improvements` trích đúng câu user đã nói (before) + bản sửa (after).
3. Nhận xét/giải thích bằng **tiếng Việt**, ví dụ/câu mẫu/từ bằng **tiếng Anh**.
4. Bấm "Lưu vào sổ từ" → từ vào Word list của user (kiểm tra ở Vocab).
5. Buổi nói lưu DB; mở lại từ Lịch sử thấy đúng.
6. Ô "Speaking" ở Progress tăng/đổi sau buổi nói.
7. Hội thoại quá ngắn → thông báo nhẹ, không tạo buổi lỗi.
8. AI lỗi → có "Thử lại", không mất transcript.

## 8c. Test plan nhanh
- Backend: unit cho `computeStats`, `evaluateConversation` (mock Groq), route auth + TOO_SHORT + FAILED.
- Client: bloc test (evaluating→reviewed / →error), widget test `SpeakingFeedbackPage` render đủ khối, capture transcript ở hook kết thúc.
- E2E thủ công theo 8 tiêu chí acceptance.

---

## 9. Backlog Phase 2 / 3 (chỉ ghi nhận, KHÔNG làm bây giờ)
**Phase 2:** thư viện tình huống (phỏng vấn, gọi món, IELTS Part 1/2/3, debate…) + chọn CEFR mục tiêu (AI đóng vai & chỉnh độ khó qua `assistantOverrides`) · dashboard tiến bộ (xu hướng từng tiêu chí, số phút, streak) · **error bank** (lỗi lặp lại) + ôn flashcard lỗi/từ (nối Vocab + nhắc hằng ngày) · huy hiệu/XP · tách bucket `speakingFluency` + tile riêng · mũi tên xu hướng ở Tab Tổng quan.
**Phase 3:** **chấm phát âm** (ghi audio trên máy + Azure/Google Pronunciation Assessment, phoneme-level) · độ khó thích ứng theo lịch sử · drill luyện điểm yếu tự sinh · cho giáo viên xem trong lớp · tận dụng Vapi end-of-call webhook cho transcript chuẩn.

---

## 10. Thứ tự thực hiện gợi ý cho Cursor
1. Model `SpeakingConversation` + `computeStats` + `aiService.generateSpeakingFeedback` (+ prompt) + endpoint `evaluate` → test bằng Postman với transcript mẫu.
2. Client: datasource/repo/entity/bloc + DI.
3. Hook bắt transcript ở `free_speaking_page.dart` + nút "Kết thúc & nhận đánh giá" + điều hướng loading.
4. `SpeakingFeedbackPage` (clone Writing) + route + l10n (`gen-l10n`).
5. "Lưu vào sổ từ" + Lịch sử + cộng Progress.
6. Chạy acceptance §8b.

> Sau khi Cursor làm xong, **nhờ Cursor audit** rồi Opus review lại theo quy trình.
