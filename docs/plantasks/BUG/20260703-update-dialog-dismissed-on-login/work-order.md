# Work-Order — BUG: Dialog cập nhật hiện rồi tắt vội khi đăng nhập (bị điều hướng gỡ)

- **Task ID:** 20260703-update-dialog-dismissed-on-login
- **Loại:** BUG · **Platform:** student mobile (Flutter) · **Cỡ:** MICRO→T1 (1 file, ~40 LOC)
- **Mục tiêu:** Sau khi đăng nhập, dialog "Có bản cập nhật" phải **hiện và Ở LẠI** trên màn dashboard, không bị tắt vội khi chuyển login → home.
- **Người phân tích:** Opus (brain). **Implementer:** Cursor. **Status:** ROOT CAUSE XÁC ĐỊNH — chờ implement.
- **Liên quan:** nối tiếp `20260702-mobile-update-dialog-context` (fix context — đã APPROVED). ⚠️ Chạm cùng file với FEATURE `20260703-in-app-apk-update` (chưa implement) — xem mục 11 (thứ tự).

---

## 1. Vấn đề + nguyên nhân gốc (dẫn chứng)

**Triệu chứng:** đăng nhập xong → dialog cập nhật lóe lên → **tự tắt** → nhảy thẳng vào dashboard student.

**Root cause — pageless route bị gỡ theo page login khi redirect:**
- `login` (`/login`, `app_router.dart:366`) và `home` (`/home`, `:372`) đều là GoRoute **cấp cao trên root navigator** (`navigatorKey: rootNavigatorKey`, `:137`).
- `refreshListenable: GoRouterRefreshStream(getIt<UserBloc>().stream)` (`:138`) → mỗi lần UserBloc đổi state → chạy lại `redirect`. Đăng nhập thành công (user thường) → `redirect` trả `HomePage.routePath` (`:215-219`) → go_router **thay** pages `[login]` → `[home]`.
- Dialog cập nhật được `showDialog(context: rootNavigatorKey.currentContext)` (`app_update_guard.dart:95-106`) → là **pageless route bám vào page `login`**. Khi page `login` bị gỡ lúc redirect, Flutter gỡ luôn pageless route → **dialog văng** đúng lúc `home` hiện.

**2 lỗi phụ khiến không hiện lại:**
- `_lastShownVersionCode = info.latestVersionCode` set **trước** `await _showUpdateDialog` (`app_update_guard.dart:83-85`) → sau khi bị gỡ, đã coi như "đã hiện".
- `listenWhen: (prev, next) => prev.info != next.info` (`:74`) → lần check lại sau login trả **cùng** info → listener không fire → không show lại.
- Gate `if (_lastShownVersionCode == info.latestVersionCode && info.status != forceUpdate) return;` (`:79-82`) → soft update cùng version bị chặn show lại.

**Kết quả:** dialog chỉ "lóe" trên page login rồi chết theo redirect, và không bao giờ hiện lại trên home trong session đó.

---

## 2. Audit downstream

| Điểm | File:line | Ghi chú |
|---|---|---|
| Trigger check | `app_update_guard.dart:32-72` | Check vẫn chạy đúng (open/resume/auth). Không phải lỗi check. |
| BlocListener show dialog | `app_update_guard.dart:73-88` | Nơi phát sinh: show ngay + dedup optimistic. |
| `_showUpdateDialog` | `app_update_guard.dart:95-107` | Dùng `rootNavigatorKey.currentContext` (đúng, từ fix trước). |
| Router redirect | `app_router.dart:141-224` | login→home thay page; teardown pageless route. KHÔNG sửa router. |

---

## 3. Hướng fix (thiết kế)

Chuyển từ "show ngay khi info tới" → **"giữ pending update + hiện lại khi auth/route đã settle, chỉ clear khi user thật sự bấm nút"**:

1. Giữ `AppUpdateInfoEntity? _pendingUpdate` (bản cần hiện) + `int? _handledVersionCode` (version user đã bấm "Để sau" trong session).
2. **Chỉ hiện khi auth đã settle** (`status == success | unauthenticated`), KHÔNG hiện lúc `loading/initial` (đang redirect) → tránh bám vào page login sắp bị gỡ.
3. Sau khi đăng nhập (UserBloc listener success) → gọi lại `_tryShowPending()` qua **post-frame** → lúc này `home` đã build xong → dialog bám vào `home` → **ở lại**.
4. Phân biệt "user bấm nút" vs "bị điều hướng gỡ" bằng **kết quả `showDialog`**:
   - `showDialog<bool>` + `barrierDismissible: false` → dismiss chỉ qua nút.
   - Nút "Để sau" → `pop(true)` → result `true` = user xử lý → set `_handledVersionCode`, clear `_pendingUpdate` (thôi nag).
   - Bị gỡ do điều hướng → future hoàn thành `null` → **giữ** `_pendingUpdate` → hiện lại khi settle kế tiếp.

**Không đổi:** luồng check/bloc/entity/datasource, `rootNavigatorKey`, router.

---

## 4. Scope IN / OUT

**IN:** duy nhất `english_for_community/lib/feature/app_update/app_update_guard.dart`.

**OUT (chạm là DỪNG & hỏi):**
- ❌ `app_router.dart` (redirect/route/navigatorKey), `main.dart`, `global_keys.dart`.
- ❌ bloc/datasource/entity/version-check backend/CI.
- ❌ Đổi cơ chế so sánh version, luồng iOS/web.

---

## 5. Diff cụ thể (Cursor tự viết code; code mẫu ở phần orchestration tinh tế)

File: `lib/feature/app_update/app_update_guard.dart`

**(a) State mới** (cạnh `_dialogShowing`, `_lastShownVersionCode` — bỏ `_lastShownVersionCode`):
```dart
bool _dialogShowing = false;
AppUpdateInfoEntity? _pendingUpdate;
int? _handledVersionCode; // version user đã bấm "Để sau" trong session
```

**(b) `didChangeAppLifecycleState`** (resume): sau khi add check, gọi `_tryShowPending()`:
```dart
if (state == AppLifecycleState.resumed) {
  if (!mounted) return;
  context.read<AppUpdateBloc>().add(AppUpdateCheckRequested(forceRefresh: true));
  _tryShowPending();
}
```

**(c) UserBloc listener** (`:62-72`): sau khi add check, gọi `_tryShowPending()` (để hiện lại pending khi đã settle sang home/login):
```dart
listener: (context, state) {
  context.read<AppUpdateBloc>().add(AppUpdateCheckRequested(forceRefresh: true));
  _tryShowPending();
},
```

**(d) AppUpdateBloc listener** (`:73-88`): chỉ set pending rồi thử hiện, KHÔNG show trực tiếp + dedup optimistic:
```dart
BlocListener<AppUpdateBloc, AppUpdateState>(
  listenWhen: (prev, next) => prev.info != next.info,
  listener: (context, state) {
    final info = state.info;
    if (info == null || !info.hasUpdate) {
      _pendingUpdate = null;
      return;
    }
    _pendingUpdate = info;
    _tryShowPending();
  },
),
```

**(e) Method mới `_tryShowPending()`** (logic tinh tế — bám sát):
```dart
void _tryShowPending() {
  final info = _pendingUpdate;
  if (info == null || _dialogShowing) return;

  // Chỉ hiện khi auth ĐÃ settle. Lúc redirect (loading/initial) mà show thì dialog
  // bám vào page login sắp bị gỡ -> văng. UserBloc listener sẽ gọi lại khi success.
  final authStatus = context.read<UserBloc>().state.status;
  if (authStatus == UserStatus.initial || authStatus == UserStatus.loading) return;

  // Soft đã bị user bỏ qua trong session -> không nag lại (force thì luôn hiện).
  if (_handledVersionCode == info.latestVersionCode &&
      info.status != AppUpdateStatus.forceUpdate) {
    return;
  }

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!mounted || _dialogShowing || _pendingUpdate == null) return;
    _dialogShowing = true;
    final result = await _showUpdateDialog(info); // true = user bấm nút; null = bị gỡ
    _dialogShowing = false;
    if (result == true) {
      _handledVersionCode = info.latestVersionCode;
      _pendingUpdate = null;
    }
    // result == null -> giữ _pendingUpdate; hiện lại khi auth/route settle hoặc resume.
  });
}
```

