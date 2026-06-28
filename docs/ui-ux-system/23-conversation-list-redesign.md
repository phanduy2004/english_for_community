# 23 — Redesign danh sách cuộc trò chuyện (web + mobile)

> **Phạm vi:** dòng (tile) + container của **danh sách cuộc trò chuyện** ở cả **web** (dock panel teacher/admin) và **mobile** (tab Tin nhắn học sinh).
> **Vấn đề:** layout "thô", đơn điệu, không giống app chat thật.
> **Mục tiêu:** một **component dòng dùng chung** (DRY), học theo Messenger/Telegram/WhatsApp/Slack, có biến thể density cho web/mobile. Cursor code theo + audit checklist.
> **Nguồn:** đọc code 06/2026. Liên quan [`22`](22-student-chat-scroll-and-conversation-list.md) (scroll + rebuild list), [`20`](20-student-mobile-audit-and-standards.md), [`04`](04-mobile-components.md).

---

## 1. Hiện trạng — vì sao "thô"

### Web — `ClassroomChatRoomTile` (`classroom_chat_room_tile.dart`)
| # | Vấn đề | `dòng` |
|---|--------|--------|
| W1 | **Thời gian nhét chung vào subtitle** dạng `"người gửi: tin · 3d"` (một dòng), KHÔNG căn phải | `:74-83`, `ClassroomChatRoomSubtitle.build :171-176` |
| W2 | **Chevron `>` ở mọi dòng đã đọc** — không app chat nào dùng | `:106-110` |
| W3 | **Unread = tô nền cả dòng** (`primaryTint .45`) — nặng, "loang" | `:35-39` |
| W4 | **Avatar fallback = icon nhóm xám** trên `primaryTint` — đơn điệu, không định danh từng lớp | `room_tile :136-148` |
| W5 | "Active" gắn **chấm xanh** (ngụ ý online) lên avatar — sai ngữ nghĩa (đó là "đang mở"), nên dùng thanh/nền | `:149-162` |
| W6 | Tên 14 / subtitle 12, gap 2px — chật; unread badge radius hardcode 12 | `:73,93` |

### Mobile — `StudentMessengerConversationTile` (`student_messenger_conversation_tile.dart`)
| # | Vấn đề | `dòng` |
|---|--------|--------|
| M1 | **Mỗi dòng là một THẺ accent xanh** (`skillAccentCard` + viền trái) — "boxy", xếp hộp, không giống list chat (vốn là hàng phẳng) | `:34-38` |
| M2 | **Chevron `>`** | `:100-101` |
| M3 | **Tất cả xanh "speaking"** — không định danh từng lớp | `:32,35` |
| M4 | Unread badge radius `AppRadius.card`(10) thay vì `pill` | `:162` |
| ✅ | Thời gian đã căn phải, unread đậm — **giữ** | `:65-74` |

> **Bản chất:** hai tile **thiết kế khác nhau** (web vs mobile) → trùng lặp + lệch. Web nhồi time vào subtitle + chevron; mobile bọc thẻ accent. Cả hai thiếu **định danh avatar** và **cấu trúc 2-hàng chuẩn**.

---

## 2. Học theo app tốt (reference)

| App | Điều đáng học |
|-----|---------------|
| **Messenger / WhatsApp / iMessage** | Hàng **phẳng** (không thẻ), avatar tròn, tên đậm hơn khi chưa đọc, preview 1 dòng muted (đậm+đen khi chưa đọc), **time căn phải** ngang tên, unread = **badge số (pill)** hoặc chấm, **KHÔNG chevron**. |
| **Telegram** | Avatar **màu theo tên** (gradient hash) → mỗi nhóm một màu nhận diện; ✓/✓✓ trạng thái gửi/đã xem; badge xanh đếm; pin/mute icon. |
| **Slack / Linear** | Rất phẳng, dày thông tin; unread = **tên đậm + chấm**; hover nền nhẹ; phân nhóm (pinned/unread). |
| **Chung** | Phân tách bằng **divider inset** (bắt đầu sau avatar) hoặc spacing, KHÔNG xếp thẻ; trailing chỉ time + badge; preview có thể kèm prefix "📷 Ảnh", "🎤 Thoại", "Đang nhập…". |

---

## 3. Spec redesign — một dòng chuẩn (dùng chung web + mobile)

