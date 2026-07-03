# Work-order — BUG · Daily Reminder / Learning Preferences notifications

**Task ID:** 20260702-daily-reminder-notification · **Loại:** BUG · **Platform:** full-stack (student mobile + backend)
**Ngày:** 2026-07-02 · **Vai:** Opus AUDIT (Phase 1–2). Chưa implement — chờ quyết định thiết kế ở mục 3.

**Mục tiêu:** Xác định cụm *Daily Reminder / Reminder Time* (và Daily Time/Lesson Goal) trong "Learning Preferences" có hoạt động đúng chức năng thông báo trên máy user không, liệt kê bug.

**Kỳ vọng đầu ra (audit):** Bản đồ luồng end-to-end + danh sách bug có dẫn chứng `file:line` + hướng fix. (Implement để phase sau, sau khi user chốt mục 3.)

---

## 0. TL;DR (kết luận nhanh)

Cụm này **CÓ nối tới thông báo thật** (không phải nút chết), nhưng **không hoạt động đúng như nhãn "Daily Reminder"** và có **nhiều bug**:

- Toggle ON/OFF và lưu giờ lên server: **OK** (persist đúng, toggle OFF phản ánh đúng).
- Nhưng "Daily Reminder" **thực chất là "nhắc 3 từ vựng recent"**, không phải nhắc học chung chung. User không tra từ điển gần đây → BẬT reminder nhưng **không có thông báo nào**.
- **Đổi Reminder Time không reschedule** local notification → giờ mới chỉ áp dụng sau khi **kill/mở lại app**.
- **Bắn trùng**: cùng một mốc giờ, **local (device) + server (FCM) cùng bắn** ~3 từ → user nhận tới ~6 thông báo, nội dung lệch nhau (EN vs VI, từ cũ vs từ mới).
- Backend còn **giờ test hardcode** cho Progress Nudge (23:12) và Streak Rescue (23:14).

Chi tiết + dẫn chứng bên dưới.

---

## 1. Luồng end-to-end (ground-truth)

Có **HAI** cơ chế cùng lấy mốc từ `user.reminder`, chạy song song, không biết đến nhau:

### A. Local notification (device) — Flutter
1. `main.dart:48` → `LocalNotificationService().init()` (timezone + plugin).
2. Mở Home → `home_page.dart:103 initState` → `addPostFrameCallback` (dòng 108):
   - `_initializeLocalNotifications()` (`:178`) → `requestPermissions()` (POST_NOTIFICATIONS + SCHEDULE_EXACT_ALARM) → `_syncDailyReminders()`.
   - `_syncDailyReminders()` (`:183`): đọc `user.reminder` từ `UserBloc`. Nếu null → `cancelAll()`. Nếu có → gọi `vocabRepo.getDailyReminders()` → nếu list **không rỗng** → `scheduleDailyWordSequence(words, time: user.reminder!)`.
3. `local_notification_service.dart:147 scheduleDailyWordSequence`: `cancelAll()` rồi `zonedSchedule` mỗi từ, id `i+1000`, cách nhau 1 phút, `matchDateTimeComponents: DateTimeComponents.time` (**lặp lại hằng ngày**), mode `exactAllowWhileIdle`. Title `"Daily Vocab (i/N) 🔔"`.

### B. Server push (FCM) — backend cron
1. `smartNotificationJob.js:178` `cron.schedule('* * * * *')` — **mỗi phút**, quét mọi user có `fcmTokens`.
2. Với mỗi user: `getUserTime(user.timezone)`; nếu `hour === user.reminder.hour && minute === user.reminder.minute` (dòng 188-189) → `triggerDailyVocabSequence(user)`.
3. `triggerDailyVocabSequence` (`:66`) → `vocabService.getDailyReminderWords(user._id)`; nếu rỗng → return; nếu có → gửi từng từ qua FCM, cách nhau **20s** (`setTimeout`). Title `"Từ vựng mỗi ngày (i/N) ⏰"`.

### Nguồn từ vựng (cả A và B dùng CHUNG)
`vocabularyService.js:174 getDailyReminderWords`: `Word.find({ user, status: 'recent' }).sort({updatedAt:-1}).limit(3)` — **3 từ tra gần nhất**, đồng thời ghi `lastRemindedDate`. Client `getDailyReminders()` → `GET /vocab/daily-reminders` (`vocabRoutes.js:18` → `vocabController.getDailyReminders`) → cùng logic.

