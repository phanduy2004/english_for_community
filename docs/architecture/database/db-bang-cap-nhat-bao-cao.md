# Cập nhật bảng CSDL cho báo cáo (mục 3.3)

> **Nguồn chân lý:** 32 Mongoose model trong thư mục english_for_community_backend/src/models/ (đọc trực tiếp 06/2026).
> **Đối chiếu với:** mục *3.3.1 Chi tiết bảng dữ liệu* của báo cáo (Bảng 35–52).
> Giữ nguyên các cột của báo cáo: STT, Thuộc tính, Kiểu dữ liệu, Ý nghĩa, Ghi chú.
> Quy ước kiểu dữ liệu: Char(24) là ObjectId (mã định danh); Object là dữ liệu con nhúng bên trong; Array là mảng (danh sách nhiều giá trị).

---

## 0. Bảng tổng hợp — bảng nào SAI / ĐÚNG / THIẾU

| Bảng trong báo cáo | Tình trạng | Việc cần làm |
|--------------------|-----------|--------------|
| Bảng 35 — **User** | ⚠️ Sai | role thiếu `teacher`; `reminder_hour/minute`→object; `dailyActivityGoal`→**`dailyLessonGoal`**; thiếu `fcmTokens` |
| Bảng 37 — **Listening** | ⚠️ Sai | `playbackPad_*`→object; thiếu `_destroy`, `deletedAt` |
| Bảng 38 — **Cue** | ⚠️ Sai | thiếu `meaning` |
| Bảng 41 — **Reading** | ⚠️ Sai | thiếu `_destroy`, `deletedAt` |
| Bảng 50 — **Writing Topics** | ❌ Sai nặng | có 4 field **không tồn tại** (`slug,icon,color,order`); thiếu `approvalStatus`, `approval` |
| Bảng 51 — **Writing Submissions** | ❌ Thiếu thân | bảng hiện chỉ là sub-object **Feedback**; thiếu toàn bộ field chính của submission |
| Bảng 36 — Word | ✅ Đúng (lưu ý nhỏ) | field tên là `user` (không phải `user_id`) |
| Bảng 39 — Dictation Attempt | ✅ Đúng | — |
| Bảng 40 — Enrollment | ✅ Đúng | — |
| Bảng 42 — Questions, 43 — Reading Attempt, 44 — Answer, 45 — Reading Progress | ✅ Đúng | — |
| Bảng 46 — Speaking Set, 47 — Sentence, 48 — Speaking Attempts, 49 — Speaking Enrollment | ✅ Đúng | `speakingSetId` = Char(24) FK **khớp migration 004** (String→ObjectId) |
| Bảng 52 — User Daily Progress | ✅ Đúng | — |
| CueComment | ✅ Đúng | — |
| **17 collection còn lại** | ❌ Thiếu hẳn | Xem **Phần 2** (miền Lớp học / Đề thi / Hệ thống) |

> **Tóm tắt:** Báo cáo chỉ mô tả **15/32 collection**. Trong 15 đó: **5 bảng sai** (User, Listening, Cue, Reading, Writing Topics) + **1 bảng thiếu thân** (Writing Submissions). Phần Speaking **đã đúng** sau migration — không cần sửa.

---

# PHẦN 1 — SỬA CÁC BẢNG ĐANG SAI

## 1.1 Bảng User (Bảng 35) — sửa 4 chỗ

**(a) Sửa Ghi chú dòng role:**

| Thuộc tính | Ghi chú MỚI |
|-----------|-------------|
| role | Enum: `'user'`, `'admin'`, `'teacher'` — mặc định `'user'` |

**(b) GỘP 2 dòng reminder_hour + reminder_minute → 1 dòng:**

| Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----------|--------------|---------|---------|
| reminder | Object | Giờ nhắc học tập | `{ hour: 0–23, minute: 0–59 }`, mặc định `null` |

**(c) ĐỔI TÊN dòng dailyActivityGoal → dailyLessonGoal:**

| Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----------|--------------|---------|---------|
| dailyLessonGoal | Int | Mục tiêu số bài học/ngày | Mặc định 5, min 1, max 100 |

**(d) THÊM dòng mới (sau refreshToken):**

| Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----------|--------------|---------|---------|
| fcmTokens | Array<String> | Danh sách token thiết bị (Firebase Cloud Messaging) | 1 user dùng nhiều máy → đẩy thông báo |

## 1.2 Bảng Listening (Bảng 37) — sửa

**(a) GỘP playbackPad_before + playbackPad_after → 1 dòng:**

| Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----------|--------------|---------|---------|
| playbackPad | Object | Thời gian đệm phát audio (ms) | `{ before: 200, after: 200 }` |

**(b) THÊM 2 dòng (xóa mềm):**

| Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----------|--------------|---------|---------|
| _destroy | Boolean | Cờ xóa mềm | Mặc định false, có Index |
| deletedAt | Datetime | Thời điểm xóa mềm | Mặc định null |

## 1.3 Bảng Cue (Bảng 38) — thêm

| Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----------|--------------|---------|---------|
| meaning | Text | Nghĩa / bản dịch của câu | Mặc định `''` (hiển thị hỗ trợ học) |

## 1.4 Bảng Reading (Bảng 41) — thêm

| Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----------|--------------|---------|---------|
| _destroy | Boolean | Cờ xóa mềm | Mặc định false, có Index |
| deletedAt | Datetime | Thời điểm xóa mềm | Mặc định null |

## 1.5 Bảng Writing Topics (Bảng 50) — VIẾT LẠI

> Bỏ hẳn 4 dòng không có thật trong model: slug, icon, color, order.
> Thêm nhóm trường phục vụ duyệt nội dung (gồm approvalStatus và approval). Tên collection thật là writing_topics.

| STT | Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----|-----------|--------------|---------|---------|
| 1 | _id | Char(24) | Mã định danh chủ đề | PK |
| 2 | name | Varchar(100) | Tên chủ đề | Not Null. VD "Technology", "Art" |
| 3 | isActive | Boolean | Trạng thái kích hoạt | Mặc định true |
| 4 | approvalStatus | Varchar(20) | Trạng thái duyệt | Enum: `draft, pending_review, approved, published, rejected`. Mặc định `published`. Index |
| 5 | approval.submittedBy | Char(24) | Người gửi duyệt | FK User, null |
| 6 | approval.submittedAt | Datetime | Thời điểm gửi duyệt | null |
| 7 | approval.reviewedBy | Char(24) | Người duyệt | FK User, null |
| 8 | approval.reviewedAt | Datetime | Thời điểm duyệt | null |
| 9 | approval.reviewNote | Text | Ghi chú khi duyệt | Mặc định '' |
| 10 | aiConfig.language | Varchar(10) | Ngôn ngữ tạo đề | Mặc định 'vi-VN' |
| 11 | aiConfig.taskTypes | Array<String> | Các dạng bài hỗ trợ | Enum: Opinion, Discussion, Advantages-Disadvantages, Problem-Solution… |
| 12 | aiConfig.defaultTaskType | Varchar(50) | Dạng bài mặc định | Mặc định 'Discussion' |
| 13 | aiConfig.level | Varchar(20) | Trình độ bài viết | Mặc định 'Intermediate' |
| 14 | aiConfig.targetWordCount | Varchar(20) | Số từ mục tiêu | Mặc định '250–320' |
| 15 | aiConfig.generationTemplate | Text | Prompt khung riêng cho topic | Optional (override prompt chung) |
| 16 | stats.submissionsCount | Int | Tổng số bài đã nộp | Mặc định 0 (denormalized) |
| 17 | stats.avgScore | Float | Điểm trung bình chủ đề | Min 0, Max 9, null |
| 18 | createdAt | Datetime | Ngày tạo | — |
| 19 | updatedAt | Datetime | Ngày cập nhật | — |

