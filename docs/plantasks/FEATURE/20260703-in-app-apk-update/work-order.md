# Work-Order — FEATURE: Tải + cài APK ngay trong app (in-app OTA update, Android)

- **Task ID:** 20260703-in-app-apk-update
- **Loại:** FEATURE · **Platform:** student mobile (Flutter, **Android-only**) · **Cỡ:** T1 (~5 file, 1 file mới)
- **Mục tiêu:** Khi hiện dialog cập nhật, người dùng bấm "Cập nhật ngay" → app **tải APK ngay trong app** (thanh tiến trình %) → mở thẳng màn hình cài đặt hệ thống → cài đè. KHÔNG bắt user tự mở trình duyệt tải file.
- **Người phân tích:** Opus (brain). **Implementer:** Cursor. **Status:** PLAN XONG — chờ implement.
- **Liên quan:** nối tiếp `docs/plantasks/BUG/20260702-mobile-update-dialog-context/` (fix dialog đã APPROVED). Đây là nâng cấp UX bước tải/cài.

> Giới hạn Android: app sideload **không thể** tự cài im lặng. Mức mượt nhất = ở-trong-app tải + 1 lần cấp quyền "nguồn không xác định" (lần đầu) + 1 lần bấm "Cài đặt" của hệ thống. Muốn im lặng 100% phải phát hành qua Google Play (ngoài scope).

---

## 1. Hiện trạng + ground-truth (dẫn chứng)

- Dialog & nút hiện tại: `lib/feature/app_update/app_update_guard.dart:115-125` — `_openUpdateUrl` chỉ `launchUrl(info.updateUrl, LaunchMode.externalApplication)` → **mở trình duyệt**, user tự tải + tự tìm file cài.
- `info.updateUrl` (`lib/core/entity/app_update_info_entity.dart:30-34`) = `downloadUrl ?? storeUrl`. Với Android, `downloadUrl` = APK GitHub Release (đã verify: 302→200, `application/vnd.android.package-archive`, ~214 MB).
- Deps đã có (`pubspec.yaml`): `dio: ^5.7.0` (:46), `path_provider: ^2.1.5` (:59), `permission_handler: ^11.4.0` (:72), `package_info_plus` (:87), `url_launcher: ^6.3.0` (:88). **Thiếu** gói mở installer.
- Manifest (`android/app/src/main/AndroidManifest.xml`): có `INTERNET`, `usesCleartextTraffic="true"`, `label="E4C"`. **Thiếu** `REQUEST_INSTALL_PACKAGES`. Chưa có FileProvider.
- `applicationId = com.example.english_for_community` (`android/app/build.gradle.kts:37`) — giữ nguyên (cùng package + cùng keystore CI ⇒ cài đè được). *(Note ngoài scope: `com.example.*` sẽ bị Google Play từ chối — không ảnh hưởng sideload.)*

---

## 2. Quyết định thiết kế + cảnh báo

**Luồng (Android):**
1. Bấm "Cập nhật ngay" → kiểm/ xin quyền `Permission.requestInstallPackages` (permission_handler). Từ chối → **fallback** mở trình duyệt (hành vi cũ) + báo nhẹ, DỪNG.
2. Tải APK bằng **`Dio()` mới** (không dùng `dioPublic` để tránh baseUrl `/api/` + interceptor): `dio.download(downloadUrl, savePath, onReceiveProgress: ...)`. Dio follow redirect GitHub mặc định.
   - `savePath` = `${(await getExternalStorageDirectory())!.path}/e4c-update-<versionCode>.apk` (thư mục app-specific external → không cần quyền storage; nằm trong path FileProvider của open_filex).
   - Xoá file APK cũ trước khi tải (dọn rác).
3. Xong → `OpenFilex.open(savePath, type: 'application/vnd.android.package-archive')` → hệ thống mở installer → user bấm Cài. Kết quả != `done` → **fallback** trình duyệt.
4. Mọi lỗi (mạng/permission/open) → giữ dialog, hiện lỗi + nút **"Mở bằng trình duyệt"** (fallback) và **"Thử lại"**.

**Gói thêm:** `open_filex` (chỉ để bắn install intent; tự khai FileProvider authority `${applicationId}.fileProvider...` nên KHÔNG cần cấu hình FileProvider thủ công). Cài bằng `flutter pub add open_filex` (để pub resolve version hợp Flutter hiện tại).

