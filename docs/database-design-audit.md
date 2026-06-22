# Đánh giá & chuẩn thiết kế Database (MongoDB + Mongoose)

> **Phạm vi:** 35 schema trong `english_for_community_backend/src/models/**`.
> **Mục đích:** chấm điểm thiết kế hiện trạng, chỉ ra cái chưa tốt **kèm `file:dòng`**, và đề xuất cách làm theo **chuẩn thiết kế DB** (indexing, embed vs reference, schema discipline, integrity, lifecycle). Dùng cho Cursor/dev sửa.
> **Nguồn:** đọc trực tiếp models 06/2026. Stack: Express 4 + Mongoose 8 + MongoDB.

---

## 1. Điểm số tổng quan

| Trục | Điểm | Nhận định |
|------|:----:|-----------|
| **Mô hình hoá & quan hệ** | 7/10 | Dùng `ObjectId + ref` nhất quán, sub-schema tốt ở `Classroom`/`ExamAssignment`. Trừ: **lạm dụng `Mixed`** ở miền đề thi. |
| **Indexing** | 7/10 | Compound index đề thi đã thêm (doc 21), unique constraint hợp lý. Trừ: vài collection **thiếu index cho query pattern** (chat sender, comment, enrollment, notification unread). |
| **Chuẩn hoá & nhất quán** | 5.5/10 | `User` lệch chuẩn (timestamps thủ công), `SpeakingAttempt.speakingSetId` String, `Word.user`, daily-progress trùng nguồn. |
| **Toàn vẹn & vòng đời** | 5/10 | **Không có chiến lược cascade/soft-delete đồng nhất**, **không TTL** cho log/notification, **examSnapshot nhân bản** mỗi attempt. |
| **Validation** | 6.5/10 | Enum phủ phần lớn status; trừ vài free-text (gender, audit action) + thiếu min/max điểm. |
| **Tổng** | **6.3/10** | Nền tảng ổn cho Mongoose, nhưng có **vài quyết định cấu trúc cần sửa sớm** (Mixed miền đề, snapshot nhân bản, integrity). |

> **Một dòng:** Schema "chạy được và đã tối ưu index gần đây", nhưng đang gánh **nợ cấu trúc ở miền đề thi (Mixed + snapshot nhân bản)** và **thiếu kỷ luật vòng đời dữ liệu (cascade/TTL/soft-delete)**.

---

## 2. Điểm mạnh cần giữ

1. **Quan hệ bằng `ObjectId + ref` rõ ràng**, `required`/`index` ở khoá ngoại chính (Exam/Assignment/Attempt/Member).
2. **Compound index đề thi đã chuẩn** (`ExamAttempt.js:27-34`) — gradebook/grading hub query đúng index (kết quả doc 21).
3. **Unique constraint hợp lý:** `ClassroomMember {classroomId,userId}` (`:15`), `Classroom.inviteCode/inviteToken`, `UserDailyProgress {userId,date}`, `AppRelease {platform,environment,versionCode}`, `SpeakingEnrollment {userId,speakingSetId}`.
4. **Sub-schema có cấu trúc** ở `Classroom.settings/integrations` (`:19-51`) và `ExamAssignment.publicJoin` (`:15-26`) — đúng cách (thay vì Mixed).
5. **TTL index OTP** với `partialFilterExpression` (`User.js:80-90`) — kỹ thuật tốt.
6. **`ClassroomMember.js`** là model mẫu mực (enum + unique + index + soft-state qua `status/leftAt`).

---

## 3. Vấn đề theo chuẩn thiết kế (kèm `file:dòng`)

### 3.1 🔴 `examSnapshot` nhân bản mỗi attempt (storage + perf)
- `ExamAttempt.examSnapshot: Mixed required` (`ExamAttempt.js:8`) — **copy TOÀN BỘ đề** (sections + câu hỏi, ~50–100KB) vào **mỗi lượt làm**. Lớp 40 HS = 40+ bản sao y hệt. Cùng nhân bản ở `ExamSession.examSnapshot` (`ExamSession.js:7`).
- Hệ quả: phình collection; chính là nguồn của lỗi perf "populate kéo `exam.sections`" (doc 21 §B5); mỗi query attempt kéo blob lớn.
- **Lý do hợp lệ:** cần snapshot point-in-time (đề có thể đổi sau khi giao). Nhưng nên **snapshot 1 lần/assignment (hoặc /session)** rồi attempt **tham chiếu** `examSnapshotId`, không copy mỗi attempt.

