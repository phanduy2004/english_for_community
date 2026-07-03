# WORK-ORDER — Live session (phòng thi realtime) không tự kết thúc khi hết giờ

| | |
|---|---|
| **Task ID** | `20260702-live-session-auto-end` |
| **Loại** | BUG |
| **Platform** | backend (Node/Express + MongoDB) — **fix backend-only**, client đã phản ứng đúng |
| **Cỡ** | T1 (4 file, ~40 dòng) |
| **Mục tiêu** | Khi live session (assignment `mode: 'realtime'`) vượt qua thời điểm hết giờ (`timeLimitSeconds` và/hoặc `hardEndAt`), hệ thống **tự động**: đóng phòng (`ExamSession.status → closed`) + **force-submit + chấm** mọi attempt `in_progress` + phát socket `exam_session_ended` — **không phụ thuộc việc GV có mở live console hay không**. |
| **Kỳ vọng đầu ra** | `node --check` OK · server khởi động không lỗi · sau khi qua scheduled end ≤ ~1 phút: session `closed` + `endedAt` set, mọi attempt `in_progress` của session → `submitted` (có `submittedAt` + `scores` + `gradingState`), socket `exam_session_ended` phát, student/lobby tự thoát · **không regression**: async/scheduled/self_paced attempts vẫn expired qua cron cũ; live session KHÔNG cấu hình giờ (`timeLimitSeconds` null & `hardEndAt` null) thì KHÔNG bị đóng. |
| **Trạng thái** | 📝 Work-order sẵn sàng — chờ implement |

---

## 1. Vấn đề + nguyên nhân gốc (dẫn chứng code)

### Triệu chứng (user + ảnh)
GV tạo 1 live session (`Kiểm tra giữa kì`, 60 min) hôm trước, quên bấm **End session**. Hôm sau mở lên phòng **vẫn đang "Live session"** (chưa đóng). Nghiệp vụ đúng: từ lúc mở live tới khi hết thời gian thi → **tự kết thúc phòng** + **tự nộp bài học sinh**.

> Lưu ý về ảnh: badge **"Live session"** trong màn Grading queue KHÔNG phải trạng thái phòng — nó là nhãn `mode` của assignment (xem §2). Vấn đề thật là `ExamSession.status` **kẹt ở `live`** trong DB.

### Nguyên nhân gốc — có logic auto-end nhưng KHÔNG có ai gọi định kỳ

**(A) Auto-end phòng chỉ chạy LAZY, không có background job.**
Hàm tự đóng phòng đã tồn tại — `english_for_community_backend/src/services/examSessionService.js:94-109`:
```js
/** When live session passes scheduled end (time limit / hardEndAt), auto-close like teacher "End session". */
async function maybeAutoEndLiveSessionIfDue(session) {
  if (!session || session.status !== 'live') return;
  const assignment = session.assignmentId && typeof session.assignmentId === 'object' ? session.assignmentId : null;
  if (!assignment) return;
  const end = computeSessionScheduledEnd(session, assignment);
  if (!end || end.getTime() > Date.now()) return;
  try {
    await examSessionService.endSession(session.leaderTeacherId, session._id);
  } catch { /* race or already ended */ }
}
```
Nhưng nó được gọi **duy nhất 1 chỗ** — bên trong `buildRealtimePayload` (`examSessionService.js:125-127`):
```js
if (session?.status === 'live') {
  await maybeAutoEndLiveSessionIfDue(session);   // ← trigger DUY NHẤT
}
```
`buildRealtimePayload` chỉ chạy khi có request/socket đọc state phòng: `getSessionConsoleForTeacher` (`:282`), `emitSessionStateBroadcast` (`:293`), `getSessionLobbyForTeacher` (`:306`), `kickParticipant`, `setParticipantReady`. **Không có cron/timer/interval nào gọi nó.** → GV đóng app + học sinh disconnect ⇒ không ai gọi ⇒ phòng ở `live` **vĩnh viễn**. Đúng triệu chứng.

**Quan trọng — màn Grading queue (ảnh) KHÔNG kích hoạt auto-end:** endpoint của màn đó là `getAssignmentGradingHub` (`examAttemptService.js:1755-1816`) — chỉ trả `assignment.mode` + list attempts, **không** đụng `buildRealtimePayload`/`maybeAutoEndLiveSessionIfDue`. Nên kể cả khi GV mở lại màn này, phòng vẫn không đóng.