### 3.1 Anatomy

```
┌────────────────────────────────────────────────────────────────┐
│              Tên lớp / nhóm ·························  12:30  ▸t  │   hàng 1: tên (trái) ── time (phải)
│  (avatar)    Người gửi: nội dung tin gần nhất ···········  ● 3  │   hàng 2: preview (trái) ── badge (phải)
└────────────────────────────────────────────────────────────────┘
  ▸t = time accent + đậm khi unread; ● 3 = badge số (pill) khi unread
```

- **2 hàng**: (tên ── time) / (preview ── badge). Time và badge **căn phải**, KHÔNG nhồi vào subtitle.
- **Bỏ chevron** hoàn toàn.
- **Bỏ tô nền cả dòng** cho unread (chỉ dùng đậm + badge).

### 3.2 Trạng thái & token

| Yếu tố | Đã đọc | Chưa đọc (unread) | Đang mở (web active) |
|--------|--------|-------------------|----------------------|
| Tên | `w600` `textPrimary` | `w700` `textPrimary` | `w700` `primary` |
| Preview | `w400` `textMuted` | `w600` `textPrimary` | như đã đọc |
| Time | `caption` `textMuted` | `caption w600` `accent`/`primary` | — |
| Trailing | — (trống) | **badge số** nền `primary`/`accent`, chữ trắng, **radius `pill`** | — |
| Nền dòng | trong suốt | **trong suốt** (không tô) | `primaryTint` + **thanh trái 3px** `primary` |
| Hover (web) | `surfaceSubtle` | `surfaceSubtle` | giữ active |
| Press (mobile) | `pressOverlay` | — | — |

> Dùng **chấm `●`** thay badge số khi không cần đếm (vd nhóm im lặng). Mute → icon loa-gạch + dim 60%. Pinned → nhóm trên cùng + icon ghim.

### 3.3 Avatar có định danh (W4/M3)

- Có ảnh cover → hiển thị ảnh (đã có `ChatGroupCoverAvatar`).
- Không ảnh → **initials trên màu suy ra từ hash tên** (palette 6–8 màu trung tính-tươi), KHÔNG icon nhóm xám. Mỗi lớp một màu ổn định → nhận diện nhanh (kiểu Telegram/Slack).
- Bỏ "chấm xanh online" cho trạng thái active (W5) — chấm xanh **chỉ** dành cho presence thật (tương lai).
- **06/2026 (impl):** palette = 8 cặp tint-nhạt/chữ-đậm cùng tông (`_avatarPalette` trong `classroom_chat_ui.dart`): slate, teal, indigo, violet, rose, sand, green, cyan. **Không** mượn `danger`/`warning` (tránh trông như cảnh báo) và bỏ entry trùng `dangerBg`.

### 3.4 Density (một component, 2 biến thể)

| | Mobile hub | Web dock / panel |
|--|-----------|------------------|
| Row height | **72** | **56–60** |
| Avatar | 48 | 40 |
| Tên / preview | 15 / 13 | 14 / 13 |
| Padding ngang | `s4` | `s3` |
| Phân tách | divider inset (sau avatar) hoặc gap `s2` | **divider inset 1px `outlineMuted`** (đã có, indent ~56) |
| Nền | **hàng phẳng** trên `surface` (bỏ `skillAccentCard`) | hàng phẳng trên `surfaceCard` |

### 3.5 Before / After (mobile)

```
TRƯỚC (boxy, accent xanh, chevron):           SAU (Messenger-clean):
┌─────────────────────────────────┐           (avatar)  Lớp 10A2 ············ 12:30
│▌ (○) Lớp 10A2        12:30   ›  │            [ring]   Cô Lan: Các em nộp bài…   ● 3
│▌     Cô Lan: Các em…    ● 3      │           ───────────────────────────────────  (divider inset)
└─────────────────────────────────┘           (avatar)  Lớp 11B1 ············ 3d
  ↑ thẻ viền trái xanh, chevron                 [grey]   Bạn: Em cảm ơn ạ
```

### 3.6 Tinh chỉnh "Messenger-grade" (tùy chọn, P1)
- Prefix preview theo loại: `📷 Ảnh`, `🎤 Thoại`, `📎 Tệp` khi tin cuối là media.
- "Đang nhập…" (accent, italic) thay preview khi có người gõ (nếu socket hỗ trợ).
- ✓/✓✓ trạng thái gửi/đã xem cho tin cuối của mình.
- Vuốt trái (mobile) để Đọc/ Ẩn (tùy chọn).

