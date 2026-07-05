# Bổ sung THIẾT KẾ CƠ SỞ DỮ LIỆU — các bảng mới (dán vào mục "Chi tiết bảng dữ liệu")

> Trích trực tiếp từ schema Mongoose thật (chính xác tên trường / kiểu / enum / khóa ngoại). Đánh số "Bảng N" tiếp theo Bảng 52 hiện có. Ghi chú chung:
> - `timestamps: true` → tự thêm `createdAt`, `updatedAt` (không liệt kê lại trong bảng). Các bảng có `createdAt` thủ công được ghi rõ.
> - `ObjectId → X` nghĩa là **khóa ngoại** tham chiếu collection X.
> - `_destroy` / `deletedAt` là cờ **xóa mềm (soft delete)**. `toJsonIdPlugin` ánh xạ `_id` → `id` khi trả JSON.
> - Trường kiểu **Mixed** = JSON tự do (không ràng buộc schema), dùng cho dữ liệu linh hoạt.

---

## NHÓM 1 — LỚP HỌC (CLASSROOM / LMS)

### Bảng — Classroom (Lớp học)
Lớp học do giáo viên sở hữu, có mã/liên kết mời và tích hợp ngoài. *(timestamps; soft delete qua `deletedAt`)*

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| teacherId | ObjectId → User | required, index | Giáo viên chủ nhiệm |
| name | String | required | Tên lớp |
| description | String | default '' | Mô tả |
| coverImageUrl | String | default '' | Ảnh bìa |
| inviteCode | String | required, unique, index | Mã tham gia lớp |
| inviteToken | String | required, unique, index | Token liên kết mời |
| joinPolicy | String | enum['open','approval_required'], default 'open' | Chế độ vào lớp (tự do / cần duyệt) |
| pinnedMessageId | ObjectId → ClassroomMessage | default null | Tin nhắn ghim |
| archived | Boolean | default false, index | Đã lưu trữ lớp |
| settings | Object | default {} | `allowStudentInvite` (Boolean) |
| integrations | Object | default {} | `googleClassroom`{courseId,courseName,linkedAt}, `lti`{contextId,platformIssuer,linkedAt} |

### Bảng — ClassroomMember (Thành viên lớp)
*(timestamps; unique {classroomId,userId})*

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| classroomId | ObjectId → Classroom | required, index | Lớp |
| userId | ObjectId → User | required, index | Người dùng |
| roleInClass | String | enum['student','co_teacher'], default 'student' | Vai trò trong lớp |
| status | String | enum['active','pending','removed'], default 'active', index | Trạng thái thành viên |
| joinedAt | Date | default now | Thời điểm tham gia |
| leftAt | Date | default null | Thời điểm rời lớp |

### Bảng — ClassroomActivityLog (Nhật ký hoạt động lớp)
*(timestamps; TTL 365 ngày)*

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| classroomId | ObjectId → Classroom | required, index | Lớp |
| actorId | ObjectId → User | default null | Người thực hiện |
| type | String | required, enum (11 giá trị) | Loại sự kiện |
| message | String | default '' | Nội dung mô tả |
| meta | Mixed | default {} | Dữ liệu kèm |

> `type` ∈ {member_joined, member_pending, member_approved, member_removed, co_teacher_added, co_teacher_removed, assignment_created, assignment_closed, attempt_submitted, results_released, integrity_flag}

### Bảng — ClassroomMessage (Tin nhắn chat lớp)
Tin nhắn nhóm hỗ trợ văn bản/đa phương tiện, trả lời, thả cảm xúc, nhắc tên. *(timestamps)*

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| classroomId | ObjectId → Classroom | required, index | Lớp |
| senderId | ObjectId → User | required | Người gửi |
| type | String | enum['text','image','video','file'], default 'text' | Loại tin nhắn |
| content | String | default '' | Nội dung (kèm markup @nhắc tên) |
| media | Object | default null | url, name, size, mimeType, thumbnailUrl, width, height, durationSeconds |
| replyTo | Object | default null | Ảnh chụp tin được trả lời (messageId, senderId, senderName, contentPreview, messageType) |
| mentions | [ObjectId → User] | | Người được nhắc tên |
| reactions | [Object] | default [] | {emoji, userIds[]} |
| deletedAt | Date | default null | Xóa mềm |
| editedAt | Date | default null | Thời điểm sửa |
| clientId | String | index, sparse | Khóa idempotency (chống gửi trùng) |

