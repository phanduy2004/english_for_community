# Work-Order — BUG: Web app đăng nhập lại mỗi lần mở (token không persist)

- **Task ID:** 20260706-web-token-persistence
- **Loại:** BUG · **Platform:** student/teacher/admin (Flutter **web**) · **Cỡ:** MICRO (1 file, ~30 LOC; pubspec đã có dep)
- **Mục tiêu:** Trên web, sau khi đăng nhập rồi **reload/mở lại tab** thì vẫn giữ phiên (không quay về Login). Mobile giữ nguyên hành vi.
- **Người phân tích:** Opus (brain). **Implementer:** Cursor. **Status:** ROOT CAUSE (nhánh a) — cần diagnostic xác nhận rồi implement.
- **Bối cảnh:** User truy cập qua **HTTPS** (đã loại nguyên nhân http/secure-context). Web-specific, xảy ra **mỗi lần**.

---

## 1. Vấn đề + nguyên nhân gốc (dẫn chứng code)

**Triệu chứng:** Mở web app lần nào cũng phải đăng nhập lại. Mobile bình thường.

**Luồng khởi động (đã trace):**
- `main.dart:71` → `getIt<UserBloc>()..add(CheckAuthStatusEvent())`.
- `user_bloc.dart:329-346` `onCheckAuthStatusEvent`: `final refreshToken = await TokenStorage.readRefreshToken();` → **null → `emit(unauthenticated)` → return** (không gọi `getProfile`).
- `app_router.dart:170-172`: `unauthenticated` → mọi route non-public → `LoginPage`.

**Root cause (nhánh a — persistence web):** `TokenStorage` (`token_storage.dart:6`) dùng `FlutterSecureStorage()`. Web backend = `flutter_secure_storage_web 1.2.1` (lock `:662-669`) lưu `localStorage` + mã hoá Web-Crypto. Trên web nó **không persist bền qua reload/tab mới** (kể cả HTTPS — lỗi flaky đã biết của secure_storage web; web vốn chỉ là localStorage + key nằm cạnh, không phải secure thật). ⇒ `readRefreshToken()` trả **null** mỗi lần mở → app coi như chưa đăng nhập. Mobile dùng Keystore/Keychain native nên không dính.

Login CÓ lưu đúng cả 2 token (`auth_remote_datasource.dart:43-44` `saveAccessToken`+`saveRefreshToken`) — nên KHÔNG phải lỗi login/API; thuần lỗi **persistence tầng web**.

> **Nhánh b (ít khả năng, phải loại bằng diagnostic §7):** token CÓ persist nhưng `getProfile()` startup fail (→ unauthenticated). Nếu vậy fix này không đúng — xem §7 để phân biệt trước khi code.

---

## 2. Audit downstream (consumer của `TokenStorage`)

API `TokenStorage` là **static, signature giữ nguyên** → sửa nội bộ, **không đụng consumer**:

| Consumer | file:line | Dùng |
|---|---|---|
| JWT inject | `app_jwt_interceptor.dart:29` | `readAccessToken()` |
| Refresh flow | `app_jwt_interceptor.dart:42,79,88,116` · `auth_remote_datasource.dart:108` | `read/save/clear` |
| Login lưu token | `auth_remote_datasource.dart:22-23,43-44` | `saveAccess/RefreshToken` |
| Startup gate | `user_bloc.dart:332` | `readRefreshToken()` |
| Logout/ban | `user_bloc.dart:311,322,353` · `auth_remote_datasource.dart:56` | `clearAllTokens()` |
| Socket/exam token | `socket_service.dart`, `exam_live_session_guard.dart:59`, `teacher_exam_session_console_bloc.dart:140` | `readAccessToken()` |

**Không regression:** tất cả gọi qua static method giữ nguyên tên/kiểu trả về → chỉ đổi backend lưu trữ bên trong. Mobile vẫn `FlutterSecureStorage`.

---

## 3. Hướng fix (thiết kế)

