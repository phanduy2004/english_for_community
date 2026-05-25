# 16 — Teacher live session: participant status (Session control + Live monitor)

> **Màn:** `TeacherExamSessionConsolePage` — tab **Session control** và **Live monitor**.  
> **Mục tiêu:** Giáo viên nhìn **một dòng** biết học sinh đang **chờ / sẵn sàng / đang làm / đã nộp** — cùng một component, cùng màu & copy trên **cả hai tab**.

**Liên quan:** [`13-teacher-live-session-console-layout.md`](13-teacher-live-session-console-layout.md), [`08-web-screens.md`](08-web-screens.md) §8, [`07-web-components.md`](07-web-components.md) §8.

---

## 1. Vấn đề hiện tại

| Tab | Hiện trạng | Thiếu |
|-----|------------|-------|
| **Session control** | Lobby: chip Ready / Not ready. Khi **Exam in progress**: chỉ tên + email + nút Kick — **không** có “đang làm” vs “đã nộp”. | Trạng thái làm bài khi phiên **live** |
| **Live monitor** | Progress % + caption “Submitted” hoặc `answered/total`; filter chip toolbar | **Chip trạng thái** thống nhất với Session control; dễ lướt mắt |

**Nguyên tắc:** Một học sinh = một **trạng thái chính** (primary status). Cảnh báo toàn vẹn (integrity) là **lớp phụ**, không thay thế trạng thái làm bài.

---

## 2. Component: `TeacherExamParticipantStatusChip`

### 2.1 Vai trò

- Hiển thị **trạng thái nghiệp vụ** của học sinh trong phiên thi.
- Dùng **cùng widget** trong:
  - `_participantTile` (Session control → roster)
  - `_StudentMonitorTile` (Live monitor → list card)
- Map từ payload server → enum UI (không hardcode text trong widget).

### 2.2 Anatomy

```
┌─────────────────────────────┐
│ ●  In progress              │  ← optional dot 6dp + label 11/600
└─────────────────────────────┘
```

| Thuộc tính | Token / spec |
|------------|----------------|
| Padding | `8×4` ngang-dọc |
| Radius | `AppRadius.chip` (6) |
| Font | `ExamSystemUi.captionMuted` → 11px, `fontWeight: w600` |
| Border | 1px, alpha 0.35–0.45 của màu semantic |
| Background | semantic bg 12% alpha (giống status pill mobile `04` §5.3) |
| Dot (optional) | 6×6 tròn, cùng màu fg semantic |

### 2.3 API (Flutter đề xuất)

```dart
enum TeacherExamParticipantStatus {
  notReady,      // lobby
  ready,         // lobby
  inProgress,    // live — attempt in_progress
  submitted,     // live — attempt submitted
  expired,       // live — hết giờ / auto-submit
  voided,        // kicked / void
}

class TeacherExamParticipantStatusChip extends StatelessWidget {
  const TeacherExamParticipantStatusChip({
    required this.status,
    this.showDot = true,
    this.compact = true,
  });

  final TeacherExamParticipantStatus status;
  final bool showDot;
  final bool compact;
}
```

**Factory từ JSON (gợi ý):**

| `session.status` | Fields | → `TeacherExamParticipantStatus` |
|------------------|--------|----------------------------------|
| `lobby` | `ready == true` | `ready` |
| `lobby` | `ready == false` | `notReady` |
| `live` / `ended` | `attempt.status` hoặc monitor `status` | xem bảng §3 |

---

## 3. Ma trận trạng thái (server → UI)

### 3.1 Giai đoạn **Lobby** (`session.status == lobby`)

| UI status | Điều kiện (participant) | Label EN | Label VI |
|-----------|---------------------------|----------|----------|
| `notReady` | `ready != true` | Not ready | Chưa sẵn sàng |
| `ready` | `ready == true` | Ready | Sẵn sàng |

**Nguồn:** `exam_session_state.participants[]` — `ready` từ `readyUserIds` (Socket + GET lobby).

**Session control — dòng phụ (optional):** giữ dòng tổng `Ready: 2/5` phía trên list (đã có `examSessionReadyCount`).

### 3.2 Giai đoạn **Live** (`session.status == live`)

