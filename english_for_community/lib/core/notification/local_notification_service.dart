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
      channelDescription: 'Notifications for replies and reactions',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF2E7D32),
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

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
    if (context == null) {
      print("❌ Context is null, cannot navigate");
      return;
    }

    try {
      // A. Cố gắng giải mã JSON
      final Map<String, dynamic> data = jsonDecode(payload);

      // --- TRƯỜNG HỢP 1: THÔNG BÁO LISTENING (Reply/Reaction) ---
      if (data.containsKey('listeningId')) {
        final String listeningId = data['listeningId'];
        final String? commentId = data['commentId'];
        final String audioUrl = data['audioUrl'] ?? '';
        final String? cueId = data['cueId'];
        print("🚀 Navigating to Listening: $listeningId, Target Comment: $commentId");

        GoRouter.of(context).pushNamed(
          'ListeningSkillsPage',
          pathParameters: {'listeningId': listeningId},
          extra: {
            'listeningId': listeningId,
            'audioUrl': audioUrl,
            'targetCommentId': commentId, // 🔥 ID comment cần highlight
            'openDiscussion': true,       // 🔥 Cờ mở tab Discussion
            'cueId': cueId,
          },
        );
      }

      // --- TRƯỜNG HỢP 2: THÔNG BÁO TỪ VỰNG (Daily Word) ---
      else if (data.containsKey('wordId')) {
        print("🚀 Navigating to Vocabulary...");
        // Điều hướng đến trang từ vựng (Bạn có thể sửa route này theo ý muốn)
        GoRouter.of(context).pushNamed('VocabularyPage');

        // Nếu muốn mở chi tiết từ vựng:
        // GoRouter.of(context).pushNamed(kDictDetailRouteName, extra: Entry(...));
        // (Lưu ý: Cần fetch dữ liệu Entry từ DB dựa trên wordId trước khi push)
      }

    } catch (e) {
      print("⚠️ Payload is not JSON or Error parsing: $e");
      // Fallback: Nếu payload là chuỗi thường (logic cũ), xử lý tại đây
      // Ví dụ: Mở trang chủ
      // GoRouter.of(context).go('/homePage');
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

  // 🟢 5. ĐẶT LỊCH NHẮC TỪ VỰNG HÀNG NGÀY
  Future<void> scheduleDailyWordSequence({
    required List<dynamic> words,
    required TimeOfDay time,
  }) async {
    if (kIsWeb) return;

    await cancelAll(); // Hủy lịch cũ

    final now = tz.TZDateTime.now(tz.local);

    // Tạo thời gian nhắc
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year, now.month, now.day,
      time.hour, time.minute,
    );

    // Nếu giờ đã qua, chuyển sang ngày mai
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    print("📅 Scheduled Daily Words starting at: $scheduledDate");

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final headword = word['headword'] ?? 'Word';
      final definition = word['shortDefinition'] ?? 'Review now';

      // Lấy ID word
      final String wordId = (word['id'] ?? word['_id'] ?? '').toString();

      // 🔥 ĐÓNG GÓI PAYLOAD DẠNG JSON (để _handleNotificationTap đọc được)
      final String jsonPayload = jsonEncode({
        "wordId": wordId,
        "type": "DAILY_VOCAB"
      });

      // Mỗi từ cách nhau 1 phút
      final reminderTime = scheduledDate.add(Duration(minutes: i));

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        i + 1000,
        "Daily Vocab (${i + 1}/${words.length}) 🔔",
        "$headword: $definition",
        reminderTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'vocab_channel_v3',
            'Daily Vocabulary',
            importance: Importance.max,
            priority: Priority.high,
            color: Color(0xFF2E7D32),
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Lặp lại hàng ngày
        payload: jsonPayload, // 🔥 Payload JSON mới
      );
    }
  }

  // 🟢 6. HỦY TẤT CẢ
  Future<void> cancelAll() async {
    if (kIsWeb) return;

    await _flutterLocalNotificationsPlugin.cancelAll();
    print("🗑️ Cancelled all notifications.");
  }
}