Làm `TokenStorage` **platform-aware**: `kIsWeb` → `SharedPreferences` (đã có `shared_preferences 2.5.3`, lock `:1376`; web = localStorage thẳng, persist same-origin mọi context kể cả HTTPS); else → `FlutterSecureStorage` (giữ nguyên mobile). Public API **không đổi**.

- **Không migrate** token cũ: token secure_storage cũ trên web vốn không đọc được (chính là bug) → login mới ghi vào SharedPreferences là đủ.
- **Bảo mật:** trên web, secure_storage cũng chỉ là localStorage (không secure thật) → chuyển SharedPreferences **không giảm** bảo mật thực. Access token ngắn hạn + refresh rotate ở backend. (Giải pháp httpOnly cookie = đổi backend, OUT scope — xem §10.)
- **Không đổi:** interceptor, datasource, user_bloc, router, DI.

---

## 4. Scope IN / OUT

**IN:** `english_for_community/lib/core/api/token_storage.dart` — chuyển sang platform-aware (như §5).

**OUT (chạm là DỪNG & hỏi):**
- ❌ `app_jwt_interceptor.dart`, `auth_remote_datasource.dart`, `user_bloc.dart`, `app_router.dart` — API static giữ nguyên, không cần đụng.
- ❌ pubspec (đã có `shared_preferences`, `flutter_secure_storage`) — KHÔNG thêm/xoá dep.
- ❌ Đổi tên key `auth_token`/`refresh_token`. ❌ Migrate token cũ. ❌ Backend/cookie.

---

## 5. CONTEXT BUNDLE ⭐ (Codex đọc là đủ — KHÔNG grep lại)

### Site 1 — `english_for_community/lib/core/api/token_storage.dart` (thay TOÀN BỘ nội dung file — file ngắn 38 dòng)
- **Locator (anchor):** `static const _storage = FlutterSecureStorage();` (dòng khai báo backend, `:6`).
- **BEFORE (verbatim, file hiện tại):**
  ```dart
  import 'package:flutter_secure_storage/flutter_secure_storage.dart';

  class TokenStorage {
    static const _accessTokenKey = 'auth_token';
    static const _refreshTokenKey = 'refresh_token';
    static const _storage = FlutterSecureStorage();

    // --- Access Token ---
    static Future<void> saveAccessToken(String token) =>
        _storage.write(key: _accessTokenKey, value: token);

    static Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

    // --- Refresh Token ---
    static Future<void> saveRefreshToken(String token) =>
        _storage.write(key: _refreshTokenKey, value: token);

    static Future<String?> readRefreshToken() =>
        _storage.read(key: _refreshTokenKey);

    // --- Clear All ---
    static Future<void> clearAllTokens() async {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
    }

    /// Backend rotates refresh token on every `/auth/refresh` — must persist both.
    static Future<String?> saveTokensFromAuthResponse(Map<String, dynamic> data) async {
      final access = data['accessToken'] as String?;
      final refresh = data['refreshToken'] as String?;
      if (access == null || access.isEmpty) return null;
      await saveAccessToken(access);
      if (refresh != null && refresh.isNotEmpty) {
        await saveRefreshToken(refresh);
      }
      return access;
    }
  }
  ```
