import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// Import thư viện Timezone
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
// Import thư viện lấy múi giờ máy
import 'package:flutter_timezone/flutter_timezone.dart';

// Import Router để điều hướng khi bấm vào thông báo
import '../../core/router/app_router.dart';
import '../utils/global_keys.dart'; // Hoặc nơi bạn để rootNavigatorKey
// import '../../core/utils/global_keys.dart'; // Nếu rootNavigatorKey ở đây

class LocalNotificationService {
  // Singleton Pattern
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // 🟢 1. KHỞI TẠO DỊCH VỤ
  Future<void> init() async {
    // A. Khởi tạo dữ liệu múi giờ
    tz.initializeTimeZones();

    // B. Lấy múi giờ thực tế của điện thoại (Quan trọng để không bị lệch giờ)
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      print("🕒 Đã cập nhật múi giờ theo máy: $timeZoneName");
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

    // E. Khởi tạo Plugin & Xử lý sự kiện Click
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Xử lý khi người dùng bấm vào thông báo
        if (response.payload != null) {
          print("👉 Người dùng bấm vào thông báo (Payload: ${response.payload})");
          _navigateToVocabulary(response.payload!);
        }
      },
    );
  }
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'social_channel', // ID kênh riêng cho thông báo xã hội
      'Thông báo tương tác', // Tên kênh hiển thị trong cài đặt
      channelDescription: 'Thông báo khi có người trả lời hoặc thả tim',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      color: Color(0xFF2E7D32),
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    debugPrint("🔔 [Local Notification] Received Notification Data of body: $body");
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }
  // 🟢 2. HÀM ĐIỀU HƯỚNG (Khi bấm vào thông báo)
  void _navigateToVocabulary(String payload) {
    // Sử dụng GlobalKey để điều hướng từ bất cứ đâu
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      // Điều hướng đến màn hình Từ vựng (Sửa lại route cho đúng app của bạn)
      // Ví dụ: Mở trang Vocabulary
      // GoRouter.of(context).pushNamed('VocabularyPage');

      print("🚀 Đang mở màn hình từ vựng...");
    }
  }

  // 🟢 3. XIN QUYỀN THÔNG BÁO & BÁO THỨC
  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      // Xin quyền hiện thông báo (Android 13+)
      await androidImplementation?.requestNotificationsPermission();

      // Xin quyền đặt lịch chính xác (Android 12+)
      // (Nếu máy khó tính sẽ hiện dialog dẫn vào cài đặt)
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  // 🟢 4. ĐẶT LỊCH NHẮC 3 TỪ (CHẠY THẬT HÀNG NGÀY)
  Future<void> scheduleDailyWordSequence({
    required List<dynamic> words,
    required TimeOfDay time,
  }) async {
    await cancelAll(); // Hủy lịch cũ

    final now = tz.TZDateTime.now(tz.local);

    // Tạo thời gian nhắc cơ sở
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year, now.month, now.day,
      time.hour, time.minute,
    );

    // Nếu giờ này đã qua rồi thì đặt cho ngày mai
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    print("📅 Đã lên lịch nhắc từ vựng bắt đầu lúc: $scheduledDate");

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final headword = word['headword'] ?? 'Word';
      final definition = word['shortDefinition'] ?? 'Tap to review';

      // ID payload để mở đúng từ
      final String idPayload = (word['id'] ?? word['_id'] ?? '').toString();

      // Mỗi từ cách nhau 1 phút
      final reminderTime = scheduledDate.add(Duration(minutes: i));

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        i + 1000, // ID duy nhất
        "Học từ vựng (${i + 1}/${words.length}) 🔔",
        "$headword: $definition",
        reminderTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'vocab_channel_v3', // ID Kênh (Phải trùng với lúc test)
            'Nhắc nhở học tập',
            importance: Importance.max,
            priority: Priority.high,
            color: Color(0xFF2E7D32),
            icon: '@mipmap/ic_launcher',
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        // Dùng inexact để ổn định hơn trên các máy chặn ngầm
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        // Lặp lại hàng ngày
        matchDateTimeComponents: DateTimeComponents.time,
        payload: idPayload,
      );
    }
  }

  // 🟢 5. HÀM TEST: KIỂM TRA XEM THÔNG BÁO CÓ HIỆN KHÔNG
  Future<void> testWithRealData(List<dynamic> words) async {
    print("🧪 Bắt đầu test...");
    await cancelAll();

    final now = tz.TZDateTime.now(tz.local);

    // In ra giờ hệ thống để đối chiếu
    print("🕒 Giờ hệ thống (Timezone): $now");
    print("🕒 Giờ điện thoại (DateTime): ${DateTime.now()}");

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final headword = word['headword'] ?? 'Unknown';
      final definition = word['shortDefinition'] ?? '...';
      final String idPayload = (word['id'] ?? word['_id'] ?? 'word_$i').toString();
      final notificationId = 9000 + i;

      if (i == 0) {
        // Từ 1: Hiện ngay
        await _flutterLocalNotificationsPlugin.show(
          notificationId,
          "🔔 Test Ngay: $headword",
          definition,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'vocab_channel_v3',
              'Nhắc nhở học tập',
              importance: Importance.max,
              priority: Priority.high,
              color: Color(0xFF2E7D32),
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: idPayload,
        );
      } else {
        // 🔥 CHIẾN THUẬT AN TOÀN:
        // Đặt lịch các từ sau cách hiện tại i phút (1 phút, 2 phút...)
        final scheduledDate = now.add(Duration(minutes: i));

        try {
          await _flutterLocalNotificationsPlugin.zonedSchedule(
            notificationId,
            "🔔 Test Hẹn Giờ ($i): $headword",
            definition,
            scheduledDate,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'vocab_channel_v3',
                'Nhắc nhở học tập',
                importance: Importance.max,
                priority: Priority.high,
                color: Color(0xFF2E7D32),
                icon: '@mipmap/ic_launcher',
                // Thêm cái này để đảm bảo hiện khi màn hình khóa
                visibility: NotificationVisibility.public,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            // Vẫn dùng Exact để test quyền
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            payload: idPayload,
          );
          print("⏳ Đã gửi lệnh hẹn: '$headword' (ID: $notificationId) vào $scheduledDate");
        } catch (e) {
          print("☠️ LỖI KHI GỌI ZONEDSCHEDULE: $e");
        }
      }
    }

    // 🔥 QUAN TRỌNG: Kiểm tra lại ngay xem Android đã lưu chưa
    await Future.delayed(const Duration(seconds: 1)); // Đợi 1 xíu cho chắc
    await checkPendingNotifications();
  }
  // 🟢 6. HỦY TẤT CẢ
  Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    print("🗑️ Đã hủy tất cả lịch nhắc nhở cũ.");
  }
  Future<void> checkPendingNotifications() async {
    final List<PendingNotificationRequest> pendingNotificationRequests =
    await _flutterLocalNotificationsPlugin.pendingNotificationRequests();

    print("📋 --- DANH SÁCH THÔNG BÁO ĐANG CHỜ ---");
    print("🔢 Tổng số lượng: ${pendingNotificationRequests.length}");

    if (pendingNotificationRequests.isEmpty) {
      print("❌ Rỗng! Android đã từ chối/hủy lệnh đặt lịch của bạn.");
    } else {
      for (var p in pendingNotificationRequests) {
        print("   ✅ Chờ: ID=${p.id}, Title='${p.title}', Payload=${p.payload}");
      }
      print("👉 Nếu danh sách có mà không hiện -> Do điện thoại chặn hiển thị.");
    }
    print("-----------------------------------------");
  }
}