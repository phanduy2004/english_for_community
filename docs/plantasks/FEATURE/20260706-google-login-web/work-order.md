# Work-Order — FEATURE: Google Sign-In cho Web (song song Android)

- **Task ID:** `20260706-google-login-web`
- **Loại:** FEATURE · **Platform:** student mobile + web (Flutter, cùng codebase) · **Cỡ:** MICRO (1 file, ~25 LOC)
- **Mục tiêu:** Bấm "Continue with Google" trên bản **web** (flutter run -d chrome) mở được popup Google → đăng nhập thành công vào app, y như Android hiện tại. Backend KHÔNG đổi.
- **Người phân tích:** Opus (brain). **Implementer:** Cursor/Codex. **Status:** ROOT CAUSE XÁC ĐỊNH — chờ implement.
- **Liên quan:** luồng auth `auth/google` (đã chạy trên Android).

---

## 1. Vấn đề + nguyên nhân gốc (dẫn chứng code)

**Triệu chứng:** Google login chỉ hoạt động trên Android. Trên web, nút "Continue with Google" không đăng nhập được.

**Root cause:** Handler dùng `google_sign_in` classic API cho mọi platform:
- `lib/feature/auth/bloc/user_bloc.dart:41-42` — `GoogleSignIn().signIn()`.
- Trên **web**, `google_sign_in ^6.3.0` (`google_sign_in_web`) KHÔNG lấy `idToken` qua `signIn()` như mobile — nó cần Google Identity Services + một **browser OAuth clientId** (meta tag `google-signin-client_id` hoặc `GoogleSignIn(clientId:)`). Cả hai đều KHÔNG có:
  - `web/index.html` không có meta GSI/clientId (scout §3: chỉ có `flutter_bootstrap.js`).
  - `GoogleSignIn()` được tạo không truyền `clientId`/`serverClientId` (`user_bloc.dart:41`).
  - `firebase_options.dart` web block không mang OAuth client_id.
  → Nên nhánh mobile chạy thẳng trên web sẽ fail.

**Chốt quan trọng — vì sao KHÔNG cần đụng backend:** backend chỉ verify **Firebase ID token**, không phải Google idToken:
- `english_for_community_backend/src/services/authService.js:371` — `admin.auth().verifyIdToken(idToken)` (firebase-admin), không có `google-auth-library`, không check `GOOGLE_CLIENT_ID`/`audience`.
- Frontend hiện cũng gửi **Firebase** ID token: `user_bloc.dart:59-62` `signInWithCredential(...)` → `userCredential.user?.getIdToken()`.
→ Trên web chỉ cần lấy **Firebase ID token bằng đường khác** rồi gửi cùng endpoint `auth/google`. `FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider())` cho ra đúng token đó, Firebase tự lo OAuth (không cần google_sign_in/clientId).

**Sẵn sàng sẵn (đã verify — giảm rủi ro):**
- `firebase_auth: ^5.3.1` + `firebase_core: ^3.6.0` → `signInWithPopup` có sẵn; firebase JS SDK auto-inject → **KHÔNG cần sửa `web/index.html`**.
- Web app đã đăng ký Firebase: `firebase_options.dart:49-57` (web block, `authDomain: english4community-4c654.firebaseapp.com`).
- `main.dart:40` `Firebase.initializeApp(...currentPlatform)` (trả `web` khi `kIsWeb`) + `main.dart:38` `configureWebUrlStrategy()`.

---

## 2. Audit downstream + Không regression (gộp — MICRO)

- Handler `_onLoginWithGoogleEvent` là **consumer duy nhất** của luồng google trong bloc. Nút gọi nó: `login_page.dart:416` `add(LoginWithGoogleEvent())`. Repo/datasource chỉ pass-through `idToken` (`auth_repository_impl.dart:37-39`, `auth_remote_datasource.dart:10-13`) → không đổi.
- **Mobile giữ NGUYÊN:** nhánh `else` là code cũ nguyên văn (chỉ được bọc trong `if (!kIsWeb)`). Nhánh `catch (e)` báo lỗi cũ giữ **byte-for-byte**; chỉ THÊM 1 short-circuit "huỷ popup" ở đầu catch (các mã lỗi này chỉ phát sinh trên web) → mobile không đổi hành vi.
- `signOut` (`user_bloc.dart:336-337`) gọi `GoogleSignIn().signOut()` — trên web là no-op vô hại, để nguyên (OUT scope).

---

## 3. Hướng fix (thiết kế) + quyết định

**Chọn:** branch theo `kIsWeb` trong `_onLoginWithGoogleEvent`.
- **Web:** `FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider())` → `getIdToken()`.
- **Mobile:** giữ nguyên `google_sign_in` → `signInWithCredential` → `getIdToken()`.
- Phần sau (`if (idToken == null)` → `authRepository.loginWithGoogle` → `fold`) DÙNG CHUNG, không đổi.

