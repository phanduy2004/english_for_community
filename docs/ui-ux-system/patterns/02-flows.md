# 02 — Flow blueprints (chuỗi màn)

> Pattern cho **chuỗi nhiều màn** (flow), không phải 1 màn lẻ. Mỗi flow: **các bước · transition · giữ state · progress · interrupt/exit · reference apps · build with**.
> Bổ trợ [`01-screen-archetypes`](01-screen-archetypes.md) (màn lẻ) và `05-mobile-screens` (spec màn thật). Mọi token theo [`02-design-tokens`](../02-design-tokens.md); motion theo `app_motion.dart` + reduce-motion (`20`).

**Nguyên tắc flow chung (Editorial Black):**
- **1 quyết định / màn** ở flow nhập liệu (onboarding/exam-setup) — như Duolingo intake.
- **Progress luôn nhìn thấy** (dots/bar/step "3/12") khi flow > 2 bước.
- **Giữ ngữ cảnh khi chuyển**: transition `slide`/`fade` nhẹ (`AppMotion.base`), không cắt cảnh thô.
- **Interrupt an toàn**: flow có dữ liệu chưa lưu → `runnerPopScope` + confirm (`20` §5.8).
- **Server là sự thật**: mỗi bước phản ánh state từ API/socket; resume đúng chỗ khi quay lại.

---

## F1 · Auth + Onboarding

**Reference apps:** Duolingo (intake từng bước), Headway (goal → level → plan), Linear (auth tối giản).

### Chuỗi màn
```
Splash ─▶ [chưa đăng nhập] ─▶ Login ──┬─▶ (success) ─▶ Home
                                       ├─▶ Register ─▶ OTP verify ─▶ Onboarding ─▶ Home
                                       └─▶ Quên MK ─▶ OTP ─▶ Reset ─▶ Login
Onboarding (user mới):  Goal ─▶ Level (CEFR) ─▶ Daily goal ─▶ Reminder ─▶ (done) Home
```

