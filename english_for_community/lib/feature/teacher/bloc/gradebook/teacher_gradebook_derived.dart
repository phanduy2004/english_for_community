import 'package:english_for_community/feature/teacher/teacher_gradebook_labels.dart';

enum TeacherGradebookSort { nameAsc, nameDesc, avgDesc, avgAsc }

List<Map<String, dynamic>> teacherGradebookParseList(dynamic raw) {
  return (raw as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
}

Map<String, dynamic>? teacherGradebookParseSummary(Map<String, dynamic> data) {
  return data['summary'] is Map ? Map<String, dynamic>.from(data['summary'] as Map) : null;
}

List<Map<String, dynamic>> teacherGradebookVisibleAssignments(
  List<Map<String, dynamic>> assignments,
  String? modeFilter,
) {
  if (modeFilter == null) return assignments;
  return assignments.where((a) => a['mode'] == modeFilter).toList();
}

List<Map<String, dynamic>> teacherGradebookFilteredRows({
  required List<Map<String, dynamic>> rows,
  required String query,
  required TeacherGradebookSort sort,
  required bool hideEmpty,
}) {
  var out = List<Map<String, dynamic>>.from(rows);

  if (query.trim().isNotEmpty) {
    final q = query.trim().toLowerCase();
    out = out.where((r) {
      final name = TeacherGradebookLabels.studentLabel(r).toLowerCase();
      final email = ((r['email'] as String?) ?? '').toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  if (hideEmpty) {
    out = out.where((r) => (r['submittedCount'] as num? ?? 0) > 0).toList();
  }

  out.sort((a, b) {
    switch (sort) {
      case TeacherGradebookSort.nameDesc:
        return TeacherGradebookLabels.studentLabel(b).compareTo(TeacherGradebookLabels.studentLabel(a));
      case TeacherGradebookSort.avgDesc:
        return ((b['rowAvgPercent'] as num?) ?? -1).compareTo((a['rowAvgPercent'] as num?) ?? -1);
      case TeacherGradebookSort.avgAsc:
        final ba = b['rowAvgPercent'] as num?;
        final aa = a['rowAvgPercent'] as num?;
        if (ba == null && aa == null) return 0;
        if (ba == null) return 1;
        if (aa == null) return -1;
        return aa.compareTo(ba);
      case TeacherGradebookSort.nameAsc:
        return TeacherGradebookLabels.studentLabel(a).compareTo(TeacherGradebookLabels.studentLabel(b));
    }
  });

  return out;
}
