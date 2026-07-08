# Work-Order — FEATURE: Báo reaction qua CHAT INBOX (badge + card preview), không dùng notification chuông

- **Task ID:** `20260707-classroom-chat-reaction-notify`
- **Loại:** FEATURE (gap-fill) · **Platform:** backend (client generic đã đủ) · **Cỡ:** MICRO (1 file, ~25 LOC)
- **Mục tiêu:** Khi một thành viên thả icon vào tin nhắn của bạn trong group chat lớp → **icon danh sách chat hiện badge +1** và **card cuộc trò chuyện hiện preview** "*{Tên} đã thả {emoji} vào tin nhắn của bạn*" (giống khi có tin nhắn mới). **KHÔNG** đẩy vào dialog "Notifications" (chuông) — chuông chỉ cho thông báo hệ thống / việc quan trọng.
- **Người phân tích + implement:** Opus. **Status:** ĐÃ IMPLEMENT — chờ smoke E2E.

> **Lịch sử (quan trọng):** bản v1 của work-order này đi hướng SAI — tạo `Notification` (chuông) type `CLASSROOM_CHAT_REACTION`. User phản hồi: reaction phải hiện ở **chat inbox** (badge + card), không phải chuông. Bản v1 đã bị commit nhầm vào HEAD `3df68b4` (kèm nhiều task khác) rồi được **revert** ở working tree; bản v2 (doc này) là hướng đúng.

---

## 1. Vấn đề + nguyên nhân gốc

**Triệu chứng:** Thả reaction vào tin nhắn → reaction hiện realtime trên bubble, NHƯNG chủ tin nhắn không hề biết (không badge ở icon Messages, card hội thoại không đổi) khi họ không mở đúng phòng.

**Root cause:** `reactMessage` chỉ `emitToRoom('classroom_message_react_update')` (patch UI reaction trong phòng), **không** đẩy `classroom_chat_inbox_updated` (event lo badge + preview card của danh sách chat). Đối chiếu `sendMessage` (`classroomChatService.js:248-249`) khi có tin mới thì gọi cả `emitToRoom(...new)` **và** `emitInboxUpdates(...)`. Reaction thiếu bước inbox → không có tín hiệu ở danh sách chat.

---

## 2. Audit downstream + 3. Hướng fix (gộp — MICRO)

**Thiết kế:** Tái dùng đúng hệ inbox có sẵn. Trong `reactMessage`, khi là **reaction MỚI** (thêm userId, không phải bỏ react) và **không tự-react**, emit `classroom_chat_inbox_updated` **CHỈ tới chủ tin nhắn** với `lastMessage.preview` = cả câu + `unreadDelta:1`. Client generic tự lo badge + card → **không sửa Flutter**.

**Client generic (đã đọc code thật — không cần sửa):**
| Điểm | file:line | Hành vi với payload reaction |
|---|---|---|
| Listener inbox | `socket_classroom_chat_handler.dart:152-156` | fan-out mọi callback → dock/hub nhận |
| Áp payload → state | `classroom_chat_dock_controller.dart:184-233` `applyInboxSocketUpdate` | đọc `preview`/`senderName`/`type`/`createdAt` generic; `unreadDelta` cộng dồn (`:219-220`); nếu đang mở đúng phòng (`active`) ép unread 0 (không tăng badge — đúng); `type:'reaction'` KHÔNG switch → an toàn |
| Render preview | `classroom_chat_room_tile.dart:18-25` `previewBody` | `senderName` rỗng → hiện **nguyên** `preview` (không prefix). Nếu để senderName → client ghép `"{firstWord}: {preview}"` gây lặp tên |
| Badge tổng icon chat | `dock_controller.dart:252-254` + `home_page.dart:223`, `classroom_chat_dock.dart:102`, `student_classroom_chat_hub_page.dart:289` | đếm số phòng có unread & !muted |
| Media icon theo type | `conversation_tile.dart:343-354` `_mediaIconFor` | `default → null` → `type:'reaction'` không icon, không crash |

**Không regression:** thêm 1 nhánh emit sau `emitToRoom` cũ (giữ nguyên payload/emit react); không đổi signature/route/controller; enum Notification & notification_navigation **đã revert** về nguyên bản (không đụng hệ chuông).

---

## 4. Scope IN / OUT