### 3.2 🔴 Lạm dụng `Schema.Types.Mixed` ở dữ liệu lõi (mất schema/validation/queryability)
| Field | `file:dòng` | Ghi chú |
|-------|-------------|---------|
| `Exam.sections` (`[Mixed]`), `Exam.settings` | `Exam.js:10-11` | **Cấu trúc đề thi hoàn toàn schemaless** — không validate, không versioned |
| `ExamAttempt.answers/scores/meta/integrity` | `ExamAttempt.js:13-22` | Code đọc `scores.totalAwarded`… nhưng không có schema → hợp đồng ngầm, dễ vỡ |
| `ExamAssignment.config` | `ExamAssignment.js:14` | config schemaless |
| `Notification.data`, `AdminAuditLog.metadata`, `ClassroomActivityLog.meta` | tương ứng | payload/metadata không cấu trúc → khó query/audit |
> **Chuẩn:** ít nhất định nghĩa **sub-schema cho `scores`/`integrity`** (shape ổn định) và **typed schema cho `sections`** (hoặc tách câu hỏi ra collection). Giữ `Mixed` chỉ cho phần thật sự động, và **ghi rõ contract**.

### 3.3 🔴 Toàn vẹn tham chiếu, orphan & vòng đời
- **Không cascade:** xoá `Classroom` → `ClassroomMember/ClassroomMessage/ActivityLog/ChatReadState` mồ côi; xoá `User` → `Notification/Attempt/Comment/Message` mồ côi; xoá `Exam/Listening/...` → `Attempt/Enrollment` mồ côi. Không thấy middleware `pre/post delete` nào.
- **Không TTL** cho dữ liệu chỉ-tăng: `Notification`, `AdminAuditLog`, `ClassroomActivityLog` → phình vô hạn.
- **Soft-delete không đồng nhất:** `User._destroy` (`User.js:58`), `ClassroomMessage.deletedAt`, còn lại hard-delete → mỗi nơi một kiểu; query thường **không filter** cờ xoá.

### 3.4 🟡 Thiếu index cho query pattern thực tế
| Collection | Thiếu | Vì sao |
|-----------|-------|--------|
| `CueComment` | **không index nào** | query theo `listeningId+cueId`, reply theo `parentId` |
| `Enrollment` | **không index/unique** | cần unique `{userId,listeningId}` + list theo user |
| `ExamSession` | `{assignmentId,status}` | chỉ có index lẻ `assignmentId`,`status` |
| `Notification` | `{recipientId,isRead,createdAt}` | đếm/list "chưa đọc" |
| `ClassroomMessage` | `{senderId,createdAt}` | (đã có `{classroomId,createdAt:-1}` ✓) |
| `AdminAuditLog` | compound `{targetType,targetId,createdAt}`, `{actorId,createdAt}` | hiện chỉ index lẻ |
| `ReadingAttempt`/`SpeakingAttempt` | `{userId,<resource>,createdAt:-1}` | lấy "lượt mới nhất" |

### 3.5 🟡 Nhất quán & chuẩn hoá
- **`User` lệch chuẩn timestamps:** tự khai `createdAt/updatedAt` + `pre('save')` (`User.js:55-56,74-77`) trong khi **30 model khác** dùng `{timestamps:true}`. `updatedAt default null` sai lệch. → chuyển `User` sang `timestamps:true`.
- **`SpeakingAttempt.speakingSetId: String` + `ref`** → `populate` **không chạy** (ref cần ObjectId). Sửa thành `ObjectId`.
- **Đặt tên khoá ngoại lệch:** `Word.user` vs `userId` ở mọi nơi khác.
- **Daily progress trùng nguồn:** `User.dailyActivityProgress/dailyProgressDate` (`User.js:38-39`) **và** collection `UserDailyProgress` → 2 nguồn sự thật cho cùng dữ liệu.
- **`submittedAt` thừa** khi đã có `createdAt` (DictationAttempt/SpeakingAttempt) — chỉ giữ khi thật sự là mốc khác.
- **`toJSON{ id }` lặp ở mọi model** + `.lean()` **bỏ qua** transform này → đây chính là gốc bug grading-hub (doc 25). Nên dùng **plugin serializer chung** và quy ước: API trả `id` nhất quán dù `.lean()`.