### Lưu trữ setting (OK)
- UI: `profile_page.dart:343-369` (toggle Switch + Reminder Time), `_showTimePicker` (`:242`), `_quickUpdateProfile` (`:94`) → chỉ dispatch `UpdateProfileEvent` → `UserBloc` → `PUT users/profile`.
- Model client: `user_entity.dart:62 reminder: TimeOfDay?` + `TimeOfDayConverter` (`:5-30`). Toggle ON/OFF là **derived state**: `reminder != null` = ON.
- Backend model: `User.js:33-36 reminder: { hour, minute }` (không có field `enabled`). Parse: `userController.js:227-242` (`'null'` → null để xóa; JSON string → object).

---

## 2. Danh sách BUG (có dẫn chứng)

### 🔴 BUG-1 — Đổi Reminder Time KHÔNG reschedule local notification (High)
`_syncDailyReminders` chỉ được gọi từ `_initializeLocalNotifications`, mà hàm này **chỉ chạy trong `home_page.dart:110 initState`** (grep toàn repo: không có caller nào khác, không có `didChangeAppLifecycleState` re-sync cho reminder). Profile là **tab trong Home** (`_tab`/`_selectTab`), đổi giờ trong tab **không** re-init Home.
→ User đổi giờ (vd 20:10 → 21:00): server cập nhật đúng, nhưng **local schedule vẫn giữ giờ cũ** cho tới lần **cold start / re-login** kế tiếp. Local và server sẽ bắn **hai giờ khác nhau**.
*Bằng chứng:* `home_page.dart:108-114, 178-222`; `profile_page.dart:259-261` (chỉ `_quickUpdateProfile`, không reschedule).

### 🔴 BUG-2 — "Daily Reminder" chỉ chạy khi có ≤3 từ `status:'recent'` (High / mislabel)
Cả local (`_syncDailyReminders:210` `if (words.isNotEmpty)`) lẫn server (`smartNotificationJob.js:69` `if (!words || words.length === 0) return`) đều phụ thuộc `getDailyReminderWords` (`vocabularyService.js:177-182`, `status:'recent'`, limit 3).
→ User bật "Daily Reminder" nhưng **chưa tra từ điển gần đây** (từ `recent`) → **không có thông báo nào**, dù toggle hiển thị ON. Nhãn UI "Daily Reminder / Nhắc nhở hàng ngày" gợi ý nhắc học chung, nhưng thực chất là "ôn 3 từ recent". **Sai kỳ vọng người dùng.**

### 🔴 BUG-3 — Bắn trùng thông báo (local + server) (High UX)
Cùng mốc `reminder`, local (device, lặp `DateTimeComponents.time`) và server (FCM, cron mỗi phút match) **cùng kích hoạt** trên cùng danh sách "3 từ recent".
→ User nhận **tới ~6 thông báo** quanh cùng thời điểm: 3 local (`"Daily Vocab (i/3) 🔔"`, EN) + 3 server (`"Từ vựng mỗi ngày (i/3) ⏰"`, VI). (FCM foreground bị suppress ở `home_page.dart:167-174`, nhưng **background/terminated vẫn hiện** — đúng lúc reminder thường app không mở.)

### 🟠 BUG-4 — Nội dung local bị stale/lặp lại (Medium)
`matchDateTimeComponents: DateTimeComponents.time` (`local_notification_service.dart:206`) khiến local **lặp đúng 3 từ đã cache** ở lần mở Home gần nhất, **mỗi ngày**, cho tới khi user mở lại Home. Server thì gửi 3 từ mới mỗi ngày → nội dung hai bên lệch nhau; local có thể nhắc từ đã học xong từ lâu.

### 🟠 BUG-5 — Nhánh không có từ (online) không `cancelAll()` (Medium)
`_syncDailyReminders` nhánh success khi `words.isEmpty` **không hủy** lịch cũ (chỉ nhánh `user.reminder == null` mới `cancelAll`). → Nếu hôm nay không còn từ recent, **lịch local cũ (lặp) vẫn bắn từ ngày trước**.
*Bằng chứng:* `home_page.dart:209-220` (không có `else`/cancel).