**(B) Cron exam duy nhất chỉ expire ATTEMPT kiểu thô — không đóng session, không nộp đúng nghiệp vụ.**
`english_for_community_backend/src/jobs/examAttemptExpireJob.js` (mỗi 2 phút) gọi `bulkExpirePastDeadline` — `examAttemptService.js:1449-1457`:
```js
async bulkExpirePastDeadline() {
  const now = new Date();
  const res = await ExamAttempt.updateMany(
    { status: 'in_progress', attemptDeadlineAt: { $lte: now } },
    { $set: { status: 'expired' } }        // ← chỉ lật status, KHÔNG submit/chấm/notify, KHÔNG set submittedAt
  );
  return res.modifiedCount ?? 0;
}
```
Đây là lý do attempt học sinh hiện **"Time is up"** (`status: 'expired'`) nhưng **phòng vẫn mở** và bài **không đi qua flow nộp thật** (`submit`). Cron này **không bao giờ** đụng `ExamSession`.

### Flow ĐÚNG đã có sẵn — fix chỉ cần gọi nó định kỳ
`endSession` (`examSessionService.js:506-549`) là teardown đầy đủ, đã dùng cho nút **End session** của GV: set `grading` → **force-submit + chấm** mọi attempt `in_progress` qua `examAttemptService.submit(force, forceEnd)` → set `closed` → phát socket `exam_session_state` + `exam_session_ended`. `submit(forceEnd:true)` (`examAttemptService.js:1580-1737`) set `status:'submitted'` + `submittedAt` + `scores` + `gradingState` + `broadcastAttemptProgress` + `afterAttemptActivity` (notify GV, log activity). Đây chính là "tự động nộp bài" đúng nghiệp vụ.

**Kết luận root-cause:** thiếu **background job** quét `ExamSession` `live` quá hạn để gọi `endSession`. Mảnh ghép (`computeSessionScheduledEnd`, `endSession`) đã có — chỉ chưa được gọi theo lịch.

---

## 2. Audit downstream (consumer dùng chung)

| Điểm chạm | Ai dùng | Ảnh hưởng khi fix |
|---|---|---|
| **`endSession`** | nút End session (`teacherExamController.js:378`) + lazy `maybeAutoEndLiveSessionIfDue` (`:105`) | Thêm 1 caller mới (cron). `endSession` đã idempotent: early-return nếu `status ∈ {closed, canceled}` (`:510`) → gọi trùng vô hại. Race đóng-đôi (GV bấm End + cron) **đã tồn tại sẵn** với lazy path, không phát sinh class rủi ro mới. |
| **`bulkExpirePastDeadline`** | **chỉ** `examAttemptExpireJob.js:11` (đã grep: không caller nào khác) | Thu hẹp về `sessionId: null` (§3-B). Không nơi nào khác phụ thuộc. |
| **Badge "Live session" (client)** | `teacher_grading_hub_labels.dart:16-27` render từ `assignment.mode == 'realtime'` (nhãn tĩnh `examModeRealtime`) | **KHÔNG** đọc `ExamSession.status` → không cần đổi. Badge này luôn hiện cho assignment realtime, độc lập trạng thái phòng. |
| **Client student/lobby** | `exam_live_session_guard.dart:58-109`, `exam_session_lobby_page.dart:140-163` nghe `exam_session_state`/`exam_session_ended`; khi `status ∈ {closed, grading}` → `_exit()` | Đã phản ứng ĐÚNG khi backend đóng phòng + phát socket (endSession làm việc này). **Không cần đổi client.** |
| **Attempt `sessionId`** | realtime set `sessionId` (`examSessionService.js:468`); mọi mode khác để `null` (`examAttemptService.js:1536`, không set) — **đã verify** | Filter `sessionId: null` tách sạch: async/scheduled/self_paced/practice → cron cũ; realtime → session lifecycle. |

→ Fix khoanh gọn trong backend jobs + 2 service method. Client **không đổi**.

---

## 3. Quyết định thiết kế + cảnh báo