---

## 4. Container danh sách (gộp từ [`22`](22-student-chat-scroll-and-conversation-list.md) §B)

- **Rebuild chọn lọc:** bọc list bằng `ListenableBuilder(listenable: controller)`; bỏ `setState` toàn trang mỗi tick socket.
- **Key + recency:** `key: ValueKey(room.id)`; sort `lastMessageAt` desc (cuộc trò chuyện mới lên đầu — có animation mượt khi đổi chỗ).
- **Skeleton hàng** khi loading (khung giống tile) thay spinner full-màn.
- **Header (mobile):** giữ greeting/banner/search/filter; cân nhắc thu gọn banner nếu chiếm chỗ.

---

## 5. Kế hoạch triển khai (hợp nhất 1 component)

1. **Tạo `ConversationTile` dùng chung** (vd `widgets/conversation_tile.dart`) theo §3 — tham số `density` (mobile/web), `isActive`, `room`, `onTap`. Avatar dùng `ChatGroupCoverAvatar` + fallback màu-theo-tên.
2. **Web:** thay `ClassroomChatRoomTile` (trong `classroom_chat_list_panel.dart` + teacher panel) bằng `ConversationTile(density: web)`. Bỏ chevron, time top-right, active = nền + thanh trái.
3. **Mobile:** thay `StudentMessengerConversationTile` bằng `ConversationTile(density: mobile)`. **Bỏ `skillAccentCard`** → hàng phẳng + divider inset.
4. **Sửa `ClassroomChatRoomSubtitle`**: tách `previewBody` (chỉ nội dung, không nhồi time) cho hàng 2; time lấy riêng từ `timeLabel` đặt top-right. (Giữ `formatListTime`.)
5. Badge: radius `pill`; thêm helper màu-avatar-theo-tên trong `ClassroomChatUi` hoặc `AppColors`.
6. Container: §4 (ListenableBuilder, key, skeleton, sort).

---

## 6. Audit checklist

- [ ] **Một** component `ConversationTile` dùng cho cả web + mobile (xoá 2 tile cũ trùng lặp).
- [ ] Time **căn phải** ngang tên; preview hàng 2 **không** chứa time.
- [ ] **Không chevron**; unread không tô nền cả dòng; badge radius `pill`.
- [ ] Avatar không ảnh → **initials màu-theo-tên** (không icon xám).
- [ ] Mobile: hàng **phẳng** (bỏ `skillAccentCard`) + divider inset; row 72dp; web row 56–60.
- [ ] Active (web) = `primaryTint` + thanh trái 3px (bỏ chấm xanh online).
- [ ] Unread: tên `w700`, preview `w600 textPrimary`, time accent.
- [ ] Container: tick socket không rebuild cả trang; `ValueKey(room.id)`; sort recency; skeleton hàng.
- [ ] `dart analyze lib` 0 lỗi mới; xem trên 360×640 (mobile) + dock web.

---

## 7. Bản đồ file ↔ việc

| File | Việc | Mục |
|------|------|-----|
| `widgets/conversation_tile.dart` (mới) | component dòng dùng chung 2 density | 3, 5.1 |
| `classroom_chat_room_tile.dart` | thay nội dung tile bằng `ConversationTile(web)`; bỏ chevron/tô-nền/chấm-xanh; giữ `ClassroomChatRoomAvatar` (sửa fallback màu-theo-tên) | W1–W6 |
| `student_messenger_conversation_tile.dart` | thay bằng `ConversationTile(mobile)`; bỏ `skillAccentCard` | M1–M4 |
| `classroom_chat_room_tile.dart` → `ClassroomChatRoomSubtitle` | tách time khỏi subtitle | W1 |
| `classroom_chat_list_panel.dart` | dùng tile mới; giữ divider inset; skeleton | 4 |
| `student_classroom_chat_hub_page.dart` | ListenableBuilder + key + skeleton + sort recency | 4 |
| `classroom_chat_ui.dart` / `app_color.dart` | helper màu-avatar-theo-tên + badge pill | 3.3 |

> Ghi commit vào [`11-implementation-mapping.md`](11-implementation-mapping.md) "Migration log".
</content>
