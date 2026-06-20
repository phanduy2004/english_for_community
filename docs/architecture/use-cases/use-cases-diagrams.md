# Sơ đồ use case & kiến trúc — English for Community

> Dựa trên backend `english_for_community_backend/` (routes, `permissions.js`, Socket.IO, cron jobs).  
> Xem trên GitHub / VS Code / Cursor: preview Markdown để render Mermaid.  
> **UML kiểu luận văn:** [use-cases-uml.md](./use-cases-uml.md)

---

## 1. Tổng quan — Actor & hệ thống

```mermaid
flowchart TB
  subgraph Actors["Người dùng & hệ thống"]
    Guest["Guest\n(chưa đăng nhập)"]
    User["Học viên\nrole: user"]
    Teacher["Giáo viên\nrole: teacher"]
    Admin["Quản trị\nrole: admin"]
    CI["CI/CD\n(CI_RELEASE_TOKEN)"]
    Cron["Cron jobs\n(node-cron)"]
  end

  subgraph Client["Flutter App"]
    App["Android / iOS / Web"]
    DictDB["SQLite\n(từ điển offline)"]
  end

  subgraph Backend["Node.js API"]
    API["Express REST\n/api/*"]
    Socket["Socket.IO"]
    Jobs["smartNotification\nexamExpire\nappRelease"]
  end

  subgraph Data["Hạ tầng"]
    Mongo["MongoDB"]
    Cloud["Cloudinary"]
    FCM["Firebase FCM"]
    AI["Gemini / OpenAI / Groq"]
  end

  Guest --> App
  User --> App
  Teacher --> App
  Admin --> App
  App --> DictDB
  App <-->|JWT + REST| API
  App <-->|realtime| Socket
  API --> Mongo
  API --> Cloud
  API --> AI
  Socket --> Mongo
  Jobs --> Mongo
  Jobs --> FCM
  CI --> API
  Cron --> Jobs
```

---

## 2. Phân quyền theo role (RBAC)

```mermaid
flowchart LR
  User["user\n(học viên)"]
  Teacher["teacher"]
  Admin["admin"]

  User -->|nộp đơn| Apply["teacher.application.*"]
  Apply -->|admin duyệt| Teacher

  User --> Learn["Học tập\n4 kỹ năng + vocab\n+ progress + AI chat"]
  User --> Join["Tham gia lớp\n+ làm bài thi"]
  User --> Notify["Thông báo\n+ báo cáo lỗi"]

  Teacher --> Learn
  Teacher --> Join
  Teacher --> Class["classroom.manage\nmembers.manage"]
  Teacher --> Exam["exam.manage\nassign + session.run"]
  Teacher --> Grade["grading.read\ngrading.write"]

  Admin -->|wildcard *| All["Toàn bộ quyền"]
  All --> CMS["CMS nội dung\n5 kỹ năng"]
  All --> Users["users.read/restore\nban, role"]
  All --> Reports["reports.*\nmoderation"]
  All --> Release["app-releases"]
  All --> Class
  All --> Exam
  All --> Grade
```

---

## 3. Use case học viên — tự học

```mermaid
flowchart TD
  Start([Đăng nhập / Đăng ký OTP])
  Start --> Home[Trang chủ\nprofile + streak]

  Home --> L[Listening Dictation\n/api/listening]
  Home --> LC[Listening MCQ\n/api/listening-comp]
  Home --> R[Reading\n/api/reading]
  Home --> S[Speaking\n/api/speaking]
  Home --> W[Writing\n/api/writing]
  Home --> V[Vocabulary SRS\n/api/vocab]
  Home --> P[Progress & BXH\n/api/progress]
  Home --> AI[Hỏi AI\n/api/chat/ask]

  L --> Submit1[POST /submit\n+ gamification]
  LC --> Submit2[POST /submit]
  R --> Submit3[POST /submit\nAI feedback]
  S --> Submit4[POST /submit\nSTT / VAPI]
  W --> Draft[PATCH /draft]
  Draft --> Submit5[POST /submit\nAI chấm]
  V --> Review[POST /review-update]

  Submit1 --> Hist[Lịch sử\n/users/me/activities]
  Submit2 --> Hist
  Submit3 --> Hist
  Submit4 --> Hist
  Submit5 --> Hist
```

---

## 4. Use case lớp học & bài thi