**Chỉ Android.** Bọc nhánh tải/cài trong `if (Platform.isAndroid)`; iOS/khác giữ nguyên `launchUrl(info.updateUrl)`.

**Cảnh báo:**
- Không dùng `dioPublic` để download (baseUrl `.../api/` sẽ phá URL tuyệt đối + interceptor thừa). Dùng `Dio()` mới.
- File ~214 MB: BẮT BUỘC có progress + cho **huỷ** (soft) + xử lý lỗi mạng; không block UI, không giữ spinner vô hạn.
- `_UpdateDialogContent` hiện là `StatelessWidget` → phải chuyển **`StatefulWidget`** để giữ state (idle/downloading %/error). Force-update: giữ `PopScope canPop:false`, và **khoá huỷ** trong lúc tải.
- Không đổi cơ chế `version-check`/bloc/entity — chỉ đổi hành vi nút trong dialog + thêm service tải/cài.

---

## 3. Scope IN / OUT

**IN (được sửa/thêm):**
1. `pubspec.yaml` — thêm `open_filex`.
2. `android/app/src/main/AndroidManifest.xml` — thêm `REQUEST_INSTALL_PACKAGES`.
3. **File mới** `lib/feature/app_update/app_apk_updater.dart` — service tải+quyền+mở installer+dọn rác+fallback.
4. `lib/feature/app_update/app_update_guard.dart` — `_UpdateDialogContent` → Stateful; nút "Cập nhật ngay" gọi service; UI progress + error + fallback.
5. `lib/l10n/app_en.arb` + `lib/l10n/app_vi.arb` — string mới + `flutter gen-l10n`.

**OUT (chạm là DỪNG & hỏi):**
- ❌ `app_update_bloc.dart`, `app_update_remote_datasource.dart`, `app_update_info_entity.dart`, `version-check` backend, CI workflow.
- ❌ Đổi `applicationId`, keystore, signing.
- ❌ Thêm FileProvider thủ công (open_filex tự lo) trừ khi build lỗi thiếu provider → báo trước.
- ❌ Đổi luồng iOS (giữ `launchUrl`).
- ❌ Tự cài im lặng / auto-install không hỏi (Android cấm).

---

## 4. Diff theo file (Cursor tự viết code; code mẫu chỉ ở chỗ tinh tế)

### 4.1 `pubspec.yaml`
`flutter pub add open_filex` (không tự gõ tay version — để resolve).

### 4.2 `AndroidManifest.xml` (cạnh các uses-permission)
```xml
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
```

### 4.3 File mới `lib/feature/app_update/app_apk_updater.dart`
Service thuần Dart, Android-only. API gợi ý:
```dart
enum ApkUpdateStage { idle, checkingPermission, downloading, opening, error }

class ApkUpdateProgress {
  final ApkUpdateStage stage;
  final double progress;   // 0..1 khi downloading
  final String? error;
  const ApkUpdateProgress(this.stage, {this.progress = 0, this.error});
}

class AppApkUpdater {
  final Dio _dio = Dio(); // KHÔNG dùng dioPublic
  CancelToken? _cancel;

  /// Trả về true nếu đã mở được installer; false nếu caller nên fallback trình duyệt.
  Future<bool> downloadAndInstall({
    required String url,
    required int versionCode,
    required void Function(ApkUpdateProgress) onProgress,
  }) async {
    try {
      onProgress(const ApkUpdateProgress(ApkUpdateStage.checkingPermission));
      final status = await Permission.requestInstallPackages.status;
      final granted = status.isGranted
          ? true
          : (await Permission.requestInstallPackages.request()).isGranted;
      if (!granted) return false; // caller fallback trình duyệt

      final dir = await getExternalStorageDirectory();
      if (dir == null) return false;
      final path = '${dir.path}/e4c-update-$versionCode.apk';
      final file = File(path);
      if (await file.exists()) await file.delete(); // dọn rác

      _cancel = CancelToken();
      onProgress(const ApkUpdateProgress(ApkUpdateStage.downloading));
      await _dio.download(
        url, path,
        cancelToken: _cancel,
        onReceiveProgress: (rec, total) {
          if (total > 0) {
            onProgress(ApkUpdateProgress(
              ApkUpdateStage.downloading, progress: rec / total));
          }
        },
      );

      onProgress(const ApkUpdateProgress(ApkUpdateStage.opening));
      final res = await OpenFilex.open(
        path, type: 'application/vnd.android.package-archive');
      return res.type == ResultType.done;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return true; // user huỷ, không coi là lỗi
      onProgress(ApkUpdateProgress(ApkUpdateStage.error, error: e.message));
      return false;
    } catch (e) {
      onProgress(ApkUpdateProgress(ApkUpdateStage.error, error: e.toString()));
      return false;
    }
  }

  void cancel() => _cancel?.cancel();
}
```
**Ràng buộc:** không rò `Dio`; huỷ token khi dispose; `versionCode` lấy từ `info.latestVersionCode`.

