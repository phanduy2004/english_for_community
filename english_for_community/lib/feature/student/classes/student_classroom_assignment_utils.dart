/// Client-side assignment grouping for student classroom detail.
enum StudentClassAssignmentSegment { open, submitted, graded, closed }

enum StudentClassAssignmentSort { priority, dueDate }

class StudentClassAssignmentUtils {
  StudentClassAssignmentUtils._();

  static bool isResultsReleased(Map<String, dynamic> m) {
    final attempt = m['myAttempt'];
    if (attempt is Map && attempt['resultsReleased'] == true) return true;
    return false;
  }

  static StudentClassAssignmentSegment segmentOf(Map<String, dynamic> m) {
    final hint = m['studentStatusHint'] as String? ?? '';
    final attempt = m['myAttempt'];
    final attStatus = attempt is Map ? attempt['status'] as String? : null;

    if (attStatus == 'submitted' || hint == 'already_submitted') {
      if (isResultsReleased(m)) return StudentClassAssignmentSegment.graded;
      return StudentClassAssignmentSegment.submitted;
    }
    if (hint == 'session_ended' || hint == 'closed' || hint == 'past_due') {
      return StudentClassAssignmentSegment.closed;
    }
    return StudentClassAssignmentSegment.open;
  }

  static List<Map<String, dynamic>> filter(
    List<dynamic> assignments,
    StudentClassAssignmentSegment segment,
  ) {
    return assignments
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((m) => segmentOf(m) == segment)
        .toList();
  }

  static List<Map<String, dynamic>> filterAndSort(
    List<dynamic> assignments,
    StudentClassAssignmentSegment segment,
    StudentClassAssignmentSort sort,
  ) {
    final list = filter(assignments, segment);
    list.sort((a, b) => _compare(a, b, sort));
    return list;
  }

  static int _compare(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
    StudentClassAssignmentSort sort,
  ) {
    if (sort == StudentClassAssignmentSort.priority) {
      final aLive = isLiveOrLobby(a) ? 0 : 1;
      final bLive = isLiveOrLobby(b) ? 0 : 1;
      if (aLive != bLive) return aLive.compareTo(bLive);
      final aAttention = needsAttention(a) ? 0 : 1;
      final bAttention = needsAttention(b) ? 0 : 1;
      if (aAttention != bAttention) return aAttention.compareTo(bAttention);
    }
    final aDue = _dueMillis(a);
    final bDue = _dueMillis(b);
    if (aDue != null && bDue != null) return aDue.compareTo(bDue);
    if (aDue != null) return -1;
    if (bDue != null) return 1;
    return 0;
  }

  static int? _dueMillis(Map<String, dynamic> m) {
    final schedule = m['schedule'];
    if (schedule is! Map) return null;
    for (final key in ['dueAt', 'closesAt', 'endsAt']) {
      final raw = schedule[key];
      if (raw == null) continue;
      final dt = DateTime.tryParse(raw.toString());
      if (dt != null) return dt.millisecondsSinceEpoch;
    }
    return null;
  }

  static bool needsAttention(Map<String, dynamic> m) {
    final hint = m['studentStatusHint'] as String? ?? '';
    if (m['studentCanStart'] == true) return true;
    return hint == 'resume' || hint == 'live' || hint == 'lobby';
  }

  static bool isLiveOrLobby(Map<String, dynamic> m) {
    final hint = m['studentStatusHint'] as String? ?? '';
    return hint == 'live' || hint == 'lobby';
  }

  static List<Map<String, dynamic>> liveOrLobby(List<dynamic> assignments) {
    return assignments
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where(isLiveOrLobby)
        .toList();
  }

  static List<Map<String, dynamic>> overviewRecent(List<dynamic> assignments) {
    final all = assignments.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];

    void add(Map<String, dynamic> m) {
      final id = m['id'] as String? ?? '';
      if (id.isEmpty || seen.contains(id)) return;
      seen.add(id);
      result.add(m);
    }

    for (final m in all.where(needsAttention)) {
      add(m);
      if (result.length >= 3) return result;
    }
    for (final m in all) {
      if (segmentOf(m) != StudentClassAssignmentSegment.open) continue;
      add(m);
      if (result.length >= 3) return result;
    }
    return result;
  }

  static bool allowStudentInvite(Map<String, dynamic> classroom) {
    final settings = classroom['settings'];
    if (settings is Map) return settings['allowStudentInvite'] == true;
    return false;
  }
}
