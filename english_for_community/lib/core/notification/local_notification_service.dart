import 'dart:convert'; // 🔥 Import để xử lý JSON
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart'; // 🔥 Import GoRouter
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../utils/global_keys.dart';
import 'package:english_for_community/feature/home/notification_dialog.dart';
import 'notification_navigation.dart';

class LocalNotificationService {
  // Singleton Pattern
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // 🟢 1. KHỞI TẠO DỊCH VỤ
  Future<void> init() async {
    if (kIsWeb) return;

    // A. Khởi tạo dữ liệu múi giờ
    tz.initializeTimeZones();

    // B. Lấy múi giờ thực tế của điện thoại
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      print("⚠️ Không lấy được múi giờ, dùng mặc định Asia/Ho_Chi_Minh");
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    }

    // C. Cấu hình Icon cho Android
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // D. Cấu hình cho iOS
    final DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // E. Khởi tạo Plugin & Đăng ký sự kiện Click
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      // 👇 HÀM NÀY CHẠY KHI NGƯỜI DÙNG BẤM VÀO THÔNG BÁO
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          print("👉 User tapped notification (Payload: ${response.payload})");
          _handleNotificationTap(response.payload!);
        }
      },
    );
  }

  // 🟢 2. SHOW THÔNG BÁO NGAY LẬP TỨC (Dùng cho Socket/Push)
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'social_channel',
      'Social Interactions',
      channelDescription: 'Notifications for replies, exams, and classroom updates',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF2E7D32),
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // 🟢 3. XỬ LÝ ĐIỀU HƯỚNG THÔNG MINH (LOGIC MỚI)
  void _handleNotificationTap(String payload) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    try {
      final data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
      final router = GoRouter.of(context);
      if (!navigateFromNotification(router, data: data)) {
        showAppNotificationsDialog(context);
      }
    } catch (e) {
      print('⚠️ Notification payload parse error: $e');
      showAppNotificationsDialog(context);
    }
  }

  // 🟢 4. XIN QUYỀN THÔNG BÁO
  Future<void> requestPermissions() async {
    if (kIsWeb) return;

    if (Platform.isIOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  // 🟢 5. HỦY TẤT CẢ
  Future<void> cancelAll() async {
    if (kIsWeb) return;

    await _flutterLocalNotificationsPlugin.cancelAll();
    print("🗑️ Cancelled all notifications.");
  }
}
