import 'package:equatable/equatable.dart';

abstract class TeacherExamAttemptGradeEvent extends Equatable {
  const TeacherExamAttemptGradeEvent();

  @override
  List<Object?> get props => [];
}

class TeacherExamAttemptGradeLoadRequested extends TeacherExamAttemptGradeEvent {
  const TeacherExamAttemptGradeLoadRequested();
}

class TeacherExamAttemptGradeRunAiRequested extends TeacherExamAttemptGradeEvent {
  const TeacherExamAttemptGradeRunAiRequested();
}

class TeacherExamAttemptGradeSectionExpandedToggled extends TeacherExamAttemptGradeEvent {
  const TeacherExamAttemptGradeSectionExpandedToggled(this.sectionId);

  final String sectionId;

  @override
  List<Object?> get props => [sectionId];
}

class TeacherExamAttemptGradeSaveRequested extends TeacherExamAttemptGradeEvent {
  const TeacherExamAttemptGradeSaveRequested({
    required this.items,
    this.finalize = false,
  });

  final Map<String, dynamic> items;
  final bool finalize;

  @override
  List<Object?> get props => [items, finalize];
}

class TeacherExamAttemptGradeSaveSkillScoreRequested extends TeacherExamAttemptGradeEvent {
  const TeacherExamAttemptGradeSaveSkillScoreRequested({
    required this.sectionId,
    required this.score,
    required this.note,
  });

  final String sectionId;
  final double score;
  final String note;

  @override
  List<Object?> get props => [sectionId, score, note];
}