### 3.6 🟡 Denormalize không có cơ chế đồng bộ
- `WritingTopics.stats {submissionsCount, avgScore}`, gamification trong `User {totalPoints, currentStreak, level}`, unread counters… là **tổng hợp denormalized** nhưng không có hook/transaction đảm bảo đồng bộ → nguy cơ lệch số. → cần hook tập trung hoặc job đối soát.

### 3.7 🟢 Validation & sub-schema nhỏ
- Free-text nên enum: `User.gender` (`:20`), `AdminAuditLog.action` (chuỗi tự do → 'update'/'Update' lẫn lộn).
- Thiếu `min/max` điểm: các attempt `score/wer/confidence` (có thể âm/ >max).
- Mảng có thể phình (cân nhắc, phụ thuộc quy mô thực): `ClassroomMessage.reactions[].userIds`, `Enrollment.completedCueIds`, `User.fcmTokens` (nên giới hạn ~10 + dọn token cũ).
- Sub-schema cue/question (`Listening`/`Reading`) khai `_id` rồi `{_id:false}` — mâu thuẫn, dọn lại.

---

## 4. Chuẩn / cách làm tốt hơn (đề xuất)

### 4.1 Bỏ nhân bản snapshot (P0)
- Tạo **`ExamSnapshot`** (hoặc nhúng 1 lần vào `ExamAssignment`/`ExamSession`): `{ assignmentId, contentVersion, sections, settings }`.
- `ExamAttempt` thay `examSnapshot` bằng `examSnapshotId: ObjectId ref`. Khi đọc bài → populate snapshot 1 lần. Giảm storage ~N lần + hết kéo blob/attempt.

### 4.2 Đưa cấu trúc cho dữ liệu lõi (P0–P1)
- Định nghĩa **sub-schema `scores`** (`{ totalAwarded, totalMax, skillScores: [{skill, score}] }`) và **`integrity`** (shape ổn định) thay `Mixed` — vẫn cho `answers` linh hoạt nhưng tài liệu hoá contract.
- `sections`: chuyển sang **typed sub-schema** hoặc tách `ExamQuestion`/`ExamSection` collection nếu cần query theo câu.
- `Notification.data`/`audit.metadata`/`activity.meta`: tối thiểu chuẩn hoá field hay dùng (`classroomId/assignmentId/...`) thành ObjectId có index nếu cần lọc.

### 4.3 Vòng đời dữ liệu (P0–P1)
- **Cascade**: thêm middleware `pre('deleteOne'/'findOneAndDelete')` cho `Classroom`/`User`/`Exam` để dọn con, **hoặc** chuẩn hoá **soft-delete** (`deletedAt` + filter mặc định qua query helper/plugin).
- **TTL** cho log/notification: `Notification` (vd 90 ngày), `AdminAuditLog` (giữ theo compliance), `ClassroomActivityLog` (vd 1 năm) bằng index `expireAfterSeconds` (cân nhắc nghiệp vụ).

### 4.4 Thêm index còn thiếu (P1)
```js
CueComment:        { listeningId:1, cueId:1, createdAt:-1 } · { parentId:1, createdAt:1 }
Enrollment:        { userId:1, listeningId:1 } (unique) · { userId:1, isCompleted:1, updatedAt:-1 }
ExamSession:       { assignmentId:1, status:1 }
Notification:      { recipientId:1, isRead:1, createdAt:-1 }
ClassroomMessage:  { senderId:1, createdAt:-1 }
AdminAuditLog:     { targetType:1, targetId:1, createdAt:-1 } · { actorId:1, createdAt:-1 }
ReadingAttempt:    { userId:1, readingId:1, createdAt:-1 }
```

