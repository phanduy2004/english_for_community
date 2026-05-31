import 'package:equatable/equatable.dart';

enum TeacherStudentLiveScreenStatus { initial, loading, success, error }

class TeacherStudentLiveScreenState extends Equatable {
  const TeacherStudentLiveScreenState({
    required this.status,
    this.errorMessage,
    this.liveScreen,
  });

  final TeacherStudentLiveScreenStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? liveScreen;

  factory TeacherStudentLiveScreenState.initial() =>
      const TeacherStudentLiveScreenState(status: TeacherStudentLiveScreenStatus.initial);

  TeacherStudentLiveScreenState copyWith({
    TeacherStudentLiveScreenStatus? status,
    String? errorMessage,
    Map<String, dynamic>? liveScreen,
    bool clearError = false,
  }) {
    return TeacherStudentLiveScreenState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      liveScreen: liveScreen ?? this.liveScreen,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, liveScreen];
}
