import 'package:equatable/equatable.dart';

enum TeacherExamEditorStatus { initial, loading, success, error }

class TeacherExamEditorState extends Equatable {
  const TeacherExamEditorState({
    required this.status,
    this.errorMessage,
    this.examStatus = 'draft',
    this.title = '',
    this.description = '',
    this.showResultsPolicy = 'after_submit',
    this.items = const [],
    this.saving = false,
    this.successMessage,
  });

  final TeacherExamEditorStatus status;
  final String? errorMessage;
  final String? successMessage;
  final String examStatus;
  final String title;
  final String description;
  final String showResultsPolicy;
  final List<Map<String, dynamic>> items;
  final bool saving;

  bool get isDraft => examStatus == 'draft';

  factory TeacherExamEditorState.initial() =>
      const TeacherExamEditorState(status: TeacherExamEditorStatus.initial);

  TeacherExamEditorState copyWith({
    TeacherExamEditorStatus? status,
    String? errorMessage,
    String? examStatus,
    String? title,
    String? description,
    String? showResultsPolicy,
    List<Map<String, dynamic>>? items,
    bool? saving,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return TeacherExamEditorState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      examStatus: examStatus ?? this.examStatus,
      title: title ?? this.title,
      description: description ?? this.description,
      showResultsPolicy: showResultsPolicy ?? this.showResultsPolicy,
      items: items ?? this.items,
      saving: saving ?? this.saving,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        successMessage,
        examStatus,
        title,
        description,
        showResultsPolicy,
        items,
        saving,
      ];
}