**(f) `_showUpdateDialog`** (`:95-107`): trả `bool?`, khoá barrier:
```dart
Future<bool?> _showUpdateDialog(AppUpdateInfoEntity info) async {
  final host = rootNavigatorKey.currentContext;
  if (host == null) return null;
  return showDialog<bool>(
    context: host,
    barrierDismissible: false, // dismiss chỉ qua nút -> phân biệt teardown(null) vs user(true)
    useRootNavigator: true,
    builder: (dialogContext) => _UpdateDialogContent(info: info),
  );
}
```

**(g) Nút "Để sau"** trong `_UpdateDialogContent` (2 layout: cột `:268-275` và hàng `:282-286`): `pop()` → `pop(true)`:
```dart
onPressed: () => Navigator.of(context).pop(true),
```
(Nút "Cập nhật ngay" GIỮ NGUYÊN — mở link, không pop; force vẫn `PopScope canPop:false`, không có "Để sau".)

**RÀNG BUỘC:**
- Bỏ hẳn `_lastShownVersionCode` (thay bằng `_handledVersionCode`) và bỏ khối show trực tiếp trong listener cũ.
- `if (!mounted) return;` trước mọi `setState`/`await` tiếp xúc context sau await.
- Không đổi nội dung/logic `_UpdateDialogContent` ngoài 2 chỗ `pop(true)`.

---

## 6. Vì sao fix này đúng
- Không show lúc `loading/initial` → không bám vào page login → **không teardown**.
- UserBloc success → post-frame (sau khi `home` build) → dialog bám vào `home` → **ở lại**.
- Pending chỉ clear khi user bấm nút (result==true) → bị gỡ do điều hướng thì **tự hiện lại** ở lần settle kế.
- Force update: `barrierDismissible:false` + không "Để sau" → chỉ đóng khi cập nhật/app bị thay → luôn được hiện lại tới khi xử lý.

---

## 7. Lệnh verify
```bash
cd english_for_community
flutter analyze lib/feature/app_update/app_update_guard.dart   # 0 lỗi
flutter test
```
**Smoke thiết bị (bắt buộc — cần 1 bản published > versionCode máy):**
```bash
flutter run --dart-define-from-file=config/prod.json   # versionCode=1 < bản published
```
Kịch bản:
1. Mở app ở màn **login** (chưa đăng nhập) → dialog hiện & **ở lại** (không nav → không tắt).
2. **Đăng nhập** → dialog (nếu đang hiện) có thể lóe rồi **hiện lại và Ở LẠI trên dashboard** (không còn tắt vội mất hút).
3. Bấm "Để sau" → đóng, **không nag lại** trong session (soft).
4. Force update: dialog không tắt được; sau đăng nhập vẫn ở lại trên dashboard.

## 8. Hồi quy tối thiểu
1. `up_to_date` → không hiện dialog.
2. Đang mở dialog, background→foreground (resume) → không mở chồng dialog (`_dialogShowing`).
3. Logout (success→unauthenticated) → nếu có pending, hiện trên login, không crash.
4. Nút "Cập nhật ngay" vẫn mở được link (soft) / vẫn chặn đóng (force).

---

## 9. HANDOFF PROMPT cho Cursor
```text
Bạn là implementer. CHỈ sửa 1 file; ngoài danh sách → DỪNG & hỏi.
Repo: english_for_community (Flutter).

FILE: lib/feature/app_update/app_update_guard.dart

THEO ĐÚNG mục 5 work-order:
  (a) state: bỏ _lastShownVersionCode, thêm _pendingUpdate + _handledVersionCode
  (b) resume: gọi _tryShowPending()
  (c) UserBloc listener: gọi _tryShowPending() sau khi add check
  (d) AppUpdateBloc listener: chỉ set _pendingUpdate + _tryShowPending() (bỏ show trực tiếp + dedup cũ)
  (e) thêm _tryShowPending() (đúng logic mẫu: chặn khi auth loading/initial; post-frame; result==true mới clear)
  (f) _showUpdateDialog -> Future<bool?>, showDialog<bool>, barrierDismissible:false
  (g) nút "Để sau" (2 layout) -> Navigator.of(context).pop(true)

TUYỆT ĐỐI KHÔNG: đụng app_router.dart/main.dart/global_keys.dart/bloc/datasource/entity;
  đổi nút "Cập nhật ngay"; đổi nội dung _UpdateDialogContent ngoài 2 chỗ pop(true).

VERIFY: flutter analyze lib/feature/app_update/app_update_guard.dart (0 lỗi);
  smoke thiết bị: đăng nhập -> dialog Ở LẠI trên dashboard (không tắt vội).
Xong -> dán analyze + clip/ảnh smoke vào tracker -> báo Opus audit.
```