**Vì sao không chọn alt:** dùng `google_sign_in_web` (GSI) trên web đòi tạo **OAuth Web Client ID** trong Google Cloud, thêm authorized JS origins + meta tag trong `index.html` → nhiều config + dễ sai; và vẫn phải quy về Firebase token cho backend. `signInWithPopup` tận dụng OAuth client Firebase tự tạo sẵn (qua `authDomain`) → 0 thêm config, 0 đổi `index.html`, 0 đổi backend.

**Bẫy/cảnh báo:**
- **Authorized domains (config, KHÔNG phải code):** Firebase Console → Authentication → Settings → *Authorized domains* phải chứa domain phục vụ web. `localhost` + `english4community-4c654.firebaseapp.com` + `*.web.app` được authorize mặc định → `flutter run -d chrome` (localhost) chạy ngay. Khi deploy domain riêng (Render/Vercel/custom) phải **add domain đó** nếu không popup báo `auth/unauthorized-domain`.
- **Google provider** phải đang bật ở Firebase Auth → Sign-in method (đã bật vì Android đang chạy).
- **Popup blocker:** giữ `signInWithPopup` là `await` ĐẦU TIÊN trong handler (đừng chèn await nào trước nó) để trình duyệt còn tính là "user gesture".

---

## 4. Scope IN / OUT

**IN (chính xác file được sửa):**
- `english_for_community/lib/feature/auth/bloc/user_bloc.dart` — thêm import `kIsWeb`; branch web/mobile trong `_onLoginWithGoogleEvent`; short-circuit huỷ popup.

**OUT (chạm là DỪNG & hỏi):**
- ❌ `english_for_community_backend/**` — backend đã verify Firebase ID token, không đụng.
- ❌ `web/index.html`, `firebase_options.dart`, `main.dart` — cấu hình web đã đủ.
- ❌ `login_page.dart`, repository/datasource — pass-through, không đổi.
- ❌ Nhánh `else` (mobile) logic — copy nguyên văn, không "cải tiến".

---

## 5. CONTEXT BUNDLE ⭐ (đọc phần này là ĐỦ để code)

### Site 1 — `lib/feature/auth/bloc/user_bloc.dart` · phần import
- **Locator (anchor):** search chuỗi unique `import 'package:google_sign_in/google_sign_in.dart';` _(≈:7)._
- **BEFORE (verbatim):**
  ```dart
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:google_sign_in/google_sign_in.dart';
  import '../../../core/api/token_storage.dart';
  ```
- **AFTER / THAO TÁC:** thêm 1 dòng import `kIsWeb` ngay dưới dòng `google_sign_in`:
  ```dart
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:google_sign_in/google_sign_in.dart';
  import 'package:flutter/foundation.dart' show kIsWeb;
  import '../../../core/api/token_storage.dart';
  ```
- **GOTCHA:** file này KHÔNG import `flutter/material` hay `foundation` nên `kIsWeb` chưa có — bắt buộc thêm import này, nếu không analyze báo undefined `kIsWeb`.

### Site 2 — `lib/feature/auth/bloc/user_bloc.dart` · `_onLoginWithGoogleEvent` (bước lấy idToken)
- **Locator (anchor):** search chuỗi unique `// 1. Trigger Google Sign In Flow` _(≈:40)._
- **BEFORE (verbatim):**
  ```dart
      try {
        // 1. Trigger Google Sign In Flow
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          // User hủy login
          emit(state.copyWith(isFormLoading: false));
          return;
        }

        // 2. Lấy Auth Credential
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // 3. Sign in Firebase để lấy ID Token chuẩn
        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        final String? idToken = await userCredential.user?.getIdToken();

        if (idToken == null) {
          throw Exception("Không lấy được ID Token từ Google");
        }
  ```
- **AFTER / THAO TÁC:** thay nguyên khối trên bằng branch web/mobile; phần từ `if (idToken == null)` trở đi giữ nguyên:
  ```dart
      try {
        // 1. Lấy Firebase ID Token — web dùng popup, mobile dùng google_sign_in native
        final String? idToken;

        if (kIsWeb) {
          // WEB: Firebase Auth popup lo trọn OAuth (không cần google_sign_in / clientId)
          final UserCredential userCredential = await FirebaseAuth.instance
              .signInWithPopup(GoogleAuthProvider());
          idToken = await userCredential.user?.getIdToken();
        } else {
          // MOBILE: giữ NGUYÊN luồng native google_sign_in
          final GoogleSignIn googleSignIn = GoogleSignIn();
          final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

          if (googleUser == null) {
            // User hủy login
            emit(state.copyWith(isFormLoading: false));
            return;
          }

          final GoogleSignInAuthentication googleAuth =
              await googleUser.authentication;
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          final UserCredential userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
          idToken = await userCredential.user?.getIdToken();
        }

        if (idToken == null) {
          throw Exception("Không lấy được ID Token từ Google");
        }
  ```
