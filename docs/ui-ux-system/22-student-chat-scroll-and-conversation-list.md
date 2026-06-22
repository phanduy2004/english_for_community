# 22 — Student chat: scroll mượt + màn danh sách cuộc trò chuyện

> **Phạm vi:** (A) màn **chat** học sinh (`classroom_chat`) — lỗi vào màn không hiện tin mới nhất, kéo xuống giật; (B) màn **danh sách cuộc trò chuyện** (`student_classroom_chat_hub_page`) — cần làm gọn/đẹp/mượt hơn.
> **Mục đích:** chẩn đoán **root-cause kèm `file:dòng`** + **giải pháp chi tiết** để Cursor code theo + **audit checklist** để kiểm lại.
> **Nguồn:** đọc trực tiếp code 06/2026. Chuẩn nền: [`04`](04-mobile-components.md), [`15`](15-mobile-smart-patterns.md), [`20`](20-student-mobile-audit-and-standards.md).

---

## 1. Triệu chứng (người dùng báo)

1. **Vào màn chat:** không hiện ngay đoạn tin **mới nhất** — hiện đoạn tin **cũ hơn** trước, rồi mới nhảy xuống; khi tự kéo xuống đáy thì **giật/lag**.
2. **Danh sách cuộc trò chuyện:** bố cục "chưa ưng", thiếu mượt.

---

# A · MÀN CHAT — SCROLL

## 2A. Chẩn đoán root-cause

> File chính: `lib/feature/classroom_chat/widgets/classroom_chat_body.dart`. Dữ liệu: `state.messages` xếp **xuôi** (cũ→mới), `messages.last` = mới nhất, `hasMore` = còn tin cũ (nạp ở **đỉnh**).

| # | Nguyên nhân | `file:dòng` | Vì sao gây triệu chứng |
|---|-------------|-------------|------------------------|
| C1 | **ListView KHÔNG reverse** — render từ trên (tin cũ) xuống dưới (tin mới); để xuống đáy phải tự cuộn | `classroom_chat_body.dart:491` (`ListView.builder`, không `reverse`) | Tin mới nhất nằm ở **đáy**, không thấy ngay khi vào |
| C2 | **Nhảy xuống đáy bằng postFrame `jumpTo(maxScrollExtent)`** sau khi build xong lần đầu | `:146-162` (first-load branch) → `:94-107` `_scrollToBottom` | Vào màn: thấy **tin cũ 1 nhịp** rồi mới "giật" xuống đáy. Với bubble cao thay đổi (ảnh/wrap), `maxScrollExtent` chưa đúng → nhảy sai chỗ → **giật** |
| C3 | **Khôi phục vị trí khi nạp tin cũ bằng toán anchor thủ công** | `:131-140` `_restoreScrollAfterLoadMore` (`jumpTo(anchor.pixels + (newMax - anchor.maxExtent))`) | Cuộn lên xem tin cũ → nhảy vị trí (fragile) |
| C4 | **Nhảy tới tin (pin) bằng ƯỚC LƯỢNG chiều cao** `estItemHeight = 72` | `:109-120` `_scrollToMessage` | Bubble cao thật ≠ 72 → nhảy lệch → giật |
| C5 | **Xử lý scroll trong BlocConsumer `listener`** chạy mỗi lần đổi length/status | `:201-215` gọi `_handleMessagesChanged` | Nhiều lần postFrame jump trong các chuyển trạng thái → khựng |
| C6 | `cacheExtent: 480` hơi nhỏ cho chat có media | `:495` | Cuộn nhanh phải dựng lại item → spike |
| ✅ | RepaintBoundary mỗi bubble đã có; ảnh bubble đặt `width/height` cố định | `:536`, `chat_message_bubble.dart:947-964` | Tốt — giữ |

> **Bản chất:** đây là anti-pattern "forward list + tự cuộn xuống đáy". Chuẩn chat (Messenger/Telegram/WhatsApp/Flutter) là **`reverse: true`**: tin mới nhất ở **đáy mặc định** (offset 0), **không cần** jumpTo, **không** flash, **không** toán anchor.

## 3A. Giải pháp — chuyển sang reverse list

> Mục tiêu: vào màn thấy ngay tin mới nhất ở đáy, cuộn mượt, nạp tin cũ không nhảy. **Xoá** toàn bộ jumpTo/anchor thủ công.

**Bước 1 — ListView reverse + đảo chỉ số (KHÔNG đổi thứ tự `state.messages`).**
- `ListView.builder(reverse: true, controller: scrollController, …)` (`:491`).
- `itemCount = messages.length + (hasMore ? 1 : 0)` (giữ).
- Map chỉ số (index 0 = **đáy** = tin **mới nhất**):
  ```dart
  // header "tải tin cũ" nằm ở ĐỈNH = index lớn nhất
  if (hasMore && index == messages.length) return _LoadMoreHeader(...);
  final msgIndex = messages.length - 1 - index;   // newest → oldest
  final msg = messages[msgIndex];
  ```
