import 'package:equatable/equatable.dart';

abstract class TeacherAnalyticsEvent extends Equatable {
  const TeacherAnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class TeacherAnalyticsLoadRequested extends TeacherAnalyticsEvent {
  const TeacherAnalyticsLoadRequested({this.period = 14});

  final int period;

  @override
  List<Object?> get props => [period];
}

class TeacherAnalyticsPeriodChanged extends TeacherAnalyticsEvent {
  const TeacherAnalyticsPeriodChanged(this.period);

  final int period;

  @override
  List<Object?> get props => [period];
}