- **AFTER (thay cả file):**
  ```dart
  import 'package:flutter/foundation.dart' show kIsWeb;
  import 'package:flutter_secure_storage/flutter_secure_storage.dart';
  import 'package:shared_preferences/shared_preferences.dart';

  /// Web: flutter_secure_storage không persist bền qua reload (localStorage + Web-Crypto flaky,
  /// kể cả HTTPS) → dùng SharedPreferences (localStorage thẳng, persist same-origin).
  /// Mobile/desktop: FlutterSecureStorage (Keystore/Keychain native).
  class TokenStorage {
    static const _accessTokenKey = 'auth_token';
    static const _refreshTokenKey = 'refresh_token';
    static const _secure = FlutterSecureStorage();

    static Future<void> _write(String key, String value) async {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, value);
      } else {
        await _secure.write(key: key, value: value);
      }
    }

    static Future<String?> _read(String key) async {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(key);
      }
      return _secure.read(key: key);
    }

    static Future<void> _delete(String key) async {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(key);
      } else {
        await _secure.delete(key: key);
      }
    }

    // --- Access Token ---
    static Future<void> saveAccessToken(String token) => _write(_accessTokenKey, token);
    static Future<String?> readAccessToken() => _read(_accessTokenKey);

    // --- Refresh Token ---
    static Future<void> saveRefreshToken(String token) => _write(_refreshTokenKey, token);
    static Future<String?> readRefreshToken() => _read(_refreshTokenKey);

    // --- Clear All ---
    static Future<void> clearAllTokens() async {
      await _delete(_accessTokenKey);
      await _delete(_refreshTokenKey);
    }

    /// Backend rotates refresh token on every `/auth/refresh` — must persist both.
    static Future<String?> saveTokensFromAuthResponse(Map<String, dynamic> data) async {
      final access = data['accessToken'] as String?;
      final refresh = data['refreshToken'] as String?;
      if (access == null || access.isEmpty) return null;
      await saveAccessToken(access);
      if (refresh != null && refresh.isNotEmpty) {
        await saveRefreshToken(refresh);
      }
      return access;
    }
  }
  ```
- **GOTCHA:** Giữ NGUYÊN tên method + kiểu trả (`Future<void>`/`Future<String?>`) — mọi call-site phụ thuộc. `saveTokensFromAuthResponse` không đổi (đã gọi qua `saveAccessToken/saveRefreshToken`). Không đổi 2 key string. `SharedPreferences.getInstance()` cần `WidgetsFlutterBinding` (đã có ở `main.dart` trước `runApp`; các call token đều sau startup → an toàn).

### SYMBOL TABLE (verbatim — Codex khỏi tra)
| Symbol | Verbatim | Nguồn | Trạng thái |
|---|---|---|---|
| `kIsWeb` | `bool` | `package:flutter/foundation.dart` | [CÓ] |
| `SharedPreferences` | `.getInstance()` → `Future<SharedPreferences>`; `.setString(k,v)`; `.getString(k)→String?`; `.remove(k)` | `package:shared_preferences/shared_preferences.dart` (dep `2.5.3`) | [CÓ] — không thêm pubspec |
| `FlutterSecureStorage` | `.write({key,value})`/`.read({key})→String?`/`.delete({key})` | `flutter_secure_storage 9.2.4` | [CÓ] |
| key `auth_token` / `refresh_token` | string keys | `token_storage.dart:4-5` | [CÓ] — giữ nguyên |

**CLONE-THIS:** N/A. **Symbol [THÊM]:** không có.

---

## 6. GATE liên quan
- **Perf:** N/A (I/O token nhẹ, không đổi tần suất). `SharedPreferences.getInstance()` cache instance sau lần đầu.
- **UI/UX:** N/A (không chạm layout).
- **Backend:** N/A (không đổi API/refresh).
- **L10n:** N/A.
- **Bảo mật:** đã cân nhắc (§3) — web không giảm bảo mật thực; note follow-up httpOnly ở §10.

---

## 7. Verify + Diagnostic (BẮT BUỘC làm §7.0 TRƯỚC khi code)

### 7.0 Diagnostic — xác nhận đúng nhánh (a) chứ không phải (b)
Chạy web hiện tại (`flutter run -d chrome`), đăng nhập, **reload**. Mở DevTools → **Application → Local Storage → origin**:
- Nếu **không thấy** giá trị token nào sống sót qua reload (secure_storage keys biến mất/không đọc được) → **nhánh (a) — đúng bug này, tiếp tục fix.**
- Nếu token secure_storage VẪN còn sau reload nhưng vẫn về Login → **nhánh (b)** (getProfile/refresh fail) → **DỪNG, báo Opus** kèm Network tab của `auth/refresh` + `getProfile` (status code). Fix này không áp dụng.

### 7.1 Build/analyze
```bash
cd english_for_community
dart analyze lib/core/api/token_storage.dart      # 0 lỗi mới
```

