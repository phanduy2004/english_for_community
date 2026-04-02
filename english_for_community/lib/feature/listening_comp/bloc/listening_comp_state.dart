import 'package:equatable/equatable.dart';
import '../../../../core/entity/listening_comp_entity.dart';

enum CompStatus { initial, loading, success, submitting, submitted, error }

class ListeningCompState extends Equatable {
  final CompStatus status;
  final ListeningCompEntity? data;
  final ListeningCompAttemptResult? attemptResult;
  final String? errorMessage;
  // Cờ để phân biệt: Load lại bài cũ (True) hay Vừa nộp bài xong (False)
  final bool isInitialLoadReview;

  const ListeningCompState({
    this.status = CompStatus.initial,
    this.data,
    this.attemptResult,
    this.errorMessage,
    this.isInitialLoadReview = false,
  });

  ListeningCompState copyWith({
    CompStatus? status,
    ListeningCompEntity? data,
    ListeningCompAttemptResult? attemptResult,
    String? errorMessage,
    bool? isInitialLoadReview,
  }) {
    return ListeningCompState(
      status: status ?? this.status,
      data: data ?? this.data,
      attemptResult: attemptResult ?? this.attemptResult,
      errorMessage: errorMessage ?? this.errorMessage,
      isInitialLoadReview: isInitialLoadReview ?? this.isInitialLoadReview,
    );
  }

  @override
  List<Object?> get props => [
    status,
    data,
    attemptResult,
    errorMessage,
    isInitialLoadReview,
  ];
}