| UI status | Điều kiện (`ExamAttempt.status` hoặc live monitor `status`) | Label EN | Label VI |
|-----------|---------------------------------------------------------------|----------|----------|
| `inProgress` | `in_progress` | In progress | Đang làm |
| `submitted` | `submitted` | Submitted | Đã nộp |
| `expired` | `expired` | Time expired | Hết giờ |
| `voided` | `void` | Removed | Đã rời / void |

**Nguồn Live monitor:** API live monitor summary + từng student `status`.  
**Nguồn Session control (bổ sung):** merge participant với attempt snapshot khi live (cùng field `status`).

### 3.3 Giai đoạn **Ended** (`session.status == ended`)

- Chip **đóng băng** trạng thái cuối (`submitted` / `expired` / `voided`).
- Không hiện `inProgress` (không còn ai “đang làm” trên server).
- Kick **ẩn**; Watch **ẩn** trừ khi còn attempt để xem (tùy product).

### 3.4 Màu semantic (web teacher)

| Status | fg | bg | border |
|--------|-----|-----|--------|
| `notReady` | `textMuted` | `surfaceSubtle` | `outlineMuted` |
| `ready` | `primaryDark` | `primaryTint` | `primary` @ 40% |
| `inProgress` | `info` hoặc `#1D4ED8` | `infoBg` | `info` @ 35% |
| `submitted` | `success` | `successBg` | `success` @ 35% |
| `expired` | `warning` | `warningBg` | `warning` @ 35% |
| `voided` | `danger` | `dangerBg` | `danger` @ 35% |

> Không dùng teal brand. Integrity **high/medium** giữ icon `flag` riêng (đã có Live monitor).

---

## 4. Hàng học sinh thống nhất (cả 2 tab)

### 4.1 Layout một dòng

```
┌──────────────────────────────────────────────────────────────────┐
│ (○)  Nguyễn Minh An          [In progress]   👁  ⊖              │
│      seed.hd.student01@…     3/12 · 25%                          │
└──────────────────────────────────────────────────────────────────┘
```

| Vùng | Session control (lobby) | Session control (live) | Live monitor |
|------|-------------------------|------------------------|--------------|
| Avatar | 36dp circle, chữ cái | 36dp | 28–36dp (compact card) |
| Tên | 13/600 `textPrimary` | 13/600 | 13/600 |
| Phụ | email 12 `textMuted` | email hoặc **progress** 11px | progress 11px hoặc “Submitted” |
| **Status chip** | Ready / Not ready | **In progress / Submitted / …** | **Cùng chip** |
| Actions | Kick (lobby) | Kick (in progress only) | Watch + Kick (in progress) + Flag |

### 4.2 Thứ tự ưu tiên khi render

1. `TeacherExamParticipantStatusChip` — luôn hiện (trừ loading skeleton).
2. Dòng phụ: progress **chỉ khi** `inProgress`; “Submitted at …” optional v1.1.
3. Integrity flag **không** đổi màu chip chính.

---

## 5. Toolbar tóm tắt (cả 2 tab khi live)

Khi `session.status == live`, **cả hai tab** nên có **cùng một dòng KPI** (copy đã có `teacherLiveMonitorSummaryLine`):

```
1 in progress · 0 submitted · 0 flagged · avg 25%
```

| Tab | Vị trí |
|-----|--------|
| **Live monitor** | Toolbar cố định ~56px (đã spec `13` §2) + filter chips |
| **Session control** | **Ngay dưới** `TeacherExamSessionCompactStrip`, **trên** roster title — cùng style, không filter (hoặc filter optional v1.1) |

**Lý do:** GV ở tab Session control vẫn thấy tổng quan trước khi scroll roster, không phải chuyển sang Live monitor.

---

## 6. Tab **Session control** — spec chi tiết

### 6.1 Lobby

- Title: `Students in lobby` + `Joined: N`.
- Mỗi row: **Status chip** `Ready` / `Not ready` (thay container custom hiện tại → gọi `TeacherExamParticipantStatusChip`).
- Kick: hiện khi lobby (đã có).

### 6.2 Live (Exam in progress) — **bổ sung mới**

- Title đổi copy (l10n mới): `Students in exam` / `Học sinh trong bài thi` (hoặc giữ “Students in lobby” + subtitle “During live session”).
- **Summary line** (§5).
- Mỗi row:
  - **Bắt buộc:** `TeacherExamParticipantStatusChip` từ attempt/monitor status.
  - **Khuyến nghị:** mini progress bar 4px + `answered/total` khi `inProgress` (reuse logic Live monitor, compact).
  - Kick: chỉ `inProgress` (giống Live monitor).
