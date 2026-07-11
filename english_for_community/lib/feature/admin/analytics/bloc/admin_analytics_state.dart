import 'package:equatable/equatable.dart';

enum AdminAnalyticsStatus { initial, loading, success, error }

class AdminAnalyticsState extends Equatable {
  const AdminAnalyticsState({
    required this.status,
    this.errorMessage,
    this.data,
    this.range = 'week',
  });

  final AdminAnalyticsStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? data;
  final String range;

  factory AdminAnalyticsState.initial() =>
      const AdminAnalyticsState(status: AdminAnalyticsStatus.initial, range: 'week');

  AdminAnalyticsState copyWith({
    AdminAnalyticsStatus? status,
    String? errorMessage,
    Map<String, dynamic>? data,
    String? range,
    bool clearError = false,
  }) {
    return AdminAnalyticsState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      data: data ?? this.data,
      range: range ?? this.range,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, data, range];
}