- **GOTCHA:**
  - `final String? idToken;` khai báo không khởi tạo, gán 1 lần ở mỗi nhánh — nhánh mobile có `return` sớm khi `googleUser == null` (không gán), các path còn lại đều gán → Dart definite-assignment hợp lệ, analyze pass.
  - Mỗi nhánh có `final UserCredential userCredential` riêng trong scope block → không trùng tên.
  - KHÔNG chèn `await` nào trước `signInWithPopup` (giữ user-gesture cho popup).

### Site 3 — `lib/feature/auth/bloc/user_bloc.dart` · `catch (e)` cuối handler
- **Locator (anchor):** search chuỗi unique `errorMessage: "Lỗi đăng nhập Google: ${e.toString()}",`  _(≈:91)._
- **BEFORE (verbatim):**
  ```dart
      } catch (e) {
        emit(state.copyWith(
          isFormLoading: false,
          status: UserStatus.error,
          errorMessage: "Lỗi đăng nhập Google: ${e.toString()}",
        ));
      }
  ```
- **AFTER / THAO TÁC:** thêm short-circuit huỷ popup Ở ĐẦU catch; phần emit lỗi giữ nguyên:
  ```dart
      } catch (e) {
        // WEB: user đóng popup / bấm huỷ → coi như cancel (giống mobile googleUser == null), không báo lỗi
        if (e is FirebaseAuthException &&
            (e.code == 'popup-closed-by-user' ||
                e.code == 'cancelled-popup-request' ||
                e.code == 'user-cancelled' ||
                e.code == 'web-context-canceled')) {
          emit(state.copyWith(isFormLoading: false));
          return;
        }
        emit(state.copyWith(
          isFormLoading: false,
          status: UserStatus.error,
          errorMessage: "Lỗi đăng nhập Google: ${e.toString()}",
        ));
      }
  ```
- **GOTCHA:** CHỈ nuốt các mã "đóng/huỷ popup". KHÔNG nuốt `popup-blocked` (đó là lỗi thật, phải hiện dialog để user biết bật popup). `FirebaseAuthException` đã có sẵn qua `firebase_auth` (đã import) — không cần import thêm.

### SYMBOL TABLE (verbatim)

| Symbol | Verbatim | Nguồn | Trạng thái |
|---|---|---|---|
| `kIsWeb` | `import 'package:flutter/foundation.dart' show kIsWeb;` | flutter foundation | [THÊM import] |
| `signInWithPopup` | `Future<UserCredential> signInWithPopup(AuthProvider provider)` | firebase_auth ^5.3.1 | [CÓ] |
| `GoogleAuthProvider()` | constructor rỗng (web) | firebase_auth | [CÓ] |
| `FirebaseAuthException` | `.code` (String) | firebase_auth (đã import :6) | [CÓ] |
| endpoint | `dio.post('auth/google', {'idToken': idToken})` | `auth_remote_datasource.dart:11` | [CÓ] — không đổi |
| backend verify | `admin.auth().verifyIdToken(idToken)` | `authService.js:371` | [CÓ] — không đổi |

### CLONE-THIS
- Nhánh `else` (mobile) = **bê nguyên** 4 lệnh cũ (GoogleSignIn → authentication → credential → signInWithCredential → getIdToken), chỉ bỏ các comment "// 2." "// 3." nếu muốn, không đổi logic.

---

## 6. GATE liên quan

- **Perf:** N/A — không thêm list/timer/listener/API-in-build; chỉ 1 branch + 1 await. Không thêm gì cần dispose.
- **UI/UX:** N/A — không chạm layout. Nút "Continue with Google" (`login_page.dart:410-435`) đã có sẵn, hiển thị mọi platform; loading dùng `isFormLoading` sẵn có.
- **Backend:** N/A — không đụng backend (đã verify Firebase ID token bất kể platform).
- **L10n:** N/A — không thêm string UI mới. (Chuỗi "Lỗi đăng nhập Google" là hardcode CŨ, không introduce ở task này — xem §10.)

---

## 7. Verify + Hồi quy tối thiểu

**Analyze (bắt buộc, 0 lỗi mới):**
```bash
cd english_for_community && dart analyze lib/feature/auth/bloc/user_bloc.dart
```

**Chạy web:**
```bash
cd english_for_community && flutter run -d chrome
```

