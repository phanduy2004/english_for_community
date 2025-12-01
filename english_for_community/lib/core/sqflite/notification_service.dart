import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
// 🔽 ✍️ SỬA ĐỔI: Import thư viện mới
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService I = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Khởi tạo Timezone
    tz.initializeTimeZones();
    // 🔽 ✍️ SỬA ĐỔI: Sử dụng FlutterTimezone.getLocalTimezone()
    final String localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone));

    // 2. Cài đặt cho Android
    // 🔽 ✍️ SỬA LỖI Ở ĐÂY
    // Dùng icon laucher mặc định (@mipmap/ic_launcher) thay vì 'app_icon'
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. Cài đặt cho iOS
    final DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) {
        // Xử lý khi app đang mở trên iOS < 10
      },
    );

    // 4. Khởi tạo plugin
    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Xử lý khi người dùng nhấn vào thông báo
        // Ví dụ: điều hướng đến màn hình ôn tập
      },
    );
  }

  /// Lên lịch thông báo lặp lại vào 9:00 sáng hàng ngày
  Future<void> scheduleDaily9AMNotification() async {
    await _plugin.zonedSchedule(
      0, // ID của thông báo
      'Đến giờ học từ vựng!', // Title
      'Bạn có một số từ cần ôn tập hôm nay. Vào học ngay nào!', // Body
      _nextInstanceOf9AM(), // Lấy 9:00 sáng tiếp theo
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_notification_channel_id', // Channel ID
          'Daily Notifications', // Channel Name
          channelDescription: 'Kênh thông báo học từ vựng hàng ngày',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default.wav',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // LẶP LẠI HÀNG NGÀY
    );
  }

  /// Helper tính toán 9:00 sáng tiếp theo
  tz.TZDateTime _nextInstanceOf9AM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, 9); // 9:00

    // Nếu 9:00 sáng hôm nay đã qua, lên lịch cho ngày mai
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}