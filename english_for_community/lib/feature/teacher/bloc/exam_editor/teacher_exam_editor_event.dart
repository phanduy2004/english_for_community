import 'package:equatable/equatable.dart';

abstract class TeacherExamEditorEvent extends Equatable {
  const TeacherExamEditorEvent();

  @override
  List<Object?> get props => [];
}

class TeacherExamEditorLoadRequested extends TeacherExamEditorEvent {
  const TeacherExamEditorLoadRequested();
}

class TeacherExamEditorTitleChanged extends TeacherExamEditorEvent {
  const TeacherExamEditorTitleChanged(this.title);
  final String title;
  @override
  List<Object?> get props => [title];
}

class TeacherExamEditorDescriptionChanged extends TeacherExamEditorEvent {
  const TeacherExamEditorDescriptionChanged(this.description);
  final String description;
  @override
  List<Object?> get props => [description];
}

class TeacherExamEditorResultsPolicyChanged extends TeacherExamEditorEvent {
  const TeacherExamEditorResultsPolicyChanged(this.policy);
  final String policy;
  @override
  List<Object?> get props => [policy];
}

class TeacherExamEditorItemsChanged extends TeacherExamEditorEvent {
  const TeacherExamEditorItemsChanged(this.items);
  final List<Map<String, dynamic>> items;
  @override
  List<Object?> get props => [items];
}

class TeacherExamEditorSaveDraftRequested extends TeacherExamEditorEvent {
  const TeacherExamEditorSaveDraftRequested();
}

class TeacherExamEditorPublishRequested extends TeacherExamEditorEvent {
  const TeacherExamEditorPublishRequested();
}
