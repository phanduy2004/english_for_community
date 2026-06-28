# Work-Order — BUG: Tab Messages (student mobile) không đồng bộ chrome với Progress/Profile

- **Task ID:** 20260626-messages-hub-chrome-sync
- **Loại:** BUG (UI inconsistency / visual defect)
- **Mục tiêu:** Tab Tin nhắn dùng cùng "chrome" với các tab tiện ích khác (AppBar căn giữa, h2/14px; component phẳng; màu avatar không như cảnh báo).
- **Cỡ task:** MICRO (2 file code, ~30 LOC net + cập nhật doc) → 1 work-order (file này).
- **Người phân tích + IMPLEMENT:** **Opus** (theo yêu cầu trực tiếp "sửa lại" ở lượt trước — ngoại lệ "Opus tự code"). **Auditor:** **Cursor** (theo yêu cầu "nhờ cursor audit luôn"). **Status:** ✅ ĐÃ IMPLEMENT + `dart analyze` sạch — **chờ Cursor AUDIT (Phase 4)**.

> Quy ước: artifact theo `docs/AI-Working-Process-vi.md`. Ngoại lệ quy trình: code đã được Opus áp dụng *trước khi* quy trình được chốt; vì vậy đây là work-order **hồi tố** + handoff **AUDIT** (không phải IMPLEMENT).
>
> ⚠️ **Lưu ý dirty state:** 2 file code này đã ở trạng thái `M` (uncommitted) **từ trước phiên này**. `git diff` HEAD→working trộn lẫn thay đổi cũ + thay đổi của task này. **Phạm vi audit = đúng 3 thay đổi liệt kê ở §5**, không phải toàn bộ git diff.

---

## 1. Vấn đề + nguyên nhân gốc (có dẫn chứng code)

**Triệu chứng (user):** màn danh sách cuộc trò chuyện không đồng bộ với Progress; chữ AppBar to hơn + sát trái; component "thô"; màu sắc "ko hợp lý".

**Ground-truth (đã đọc code thật):**

| # | Vấn đề | Nguyên nhân gốc | Dẫn chứng |
|---|--------|-----------------|-----------|
| **P1** | Tiêu đề to (16px) + **sát trái**, khác các tab khác | Messages vẽ header **trong thân scroll** bằng `StudentMobileUi.greeting` (h1=16px) thay vì dùng AppBar thật. Progress + Profile đều dùng `StudentMobileUi.appBar` → tiêu đề **căn giữa** (theme `appBarTheme.centerTitle:true`), **h2=14px** (`sectionTitle`) | `student_classroom_chat_hub_page.dart` header Row (cũ); `profile_page.dart:304` `appBar(..., showBack:false)`; `progress_report_page.dart:227`; `app_theme.dart:44`; `app_typography.dart` mobileH1=16/mobileH2=14 |
| **P2** | Component "thô" | List bọc trong `_GroupedCard` có **box-shadow 2 lớp** (blur 14 + 3) trong khi mọi card khác (`AppCard outline`) phẳng, elevation 0 | `_GroupedCard` (cũ); `app_theme.dart` cardTheme elevation 0; doc `23 §3.4` (hàng phẳng) |
| **P3** | Màu "ko hợp lý" | `groupAvatarColors` hash tên lớp lên palette gồm **danger (đỏ)** + **warning (cam)** + 1 entry **`dangerBg` trùng** → avatar trông như cảnh báo, lệch tông Editorial-Black/warm-stone | `classroom_chat_ui.dart:332` (cũ); doc `23 §3.3` yêu cầu "palette trung tính-tươi" |

**Chuẩn tham chiếu (đồng bộ về cái này):** `ProfilePage` = `Scaffold(appBar: StudentMobileUi.appBar(title, showBack:false), body: RefreshIndicator(...))` — đây là pattern "tab tiện ích gốc" đúng.

---

## 2. Audit downstream (consumer của phần bị đổi)

| Consumer | File:line | Ảnh hưởng |
|----------|-----------|-----------|
| `ConversationTile` | `conversation_tile.dart:62` | **Consumer DUY NHẤT** của `groupAvatarColors`; dùng chung cho cả **web dock** (teacher/admin) + **mobile hub** → đổi palette propagate đồng bộ 2 nơi (ý muốn) |
| `StudentMobileUi.appBar` | `student_mobile_ui.dart:86` | Helper dùng chung; **không sửa** — chỉ thêm 1 call site mới ở Messages |
| `_GroupedCard` | local `student_classroom_chat_hub_page.dart` | Local widget, không export → đổi shadow không ảnh hưởng nơi khác |
| `_hubBadge` | local | Trước dùng trong header in-body; nay dùng trong `appBar.actions` — không đổi chữ ký |

