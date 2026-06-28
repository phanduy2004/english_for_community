# Screen Brief — Messages hub (student)

> Áp blueprint **A5 · Conversation list** ([`../01-screen-archetypes.md`](../01-screen-archetypes.md)) vào màn thật.
> **Màn:** tab Tin nhắn học sinh · **File:** `lib/feature/student/messages/student_classroom_chat_hub_page.dart` + tile `feature/classroom_chat/widgets/conversation_tile.dart`.
> **Trạng thái:** ✅ **Đã triển khai (06/2026):** màu đồng bộ **primary**; **danh sách = inset grouped card** (divider inset). *(Chat thread giữ nguyên bản gốc — bản thử nghiệm premium đã được revert.)* Phần dưới giữ làm tham chiếu bố cục/nhịp dọc.
>
> **Cập nhật 06/2026 (b) — đồng bộ chrome giữa các tab:** header **chuyển sang `StudentMobileUi.appBar(title: Messages, showBack:false)`** thay cho header in-body `greeting` (h1, sát trái). Lý do: hai tab tiện ích khác — **Progress** và **Profile** — đều dùng `StudentMobileUi.appBar` (tiêu đề **căn giữa**, **h2/14px** do `appBarTheme.centerTitle:true`); header in-body khiến Messages lệch (chữ to hơn + sát trái). Số lớp/chưa đọc dời vào `actions` (caption `textMuted`). Đồng thời: **grouped card phẳng lại** (bỏ shadow 2 lớp → 1 hairline, radius `card`=10) cho khớp `AppCard(outline)`; **palette avatar** đổi sang bộ **trung tính-tươi** (bỏ danger/warning để không trông như cảnh báo) — xem [`../../23-conversation-list-redesign.md`](../../23-conversation-list-redesign.md) §3.3.

---

## 1. Hiện trạng (đo theo token)

```
┌──────────────────────────────────────────┐  pagePadding = LTRB(s? 12,10,12,20)
│  Messages                          (h1)    │
│  Nhóm chat các lớp                 (body)  │  greeting + subtitle
│   ↕ s4                                      │
│ ┌────────────────────────────────────────┐│
│ │ Kết nối với lớp            💬           ││  skillHubBanner (skill:null)
│ │ Chat với bạn & GV trong mỗi lớp.        ││   → cao ~ 3 dòng + icon 44 + padding s4
│ │ ( 1 classes )                           ││   badge = số lớp
│ └────────────────────────────────────────┘│
│   ↕ s4                                      │
│ [🔍 Tìm lớp…                             ] │  searchField
│   ↕ s3                                      │
│ (Tất cả)(Chưa đọc)                         │  filterRow
│   ↕ sectionGap(14)                          │
│  Cuộc trò chuyện                      1     │  _SectionHeader + count pill
│   ↕ s3                                      │
│ ───────────────────────────────────────── │
│ (A) 10A1 — Ca sáng              12:30      │  ConversationTile (row 72)
│     Cô Lan: …                      ● 3     │
└──────────────────────────────────────────┘
```

**Đo:** từ đỉnh tới hội thoại đầu tiên ≈ greeting+subtitle + `s4` + **banner ~104dp** + `s4` + search + `s3` + filter + `sectionGap` + section + `s3`. → **~5 khối chrome** trước item đầu. Với 1–2 lớp (phổ biến) màn **top-heavy, trống** (xem screenshot 06/2026).

### Đánh giá
| ✅ Giữ | ⚠️ Sửa |
|--------|--------|
| Tile phẳng + divider inset + avatar identity + badge pill (đúng A5/`23`) | **Banner 3 dòng** lặp ý subtitle + chiếm ~104dp cho thông tin tĩnh |
| Màu primary (đã hết emerald) | **2 lớp "tiêu đề"**: subtitle ("Nhóm chat các lớp") ≈ banner title ("Kết nối với lớp") |
| Skeleton + empty + search-empty | **Đếm lớp** hiển thị 2 nơi: badge banner + count section |
| Rebuild chọn lọc (`ListenableBuilder`) | Nhịp dọc rời rạc khi ít hội thoại |

---

## 2. Target layout (refined) — gọn, hội thoại lên sớm

Theo A5 + Messenger/Telegram (header mỏng, list-forward). **Bỏ banner to**, gộp thông tin vào **header 1 khối** + giữ search/filter; section header tùy chọn ẩn khi list ngắn.

