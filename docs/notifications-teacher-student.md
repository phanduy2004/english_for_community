# Teacher ↔ Student Notifications

In-app notifications + push (FCM) + realtime (Socket.IO) for classroom and exam workflows.

## Channels

| Channel | When | Implementation |
|---------|------|----------------|
| **In-app inbox** | Always | `Notification` MongoDB + `GET /api/notifications` |
| **Realtime (Socket)** | App open + logged in | `user_login` → join room `{userId}` → `new_notification` → `NotificationBloc` |
| **Push (trượt)** | Device has FCM token | `notificationService.createNotification` → FCM multicast |
| **Local banner** | App foreground (mobile) | `LocalNotificationService.showInstantNotification` |
| **Web banner** | App foreground (web) | `SnackBar` in `AppNotificationListener` (no FCM/local plugin) |

### Socket flow (required for realtime)

```
Teacher POST /teacher/exams/assignments (audience=classroom)
  → teacherExamAssignmentService.create
  → notifyStudentsExamAssigned (active ClassroomMember students)
  → notificationService.createNotification (each student)
       → MongoDB save
       → io.to(studentUserId).emit('new_notification', plain JSON)
  → Student app: SocketService.userLogin(studentId) already called
       → AppNotificationListener hears event → inbox + banner
```

**Student must be logged in** with socket connected (`SocketLifecycleManager` + `AppNotificationListener`).  
Backend log when assigning: `📢 [Notify] EXAM_ASSIGNED → N student(s)` and `⚡ [Socket] new_notification → room …`.

If `N = 0`: student not `active` in `ClassroomMember` for that `classroomId`, or wrong class selected.

## Notification types (enum)

| Type | Recipient | Trigger |
|------|-----------|---------|
| `CLASSROOM_JOIN_REQUEST` | Teacher | Student requests join (`approval_required`) |
| `CLASSROOM_JOIN_APPROVED` | Student | Teacher approves member |
| `CLASSROOM_JOIN_REJECTED` | Student | Teacher rejects pending member |
| `EXAM_ASSIGNED` | Active students in class | Teacher creates classroom assignment |
| `EXAM_ASSIGNMENT_UPDATED` | Same | Teacher patches assignment config (due/window) |
| `EXAM_ASSIGNMENT_CLOSED` | Same | Teacher closes assignment |
| `EXAM_SESSION_LIVE` | Students joined live session | Teacher starts realtime session |
| `EXAM_SUBMISSION_RECEIVED` | Assignment owner (teacher) | Student submits attempt |
| `EXAM_RESULTS_RELEASED` | Student | Results released (`releaseResults` or auto `after_submit`) |

Legacy types unchanged: `COMMENT_REPLY`, `COMMENT_REACTION`, `DAILY_REMINDER`, `SYSTEM_ANNOUNCEMENT`.

## Payload (`data`)

Flexible object (MongoDB `Mixed`). Common fields:

```json
{
  "classroomId": "ObjectId string",
  "assignmentId": "ObjectId string",
  "attemptId": "ObjectId string",
  "sessionId": "ObjectId string",
  "examTitle": "Midterm Reading",
  "classroomName": "Lớp 10A",
  "studentName": "Nguyễn Văn A"
}
```

Flutter navigation uses `type` on the notification entity (top-level), not only inside `data`.

## Deep links (Flutter)

| Type | Route |
|------|-------|
| `EXAM_ASSIGNED`, `EXAM_ASSIGNMENT_*` | `StudentClassroomDetailPage` `/student/classroom/:classroomId` |
| `EXAM_RESULTS_RELEASED` | `ExamRunnerPage` `/student/exam-run/:attemptId` |
| `EXAM_SESSION_LIVE` | `ExamSessionLobbyPage` `/student/exam-session/:sessionId` |
| `CLASSROOM_JOIN_APPROVED` | `MyClassesHubPage` or classroom detail |
| `CLASSROOM_JOIN_REQUEST`, `EXAM_SUBMISSION_RECEIVED` | `TeacherClassroomDetailPage` or `TeacherExamGradingPage` |

Handler: `lib/core/notification/notification_navigation.dart`.

## Backend hooks

| Service | Method | Notification |
|---------|--------|--------------|
| `teacherExamAssignmentService` | `create` | `EXAM_ASSIGNED` (classroom audience) |
| `teacherExamAssignmentService` | `patchAssignment` | `EXAM_ASSIGNMENT_UPDATED` |
| `teacherExamAssignmentService` | `closeAssignment` | `EXAM_ASSIGNMENT_CLOSED` |
| `examAttemptService` | `afterAttemptActivity` | `EXAM_SUBMISSION_RECEIVED`, `EXAM_RESULTS_RELEASED` (if auto-release) |
| `examGradingService` | `releaseResults` | `EXAM_RESULTS_RELEASED` (if newly released) |
| `examSessionService` | `startSession` | `EXAM_SESSION_LIVE` |
| `classroomService` | `approveMember` / `rejectMember` | `CLASSROOM_JOIN_APPROVED` / `REJECTED` |

Helper: `src/services/teacherNotificationHelper.js`.

## Testing (HoangDong seed)

1. Login teacher `hoangdong.teacher@e4c.dev` / `Teacher@123456`.
2. Create or duplicate a classroom assignment → login student `seed.hd.student01@e4c.dev` → open Notifications on Home.
3. Student submits exam → teacher sees `EXAM_SUBMISSION_RECEIVED`.
4. Teacher **Release results** (or practice/auto policy) → student sees `EXAM_RESULTS_RELEASED`; tap opens exam run view.
5. Approve pending join → student sees `CLASSROOM_JOIN_APPROVED`.

Ensure `MONGO_URI` points to the same DB as the running API (`localhost:3000` or Render).

## Out of scope (P1+)

- Due-date cron reminders
- Notification preferences per user
- Batching/digest (“3 new assignments”)
- Co-teacher fan-out