**Smoke (⭐ = ca nghiệm thu chính):**
1. ⭐ **Web (chrome):** mở `/login` → bấm "Continue with Google" → popup Google hiện → chọn account → vào app (Home), không kẹt loading. (Account Google bất kỳ, không cần seed.)
2. **No-regression mobile (Android):** `flutter run -d <android>` → bấm Google → sheet native → chọn account → vào app **như cũ**.
3. **Abort web:** bấm Google → ĐÓNG popup ngay → KHÔNG hiện dialog lỗi, nút hết loading (bấm lại được).
4. **Edge (không nuốt lỗi):** nếu popup bị chặn / lỗi mạng → hiện dialog "Lỗi đăng nhập Google: ...".

> Nếu popup web báo `auth/unauthorized-domain` → KHÔNG phải bug code: thêm domain đang chạy vào Firebase Console → Authentication → Settings → Authorized domains (localhost đã có sẵn). Báo Opus, đừng tự đổi code.
> Nếu smoke ⭐ vẫn fail sau fix → DỪNG & báo Opus kèm log console browser.

---

## 8. HANDOFF PROMPT cho Cursor/Codex

```text
Bạn là implementer (Cursor/Codex). Làm đúng phạm vi, biên giới cứng.
Repo: english_for_community (Flutter).

━━━ BƯỚC 0 — ĐỌC WORK-ORDER TRƯỚC (bắt buộc) ━━━
Mở & đọc HẾT: docs/plantasks/FEATURE/20260706-google-login-web/work-order.md
Code cần sửa lấy NGUYÊN từ §5 CONTEXT BUNDLE (anchor + BEFORE/AFTER + symbol table) — KHÔNG tự grep đoán.
Nếu file thực tế lệch BEFORE trong §5, hoặc doc mâu thuẫn prompt → DỪNG & hỏi Opus (doc thắng).

━━━ PHẠM VI ━━━
SỬA (chỉ file này): english_for_community/lib/feature/auth/bloc/user_bloc.dart
TUYỆT ĐỐI KHÔNG:
  - Đụng backend, web/index.html, firebase_options.dart, main.dart, login_page.dart, repository/datasource.
  - Đổi/"cải tiến" logic nhánh mobile (nhánh else = copy nguyên văn code cũ).
  - Đổi public signature; mở rộng scope; hardcode secret/clientId; thêm dependency mới.

━━━ LÀM ━━━
Theo §5, 3 Site: (1) thêm import kIsWeb; (2) branch web(signInWithPopup)/mobile trong _onLoginWithGoogleEvent;
(3) thêm short-circuit huỷ popup ở đầu catch(e). Tôn trọng GOTCHA từng Site (definite-assignment idToken; giữ
signInWithPopup là await đầu tiên; chỉ nuốt mã đóng/huỷ popup, KHÔNG nuốt popup-blocked).
GATE: §6 toàn N/A (không perf/UI/backend/l10n mới) — không thêm string, không đổi layout.

━━━ VERIFY (chạy hết, dán kết quả) ━━━
1) cd english_for_community && dart analyze lib/feature/auth/bloc/user_bloc.dart   (0 lỗi mới)
2) flutter run -d chrome → smoke 1..4 ở §7 (⭐ = login web thành công; mobile no-regression; abort không báo lỗi).

━━━ XONG ━━━
- Dán analyze + smoke (đủ 4 bước) vào chat.
- Self-audit ngắn: file đã sửa · rủi ro · checklist tự chấm.
- KHÔNG commit/push. Báo Opus: "implementer đã xong, audit đi".
```

---

## 9. Checklist OPUS AUDIT (Phase 4)
- [ ] `git diff`: CHỈ `user_bloc.dart` đổi; backend/index.html/firebase_options/main/login_page không đụng.
- [ ] Site 1: import `kIsWeb` đã thêm.
- [ ] Site 2: branch `kIsWeb` đúng; nhánh `else` = code mobile cũ nguyên văn; `idToken` definite-assignment; phần sau `if (idToken == null)` dùng chung không đổi.
- [ ] Site 3: chỉ nuốt mã đóng/huỷ popup; nhánh emit lỗi cũ giữ nguyên; `popup-blocked` KHÔNG bị nuốt.
- [ ] `dart analyze` 0 lỗi mới; smoke ⭐ (web login) pass; mobile no-regression pass; abort web không hiện dialog lỗi.
- [ ] Không thêm dependency; không placeholder/TODO.

---

## 10. Follow-up (OUT scope này — task riêng khi cần)
- **Deploy web:** khi lên domain thật, add domain vào Firebase Authorized domains (nếu không → `auth/unauthorized-domain`).
- **l10n hoá lỗi Google:** "Lỗi đăng nhập Google"/"Không lấy được ID Token" đang hardcode VI (nợ cũ) → chuyển sang `app_en.arb`+`app_vi.arb` trong 1 task cleanup l10n chung.
- **Popup bị chặn UX:** cân nhắc fallback `signInWithRedirect` nếu user report popup blocker (hiện dựa `signInWithPopup`).
