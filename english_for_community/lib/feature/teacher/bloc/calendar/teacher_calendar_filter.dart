import 'package:english_for_community/l10n/generated/app_localizations.dart';

/// Calendar layout mode (segmented control).
enum TeacherCalendarViewMode {
  month,
  week,
  list,
}

/// Event kind filter for [TeacherCalendarBloc].
enum TeacherCalendarKindFilter {
  all,
  due,
  opens,
  closes,
  live,
}

class TeacherCalendarClassroomOption {
  const TeacherCalendarClassroomOption({required this.id, required this.name});

  final String id;
  final String name;
}

/// One assignment with one or more schedule milestones.
class TeacherCalendarAssignmentGroup {
  const TeacherCalendarAssignmentGroup({
    required this.assignmentId,
    required this.milestones,
  });

  final String assignmentId;
  final List<Map<String, dynamic>> milestones;

  Map<String, dynamic> get anchor => milestones.first;

  String examTitle(Map<String, dynamic> event) {
    final fromExam = (event['examTitle'] as String?)?.trim();
    if (fromExam != null && fromExam.isNotEmpty) return fromExam;
    return (event['title'] as String?) ?? '—';
  }
}

bool teacherCalendarMatchesKindFilter(Map<String, dynamic> event, TeacherCalendarKindFilter filter) {
  if (filter == TeacherCalendarKindFilter.all) return true;
  final kind = event['kind'] as String? ?? '';
  switch (filter) {
    case TeacherCalendarKindFilter.due:
      return kind == 'due';
    case TeacherCalendarKindFilter.opens:
      return kind == 'opens';
    case TeacherCalendarKindFilter.closes:
      return kind == 'closes';
    case TeacherCalendarKindFilter.live:
      return kind == 'live';
    case TeacherCalendarKindFilter.all:
      return true;
  }
}

bool teacherCalendarMatchesSearch(Map<String, dynamic> event, String query) {
  if (query.isEmpty) return true;
  final haystack = [
    event['examTitle'],
    event['title'],
    event['classroomName'],
  ].whereType<String>().join(' ').toLowerCase();
  return haystack.contains(query);
}

List<Map<String, dynamic>> teacherCalendarVisibleEvents(
  List<Map<String, dynamic>> events, {
  required TeacherCalendarKindFilter kindFilter,
  String? classroomId,
  required String searchQuery,
}) {
  var list = events;
  if (kindFilter != TeacherCalendarKindFilter.all) {
    list = list.where((e) => teacherCalendarMatchesKindFilter(e, kindFilter)).toList();
  }
  if (classroomId != null && classroomId.isNotEmpty) {
    list = list.where((e) => (e['classroomId'] as String? ?? '') == classroomId).toList();
  }
  final q = searchQuery.trim().toLowerCase();
  if (q.isNotEmpty) {
    list = list.where((e) => teacherCalendarMatchesSearch(e, q)).toList();
  }
  return list;
}

List<TeacherCalendarClassroomOption> teacherCalendarClassroomOptions(List<Map<String, dynamic>> events) {
  final map = <String, String>{};
  for (final e in events) {
    final id = e['classroomId'] as String? ?? '';
    final name = (e['classroomName'] as String?)?.trim() ?? '';
    if (id.isNotEmpty && name.isNotEmpty) map[id] = name;
  }
  final list = map.entries
      .map((e) => TeacherCalendarClassroomOption(id: e.key, name: e.value))
      .toList();
  list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return list;
}

