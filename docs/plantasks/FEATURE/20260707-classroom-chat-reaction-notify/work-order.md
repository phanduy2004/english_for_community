# Work-Order — FEATURE: Notification khi thả reaction vào tin nhắn trong chat lớp học

- **Task ID:** `20260707-classroom-chat-reaction-notify`
- **Loại:** FEATURE (gap-fill: hành vi còn thiếu) · **Platform:** full-stack (backend + student mobile/teacher web) · **Cỡ:** MICRO (3 file, ~45 LOC)
- **Mục tiêu:** Khi một thành viên thả icon (❤️/👍/😂…) vào tin nhắn của bạn trong group chat lớp, **chủ tin nhắn nhận notification** (badge + in-app banner + push FCM + trong list), và tap vào mở đúng phòng chat.
- **Người phân tích:** Opus (brain). **Implementer:** Cursor/Codex. **Status:** ROOT CAUSE XÁC ĐỊNH — chờ implement.
- **Liên quan:** mẫu chuẩn `COMMENT_REACTION` (listeningController.reactToComment); hệ notification `notificationService.createNotification`.

---

## 1. Vấn đề + nguyên nhân gốc (dẫn chứng code)

**Triệu chứng:** Trong group chat lớp (ảnh user gửi), khi thành viên thả reaction (❤️/😮…) vào tin nhắn, reaction hiện realtime trên bubble NHƯNG chủ tin nhắn **không nhận notification nào** (không badge, không banner, không push).

**Root cause:** `reactMessage` chỉ broadcast socket patch UI reaction cho room chat, **không hề tạo `Notification`** (không record DB, không emit `new_notification`, không FCM). Trích `english_for_community_backend/src/services/classroomChatService.js:347-386`:

```js
export async function reactMessage(classroomId, userId, messageId, emoji) {
  await assertMember(classroomId, userId);
  if (!ALLOWED_EMOJIS.includes(emoji)) throw httpErr(400, 'Emoji không hợp lệ');
  const msg = await ClassroomMessage.findOne({ _id: messageId, classroomId });
  ...
  await msg.save();
  const payload = { messageId, classroomId, reactions: [...] };
  emitToRoom(classroomId, 'classroom_message_react_update', payload); // ← chỉ patch UI room chat
  return payload;                                                     // ← KHÔNG createNotification
}
```

Đối chiếu: luồng react-to-comment ĐÃ có notification đúng chuẩn — `english_for_community/... listeningController.js:316-338` gọi `notificationService.createNotification({ type:'COMMENT_REACTION', ... })`. Hệ notification (create record → emit `new_notification` → FCM → client badge/banner/list) đã hoạt động đầy đủ cho mọi type khác; classroom-chat-reaction chỉ đơn giản **chưa được nối vào**.

---

## 2. Audit downstream + 3. Hướng fix (gộp — MICRO)

**Thiết kế:** Clone y hệt pattern `COMMENT_REACTION`. Trong `reactMessage`, sau khi lưu + emit react, **chỉ khi là reaction MỚI** (thêm userId, không phải bỏ react) **và không tự-react** thì gọi `createNotification` với type mới `CLASSROOM_CHAT_REACTION`. Client chỉ cần thêm **1 case điều hướng** (mọi thứ badge/banner/push đã tự động qua hệ notification generic).

**3 thay đổi:**
1. `Notification.js` — thêm `'CLASSROOM_CHAT_REACTION'` vào enum `type` (append, không đổi thứ tự cũ).
2. `classroomChatService.js` — import `createNotification`; track `isNewReaction`; capture `room` từ `assertMember` (lấy tên lớp cho deep-link); tạo notification sau `emitToRoom`.
3. `notification_navigation.dart` — thêm `case 'CLASSROOM_CHAT_REACTION'` mở phòng chat (student vs teacher route).

**Audit downstream — không regression:**