## 1.6 Bảng Writing Submissions (Bảng 51) — BỔ SUNG THÂN

> Bảng 51 trong báo cáo hiện tại thực ra chỉ là một đối tượng con tên feedback. Cần bổ sung bảng chính (bảng Writing Submission) ở dưới, rồi đổi tên nhãn của bảng cũ thành "Cấu trúc Feedback".

**Bảng chính — Writing Submission:**

| STT | Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----|-----------|--------------|---------|---------|
| 1 | _id | Char(24) | Mã định danh bài nộp | PK |
| 2 | userId | Char(24) | Mã người dùng | FK User, Index, Not Null |
| 3 | topicId | Char(24) | Mã chủ đề | FK WritingTopic, Index, Not Null |
| 4 | generatedPrompt.title | Varchar(255) | Tiêu đề đề (AI sinh) | snapshot lưu vết |
| 5 | generatedPrompt.text | Text | Đề bài đầy đủ | — |
| 6 | generatedPrompt.taskType | Varchar(50) | Dạng đề | — |
| 7 | generatedPrompt.level | Varchar(20) | Trình độ | — |
| 8 | content | Text | Bài làm của người dùng | Mặc định '' |
| 9 | wordCount | Int | Số từ | — |
| 10 | durationInSeconds | Int | Thời gian làm bài (giây) | Mặc định 0 |
| 11 | status | Varchar(20) | Trạng thái | Enum: `draft, submitted, reviewed`. Mặc định 'draft' |
| 12 | startedAt | Datetime | Thời điểm bắt đầu | Mặc định now |
| 13 | submittedAt | Datetime | Thời điểm nộp | — |
| 14 | feedback | Object | Kết quả chấm của AI | Chi tiết tại bảng *Cấu trúc Feedback* |
| 15 | score | Float | Điểm tổng | = `feedback.overall` (để query nhanh) |
| 16 | reviewedAt | Datetime | Thời điểm chấm xong | — |
| 17 | createdAt | Datetime | Ngày tạo | — |
| 18 | updatedAt | Datetime | Ngày cập nhật | — |

> Cấu trúc Feedback: giữ nguyên bảng cũ trong báo cáo, gồm các trường overall, tr, cc, lr, gra, các trường nhóm Bullets, paragraphs, taskType, keyTips, outline, vocab, grammarRows, coherenceRows, sampleMid, sampleHigh, modelInfo, evaluatedAt.

---

# PHẦN 2 — 17 COLLECTION CÒN THIẾU TRONG BÁO CÁO

> Đây là miền **Lớp học – Đề thi – Hệ thống** (tương ứng nhóm use case Teacher/Admin/System đã bổ sung). Thêm vào mục 3.3 để báo cáo phản ánh đủ **32/32 collection**.

## Nhóm A — Hệ thống & Tương tác

### Notification

| STT | Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----|-----------|--------------|---------|---------|
| 1 | _id | Char(24) | Mã thông báo | PK |
| 2 | recipientId | Char(24) | Người nhận | FK User, Not Null |
| 3 | senderId | Char(24) | Người tạo thông báo | FK User; null nếu là SYSTEM |
| 4 | type | Varchar(40) | Loại thông báo | Enum 16 giá trị: COMMENT_REPLY, COMMENT_REACTION, DAILY_REMINDER, SYSTEM_ANNOUNCEMENT, CLASSROOM_JOIN_REQUEST/APPROVED/REJECTED, EXAM_ASSIGNED, EXAM_ASSIGNMENT_UPDATED/CLOSED, EXAM_SESSION_LIVE, EXAM_SUBMISSION_RECEIVED, EXAM_RESULTS_RELEASED, CO_TEACHER_INVITE/_ACCEPTED/_DECLINED, CO_TEACHER_REMOVED |
| 5 | title | Varchar(255) | Tiêu đề | Not Null |
| 6 | message | Text | Nội dung | Not Null |
| 7 | data | Object | Payload deep-link | VD classroomId, assignmentId… |
| 8 | isRead | Boolean | Đã đọc chưa | Mặc định false |
| 9 | createdAt | Datetime | Thời gian tạo | **TTL 365 ngày** (tự xóa) |

