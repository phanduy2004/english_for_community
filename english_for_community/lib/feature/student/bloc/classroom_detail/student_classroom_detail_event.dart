import 'package:equatable/equatable.dart';

abstract class StudentClassroomDetailEvent extends Equatable {
  const StudentClassroomDetailEvent();

  @override
  List<Object?> get props => [];
}

class StudentClassroomDetailLoadRequested extends StudentClassroomDetailEvent {
  const StudentClassroomDetailLoadRequested();
}