### 7.2 Smoke WEB (ca nghiệm thu chính) — `flutter run -d chrome` (HTTPS/localhost)
1. ⭐ Đăng nhập → **F5 reload** → **vẫn ở trong app, KHÔNG về Login**. Mở DevTools → Application → Local Storage: thấy key `flutter.auth_token` + `flutter.refresh_token` (SharedPreferences web prefix `flutter.`), **sống qua reload**.
2. ⭐ Đóng tab → mở lại URL → vẫn đăng nhập.
3. Logout → token bị xoá (Local Storage sạch 2 key) → về Login đúng.
4. Access token hết hạn (đợi hoặc test) → interceptor refresh chạy → không văng Login.

### 7.3 Smoke MOBILE (no regression)
5. `flutter run` trên Android/emulator → login → kill app → mở lại → vẫn đăng nhập (secure_storage native vẫn hoạt động).

> Nếu §7.0 ra nhánh (b) → DỪNG & báo Opus, đừng áp fix.

---

## 8. HANDOFF PROMPT cho Cursor
```text
Bạn là implementer. CHỈ sửa 1 file; ngoài phạm vi → DỪNG & hỏi.
Repo: english_for_community (Flutter).

BƯỚC 0 — ĐỌC WORK-ORDER TRƯỚC (bắt buộc):
  Mở & đọc HẾT: docs/plantasks/BUG/20260706-web-token-persistence/work-order.md
  Nắm: §1 root cause, §2 downstream (API static giữ nguyên), §5 CONTEXT BUNDLE (code + symbol), §7 diagnostic+smoke.
  Code lấy NGUYÊN từ §5. Doc mâu thuẫn prompt → DỪNG & hỏi (doc thắng).

BƯỚC 1 — DIAGNOSTIC §7.0 (bắt buộc trước khi code):
  Chạy web, login, reload, xem DevTools Local Storage. Xác nhận nhánh (a) token KHÔNG persist.
  Nếu là nhánh (b) (token còn nhưng vẫn về Login) → DỪNG, báo Opus kèm Network status của auth/refresh + getProfile.

BƯỚC 2 — LÀM:
  FILE (duy nhất): lib/core/api/token_storage.dart — thay theo §5 AFTER (platform-aware: kIsWeb→SharedPreferences, else→FlutterSecureStorage).
  GIỮ NGUYÊN: tên/kiểu mọi static method; 2 key 'auth_token'/'refresh_token'; saveTokensFromAuthResponse.

TUYỆT ĐỐI KHÔNG: đụng interceptor/datasource/user_bloc/router/DI; thêm-xoá pubspec dep; đổi key; migrate token cũ; đụng backend.

VERIFY (§7): dart analyze token_storage.dart (0 lỗi) + smoke WEB (1)-(4) [login→reload→còn phiên; Local Storage có flutter.auth_token/refresh_token sống qua reload; logout xoá; refresh chạy] + smoke MOBILE (5) no-regression.
Xong → dán kết quả diagnostic + verify/smoke → báo Opus audit. KHÔNG commit/push.
```

## 9. Checklist OPUS AUDIT (Phase 4)
- [ ] `git status`: chỉ `token_storage.dart` đổi; file OUT + pubspec không đụng.
- [ ] Diagnostic §7.0 xác nhận nhánh (a) (không phải b).
- [ ] Platform-aware đúng: `kIsWeb`→SharedPreferences, else→FlutterSecureStorage; API static giữ nguyên tên/kiểu; 2 key giữ nguyên.
- [ ] `dart analyze` 0 lỗi mới.
- [ ] Smoke WEB (1)-(2): login→reload/mở-lại-tab còn phiên; key `flutter.*` sống qua reload. (3) logout xoá. (4) refresh chạy.
- [ ] Smoke MOBILE (5): no regression (secure_storage native).

---

## 10. Follow-up (OUT scope — task riêng khi cần)
1. **Bảo mật web token:** cân nhắc chuyển sang **httpOnly + Secure cookie** cho refresh token (backend set cookie, client không cầm) — chống XSS đọc localStorage. Đổi cả backend `auth/*` + interceptor → task full-stack.
2. **Đồng nhất storage:** nếu muốn, gộp về 1 abstraction `SessionStore` inject qua DI (test được) thay static — refactor T1.