### Report

| STT | Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----|-----------|--------------|---------|---------|
| 1 | _id | Char(24) | Mã báo cáo | PK |
| 2 | user | Char(24) | Người gửi | FK User, Not Null |
| 3 | type | Varchar(20) | Loại báo cáo | Enum: `bug, feature, improvement, other` |
| 4 | title | Varchar(255) | Tiêu đề | Not Null |
| 5 | description | Text | Mô tả chi tiết | Not Null |
| 6 | images | Array<String> | Ảnh đính kèm | URL ảnh chụp lỗi |
| 7 | deviceInfo | Object | Thông tin thiết bị | `{ platform, version, device }` |
| 8 | status | Varchar(20) | Trạng thái xử lý | Enum: `pending, reviewed, resolved, rejected`. Mặc định 'pending' |
| 9 | adminResponse | Text | Phản hồi của admin | — |
| 10 | createdAt | Datetime | Thời gian gửi | Mặc định now |

## Nhóm B — Lớp học

### Classroom

| STT | Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----|-----------|--------------|---------|---------|
| 1 | _id | Char(24) | Mã lớp | PK |
| 2 | teacherId | Char(24) | Giáo viên chủ lớp | FK User, Index, Not Null |
| 3 | name | Varchar(255) | Tên lớp | Not Null |
| 4 | description | Text | Mô tả | Mặc định '' |
| 5 | coverImageUrl | Text | Ảnh bìa | Mặc định '' |
| 6 | inviteCode | Varchar(20) | Mã mời | Unique, Index, Not Null |
| 7 | inviteToken | Varchar(64) | Token link mời | Unique, Index, Not Null |
| 8 | joinPolicy | Varchar(20) | Chính sách vào lớp | Enum: `open, approval_required`. Mặc định 'open' |
| 9 | pinnedMessageId | Char(24) | Tin nhắn ghim | FK ClassroomMessage, null |
| 10 | archived | Boolean | Đã lưu trữ | Mặc định false, Index |
| 11 | settings | Object | Cấu hình lớp | `{ allowStudentInvite: false }` |
| 12 | integrations | Object | Tích hợp ngoài | `{ googleClassroom, lti }` |
| 13 | deletedAt | Datetime | Xóa mềm | Mặc định null |
| 14 | createdAt / updatedAt | Datetime | Ngày tạo / cập nhật | — |

### ClassroomMember

| STT | Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----|-----------|--------------|---------|---------|
| 1 | _id | Char(24) | Mã bản ghi | PK |
| 2 | classroomId | Char(24) | Mã lớp | FK Classroom, Index, Not Null |
| 3 | userId | Char(24) | Thành viên | FK User, Index, Not Null |
| 4 | roleInClass | Varchar(20) | Vai trò trong lớp | Enum: `student, co_teacher`. Mặc định 'student' |
| 5 | status | Varchar(20) | Trạng thái | Enum: `active, pending, removed`. Mặc định 'active', Index |
| 6 | joinedAt | Datetime | Thời điểm vào | Mặc định now |
| 7 | leftAt | Datetime | Thời điểm rời | null |
| 8 | createdAt / updatedAt | Datetime | Ngày tạo / cập nhật | Unique `{classroomId, userId}` |

### ClassroomMessage

