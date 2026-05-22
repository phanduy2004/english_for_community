import 'package:equatable/equatable.dart';

enum TeacherLiveMonitorFilter { all, inProgress, submitted, flagged }

abstract class TeacherLiveMonitorEvent extends Equatable {
  const TeacherLiveMonitorEvent();

  @override
  List<Object?> get props => [];
}

class TeacherLiveMonitorStarted extends TeacherLiveMonitorEvent {
  const TeacherLiveMonitorStarted({this.initialSnapshot});

  final Map<String, dynamic>? initialSnapshot;

  @override
  List<Object?> get props => [initialSnapshot];
}

class TeacherLiveMonitorProgressUpdated extends TeacherLiveMonitorEvent {
  const TeacherLiveMonitorProgressUpdated(this.payload);

  final Map<String, dynamic> payload;

  @override
  List<Object?> get props => [payload];
}

class TeacherLiveMonitorRefreshRequested extends TeacherLiveMonitorEvent {
  const TeacherLiveMonitorRefreshRequested();
}

class TeacherLiveMonitorFilterChanged extends TeacherLiveMonitorEvent {
  const TeacherLiveMonitorFilterChanged(this.filter);

  final TeacherLiveMonitorFilter filter;

  @override
  List<Object?> get props => [filter];
}

class TeacherLiveMonitorStopped extends TeacherLiveMonitorEvent {
  const TeacherLiveMonitorStopped();
}