### 4.4 `app_update_guard.dart` — `_UpdateDialogContent` → Stateful
- Chuyển `_UpdateDialogContent` sang `StatefulWidget`, giữ `AppApkUpdater` + state `ApkUpdateProgress`.
- Nút "Cập nhật ngay":
  - **Android:** gọi `updater.downloadAndInstall(url: info.downloadUrl!, versionCode: info.latestVersionCode, onProgress: setState...)`. Trả `false` (hoặc `downloadUrl` null) → **fallback** `_openUpdateUrl` (giữ hàm cũ, dùng `info.updateUrl`).
  - **iOS/khác:** gọi thẳng `_openUpdateUrl` như cũ.
- Khi `stage == downloading`: thay nút bằng `LinearProgressIndicator(value: progress)` + text `l10n.updateDownloading((progress*100).round())`; soft → có nút **Huỷ** (gọi `updater.cancel()` + về idle); force → khoá huỷ + khoá `PopScope`.
- Khi `stage == error`: hiện `l10n.updateDownloadFailed` + 2 nút **Thử lại** / **Mở bằng trình duyệt** (`_openUpdateUrl`).
- Giữ nguyên header/changelog/version line hiện có.
- `dispose()`: `updater.cancel()`.

### 4.5 l10n (`app_en.arb` + `app_vi.arb`) + `flutter gen-l10n`
Thêm key (EN + VI), đặt cạnh nhóm `update*` hiện có:
| key | EN | VI |
|---|---|---|
| `updateDownloading` (placeholder `{progress}` số) | `Downloading… {progress}%` | `Đang tải… {progress}%` |
| `updatePreparingInstall` | `Preparing to install…` | `Đang chuẩn bị cài đặt…` |
| `updateDownloadFailed` | `Download failed. Please try again.` | `Tải thất bại. Vui lòng thử lại.` |
| `updateOpenInBrowser` | `Open in browser` | `Mở bằng trình duyệt` |
| `updateRetry` | `Retry` | `Thử lại` |
| `updateCancel` | `Cancel` | `Huỷ` |
(giữ `updateNowButton`, `updateLaterButton`, `updateLinkOpenFailed` cũ.)

---

## 5. Ràng buộc UI/UX
- Dùng token/component sẵn có (`AppColors`, `FilledButton`, `TextButton`, `LinearProgressIndicator` theme). Không hardcode hex mới ngoài palette hiện dùng trong file.
- Đủ 3 state: idle (nút), downloading (progress + huỷ), error (retry + fallback). Không spinner toàn màn.
- Force-update: không tắt được dialog, không huỷ được tải; soft: huỷ/để-sau được.
- Hit target ≥44dp; text co giãn (đã có nhánh `stackActionsVertically`).

## 6. Ràng buộc hiệu năng
- Không chạy tải trong `build()`; chỉ trigger từ callback nút.
- Progress cập nhật qua `setState` cục bộ trong dialog (không rebuild cây app).
- Huỷ `CancelToken` khi dispose để không rò tải nền / callback sau unmount (`if (!mounted) return;` trước `setState`).

---

## 7. Lệnh verify
```bash
cd english_for_community
flutter pub get
flutter gen-l10n
flutter analyze                       # 0 lỗi (đặc biệt app_update_guard.dart, app_apk_updater.dart)
flutter build apk --release --dart-define-from-file=config/prod.json   # build ok, không lỗi manifest/merge
```
**Smoke thiết bị thật (bắt buộc — Android):**
```bash
flutter run --dart-define-from-file=config/prod.json   # app báo versionCode=1 < bản published → dialog hiện
```
- Bấm "Cập nhật ngay" → (lần đầu) hệ thống xin quyền "cài từ nguồn không xác định" → cho phép → **thanh tiến trình chạy trong app** → xong hiện **màn hình Cài đặt hệ thống** → cài đè → mở lại app đã update.
- Từ chối quyền → **fallback** mở trình duyệt (không crash).
- Ngắt mạng giữa chừng → hiện lỗi + "Thử lại"/"Mở bằng trình duyệt".

