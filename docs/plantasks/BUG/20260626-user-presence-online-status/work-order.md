# Work-Order — BUG: Trạng thái online/offline của user toàn project không tin cậy

- **Task ID:** 20260626-user-presence-online-status
- **Loại:** BUG (realtime presence)
- **Mục tiêu:** `isOnline` phản ánh đúng sự thật — không còn user "ma" online sau restart, không nhấp nháy khi mạng chập chờn, chỉ-báo online ở UI nhất quán.
- **Cỡ task:** T1 (2 file backend chắc chắn + 1 nhánh frontend tùy quyết định) → 1 work-order (file này).
- **Người phân tích:** Opus (brain, KHÔNG tự code). **Implementer:** Cursor. **Auditor:** Cursor (theo "nhờ cursor audit luôn") + Opus Phase 4. **Status:** PHÂN TÍCH XONG — **RC2 đã chốt = B2 (admin-only)** → SẴN SÀNG handoff Cursor (§9).

> Quy ước theo `docs/AI-Working-Process-vi.md`. Mọi file/luồng dưới đây đã đọc code thật (ground-truth), không suy đoán.

---

## 1. Luồng presence hiện tại (ground-truth)

```
CLIENT
  UserStatus.success  → socket_lifecycle_manager.dart:126  userLogin(id) → emit 'user_login'
  UserStatus.unauthenticated → :142 disconnect() → emit 'user_logout' + socket.disconnect
  onConnect (reconnect): socket_service.dart:77 → re-emit 'user_login'  (transports MOBILE = ['websocket'] only :52)

SERVER socketManager.js
  'user_login'  :78  → addUserSocket → nếu socket đầu tiên → updateUserStatus(true)
  'disconnect'  :254 / 'user_logout' :85 → removeUserSocket → nếu hết socket → updateUserStatus(false)
  updateUserStatus :13 → User.isOnline=… + lastActivityDate=now → emit 'user_status_change' CHỈ tới 'admin_room' :19
  onlineSocketIdsByUser :11 = Map in-memory (mất khi process chết)
  initSocket :70  ← server.js:37 (KHÔNG có bước reset isOnline lúc boot)

DB User.js:50  isOnline default:false; :105 index {isOnline, lastActivityDate}
CONSUMERS
  Admin: user_management_page.dart:96 listenToUserStatus → realtime OK; adminService.js:253 filter isOnline / :258 sort
  Student: progress leaderboard → user_profile_dialog.dart:77  chấm online (SNAPSHOT REST, KHÔNG realtime)
```

---

## 2. Nguyên nhân gốc (có dẫn chứng)

| # | Bug | Mức | Nguyên nhân gốc | Dẫn chứng |
|---|-----|-----|-----------------|-----------|
| **RC1** | **User "ma" online sau restart/crash** | 🔴 CAO | `onlineSocketIdsByUser` chỉ in-memory; **không reset `isOnline` lúc boot**. Render hay restart/spin-down/redeploy → process chết, `disconnect` không chạy cho mọi socket → DB giữ `isOnline:true` vĩnh viễn tới khi user đó connect+disconnect lần sau. Admin filter "online" + chấm online toàn đồ ma. | `server.js:21-46` (không `updateMany` reset); `socketManager.js:11` |
| **RC2** | **Presence realtime CHỈ tới admin** | 🟠 (cần quyết định) | `updateUserStatus` emit `user_status_change` **chỉ `admin_room`** (`socketManager.js:19`, `adminController.js:91`). Chỉ admin client lắng nghe (`user_management_page.dart:96`). Chấm online phía **student** (`user_profile_dialog.dart:77`) lấy từ REST snapshot → **không bao giờ cập nhật realtime** và phản ánh DB có thể đã cũ (RC1). | `socketManager.js:19`; `user_profile_dialog.dart:77`; chỉ 1 listener admin |
| **RC3** | **Nhấp nháy online/offline khi mạng chập chờn** | 🟡 TB | Mất mạng thoáng qua → `disconnect` → removeUserSocket → (socket cuối) → **offline ngay** → reconnect (`enableReconnection`) → `user_login` → online lại. Mỗi lần ghi DB + admin thấy nhấp nháy. `enableForceNew()` khiến mỗi reconnect là socket id mới. | `socketManager.js:41-50,254-260`; `socket_service.dart:58-60` |
| **RC5** | **Login REST không set online; phụ thuộc 100% socket** | 🟢 THẤP | Mobile transports = `['websocket']` only (`socket_service.dart:52`). Sau proxy/mạng chặn upgrade websocket → socket không lên → user đã đăng nhập vẫn **offline**. authService login không set `isOnline` (chỉ logout set false `:280`). | `socket_service.dart:52`; `authService.js:280` |