### Bước & rule
| Bước | Archetype | Ghi chú |
|------|-----------|---------|
| Login | A10 | input inline-validate, error **dưới field** (không dialog); primary đen; social phụ |
| Register → OTP | A10 | OTP 4–6 ô auto-advance, resend countdown; TTL khớp backend (10') |
| Onboarding | A10 (chuỗi) | **1 câu hỏi/màn** + progress dots + bottom CTA; chọn = `mcqOption`-like |
| Resume | — | đang onboarding mà thoát → quay lại đúng bước (lưu state) |

### Transition / progress
- Giữa các bước onboarding: `slide` ngang (`AppMotion.base`), progress dots cập nhật.
- Map field onboarding → `User`: `goal`, `cefr`, `dailyLessonGoal`/`dailyMinutes`, `reminder{hour,minute}`, `timezone`.

### Interrupt
- Onboarding: cho **Bỏ qua** (skip) → set default, không chặn vào app.
- Auth: lỗi mạng → inline retry, không mất dữ liệu đã nhập.

### Build with
`FilledButton`(primary), input `04` §4, `mcqOption`, `bottomActionBar`, progress dots (custom nhỏ).

### Don't
- Đừng hỏi >1 thứ/màn ở onboarding. Đừng để lỗi auth dạng dialog chặn. Đừng bắt onboarding bắt buộc 100% (cho skip).

---

## F2 · Lesson / Runner (làm 1 bài kỹ năng)

**Reference apps:** Duolingo (lesson), Quizlet (study), Headway (reader→quiz).

### Chuỗi màn
```
Hub (A2) ─▶ [tap bài] ─▶ (tùy) Detail/Reader (A4) ─▶ Runner (A3) ─▶ Result/Celebrate (A11)
                                                         │  ▲
                                                  (Tiếp/Quay lại giữa câu — pager)
Result ──┬─▶ [Bài tiếp] ─▶ Runner bài kế
         └─▶ [Xem lại] ─▶ Runner review-mode
```

### Bước & rule
| Bước | Archetype | Ghi chú |
|------|-----------|---------|
| Vào bài | A2→A3 | transition `sharedAxis`/slide; prefetch nội dung (như chat prefetch) |
| Làm bài | A3 | pager swipe giữa câu; `mcqPagerHeader` progress; CTA dưới |
| Nộp | A3 | CTA loading → chấm → A11 |
| Celebrate | A11 | KPI amber, streak; 2 CTA (next/review); reduce-motion fallback |

### Giữ state / progress
- Progress "3/12" + thanh mảnh suốt runner.
- Thoát giữa chừng (`in_progress`) → `runnerPopScope(blockExit:true)` + confirm; lưu nháp nếu backend hỗ trợ.
- Continue card ở Home (A1) đọc bài dở → vào đúng câu.

### Build with
`mcqPagerHeader/mcqQuestionPager/mcqOption`, `bottomActionBar`, `runnerPopScope`, celebrate (`AppLottieView`), `statCard`, `streakChip`.

### Don't
- Đừng cho thoát không confirm khi đang làm. Đừng nhồi nhiều CTA. Đừng để celebrate chặn lâu.

---

## F3 · Exam / Live session (thi nhiều kỹ năng, realtime)

**Reference apps:** thi/quiz realtime (Kahoot lobby), Duolingo timed; baseline iOS modal flow.

### Chuỗi màn
```
Assignment (A2) ─▶ Lobby (chờ/ready) ─▶ Countdown ─▶ Exam runner (A3, đa section) ─▶ Auto-submit ─▶ Chờ chấm ─▶ Kết quả (A11/A12)
        socket: join_exam_session → ready check → start → state_broadcast → submit
```

### Bước & rule
| Bước | Archetype | Ghi chú |
|------|-----------|---------|
| Lobby | A8-ish | hiện trạng thái phòng + nút **Sẵn sàng**; chờ GV start |
| Countdown | overlay | đếm ngược rõ; không cho thao tác |
| Exam runner | A3 (đa section) | timer toàn bài; chuyển section listening/reading/writing; tích hợp integrity |
| Auto-submit | A3 | hết giờ → nộp tự động (không mất bài); báo rõ |
| Kết quả | A11/A12 | có thể **chờ GV release** mới hiện điểm → state "đang chấm" |

### Realtime / state
- Mọi bước phản ánh `exam_session_state_broadcast` (server là sự thật).
- Mất kết nối → banner "đang kết nối lại", giữ bài; reconnect → resume đúng state.
- "Chờ chấm/đợi release" = state hợp lệ, không phải lỗi (UI phân biệt với error).

### Build with
A3 runner + timer; socket service; `AppFeedback.banner` cho trạng thái realtime; A11/A12 cho kết quả.

### Don't
- Đừng để mất bài khi mất mạng/đóng app (server-authoritative + resume). Đừng hiện điểm trước khi release. Đừng cho thoát giữa exam không cảnh báo.

---

## F4 · Chat (mở & nhắn trong nhóm lớp)

**Reference apps:** Telegram, Messenger, Slack.

### Chuỗi màn
```
Messages (A5) ─▶ [tap hội thoại] ─▶ Chat thread (A6) ─▶ (tap header) Settings sheet
   inbox socket ──▶ tin mới đẩy lên đầu list (recency) + badge unread
```

### Bước & rule
| Bước | Archetype | Ghi chú |
|------|-----------|---------|
| Mở hội thoại | A5→A6 | prefetch session (đã có `ClassroomChatSessionCache.prefetch`); mark-read |
| Thread | A6 | reverse list (tin mới ở đáy); nạp tin cũ ở đỉnh |
| Gửi | A6 | optimistic; upload có progress; reply/mention |
| Settings | sheet | tap header → `ChatSettingsSheet` |

### State liên tục
- Vào thread → mark conversation read → badge inbox giảm (rebuild chọn lọc `ListenableBuilder`, không rebuild cả trang — `22`/`23`).
- Quay lại Messages → list giữ recency (hội thoại vừa nhắn lên đầu, animation mượt).

### Build with
`ConversationTile` (A5) → `ClassroomChatPage`/`ClassroomChatBody` (A6) → `ChatInputBar`, `ChatSettingsSheet`, inbox socket.

### Don't
- Đừng để vào thread không thấy ngay tin mới nhất (reverse list). Đừng rebuild cả inbox mỗi tick socket. Đừng quên mark-read.

---

## Bảng tra flow → archetype → feature

| Flow | Archetype chuỗi | Feature code |
|------|-----------------|--------------|
| F1 Auth/Onboarding | A10 | `feature/auth/*` |
| F2 Lesson/Runner | A2→A4→A3→A11 | skill features + runner |
| F3 Exam/Live | A2→A3→A11/A12 | exam features + socket |
| F4 Chat | A5→A6 | `feature/classroom_chat/*`, `feature/student/messages/*` |

> Khi dựng/đổi 1 flow → ghi vào [`../11-implementation-mapping.md`](../11-implementation-mapping.md) "Migration log".
