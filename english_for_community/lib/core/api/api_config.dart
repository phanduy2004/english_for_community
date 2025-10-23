import 'package:flutter/foundation.dart' show kIsWeb;
// Tránh import dart:io khi build web: chỉ import khi không phải web
// (nếu bạn build web, dùng conditional import; còn nhanh gọn thì giữ như dưới nếu web vẫn build ok)
import 'dart:io' show Platform;

class ApiConfig {
  static const _lanIp = '192.168.1.89'; // <— ĐỔI thành IP thật của PC bạn
  static const _port  = 3000;

  static String get Base_URL {
    if (kIsWeb) return 'http://localhost:$_port/';

    if (Platform.isAndroid) {
      // Máy thật Android dùng IP LAN
      return 'http://$_lanIp:$_port/';
    }

    if (Platform.isIOS) {
      // iOS simulator/máy thật cũng dùng IP LAN
      return 'http://$_lanIp:$_port/';
    }

    // macOS/Windows/Linux (nếu có)
    return 'http://localhost:$_port/';
  }
}