→ Rủi ro lan: thấp. Điểm cần để mắt: palette avatar đổi cả tile web (đã xác nhận là consumer duy nhất, đúng ý doc 23 "dùng chung web+mobile").

---

## 3. Quyết định thiết kế + cảnh báo

- **Quyết định:** Messages theo pattern Profile (`appBar` thật, `showBack:false`). Số lớp/chưa đọc dời vào `appBar.actions` (caption `textMuted`) thay vì badge cạnh tiêu đề.
- **Đánh đổi:** mất ~1 dòng "list-forward" mà brief `messages-hub.md` cũ ưu tiên; bù lại được **đồng bộ cross-tab** (ưu tiên cao hơn theo user). Doc đã cập nhật.
- **Cảnh báo tương lai:**
  - `ProgressReportPage` vẫn để `showBack` mặc định = `true` → có **mũi tên back thừa** ở tab gốc (Profile đúng = false). Chưa sửa trong task này — ứng viên cleanup riêng.
  - Palette avatar nay là hằng `_avatarPalette` (hex thô trong `classroom_chat_ui.dart`) — nếu sau này token-hoá thì gom về `AppColors`/identity tokens.

---

## 4. Scope IN / OUT

**IN (đã chạm):**
- `english_for_community/lib/feature/student/messages/student_classroom_chat_hub_page.dart` — P1 (appBar) + P2 (grouped card).
- `english_for_community/lib/feature/classroom_chat/widgets/classroom_chat_ui.dart` — P3 (palette).
- Docs: `messages-hub.md`, `23-conversation-list-redesign.md` §3.3, `11-implementation-mapping.md` (migration log).

**OUT (chạm là DỪNG & hỏi):**
- ❌ `conversation_tile.dart` logic/layout (chỉ tiêu thụ palette, không đổi).
- ❌ `StudentMobileUi` (shared) — không đổi helper.
- ❌ Chat thread (`ClassroomChatPage`) và web dock layout.
- ❌ `ProgressReportPage` / `ProfilePage` (chỉ tham chiếu, không sửa).
- ❌ Thay đổi behavior controller / socket / filter logic.

---

## 5. Diff cụ thể (ĐÃ áp dụng — Cursor audit đối chiếu đúng 3 mục này)

### Δ1 — `student_classroom_chat_hub_page.dart` · thêm AppBar + bỏ header in-body
`build()`, Scaffold:
```dart
return Scaffold(
  backgroundColor: AppColors.surface,
  appBar: StudentMobileUi.appBar(
    context,
    title: l10n.navMessages,
    showBack: false,
    actions: [
      ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final total = _controller.rooms.length;
          if (total == 0) return const SizedBox.shrink();
          final unread = _controller.unreadConversations;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s4),
            child: Center(
              child: Text(
                _hubBadge(l10n, unread, total),
                style: StudentMobileUi.caption(context)
                    .copyWith(color: AppColors.textMuted),
              ),
            ),
          );
        },
      ),
    ],
  ),
  body: SafeArea(
    top: false,                       // AppBar đã ăn inset top
    child: RefreshIndicator( ... )),
);
```
- **Bỏ** block `Row([Expanded(Text(navMessages, greeting)), ListenableBuilder(count)])` + `SizedBox(s3)` đứng đầu `SliverChildListDelegate` → sliver giờ bắt đầu bằng `searchField`.

### Δ2 — `student_classroom_chat_hub_page.dart` · `_GroupedCard` phẳng lại
```dart
final radius = BorderRadius.circular(AppRadius.card);   // was: card + 2
// boxShadow: bỏ 2 lớp (blur 14 + 3) → 1 hairline:
boxShadow: const [
  BoxShadow(color: AppColors.shadowHairline, blurRadius: 1, offset: Offset(0, 1)),
],
```

### Δ3 — `classroom_chat_ui.dart` · `groupAvatarColors` → palette trung tính-tươi
```dart
static const List<({Color background, Color foreground})> _avatarPalette = [
  (background: Color(0xFFEEF2F7), foreground: Color(0xFF475569)), // slate
  (background: Color(0xFFE6F4F1), foreground: Color(0xFF0F766E)), // teal
  (background: Color(0xFFEEF2FF), foreground: Color(0xFF4F46E5)), // indigo
  (background: Color(0xFFF3EEFB), foreground: Color(0xFF7C3AED)), // violet
  (background: Color(0xFFFCEEF1), foreground: Color(0xFFBE185D)), // rose
  (background: Color(0xFFF1EDE5), foreground: Color(0xFF8A5A2B)), // sand
  (background: Color(0xFFE9F5EC), foreground: Color(0xFF15803D)), // green
  (background: Color(0xFFE3F2FB), foreground: Color(0xFF0369A1)), // cyan
];
// hash tên giữ nguyên; bỏ danger/warning + entry dangerBg trùng.
```

