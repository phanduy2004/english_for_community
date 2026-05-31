import 'package:equatable/equatable.dart';

abstract class TeacherIntegratedExamEditorEvent extends Equatable {
  const TeacherIntegratedExamEditorEvent();

  @override
  List<Object?> get props => [];
}

class TeacherIntegratedExamEditorLoadRequested extends TeacherIntegratedExamEditorEvent {
  const TeacherIntegratedExamEditorLoadRequested({required this.legacyUntitledLabel});

  final String legacyUntitledLabel;

  @override
  List<Object?> get props => [legacyUntitledLabel];
}

class TeacherIntegratedExamEditorTitleChanged extends TeacherIntegratedExamEditorEvent {
  const TeacherIntegratedExamEditorTitleChanged(this.title);

  final String title;

  @override
  List<Object?> get props => [title];
}

class TeacherIntegratedExamEditorSkillIncludedChanged extends TeacherIntegratedExamEditorEvent {
  const TeacherIntegratedExamEditorSkillIncludedChanged({required this.skill, required this.included});

  final String skill;
  final bool included;

  @override
  List<Object?> get props => [skill, included];
}

class TeacherIntegratedExamEditorSkillSectionUpdated extends TeacherIntegratedExamEditorEvent {
  const TeacherIntegratedExamEditorSkillSectionUpdated({required this.skill, required this.section});

  final String skill;
  final Map<String, dynamic> section;

  @override
  List<Object?> get props => [skill, section];
}

class TeacherIntegratedExamEditorSkillResourceAdded extends TeacherIntegratedExamEditorEvent {
  const TeacherIntegratedExamEditorSkillResourceAdded({
    required this.skill,
    required this.resourceId,
    required this.resourceTitle,
    this.listeningSubType,
  });

  final String skill;
  final String resourceId;
  final String resourceTitle;

  /// Only relevant when skill == 'listening'. Either 'dictation' or 'comprehension'.
  final String? listeningSubType;

  @override
  List<Object?> get props => [skill, resourceId, resourceTitle, listeningSubType];
}

class TeacherIntegratedExamEditorGrammarIncludedChanged extends TeacherIntegratedExamEditorEvent {
  const TeacherIntegratedExamEditorGrammarIncludedChanged(this.included);

  final bool included;

  @override
  List<Object?> get props => [included];
}

class TeacherIntegratedExamEditorGrammarItemsUpdated extends TeacherIntegratedExamEditorEvent {
  const TeacherIntegratedExamEditorGrammarItemsUpdated(this.items);

  final List<Map<String, dynamic>> items;

  @override
  List<Object?> get props => [items];
}

class TeacherIntegratedExamEditorGrammarEditorIndexChanged extends TeacherIntegratedExamEditorEvent {
  const TeacherIntegratedExamEditorGrammarEditorIndexChanged(this.index);

  /// `null` = closed, `-1` = new, `>= 0` = edit index.
  final int? index;

  @override
  List<Object?> get props => [index];
}

class TeacherIntegratedExamEditorGrammarSaved extends TeacherIntegratedExamEditorEvent {
  const TeacherIntegratedExamEditorGrammarSaved(this.item);

  final Map<String, dynamic> item;

  @override
  List<Object?> get props => [item];
}

class TeacherIntegratedExamEditorRemoveResource extends TeacherIntegratedExamEditorEvent {
  const TeacherIntegratedExamEditorRemoveResource({
    required this.skill,
    required this.index,
    this.listeningSubType,
  });

  final String skill;
  final int index;

  /// Only relevant when skill == 'listening'. Either 'dictation' or 'comprehension'.
  final String? listeningSubType;

  @override
  List<Object?> get props => [skill, index, listeningSubType];
}

class TeacherIntegratedExamEditorWritingFixedPromptChanged extends TeacherIntegratedExamEditorEvent {
  const TeacherIntegratedExamEditorWritingFixedPromptChanged(this.prompt);

  final Map<String, dynamic>? prompt;

  @override
  List<Object?> get props => [prompt];
}

class TeacherIntegratedExamEditorWritingGenerateRequested extends TeacherIntegratedExamEditorEvent {
  const TeacherIntegratedExamEditorWritingGenerateRequested({
    this.topicId,
    this.topicName,
    this.taskType,
  });

  final String? topicId;
  final String? topicName;
  final String? taskType;

  @override
  List<Object?> get props => [topicId, topicName, taskType];
}

class TeacherIntegratedExamEditorWritingPromptOptionsDismissed extends TeacherIntegratedExamEditorEvent {
  const TeacherIntegratedExamEditorWritingPromptOptionsDismissed();
}

class TeacherIntegratedExamEditorSaveDraftRequested extends TeacherIntegratedExamEditorEvent {
  const TeacherIntegratedExamEditorSaveDraftRequested();
}

class TeacherIntegratedExamEditorPublishRequested extends TeacherIntegratedExamEditorEvent {
  const TeacherIntegratedExamEditorPublishRequested();
}

class TeacherIntegratedExamEditorGrammarImportAppended extends TeacherIntegratedExamEditorEvent {
  const TeacherIntegratedExamEditorGrammarImportAppended(this.items);

  final List<Map<String, dynamic>> items;

  @override
  List<Object?> get props => [items];
}