### Bảng — ClassroomChatReadState (Trạng thái đã đọc chat)
*(timestamps; unique {classroomId,userId})*

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| classroomId | ObjectId → Classroom | required, index | Lớp |
| userId | ObjectId → User | required, index | Người dùng |
| lastReadAt | Date | default null | Mốc đọc gần nhất (tính số chưa đọc) |

---

## NHÓM 2 — THI CỬ (ASSESSMENT / EXAM)

### Bảng — Exam (Đề thi)
Mẫu đề do giáo viên soạn, có phiên bản nội dung. *(timestamps; soft delete)*

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| teacherId | ObjectId → User | required, index | Người tạo đề |
| title | String | required | Tiêu đề |
| description | String | default '' | Mô tả |
| status | String | enum['draft','published','archived'], default 'draft', index | Trạng thái đề |
| contentVersion | Number | default 1 | Phiên bản nội dung |
| sections | [Mixed] | default [] | Các phần/câu hỏi (đa kỹ năng) |
| settings | Mixed | default {} | Cấu hình đề |

### Bảng — ExamAssignment (Bài thi được giao)
Giao đề cho lớp hoặc phát công khai qua liên kết; lưu **ảnh chụp đề (snapshot)** để cố định nội dung. *(timestamps; soft delete)*

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| examId | ObjectId → Exam | required, index | Đề gốc |
| teacherId | ObjectId → User | required, index | Người giao |
| audience | String | required, enum['classroom','public_link'] | Đối tượng giao |
| classroomId | ObjectId → Classroom | default null, index | Lớp được giao |
| mode | String | required, enum['self_paced','scheduled','realtime','practice'] | Chế độ thi |
| config | Mixed | default {} | Cấu hình (thời lượng, số lần…) |
| publicJoin | Object | default null | token, maxUses, expiresAt, usesCount |
| status | String | enum['active','closed'], default 'active' | Trạng thái |
| examSnapshot | Mixed | default null | Bản đông cứng của đề khi giao |
| examSnapshotFrozenAt | Date | default null | Thời điểm đông cứng |

### Bảng — ExamAttempt (Bài làm của học viên)
Một lượt làm bài, gồm đáp án, trạng thái chấm, điểm và dữ liệu chống gian lận. *(timestamps; soft delete cờ `_destroy`)*

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| assignmentId | ObjectId → ExamAssignment | required, index | Bài được giao |
| sessionId | ObjectId → ExamSession | default null, index | Phiên thi (nếu thi realtime) |
| userId | ObjectId → User | required, index | Học viên |
| status | String | enum['in_progress','submitted','expired','void'], default 'in_progress' | Trạng thái lượt làm |
| startedAt | Date | default now | Bắt đầu |
| submittedAt | Date | default null | Nộp |
| attemptDeadlineAt | Date | default null | Hạn nộp |
| answers | Mixed | default {} | Đáp án của học viên |
| meta | Mixed | default {} | Dữ liệu phụ |
| gradingState | String | enum['pending_auto','pending_ai','pending_manual','finalized'], default 'pending_auto' | Trạng thái chấm |
| scores | Object | default {} | Điểm (xem bảng con) |
| resultsReleased | Boolean | default false | Đã trả kết quả |
| integrity | Object | default {} | Dữ liệu gian lận (xem bảng con) |

**Bảng con — scores (examScoresSubSchema):** totalAwarded (Number), totalMax (Number), items (Mixed), skillScores (Mixed), examFormat (String), grammarScore (Mixed), finalScore (Number), finalMax (Number), finalStatus (String).

**Bảng con — integrity (examIntegritySubSchema):** tabSwitchCount (Number, số lần chuyển tab), focusLossSeconds (Number, thời gian rời màn hình), copyPasteAttempts (Number), fullscreenExited (Boolean), lastEventAt (String), riskLevel (String enum['low','medium','high']).