---

## 6. Lệnh verify

```bash
cd english_for_community
dart analyze lib/feature/student/messages/student_classroom_chat_hub_page.dart \
             lib/feature/classroom_chat/widgets/classroom_chat_ui.dart \
             lib/feature/classroom_chat/widgets/conversation_tile.dart
#   → đã chạy: "No issues found!"
```

**Nghiệm thu (acceptance):**
- Tab Tin nhắn có AppBar: tiêu đề **căn giữa, 14px**, **không mũi tên back**, action phải = "N lớp"/"N chưa đọc".
- List bọc card **phẳng** (không bóng nổi), khớp card Progress/Home.
- Avatar nhóm không-ảnh = chữ cái trên nền tint dịu (không đỏ/cam cảnh báo).
- `dart analyze` 0 lỗi mới.
- (Mắt) 360×640: chrome khớp Progress khi chuyển tab qua lại.

---

## 7. HANDOFF AUDIT PROMPT cho Cursor (copy nguyên khối)

```text
Bạn là AUDITOR (không implement, không sửa code trừ khi tìm thấy lỗi và tôi cho phép).
Repo: english_for_community (Flutter). Work-order: docs/plantasks/BUG/20260626-messages-hub-chrome-sync/work-order.md

NHIỆM VỤ: Audit ĐÚNG 3 thay đổi ở §5 của work-order (Δ1/Δ2/Δ3). 2 file đang dirty từ trước phiên — CHỈ xét 3 thay đổi này, BỎ QUA các thay đổi uncommitted khác trong cùng file.

FILE:
  1. lib/feature/student/messages/student_classroom_chat_hub_page.dart  (Δ1 appBar, Δ2 grouped card)
  2. lib/feature/classroom_chat/widgets/classroom_chat_ui.dart           (Δ3 _avatarPalette)

KIỂM:
  - Δ1: AppBar = StudentMobileUi.appBar(title: navMessages, showBack:false); header in-body cũ (greeting Row) đã bị bỏ; count nằm trong actions; body SafeArea(top:false). Tiêu đề căn giữa 14px như Profile/Progress.
  - Δ2: _GroupedCard radius=AppRadius.card; chỉ 1 boxShadow hairline (bỏ 2 lớp blur 14+3).
  - Δ3: groupAvatarColors dùng _avatarPalette 8 cặp, KHÔNG còn AppColors.danger/warning/dangerBg trùng; hash logic giữ nguyên; xác nhận consumer duy nhất là conversation_tile.dart (web+mobile) → không vỡ web dock.
  - Không scope-creep: KHÔNG đụng conversation_tile layout, StudentMobileUi, chat thread, Progress/Profile.
  - A11y/contrast: 8 cặp màu avatar đủ tương phản chữ-trên-nền.

VERIFY: dart analyze 2 file trên + conversation_tile.dart → phải "No issues found!".
KẾT QUẢ: trả verdict APPROVED hoặc list finding kèm file:line. KHÔNG dán full file vào chat.
```

---

## 8. Checklist OPUS AUDIT (đối chiếu khi Cursor xong)

- [ ] Δ1 đúng: appBar(showBack:false), bỏ header in-body, count→actions, body SafeArea(top:false).
- [ ] Δ2 đúng: radius card, 1 hairline shadow.
- [ ] Δ3 đúng: 8-color calm palette, bỏ danger/warning/duplicate, hash giữ nguyên.
- [ ] Không scope-creep (file OUT không bị đụng bởi task này).
- [ ] `dart analyze` 0 lỗi mới (đã: pass).
- [ ] Doc đã sync: `messages-hub.md`, `23` §3.3, `11` migration log.
- [ ] Cursor verdict ghi lại + chốt.

---

## 9. Việc thực tế còn lại của DEV (ngoài code)

1. Cursor chạy AUDIT theo §7 → dán verdict.
2. Chạy app, đổi qua lại các tab (Home/Messages/Progress/Profile) xác nhận chrome khớp bằng mắt trên thiết bị thật.
3. (Tùy chọn cleanup riêng) Sửa `ProgressReportPage` → `showBack:false` cho hết mũi tên back thừa.
4. Commit (2 file code đang dirty kèm thay đổi cũ — tách commit nếu cần giữ atomic).
