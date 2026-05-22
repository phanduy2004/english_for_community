import 'package:equatable/equatable.dart';

enum StudentClassesHubStatus { initial, loading, success, error }

class StudentClassesHubState extends Equatable {
  const StudentClassesHubState({
    required this.status,
    this.errorMessage,
    this.classes = const [],
    this.joiningByCode = false,
    this.joiningByToken = false,
    this.joinSuccess = false,
  });

  final StudentClassesHubStatus status;
  final String? errorMessage;
  final List<dynamic> classes;
  final bool joiningByCode;
  final bool joiningByToken;
  final bool joinSuccess;

  factory StudentClassesHubState.initial() =>
      const StudentClassesHubState(status: StudentClassesHubStatus.initial);

  StudentClassesHubState copyWith({
    StudentClassesHubStatus? status,
    String? errorMessage,
    List<dynamic>? classes,
    bool? joiningByCode,
    bool? joiningByToken,
    bool? joinSuccess,
    bool clearError = false,
    bool clearJoinSuccess = false,
  }) {
    return StudentClassesHubState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      classes: classes ?? this.classes,
      joiningByCode: joiningByCode ?? this.joiningByCode,
      joiningByToken: joiningByToken ?? this.joiningByToken,
      joinSuccess: clearJoinSuccess ? false : (joinSuccess ?? this.joinSuccess),
    );
  }

  @override
  List<Object?> get props =>
      [status, errorMessage, classes, joiningByCode, joiningByToken, joinSuccess];
}
