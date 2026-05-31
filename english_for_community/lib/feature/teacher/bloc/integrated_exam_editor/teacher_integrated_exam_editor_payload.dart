import 'package:english_for_community/feature/teacher/bloc/integrated_exam_editor/teacher_integrated_exam_editor_constants.dart';

/// Publish validation failure kinds (map to l10n in the UI layer).
enum TeacherIntegratedExamEditorPublishFailure {
  writingNeedPrompt,
  speakingRequired,
  skillResourceRequired,
  grammarEnabledNoItems,
  needSelection,
  grammarPointsCap100,
}

Map<String, bool> teacherIntegratedExamEditorDefaultSkillIncluded() {
  final map = <String, bool>{};
  for (final sk in teacherIntegratedExamSkillOrder) {
    map[sk] = true;
  }
  return map;
}

Map<String, Map<String, dynamic>> teacherIntegratedExamEditorDefaultSkillSections() {
  final map = <String, Map<String, dynamic>>{};
  for (var i = 0; i < teacherIntegratedExamSkillOrder.length; i++) {
    final sk = teacherIntegratedExamSkillOrder[i];
    map[sk] = teacherIntegratedExamEditorEmptySkillSection(sk, i);
  }
  return map;
}

Map<String, dynamic> teacherIntegratedExamEditorEmptySkillSection(String skill, int order) {
  return {
    'sectionId': teacherIntegratedExamSectionIdsForSkill[skill]!,
    'sectionKind': 'skill_content',
    'skill': skill,
    'order': order,
    'title': '',
    'instructions': '',
    'resources': <Map<String, dynamic>>[],
    'items': <dynamic>[],
  };
}