```mermaid
sequenceDiagram
  autonumber
  participant HS as Học viên
  participant GV as Giáo viên
  participant API as REST API
  participant WS as Socket.IO
  participant DB as MongoDB

  Note over GV,DB: Giai đoạn 1 — Thiết lập
  GV->>API: POST /classrooms (tạo lớp)
  GV->>API: POST /teacher/exams (tạo đề)
  GV->>API: POST /teacher/exams/assignments (giao bài)
  HS->>API: POST /classrooms/join-by-code

  Note over GV,DB: Giai đoạn 2 — Làm bài (async)
  HS->>API: GET /exams/assignments/available
  HS->>API: POST /exams/assignments/:id/start
  HS->>API: PATCH /exams/attempts/:id (autosave)
  HS->>API: POST /exams/attempts/:id/submit

  Note over GV,DB: Giai đoạn 3 — Thi realtime (tùy chọn)
  GV->>API: POST /teacher/exams/.../sessions
  HS->>WS: exam_register + join_exam_session
  GV->>WS: join_exam_session
  GV->>API: POST .../sessions/:id/start
  HS->>WS: exam_live_view_sync
  HS->>API: PATCH .../live-view
  GV->>API: GET .../live-monitor
  GV->>API: POST .../sessions/:id/end

  Note over GV,DB: Giai đoạn 4 — Chấm & công bố
  GV->>API: GET .../attempts (danh sách)
  GV->>API: POST .../ai-suggestions / PATCH manual-grade
  GV->>API: POST .../release-results
  HS->>API: GET /exams/attempts/:id (xem điểm)
```

---

## 5. Use case Admin — vận hành

```mermaid
flowchart TD
  Admin([Admin đăng nhập])
  Admin --> Dash[Dashboard\n/api/admin/stats]
  Admin --> Users[Quản lý user\nban / xóa / đổi role]
  Admin --> TA[Duyệt đơn GV\n/teacher-applications]
  Admin --> CMS[CMS nội dung]

  CMS --> L1[Listening\n/api/listening]
  CMS --> L2[Listening Comp\n/api/listening-comp]
  CMS --> R[Reading\n/api/reading]
  CMS --> S[Speaking\n/api/speaking/admin]
  CMS --> W[Writing + version\n/api/writing/admin]

  Admin --> Rep[Báo cáo user\n/api/reports]
  Admin --> Act[Lịch sử hoạt động\n/api/admin/activities]
  Admin --> Rel[Phát hành app\n/api/admin/app-releases]
  Admin --> Audit[Audit log & export CSV]
```

---

## 6. Luồng trở thành giáo viên

```mermaid
stateDiagram-v2
  [*] --> user: Đăng ký thành công
  user --> pending: POST /teacher/applications
  pending --> user: withdraw đơn
  pending --> rejected: admin reject
  pending --> teacher: admin approve\nPATCH role
  rejected --> pending: nộp lại đơn
  teacher --> [*]: Mở classroom + exam APIs
```

---

## 7. Thông báo & realtime

```mermaid
flowchart LR
  subgraph Push["Push (FCM)"]
    CronJob[smartNotificationJob]
    CronJob --> DV[DAILY_VOCAB]
    CronJob --> RR[REVIEW_REMINDER]
    CronJob --> PN[PROGRESS_NUDGE]
    CronJob --> SR[STREAK_RESCUE]
  end

  subgraph InApp["In-app"]
    API[notificationService]
    API --> DB[(Notification)]
    API --> SocketEmit[Socket → user room]
  end

  subgraph Actions["Hành động từ notification"]
    Resp[POST /notifications/:id/respond]
    Resp --> CT[CO_TEACHER_INVITE\naccept/decline]
    Resp --> JR[CLASSROOM_JOIN_REQUEST\napprove/reject]
  end

  CronJob --> API
  FCM[Firebase] --> App[Flutter]
  SocketEmit --> App
```

---

## 8. Bản đồ API module (đang mount)

```mermaid
mindmap
  root((E4C API))
    Auth
      register OTP
      login logout
      google refresh
      forgot password
    Users
      profile
      activities
      fcm token
    Skills
      listening
      listening comp
      reading
      speaking
      writing
      vocab
    Learning
      progress
      chat AI
      notifications
      reports
    Classroom
      join code token
      teacher manage
      co teacher
    Exams
      student attempts
      teacher assign grade
      sessions live
    Admin
      users CMS
      moderation
      app releases
    Public
      version check
      public exam token
```

---

## Ghi chú

| Mục | Chi tiết |
|-----|----------|
| Route chưa mount | `dictationRoutes`, `cueRoutes`, `lessonRoutes` — logic cues/dictation đã gộp vào `/api/listening` |
| Guest | Chủ yếu `version-check`; từ điển = offline app |
| Teacher & Admin | Vẫn dùng được API học tập của `user` (chỉ cần JWT) |

**UML Use Case (giống mẫu luận văn):** [use-cases-uml.md](./use-cases-uml.md) — Actor + `<<extend>>` cho User / Teacher / Admin.
