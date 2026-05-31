enum TeacherExamsListStatusFilter { all, draft, published, archived }

List<dynamic> teacherExamsListFiltered(List<dynamic> exams, TeacherExamsListStatusFilter filter) {
  if (filter == TeacherExamsListStatusFilter.all) return exams;
  final status = switch (filter) {
    TeacherExamsListStatusFilter.draft => 'draft',
    TeacherExamsListStatusFilter.published => 'published',
    TeacherExamsListStatusFilter.archived => 'archived',
    TeacherExamsListStatusFilter.all => '',
  };
  return exams.where((raw) {
    final m = raw as Map;
    return (m['status'] as String?) == status;
  }).toList();
}