### Bảng — ExamSession (Phiên thi trực tiếp)
Phiên thi realtime theo vòng đời: chờ (lobby) → đang thi (live) → chấm → đóng. *(timestamps; soft delete)*

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| assignmentId | ObjectId → ExamAssignment | required, index | Bài giao gắn phiên |
| leaderTeacherId | ObjectId → User | required | Giáo viên chủ trì |
| status | String | enum['lobby','live','grading','closed','canceled'], default 'lobby', index | Trạng thái phiên |
| roomCode | String | default '' | Mã phòng thi |
| joinedUserIds | [ObjectId → User] | | Học viên đã vào |
| readyUserIds | [ObjectId → User] | | Học viên đã sẵn sàng |
| startedAt | Date | default null | Bắt đầu |
| endedAt | Date | default null | Kết thúc |

---

## NHÓM 3 — NGHE HIỂU (LISTENING COMPREHENSION)

### Bảng — ListeningComprehension (Bài nghe hiểu)
Bài nghe có audio, transcript và câu hỏi trắc nghiệm. *(timestamps; virtual `totalQuestions`)*

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| title | String | required | Tiêu đề |
| summary | String | | Tóm tắt |
| audioUrl | String | required | Đường dẫn audio |
| transcript | String | required | Lời thoại |
| difficulty | String | enum['easy','medium','hard'], default 'easy' | Độ khó |
| imageUrl | String | | Ảnh minh họa |
| minutesToComplete | Number | default 5 | Thời lượng gợi ý (phút) |
| questions | [Object] | | Danh sách câu hỏi (xem dưới) |
| _destroy | Boolean | default false, index | Xóa mềm |
| deletedAt | Date | default null | |

> **questions[]**: questionText (String, required), options ([String]), correctAnswerIndex (Number, required), feedback{ reasoning (String, required), hintTimestampSeconds (Number), keySentence (String) }

### Bảng — ListeningCompAttempt (Bài làm nghe hiểu)
*(timestamps)*

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| userId | ObjectId → User | required | Học viên |
| listeningId | ObjectId → ListeningComprehension | required | Bài nghe hiểu |
| answers | [Object] | | {questionId, chosenIndex (−1 nếu bỏ trống), isCorrect} |
| score | Number | default 0 | Điểm (0–100) |
| correctCount | Number | default 0 | Số câu đúng |
| totalQuestions | Number | default 0 | Tổng số câu |
| durationInSeconds | Number | default 0 | Thời gian làm (giây) |

---

## NHÓM 4 — LUYỆN NÓI (bổ sung — Hội thoại AI)

### Bảng — SpeakingScenario (Kịch bản luyện nói với AI)
Kịch bản role-play cấu hình được cho luyện hội thoại AI. *(timestamps)*

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| slug | String | required, unique | Định danh |
| title | String | required | Tiêu đề |
| description | String | default '' | Mô tả |
| group | String | enum['daily','travel','work','study','service','ielts'], default 'daily', index | Nhóm chủ đề |
| levelSuggested | String | enum['Beginner','Intermediate','Advanced'], default 'Beginner', index | Trình độ gợi ý |
| goals | [String] | | Mục tiêu hội thoại |
| roleForAI | String | required | Vai của AI |
| firstMessage | String | required | Câu mở đầu của AI |
| successCriteria | [String] | | Tiêu chí đạt |
| starterHints | [String] | | Gợi ý mở lời |
| sortOrder | Number | default 0, index | Thứ tự |
| isActive | Boolean | default true, index | Đang bật |
| _destroy | Boolean | default false, index | Xóa mềm |

### Bảng — SpeakingConversation (Phiên hội thoại AI + chấm điểm)
Phiên nói với AI: lưu lượt hội thoại và **phản hồi/chấm điểm chi tiết**. *(timestamps)*

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| userId | ObjectId → User | required, index | Học viên |
| mode | String | default 'freeSpeaking' | Chế độ nói |
| scenario | String | default null | Tên kịch bản |
| scenarioId | ObjectId → SpeakingScenario | default null, index | Kịch bản |
| scenarioSnapshot | Object | | slug, title, group, levelSuggested, goals[] |
| turns | [Object] | | {role enum['user','ai'], text, ts} |
| wordCount | Number | | Số từ |
| durationSeconds | Number | default 0 | Thời lượng (giây) |
| status | String | enum['evaluating','reviewed','failed'], default 'evaluating', index | Trạng thái chấm |
| feedback | Object | | Phản hồi AI chi tiết (xem dưới) |
| score | Number | | Điểm tổng |
| startedAt / endedAt | Date | | Bắt đầu/kết thúc |
| errorMessage | String | | Lỗi (nếu có) |