**IN:**
- `english_for_community_backend/src/services/classroomChatService.js` — thêm helper `emitReactionInboxUpdate` + gọi trong `reactMessage` khi reaction mới.

**OUT (đã revert về gốc — KHÔNG đụng):**
- ❌ `Notification.js` (enum), `notification_navigation.dart`, `notificationService.js` — hệ chuông, không dùng cho reaction.
- ❌ Client Flutter — generic đã đủ.
- ❌ Payload/emit `classroom_message_react_update`; signature `reactMessage`/controller/route.

---

## 5. CONTEXT BUNDLE ⭐ (code đã áp — verbatim)

### Site 1 — `classroomChatService.js` · helper mới (đặt ngay sau `emitInboxUpdates`, ~`:186`)
- **Locator:** search `async function emitInboxUpdates(classroomId, messageView, senderId) {` → chèn helper NGAY SAU dấu `}` đóng hàm đó.
- **CODE (áp):**
  ```js
  // Báo cho CHỦ tin nhắn khi có người thả reaction mới: badge danh sách chat +1
  // và card hội thoại hiện preview "X đã thả <emoji> vào tin nhắn của bạn".
  // Chỉ đẩy tới đúng chủ tin nhắn (không phải cả lớp) và chỉ khi là reaction mới.
  async function emitReactionInboxUpdate(classroomId, ownerId, reactorId, emoji) {
    const reactor = await User.findById(reactorId).select('fullName username').lean();
    const reactorName = reactor?.fullName || reactor?.username || 'Thành viên';
    emitToUser(String(ownerId), 'classroom_chat_inbox_updated', {
      classroomId: String(classroomId),
      lastMessage: {
        preview: `${reactorName} đã thả ${emoji} vào tin nhắn của bạn`,
        senderName: '',
        senderId: String(reactorId),
        type: 'reaction',
        createdAt: new Date().toISOString(),
      },
      unreadDelta: 1,
    });
  }
  ```
- **GOTCHA:** `senderName` PHẢI rỗng (client ghép `"{firstWord(senderName)}: {preview}"` → nếu điền tên sẽ lặp "Tat: Tat Duy Phan đã thả…"). `User` đã import sẵn (`:16`); `emitToUser` đã có (`:91`).

### Site 2 — `classroomChatService.js` · `reactMessage`
- **Locator:** search `emitToRoom(classroomId, 'classroom_message_react_update', payload);` (trong `reactMessage`).
- **BEFORE:**
  ```js
    const uid = new mongoose.Types.ObjectId(userId);
    let reactionGroup = msg.reactions.find((r) => r.emoji === emoji);

    if (!reactionGroup) {
      msg.reactions.push({ emoji, userIds: [uid] });
    } else {
      ...
      } else {
        reactionGroup.userIds.push(uid);
      }
    }
    ...
    emitToRoom(classroomId, 'classroom_message_react_update', payload);
    return payload;
  ```
- **AFTER (đã áp — thêm `isNewReaction` + gọi helper):**
  ```js
    const uid = new mongoose.Types.ObjectId(userId);
    let reactionGroup = msg.reactions.find((r) => r.emoji === emoji);
    let isNewReaction = false;

    if (!reactionGroup) {
      msg.reactions.push({ emoji, userIds: [uid] });
      isNewReaction = true;
    } else {
      const idx = reactionGroup.userIds.findIndex((id) => id.equals(uid));
      if (idx >= 0) {
        reactionGroup.userIds.splice(idx, 1);
        if (reactionGroup.userIds.length === 0) {
          msg.reactions = msg.reactions.filter((r) => r.emoji !== emoji);
        }
      } else {
        reactionGroup.userIds.push(uid);
        isNewReaction = true;
      }
    }
    ...
    emitToRoom(classroomId, 'classroom_message_react_update', payload);

    // Reaction MỚI (không phải bỏ react) và không tự-react → báo chủ tin nhắn qua chat inbox
    if (isNewReaction && String(msg.senderId) !== String(userId)) {
      await emitReactionInboxUpdate(classroomId, msg.senderId, userId, emoji);
    }

    return payload;
  ```
- **GOTCHA:** `isNewReaction=true` CHỈ ở 2 nhánh add (nhóm emoji mới + push userId vào nhóm sẵn có); KHÔNG ở nhánh toggle-off. `msg.senderId` là ObjectId (msg không populate) → guard bằng `String(...)`.

