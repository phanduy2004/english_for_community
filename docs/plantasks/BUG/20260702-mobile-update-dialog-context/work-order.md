# Work-Order — BUG (MICRO): Dialog auto-update không hiện dù server trả `soft_update`

- **Task ID:** 20260702-mobile-update-dialog-context
- **Loại:** BUG · **Platform:** student mobile (Flutter) · **Cỡ:** MICRO (1 file, ~10 LOC)
- **Mục tiêu:** Khi `version-check` trả `soft_update`/`force_update`, app phải hiện dialog "Cập nhật ngay" (hiện tại **không hiện gì**).
- **Người phân tích:** Opus (brain). **Implementer:** Cursor. **Status:** ROOT CAUSE XÁC ĐỊNH — chờ implement.
- **Liên quan:** nối tiếp `docs/plantasks/BUG/20260622-mobile-auto-update/` (RC1–RC4 ở đó đã fix; đây là nguyên nhân **còn lại** & thật sự gây "không hiện dialog").

---

## 1. Vấn đề + nguyên nhân gốc (có dẫn chứng code)

**Triệu chứng (đã kiểm chứng bằng thiết bị thật):**
- Máy đang cài **build 30** (đóng gói 28/06, ĐÃ có tính năng auto-update + đủ các fix).
- Server prod trả đúng cho versionCode=30:
  `{"status":"soft_update","latestVersionCode":32,"downloadUrl":"...build32...apk","publishedAt":"2026-07-02T13:55:51Z"}`.
- Mở **trình duyệt ngay trên chiếc máy đó** → dán URL version-check → **lấy được JSON `soft_update`** ⇒ mạng/DNS/TLS/server OK tuyệt đối.
- Nhưng mở app → **không có dialog nào**.

**Root cause — `showDialog` dùng SAI context (nằm trên Navigator):**

Cây widget (`lib/main.dart:75-112`):
```
MultiBlocProvider(UserBloc, AppUpdateBloc)
 └─ MaterialApp.router
     builder: (context, child) => AppUpdateGuard( … child … )   // guard Ở TRÊN
                                              child = Navigator của go_router  // Ở DƯỚI
```
`builder` của `MaterialApp.router` bọc **phía trên** Navigator (Navigator do go_router tạo, key = `rootNavigatorKey`, xem `lib/core/router/app_router.dart:137`).

`AppUpdateGuard` bật dialog bằng **context thô** của builder — `lib/feature/app_update/app_update_guard.dart:94-106`:
```dart
Future<void> _showUpdateDialog(BuildContext context, AppUpdateInfoEntity info) async {
  await showDialog<void>(
    context: context,          // ← context này Ở TRÊN Navigator
    ...
    useRootNavigator: true,
    builder: (dialogContext) => _UpdateDialogContent(info: info),
  );
}
```
`showDialog` → `Navigator.of(context, rootNavigator: true)` đi **lên** không gặp Navigator (Navigator nằm **dưới**) → ném `FlutterError: No Navigator` **bên trong callback async của `BlocListener`** (`app_update_guard.dart:73-88`) → lỗi bị nuốt → **dialog không bao giờ hiện**.

**Vì sao lọt tới giờ:** đây là **lần đầu** có bản `published` (build 32, publish 20:55 ngày 02/07) **cao hơn** một bản-đã-có-checker đang cài (build 30). Trước đó `hasUpdate` chưa từng = true trên thiết bị nên nhánh `showDialog` **chưa từng chạy thật** → bug ẩn.

**Bằng chứng convention (guard là ngoại lệ duy nhất):** mọi nơi bật dialog/overlay từ context toàn cục đều dùng `rootNavigatorKey.currentContext`, gồm 2 sibling ngay cạnh guard và các chỗ khác:
- `lib/core/socket/socket_lifecycle_manager.dart:37`
- `lib/core/notification/app_notification_listener.dart` (nhiều dòng), `lib/core/notification/local_notification_service.dart:113`
- `lib/feature/home/notification_dialog.dart:26` → `context: rootNavigatorKey.currentContext ?? context`
- `lib/core/ui/widget/app_corner_toast.dart:29`, các dialog chat…

Chỉ `AppUpdateGuard._showUpdateDialog` dùng `context` builder ⇒ đó là bug.

---

## 2. Audit downstream