**Điểm khuếch đại:** "online" là nhị phân thuần theo socket, **không heartbeat/TTL** → bất kỳ RC1/RC3/RC5 đều cho ra trạng thái sai mà không tự lành.

---

## 3. Audit downstream (consumer của isOnline / user_status_change)

| Consumer | File:line | Phụ thuộc | Ảnh hưởng fix |
|----------|-----------|-----------|----------------|
| Admin user list | `adminService.js:253,258` | query/sort `isOnline` | F1 làm số liệu đúng (hết ma) |
| Admin realtime | `user_management_page.dart:96` `listenToUserStatus` | nghe `user_status_change` (admin_room) | Giữ nguyên — đang đúng |
| Admin force-logout | `adminController.js:91` | emit admin_room | Giữ nguyên |
| Student profile dot | `user_profile_dialog.dart:77` | `isOnline` snapshot | RC2 — phụ thuộc nhánh B1/B2 |
| HTTP logout | `authService.js:280-284` → `setUserOfflineAndNotify` | offline ngay | F2 phải cho force-offline **bỏ qua grace** |

→ Không có nhánh logic nào khác rẽ theo `isOnline`. Rủi ro lan: thấp; chú ý đúng 1 điểm: grace period (F2) không được làm chậm force-logout.

---

## 4. Quyết định cần CHỐT trước khi implement (RC2)

**Online/offline có phải tính năng cho HỌC SINH thấy nhau không?** → ✅ **ĐÃ CHỐT: B2 (admin-only)** (2026-06-26). Chỉ làm F3-B2; bỏ qua mọi phần B1.

- **B2 — Admin-only (đề xuất, nhỏ & an toàn):** presence là công cụ quản trị. **Bỏ/ẩn chấm online ở `user_profile_dialog`** (đang hiển thị dữ liệu cũ, gây hiểu lầm). Không đụng broadcast. → chỉ thêm Fix F3-B2.
- **B1 — Cho student realtime (feature lớn hơn):** broadcast `user_status_change` rộng hơn admin + client giữ presence-cache + các màn student subscribe. → Fix F3-B1 (nhiều file hơn, cân nhắc privacy: lộ "ai đang online" cho mọi người).

> F1 + F2 + (F4) **làm bất kể B1/B2** — đó là phần sửa cốt lõi "ghost online" + "nhấp nháy". RC2 chỉ quyết phần chấm online phía student.

---

## 5. BƯỚC 0 — DIAGNOSE (DEV chạy để xác nhận RC1 trên data thật)

```js
// mongosh, đúng DB english_community
use english_community
db.users.countDocuments({ isOnline: true })          // nghi: lớn bất thường so với người đang thực sự dùng
db.users.find({ isOnline: true }, { username:1, lastActivityDate:1 }).sort({lastActivityDate:1}).limit(20)
//  → nhiều bản ghi lastActivityDate cũ (giờ/ngày trước) mà vẫn isOnline:true ⇒ RC1 xác nhận
```

---

## 6. Scope IN / OUT

**IN (được chạm):**
- `english_for_community_backend/server.js` — F1 (boot reset).
- `english_for_community_backend/src/socket/socketManager.js` — F2 (grace period) [+ F3-B1 broadcast nếu chọn B1].
- (F3-B2) `english_for_community/lib/feature/progress/user_profile_dialog.dart` — bỏ chấm online.
  **HOẶC** (F3-B1) `socket_lifecycle_manager.dart` + presence-cache + các consumer.
- (F4 tùy chọn) `english_for_community/lib/core/socket/socket_service.dart` — thêm 'polling' fallback mobile.

**OUT (chạm là DỪNG & hỏi):**
- ❌ Đổi luồng realtime admin (đang đúng).
- ❌ Đổi schema `User` / index.
- ❌ Đụng socket exam / classroom-chat / listening.
- ❌ Thêm friend-graph / online cho từng nhóm (trừ khi chọn B1 và đã chốt phạm vi broadcast).
- ❌ Đổi cơ chế auth/token.

---