| Điểm | file:line | Ảnh hưởng sau thay đổi |
|---|---|---|
| Socket react patch UI | `classroomChatService.js:384` `emitToRoom(...'classroom_message_react_update')` | KHÔNG đụng — payload/emit giữ nguyên; notification là nhánh phụ thêm sau |
| Enum `type` (consumer: mọi createNotification cũ) | `Notification.js:14-32` | Chỉ **append** value mới → validation cũ không đổi; type cũ vẫn hợp lệ |
| `navigateFromNotification` switch (4 caller) | `notification_navigation.dart:32-100` | Chỉ **thêm case mới**; case cũ nguyên vẹn; early-return `listeningId`/`wordId` không dính (payload react không chứa 2 key này) |
| `createNotification` | `notificationService.js:34-140` | Dùng như hiện có; **tự guard** self-notify (`rId===sId → null`), tự try/catch socket + FCM (`messaging` null-safe) → thêm call không thể làm crash reactMessage |

---

## 4. Scope IN / OUT

**IN (chính xác file được sửa):**
- `english_for_community_backend/src/models/Notification.js` — thêm 1 giá trị enum.
- `english_for_community_backend/src/services/classroomChatService.js` — import + track isNewReaction + createNotification.
- `english_for_community/lib/core/notification/notification_navigation.dart` — 1 case điều hướng + imports.

**OUT (chạm là DỪNG & hỏi):**
- ❌ `notificationService.js` — dùng nguyên hàm `createNotification`, KHÔNG sửa.
- ❌ `listeningController.js` — chỉ là mẫu để clone, không đụng.
- ❌ Client bloc/handler reaction (`classroom_chat_bloc.dart`, `socket_classroom_chat_handler.dart`) — luồng patch UI reaction đã đúng, giữ nguyên.
- ❌ Không đổi payload/emit của `classroom_message_react_update`.
- ❌ Không đổi route/signature `reactMessage`, controller, hay REST endpoint.

---

## 5. CONTEXT BUNDLE ⭐ (Codex đọc phần này là ĐỦ — KHÔNG grep lại)

### Site 1 — `english_for_community_backend/src/models/Notification.js` · enum `type`
- **Locator (anchor):** search `'CO_TEACHER_REMOVED',` (dòng cuối enum, ~`:31`).
- **BEFORE (verbatim):**
  ```js
      'CO_TEACHER_INVITE',
      'CO_TEACHER_INVITE_ACCEPTED',
      'CO_TEACHER_INVITE_DECLINED',
      'CO_TEACHER_REMOVED',
    ],
    required: true
  ```
- **AFTER / THAO TÁC:** thêm 1 dòng ngay sau `'CO_TEACHER_REMOVED',`:
  ```js
      'CO_TEACHER_INVITE',
      'CO_TEACHER_INVITE_ACCEPTED',
      'CO_TEACHER_INVITE_DECLINED',
      'CO_TEACHER_REMOVED',
      'CLASSROOM_CHAT_REACTION',
    ],
    required: true
  ```
- **GOTCHA:** chỉ append. KHÔNG sắp lại thứ tự / xoá value cũ (dữ liệu Notification cũ trong DB phải còn hợp lệ).

### Site 2a — `english_for_community_backend/src/services/classroomChatService.js` · import
- **Locator (anchor):** search `import { getIO } from '../socket/socketManager.js';` (~`:19`).
- **BEFORE (verbatim):**
  ```js
  import mongoose from 'mongoose';
  import { getIO } from '../socket/socketManager.js';
  ```
- **AFTER / THAO TÁC:** thêm import ngay dưới:
  ```js
  import mongoose from 'mongoose';
  import { getIO } from '../socket/socketManager.js';
  import { createNotification } from './notificationService.js';
  ```
- **GOTCHA:** `createNotification` là **named export** trong `notificationService.js:180` (`export { createNotification };`) — import đúng dạng `{ createNotification }`. KHÔNG import `notificationService` object (dư).