## 8. Hồi quy tối thiểu
1. Soft update: huỷ tải giữa chừng → về idle, "Để sau" vẫn đóng được dialog.
2. Force update: không tắt/huỷ được; tải xong cài được.
3. `downloadUrl` null (chỉ storeUrl) → fallback `launchUrl`.
4. iOS/web build (nếu chạy): không gọi nhánh install; không đụng `dart:io` sai chỗ (bọc `Platform.isAndroid`; import `dart:io` an toàn — file này Android-only, không import ở web path).
5. `up_to_date` → không hiện dialog (không regress).

---

## 9. HANDOFF PROMPT cho Cursor (copy nguyên khối)
```text
Bạn là implementer. CHỈ sửa/thêm đúng các file dưới; ngoài danh sách → DỪNG & hỏi.
Repo: english_for_community (Flutter). FEATURE: tải + cài APK trong app (Android).

FILE:
  1. pubspec.yaml                                   — flutter pub add open_filex
  2. android/app/src/main/AndroidManifest.xml       — thêm REQUEST_INSTALL_PACKAGES
  3. lib/feature/app_update/app_apk_updater.dart     — MỚI: service tải+quyền+open installer (theo mục 4.3)
  4. lib/feature/app_update/app_update_guard.dart    — _UpdateDialogContent -> Stateful, progress+error+fallback (mục 4.4)
  5. lib/l10n/app_en.arb + app_vi.arb                — thêm key mục 4.5 + flutter gen-l10n

THEO ĐÚNG mục 2/4/5 work-order. TUYỆT ĐỐI KHÔNG:
  - Dùng dioPublic để download (tạo Dio() mới).
  - Đụng bloc/datasource/entity/version-check/CI/applicationId/keystore.
  - Thêm FileProvider thủ công (open_filex tự lo) — nếu build báo thiếu provider thì DỪNG & hỏi.
  - Tự cài im lặng không hỏi; bỏ nhánh fallback trình duyệt.
  - Bỏ Platform.isAndroid guard (iOS/khác giữ launchUrl cũ).

VERIFY: flutter pub get && flutter gen-l10n && flutter analyze (0 lỗi) &&
        flutter build apk --release --dart-define-from-file=config/prod.json
SMOKE (thiết bị Android): flutter run --dart-define-from-file=config/prod.json
        -> "Cập nhật ngay" -> cấp quyền -> progress trong app -> màn Cài đặt hệ thống -> cài đè.
Xong -> dán kết quả analyze/build + ảnh/clip smoke vào tracker -> báo Opus audit.
```

---

## 10. Checklist OPUS AUDIT (Phase 4)
- [ ] Chỉ 5 file trong scope; không đụng file OUT.
- [ ] Download dùng `Dio()` mới (không dioPublic); follow redirect; có `onReceiveProgress` + `CancelToken`.
- [ ] Quyền `REQUEST_INSTALL_PACKAGES` trong manifest; xin quyền runtime; từ chối → fallback trình duyệt.
- [ ] `open_filex` mở với MIME `application/vnd.android.package-archive`; kết quả != done → fallback.
- [ ] Nhánh install bọc `Platform.isAndroid`; iOS/khác giữ `launchUrl`.
- [ ] `_UpdateDialogContent` Stateful: 3 state (idle/downloading/error); force khoá huỷ + `PopScope canPop:false`; `if(!mounted)` trước `setState`; `dispose` huỷ token.
- [ ] Dọn APK cũ trước khi tải; không rò Dio/subscription.
- [ ] l10n EN+VI đủ key; `flutter gen-l10n` chạy; không hardcode string.
- [ ] `flutter analyze` 0 lỗi; `flutter build apk` ok; smoke thiết bị PASS (tải trong app → màn cài hệ thống → cài đè).
- [ ] Không regress: soft huỷ được, force không, downloadUrl null → fallback, up_to_date → không dialog.
