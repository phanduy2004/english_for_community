import 'package:english_for_community/l10n/generated/app_localizations.dart';

import 'teacher_integrated_exam_editor_page.dart';

/// Shared JSON body for `TeacherExamRepository.createExamDraft` — skills / integrated template.
Map<String, dynamic> buildTeacherSkillsExamDraftPayload(AppLocalizations l10n) {
  final sections = <Map<String, dynamic>>[];
  for (var i = 0; i < TeacherIntegratedExamEditorPage.skillOrder.length; i++) {
    final skill = TeacherIntegratedExamEditorPage.skillOrder[i];
    sections.add({
      'sectionId': TeacherIntegratedExamEditorPage.sectionIdsForSkill[skill]!,
      'sectionKind': 'skill_content',
      'skill': skill,
      'order': i,
      'title': '',
      'instructions': '',
      'resourceId': '',
      'resourceTitle': '',
      'items': <dynamic>[],
    });
  }
  return {
    'title': '',
    'description': '',
    'settings': {
      'examFormat': 'skills_exam',
      'showResultsPolicy': 'after_submit',
      'allowMultipleSubmissions': false,
      'grammarItems': <dynamic>[],
    },
    'sections': sections,
  };
}