- **Grouping/date giữ NGUYÊN logic** (vẫn tính trên `msgIndex` của list xuôi): `showDate = msgIndex == 0 || !_isSameDay(msg, messages[msgIndex-1])`, `_isFirstInGroup/_isLastInGroup` không đổi. `_DateSeparator` vẫn đặt **trước** bubble trong `Column` (reverse chỉ đảo thứ tự item, không đảo con trong item) → separator vẫn hiển thị **phía trên** tin đầu ngày. ✔
- Thêm `key: ValueKey(msg.id)` cho mỗi item; `addAutomaticKeepAlives: false`.

**Bước 2 — Bỏ jumpTo lúc vào màn (C2).**
- **Xoá** 2 nhánh first-load ở `_handleMessagesChanged` (`:146-162`) gọi `_scrollToBottom`. Reverse list đã ở đáy sẵn → không cần.
- `_scrollToBottom`: đổi đích từ `maxScrollExtent` → **0** (`animateTo(0)` / `jumpTo(0)`).
- `_isNearBottom`: đáy giờ là offset **0** → `_scrollCtrl.offset <= _nearBottomThreshold`. `_stickToBottom` cập nhật theo `offset <= threshold`.
- Tin mới đến / tin của mình: nếu đang gần đáy → `jumpTo(0)` (giữ logic `shouldScroll` ở `:183-191` nhưng đổi đích 0).

**Bước 3 — Nạp tin cũ không cần anchor (C3).**
- Trong reverse list, nạp tin cũ = **thêm vào cuối** thứ tự đảo → offset **tự giữ nguyên**. **Xoá** `_loadMoreAnchor`, `_ScrollAnchor`, `_restoreScrollAfterLoadMore` (`:51, 87-90, 131-140, 164-181`).
- Trigger nạp thêm: đỉnh giờ là `maxScrollExtent` → đổi điều kiện ở `_onScroll` (`:81`) từ `pos.pixels > _loadMoreThreshold` (return) sang: nạp khi `pos.maxScrollExtent - pos.pixels <= _loadMoreThreshold`.

**Bước 4 — Nhảy tới tin pin chính xác (C4, P1).**
- Thay ước lượng `estItemHeight` bằng `Scrollable.ensureVisible` trên `ValueKey(msg.id)` nếu item đã dựng; nếu chưa (còn ở trang cũ) → nạp thêm rồi ensureVisible. Best-effort, không dùng số magic.

**Bước 5 — Polish (C5, C6).**
- Giữ `_handleMessagesChanged` nhưng chỉ còn nhánh "tin mới + gần đáy → jumpTo(0)". Cân nhắc chuyển phần scroll ra `listener` riêng gọn.
- Tăng `cacheExtent` ~ 800–1000 cho cuộn mượt.

**Kết quả kỳ vọng:** vào màn hiện ngay tin mới nhất ở đáy (0 flash, 0 jump); cuộn lên xem tin cũ mượt, không nhảy; bỏ hẳn toán `maxScrollExtent`.

---

# B · MÀN DANH SÁCH CUỘC TRÒ CHUYỆN

## 2B. Chẩn đoán

> File: `student_classroom_chat_hub_page.dart` + `student_messenger_conversation_tile.dart`.

| # | Vấn đề | `file:dòng` | Tác động |
|---|--------|-------------|----------|
| L1 | **`setState(() {})` rebuild CẢ hub** mỗi lần controller đổi (socket/tin mới/đọc) | `:79-81` `_onControllerChanged` | Header + search + filter + cả list dựng lại mỗi tick socket → khựng |
| L2 | **`_filtered` `.where().toList()` chạy mỗi build** (kể cả tick socket) | `:83-91, 126` | Lọc/sort lặp thừa |
| L3 | **Tile thiếu `key: ValueKey(room.id)`** trong `SliverChildBuilderDelegate` | `:229-234` | Khi cuộc trò chuyện nhảy lên đầu (tin mới) → diff sai → rebuild thừa, mất state |
| L4 | **Mọi tile đều accent xanh "speaking"** + có `chevron_right` | `student_messenger_conversation_tile.dart:35,102` | Đơn điệu, không giống list chat; chevron không phải idiom chat-list |
| L5 | **Loading = `pageLoading()` full-màn** | hub `:191` | Không khớp khung list; nên skeleton hàng |
| L6 | Unread pill radius `AppRadius.card`(10) cho badge số | `conversation_tile.dart:188` | Badge số nên `AppRadius.pill` |
| L7 | Sắp xếp theo recency? cần đảm bảo `controller.rooms` sort theo tin mới nhất | `dock_controller` | Cuộc trò chuyện mới nhất phải lên đầu |

