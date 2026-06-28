import 'package:english_for_community/feature/student/classes/student_classroom_assignment_utils.dart';
import 'package:equatable/equatable.dart';

abstract class StudentClassroomDetailEvent extends Equatable {
  const StudentClassroomDetailEvent();

  @override
  List<Object?> get props => [];
}

class StudentClassroomDetailLoadRequested extends StudentClassroomDetailEvent {
  const StudentClassroomDetailLoadRequested({this.silent = false});

  final bool silent;

  @override
  List<Object?> get props => [silent];
}

class StudentClassroomDetailSegmentChanged extends StudentClassroomDetailEvent {
  const StudentClassroomDetailSegmentChanged(this.segment);

  final StudentClassAssignmentSegment segment;

  @override
  List<Object?> get props => [segment];
}

class StudentClassroomDetailSortChanged extends StudentClassroomDetailEvent {
  const StudentClassroomDetailSortChanged(this.sort);

  final StudentClassAssignmentSort sort;

  @override
  List<Object?> get props => [sort];
}

class StudentClassroomDetailLeaveRequested extends StudentClassroomDetailEvent {
  const StudentClassroomDetailLeaveRequested();
}