Fix gồm **2 thay đổi khớp nhau** (phải làm cả hai để "tự nộp bài" đúng nghiệp vụ, không chỉ half-baked expire):

### Change A — Thêm cron job đóng live session quá hạn (mảnh chính)
- Thêm method `bulkAutoEndDueLiveSessions()` vào `examSessionService` (đặt trong cùng module để dùng được `computeSessionScheduledEnd` private): quét `ExamSession.find({ status: 'live' })`, với mỗi session populate `assignment.config/mode`, tính `computeSessionScheduledEnd`, nếu đã quá hạn → `examSessionService.endSession(leaderTeacherId, _id)`, đếm số phòng đóng để log.
- Thêm file job `examSessionExpireJob.js` (giống hệt pattern `examAttemptExpireJob.js`) chạy **mỗi 1 phút** (`* * * * *`), gọi `bulkAutoEndDueLiveSessions`.
- Wire vào `server.js` cạnh `initExamAttemptExpireJob()`.

**Vì sao đóng phòng qua `endSession` (không tự viết logic mới):** tái dùng đúng flow đã kiểm chứng của nút End session — force-submit + chấm + phát socket. Không nhân đôi logic.

**Vì sao mỗi 1 phút:** đóng phòng kịp thời (sát giờ hết) mà vẫn nhẹ (query `status:'live'` có index, thường 0–vài doc; `endSession` chỉ chạy cho phòng ĐÃ quá hạn — hiếm).

### Change B — Thu hẹp `bulkExpirePastDeadline` về `sessionId: null` (để realtime nộp qua flow đúng)
Hiện `bulkExpirePastDeadline` (cron 2 phút) sẽ lật realtime attempt `in_progress` → `expired` **thô** ngay khi qua `attemptDeadlineAt`. Do realtime `attemptDeadlineAt == started + timeLimit == scheduledEnd`, cron này **có thể chạy trước** cron session (race) → khi `endSession` chạy sau thì không còn attempt `in_progress` để submit ⇒ bài kẹt ở `expired` (không `submittedAt`, không qua `submit`/notify). Đây đúng là hành vi nửa vời user than phiền.

→ Thêm `sessionId: null` vào filter để cron cũ **chỉ** lo attempt non-realtime; realtime attempt do **session lifecycle** sở hữu (đóng qua `endSession` → submit đúng; hoặc lazy `lazyExpireIfNeeded` khi học sinh mở lại bài → cũng submit đúng). Deterministic, hết race.

**An toàn (đã verify):** chỉ realtime attempt có `sessionId`; async/scheduled/self_paced/practice để `null` (`examAttemptService.js:1536` không set field này). Open-ended realtime (không timeLimit) có `attemptDeadlineAt: null` → vốn dĩ không khớp filter `attemptDeadlineAt ≤ now` → Change B không đổi gì cho case đó.

### KHÔNG làm trong scope này
- **KHÔNG** đổi `endSession` (giữ nguyên chữ ký + logic — nhiều caller). Race đóng-đôi để nguyên (đã benign sẵn).
- **KHÔNG** đổi `maybeAutoEndLiveSessionIfDue`/`computeSessionScheduledEnd`/`buildRealtimePayload` (giữ lazy path song song — vô hại).
- **KHÔNG** thêm auto-close cho live session không cấu hình giờ (mở vô thời hạn) — đúng thiết kế: chỉ đóng khi có `timeLimitSeconds` hoặc `hardEndAt`. (Case user có 60 min nên được đóng.)
- **KHÔNG** đụng client Flutter (đã phản ứng đúng socket — §2).
- **KHÔNG** đụng schema/migration.

---

## 4. Scope IN / OUT

**IN (được sửa):**
1. `english_for_community_backend/src/jobs/examSessionExpireJob.js` — **file mới**.
2. `english_for_community_backend/src/services/examSessionService.js` — thêm method `bulkAutoEndDueLiveSessions` vào object `examSessionService` (không sửa method cũ).
3. `english_for_community_backend/server.js` — thêm import + gọi `initExamSessionExpireJob()`.
4. `english_for_community_backend/src/services/examAttemptService.js` — chỉ dòng filter trong `bulkExpirePastDeadline` (thêm `sessionId: null`).