## 7. Diff cụ thể (Cursor implement theo đúng đây)

### Fix F1 (RC1) — Reset presence "ma" lúc boot — `server.js`
Thêm import (đầu file, cạnh các import model):
```js
import User from './src/models/User.js';
```
Thêm NGAY SAU log "Connected to MongoDB" (sau dòng 31), TRƯỚC `initSocket`:
```js
// Cờ isOnline còn sót từ vòng đời process trước (Render restart/crash/spin-down) → reset.
try {
  const r = await User.updateMany({ isOnline: true }, { $set: { isOnline: false } });
  console.log(`🧹 Presence boot-reset: ${r.modifiedCount} user(s) → offline`);
} catch (e) {
  console.error('Presence boot-reset failed:', e?.message || e);
}
```

### Fix F2 (RC3) — Grace period trước khi đánh offline — `socketManager.js`
Thêm cạnh `onlineSocketIdsByUser` (~:11):
```js
const OFFLINE_GRACE_MS = 20000;            // chờ reconnect trước khi báo offline
const pendingOffline = new Map();          // userId -> Timeout
```
`addUserSocket` — hủy timer offline đang chờ (reconnect):
```js
const addUserSocket = async (userId, socketId) => {
  const key = String(userId);
  const pending = pendingOffline.get(key);
  if (pending) { clearTimeout(pending); pendingOffline.delete(key); }   // ⬅ thêm
  if (!onlineSocketIdsByUser.has(key)) onlineSocketIdsByUser.set(key, new Set());
  const set = onlineSocketIdsByUser.get(key);
  const wasOffline = set.size === 0;
  set.add(socketId);
  if (wasOffline) await updateUserStatus(userId, true);
};
```
`removeUserSocket` — hoãn offline thay vì offline ngay:
```js
const removeUserSocket = async (userId, socketId) => {
  const key = String(userId);
  const set = onlineSocketIdsByUser.get(key);
  if (!set) return;
  set.delete(socketId);
  if (set.size === 0) {
    onlineSocketIdsByUser.delete(key);
    const t = setTimeout(async () => {            // ⬅ thay updateUserStatus(false) trực tiếp
      pendingOffline.delete(key);
      if (!onlineSocketIdsByUser.has(key)) await updateUserStatus(userId, false);
    }, OFFLINE_GRACE_MS);
    pendingOffline.set(key, t);
  }
};
```
`setUserOfflineAndNotify` (force logout) — phải **bỏ qua grace**, hủy timer + offline ngay (giữ logic cũ, thêm clear):
```js
const pending = pendingOffline.get(key);
if (pending) { clearTimeout(pending); pendingOffline.delete(key); }
// … phần disconnect socket + updateUserStatus(userId, false) giữ nguyên
```

### Fix F3 — theo nhánh đã chốt ở §4
**B2 (đề xuất) — `user_profile_dialog.dart`:** bỏ block `if (isOnline) Positioned(... chấm online ...)` (~:77). (Hoặc chỉ render khi có nguồn realtime đáng tin — hiện chưa có cho student.)

**B1 — cho student realtime (nếu chọn):**
- `socketManager.js` `updateUserStatus`: broadcast rộng hơn admin (phạm vi cần CHỐT — gợi ý: phát tới các room `classroom_chat_*` user thuộc về, hoặc `io.emit` nếu chấp nhận lộ toàn cục cho app nhỏ).
- Client: thêm listener `user_status_change` toàn cục (vd trong `socket_lifecycle_manager`) → cập nhật `ValueNotifier<Map<String,bool>>` presence-cache; `user_profile_dialog` + leaderboard đọc từ cache.
- (Chi tiết phạm vi B1 sẽ bổ sung sau khi chốt — đây là FEATURE, có thể tách task riêng.)

### Fix F4 (RC5, tùy chọn) — `socket_service.dart:52`
```dart
final transports = kIsWeb ? ['websocket', 'polling'] : ['websocket', 'polling'];
```
→ Cho mobile fallback polling khi proxy chặn websocket upgrade (giảm "đăng nhập mà offline").

---

## 8. Lệnh verify

```bash
# Backend syntax
cd english_for_community_backend
node --check server.js
node --check src/socket/socketManager.js

# Flutter (nếu chạm dart)
cd ../english_for_community
dart analyze lib/feature/progress/user_profile_dialog.dart lib/core/socket/socket_service.dart
```