### Site 2b — `english_for_community_backend/src/services/classroomChatService.js` · hàm `reactMessage`
- **Locator (anchor):** search `export async function reactMessage(classroomId, userId, messageId, emoji) {` (~`:347`).
- **BEFORE (verbatim):**
  ```js
  export async function reactMessage(classroomId, userId, messageId, emoji) {
    await assertMember(classroomId, userId);

    if (!ALLOWED_EMOJIS.includes(emoji)) throw httpErr(400, 'Emoji không hợp lệ');

    const msg = await ClassroomMessage.findOne({ _id: messageId, classroomId });
    if (!msg) throw httpErr(404, 'Tin nhắn không tồn tại');
    if (msg.deletedAt) throw httpErr(400, 'Không thể react tin nhắn đã bị xóa');

    const uid = new mongoose.Types.ObjectId(userId);
    let reactionGroup = msg.reactions.find((r) => r.emoji === emoji);

    if (!reactionGroup) {
      msg.reactions.push({ emoji, userIds: [uid] });
    } else {
      const idx = reactionGroup.userIds.findIndex((id) => id.equals(uid));
      if (idx >= 0) {
        reactionGroup.userIds.splice(idx, 1);
        if (reactionGroup.userIds.length === 0) {
          msg.reactions = msg.reactions.filter((r) => r.emoji !== emoji);
        }
      } else {
        reactionGroup.userIds.push(uid);
      }
    }

    await msg.save();

    const payload = {
      messageId: String(messageId),
      classroomId: String(classroomId),
      reactions: msg.reactions.map((r) => ({
        emoji: r.emoji,
        count: r.userIds.length,
        userIds: r.userIds.map(String),
      })),
    };
    emitToRoom(classroomId, 'classroom_message_react_update', payload);
    return payload;
  }
  ```
- **AFTER / THAO TÁC (áp đúng 4 chỗ đánh dấu ◀):**
  ```js
  export async function reactMessage(classroomId, userId, messageId, emoji) {
    const { room } = await assertMember(classroomId, userId);          // ◀ 1. capture room (tên lớp cho deep-link)

    if (!ALLOWED_EMOJIS.includes(emoji)) throw httpErr(400, 'Emoji không hợp lệ');

    const msg = await ClassroomMessage.findOne({ _id: messageId, classroomId });
    if (!msg) throw httpErr(404, 'Tin nhắn không tồn tại');
    if (msg.deletedAt) throw httpErr(400, 'Không thể react tin nhắn đã bị xóa');

    const uid = new mongoose.Types.ObjectId(userId);
    let reactionGroup = msg.reactions.find((r) => r.emoji === emoji);
    let isNewReaction = false;                                          // ◀ 2. cờ: chỉ notify khi THÊM react

    if (!reactionGroup) {
      msg.reactions.push({ emoji, userIds: [uid] });
      isNewReaction = true;                                            // ◀ 3a. thêm nhóm emoji mới
    } else {
      const idx = reactionGroup.userIds.findIndex((id) => id.equals(uid));
      if (idx >= 0) {
        reactionGroup.userIds.splice(idx, 1);
        if (reactionGroup.userIds.length === 0) {
          msg.reactions = msg.reactions.filter((r) => r.emoji !== emoji);
        }
      } else {
        reactionGroup.userIds.push(uid);
        isNewReaction = true;                                          // ◀ 3b. thêm userId vào nhóm sẵn có
      }
    }

    await msg.save();

    const payload = {
      messageId: String(messageId),
      classroomId: String(classroomId),
      reactions: msg.reactions.map((r) => ({
        emoji: r.emoji,
        count: r.userIds.length,
        userIds: r.userIds.map(String),
      })),
    };
    emitToRoom(classroomId, 'classroom_message_react_update', payload);

    // ◀ 4. Notify chủ tin nhắn khi có reaction MỚI (bỏ react / tự react → không notify)
    if (isNewReaction && String(msg.senderId) !== String(userId)) {
      const preview =
        msg.type === 'text'
          ? `: "${(msg.content || '').slice(0, 30)}"`
          : msg.type === 'image'
          ? ' (image)'
          : msg.type === 'video'
          ? ' (video)'
          : ' (file)';
      await createNotification({
        recipientId: msg.senderId,
        senderId: userId,
        type: 'CLASSROOM_CHAT_REACTION',
        title: 'New reaction',
        message: `reacted ${emoji} to your message${preview}`,
        data: {
          classroomId: String(classroomId),
          messageId: String(messageId),
          classroomName: room?.name || '',
        },
      });
    }

    return payload;
  }
  ```
- **GOTCHA:**
  - `msg` KHÔNG populate → `msg.senderId` là ObjectId (đúng cho `recipientId`; `createNotification` tự `.toString()`). ĐỪNG populate senderId.
  - Guard `String(msg.senderId) !== String(userId)` là chốt sớm bỏ self-react (dù `createNotification` cũng tự trả `null` khi `rId===sId`).
  - `assertMember` trả `{ room, role }` (room = `Classroom.findById(...).lean()`, có `.name`) — capture `{ room }` KHÔNG tốn thêm query.
  - `createNotification` tự nuốt lỗi socket/FCM (`messaging` null-safe khi chưa cấu hình Firebase) → `await` không làm hỏng response react. Giữ `await` (react là thao tác tần suất thấp).

