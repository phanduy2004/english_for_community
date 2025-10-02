// lib/main.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/rendering.dart';
import 'package:recognize_face/utils/simple_settings.dart';

import 'screens/home_page.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SimpleSettings.load(); // 🔹 load cấu hình
  debugPaintBaselinesEnabled = false; // đảm bảo không bật

  try {
    cameras = await availableCameras();
    debugPrint("✅ Cameras loaded: ${cameras.length}");
    for (var cam in cameras) {
      debugPrint(
          "Camera: ${cam.name}, lens: ${cam.lensDirection}, sensorOrientation: ${cam.sensorOrientation}");
    }
  } catch (e) {
    debugPrint('Error loading cameras: $e');
  }

  /* final repo = FaceDatasetRepository();
  // Xoá file JSON local. Đặt recreateEmpty = true để tạo lại file rỗng ngay sau khi xoá.
  // Gợi ý: chỉ xoá khi chạy debug để tránh mất dữ liệu thật.
  if (kDebugMode) {
    await repo.deleteLocalJson(recreateEmpty: true);
  }
*/
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recognize Face',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