## 3B. Giải pháp — gọn, mượt, "Messenger-clean"

**L1/L2 · Rebuild có chọn lọc.** Tách header (greeting/banner/search/filter — phụ thuộc `_query/_filter`) khỏi list (phụ thuộc `controller`). Bọc **chỉ** sliver list + badge đếm bằng `ListenableBuilder(listenable: _controller, …)`; bỏ `_onControllerChanged → setState` toàn trang. Memo `_filtered` theo `(rooms-version, _query, _filter)`.

**L3 · Key + skeleton.** Thêm `key: ValueKey(room.id)` cho `StudentMessengerConversationTile`. Khi `loadingRooms` → skeleton 5 hàng (khung giống tile) thay `pageLoading()`.

**L4 · Tile sạch hơn (giữ accent tinh tế).** Bố cục Messenger-clean:
```
[avatar 48 (ring khi unread)]  Tên lớp (đậm nếu unread)            12:30 (accent nếu unread)
                               Tin nhắn gần nhất (1 dòng, muted;      ● 3  (badge pill accent)
                               đậm nếu unread)
```
- **Bỏ `chevron_right`** (không phải idiom chat-list).
- Accent xanh: chỉ ở **avatar ring + time + badge khi unread**; nền thẻ `surfaceCard` phẳng, tách hàng bằng spacing `s2` (không cần viền skill-accent nặng).
- Unread: tên `w700` + preview `w600 textPrimary`; đã đọc: tên `w600` + preview `textMuted`.
- Badge số: `AppRadius.pill`, nền accent, chữ trắng (L6).
- Touch target hàng ≥ 64dp.

**L7 · Recency.** Đảm bảo `controller.rooms` sort `lastMessageAt` desc (nếu chưa, sort ở getter `_filtered`/controller).

**Tùy chọn nâng cấp:** dòng "đang gõ…" / presence dot; gộp tile vào `panel` bo góc nhóm (iOS-style) nếu muốn.

---

## 4. Audit checklist (kiểm lại sau khi sửa)

**Màn chat:**
- [ ] `ListView.builder(reverse: true)`; index 0 = tin mới nhất; header "tải tin cũ" ở đỉnh.
- [ ] Vào màn: **thấy ngay tin mới nhất ở đáy**, KHÔNG flash tin cũ, KHÔNG nhảy.
- [ ] Đã **xoá** `_scrollToBottom(maxScrollExtent)` lúc first-load, `_loadMoreAnchor`, `_ScrollAnchor`, `_restoreScrollAfterLoadMore`.
- [ ] `_scrollToBottom` đích = 0; `_isNearBottom` theo `offset<=threshold`.
- [ ] Cuộn lên nạp tin cũ: **không nhảy** vị trí; trigger theo `maxScrollExtent - pixels <= threshold`.
- [ ] Mỗi item có `ValueKey(msg.id)`; RepaintBoundary giữ; `cacheExtent` ~800.
- [ ] Date separator + grouping vẫn đúng (separator trên tin đầu ngày).
- [ ] Đo: DevTools Performance — cuộn nhanh chat raster < 16ms; không thấy "jump" khi vào màn.

**Màn danh sách:**
- [ ] Tick socket KHÔNG rebuild cả trang (chỉ list/badge qua `ListenableBuilder`).
- [ ] Tile có `key: ValueKey(room.id)`; loading = skeleton hàng.
- [ ] Tile: bỏ chevron; unread đậm; time/badge accent; badge `pill`; hàng ≥ 64dp.
- [ ] Cuộc trò chuyện mới nhất ở đầu (sort recency).
- [ ] `dart analyze lib` 0 lỗi mới.

---

## 5. Bản đồ file ↔ việc

| File | Việc | Mục |
|------|------|-----|
| `classroom_chat_body.dart` | reverse list + đảo chỉ số; xoá jumpTo first-load + anchor; đổi trigger load-more; đích scroll = 0; key+cacheExtent | C1–C6 / 3A |
| `chat_message_bubble.dart` | giữ (ảnh đã cố định kích thước); đảm bảo `ValueKey` truyền vào item ở body | C-✅ |
| `student_classroom_chat_hub_page.dart` | tách header/list; `ListenableBuilder` quanh list+badge; bỏ setState toàn trang; skeleton hàng; key tile | L1,L2,L3,L5 |
| `student_messenger_conversation_tile.dart` | bố cục Messenger-clean; bỏ chevron; unread emphasis; badge pill; accent tinh tế; ≥64dp | L4,L6 |
| `classroom_chat_dock_controller.dart` | đảm bảo sort `rooms` theo recency | L7 |

> Ghi commit vào [`11-implementation-mapping.md`](11-implementation-mapping.md) "Migration log". Tham chiếu chuẩn mobile [`20`](20-student-mobile-audit-and-standards.md) (skeleton, touch-target, reduce-motion).
</content>