| STT | Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----|-----------|--------------|---------|---------|
| 1 | _id | Char(24) | Mã tin nhắn | PK |
| 2 | classroomId | Char(24) | Mã lớp | FK Classroom, Index, Not Null |
| 3 | senderId | Char(24) | Người gửi | FK User, Not Null |
| 4 | type | Varchar(10) | Loại tin | Enum: `text, image, video, file`. Mặc định 'text' |
| 5 | content | Text | Nội dung văn bản | Có markup @mention |
| 6 | media | Object | Tệp đính kèm | `{ url, name, size, mimeType, thumbnailUrl, width, height, durationSeconds }`, null |
| 7 | replyTo | Object | Snapshot tin được trả lời | `{ messageId, senderId, senderName, contentPreview, messageType }`, null |
| 8 | mentions | Array<Char(24)> | Người được nhắc | FK User |
| 9 | reactions | Array<Object> | Cảm xúc | `{ emoji, userIds[] }` |
| 10 | deletedAt | Datetime | Xóa mềm | null (giữ cho reply preview) |
| 11 | editedAt | Datetime | Đã chỉnh sửa | null |
| 12 | clientId | Varchar(50) | Khóa chống trùng gửi lại | Index, sparse |
| 13 | createdAt / updatedAt | Datetime | Ngày tạo / cập nhật | — |

### ClassroomActivityLog

| STT | Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----|-----------|--------------|---------|---------|
| 1 | _id | Char(24) | Mã log | PK |
| 2 | classroomId | Char(24) | Mã lớp | FK Classroom, Index, Not Null |
| 3 | actorId | Char(24) | Người thực hiện | FK User, null (hệ thống) |
| 4 | type | Varchar(30) | Loại hoạt động | Enum: member_joined/pending/approved/removed, co_teacher_added/removed, assignment_created/closed, attempt_submitted, results_released, integrity_flag |
| 5 | message | Text | Mô tả | Mặc định '' |
| 6 | meta | Object | Dữ liệu kèm | Mixed |
| 7 | createdAt / updatedAt | Datetime | Ngày tạo / cập nhật | **TTL 365 ngày** |

### ClassroomChatReadState

| STT | Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----|-----------|--------------|---------|---------|
| 1 | _id | Char(24) | Mã bản ghi | PK |
| 2 | classroomId | Char(24) | Mã lớp | FK Classroom, Index, Not Null |
| 3 | userId | Char(24) | Người dùng | FK User, Index, Not Null |
| 4 | lastReadAt | Datetime | Thời điểm đọc cuối | null (tính unread) |
| 5 | createdAt / updatedAt | Datetime | Ngày tạo / cập nhật | Unique `{classroomId, userId}` |

## Nhóm C — Đề thi & Chấm điểm

### Exam

| STT | Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----|-----------|--------------|---------|---------|
| 1 | _id | Char(24) | Mã đề | PK |
| 2 | teacherId | Char(24) | Giáo viên tạo | FK User, Index, Not Null |
| 3 | title | Varchar(255) | Tiêu đề đề | Not Null |
| 4 | description | Text | Mô tả | Mặc định '' |
| 5 | status | Varchar(20) | Trạng thái | Enum: `draft, published, archived`. Mặc định 'draft', Index |
| 6 | contentVersion | Int | Phiên bản nội dung | Mặc định 1 |
| 7 | sections | Array<Object> | Các phần/câu hỏi của đề | Mixed (linh hoạt theo kỹ năng) |
| 8 | settings | Object | Cấu hình đề | Mixed |
| 9 | deletedAt | Datetime | Xóa mềm | null |
| 10 | createdAt / updatedAt | Datetime | Ngày tạo / cập nhật | — |

### ExamAssignment

| STT | Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----|-----------|--------------|---------|---------|
| 1 | _id | Char(24) | Mã giao bài | PK |
| 2 | examId | Char(24) | Đề được giao | FK Exam, Index, Not Null |
| 3 | teacherId | Char(24) | Giáo viên giao | FK User, Index, Not Null |
| 4 | audience | Varchar(20) | Đối tượng | Enum: `classroom, public_link` |
| 5 | classroomId | Char(24) | Lớp nhận (nếu có) | FK Classroom, null, Index |
| 6 | mode | Varchar(20) | Hình thức làm | Enum: `self_paced, scheduled, realtime, practice` |
| 7 | config | Object | Cấu hình làm bài | Mixed (thời hạn, số lần…) |
| 8 | publicJoin | Object | Cấu hình link công khai | `{ token, maxUses, expiresAt, usesCount }`, null |
| 9 | status | Varchar(20) | Trạng thái | Enum: `active, closed`. Mặc định 'active' |
| 10 | examSnapshot | Object | Bản đông cứng của đề | Lưu 1 lần/assignment (chống sửa đề giữa chừng) |
| 11 | examSnapshotFrozenAt | Datetime | Thời điểm đông cứng | — |
| 12 | deletedAt | Datetime | Xóa mềm | null |
| 13 | createdAt / updatedAt | Datetime | Ngày tạo / cập nhật | Index `{classroomId, audience, status}` |

