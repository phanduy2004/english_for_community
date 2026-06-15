/// Helpers for teacher assignment lists (dashboard + classroom), aligned with API `teacherListSegment`.
class TeacherAssignmentListUtils {
  TeacherAssignmentListUtils._();

  static String? teacherListSegment(Map<String, dynamic> m) =>
      m['teacherListSegment'] as String?;

  static bool isHistory(Map<String, dynamic> m) => teacherListSegment(m) == 'history';

  static bool isActiveListItem(Map<String, dynamic> m) => !isHistory(m);

  static String? activeSessionStatus(Map<String, dynamic> m) {
    final session = m['activeSession'];
    if (session is Map) return session['status'] as String?;
    return null;
  }

  /// Realtime assignment with lobby or live session — shown in dashboard live strip.
  static bool hasOngoingLiveSession(Map<String, dynamic> m) {
    if ((m['mode'] as String?) != 'realtime') return false;
    final st = activeSessionStatus(m);
    return st == 'lobby' || st == 'live';
  }

  static String? classroomNameFromAssignment(Map<String, dynamic> m) {
    final c = m['classroomId'];
    if (c is Map) return (c['name'] as String?)?.trim();
    final direct = m['classroomName'] as String?;
    if (direct != null && direct.trim().isNotEmpty) return direct.trim();
    return null;
  }

  static String? classroomIdFromAssignment(Map<String, dynamic> m) {
    final c = m['classroomId'];
    if (c is Map) return (c['id'] ?? c['_id'])?.toString();
    final id = c?.toString();
    if (id != null && id.isNotEmpty) return id;
    return null;
  }

  static bool matchesClassroomFilter(Map<String, dynamic> m, String? classroomId) {
    if (classroomId == null || classroomId.isEmpty) return true;
    return classroomIdFromAssignment(m) == classroomId;
  }
}