**OUT (chạm là DỪNG & hỏi):**
- `endSession`, `maybeAutoEndLiveSessionIfDue`, `computeSessionScheduledEnd`, `buildRealtimePayload`, `startSession` (giữ nguyên).
- Bất kỳ file client Flutter nào.
- Model/schema (`ExamSession.js`, `ExamAttempt.js`), migration.
- `examAttemptExpireJob.js` (giữ nguyên — chỉ đổi filter bên trong service).

---

## 5. Diff cụ thể

### 5.1 — FILE MỚI: `english_for_community_backend/src/jobs/examSessionExpireJob.js`
Viết theo đúng pattern `examAttemptExpireJob.js`:
```js
import cron from 'node-cron';
import { examSessionService } from '../services/examSessionService.js';

/**
 * Auto-closes live exam sessions whose scheduled end (time limit / hardEndAt) has passed.
 * Complements the lazy auto-end that only fires when someone reads the realtime payload.
 */
export function initExamSessionExpireJob() {
  cron.schedule('* * * * *', async () => {
    try {
      const n = await examSessionService.bulkAutoEndDueLiveSessions();
      if (n > 0) console.log(`[examSessionExpire] auto-ended ${n} live session(s)`);
    } catch (e) {
      console.error('[examSessionExpire]', e);
    }
  });
}
```
**RÀNG BUỘC:** dùng `node-cron` (đã là dep, import y hệt file cũ). Lịch `* * * * *` (1 phút).

### 5.2 — `examSessionService.js`: thêm method `bulkAutoEndDueLiveSessions`
Thêm vào **trong object literal** `export const examSessionService = { ... }`, ngay sau `maybeAutoEndLiveSessionIfDue,` (dòng ~112) hoặc bất kỳ vị trí method nào trong object. Method dùng `computeSessionScheduledEnd` (private, cùng module — OK):
```js
  /** Cron sweep: close every live session whose scheduled end (time limit / hardEndAt) has passed. */
  async bulkAutoEndDueLiveSessions() {
    const now = Date.now();
    const sessions = await ExamSession.find({ status: 'live' })
      .populate({ path: 'assignmentId', select: 'config mode' });
    let closed = 0;
    for (const session of sessions) {
      const assignment =
        session.assignmentId && typeof session.assignmentId === 'object'
          ? session.assignmentId
          : null;
      if (!assignment) continue;
      const end = computeSessionScheduledEnd(session, assignment);
      if (!end || end.getTime() > now) continue;
      try {
        await examSessionService.endSession(session.leaderTeacherId, session._id);
        closed += 1;
      } catch {
        /* race or already ended */
      }
    }
    return closed;
  },
```
**RÀNG BUỘC:**
- Gọi `examSessionService.endSession(...)` (khớp style `maybeAutoEndLiveSessionIfDue`), **không** viết lại logic đóng phòng.
- Chỉ `.populate` `config mode` (đủ cho `computeSessionScheduledEnd`); `endSession` tự re-fetch + populate riêng.
- Không đổi/không đụng `computeSessionScheduledEnd`, `maybeAutoEndLiveSessionIfDue`, `endSession`.

### 5.3 — `server.js`: wire job
Cạnh import dòng 8 và init dòng 49:
```js
import { initExamSessionExpireJob } from './src/jobs/examSessionExpireJob.js';
// ...
initExamAttemptExpireJob();
initExamSessionExpireJob();   // ← thêm dòng này
```

### 5.4 — `examAttemptService.js`: thu hẹp `bulkExpirePastDeadline` (dòng ~1450-1457)
Thay:
```js
  async bulkExpirePastDeadline() {
    const now = new Date();
    const res = await ExamAttempt.updateMany(
      { status: 'in_progress', attemptDeadlineAt: { $lte: now } },
      { $set: { status: 'expired' } }
    );
    return res.modifiedCount ?? 0;
  },
```
Bằng (thêm `sessionId: null`):
```js
  async bulkExpirePastDeadline() {
    const now = new Date();
    // Realtime/live-session attempts (sessionId set) are owned by the session lifecycle
    // (endSession force-submits + grades them). Only bulk-expire non-session attempts here.
    const res = await ExamAttempt.updateMany(
      { status: 'in_progress', attemptDeadlineAt: { $lte: now }, sessionId: null },
      { $set: { status: 'expired' } }
    );
    return res.modifiedCount ?? 0;
  },
```
**RÀNG BUỘC:** chỉ thêm `sessionId: null` vào filter + comment. Không đổi gì khác trong hàm.