### Site 3 — `english_for_community/lib/core/notification/notification_navigation.dart` · switch + imports
- **Locator (anchor imports):** search `import 'package:go_router/go_router.dart';` (~`:8`).
- **BEFORE (imports):**
  ```dart
  import 'package:english_for_community/feature/teacher/teacher_classroom_detail_page.dart';
  import 'package:english_for_community/feature/teacher/teacher_exam_grading_page.dart';
  import 'package:go_router/go_router.dart';
  ```
- **AFTER (imports):** thêm 3 import:
  ```dart
  import 'package:english_for_community/feature/teacher/teacher_classroom_detail_page.dart';
  import 'package:english_for_community/feature/teacher/teacher_exam_grading_page.dart';
  import 'package:english_for_community/feature/classroom_chat/classroom_chat_page.dart';
  import 'package:english_for_community/core/utils/global_keys.dart';
  import 'package:english_for_community/core/ui/workspace_layout_scope.dart';
  import 'package:go_router/go_router.dart';
  ```
- **Locator (anchor case):** search `case 'EXAM_SESSION_LIVE':` (~`:78`) — chèn case mới NGAY TRƯỚC nó (hoặc bất kỳ đâu trong `switch (type)`; miễn trong switch).
- **BEFORE (verbatim, vùng chèn):**
  ```dart
        case 'EXAM_SESSION_LIVE':
          final sessionId = payload['sessionId']?.toString();
  ```
- **AFTER / THAO TÁC:** chèn case mới trước `case 'EXAM_SESSION_LIVE':`:
  ```dart
        case 'CLASSROOM_CHAT_REACTION':
          final chatClassroomId = payload['classroomId']?.toString();
          if (chatClassroomId != null && chatClassroomId.isNotEmpty) {
            final extra = <String, dynamic>{
              'classroomName':
                  payload['classroomName']?.toString() ?? 'Nhóm lớp học',
            };
            final ctx = rootNavigatorKey.currentContext;
            final isWeb = ctx != null && WorkspaceLayoutScope.isWebWorkspace(ctx);
            if (isWeb) {
              router.push(
                ClassroomChatPage.routePathFor(chatClassroomId),
                extra: extra,
              );
            } else {
              router.pushNamed(
                ClassroomChatPage.studentRouteName,
                pathParameters: {'classroomId': chatClassroomId},
                extra: extra,
              );
            }
            return true;
          }
          break;

        case 'EXAM_SESSION_LIVE':
          final sessionId = payload['sessionId']?.toString();
  ```
- **GOTCHA:**
  - **BẮT BUỘC** `<String, dynamic>{}` tường minh cho `extra`. Route chat cast `state.extra as Map<String, dynamic>?` (`app_router.dart:443`) và `extra is Map<String, dynamic>` (`:639`) — nếu để literal suy ra `Map<String,String>` thì teacher route sẽ **ném runtime cast error**, student route bỏ qua tên lớp. Đã ép `<String, dynamic>` ở trên.
  - Web = teacher workspace → `routePathFor` = `/teacher/classroom/$id/chat` (dùng `router.push` full-path vì route lồng). Non-web = student app → `studentRouteName` (`/student/classroom/:id/chat`) dùng `pushNamed` + pathParameter.
  - Payload react KHÔNG chứa `listeningId`/`wordId` → không dính early-return đầu hàm; rơi đúng vào `switch`.

### SYMBOL TABLE (verbatim)

