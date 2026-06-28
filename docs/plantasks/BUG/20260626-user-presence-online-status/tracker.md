# Tracker — 20260626-user-presence-online-status

| Field | Value |
|-------|-------|
| **Status** | **DONE** |
| **RC2** | B2 (admin-only) — không B1 |
| **Implementer** | Cursor |
| **Date** | 2026-06-21 |

## Files changed

| Fix | File | Mô tả |
|-----|------|-------|
| F1 | `english_for_community_backend/server.js` | Import `User`; sau `mongoose.connect`, trước `initSocket`: `updateMany({isOnline:true})` → offline + log |
| F2 | `english_for_community_backend/src/socket/socketManager.js` | `OFFLINE_GRACE_MS=20000`, `pendingOffline`; cancel on reconnect; grace on disconnect; force-logout bỏ qua grace |
| F3-B2 | `english_for_community/lib/feature/progress/user_profile_dialog.dart` | Bỏ chấm online (`Positioned` dot); giữ param `isOnline` (API tương thích) |
| F4 | `english_for_community/lib/core/socket/socket_service.dart` | Mobile transports `['websocket','polling']` |

## Verify

### Backend — `node --check`

```
cd english_for_community_backend
node --check server.js
node --check src/socket/socketManager.js
```

**Kết quả:** exit code 0 (cả hai file, không output lỗi).

### Flutter — `dart analyze`

```
cd english_for_community
dart analyze lib/feature/progress/user_profile_dialog.dart lib/core/socket/socket_service.dart
```

**Kết quả:** exit code 0. 12 `info` (library_prefixes, avoid_print) — có sẵn trong `socket_service.dart`, **0 error / 0 warning mới**.

## Acceptance (DEV manual — chưa chạy trên môi trường deploy)

- [ ] F1: Restart server → log `Presence boot-reset: N`; `countDocuments({isOnline:true})` ~0
- [ ] F2: Mất mạng <20s không nhấp nháy admin; >20s offline; ban/force-logout offline ngay
- [ ] F3-B2: Student profile không còn chấm xanh
- [ ] F4: Mobile reconnect qua polling khi websocket bị chặn (optional smoke)