**Nghiệm thu (acceptance):**
- (F1) Restart server → `db.users.countDocuments({isOnline:true})` về ~0 ngay sau boot (chỉ tăng khi có người connect thật). Log "Presence boot-reset: N".
- (F1) User không mở app → KHÔNG còn hiện online ở admin.
- (F2) Tắt/bật mạng <20s → admin KHÔNG thấy offline→online nhấp nháy; >20s mới offline.
- (F2) Force-logout (ban) vẫn offline **ngay**, không chờ grace.
- (F3-B2) Màn student không còn chấm online (hết hiển thị dữ liệu cũ). / (F3-B1) chấm online cập nhật realtime.
- `node --check` + `dart analyze` 0 lỗi mới.

---

## 9. HANDOFF — Cursor IMPLEMENT (copy nguyên khối)

```text
Bạn là implementer. CHỈ sửa đúng file dưới; file ngoài danh sách → DỪNG & hỏi.
Repo: english_for_community_backend (Node) + english_for_community (Flutter).
Work-order: docs/plantasks/BUG/20260626-user-presence-online-status/work-order.md (làm đúng §7).

NHÁNH RC2 ĐÃ CHỐT: B2 (admin-only) — KHÔNG làm B1 (không broadcast rộng, không presence-cache).

FILE:
  1. english_for_community_backend/server.js                         — F1 boot-reset (import User + updateMany)
  2. english_for_community_backend/src/socket/socketManager.js       — F2 grace period
  3. english_for_community/lib/feature/progress/user_profile_dialog.dart — F3-B2: bỏ chấm online (~:77)
  4. (tùy chọn) english_for_community/lib/core/socket/socket_service.dart — F4 polling fallback

TUYỆT ĐỐI KHÔNG: đổi realtime admin, schema/index User, socket exam/chat/listening, auth/token, broadcast presence cho student (B1 đã loại), thêm friend-graph.
VERIFY: node --check server.js + socketManager.js; dart analyze file dart đã chạm. Dán kết quả vào tracker, đặt DONE.
```

---

## 10. HANDOFF — Cursor AUDIT (copy nguyên khối)

```text
Bạn là AUDITOR (không sửa code trừ khi tìm lỗi và được phép).
Work-order: docs/plantasks/BUG/20260626-user-presence-online-status/work-order.md

KIỂM:
  - F1: server.js reset isOnline lúc boot, đặt SAU khi mongoose.connect thành công, TRƯỚC initSocket; có log; import User đúng.
  - F2: grace 20s; addUserSocket hủy pendingOffline khi reconnect; removeUserSocket hoãn offline; setUserOfflineAndNotify (force-logout) BỎ QUA grace (offline ngay). Không rò rỉ Timeout.
  - F3: đúng nhánh đã chốt (B2 bỏ chấm online / B1 broadcast + listener + cache đúng phạm vi).
  - Không scope-creep: realtime admin/auth/schema/exam-chat-socket KHÔNG đổi.
  - Edge: nhiều thiết bị cùng user (multi-socket) vẫn đúng; logout chủ động vẫn offline.
VERIFY: node --check (2 file JS) + dart analyze (file dart) → sạch.
KẾT QUẢ: verdict APPROVED hoặc finding kèm file:line. KHÔNG dán full file vào chat.
```

---

## 11. Checklist OPUS AUDIT (Phase 4)

- [ ] F1 đúng vị trí (sau connect, trước initSocket) + log + import.
- [ ] F2: grace cancel-on-reconnect; force-logout bỏ qua grace; không leak timer.
- [ ] F3 khớp nhánh đã chốt.
- [ ] F4 (nếu làm) chỉ thêm 'polling', không đổi gì khác.
- [ ] Không đụng file OUT; admin realtime nguyên vẹn.
- [ ] `node --check` + `dart analyze` pass.
- [ ] DEV đã chạy Diagnose §5 + xác nhận count isOnline về đúng sau restart.

---

## 12. Việc thực tế còn lại của DEV (ngoài code)

1. Chạy Diagnose §5 trước/sau khi deploy fix.
2. (1 lần) sau khi deploy F1, có thể chạy tay `db.users.updateMany({isOnline:true},{$set:{isOnline:false}})` để dọn ngay đám "ma" hiện có (F1 sẽ tự lo các lần boot sau).
3. Re-test multi-device + mất mạng thoáng qua + ban/force-logout.
