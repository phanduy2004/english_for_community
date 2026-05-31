import 'package:english_for_community/feature/teacher/bloc/integrated_exam_editor/teacher_integrated_exam_editor_payload.dart';
import 'package:equatable/equatable.dart';

enum TeacherIntegratedExamEditorStatus { initial, loading, success, error }

class TeacherIntegratedExamEditorState extends Equatable {
  const TeacherIntegratedExamEditorState({
    required this.status,
    this.errorMessage,
    this.examStatus = 'draft',
    this.title = '',
    this.skillIncluded = const {},
    this.skillSection = const {},
    this.grammarItems = const [],
    this.grammarIncluded = false,
    this.grammarEditorIndex,
    this.writingPromptGenerating = false,
    this.saving = false,
    this.successMessage,
    this.publishFailure,
    this.writingPromptOptions,
    this.legacyUntitledLabel = '',
  });

  final TeacherIntegratedExamEditorStatus status;
  final String? errorMessage;
  final String examStatus;
  final String title;
  final Map<String, bool> skillIncluded;
  final Map<String, Map<String, dynamic>> skillSection;
  final List<Map<String, dynamic>> grammarItems;
  final bool grammarIncluded;
  final int? grammarEditorIndex;
  final bool writingPromptGenerating;
  final bool saving;
  final String? successMessage;
  final TeacherIntegratedExamEditorPublishFailure? publishFailure;
  final List<Map<String, dynamic>>? writingPromptOptions;
  final String legacyUntitledLabel;

  bool get isDraft => examStatus == 'draft';
  bool get canEditSkillContent => examStatus == 'draft' || examStatus == 'published';

  factory TeacherIntegratedExamEditorState.initial() =>
      const TeacherIntegratedExamEditorState(status: TeacherIntegratedExamEditorStatus.initial);

  TeacherIntegratedExamEditorState copyWith({
    TeacherIntegratedExamEditorStatus? status,
    String? errorMessage,
    String? examStatus,
    String? title,
    Map<String, bool>? skillIncluded,
    Map<String, Map<String, dynamic>>? skillSection,
    List<Map<String, dynamic>>? grammarItems,
    bool? grammarIncluded,
    int? grammarEditorIndex,
    bool? writingPromptGenerating,
    bool? saving,
    String? successMessage,
    TeacherIntegratedExamEditorPublishFailure? publishFailure,
    List<Map<String, dynamic>>? writingPromptOptions,
    String? legacyUntitledLabel,
    bool clearError = false,
    bool clearGrammarEditorIndex = false,
    bool clearSuccess = false,
    bool clearPublishFailure = false,
    bool clearWritingPromptOptions = false,
  }) {
    return TeacherIntegratedExamEditorState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      examStatus: examStatus ?? this.examStatus,
      title: title ?? this.title,
      skillIncluded: skillIncluded ?? this.skillIncluded,
      skillSection: skillSection ?? this.skillSection,
      grammarItems: grammarItems ?? this.grammarItems,
      grammarIncluded: grammarIncluded ?? this.grammarIncluded,
      grammarEditorIndex:
          clearGrammarEditorIndex ? null : (grammarEditorIndex ?? this.grammarEditorIndex),
      writingPromptGenerating: writingPromptGenerating ?? this.writingPromptGenerating,
      saving: saving ?? this.saving,
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      publishFailure: clearPublishFailure ? null : (publishFailure ?? this.publishFailure),
      writingPromptOptions:
          clearWritingPromptOptions ? null : (writingPromptOptions ?? this.writingPromptOptions),
      legacyUntitledLabel: legacyUntitledLabel ?? this.legacyUntitledLabel,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        examStatus,
        title,
        skillIncluded,
        skillSection,
        grammarItems,
        grammarIncluded,
        grammarEditorIndex,
        writingPromptGenerating,
        saving,
        successMessage,
        publishFailure,
        writingPromptOptions,
        legacyUntitledLabel,
      ];
}