List<TeacherCalendarAssignmentGroup> teacherCalendarGroupEvents(List<Map<String, dynamic>> events) {
  final byAid = <String, List<Map<String, dynamic>>>{};
  for (final e in events) {
    final aid = e['assignmentId'] as String? ?? '';
    if (aid.isEmpty) continue;
    byAid.putIfAbsent(aid, () => []).add(e);
  }

  final groups = byAid.entries.map((entry) {
    final sorted = [...entry.value]..sort((a, b) {
        final ta = teacherCalendarEventAt(a)?.millisecondsSinceEpoch ?? 0;
        final tb = teacherCalendarEventAt(b)?.millisecondsSinceEpoch ?? 0;
        return ta.compareTo(tb);
      });
    return TeacherCalendarAssignmentGroup(assignmentId: entry.key, milestones: sorted);
  }).toList();

  groups.sort((a, b) {
    final ta = teacherCalendarEventAt(a.milestones.first)?.millisecondsSinceEpoch ?? 0;
    final tb = teacherCalendarEventAt(b.milestones.first)?.millisecondsSinceEpoch ?? 0;
    return ta.compareTo(tb);
  });
  return groups;
}

DateTime? teacherCalendarEventAt(Map<String, dynamic> event) {
  return DateTime.tryParse(event['at'] as String? ?? '')?.toLocal();
}

List<Map<String, dynamic>> teacherCalendarEventsForDay(
  DateTime day,
  List<Map<String, dynamic>> events,
) {
  return events.where((e) {
    final at = teacherCalendarEventAt(e);
    if (at == null) return false;
    return at.year == day.year && at.month == day.month && at.day == day.day;
  }).toList()
    ..sort((a, b) {
      final ta = teacherCalendarEventAt(a)?.millisecondsSinceEpoch ?? 0;
      final tb = teacherCalendarEventAt(b)?.millisecondsSinceEpoch ?? 0;
      return ta.compareTo(tb);
    });
}

DateTime teacherCalendarDateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

DateTime teacherCalendarWeekStart(DateTime day) {
  final d = teacherCalendarDateOnly(day);
  return d.subtract(Duration(days: d.weekday - 1));
}

DateTime teacherCalendarWeekEnd(DateTime day) =>
    teacherCalendarWeekStart(day).add(const Duration(days: 6));

/// Primary milestone used for relative-time badge (soonest upcoming, else latest past).
Map<String, dynamic>? teacherCalendarPrimaryMilestone(List<Map<String, dynamic>> milestones) {
  if (milestones.isEmpty) return null;
  final now = DateTime.now();
  Map<String, dynamic>? upcoming;
  DateTime? upcomingAt;
  Map<String, dynamic>? latestPast;
  DateTime? latestPastAt;

  for (final m in milestones) {
    final at = teacherCalendarEventAt(m);
    if (at == null) continue;
    if (!at.isBefore(now)) {
      if (upcomingAt == null || at.isBefore(upcomingAt)) {
        upcoming = m;
        upcomingAt = at;
      }
    } else if (latestPastAt == null || at.isAfter(latestPastAt)) {
      latestPast = m;
      latestPastAt = at;
    }
  }
  return upcoming ?? latestPast ?? milestones.last;
}

String teacherCalendarRelativeTimeLabel(AppLocalizations l10n, DateTime at) {
  final now = DateTime.now();
  final diff = at.difference(now);

  if (diff.inSeconds >= -59 && diff.inSeconds <= 59) {
    return l10n.teacherCalendarRelativeNow;
  }

  if (diff.isNegative) {
    final past = now.difference(at);
    if (past.inDays >= 1) {
      return l10n.teacherCalendarRelativeOverdueDays(past.inDays);
    }
    if (past.inHours >= 1) {
      return l10n.teacherCalendarRelativeOverdueHours(past.inHours);
    }
    return l10n.teacherCalendarRelativeOverdueMinutes(past.inMinutes.clamp(1, 59));
  }

  if (diff.inDays >= 1) {
    return l10n.teacherCalendarRelativeInDays(diff.inDays);
  }
  if (diff.inHours >= 1) {
    return l10n.teacherCalendarRelativeInHours(diff.inHours);
  }
  return l10n.teacherCalendarRelativeInMinutes(diff.inMinutes.clamp(1, 59));
}