## 10. Checklist OPUS AUDIT (Phase 4)
- [ ] Chỉ sửa `app_update_guard.dart`; không đụng file OUT.
- [ ] Bỏ `_lastShownVersionCode` + show-trực-tiếp; thêm `_pendingUpdate`/`_handledVersionCode`/`_tryShowPending`.
- [ ] `_tryShowPending` chặn khi `authStatus` loading/initial; show qua post-frame; `!mounted` guard.
- [ ] `_showUpdateDialog` trả `bool?`, `barrierDismissible:false`; "Để sau" pop(true) (cả 2 layout).
- [ ] result==true → clear pending + set `_handledVersionCode`; null → giữ pending (hiện lại khi settle).
- [ ] Không mở chồng dialog; force vẫn không đóng được.
- [ ] `flutter analyze` 0 lỗi; smoke: đăng nhập → dialog ở lại dashboard.

---

## 12. Kết quả OPUS AUDIT (Phase 4) — 2026-07-03

**Đã đọc DIFF thật** (`git diff app_update_guard.dart`) + trace luồng login.

| Mục | Kết quả |
|---|---|
| Scope | ✅ Chỉ `app_update_guard.dart`. `git status` các file OUT → không đụng. |
| Đúng fix | ✅ Bỏ `_lastShownVersionCode`; thêm `_pendingUpdate`/`_handledVersionCode`/`_tryShowPending`. Listener AppUpdate chỉ set pending + gọi `_tryShowPending`; resume + UserBloc listener đều gọi lại. |
| `_tryShowPending` | ✅ Chặn khi `authStatus` initial/loading; dedup soft qua `_handledVersionCode` (force luôn hiện); show qua `addPostFrameCallback`; guard `!mounted`/`_dialogShowing`/`_pendingUpdate`. |
| `_showUpdateDialog` | ✅ Trả `Future<bool?>` = `showDialog<bool>`, `barrierDismissible:false`, host null → null. |
| "Để sau" | ✅ `pop(true)` cả 2 layout (cột + hàng). "Cập nhật ngay" giữ nguyên. |
| Phân biệt teardown vs user | ✅ result==true → set `_handledVersionCode` + clear pending; null (bị gỡ/force teardown) → giữ pending → hiện lại lần settle kế. |
| Trace login | ✅ pre-login show trên login → redirect gỡ (result null, giữ pending) → UserBloc success → `_tryShowPending` post-frame → **show lại trên home & ở lại**. Không double-show (post-frame sau đã thấy `_dialogShowing==true`). |
| Verify | ✅ `flutter analyze lib/feature/app_update/app_update_guard.dart` → **No issues found (1.6s)**. |

**VERDICT: APPROVED (code).** Còn **1 cổng bắt buộc**: smoke thiết bị — đăng nhập với 1 bản published > versionCode máy → dialog phải **ở lại** trên dashboard (không tắt vội). Chưa chạy được ở audit (cần device + published version).

---

## 11. Thứ tự với FEATURE `20260703-in-app-apk-update` (chạm cùng file)
- **Làm BUG này TRƯỚC** (lỗi hiển thị nặng hơn), rồi mới tới in-app-apk-update.
- Khi làm in-app-apk-update: `_UpdateDialogContent` sẽ chuyển Stateful — **giữ hợp đồng `pop(true)`** ở nút "Để sau", và khi nút "Cập nhật ngay" hoàn tất/huỷ cũng nên `pop(true)` để clear pending (cập nhật lại mục 4.4 của work-order kia cho khớp). Nếu Cursor thấy mâu thuẫn → DỪNG & hỏi Opus.