### 4.5 Chuẩn hoá (P1–P2)
- `User` → `{timestamps:true}` (bỏ createdAt/updatedAt thủ công + pre-save).
- `SpeakingAttempt.speakingSetId` → `ObjectId`; `Word.user` → `userId` (kèm migration).
- Bỏ một trong hai nguồn daily-progress (giữ `UserDailyProgress`, bỏ field trong `User` hoặc coi là cache có hook).
- **Plugin chung**: `toJSON id` + soft-delete filter + base timestamps → áp cho mọi schema (giảm lặp, tránh lỗi `.lean()`/`_id`).
- Cân nhắc **gom pattern enrollment** (`Enrollment`/`SpeakingEnrollment`/`ReadingProgress`) về một mô hình `{ userId, contentType, contentId, progress, completedItemIds, ... }` (hoặc giữ riêng nhưng cùng base schema).

### 4.6 Validation (P2)
- Enum cho `gender`, `AdminAuditLog.action`; `min:0/max` cho điểm; `required` cho field then chốt của attempt.

---

## 5. Ưu tiên triển khai

| Ưu tiên | Hạng mục |
|:-------:|----------|
| **P0** | 4.1 bỏ nhân bản snapshot · 4.3 cascade/soft-delete chuẩn hoá · sub-schema `scores`/`integrity` (4.2) |
| **P1** | 4.4 index còn thiếu · TTL log/notification · `User` timestamps · `SpeakingAttempt` ObjectId · daily-progress 1 nguồn |
| **P2** | plugin chung (id/soft-delete) · gom enrollment · validation enum/min-max · dọn sub-schema `_id` |

---

## 6. Checklist nghiệm thu (khi sửa)

- [ ] `ExamAttempt` không còn copy full đề; dùng `examSnapshotId` (hoặc snapshot 1 lần/assignment). Migration cũ → mới chạy được.
- [ ] `scores`/`integrity` có sub-schema; code đọc đúng, test grading không vỡ.
- [ ] Cascade/soft-delete: xoá lớp/đề/user không để lại bản ghi con mồ côi (test).
- [ ] Index mới tạo; `explain()` các query nóng ra `IXSCAN`.
- [ ] TTL áp cho notification/audit/activity (đúng thời hạn nghiệp vụ).
- [ ] `User` dùng `timestamps:true`; `SpeakingAttempt.speakingSetId` populate được.
- [ ] Một nguồn duy nhất cho daily-progress.
- [ ] API vẫn trả `id` nhất quán (kể cả `.lean()`).

---

## 7. Bản đồ model ↔ vấn đề (tra nhanh)

| Model | Vấn đề | Mục |
|-------|--------|-----|
| `ExamAttempt.js` / `ExamSession.js` | examSnapshot nhân bản; answers/scores/meta/integrity = Mixed | 3.1, 3.2 |
| `Exam.js` / `ExamAssignment.js` | sections/settings/config = Mixed | 3.2 |
| `User.js` | timestamps thủ công; daily-progress trùng; gender free-text; fcmTokens không giới hạn | 3.5, 3.6, 3.7 |
| `CueComment.js` / `Enrollment.js` | thiếu index/unique | 3.4 |
| `Notification.js` / `AdminAuditLog.js` / `ClassroomActivityLog.js` | Mixed payload; thiếu index; thiếu TTL | 3.2, 3.3, 3.4 |
| `SpeakingAttempt.js` / `Word.js` | kiểu/đặt tên khoá ngoại lệch | 3.5 |
| `ClassroomMessage.js` | mảng reactions có thể phình; thiếu index sender | 3.4, 3.7 |
| `Listening.js` / `Reading.js` | sub-schema `_id` mâu thuẫn | 3.7 |
| (mọi model) | `toJSON id` lặp + `.lean()` bỏ qua → bug `_id` | 3.5 |

> Khi sửa, ghi commit + migration vào nhật ký; với MongoDB **đổi schema cần script migration** cho dữ liệu cũ (đặc biệt §4.1 snapshot và §4.5 đổi kiểu).
</content>