### ExamSession

| STT | Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----|-----------|--------------|---------|---------|
| 1 | _id | Char(24) | Mã phiên thi | PK |
| 2 | assignmentId | Char(24) | Bài thi được giao | FK ExamAssignment, Index, Not Null |
| 3 | leaderTeacherId | Char(24) | Giáo viên điều hành | FK User, Not Null |
| 4 | status | Varchar(20) | Trạng thái phiên | Enum: `lobby, live, grading, closed, canceled`. Mặc định 'lobby', Index |
| 5 | roomCode | Varchar(20) | Mã phòng thi | — |
| 6 | joinedUserIds | Array<Char(24)> | Học sinh đã vào | FK User |
| 7 | readyUserIds | Array<Char(24)> | Học sinh đã sẵn sàng | FK User (realtime lobby) |
| 8 | startedAt | Datetime | Bắt đầu | null |
| 9 | endedAt | Datetime | Kết thúc | null |
| 10 | deletedAt | Datetime | Xóa mềm | null |
| 11 | createdAt / updatedAt | Datetime | Ngày tạo / cập nhật | — |

### ExamAttempt

| STT | Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----|-----------|--------------|---------|---------|
| 1 | _id | Char(24) | Mã lượt làm bài | PK |
| 2 | assignmentId | Char(24) | Bài thi được giao | FK ExamAssignment, Index, Not Null |
| 3 | sessionId | Char(24) | Phiên thi (nếu realtime) | FK ExamSession, null, Index |
| 4 | userId | Char(24) | Học sinh | FK User, Index, Not Null |
| 5 | status | Varchar(20) | Trạng thái | Enum: `in_progress, submitted, expired, void`. Mặc định 'in_progress' |
| 6 | startedAt | Datetime | Bắt đầu làm | Mặc định now |
| 7 | submittedAt | Datetime | Nộp bài | null |
| 8 | attemptDeadlineAt | Datetime | Hạn nộp | null (hệ thống tự thu khi quá hạn) |
| 9 | answers | Object | Bài làm của học sinh | Mixed |
| 10 | gradingState | Varchar(20) | Trạng thái chấm | Enum: `pending_auto, pending_ai, pending_manual, finalized`. Mặc định 'pending_auto' |
| 11 | scores | Object | Điểm chi tiết | `{ totalAwarded, totalMax, items, skillScores, examFormat, grammarScore, finalScore, finalMax, finalStatus }` |
| 12 | resultsReleased | Boolean | Đã công bố điểm | Mặc định false |
| 13 | integrity | Object | Giám sát gian lận | `{ tabSwitchCount, focusLossSeconds, copyPasteAttempts, fullscreenExited, lastEventAt, riskLevel: low/medium/high }` |
| 14 | _destroy | Boolean | Xóa mềm | Mặc định false |
| 15 | createdAt / updatedAt | Datetime | Ngày tạo / cập nhật | Nhiều compound index cho gradebook |

### TeacherAssignmentPreset