/// Dictation resources (stored in the standard 'resources' key).
List<Map<String, dynamic>> teacherIntegratedExamEditorGetResources(Map<String, dynamic> sec) {
  final raw = sec['resources'];
  if (raw is List) {
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  final id = (sec['resourceId'] as String?)?.trim() ?? '';
  final title = (sec['resourceTitle'] as String?)?.trim() ?? '';
  if (id.isNotEmpty) return [{'id': id, 'title': title}];
  return [];
}

/// Comprehension resources (stored in 'compResources' key within the listening section).
List<Map<String, dynamic>> teacherIntegratedExamEditorGetCompResources(Map<String, dynamic> sec) {
  final raw = sec['compResources'];
  if (raw is List) {
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return [];
}

Map<String, dynamic>? teacherIntegratedExamEditorGetWritingFixedPrompt(
  Map<String, Map<String, dynamic>> skillSection,
) {
  final sec = skillSection['writing'];
  if (sec == null) return null;
  final raw = sec['fixedWritingPrompt'];
  if (raw is Map && (raw['text'] as String?)?.isNotEmpty == true) {
    return Map<String, dynamic>.from(raw);
  }
  return null;
}

bool teacherIntegratedExamEditorWritingSkillReady(Map<String, Map<String, dynamic>> skillSection) =>
    teacherIntegratedExamEditorGetWritingFixedPrompt(skillSection) != null;

bool teacherIntegratedExamEditorSkillMeetsPublishRequirement({
  required String skill,
  required bool included,
  required Map<String, Map<String, dynamic>> skillSection,
}) {
  if (!included) return true;
  if (skill == 'writing') return teacherIntegratedExamEditorWritingSkillReady(skillSection);
  if (skill == 'listening') {
    final sec = skillSection['listening'] ?? {};
    final dictRes = teacherIntegratedExamEditorGetResources(sec);
    final compRes = teacherIntegratedExamEditorGetCompResources(sec);
    return dictRes.isNotEmpty || compRes.isNotEmpty;
  }
  return teacherIntegratedExamEditorGetResources(skillSection[skill] ?? {}).isNotEmpty;
}

List<Map<String, dynamic>> teacherIntegratedExamEditorBuildSectionsForSave({
  required Map<String, bool> skillIncluded,
  required Map<String, Map<String, dynamic>> skillSection,
}) {
  var order = 0;
  final out = <Map<String, dynamic>>[];
  for (final sk in teacherIntegratedExamSkillOrder) {
    if (skillIncluded[sk] != true) continue;

    if (sk == 'listening') {
      final base = Map<String, dynamic>.from(
        skillSection['listening'] ?? teacherIntegratedExamEditorEmptySkillSection('listening', order),
      );
      // Remove internal keys before saving
      base.remove('compResources');

      final dictRes = teacherIntegratedExamEditorGetResources(base);
      final compRes = teacherIntegratedExamEditorGetCompResources(
        skillSection['listening'] ?? {},
      );

      if (dictRes.isNotEmpty) {
        final dictSection = Map<String, dynamic>.from(base)
          ..['resources'] = dictRes
          ..['resourceId'] = dictRes.first['id']?.toString() ?? ''
          ..['resourceTitle'] = dictRes.first['title']?.toString() ?? ''
          ..['sectionId'] = teacherIntegratedExamSectionIdsForSkill['listening']!
          ..['sectionConfig'] = {'listeningType': 'dictation'}
          ..['order'] = order;
        out.add(dictSection);
        order++;
      }

      if (compRes.isNotEmpty) {
        final compSection = <String, dynamic>{
          'sectionId': teacherIntegratedExamListeningCompSectionId,
          'sectionKind': 'skill_content',
          'skill': 'listening',
          'order': order,
          'title': base['title'] ?? '',
          'instructions': base['instructions'] ?? '',
          'resources': compRes,
          'resourceId': compRes.first['id']?.toString() ?? '',
          'resourceTitle': compRes.first['title']?.toString() ?? '',
          'items': <dynamic>[],
          'sectionConfig': {'listeningType': 'comprehension'},
        };
        out.add(compSection);
        order++;
      }

      // If nothing added (no resources), still add an empty placeholder for the section
      if (dictRes.isEmpty && compRes.isEmpty) {
        base
          ..['resources'] = <Map<String, dynamic>>[]
          ..['order'] = order;
        base.remove('resourceId');
        base.remove('resourceTitle');
        out.add(base);
        order++;
      }
      continue;
    }

    final base = Map<String, dynamic>.from(
      skillSection[sk] ?? teacherIntegratedExamEditorEmptySkillSection(sk, order),
    );
    final resources = teacherIntegratedExamEditorGetResources(base);
    if (resources.isNotEmpty) {
      base['resources'] = resources;
      base['resourceId'] = resources.first['id']?.toString() ?? '';
      base['resourceTitle'] = resources.first['title']?.toString() ?? '';
    } else if (sk != 'writing') {
      base.remove('resourceId');
      base.remove('resourceTitle');
      base['resources'] = <Map<String, dynamic>>[];
    }
    if (sk == 'writing') {
      final prompt = teacherIntegratedExamEditorGetWritingFixedPrompt(skillSection);
      if (prompt != null) {
        base['fixedWritingPrompt'] = prompt;
      } else {
        base.remove('fixedWritingPrompt');
      }
    }
    base['order'] = order;
    out.add(base);
    order++;
  }
  return out;
}

/// Merges a section loaded from the backend into `skillSection['listening']`.
/// Dictation sections populate `resources`; comprehension populates `compResources`.
void teacherIntegratedExamEditorMergeListeningSection(
  Map<String, Map<String, dynamic>> skillSection,
  Map<String, dynamic> sec,
) {
  final listeningType =
      (sec['sectionConfig'] as Map?)?['listeningType'] as String? ?? 'dictation';
  final resources = List<Map<String, dynamic>>.from(
    (sec['resources'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
  );

  if (!skillSection.containsKey('listening')) {
    skillSection['listening'] = teacherIntegratedExamEditorEmptySkillSection('listening', 0);
  }
  final existing = Map<String, dynamic>.from(skillSection['listening']!);

  if (listeningType == 'comprehension') {
    existing['compResources'] = resources;
  } else {
    // Base section structure comes from the first dictation section.
    final merged = Map<String, dynamic>.from(sec)
      ..['resources'] = resources
      ..['compResources'] = existing['compResources'] ?? <Map<String, dynamic>>[];
    skillSection['listening'] = merged;
    return;
  }
  skillSection['listening'] = existing;
}

Map<String, dynamic> teacherIntegratedExamEditorSettingsForSave({
  required bool grammarIncluded,
  required List<Map<String, dynamic>> grammarItems,
}) {
  return {
    'examFormat': 'skills_exam',
    'showResultsPolicy': 'after_submit',
    'allowMultipleSubmissions': false,
    'grammarEnabled': grammarIncluded,
    'grammarItems': grammarIncluded ? grammarItems : <Map<String, dynamic>>[],
  };
}

TeacherIntegratedExamEditorPublishFailure? teacherIntegratedExamEditorValidatePublish({
  required Map<String, bool> skillIncluded,
  required Map<String, Map<String, dynamic>> skillSection,
  required bool grammarIncluded,
  required List<Map<String, dynamic>> grammarItems,
}) {
  var anySkill = false;
  for (final sk in teacherIntegratedExamSkillOrder) {
    if (skillIncluded[sk] != true) continue;
    if (!teacherIntegratedExamEditorSkillMeetsPublishRequirement(
      skill: sk,
      included: true,
      skillSection: skillSection,
    )) {
      if (sk == 'writing') return TeacherIntegratedExamEditorPublishFailure.writingNeedPrompt;
      if (sk == 'speaking') return TeacherIntegratedExamEditorPublishFailure.speakingRequired;
      return TeacherIntegratedExamEditorPublishFailure.skillResourceRequired;
    }
    anySkill = true;
  }
  if (grammarIncluded && grammarItems.isEmpty) {
    return TeacherIntegratedExamEditorPublishFailure.grammarEnabledNoItems;
  }
  final anyGrammar = grammarIncluded && grammarItems.isNotEmpty;
  if (!anySkill && !anyGrammar) {
    return TeacherIntegratedExamEditorPublishFailure.needSelection;
  }
  if (anyGrammar) {
    var sum = 0;
    for (final it in grammarItems) {
      sum += int.tryParse('${it['points'] ?? 1}') ?? 1;
    }
    if (anySkill && sum > 100) {
      return TeacherIntegratedExamEditorPublishFailure.grammarPointsCap100;
    }
  }
  return null;
}

Map<String, dynamic> teacherIntegratedExamEditorDraftPayload({
  required String title,
  required Map<String, bool> skillIncluded,
  required Map<String, Map<String, dynamic>> skillSection,
  required bool grammarIncluded,
  required List<Map<String, dynamic>> grammarItems,
}) {
  return {
    'title': title.trim(),
    'description': '',
    'settings': teacherIntegratedExamEditorSettingsForSave(
      grammarIncluded: grammarIncluded,
      grammarItems: grammarItems,
    ),
    'sections': teacherIntegratedExamEditorBuildSectionsForSave(
      skillIncluded: skillIncluded,
      skillSection: skillSection,
    ),
  };
}