| Điểm | File:line | Ảnh hưởng của fix |
|---|---|---|
| Trigger check (initState/resume/auth) | `app_update_guard.dart:32-72` | KHÔNG đổi — `context.read<AppUpdateBloc>()` vẫn hợp lệ (provider ở trên guard). Check vẫn chạy đúng. |
| BlocListener bật dialog | `app_update_guard.dart:73-88` | Chỉ đổi tham số truyền vào `_showUpdateDialog`. |
| Nội dung dialog | `_UpdateDialogContent` (`app_update_guard.dart:110-310`) | KHÔNG đổi — `AppLocalizations/Theme/MediaQuery.of` vẫn resolve vì dialog nay nằm **dưới** Navigator/MaterialApp. |
| `rootNavigatorKey` | `lib/core/utils/global_keys.dart:4` | Dùng lại, không sửa. |

Không chạm backend / socket / perf. Không thêm string l10n mới.

---

## 3. Scope IN / OUT

**IN (được sửa):** duy nhất `english_for_community/lib/feature/app_update/app_update_guard.dart`.

**OUT (chạm là DỪNG & hỏi):**
- ❌ Sửa `main.dart` / vị trí guard trong cây widget (cách khác nhưng rủi ro hơn — không làm trong task này).
- ❌ Sửa bloc/datasource/entity/repository app_update, đổi luồng check.
- ❌ Đổi `app_router.dart`, `global_keys.dart`.
- ❌ Đổi text/l10n, layout dialog, backend, CI workflow.

---

## 4. Diff cụ thể (Cursor tự viết code theo ý định dưới)

File: `lib/feature/app_update/app_update_guard.dart`

**(a) Thêm import** (khối import đầu file):
```dart
import 'package:english_for_community/core/utils/global_keys.dart';
```

**(b) Chỗ gọi trong BlocListener** (~dòng 85): bỏ truyền `context`:
```diff
-            await _showUpdateDialog(context, info);
+            await _showUpdateDialog(info);
```

**(c) Hàm `_showUpdateDialog`** (dòng 94-106): bật dialog qua `rootNavigatorKey.currentContext` (context NẰM DƯỚI Navigator):
```diff
-  Future<void> _showUpdateDialog(
-    BuildContext context,
-    AppUpdateInfoEntity info,
-  ) async {
-    await showDialog<void>(
-      context: context,
-      barrierDismissible: info.status != AppUpdateStatus.forceUpdate,
-      useRootNavigator: true,
-      builder: (dialogContext) {
-        return _UpdateDialogContent(info: info);
-      },
-    );
-  }
+  Future<void> _showUpdateDialog(AppUpdateInfoEntity info) async {
+    // Guard nằm TRONG builder của MaterialApp.router → context builder ở TRÊN
+    // Navigator của go_router. Phải bật dialog qua rootNavigatorKey.currentContext
+    // (nằm DƯỚI Navigator) như mọi chỗ toàn cục khác, nếu không showDialog ném
+    // "No Navigator" và bị nuốt trong callback async → không hiện gì.
+    final host = rootNavigatorKey.currentContext;
+    if (host == null) return;
+    await showDialog<void>(
+      context: host,
+      barrierDismissible: info.status != AppUpdateStatus.forceUpdate,
+      useRootNavigator: true,
+      builder: (dialogContext) {
+        return _UpdateDialogContent(info: info);
+      },
+    );
+  }
```

**RÀNG BUỘC:**
- Giữ nguyên logic `_dialogShowing` / `_lastShownVersionCode` (khi `host == null` return sớm thì `_dialogShowing` vẫn được reset `false` ở dòng sau `await` trong listener → lần trigger sau retry, KHÔNG kẹt cờ).
- Giữ `barrierDismissible` phụ thuộc soft/force; giữ `PopScope canPop:!mustUpdate` trong `_UpdateDialogContent` (force = không tắt được).
- KHÔNG đổi gì trong `_UpdateDialogContent`.

**TIÊU CHÍ NGHIỆM THU:** khi server trả `soft_update`/`force_update`, dialog hiện; bấm "Cập nhật ngay" mở `downloadUrl`; force thì không tắt được, soft thì có nút "Để sau".

---

## 5. Lệnh verify

```bash
cd english_for_community
flutter analyze lib/feature/app_update/app_update_guard.dart   # 0 lỗi
flutter test                                                   # không vỡ test hiện có
```

**Smoke trên thiết bị (bắt buộc — đây là bug runtime):**
```bash
# Debug trỏ prod: app báo versionCode=1 < 32 → server trả soft_update
flutter run --dart-define-from-file=config/prod.json
```
- TRƯỚC fix: mở app → không dialog; log có `No Navigator`/exception đúng lúc lẽ ra hiện dialog.
- SAU fix: mở app → **hiện dialog "Cập nhật ngay"** ngay lần đầu; bấm nút mở được link tải APK build 32.

