# Teacher ↔ Student Notifications

In-app notifications + push (FCM) + realtime (Socket.IO) for classroom and exam workflows.

## Channels

| Channel | When | Implementation |
|---------|------|----------------|
| **In-app inbox** | Always | `Notification` MongoDB + `GET /api/notifications` |
| **Realtime (Socket)** | App open + logged in | `user_login` → room `{userId}` → `new_notification` → `NotificationBloc` |
| **Push (FCM)** | Device has FCM token | `notificationService.createNotification` → FCM multicast |
| **Local push banner** | App foreground (student mobile) | `LocalNotificationService.showInstantNotification` |
| **In-app inbox** | Tap bell icon | `NotificationDialog` + `NotificationBloc` |
| **Web banner** | App foreground (web only) | Corner toast in `AppNotificationListener` |
| **Action feedback (student mobile)** | Save/submit/errors | Full-width bottom `SnackBar` via `AppCornerToast` |

## Notification types (enum)

### Classroom & team

| Type | Recipient | Trigger | In-app Accept/Decline |
|------|-----------|---------|------------------------|
| `CLASSROOM_JOIN_REQUEST` | Primary teacher (owner) | Student requests join (`approval_required`) | **Yes** — `POST /api/notifications/:id/respond` |
| `CLASSROOM_JOIN_APPROVED` | Student | Teacher approves (UI or notification) | No |
| `CLASSROOM_JOIN_REJECTED` | Student | Teacher rejects | No |
| `CO_TEACHER_INVITE` | Invited teacher | Owner adds co-teacher (**pending** until accept) | **Yes** |
| `CO_TEACHER_INVITE_ACCEPTED` | Owner | Co-teacher accepts invite | No (info) |
| `CO_TEACHER_INVITE_DECLINED` | Owner | Co-teacher declines | No (info) |
| `CO_TEACHER_REMOVED` | Co-teacher | Owner removes them from class | No (info) |

### Exams

| Type | Recipient | Trigger | Actions |
|------|-----------|---------|---------|
| `EXAM_ASSIGNED` | Active students in class | Teacher creates classroom assignment | Tap → classroom |
| `EXAM_ASSIGNMENT_UPDATED` | Same | Teacher patches assignment window/config | Tap → classroom |
| `EXAM_ASSIGNMENT_CLOSED` | Same | Teacher closes assignment | Tap → classroom |
| `EXAM_SESSION_LIVE` | Students (live session) | Teacher starts realtime session | Tap → session lobby |
| `EXAM_SUBMISSION_RECEIVED` | Assignment `teacherId` (owner) | Student submits attempt | Tap → grading hub |
| `EXAM_RESULTS_RELEASED` | Student | Results released / auto after submit | Tap → exam run |

### Learning / social (legacy)

| Type | Recipient | Trigger |
|------|-----------|---------|
| `COMMENT_REPLY` | Cue author | Reply on listening cue |
| `COMMENT_REACTION` | Comment author | Reaction on cue comment |
| `DAILY_REMINDER` | User | Cron / smart notification job |
| `SYSTEM_ANNOUNCEMENT` | User | Admin / system |

## Actionable notifications API

```http
POST /api/notifications/:id/respond
Authorization: Bearer …
Content-Type: application/json

{ "action": "accept" | "decline" }
```

Supported types: `CO_TEACHER_INVITE`, `CLASSROOM_JOIN_REQUEST`.

Payload `data` fields:

```json
{
  "actionable": true,
  "actionStatus": "pending | accepted | declined",
  "classroomId": "...",
  "memberId": "...",
  "studentId": "...",
  "studentName": "..."
}
```

Flutter: notification list shows **Chấp nhận / Từ chối** when `actionable` + `actionStatus` pending (`NotificationEntity.supportsInAppResponse`).

## Co-teacher flow (new)

