import 'package:equatable/equatable.dart';

// Enum trạng thái (Giống ProgressStatus)
enum ReportStatus { initial, loading, success, error }

class ReportState extends Equatable {
  final ReportStatus status;
  final String? errorMessage;

  const ReportState({
    required this.status,
    this.errorMessage,
  });

  // Trạng thái ban đầu
  factory ReportState.initial() => const ReportState(
    status: ReportStatus.initial,
    errorMessage: null,
  );

  // Hàm copyWith
  ReportState copyWith({
    ReportStatus? status,
    String? errorMessage,
  }) {
    return ReportState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}