---

## 6. Ràng buộc hiệu năng (PERF GATE)

- ✅ `ExamSession.find({ status: 'live' })` dùng index `status` (schema `index: true`, `ExamSession.js:14`) — thường trả 0–vài doc. Cron 1 phút, chi phí không đáng kể.
- ✅ `endSession` chỉ chạy cho phòng **đã quá hạn** (hiếm) — không phải mọi tick.
- ✅ Không N+1 phát sinh: vòng lặp chỉ với live sessions; `endSession` re-fetch có chủ đích (giữ nguyên hành vi hiện tại).
- ✅ Change B: filter `{ status, attemptDeadlineAt, sessionId }` — tận dụng index sẵn có (`{ status:1, attemptDeadlineAt:1 }` hoặc `{ sessionId:1, status:1 }`), tập kết quả nhỏ. Không cần index mới.
- ⚠️ node-cron không tự chống overlap nếu 1 tick chạy > 1 phút; nhưng `bulkAutoEndDueLiveSessions` nhanh (indexed find + endSession chỉ cho phòng quá hạn) → không lo. Không cần lock.

## 6c. Backend GATE

1. ✅ Logic ở **service** (`bulkAutoEndDueLiveSessions` trong `examSessionService`); job chỉ là lớp mỏng gọi service (không controller/route mới).
2. ✅ Không route/endpoint mới → không cần Zod/auth middleware. Cron nội bộ. `endSession` vẫn tự check ownership (`leaderTeacherId`) — ta truyền đúng `session.leaderTeacherId` nên hợp lệ, không bypass.
3. ✅ Query có index (`status`); populate tối thiểu (`config mode`); không loop `findById`.
4. ✅ Socket: `endSession` phát `exam_session_state` + `exam_session_ended` (không thêm handler/emit mới, không duplicate). Client đã nghe sẵn.

## 6b. UI/UX GATE — Không áp dụng (không chạm client/layout).
## L10N GATE — Không áp dụng (không thêm string UI).

---

## 7. Hồi quy tối thiểu (smoke)

Account test: `docs/dev/seeds/` (1 teacher + ≥1 student, assignment `mode: 'realtime'` có `timeLimitSeconds` ngắn để test nhanh).

1. **Bug chính — auto đóng + auto nộp:** GV tạo session realtime (đặt `timeLimitSeconds` ~2 phút cho dễ test), start, học sinh join + làm dở (không submit). **Đóng cả app GV lẫn student.** Chờ qua mốc hết giờ + ≤1 phút. Kiểm DB/API:
   - `ExamSession.status == 'closed'`, `endedAt` != null.
   - Attempt học sinh `status == 'submitted'`, `submittedAt` != null, có `scores`/`gradingState` (KHÔNG còn `in_progress`/`expired` thô).
   - Log server: `[examSessionExpire] auto-ended 1 live session(s)`.
2. **Socket đẩy client:** nếu để 1 student còn mở màn exam khi hết giờ → nhận `exam_session_ended`/`status: closed` → tự thoát (guard `_exit`).
3. **Regression async:** 1 attempt `mode: 'self_paced'`/`scheduled` (sessionId null) quá `attemptDeadlineAt` → cron cũ vẫn lật `expired` như trước (Change B không ảnh hưởng vì sessionId null vẫn khớp filter).
4. **Open-ended live:** session realtime KHÔNG đặt `timeLimitSeconds` & KHÔNG `hardEndAt` → cron **KHÔNG** đóng (đúng thiết kế). Verify phòng vẫn `live`.
5. **Idempotent:** GV bấm **End session** thủ công trước khi cron chạy → sau đó cron chạy không lỗi, không đổi lại trạng thái (early-return `closed`).
6. **hardEndAt:** nếu `hardEndAt` sớm hơn `started + timeLimit` → đóng theo `hardEndAt` (min). Verify nếu có cấu hình này.

---

## 8. Lệnh verify