| Symbol | Verbatim | Nguồn `file:line` | Trạng thái |
|---|---|---|---|
| enum type mới | `'CLASSROOM_CHAT_REACTION'` | `Notification.js:14-32` | **[THÊM]** |
| `createNotification` | `createNotification({ recipientId, senderId, type, title, message, data, skipSocket?, skipFCM? })` — named export | `notificationService.js:34`, export `:180` | [CÓ] |
| `assertMember` trả về | `{ room, role }` (room có `.name`) | `classroomChatService.js:33-47` | [CÓ] |
| `ClassroomChatPage.studentRouteName` | `'StudentClassroomChatPage'` (path `/student/classroom/:classroomId/chat`) | `classroom_chat_page.dart:68`, route `app_router.dart:632` | [CÓ] |
| `ClassroomChatPage.routePathFor` | `routePathFor(id) => '/teacher/classroom/$id/chat'` | `classroom_chat_page.dart:61-63` | [CÓ] |
| `WorkspaceLayoutScope.isWebWorkspace` | `isWebWorkspace(BuildContext) → bool` | `core/ui/workspace_layout_scope.dart` | [CÓ] |
| `rootNavigatorKey` | `final GlobalKey<NavigatorState> rootNavigatorKey` | `core/utils/global_keys.dart:4` | [CÓ] |
| `ALLOWED_EMOJIS` | `['❤️','👍','😂','😮','😢','😡','🎉','👏']` | `classroomChatService.js:23` | [CÓ] |

### CLONE-THIS (mẫu có sẵn để nhái — đừng viết mới)
- **isNewReaction + createNotification**: `listeningController.js:301-338` (`reactToComment`) — nhái đúng cách set cờ `isNewReaction` chỉ khi THÊM, guard `recipientIdStr !== userId`, và shape `createNotification({recipientId, senderId, type, title, message, data})`.
- **case điều hướng theo type**: `notification_navigation.dart:52-68` (`case 'EXAM_ASSIGNED': ... router.pushNamed(...pathParameters...)`) — nhái cấu trúc guard id + pushNamed + `return true`.

---

## 6. GATE liên quan

- **Perf:** Reaction là thao tác tần suất thấp. `createNotification` thêm ~1 write + 1 `User.findById(fcmTokens)` + FCM multicast vào response HTTP của **người react** (await). Chấp nhận được (không phải hot-path list). Realtime của người NHẬN đi qua socket riêng (`new_notification`), không đụng luồng react. Client chỉ thêm 1 `case` — không list/timer/listener mới. **Không leak.**
- **UI/UX:** N/A (không dựng/đổi layout). Badge/banner/list tái dùng hệ notification generic đã chuẩn.
- **Backend:** Logic ở service (đúng), không thêm route/controller/Zod (emoji đã validate qua `ALLOWED_EMOJIS`), không N+1 (room tái dùng từ `assertMember`; các query của `createNotification` là chuẩn dùng chung mọi notification). Socket không dup: `new_notification` → room = recipientId, khác room `classroom_chat_*`.
- **L10n:** **N/A** — `title`/`message` là **string backend lưu DB** (không phải string UI Flutter) → KHÔNG cần app_en.arb/app_vi.arb (đồng bộ convention hiện có: 'New assignment', 'New Reaction'…). Default deep-link `'Nhóm lớp học'` đã tồn tại sẵn trong route, không phải string mới.

---

## 7. Verify + Hồi quy tối thiểu

**Backend syntax check (chạy được không cần DB):**
```bash
cd english_for_community_backend
node --check src/models/Notification.js
node --check src/services/classroomChatService.js
```
**Client analyze:**
```bash
cd english_for_community
flutter analyze lib/core/notification/notification_navigation.dart
```
→ Kỳ vọng: 0 lỗi mới (import resolve, không unused).

**Smoke (⭐ = ca nghiệm thu chính) — 2 tài khoản cùng 1 lớp:**
1. ⭐ B thả ❤️ vào tin nhắn của A → A nhận: **badge notification +1** + **in-app banner** "B reacted ❤️ to your message: \"...\"" + xuất hiện trong **list notification**. A ở background (mobile) → nhận **push FCM**.
2. No-regression (self): A tự thả reaction vào tin nhắn của **chính A** → **KHÔNG** notification cho A; reaction vẫn hiện trên bubble realtime.
3. Toggle-off: B bỏ react (tap lại ❤️ đã thả) → **KHÔNG** tạo notification mới; reaction biến mất realtime bình thường.
4. ⭐ Deep-link: A tap notification → mở đúng **phòng chat lớp** (student app → student route; teacher web → teacher route), không crash cast `extra`.
5. Emoji khác (👍/😂/😮…) → notification hiển thị đúng emoji đã thả.
6. No-regression (type cũ): 1 notification cũ bất kỳ (vd EXAM_ASSIGNED) tap vẫn điều hướng đúng như trước.

**Account test:** `docs/dev/seeds/` — 2 student cùng lớp (hoặc 1 student + 1 teacher chủ lớp) để test 2 chiều.

