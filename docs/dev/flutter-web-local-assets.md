# Flutter Web — CDN bị chặn (Edge / Chrome)

## Triệu chứng

```
Failed to fetch ... fonts.gstatic.com ... Roboto
Failed to fetch ... gstatic.com/flutter-canvaskit/.../canvaskit.js
Application finished.
```

Flutter Web mặc định tải **CanvasKit** và font **Roboto** từ CDN Google (`gstatic.com`). Mạng công ty, VPN, firewall hoặc adblock thường chặn → app không khởi động được.

## Cách chạy (dev)

**Cursor / VS Code:** chọn launch config **「E4C — Edge (local web assets)」** hoặc dùng F5 sau khi repo đã có `.vscode/settings.json` (`--no-web-resources-cdn`).

**Terminal:**

```bash
cd english_for_community
flutter run -d edge --no-web-resources-cdn
# hoặc
flutter run -d chrome --no-web-resources-cdn
```

Flag này bundle CanvasKit + font vào build local, phục vụ từ `localhost` thay vì CDN.

## Build production

```bash
flutter build web --no-web-resources-cdn
```

Deploy thư mục `build/web/` (kèm thư mục `canvaskit/` bên trong).

## Nếu vẫn lỗi

1. Kiểm tra internet / tắt adblock cho `localhost`.
2. Thử Chrome thay Edge (hoặc ngược lại).
3. `flutter clean` rồi chạy lại với `--no-web-resources-cdn`.
4. Flutter cũ: thêm `--web-renderer html` (renderer HTML đã bị gỡ ở bản Flutter mới).