| STT | Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----|-----------|--------------|---------|---------|
| 1 | _id | Char(24) | Mã preset | PK |
| 2 | teacherId | Char(24) | Giáo viên sở hữu | FK User, Index, Not Null |
| 3 | name | Varchar(120) | Tên preset | Not Null |
| 4 | config.mode | Varchar(20) | Hình thức | Enum: `self_paced, scheduled, realtime`. Mặc định 'self_paced' |
| 5 | config.attemptPolicy | Varchar(20) | Chính sách số lần làm | Enum: `single, unlimited, limited`. Mặc định 'single' |
| 6 | config.maxAttempts | Int | Số lần tối đa | min 2, max 99 |
| 7 | config.showResultsPolicy | Varchar(20) | Chính sách xem kết quả | Enum: `after_submit, after_release, never`. Mặc định 'after_release' |
| 8 | config.allowPartialSubmit | Boolean | Cho nộp một phần | Mặc định true |
| 9 | config.timeLimitSeconds | Int | Giới hạn thời gian (giây) | null = không giới hạn |
| 10 | createdAt / updatedAt | Datetime | Ngày tạo / cập nhật | — |

## Nhóm D — Nghe hiểu (Comprehension)

### ListeningComprehension

| STT | Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----|-----------|--------------|---------|---------|
| 1 | _id | Char(24) | Mã bài nghe hiểu | PK |
| 2 | title | Varchar(255) | Tiêu đề | Not Null |
| 3 | summary | Text | Tóm tắt | — |
| 4 | audioUrl | Text | File âm thanh | Not Null |
| 5 | transcript | Text | Lời thoại | Not Null |
| 6 | difficulty | Varchar(10) | Độ khó | Enum: `easy, medium, hard`. Mặc định 'easy' |
| 7 | imageUrl | Text | Ảnh minh họa | — |
| 8 | minutesToComplete | Int | Thời gian ước tính (phút) | Mặc định 5 |
| 9 | questions | Array<Object> | Câu hỏi trắc nghiệm | `{ _id, questionText, options[], correctAnswerIndex, feedback{ reasoning, hintTimestampSeconds, keySentence } }` |
| 10 | _destroy | Boolean | Xóa mềm | Mặc định false, Index |
| 11 | deletedAt | Datetime | Thời điểm xóa | null |
| 12 | createdAt / updatedAt | Datetime | Ngày tạo / cập nhật | — |

### ListeningCompAttempt

| STT | Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----|-----------|--------------|---------|---------|
| 1 | _id | Char(24) | Mã lượt làm bài | PK |
| 2 | userId | Char(24) | Người dùng | FK User, Not Null |
| 3 | listeningId | Char(24) | Bài nghe hiểu | FK ListeningComprehension, Not Null |
| 4 | answers | Array<Object> | Câu trả lời | `{ questionId, chosenIndex (−1 nếu bỏ), isCorrect }` |
| 5 | score | Int | Điểm số (%) | 0–100, mặc định 0 |
| 6 | correctCount | Int | Số câu đúng | Mặc định 0 |
| 7 | totalQuestions | Int | Tổng số câu | Mặc định 0 |
| 8 | durationInSeconds | Int | Thời gian làm (giây) | Mặc định 0 |
| 9 | createdAt / updatedAt | Datetime | Ngày tạo / cập nhật | Index `{userId, listeningId, score desc}` |

## Nhóm E — Nội dung & Vận hành

### WritingTopicVersion

| STT | Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----|-----------|--------------|---------|---------|
| 1 | _id | Char(24) | Mã phiên bản | PK |
| 2 | topicId | Char(24) | Chủ đề gốc | FK WritingTopic, Index, Not Null |
| 3 | snapshot | Object | Bản chụp toàn bộ topic | Mixed (để rollback) |
| 4 | changedBy | Char(24) | Người thay đổi | FK User, Not Null |
| 5 | changeReason | Text | Lý do thay đổi | Mặc định '' |
| 6 | createdAt / updatedAt | Datetime | Ngày tạo / cập nhật | collection `writing_topic_versions` |

### AdminAuditLog