### 🟠 BUG-6 — Backend còn GIỜ TEST hardcode (Medium)
`smartNotificationJob.js`:
- `:200` Progress Nudge: `if (hour === 23 && minute === 12)` — comment ghi ý định "20:00 … đang set phút 8 để test".
- `:205` Streak Rescue: `if (hour === 23 && minute === 14)` — comment ghi "22:00".
- `:195` Review Reminder: hardcode `19:00`, không theo pref user.
→ Các thông báo này bắn **sai giờ** (giờ test còn sót trong code).

### 🟡 BUG-7 — Lệch timezone local vs server (Low)
Local dùng device tz (`FlutterTimezone.getLocalTimezone`, fallback Asia/Ho_Chi_Minh — `local_notification_service.dart:32-38`); server dùng `user.timezone` (fallback Asia/Ho_Chi_Minh — `smartNotificationJob.js:185`). Nếu hai giá trị khác nhau → hai bên bắn lệch giờ.

### 🟡 BUG-8 — Race khi first-login (Low)
`_syncDailyReminders:184-185` đọc `UserBloc.state` ngay sau khi dispatch `GetProfileEvent` (`home_page.dart:109`). Nếu profile chưa load xong (`status != success`) → return, **bỏ qua lịch** lần đó (đợi tới lần Home init sau).

### 🟡 BUG-9 — Perf backend + side-effect trên read (Low/Perf)
- Cron `* * * * *` quét **toàn bộ** user có `fcmTokens` mỗi phút; tại mốc reminder còn `getDailyReminderWords` (find + `updateMany`) per-user → burst khi scale.
- `getDailyReminderWords` **ghi `lastRemindedDate` mỗi lần client gọi** `getDailyReminders` (mỗi lần mở Home), dù không thực sự "nhắc".

### 🟡 BUG-10 — Field/permission thừa (Low)
- `smartNotificationJob.js:188` kiểm tra `user.reminder?.enabled !== false` nhưng schema/app **không hề có** `enabled` → dead check; không hỗ trợ tách enable/disable độc lập với hour.
- AndroidManifest có `SCHEDULE_EXACT_ALARM` nhưng **thiếu `USE_EXACT_ALARM`**; phụ thuộc `requestExactAlarmsPermission()` (Android 14) — nếu user từ chối, `exactAllowWhileIdle` có thể lệch giờ.

### Ghi chú — Daily Time Goal / Daily Lesson Goal
Không phải "thông báo": chỉ là preference lưu server. `dailyLessonGoal` **có** dùng cho Progress Nudge (`smartNotificationJob.js:112`), nhưng nudge đang dính BUG-6 (bắn 23:12). `dailyMinutes` (Daily Time Goal) **không** kích hoạt thông báo nào.

---

## 3. ✅ QUYẾT ĐỊNH THIẾT KẾ (user chốt 2026-07-02)

**CHỌN: Server-only + nhắc chung** (Hướng 1 gộp Hướng 2).

- **Nguồn bắn duy nhất = backend FCM** (`smartNotificationJob`). **Bỏ local schedule** ở Flutter.
- Tại mốc `reminder`, backend bắn **ĐÚNG 1 thông báo** "Đến giờ học rồi 👋" **kể cả khi không có từ recent**; nếu có từ recent thì dùng làm **nội dung phụ** (không bắn chuỗi 3 thông báo cách 20s như hiện tại).
- Client khi init phải `cancelAll()` để **dọn lịch local cũ** (user đã cài bản trước có lịch lặp `DateTimeComponents.time` sẽ bắn mãi).

Hệ quả: sửa được BUG-1 (đổi giờ có hiệu lực ngay vì server đọc DB trực tiếp), BUG-2 (luôn có nhắc), BUG-3 (hết trùng), BUG-4/5 (không còn local stale). Gộp thêm fix BUG-6 (giờ test).

---

## 4. Hướng fix (intent-level — theo quyết định "Server-only + nhắc chung")

> Cursor TỰ viết code theo ý định + ràng buộc dưới đây. Opus không dán full code.