> **feedback** gồm: điểm 4 tiêu chí IELTS (fc – Fluency, lr – Lexical, gra – Grammar, ia – Interaction) kèm bullet & ghi chú; `overall`, `cefr`, `summary`, `taskAchievement`; `trends`, `strengths[]`, `improvements[]`, `corrections[]`, `vocabUpgrades[]`, `modelAnswers[]`, `nextSteps[]`, `stats`{words,durationSec,wpm,fillerCount,questionCount,turnCount}, `modelInfo`{provider,model}, `evaluatedAt`.

*(Ghi chú: `SpeakingSet`, `Sentence`, `SpeakingAttempts`, `SpeakingEnrollment` đã có trong báo cáo — Bảng 46–49.)*

---

## NHÓM 5 — TƯƠNG TÁC & THÔNG BÁO

### Bảng — Notification (Thông báo)
Thông báo trong ứng dụng, có kèm payload điều hướng sâu. *(chỉ có `createdAt` thủ công; TTL 365 ngày)*

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| recipientId | ObjectId → User | required | Người nhận |
| senderId | ObjectId → User | | Người gửi (null nếu hệ thống) |
| type | String | required, enum (18 giá trị) | Loại thông báo |
| title | String | required | Tiêu đề |
| message | String | required | Nội dung |
| data | Mixed | default {} | Dữ liệu điều hướng |
| isRead | Boolean | default false | Đã đọc |
| createdAt | Date | default now | Thời điểm tạo |

> `type` ∈ {COMMENT_REPLY, COMMENT_REACTION, DAILY_REMINDER, SYSTEM_ANNOUNCEMENT, CLASSROOM_JOIN_REQUEST, CLASSROOM_JOIN_APPROVED, CLASSROOM_JOIN_REJECTED, EXAM_ASSIGNED, EXAM_ASSIGNMENT_UPDATED, EXAM_ASSIGNMENT_CLOSED, EXAM_SESSION_LIVE, EXAM_SUBMISSION_RECEIVED, EXAM_RESULTS_RELEASED, CO_TEACHER_INVITE, CO_TEACHER_INVITE_ACCEPTED, CO_TEACHER_INVITE_DECLINED, CO_TEACHER_REMOVED}

### Bảng — CueComment (Bình luận theo phân đoạn bài nghe)
Bình luận phân luồng (reply) theo từng cue, có cảm xúc. *(chỉ `createdAt` thủ công)*

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| listeningId | ObjectId → Listening | required | Bài nghe |
| cueId | String | required | Phân đoạn (cue) |
| userId | ObjectId → User | required | Người bình luận |
| content | String | required | Nội dung |
| parentId | ObjectId → CueComment | default null | Bình luận cha (reply) |
| reactions | [Object] | | {userId, type enum['LIKE','LOVE','HAHA','WOW','SAD','ANGRY']} |
| createdAt | Date | default now | Thời điểm |

---

## NHÓM 6 — QUẢN TRỊ & HỆ THỐNG

### Bảng — AppRelease (Phiên bản phát hành ứng dụng)
Quản lý vòng đời phát hành phiên bản cho cập nhật OTA. *(timestamps)*

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| platform | String | required, enum['android','ios'], index | Nền tảng |
| environment | String | required, enum['production','staging'], default 'production', index | Môi trường |
| versionName | String | required | Tên phiên bản (vd 1.0.0) |
| versionCode | Number | required (≥1), index | Số hiệu bản dựng (so sánh cập nhật) |
| minSupportedVersionCode | Number | required (≥1) | Ngưỡng buộc cập nhật |
| forceUpdate | Boolean | default false | Buộc cập nhật |
| updateType | String | enum['soft','force'], default 'soft' | Loại cập nhật |
| status | String | enum['pending_approval','approved','scheduled','published','rejected','archived'], default 'pending_approval', index | Trạng thái phát hành |
| downloadUrl / storeUrl | String | default null | Link tải APK / chợ ứng dụng |
| artifactUrlApk / artifactUrlAab | String | default null | Link artifact build |
| changelog / releaseNotes | String | default '' | Ghi chú thay đổi |
| gitSha / gitBranch / ciRunId | String | | Thông tin CI |
| isActive | Boolean | default false, index | Bản đang hiệu lực |
| approvedBy / rejectedBy / publishedBy | ObjectId → User | default null | Vết duyệt/từ chối/phát hành |
| approvedAt / rejectedAt / publishedAt | Date | default null | Mốc thời gian tương ứng |
| scheduledPublishAt | Date | default null | Lịch phát hành |
| createdBy | ObjectId → User | default null | Người tạo |

