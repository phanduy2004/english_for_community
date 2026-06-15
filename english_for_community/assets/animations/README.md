# Animation assets (Lottie)

Thư mục này chứa file **JSON Lottie** tải từ bên thứ ba (LottieFiles, Lordicon, IconScout, …).

## Cách thay animation

1. Tải file **Lottie JSON** (không dùng `.lottie` zip trừ khi giải nén ra `.json`).
2. Đổi tên đúng một trong các file bên dưới (ghi đè file cũ).
3. `flutter pub get` (nếu vừa sửa `pubspec.yaml`) rồi **hot restart** app.

| File | Dùng ở đâu (Flutter) |
|------|----------------------|
| `empty_generic.json` | Empty state mặc định |
| `empty_notifications.json` | Hộp thông báo trống |
| `empty_classes.json` | Lớp học của học sinh trống |
| `loading.json` | **Paperplane** — loading toàn app (`AppLoadingIndicator`) |
| `success_celebrate.json` | Chúc mừng / hoàn thành (dùng ít) |

## Gợi ý tìm animation

- [LottieFiles](https://lottiefiles.com/) — lọc **Free**, format **JSON**
- Từ khóa: `empty`, `notification bell`, `classroom`, `loading`, `success check`

## Code

- Preset: `AppLottiePreset` → `lib/core/ui/motion/app_lottie_preset.dart`
- Widget: `AppLottieView`
- Empty UI: `StudentMobileUi.emptyState(..., lottie: AppLottiePreset.emptyNotifications)`

Giữ animation **nhẹ** (Calm Momentum): ưu tiên loop chậm, không full-screen trừ celebrate.