1. Owner searches username → **Add** → `ClassroomMember` created with `roleInClass: co_teacher`, `status: pending`.
2. Invited teacher receives `CO_TEACHER_INVITE` (socket + FCM + inbox).
3. **Accept** → `status: active`, class appears in My classrooms, owner gets `CO_TEACHER_INVITE_ACCEPTED`.
4. **Decline** → member `removed`, owner gets `CO_TEACHER_INVITE_DECLINED`.
5. Owner Settings shows pending row with badge **Đang chờ**.

> Co-teachers already `active` in DB before this change stay active (no re-invite).

## Deep links (Flutter)

| Type | Route |
|------|-------|
| `EXAM_ASSIGNED`, `EXAM_ASSIGNMENT_*` | `StudentClassroomDetailPage` |
| `EXAM_RESULTS_RELEASED` | `ExamRunnerPage` |
| `EXAM_SESSION_LIVE` | `ExamSessionLobbyPage` |
| `CLASSROOM_JOIN_*`, `CO_TEACHER_*` | `TeacherClassroomDetailPage` |
| `EXAM_SUBMISSION_RECEIVED` | `TeacherExamGradingPage` |

Handler: `lib/core/notification/notification_navigation.dart`.

## Backend hooks (implemented)

| Service | Event | Notification |
|---------|-------|--------------|
| `classroomService` | `_joinClassroom` (pending) | `CLASSROOM_JOIN_REQUEST` (+ `studentId`) |
| `classroomService` | `approveMember` / `rejectMember` | `CLASSROOM_JOIN_APPROVED` / `REJECTED` |
| `classroomService` | `addCoTeacher` | `CO_TEACHER_INVITE` |
| `classroomService` | `removeCoTeacher` | `CO_TEACHER_REMOVED` |
| `notificationActionService` | `respond` accept/decline | Updates member + resolves notification |
| `teacherExamAssignmentService` | create / patch / close | `EXAM_ASSIGNED` / `UPDATED` / `CLOSED` |
| `examAttemptService` | submit | `EXAM_SUBMISSION_RECEIVED`, optional `EXAM_RESULTS_RELEASED` |
| `examGradingService` | `releaseResults` | `EXAM_RESULTS_RELEASED` |
| `examSessionService` | `startSession` | `EXAM_SESSION_LIVE` |
| `listeningController` | reply / reaction | `COMMENT_REPLY` / `COMMENT_REACTION` |
| `smartNotificationJob` | cron | `DAILY_REMINDER`, vocab reminders |

Helper: `src/services/teacherNotificationHelper.js`  
Actions: `src/services/notificationActionService.js`

## Gaps / roadmap (chưa có)

| Feature | Ghi chú |
|---------|---------|
| **Co-teacher exam fan-out** | `EXAM_ASSIGNED`, `EXAM_SUBMISSION_RECEIVED` chỉ gửi owner (`teacherId`), chưa gửi GV phụ active |
| **Join request → co-teacher** | Chỉ GVCN nhận `CLASSROOM_JOIN_REQUEST`; GV phụ active chưa nhận bản sao |
| **Open join** | Học sinh vào `open` policy không tạo thông báo (đúng nghiệp vụ) |
| ~~Teacher application approved~~ | **Không dùng** — GV được `role: teacher` khi đăng ký hoặc gửi đơn (tự kích hoạt) |
| **Report / admin moderation** | Report được xử lý — chưa push reporter |
| **Writing graded manually** | Chấm tay xong — có thể thiếu notification nếu không đi qua `releaseResults` |
| **Due-date reminders** | Cron nhắc hạn bài tập — P1 |
| **Notification preferences** | Tắt từng loại — P2 |
| **Digest** | Gộp nhiều tin — P2 |

## Testing

1. Owner adds co-teacher → login invited teacher → Notifications → Accept → mở được lớp.
2. Student join `approval_required` class → teacher notification → Accept/Decline.
3. Assign exam → students receive `EXAM_ASSIGNED` (socket log `📢 [Notify]`).

Scripts: `npm run test:notifications` (HoangDong seed).
