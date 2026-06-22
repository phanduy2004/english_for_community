import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // ============================================================
  // 1. NGUỒN CẤU HÌNH (ưu tiên compile-time define — KHÔNG sửa source để đổi môi trường)
  // ============================================================

  // ☁️ Production mặc định (dùng khi release / khi không truyền define)
  static const String _renderUrl = "https://english-for-community.onrender.com";

  // 🔧 Override tường minh: --dart-define=API_BASE_URL=...
  //    - Rỗng      → tự động theo build mode (debug = local, release = production).
  //    - Có giá trị → DÙNG NGUYÊN giá trị này (CI prod, hoặc dev tự chỉ định).
  static const String _envBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  // 🏠 IP LAN máy dev — KHÔNG hardcode nữa. Truyền qua config/local.json (đã .gitignore):
  //    flutter run --dart-define-from-file=config/local.json
  //    LDPlayer / máy Android thật: dùng IPv4 Wi‑Fi/Ethernet (cmd: ipconfig → dòng IPv4, thường 192.168.x.x).
  //    Không dùng IP VMware/Hyper-V (192.168.163.x, 192.168.62.x).
  static const String _localLanIp =
      String.fromEnvironment('LOCAL_LAN_IP', defaultValue: '192.168.1.72');
  static const int _localPort =
      int.fromEnvironment('LOCAL_PORT', defaultValue: 3000);

  // ============================================================
  // 2. CHỌN MÔI TRƯỜNG (tự động — không cần sửa tay)
  // ============================================================
  //  - Có API_BASE_URL         → dùng URL đó.
  //  - Debug (flutter run)     → local.
  //  - Release/Profile (build) → production.
  static bool get _useLocal => _envBaseUrl.isEmpty && kDebugMode;

  // ============================================================
  // 3. LOGIC XỬ LÝ (Không cần sửa gì ở dưới này)
  // ============================================================

  /// Android emulator → host machine is [emulatorHost] (10.0.2.2), not LAN IP.
  /// LDPlayer / BlueStacks / MEmu: luôn dùng IP LAN PC — 10.0.2.2 thường không hoạt động.
  static bool _androidUsesEmulatorHost = false;

  static bool _isThirdPartyAndroidEmulator(AndroidDeviceInfo info) {
    final blob = [
      info.manufacturer,
      info.brand,
      info.model,
      info.product,
      info.device,
      info.hardware,
      info.fingerprint,
    ].join(' ').toLowerCase();
    return blob.contains('ldplayer') ||
        blob.contains('ldplay') ||
        blob.contains('dnplayer') ||
        blob.contains('changwan') ||
        blob.contains('bluestacks') ||
        blob.contains('memu') ||
        blob.contains('nox');
  }

  /// Gọi trong `main()` trước `setup()` để nhận diện máy ảo / máy thật.
  static Future<void> init() async {
    if (kIsWeb || !_useLocal || !Platform.isAndroid) return;
    try {
      final android = await DeviceInfoPlugin().androidInfo;
      final thirdPartyEmu = _isThirdPartyAndroidEmulator(android);
      // AVD: 10.0.2.2 → host PC. LDPlayer & co.: IP LAN (cùng mạng với PC).
      _androidUsesEmulatorHost =
          !android.isPhysicalDevice && !thirdPartyEmu;
      if (kDebugMode) {
        if (_useLocal) {
          final host = _androidUsesEmulatorHost ? '10.0.2.2' : _localLanIp;
          final kind = thirdPartyEmu
              ? 'LDPlayer/third-party emulator'
              : android.isPhysicalDevice
                  ? 'device'
                  : 'AVD emulator';
          debugPrint('[ApiConfig] Android $kind → $host:$_localPort');
        } else {
          final mode = _envBaseUrl.isNotEmpty ? 'override (API_BASE_URL)' : 'Render (release)';
          debugPrint('[ApiConfig] API target: $mode → $Base_URL');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ApiConfig] device check failed, using LAN IP: $e');
      }
    }
  }

  static String get Base_URL {
    // 0. Override tường minh (CI prod / dev tự chỉ định) — ưu tiên cao nhất.
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl.endsWith('/') ? _envBaseUrl : '$_envBaseUrl/';
    }

    // A. Nếu dùng SERVER ONLINE (Render)
    if (!_useLocal) {
      return '$_renderUrl/';
    }

    // B. Nếu dùng SERVER LOCAL (Máy tính)
    // 1. Web: Luôn là localhost
    if (kIsWeb) {
      return 'http://localhost:$_localPort/';
    }

    // 2. Android: AVD → 10.0.2.2; LDPlayer / máy thật → IP LAN PC
    if (Platform.isAndroid) {
      return _androidUsesEmulatorHost
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