> Smoke fail sau fix → DỪNG & báo Opus kèm log.

---

## 8. HANDOFF PROMPT cho Cursor/Codex

```text
Bạn là implementer (Cursor/Codex). Làm đúng phạm vi, biên giới cứng.
Repo: english_for_community (Flutter) + english_for_community_backend (Node ESM).

BƯỚC 0 — ĐỌC WORK-ORDER TRƯỚC (bắt buộc):
  Mở & đọc HẾT: docs/plantasks/FEATURE/20260707-classroom-chat-reaction-notify/work-order.md
  Code cần sửa lấy NGUYÊN từ §5 CONTEXT BUNDLE (anchor + BEFORE/AFTER + symbol table). KHÔNG tự grep đoán.
  File thực tế lệch BEFORE, hoặc doc mâu thuẫn prompt → DỪNG & hỏi (doc thắng).

SỬA (chỉ 3 file này — khớp §4 IN):
  1. english_for_community_backend/src/models/Notification.js        (Site 1: append enum)
  2. english_for_community_backend/src/services/classroomChatService.js (Site 2a import + 2b reactMessage)
  3. english_for_community/lib/core/notification/notification_navigation.dart (Site 3: imports + case)

TUYỆT ĐỐI KHÔNG:
  - Đụng file §4 OUT (notificationService.js, listeningController.js, bloc/handler reaction client).
  - Đổi payload/emit 'classroom_message_react_update'; đổi signature reactMessage/controller/route.
  - Sắp lại/xoá value enum cũ (chỉ append CLASSROOM_CHAT_REACTION).
  - Populate msg.senderId; bỏ guard self-react; đổi `await createNotification`.
  - Quên `<String, dynamic>{}` tường minh cho `extra` ở Site 3 (route cast Map<String,dynamic> → literal String sẽ crash teacher route).
  - Thêm string vào ARB (title/message là string backend, KHÔNG l10n).

LÀM: theo §5 từng Site (tìm anchor → áp AFTER → xử lý GOTCHA). Bám .cursor/rules/project.mdc + Route→Controller→Service→Model.
GATE (§6): Backend — logic ở service, không N+1 (tái dùng room từ assertMember).

VERIFY (chạy hết, dán kết quả): theo §7 (node --check ×2 + flutter analyze + smoke 1..6, ⭐ ưu tiên).
XONG → self-audit ngắn (file · rủi ro · checklist) → dán verify/smoke → báo "implementer đã xong, audit đi". KHÔNG commit/push.
```

---

## 9. Checklist OPUS AUDIT (Phase 4)
- [ ] `git status`/diff: chỉ 3 file Scope IN đổi; file OUT không đụng.
- [ ] Site 1: enum chỉ **append** `CLASSROOM_CHAT_REACTION`; thứ tự/value cũ nguyên vẹn.
- [ ] Site 2: `isNewReaction` set đúng **2 nhánh add**, KHÔNG set ở nhánh toggle-off; guard `String(msg.senderId)!==String(userId)`; import named `{ createNotification }`; capture `{ room }`.
- [ ] Site 3: `extra` là `<String, dynamic>{}`; branch web/non-web đúng route; case nằm trong `switch`; 3 import thêm resolve được.
- [ ] Verify §7: node --check 0 lỗi; flutter analyze 0 lỗi mới; smoke ⭐1 (nhận noti) + ⭐4 (deep-link) pass; no-regression 2/3/6 pass.
- [ ] Không nuốt lỗi / không placeholder-TODO.

---

## 10. Follow-up (OUT scope này — mở task riêng khi cần)
- **Localize notification layer**: title/message backend đang tiếng Anh cứng ('New reaction', 'New assignment'…). Nên chuẩn hoá i18n theo locale người nhận (task hệ thống hoá riêng, áp cho MỌI type).
- **New-message notification**: `sendMessage` (classroomChatService.js:189) hiện cũng KHÔNG tạo Notification (chỉ socket + inbox badge). Nếu muốn push khi có tin nhắn mới lúc app đóng → task riêng (cân nhắc chống spam / mention-only).
- **Dedup reaction spam**: react → unreact → react lặp sẽ tạo nhiều notification. Nếu thành vấn đề → thêm throttle/dedup theo (messageId, sender) trong khoảng thời gian.
