import 'package:equatable/equatable.dart';
// ✍️  entity kết quả
import 'package:english_for_community/core/entity/reading/reading_attempt_entity.dart';

enum AttemptStatus { initial, loading, success, error,review }

class ReadingAttemptState extends Equatable {
  final AttemptStatus status;
  final String? errorMessage;
  // ✍️ Lưu kết quả trả về từ server
  final ReadingAttemptEntity? attemptResult;

  const ReadingAttemptState({
    required this.status,
    this.errorMessage,
    this.attemptResult,
  });

  factory ReadingAttemptState.initial() =>
      const ReadingAttemptState(status: AttemptStatus.initial);

  ReadingAttemptState copyWith({
    AttemptStatus? status,
    String? errorMessage,
    ReadingAttemptEntity? attemptResult,
  }) {
    return ReadingAttemptState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      attemptResult: attemptResult ?? this.attemptResult,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, attemptResult];
}