| # | File | Ý định | Ràng buộc / nghiệm thu |
|---|------|--------|------------------------|
| **F1** | `home_page.dart:183-222` `_syncDailyReminders` | **Bỏ toàn bộ nhánh schedule local**: không gọi `getDailyReminders()`, không `scheduleDailyWordSequence`, bỏ cache `CACHED_DAILY_WORDS`. Thay bằng: **luôn** `await LocalNotificationService().cancelAll();` (dọn lịch local cũ trên máy user đã cài bản trước). | Sau init, KHÔNG còn pending local vocab schedule. Không crash khi `userEntity` null. |
| **F2** | `local_notification_service.dart:147-210` | `scheduleDailyWordSequence` trở thành dead code → **xóa** (hoặc để lại nhưng không caller). Giữ `init()`, `showInstantNotification()`, `cancelAll()`, `requestPermissions()`. | `flutter analyze` 0 warning về unused. `cancelAll` chỉ hủy pending scheduled, KHÔNG ảnh hưởng `.show` social. |
| **F3** | `smartNotificationJob.js:66-81 triggerDailyVocabSequence` | Đổi thành bắn **ĐÚNG 1 push** tại mốc reminder: lấy tối đa 3 từ recent; **có từ** → title `"Đến giờ học rồi 👋"`, body dạng "Ôn lại: w1, w2, w3 + vào học nhé"; **không có từ** → body nhắc chung "Đã đến giờ học tiếng Anh của bạn. Vào luyện tập ngay!". Dùng `sendPush`-style (1 FCM + 1 record DB, `skipSocket/skipFCM` như hiện có). Bỏ vòng `setTimeout` 20s. | Chỉ 1 thông báo/ngày/ user. `type` giữ điều hướng được (vd `DAILY_REMINDER`, data có `wordId` nếu có để tap mở vocab). |
| **F4** | `smartNotificationJob.js:188` | Bỏ dead check `user.reminder?.enabled !== false` (schema không có `enabled`); giữ guard `user.reminder?.hour != null`. | Toggle OFF (reminder null) → không bắn. |
| **F5** | `smartNotificationJob.js:200,205` | Sửa giờ test hardcode: Progress Nudge `23:12` → **20:00**, Streak Rescue `23:14` → **22:00** (theo comment ý định). ⚠️ Xác nhận lại giờ mong muốn nếu khác. | Không còn `minute === 12/14` test. |
| **F6** (tùy chọn) | `vocabularyService.js:184-191` | Client không còn gọi `getDailyReminders` (đã bỏ ở F1) nên endpoint `/vocab/daily-reminders` thành orphan; side-effect ghi `lastRemindedDate` giờ chỉ xảy ra từ job (chấp nhận được — đúng lúc "đã nhắc"). Có thể để nguyên. | Không bắt buộc. |

**TUYỆT ĐỐI KHÔNG:** đổi schema `User.reminder`, đổi contract `PUT users/profile`, chạm luồng toggle/save ở `profile_page.dart` (đang đúng), đổi FCM/socket infra khác.

---

## 5. Hồi quy tối thiểu (sau khi fix)
1. Bật Daily Reminder, đặt giờ = now+2 phút, có ≥1 từ recent → nhận **đúng 1 bộ** thông báo (không trùng), đúng giờ.
2. User **không có từ recent** → theo hướng đã chọn: Hướng 1 = im lặng (chấp nhận) / Hướng 2 = vẫn có 1 nhắc chung.
3. Đổi giờ reminder → giờ mới có hiệu lực (không cần kill app nếu chọn server-only, vì server đọc DB trực tiếp).
4. Tắt Daily Reminder → không còn thông báo; lịch local cũ (nếu có) bị `cancelAll`.
5. Progress Nudge / Streak Rescue bắn đúng giờ mới (không phải 23:12/23:14).

## 6. Lệnh verify
- Flutter: `flutter analyze` (0 lỗi).
- Backend: chạy job với mốc giờ giả lập / log `📢 [type] Sent` đúng 1 lần.
- Account test: `docs/dev/seeds/` (user có/không có từ recent).

## 7. HANDOFF cho Cursor (copy-paste — biên giới cứng)