---

## 6. Hồi quy tối thiểu

1. Mở app khi có bản mới published → hiện dialog (soft: tắt được bằng "Để sau"; force: không tắt được).
2. Background → foreground (resume) → check lại, dialog xuất hiện đúng (không double khi đang mở: `_dialogShowing`).
3. Bản đã mới nhất (versionCode == latest) → `up_to_date` → không hiện gì (không regress).
4. Web (`kIsWeb`) → vẫn skip, không crash (`app_update_bloc.dart:27`).

---

## 7. HANDOFF PROMPT cho Cursor (copy nguyên khối)

```text
Bạn là implementer. CHỈ sửa đúng 1 file; file ngoài danh sách → DỪNG & hỏi.
Repo: english_for_community (Flutter).

FILE ĐƯỢC SỬA:
  lib/feature/app_update/app_update_guard.dart

THEO ĐÚNG diff mục 4 của work-order:
  (a) import core/utils/global_keys.dart
  (b) đổi lời gọi: _showUpdateDialog(info)  (bỏ truyền context)
  (c) _showUpdateDialog bật dialog qua rootNavigatorKey.currentContext (guard null → return)

TUYỆT ĐỐI KHÔNG:
  - Đổi main.dart / vị trí guard, app_router.dart, global_keys.dart.
  - Đổi bloc/datasource/entity/repository app_update, luồng check.
  - Đổi text/l10n, layout _UpdateDialogContent, backend, CI.

VERIFY:
  flutter analyze lib/feature/app_update/app_update_guard.dart   → 0 lỗi
  flutter run --dart-define-from-file=config/prod.json           → mở app phải HIỆN dialog "Cập nhật ngay"

Xong → dán kết quả analyze + ảnh/log dialog hiện vào phần tracker, báo Opus audit.
```

---

## 8. Checklist OPUS AUDIT (chạy khi implementer báo xong)

- [ ] Chỉ sửa `app_update_guard.dart`; không chạm file OUT.
- [ ] `_showUpdateDialog` dùng `rootNavigatorKey.currentContext`, có guard null; bỏ tham số `context` thừa; call site cập nhật.
- [ ] Không đổi `_UpdateDialogContent`, không đổi logic `_dialogShowing`/`_lastShownVersionCode`.
- [ ] `flutter analyze` file: 0 lỗi; `flutter test` pass.
- [ ] Smoke thiết bị: SAU fix dialog hiện; nút mở được downloadUrl; force không tắt được.
- [ ] Không regress `up_to_date` (không hiện dialog khi đã mới nhất).

---

## 9. Kết quả OPUS AUDIT (Phase 4) — 2026-07-03

**Diff thật đã đọc** (`git diff app_update_guard.dart`): đúng 3 thay đổi theo mục 4, không hơn.

| Mục | Kết quả |
|---|---|
| Scope | ✅ Chỉ `app_update_guard.dart`. Kiểm `git status` các file OUT (`main.dart`, `app_router.dart`, `global_keys.dart`, `bloc/*`, datasource, entity) → **không đụng**. |
| Đúng fix | ✅ `_showUpdateDialog(info)` bật dialog qua `rootNavigatorKey.currentContext` + guard `host == null`. Bỏ tham số `context` thừa; call site (`:85`) đã cập nhật; không sót tham chiếu `context` cũ. |
| Đúng cơ chế | ✅ `rootNavigatorKey` là root navigator của go_router (`app_router.dart:137`). `Navigator.of(host, rootNavigator:true)` → `host` chính là context của Navigator (currentContext của GlobalKey<NavigatorState>) → resolve đúng root navigator (giống pattern đã chạy ổn ở `notification_dialog.dart:26` v.v.). |
| Không regress | ✅ `_UpdateDialogContent`, logic `_dialogShowing`/`_lastShownVersionCode`, nhánh `up_to_date` (listener return sớm) đều nguyên vẹn. `host==null` return sớm → `_dialogShowing` vẫn được reset ở listener → không kẹt cờ. |
| Verify | ✅ `flutter analyze lib/feature/app_update/app_update_guard.dart` → **No issues found (2.9s)**. `flutter test` chưa chạy trong audit (đổi UI-only, rủi ro vỡ test ~0). |

**VERDICT: APPROVED (code).** Còn **1 cổng bắt buộc** trước khi đóng task (bug runtime): **smoke trên thiết bị** — build/run có fix, xác nhận dialog "Cập nhật ngay" hiện. Chưa build lại thì APK build 30 đang cài **vẫn dính bug** (fix không hot-update được).
