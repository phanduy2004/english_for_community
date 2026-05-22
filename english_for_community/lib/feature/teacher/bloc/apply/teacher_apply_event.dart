import 'package:equatable/equatable.dart';

abstract class TeacherApplyEvent extends Equatable {
  const TeacherApplyEvent();

  @override
  List<Object?> get props => [];
}

class TeacherApplyLoadRequested extends TeacherApplyEvent {
  const TeacherApplyLoadRequested();
}

class TeacherApplySubmitRequested extends TeacherApplyEvent {
  const TeacherApplySubmitRequested({
    required this.bio,
    required this.organization,
  });

  final String bio;
  final String organization;

  @override
  List<Object?> get props => [bio, organization];
}

class TeacherApplyWithdrawRequested extends TeacherApplyEvent {
  const TeacherApplyWithdrawRequested();
}