```text
Bạn là Cursor (Codex/Sonnet) = IMPLEMENT. Làm đúng work-order
docs/plantasks/BUG/20260702-daily-reminder-notification/work-order.md, mục 4. KHÔNG mở rộng scope.

QUYẾT ĐỊNH: "Server-only + nhắc chung" — backend FCM là nguồn bắn duy nhất; bỏ local schedule; luôn bắn 1 nhắc chung tại mốc reminder (vocab làm nội dung phụ nếu có).

FILE ĐƯỢC SỬA (ngoài danh sách này → DỪNG & hỏi):
1. english_for_community/lib/feature/home/home_page.dart  (F1)
2. english_for_community/lib/core/notification/local_notification_service.dart  (F2)
3. english_for_community_backend/src/jobs/smartNotificationJob.js  (F3,F4,F5)

VIỆC:
- F1: Trong _syncDailyReminders (dòng ~183-222): bỏ hết getDailyReminders()/scheduleDailyWordSequence()/CACHED_DAILY_WORDS. Thay bằng: await LocalNotificationService().cancelAll();  (dọn lịch local cũ). Vẫn giữ requestPermissions() ở _initializeLocalNotifications. Không crash nếu userEntity null.
- F2: Xóa scheduleDailyWordSequence (dead code) trong local_notification_service.dart; giữ init/showInstantNotification/cancelAll/requestPermissions.
- F3: triggerDailyVocabSequence → bắn ĐÚNG 1 FCM push tại mốc reminder. Lấy ≤3 từ recent. Có từ: title "Đến giờ học rồi 👋", body liệt kê từ; Không có từ: body nhắc học chung. Bỏ vòng setTimeout 20s. Lưu 1 record DB (skipSocket:true, skipFCM:true như sendPush hiện có). data.type điều hướng được.
- F4: bỏ check user.reminder?.enabled !== false; giữ guard user.reminder?.hour != null.
- F5: sửa giờ test: Progress Nudge 23:12 → 20:00; Streak Rescue 23:14 → 22:00.

RÀNG BUỘC:
- Backend: logic ở job/service, không đổi schema User.reminder, không đổi contract PUT users/profile.
- Không chạm profile_page.dart (toggle/save đang đúng).
- L10n: nếu thêm string UI mới thì EN+VI — nhưng ở đây text nằm trong FCM payload (server), không cần .arb.
- Không hardcode secret, không TODO/placeholder.

VERIFY trước khi báo xong:
- cd english_for_community && flutter analyze  → 0 lỗi.
- Backend: node -c src/jobs/smartNotificationJob.js (hoặc chạy server, log "📢 [DAILY_REMINDER] Sent" đúng 1 lần tại mốc giờ giả lập).
- Smoke: mục 5 work-order (1 bộ thông báo, không trùng; đổi giờ có hiệu lực; tắt = im lặng; user không có từ recent vẫn nhận nhắc chung).

Xong → SELF-AUDIT: tóm tắt DIFF có cấu trúc (file đổi · rủi ro · self-check theo checklist mục 8) → báo "implementer đã xong, audit đi".
```

### Handoff AUDIT cho Cursor (copy-paste — chạy sau khi implement xong)
```text
Bạn là Cursor = AUDIT (chấm chéo trước khi Opus phán quyết cuối). Đọc diff của 3 file ở mục 7 và chấm theo checklist mục 8 work-order 20260702-daily-reminder-notification.
Trọng tâm:
1) Không còn caller scheduleDailyWordSequence nào (grep toàn repo). Local đã cancelAll khi init.
2) Backend bắn ĐÚNG 1 push/ngày tại mốc reminder; nhánh "không có từ" vẫn bắn nhắc chung; nhánh reminder null KHÔNG bắn.
3) Không còn giờ test 23:12/23:14.
4) Không chạm schema/contract/profile_page.
5) flutter analyze 0 lỗi; server không lỗi cú pháp.
Ghi mỗi vi phạm = BLOCKER với file:line + fix. Verdict: PASS-to-Opus | CHANGES. KHÔNG tự APPROVE.
```

## 8. OPUS AUDIT checklist (Phase 4)
- [ ] Hết trùng thông báo (chỉ 1 nguồn bắn) — smoke #1.
- [ ] Đổi giờ có hiệu lực không cần kill app — smoke #3.
- [ ] Không còn giờ test hardcode — grep `23 && minute === 1`.
- [ ] Read không mutate `lastRemindedDate` (nếu chọn F4).
- [ ] `flutter analyze` 0 lỗi; backend job log đúng.
- [ ] Ngữ nghĩa khớp nhãn UI theo hướng đã chọn.