```bash
cd english_for_community_backend
node --check src/jobs/examSessionExpireJob.js
node --check src/services/examSessionService.js
node --check src/services/examAttemptService.js
node --check server.js
npm test        # chạy full suite; CHÚ Ý test realtime bên dưới
```
- Yêu cầu: `node --check` 0 lỗi; server `npm start`/`node server.js` khởi động in log job không crash.
- **Bắt buộc kiểm** `src/tests/examRealtime.e2e.test.js` (có tạo attempt `sessionId: 's1'`) vẫn PASS sau Change B. Nếu test nào assert `bulkExpirePastDeadline` expire attempt có `sessionId` → DỪNG & báo (có thể cần cập nhật test cho đúng nghiệp vụ mới).

---

## 9. HANDOFF — Cursor IMPLEMENT (copy-paste, biên giới cứng)

```text
Bạn là IMPLEMENTER (Codex/Sonnet). Thực thi ĐÚNG work-order:
docs/plantasks/BUG/20260702-live-session-auto-end/work-order.md

CHỈ ĐƯỢC SỬA/THÊM 4 file:
  1) [MỚI] english_for_community_backend/src/jobs/examSessionExpireJob.js       (§5.1)
  2) english_for_community_backend/src/services/examSessionService.js           (§5.2 — thêm method bulkAutoEndDueLiveSessions vào object examSessionService)
  3) english_for_community_backend/server.js                                    (§5.3 — import + initExamSessionExpireJob())
  4) english_for_community_backend/src/services/examAttemptService.js           (§5.4 — chỉ thêm `sessionId: null` vào filter bulkExpirePastDeadline)
Ngoài 4 file/điểm trên → DỪNG & hỏi.

LÀM: copy đúng code mẫu §5.1–§5.4. Không tự đổi tên method, không đổi lịch cron (1 phút), không refactor thêm.

TUYỆT ĐỐI KHÔNG:
  - Đụng endSession / maybeAutoEndLiveSessionIfDue / computeSessionScheduledEnd / buildRealtimePayload / startSession.
  - Đụng examAttemptExpireJob.js, model/schema, migration, hay bất kỳ file client Flutter nào.
  - Thêm auto-close cho live session không có timeLimitSeconds/hardEndAt.
  - Đổi public signature service hiện có, hardcode secret.

VERIFY trước khi báo xong:
  - node --check cả 4 file (§8) → 0 lỗi; server khởi động in log không crash.
  - npm test → PASS; ĐẶC BIỆT src/tests/examRealtime.e2e.test.js. Nếu test đỏ vì Change B → DỪNG & báo, đừng tự sửa test.
  - Smoke §7 case 1 + 3 + 4 (auto đóng+nộp realtime; async vẫn expired; open-ended không đóng).
Dán kết quả verify + tóm tắt DIFF (file · rủi ro · checklist tự chấm) vào tracker (§10). Rồi báo: "implementer đã xong, audit đi".
KHÔNG tự kết luận APPROVED.
```

---

## 10. Tracker

| Mốc | Trạng thái | Ghi chú / bằng chứng |
|---|---|---|
| Work-order (Opus) | ✅ Done | File này |
| IMPLEMENT (Cursor) | ✅ Done | 4 file đúng scope: `examSessionExpireJob.js` (mới), `examSessionService.js` (+method), `server.js` (+wire), `examAttemptService.js` (+`sessionId:null`) |
| Verify `node --check` + server boot | ✅ Pass | `node --check` OK cả 4 file |
| `npm test` (esp. examRealtime.e2e) | ✅ Pass | `node --test src/tests/examRealtime.e2e.test.js` → 10/10 pass |
| Smoke E2E (user) | ⏳ | **Cần user chạy** §7 case 1 (cần MongoDB + seed realtime timeLimit ngắn) — gate nghiệm thu cuối |
| Opus AUDIT | ✅ **APPROVED** | Xem note bên dưới |

