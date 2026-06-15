# Tích hợp animation bên thứ ba (Lottie)

## Đã cài trong app

| Thành phần | Đường dẫn |
|-----------|-----------|
| Package | `lottie` (pubspec) |
| Assets | `english_for_community/assets/animations/*.json` |
| Preset enum | `lib/core/ui/motion/app_lottie_preset.dart` |
| Widget | `lib/core/ui/motion/app_lottie_view.dart` |
| Loading (Paperplane) | `lib/core/ui/motion/app_loading_indicator.dart` → `loading.json` |
| Motion tokens | `lib/core/ui/motion/app_motion.dart` |
| Celebrate overlay | `lib/core/ui/motion/app_celebrate_overlay.dart` |

## Cách thay file animation bạn đã tải

1. Mở [LottieFiles](https://lottiefiles.com/) (hoặc nguồn khác), tải **Lottie JSON**.
2. Copy vào `english_for_community/assets/animations/` và **ghi đè** đúng tên:
   - `empty_notifications.json` — hộp thông báo trống
   - `empty_classes.json` — chưa có lớp
   - `empty_generic.json` — empty state chung
   - `loading.json` — spinner / loading
   - `success_celebrate.json` — chúc mừng (không loop dài)
3. Hot **restart** (không chỉ hot reload) sau khi đổi asset.

Chi tiết tên file: `assets/animations/README.md`.

## Dùng trong UI

```dart
// Empty state (đã có stagger text)
StudentMobileUi.emptyState(
  context,
  icon: Icons.inbox_outlined,
  lottie: AppLottiePreset.emptyGeneric,
  title: '...',
  body: '...',
);

// Loading (thay CircularProgressIndicator)
const Center(child: AppLoadingIndicator.center());
const AppLoadingIndicator.inline(color: AppColors.primary);
const AppLoadingIndicator.button(color: Colors.white);

// Celebrate (hiếm khi)
await AppCelebrateOverlay.show(context);
```

## Màn đã bật Lottie

- `notification_dialog.dart` — `emptyNotifications`
- `my_classes_hub_page.dart` — `emptyClasses`

Các màn empty khác: thêm tham số `lottie:` tương tự (hoặc dùng `emptyGeneric`).

## Rive — mascot đăng nhập

| Thành phần | Đường dẫn |
|-----------|-----------|
| Package | `rive` (pubspec) |
| Asset | `assets/animations/rive/login_machine.riv` |
| Widget | `lib/feature/auth/widgets/login_rive_mascot.dart` |
| Khởi tạo runtime | `main.dart` → `await rive.RiveNative.init()` |

State machine: **`Login Machine`**. Inputs: `isChecking`, `isHandsUp`, `numLook`, `trigSuccess`, `trigFail`.

- Focus email + gõ chữ → nhìn theo `numLook`
- Focus password + ẩn mật khẩu → `isHandsUp` (che mắt)
- Đăng nhập thành công / lỗi → `trigSuccess` / `trigFail`

Màn hình: `login_page.dart` — thay icon sách bằng `AuthLoginRiveMascot` (chiều cao ~180–220px tùy màn hình).

## Loading toàn màn / panel

- **`AppLoadingIndicator.center()`** — Paperplane Lottie (~112px phone, ~168px web).
- **`StudentMobileUi.pageLoading()`** — alias `Center` + `.center()` cho body/dialog.
- **Nút / footer danh sách nhỏ** — `.button()` / `.inline()` vẫn dùng spinner (tránh lag).
- Màn đã chuyển từ skeleton → Lottie: Home, lịch sử bài tập, chart Home, hầu hết `Center(child: AppLoadingIndicator())` trong `lib/`.

## Loading “chạy đến khi xong data” (`AppLoadGate`)

Widget `lib/core/ui/widget/app_load_gate.dart`:

- `isLoading == true` → chỉ hiện animation (Paperplane / spinner).
- API xong (`isLoading == false`) → ẩn animation, hiện `child` (list / empty).

Bloc phải **emit `loading` ngay khi gọi API**, **emit `success`/`failure` khi xong** — không bỏ qua loading khi `isRefresh: true` (đã sửa `NotificationBloc`).

## Loading bị giật (kể cả trước khi dùng Lottie)

Spinner/Lottie chạy trên **UI thread**. Khi giật mà API vẫn đang chờ, thường do:

- **Sau khi response về**: parse JSON / build list lớn trên main thread → drop frame.
- **Debug**: `PrettyDioLogger` in full body (đã thu gọn trong `api_client.dart`).
- **Bloc rebuild** cả màn (Join card + list) thay vì chỉ vùng list.
- **ListView `shrinkWrap: true`** trong dialog (đã bỏ ở notification).

Đã xử lý: parse notification trên isolate, `buildWhen`, warm-up Lottie sau frame đầu.

## Hiệu năng Lottie

- **Warm-up** lúc mở app: `AppLottieCache.warmUp()` trong `main.dart` — parse JSON một lần.
- **Lottie** chỉ dùng cho `AppLoadingIndicator.center()` / màn full (≥72px).
- **Spinner** cho `.inline()` / `.button()` (list footer, nút submit) — tránh vẽ Paperplane 800×600 trong ô 20px khi Bloc rebuild.
- `AppLottieView`: `RenderCache.drawingCommands`, `FrameRate(30)`, `RepaintBoundary`.

Nếu vẫn giật khi mạng chậm: cân nhắc file Lottie nhẹ hơn hoặc skeleton (`AppSkeleton`) thay Lottie trên list.

## Theme Calm Momentum

- Thời gian UI: `AppMotion.fast` / `normal` / `slow`
- Stagger list/empty text: `AppMotion.staggerStep`
- Không lạm dụng `AppCelebrateOverlay` — chỉ sau hành động quan trọng (nộp bài, hoàn thành mục tiêu).
