import 'package:equatable/equatable.dart';

abstract class TeacherAnalyticsEvent extends Equatable {
  const TeacherAnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class TeacherAnalyticsLoadRequested extends TeacherAnalyticsEvent {
  const TeacherAnalyticsLoadRequested({this.period = 14, this.classroomId});

  final int period;

  /// null → giữ lớp đang chọn (hoặc chọn lớp đầu tiên nếu chưa có).
  final String? classroomId;

  @override
  List<Object?> get props => [period, classroomId];
}

class TeacherAnalyticsPeriodChanged extends TeacherAnalyticsEvent {
  const TeacherAnalyticsPeriodChanged(this.period);

  final int period;

  @override
  List<Object?> get props => [period];
}

/// Đổi lớp đang xem (analytics theo từng lớp).
class TeacherAnalyticsClassChanged extends TeacherAnalyticsEvent {
  const TeacherAnalyticsClassChanged(this.classroomId);

  final String classroomId;

  @override
  List<Object?> get props => [classroomId];
}
