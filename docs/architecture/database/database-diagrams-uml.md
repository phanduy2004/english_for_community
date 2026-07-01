# Lược đồ thực thể kết hợp (ERD) — English for Community

> **32 collection** · MongoDB `english_community`  
> Kiểu **luận văn**: mỗi thực thể dạng **class UML** (`+ObjectId _id`, một cột); quan hệ có **cardinality** (`1`, `0..*`, `0..1`); **không ghi tên FK** trên mũi tên.  
> **Trắng đen** (không tô màu miền). Ký hiệu field: `+` public · `-` private · `#` protected.

**Hướng dẫn Word:** [database-diagrams-for-word.md](../database-diagrams-for-word.md)  
**PlantUML (7 trang):** [plantuml/database-full.puml](../plantuml/database-full.puml)

### Cách xem & sửa

| Việc | Làm gì |
|------|--------|
| **Xem sơ đồ** | Preview file này (Ctrl+Shift+V) hoặc xem PNG bên dưới |
| **Sửa schema** | Sửa [`export/*.mmd`](export/) → chạy [`export/export-erd.ps1`](export/export-erd.ps1) |
| **Chèn Word** | PNG/SVG trong [`export/`](export/) |
| **Copy Mermaid** | Dán khối ```mermaid``` bên dưới vào [mermaid.live](https://mermaid.live) (kèm frontmatter [`erd-frontmatter.yaml`](export/erd-frontmatter.yaml)) |

---

## 2.x.2.1 User, hệ thống, lớp học (Hình 1/3)

12 thực thể · Source: [`export/erd-hinh-1a-user-lop.mmd`](export/erd-hinh-1a-user-lop.mmd)

```mermaid
classDiagram
    direction TB

    class User {
        +ObjectId _id
        +String phone
        +String email
        -String password
        +String avatarUrl
        +String fullName
        +String username
        +String role
        +Date dateOfBirth
        +String bio
        +String gender
        +Boolean isVerified
        +String goal
        +String cefr
        +Number dailyMinutes
        +Object reminder
        +Number dailyLessonGoal
        +Number dailyActivityProgress
        +String dailyProgressDate
        +Number totalPoints
        +Number level
        +Number currentStreak
        +Boolean strictCorrection
        +String language
        +String timezone
        +Boolean isOnline
        +Date lastActivityDate
        +Boolean isBanned
        +Date banExpiresAt
        +String banReason
        #Boolean _destroy
        -String refreshToken
        +String[] fcmTokens
        -String resetOtp
        -Date resetOtpExpiresAt
        -Number resetOtpAttempts
        -Date resetLastSentAt
        -String otpPurpose
        -Date otpCreatedAt
        +Date createdAt
        +Date updatedAt
    }
    class Notification {
        +ObjectId _id
        +ObjectId recipientId
        +ObjectId senderId
        +String type
        +String title
        +String message
        +Object data
        +Boolean isRead
        +Date createdAt
    }
    class Report {
        +ObjectId _id
        +ObjectId user
        +String type
        +String title
        +String description
        +String[] images
        +Object deviceInfo
        +String status
        +String adminResponse
        +Date createdAt
    }
    class Word {
        +ObjectId _id
        +ObjectId user
        +String headword
        +String ipa
        +String shortDefinition
        +String pos
        +String status
        +Number learningLevel
        +Date nextReviewDate
        +Date lastReviewedDate
        +Date lastRemindedDate
        +Date createdAt
        +Date updatedAt
    }
    class UserDailyProgress {
        +ObjectId _id
        +ObjectId userId
        +String date
        +Number studySeconds
        +Number vocabLearned
        +Object lessonsCompleted
        +Object stats
        +Date createdAt
        +Date updatedAt
    }
    class AdminAuditLog {
        +ObjectId _id
        +ObjectId actorId
        +String actorRole
        +String action
        +String targetType
        +String targetId
        +Object metadata
        +String ip
        +String userAgent
        +Date createdAt
    }
    class AppRelease {
        +ObjectId _id
        +String platform
        +String environment
        +String versionName
        +Number versionCode
        +Number minSupportedVersionCode
        +Boolean forceUpdate
        +String updateType
        +String status
        +String downloadUrl
        +String releaseNotes
        +Date publishedAt
        +Date createdAt
        +Date updatedAt
    }
    class Classroom {
        +ObjectId _id
        +ObjectId teacherId
        +String name
        +String description
        +String coverImageUrl
        +String inviteCode
        +String inviteToken
        +String joinPolicy
        +ObjectId pinnedMessageId
        +Boolean archived
        +Object settings
        +Object integrations
        +Date createdAt
        +Date updatedAt
    }
    class ClassroomMember {
        +ObjectId _id
        +ObjectId classroomId
        +ObjectId userId
        +String roleInClass
        +String status
        +Date joinedAt
        +Date leftAt
        +Date createdAt
        +Date updatedAt
    }
    class ClassroomMessage {
        +ObjectId _id
        +ObjectId classroomId
        +ObjectId senderId
        +String type
        +String content
        +Object media
        +Object replyTo
        +ObjectId[] mentions
        +Object[] reactions
        +Date deletedAt
        +Date editedAt
        +String clientId
        +Date createdAt
        +Date updatedAt
    }
    class ClassroomActivityLog {
        +ObjectId _id
        +ObjectId classroomId
        +ObjectId actorId
        +String type
        +String message
        +Object meta
        +Date createdAt
        +Date updatedAt
    }
    class ClassroomChatReadState {
        +ObjectId _id
        +ObjectId classroomId
        +ObjectId userId
        +Date lastReadAt
        +Date createdAt
        +Date updatedAt
    }

    User "1" --> "0..*" Notification
    User "1" --> "0..*" Report
    User "1" --> "0..*" Word
    User "1" --> "0..*" UserDailyProgress
    User "1" --> "0..*" AdminAuditLog
    User "1" --> "0..*" Classroom
    User "1" --> "0..*" ClassroomMember
    User "1" --> "0..*" ClassroomMessage
    User "0..1" ..> "0..*" ClassroomActivityLog
    User "1" --> "0..*" ClassroomChatReadState
    Classroom "1" --> "0..*" ClassroomMember
    Classroom "1" --> "0..*" ClassroomMessage
    Classroom "1" --> "0..*" ClassroomActivityLog
    Classroom "1" --> "0..*" ClassroomChatReadState
    Classroom "0..1" ..> "0..1" ClassroomMessage
```

![Hình 2.x.2.1 — User, hệ thống, lớp học](export/erd-hinh-1a-user-lop.png)

---

## 2.x.2.2 Đề thi (Hình 2/3)

7 thực thể · Source: [`export/erd-hinh-1b-de-thi.mmd`](export/erd-hinh-1b-de-thi.mmd)

```mermaid
classDiagram
    direction TB

    class User {
        +ObjectId _id
        +String fullName
        +String role
    }
    class Classroom {
        +ObjectId _id
        +String name
    }
    class Exam {
        +ObjectId _id
        +ObjectId teacherId
        +String title
        +String description
        +String status
        +Number contentVersion
        +Object[] sections
        +Object settings
        +Date createdAt
        +Date updatedAt
    }
    class ExamAssignment {
        +ObjectId _id
        +ObjectId examId
        +ObjectId teacherId
        +ObjectId classroomId
        +String audience
        +String mode
        +Object config
        +Object publicJoin
        +String status
        +Object examSnapshot
        +Date examSnapshotFrozenAt
        +Date createdAt
        +Date updatedAt
    }
    class ExamSession {
        +ObjectId _id
        +ObjectId assignmentId
        +ObjectId leaderTeacherId
        +String status
        +String roomCode
        +ObjectId[] joinedUserIds
        +ObjectId[] readyUserIds
        +Date startedAt
        +Date endedAt
        +Date createdAt
        +Date updatedAt
    }
    class ExamAttempt {
        +ObjectId _id
        +ObjectId assignmentId
        +ObjectId sessionId
        +ObjectId userId
        +String status
        +Object answers
        +Object scores
        +String gradingState
        +Boolean resultsReleased
        +Object integrity
        +Date startedAt
        +Date submittedAt
        +Date attemptDeadlineAt
        +Date createdAt
        +Date updatedAt
    }
    class TeacherAssignmentPreset {
        +ObjectId _id
        +ObjectId teacherId
        +String name
        +Object config
        +Date createdAt
        +Date updatedAt
    }

    User "1" --> "0..*" Exam
    User "1" --> "0..*" ExamAssignment
    User "1" --> "0..*" ExamSession
    User "1" --> "0..*" ExamAttempt
    User "1" --> "0..*" TeacherAssignmentPreset
    Exam "1" --> "0..*" ExamAssignment
    Classroom "0..1" ..> "0..*" ExamAssignment
    ExamAssignment "1" --> "0..*" ExamSession
    ExamAssignment "1" --> "0..*" ExamAttempt
    ExamSession "0..1" ..> "0..*" ExamAttempt
```

![Hình 2.x.2.2 — Đề thi](export/erd-hinh-1b-de-thi.png)

---

## 2.x.2.3 Học tập — Nghe, đọc, viết, nói (Hình 3/3)

15 thực thể · Source: [`export/erd-hinh-2-hoc-tap.mmd`](export/erd-hinh-2-hoc-tap.mmd)

```mermaid
classDiagram
    direction TB

    class User {
        +ObjectId _id
        +String fullName
        +String role
    }
    class Listening {
        +ObjectId _id
        +String code
        +String title
        +String audioUrl
        +Object playbackPad
        +String difficulty
        +String[] tags
        +String transcript
        +Object[] cues
        #Boolean _destroy
        +Date deletedAt
        +Date createdAt
        +Date updatedAt
    }
    class DictationAttempt {
        +ObjectId _id
        +ObjectId userId
        +ObjectId listeningId
        +Number cueIdx
        +String userText
        +String userTextNorm
        +Object score
        +Number attemptsCount
        +Number durationInSeconds
        +Number playedMs
        +Date submittedAt
        +Date createdAt
        +Date updatedAt
    }
    class Enrollment {
        +ObjectId _id
        +ObjectId userId
        +ObjectId listeningId
        +ObjectId[] completedCueIds
        +Number progress
        +Date lastAccessedAt
        +Boolean isCompleted
        +Date createdAt
        +Date updatedAt
    }
    class CueComment {
        +ObjectId _id
        +ObjectId listeningId
        +String cueId
        +ObjectId userId
        +String content
        +ObjectId parentId
        +Object[] reactions
        +Date createdAt
    }
    class ListeningComprehension {
        +ObjectId _id
        +String title
        +String summary
        +String audioUrl
        +String transcript
        +String difficulty
        +String imageUrl
        +Number minutesToComplete
        +Object[] questions
        #Boolean _destroy
        +Date deletedAt
        +Date createdAt
        +Date updatedAt
    }
    class ListeningCompAttempt {
        +ObjectId _id
        +ObjectId userId
        +ObjectId listeningId
        +Object[] answers
        +Number score
        +Number correctCount
        +Number totalQuestions
        +Number durationInSeconds
        +Date createdAt
        +Date updatedAt
    }
    class Reading {
        +ObjectId _id
        +String title
        +String summary
        +String content
        +Object translation
        +String difficulty
        +String imageUrl
        +Number minutesToRead
        +Object[] questions
        #Boolean _destroy
        +Date deletedAt
        +Date createdAt
        +Date updatedAt
    }
    class ReadingProgress {
        +ObjectId _id
        +ObjectId userId
        +ObjectId readingId
        +String status
        +Number highScore
        +Number attemptsCount
        +Date lastAttemptedAt
        +Date createdAt
        +Date updatedAt
    }
    class ReadingAttempt {
        +ObjectId _id
        +ObjectId userId
        +ObjectId readingId
        +Object[] answers
        +Number score
        +Number correctCount
        +Number totalQuestions
        +Number durationInSeconds
        +Date createdAt
        +Date updatedAt
    }
    class WritingTopic {
        +ObjectId _id
        +String name
        +Boolean isActive
        +String approvalStatus
        +Object approval
        +Object aiConfig
        +Object stats
        +Date createdAt
        +Date updatedAt
    }
    class WritingTopicVersion {
        +ObjectId _id
        +ObjectId topicId
        +Object snapshot
        +ObjectId changedBy
        +String changeReason
        +Date createdAt
    }
    class WritingSubmission {
        +ObjectId _id
        +ObjectId userId
        +ObjectId topicId
        +Object generatedPrompt
        +String content
        +Number wordCount
        +Number durationInSeconds
        +String status
        +Date startedAt
        +Date submittedAt
        +Object feedback
        +Number score
        +Date reviewedAt
        +Date createdAt
        +Date updatedAt
    }
    class SpeakingSet {
        +ObjectId _id
        +String title
        +String description
        +String level
        +String mode
        +Object[] sentences
        #Boolean _destroy
        +Date deletedAt
        +Date createdAt
        +Date updatedAt
    }
    class SpeakingEnrollment {
        +ObjectId _id
        +ObjectId userId
        +ObjectId speakingSetId
        +String[] completedSentenceIds
        +Number progress
        +Number averageWer
        +Date lastAccessedAt
        +Boolean isCompleted
        +Date createdAt
        +Date updatedAt
    }
    class SpeakingAttempt {
        +ObjectId _id
        +ObjectId userId
        +ObjectId speakingSetId
        +String sentenceId
        +String userTranscript
        +String userAudioUrl
        +Number audioDurationSeconds
        +Object score
        +Date submittedAt
        +Date createdAt
        +Date updatedAt
    }

    User "1" --> "0..*" DictationAttempt
    User "1" --> "0..*" Enrollment
    User "1" --> "0..*" CueComment
    User "1" --> "0..*" ListeningCompAttempt
    User "1" --> "0..*" ReadingProgress
    User "1" --> "0..*" ReadingAttempt
    User "1" --> "0..*" WritingSubmission
    User "0..1" ..> "0..*" WritingTopicVersion
    User "1" --> "0..*" SpeakingEnrollment
    User "1" --> "0..*" SpeakingAttempt
    Listening "1" --> "0..*" DictationAttempt
    Listening "1" --> "0..*" Enrollment
    Listening "1" --> "0..*" CueComment
    ListeningComprehension "1" --> "0..*" ListeningCompAttempt
    CueComment "0..1" ..> "0..*" CueComment
    Reading "1" --> "0..*" ReadingProgress
    Reading "1" --> "0..*" ReadingAttempt
    WritingTopic "1" --> "0..*" WritingSubmission
    WritingTopic "1" --> "0..*" WritingTopicVersion
    SpeakingSet "1" --> "0..*" SpeakingEnrollment
    SpeakingSet "1" --> "0..*" SpeakingAttempt
```

![Hình 2.x.2.3 — Học tập](export/erd-hinh-2-hoc-tap.png)

---

## Ghi chú

| Mục | Giải thích |
|-----|------------|
| **Đủ 32/32** | User + 31 collection còn lại — bảng đối chiếu bên dưới |
| **Hình 1** | User (đủ field) + hệ thống + lớp — 12 thực thể |
| **Hình 2** | Đề thi — 7 thực thể; User rút gọn (tham chiếu) |
| **Hình 3** | Nghe, đọc, viết, nói — 15 thực thể; User rút gọn |
| **Không vẽ** | `RolePermission`, `TeacherApplication` — model cũ |
| **AppRelease** | Không FK tới User |
| Kiểu `objectId` | Tham chiếu MongoDB ObjectId (FK ngầm) |
| Kiểu `object` / `object_array` | Subdocument nhúng (Mongoose embed) |
| Quan hệ `"1" --> "0..*"` | Một–nhiều bắt buộc |
| Quan hệ `"0..1" ..> "0..*"` | Một–nhiều tùy chọn |
| Quan hệ `"0..1" ..> "0..1"` | Một–một tùy chọn |
| **Giới hạn Mermaid** | Không vẽ **chân quạ ER** và **bảng class** trong cùng một diagram |

### Bảng đối chiếu 32 collection

| STT | Collection | Hình ERD |
|:---:|------------|:--------:|
| 1 | User | 1 + 2 + 3 |
| 2 | Notification | 1 |
| 3 | Report | 1 |
| 4 | Word | 1 |
| 5 | UserDailyProgress | 1 |
| 6 | AdminAuditLog | 1 |
| 7 | AppRelease | 1 |
| 8 | Classroom | 1 |
| 9 | ClassroomMember | 1 |
| 10 | ClassroomMessage | 1 |
| 11 | ClassroomActivityLog | 1 |
| 12 | ClassroomChatReadState | 1 |
| 13 | Exam | 2 |
| 14 | ExamAssignment | 2 |
| 15 | ExamSession | 2 |
| 16 | ExamAttempt | 2 |
| 17 | TeacherAssignmentPreset | 2 |
| 18 | Listening | 3 |
| 19 | Enrollment | 3 |
| 20 | DictationAttempt | 3 |
| 21 | CueComment | 3 |
| 22 | ListeningComprehension | 3 |
| 23 | ListeningCompAttempt | 3 |
| 24 | Reading | 3 |
| 25 | ReadingProgress | 3 |
| 26 | ReadingAttempt | 3 |
| 27 | WritingTopic | 3 |
| 28 | WritingSubmission | 3 |
| 29 | WritingTopicVersion | 3 |
| 30 | SpeakingSet | 3 |
| 31 | SpeakingEnrollment | 3 |
| 32 | SpeakingAttempt | 3 |