| STT | Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----|-----------|--------------|---------|---------|
| 1 | _id | Char(24) | Mã log | PK |
| 2 | actorId | Char(24) | Người thực hiện | FK User, Index, Not Null |
| 3 | actorRole | Varchar(20) | Vai trò người thực hiện | Not Null |
| 4 | action | Varchar(50) | Hành động | Index, Not Null |
| 5 | targetType | Varchar(50) | Loại đối tượng | Index, Not Null |
| 6 | targetId | Varchar(50) | ID đối tượng | Index, Not Null |
| 7 | metadata | Object | Dữ liệu kèm | Mixed |
| 8 | ip | Varchar(45) | Địa chỉ IP | Mặc định '' |
| 9 | userAgent | Text | Trình duyệt/thiết bị | Mặc định '' |
| 10 | createdAt / updatedAt | Datetime | Ngày tạo / cập nhật | **TTL 365 ngày**, collection `admin_audit_logs` |

### AppRelease

| STT | Thuộc tính | Kiểu dữ liệu | Ý nghĩa | Ghi chú |
|-----|-----------|--------------|---------|---------|
| 1 | _id | Char(24) | Mã bản phát hành | PK |
| 2 | platform | Varchar(10) | Nền tảng | Enum: `android, ios`. Index |
| 3 | environment | Varchar(15) | Môi trường | Enum: `production, staging`. Mặc định 'production', Index |
| 4 | versionName | Varchar(20) | Tên phiên bản | VD '1.2.0'. Not Null |
| 5 | versionCode | Int | Mã phiên bản | min 1, Index, Not Null |
| 6 | minSupportedVersionCode | Int | Bản tối thiểu hỗ trợ | min 1, Not Null |
| 7 | forceUpdate | Boolean | Bắt buộc cập nhật | Mặc định false |
| 8 | updateType | Varchar(10) | Kiểu cập nhật | Enum: `soft, force`. Mặc định 'soft' |
| 9 | status | Varchar(20) | Trạng thái phát hành | Enum: `pending_approval, approved, scheduled, published, rejected, archived`. Mặc định 'pending_approval', Index |
| 10 | buildSource / gitSha / gitBranch / ciRunId | Varchar | Thông tin build CI/CD | — |
| 11 | artifactUrlApk / artifactUrlAab | Text | Link file build | null |
| 12 | qaNotes / releaseNotes / changelog | Text | Ghi chú QA / phát hành | — |
| 13 | storeUrl / downloadUrl | Text | Link tải | null |
| 14 | approvedBy / approvedAt | Char(24) / Datetime | Người & thời điểm duyệt | FK User, null |
| 15 | rejectedBy / rejectedAt / rejectReason | Char(24) / Datetime / Text | Người & lý do từ chối | null |
| 16 | scheduledPublishAt | Datetime | Lịch phát hành | null |
| 17 | publishedBy / publishedAt | Char(24) / Datetime | Người & thời điểm publish | FK User; publishedAt có Index |
| 18 | isActive | Boolean | Bản đang hiệu lực | Mặc định false, Index |
| 19 | createdBy | Char(24) | Người tạo | FK User, null |
| 20 | createdAt / updatedAt | Datetime | Ngày tạo / cập nhật | Unique `{platform, environment, versionCode}` |

---

## Ghi chú chung khi đưa vào Word

1. Báo cáo dùng kiểu dữ liệu theo phong cách SQL (Char, Varchar, Int…) cho dễ đọc — đã giữ nguyên quy ước đó. Thực tế MongoDB không ràng buộc độ dài; kiểu Char(24) chỉ mang tính tượng trưng cho ObjectId.
2. Các trường nhúng (dạng đối tượng) như reminder, playbackPad, approval, aiConfig, score… có thể trình bày phẳng theo tiền tố — ví dụ reminder.hour — giống cách báo cáo đang làm với score.wer hay aiConfig_… — miễn là trình bày nhất quán.
3. Hầu hết các collection (trừ một vài bảng log/thông báo) đều có trường createdAt và updatedAt, do Mongoose tự động quản lý qua tính năng timestamps.
4. Sơ đồ ERD tương ứng: [database/database-diagrams-uml.md](./database-diagrams-uml.md) và [plantuml/database-full.puml](../plantuml/database-full.puml).
