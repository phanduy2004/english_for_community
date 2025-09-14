import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get Base_URL {
    if (kIsWeb) {
      // Web: Sử dụng localhost (hoặc IP cục bộ nếu server không chạy trên cùng máy)
      return 'http://localhost:3000/';
    } else {
      // Mobile
      if (Platform.isAndroid && _isEmulator()) {
        // Android emulator
        return 'http://10.0.2.2:3000/';
      } else {
        // Thiết bị thật (Android/iOS) hoặc iOS simulator
        return 'http://192.168.x.x:3000/'; // Thay bằng IP cục bộ của máy bạn
      }
    }
  }

  // Kiểm tra emulator (tùy chọn, nếu cần phân biệt emulator và thiết bị thật)
  static bool _isEmulator() {
    // Giả sử đang chạy trên emulator, có thể dùng package như `device_info_plus` để kiểm tra chính xác
    return true; // Thay bằng logic kiểm tra emulator nếu cần
  }
}