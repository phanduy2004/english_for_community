import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // ============================================================
  // 1. CẤU HÌNH THÔNG SỐ (Sửa lại IP LAN của bạn ở đây)
  // ============================================================

  // ☁️ Server Render (Online)
  static const String _renderUrl = "https://english-for-community.onrender.com";

  // 🏠 Server Local (Máy tính của bạn) - Thay đổi IP này theo máy bạn
  static const String _localLanIp = "192.168.1.80";
  static const int _localPort = 3000;

  // ============================================================
  // 2. CÔNG TẮC CHUYỂN ĐỔI (CHỌN 1 TRONG 2 CÁCH DƯỚI ĐÂY)
  // ============================================================

  /// 👉 CÁCH 1: CHỈNH TAY (Khuyên dùng khi Dev)
  /// - true: Dùng Local (192.168...) để code cho nhanh.
  /// - false: Dùng Server Render (https...) để test giống người dùng thật.
  static const bool _useLocal = true;

  /// 👉 CÁCH 2: TỰ ĐỘNG (Nâng cao)
  /// Nếu đang chạy Debug (F5) thì dùng Local, còn Build ra file APK thì tự dùng Server.
  /// Muốn dùng cách này thì mở comment dòng dưới và đóng dòng trên lại.
  // static const bool _useLocal = kDebugMode;

  // ============================================================
  // 3. LOGIC XỬ LÝ (Không cần sửa gì ở dưới này)
  // ============================================================

  static Future<void> init() async {
    // Không cần logic phức tạp nữa
  }

  static String get Base_URL {
    // A. Nếu dùng SERVER ONLINE (Render)
    if (!_useLocal) {
      return '$_renderUrl/';
    }

    // B. Nếu dùng SERVER LOCAL (Máy tính)
    // 1. Web: Luôn là localhost
    if (kIsWeb) {
      return 'http://localhost:$_localPort/';
    }

    // 2. Android: Cần xử lý riêng cho Emulator
    if (Platform.isAndroid) {
      // Nếu chạy trên máy ảo Android (Emulator) -> Dùng 10.0.2.2
      // Nếu chạy trên điện thoại thật -> Dùng IP LAN
      // (Cách đơn giản để check emulator là check model, hoặc cứ mặc định dùng LAN IP nếu test máy thật là chính)
      const bool isEmulator = false; // Đổi thành true nếu bạn code bằng Máy ảo Android Studio

      return isEmulator
          ? 'http://10.0.2.2:$_localPort/'
          : 'http://$_localLanIp:$_localPort/';
    }

    // 3. iOS / Các nền tảng khác: Dùng IP LAN
    return 'http://$_localLanIp:$_localPort/';
  }

  static String get Socket_URL {
    // Socket.io client không cần dấu '/' ở cuối
    var url = Base_URL;
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }
}