### Opus AUDIT note (Phase 4) — verdict: **APPROVED**
Đọc DIFF thật cả 4 điểm, đối chiếu §11:
- ✅ Đúng 4 file scope, không scope-creep (`endSession`/`startSession`/`computeSessionScheduledEnd`/client **không** bị đụng).
- ✅ `bulkAutoEndDueLiveSessions`: query `status:'live'` (dùng index), populate `config mode`, tính `computeSessionScheduledEnd`, chỉ `endSession` khi `end && end <= now`, gọi qua `examSessionService.endSession` (tái dùng flow đã kiểm chứng), có `try/catch`, trả count. `session.startedAt` + `assignment.config` đều có sẵn cho hàm compute.
- ✅ Job đúng pattern `node-cron` `* * * * *`; wire đủ trong `server.js`.
- ✅ `bulkExpirePastDeadline` chỉ thêm `sessionId: null` → realtime attempt do session lifecycle sở hữu; async (sessionId null) **không** đổi hành vi. Đã verify: chỉ realtime set `sessionId`.
- ✅ Open-ended live (không timeLimit/hardEndAt) → `computeSessionScheduledEnd` null → **không** đóng (đúng thiết kế).
- ✅ Idempotent: `endSession` early-return `closed/canceled`; `emitSessionStateBroadcast` sau khi đóng gọi lại `maybeAutoEndLiveSessionIfDue` nhưng status đã `closed` → không loop.
- ✅ Syntax sạch (`node --check`), unit test realtime pass 10/10.
- ⚠️ **Còn 1 gate cuối cần user:** smoke E2E §7 case 1 (đóng cả 2 app, chờ qua giờ → session `closed` + attempt `submitted` có `submittedAt`/`scores`) — cần chạy trên stack có DB/seed, không verify được bằng static.

---

## 11. Checklist OPUS AUDIT (Phase 4) + HANDOFF Cursor AUDIT

### Checklist audit (đọc DIFF thật, đối chiếu plan)
- [ ] Đúng 4 file scope; không scope-creep (đặc biệt không đụng `endSession`/`startSession`/client).
- [ ] `bulkAutoEndDueLiveSessions`: query `status:'live'`, tính `computeSessionScheduledEnd`, chỉ `endSession` khi `end && end <= now`; gọi qua `examSessionService.endSession` (tái dùng flow), có `try/catch`, trả count.
- [ ] Job `examSessionExpireJob.js` đúng pattern (`node-cron`, `* * * * *`), wire đủ trong `server.js`.
- [ ] `bulkExpirePastDeadline` chỉ thêm `sessionId: null` — không đổi gì khác.
- [ ] Không auto-close live session open-ended (không timeLimit/hardEndAt).
- [ ] `node --check` 0 lỗi; `npm test` PASS (đọc kỹ examRealtime.e2e).
- [ ] Smoke: realtime hết giờ → session `closed` + attempt `submitted` (có submittedAt/scores), socket `exam_session_ended` phát; async vẫn expired; idempotent với End session thủ công.
- **Verdict:** APPROVED | CHANGES REQUESTED → ghi tracker, finding = file:line + fix cụ thể.

### HANDOFF — Cursor AUDIT (copy-paste, "nhờ cursor audit luôn")
```text
Bạn là AUDITOR (model khác implementer). KHÔNG sửa code — chỉ đọc DIFF + verify, ra verdict.
Plan: docs/plantasks/BUG/20260702-live-session-auto-end/work-order.md (§11 checklist).

Kiểm:
  1. Đúng 4 file scope; endSession/startSession/computeSessionScheduledEnd/buildRealtimePayload/client KHÔNG bị đụng.
  2. bulkAutoEndDueLiveSessions gọi endSession đúng điều kiện quá hạn (end <= now), try/catch, trả count; không nhân đôi logic đóng phòng.
  3. Job wire đủ trong server.js; cron 1 phút.
  4. bulkExpirePastDeadline chỉ thêm sessionId:null; async attempt (sessionId null) vẫn expire.
  5. Smoke: realtime timeLimit ngắn, đóng cả 2 app, chờ qua giờ → session closed + attempt submitted(submittedAt+scores) + log [examSessionExpire]; open-ended KHÔNG đóng; End session thủ công rồi cron chạy vẫn idempotent.
  6. node --check 0 lỗi; npm test PASS (examRealtime.e2e).

Mỗi finding: file:line + mô tả + fix đề xuất. Verdict: APPROVED | CHANGES REQUESTED. Ghi vào tracker §10.
```