### SYMBOL TABLE
| Symbol | Verbatim | Nguồn | Trạng thái |
|---|---|---|---|
| event inbox | `'classroom_chat_inbox_updated'` payload `{classroomId, lastMessage:{preview,senderName,senderId,type,createdAt}, unreadDelta}` | `classroomChatService.js:166-186` | [CÓ] |
| `emitToUser` | `emitToUser(userId, event, payload)` → `getIO().to(String(userId)).emit(...)` | `classroomChatService.js:91-95` | [CÓ] |
| `User` model | `import User from '../models/User.js'` | `:16` | [CÓ] |
| client `unreadDelta` | `room.unreadCount + delta` | `classroom_chat_dock_controller.dart:219` | [CÓ] |
| client preview (senderName rỗng → preview nguyên) | `previewBody` | `classroom_chat_room_tile.dart:18-25` | [CÓ] |

### CLONE-THIS
- `emitInboxUpdates` (`classroomChatService.js:166-186`) — nhái shape payload `classroom_chat_inbox_updated` (lastMessage + unreadDelta) + cách gọi `emitToUser`.

---

## 6. GATE
- **Perf:** reaction tần suất thấp; helper thêm 1 `User.findById(...).lean()` chỉ khi reaction mới. Không list/timer/leak. Không N+1.
- **Backend:** logic ở service (đúng), emit tới đúng 1 user (không fanout cả lớp), không route/Zod mới.
- **UI/UX / L10n:** N/A client (generic). Preview là string backend (tiếng Việt, khớp UI) — không phải string Flutter → không cần ARB.

---

## 7. Verify + Hồi quy

**Backend syntax:**
```bash
cd english_for_community_backend && node --check src/services/classroomChatService.js
```
→ đã chạy: **OK**.

**Smoke (⭐ nghiệm thu chính) — 2 account cùng 1 lớp, cùng online:**
1. ⭐ A KHÔNG mở phòng đó (đang ở màn khác). B thả ❤️ vào tin của A → **icon Messages của A hiện badge +1** + **card lớp đó preview** "B đã thả ❤️ vào tin nhắn của bạn", nhảy lên đầu danh sách.
2. A đang MỞ đúng phòng đó khi B thả → **không** tăng badge (đúng — A đang xem); reaction hiện trên bubble realtime.
3. Self: A tự thả reaction tin mình → **không** badge/preview cho A.
4. Toggle-off: B bỏ react → **không** phát inbox mới.
5. A mở phòng đó → badge phòng về 0 (markRead cũ, không regression).
6. Emoji khác (👍/😡…) → preview đúng emoji đã thả.

**Account test:** `docs/dev/seeds/` — 2 student cùng lớp (hoặc student + teacher chủ lớp).

---

## 8. Trạng thái thực thi
- ✅ Áp Site 1 + Site 2 vào `classroomChatService.js`; `node --check` OK.
- ✅ Revert sạch hướng chuông sai: `Notification.js`, `notification_navigation.dart` về nguyên bản.
- ⏳ Chờ smoke E2E (cần app live + 2 account) — mục 7.

---

## 9. Checklist OPUS AUDIT
- [x] Chỉ `classroomChatService.js` mang logic mới; hệ chuông đã revert.
- [x] `isNewReaction` đúng 2 nhánh add; guard self-react.
- [x] `senderName:''` (tránh lặp tên); `type:'reaction'` an toàn client.
- [x] `node --check` OK.
- [ ] Smoke ⭐1 (badge+preview khi A không mở phòng) + 2 (không tăng khi đang mở) pass.

---

## 10. Follow-up (OUT scope)
- **Persist reaction-unread server-side:** badge reaction hiện là optimistic client (socket `unreadDelta`). Nếu chủ tin nhắn CHƯA nạp inbox (room chưa có trong `rooms` → `applyInboxSocketUpdate` gọi `refreshInboxBadge()` REST, mà REST không đếm reaction) hoặc restart app → badge reaction mất. Muốn bền vững phải lưu unread reaction ở read-state (task riêng, vì reaction không phải message).
- **FCM push khi app đóng:** inbox update là socket → chỉ tới khi online. Muốn push lúc app background → task riêng (cân nhắc spam).
- **New-message inbox vs chuông:** `sendMessage` cũng chỉ inbox (không chuông) — nhất quán, không cần đổi.