- **Không** hiện Ready/Not ready khi đã live.

### 6.3 Realtime

- Cập nhật qua Socket `exam_session_state` + refresh live monitor API khi cần.
- Khi HS submit → chip đổi `In progress` → `Submitted` **không cần reload trang** (patch list).

---

## 7. Tab **Live monitor** — spec chi tiết

### 7.1 Giữ toolbar + filter

- Filter: All · In progress · Submitted · Flagged (đã có).
- Summary line đếm khớp chip (server summary).

### 7.2 Thẻ học sinh

- Header row: tên + **Status chip** (bên phải tên, trước icon flag/watch).
- Bỏ caption chữ “Submitted” trùng — chip đã đủ; dòng dưới chỉ còn **progress** khi `inProgress`.
- Progress bar 4px giữ nguyên (`13` §4).

**Trước / sau (ý tưởng):**

| Trước | Sau |
|-------|-----|
| Chỉ text `Submitted` hoặc `3/12 · 25%` | Chip **Submitted** + (optional) `3/12 · 25%` |

---

## 8. Empty & edge cases

| Tình huống | UI |
|------------|-----|
| Chưa có HS | `No students in the lobby yet.` |
| Live nhưng chưa có attempt | Chip `In progress` sau khi GV Start; nếu HS join muộn → cập nhật khi có attempt |
| HS bị kick | Chip → `Removed` (`voided`), row có thể ẩn hoặc grey-out (product: **ẩn khỏi list** sau kick) |
| Mất socket | Banner warning + nút Retry; chip giữ state cuối + stale indicator optional |

---

## 9. Accessibility

- Chip có `Semantics(label: …)` = full status text (VI/EN).
- Dot không là sole indicator — luôn có text.
- Màu kèm text — đạt `10-accessibility` contrast cho 11px trên bg tint.

---

## 10. L10n (keys đề xuất)

| Key | EN | VI |
|-----|----|----|
| `teacherExamParticipantNotReady` | Not ready | Chưa sẵn sàng |
| `teacherExamParticipantReady` | Ready | Sẵn sàng |
| `teacherExamParticipantInProgress` | In progress | Đang làm |
| `teacherExamParticipantSubmitted` | Submitted | Đã nộp |
| `teacherExamParticipantExpired` | Time expired | Hết giờ |
| `teacherExamParticipantVoided` | Removed | Đã rời |
| `teacherExamSessionLiveRosterTitleLive` | Students in exam | Học sinh trong bài thi |

*(Có thể alias `examSessionStudentReady` → chip factory để tránh trùng.)*

---

## 11. Code map & implementation order

| Hạng mục | File |
|----------|------|
| **Component mới** | `lib/feature/teacher/widgets/teacher_exam_participant_status_chip.dart` |
| Session control roster | `teacher_exam_session_console_page.dart` — `_participantTile` |
| Live monitor card | `widgets/teacher_live_monitor_panel.dart` — `_StudentMonitorTile` |
| Live summary (control tab) | `teacher_exam_session_console_page.dart` — `_rosterSection` khi `_isLive` |
| Data merge live roster | BE: participants + attempt status trong `exam_session_state` khi live; hoặc FE gọi chung live monitor API |

**PR gợi ý:**

1. Component + l10n + map lobby (refactor chip sẵn có).
2. Live monitor: thêm chip vào card.
3. Session control live: merge status + summary line.
4. Socket patch list (optional, cùng live monitor bloc).

---

## 12. Acceptance checklist

- [ ] Cùng `TeacherExamParticipantStatusChip` trên **Session control** và **Live monitor**.
- [ ] Lobby: Ready / Not ready; Live: In progress / Submitted / Expired / Removed.
- [ ] Khi live, Session control có **summary line** giống Live monitor.
- [ ] Submit realtime → chip đổi trên cả hai tab (cùng nguồn event).
- [ ] Không hardcode hex trong feature — dùng `AppColors.*` semantic.
- [ ] EN + VI qua `AppLocalizations`.

---

*Cập nhật: 2026-05-23 — spec participant status cho live session console.*