> Chỉ mục duy nhất: {platform, environment, versionCode} (không trùng bản dựng).

### Bảng — AdminAuditLog (Nhật ký thao tác quản trị)
*(timestamps; TTL 365 ngày)*

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| actorId | ObjectId → User | required, index | Người thực hiện |
| actorRole | String | required | Vai trò |
| action | String | required, index | Hành động |
| targetType | String | required, index | Loại đối tượng tác động |
| targetId | String | required, index | Định danh đối tượng |
| metadata | Mixed | default {} | Dữ liệu chi tiết |
| ip / userAgent | String | default '' | IP & thiết bị |

### Bảng — Report (Báo cáo lỗi/góp ý)
*(chỉ `createdAt` thủ công)*

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| user | ObjectId → User | required | Người báo cáo |
| type | String | required, enum['bug','feature','improvement','other'] | Loại báo cáo |
| title | String | required | Tiêu đề |
| description | String | required | Nội dung |
| images | [String] | | Ảnh đính kèm |
| deviceInfo | Object | | platform, version, device |
| status | String | enum['pending','reviewed','resolved','rejected'], default 'pending' | Trạng thái xử lý |
| adminResponse | String | | Phản hồi của admin |
| createdAt | Date | default now | Thời điểm |

### Bảng — TeacherAssignmentPreset (Mẫu giao bài của giáo viên)
*(timestamps)*

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| teacherId | ObjectId → User | required, index | Giáo viên |
| name | String | required, ≤120 ký tự | Tên mẫu |
| config | Object | | Cấu hình mặc định (xem dưới) |

> **config**: mode (enum['self_paced','scheduled','realtime']), attemptPolicy (enum['single','unlimited','limited']), maxAttempts (2–99), showResultsPolicy (enum['after_submit','after_release','never']), allowPartialSubmit (Boolean), timeLimitSeconds (Number).

### Bảng — WritingTopicVersion (Phiên bản chủ đề Viết)
Ảnh chụp bất biến của chủ đề viết để lưu vết & khôi phục. *(timestamps)*

| Tên trường | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|---|---|---|
| topicId | ObjectId → WritingTopic | required, index | Chủ đề gốc |
| snapshot | Mixed | required | Bản đông cứng nội dung |
| changedBy | ObjectId → User | required | Người thay đổi |
| changeReason | String | default '' | Lý do thay đổi |

---

### Ghi chú kỹ thuật (có thể đưa vào phần chú thích thiết kế DB)
- 4 collection đặt tên tường minh: `speakingscenarios`, `speakingconversations`, `writing_topic_versions`, `admin_audit_logs` (còn lại dùng tên số nhiều mặc định).
- Nhiều bảng dùng **xóa mềm** (soft delete) qua cờ `_destroy`/`deletedAt` thay vì xóa vật lý → giữ lịch sử.
- Các bảng nhật ký (ClassroomActivityLog, Notification, AdminAuditLog) có **TTL 365 ngày** tự xóa dữ liệu cũ.
- Trường **Mixed** (Exam.sections/settings, ExamAssignment.config/examSnapshot, ExamAttempt.answers/scores/integrity ở dạng linh hoạt, Notification.data, AdminAuditLog.metadata, WritingTopicVersion.snapshot) là JSON schema-less để chứa cấu trúc động (đề đa kỹ năng, cấu hình, payload).
- **Enrollment** (Bảng 40 trong báo cáo) là bảng tiến độ bài **nghe**; quan hệ thành viên **lớp học** dùng bảng riêng **ClassroomMember** (mới).
