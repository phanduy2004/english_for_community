import 'package:shared_preferences/shared_preferences.dart';

/// Local per-classroom preferences (mute notifications, etc.).
abstract final class StudentClassroomPrefs {
  static const _mutePrefix = 'classroom_mute_';

  static Future<bool> isMuted(String classroomId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_mutePrefix$classroomId') ?? false;
  }

  static Future<void> setMuted(String classroomId, bool muted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_mutePrefix$classroomId', muted);
  }
}
