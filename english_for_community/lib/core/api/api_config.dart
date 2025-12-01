import 'dart:io';
import 'package:flutter/foundation.dart'; // Để dùng kIsWeb
import 'package:device_info_plus/device_info_plus.dart';

class ApiConfig {
  // Thay IP này bằng IP máy tính của bạn (kiểm tra bằng ipconfig)
  static const _lanIp = '192.168.1.185';
  static const _port = 3000;

  static bool _isPhysicalAndroid = false;
  static bool _initialized = false;

  // Hàm này gọi ở main.dart trước runApp
  static Future<void> init() async {
    if (_initialized) return;

    // 1. QUAN TRỌNG: Check Web trước. Nếu là Web thì dừng luôn.
    // Vì Web không hỗ trợ thư viện device_info_plus của Mobile
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    // 2. Logic Mobile
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final info = await deviceInfo.androidInfo;
        _isPhysicalAndroid = info.isPhysicalDevice ?? true;
      }
    } catch (e) {
      // Phòng hờ lỗi crash nếu chạy trên môi trường lạ
      debugPrint("Lỗi check device info: $e");
    }
    _initialized = true;
  }

  static String get Base_URL {
    // ---------------------------------------------------------
    // ƯU TIÊN 1: WEB (Chạy trên Edge/Chrome)
    // Phải return ngay, không được để code chạy xuống dòng Platform bên dưới
    // ---------------------------------------------------------
    if (kIsWeb) {
      return 'http://localhost:$_port/';
    }

    // ---------------------------------------------------------
    // ƯU TIÊN 2: MOBILE (Android/iOS)
    // ---------------------------------------------------------

    // Nếu chưa init hoặc có lỗi, dùng IP LAN cho an toàn (máy thật hay ảo đều connect được)
    if (!_initialized) return 'http://$_lanIp:$_port/';

    if (Platform.isAndroid) {
      // Máy thật: Dùng IP LAN (192.168...)
      // Emulator: Dùng IP đặc biệt (10.0.2.2) để trỏ về localhost máy tính
      return _isPhysicalAndroid
          ? 'http://$_lanIp:$_port/'
          : 'http://10.0.2.2:$_port/';
    }

    if (Platform.isIOS) {
      // iOS Simulator hay máy thật đều dùng IP LAN
      return 'http://$_lanIp:$_port/';
    }

    // Mặc định cho các nền tảng khác (Windows/Mac app)
    return 'http://localhost:$_port/';
  }

  static String get Socket_URL {
    var url = Base_URL;
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    return url;
  }
}