```
TRƯỚC (top-heavy)                     SAU (list-forward, Messenger-clean)
┌───────────────────────────┐        ┌───────────────────────────┐
│ Messages          (h1)     │        │ Messages              1 lớp│  header 1 hàng: title + meta phải
│ Nhóm chat các lớp          │        │                            │
│ ┌───────────────────────┐ │        │ [🔍 Tìm lớp…             ] │  search ngay dưới
│ │ Kết nối với lớp  💬     │ │        │ (Tất cả)(Chưa đọc)         │  filter
│ │ Chat với bạn & GV…     │ │        │ ───────────────────────── │
│ │ ( 1 classes )          │ │        │ (A) 10A1 — Ca sáng  12:30 │  hội thoại lên cao ~1 màn-thứ-3
│ └───────────────────────┘ │        │     Cô Lan: …       ● 3    │
│ [🔍 …]  (Tất cả)(Chưa đọc) │        │ ───────────────────────── │
│ Cuộc trò chuyện       1    │        │ (B) 11B1 — …        3d     │
│ ───────────────────────── │        │     Bạn: …                 │
│ (A) 10A1 …          12:30  │        └───────────────────────────┘
└───────────────────────────┘        ↳ tiết kiệm ~120–140dp chrome
```

### Zones (target)
| Zone | Nội dung | Token | Ghi chú |
|------|----------|-------|---------|
| Header | `Messages` (h1) ── `N lớp` (caption, phải) | textPrimary / textMuted | gộp đếm lớp vào đây (bỏ badge banner + count section) |
| Search | `searchField` | surfaceSubtle + outline | sát header, ↕ `s3` |
| Filter | `filterRow` (Tất cả/Chưa đọc) | primary selected | ↕ `s3` |
| Divider | hairline inset | outlineMuted | mở đầu list |
| List | `ConversationTile` + divider inset | surfaceCard | row 72, lên sớm |

> **Bỏ `_SectionHeader`** "Cuộc trò chuyện · N" khi đã có "N lớp" ở header (tránh đếm 2 nơi). Nếu muốn giữ nhóm (vd "Chưa đọc"/"Tất cả"), chỉ hiện section khi filter tạo ra nhóm con.

### Tùy chọn giữ banner (nếu sản phẩm muốn onboarding nhẹ)
Thu **banner → strip 1 dòng** (không phải card 3 dòng):
```
│ 💬  Chat với bạn & giáo viên trong lớp.        │  ← 1 dòng, icon nhỏ 20, padding s3, surfaceSubtle
```
Chỉ hiện **lần đầu / khi 0 hội thoại**; có hội thoại → ẩn để list lên. (Pattern "first-run hint" — `15`.)

---

## 3. Build diff (đường dẫn cụ thể cho Cursor)

File: `student_classroom_chat_hub_page.dart`, `build()`:

1. **Header 1 hàng có meta phải** — thay 2 dòng `Text(navMessages)` + `Text(subtitle)` bằng `Row(title h1 ── '$total lớp' caption)`. Lấy `total` từ `_controller.rooms.length` (bọc trong `ListenableBuilder` đang có).
   ```dart
   Row(children: [
     Expanded(child: Text(l10n.navMessages, style: StudentMobileUi.greeting(context))),
     ListenableBuilder(
       listenable: _controller,
       builder: (_, __) => Text(
         l10n.studentChatHubClassCount(_controller.rooms.length),
         style: StudentMobileUi.caption(context).copyWith(color: AppColors.textMuted),
       ),
     ),
   ]),
   ```
2. **Bỏ `skillHubBanner`** (cả block `ListenableBuilder` bao nó) — hoặc thay bằng strip 1 dòng có điều kiện `if (total == 0)`.
3. **Bỏ subtitle** `Text(studentChatHubSubtitle)` (đã gộp ý vào strip/header).
4. **Bỏ `_SectionHeader`** + `SizedBox` quanh nó (đếm đã ở header). Giữ 1 `Divider` inset mở đầu list.
5. Giữ nguyên: `searchField`, `filterRow`, list `SliverList` + `ConversationTile`, skeleton, empty/error.
6. Spacing mới: header → `s3` → search → `s3` → filter → `s2` → divider → list. (Giảm `s4`/`sectionGap` thừa.)

> Không đụng `conversation_tile.dart` (đã đạt A5). Không đụng `StudentMobileUi` (dùng chung).

---

## 4. States (đã có — chỉ kiểm lại)
- Loading → `ConversationTileSkeleton ×5` ✔
- Empty (0 lớp) → `emptyState(forum)` ✔ (nếu giữ strip onboarding, ưu tiên empty-state khi 0).
- Search empty → `emptyState(search_off)` ✔
- Error → `errorBanner` + retry ✔

## 5. Checklist
- [x] Header = `StudentMobileUi.appBar(title: Messages, showBack:false)` — căn giữa, h2/14px, đồng bộ Progress/Profile; `N lớp`/chưa đọc ở `actions`.
- [ ] Bỏ banner to (hoặc strip 1 dòng, chỉ khi 0 hội thoại).
- [ ] Bỏ `_SectionHeader` đếm trùng.
- [ ] Hội thoại đầu tiên xuất hiện cao hơn ≥ ~120dp so với trước.
- [ ] Không đụng tile / shared UI; màu vẫn primary (0 emerald).
- [ ] `dart analyze lib/feature/student/messages` 0 lỗi mới.
- [ ] Xem trên 360×640: ít hội thoại không còn "trống/top-heavy".

> Áp xong ghi vào [`../../11-implementation-mapping.md`](../../11-implementation-mapping.md) "Migration log".
