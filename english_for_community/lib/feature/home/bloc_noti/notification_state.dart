import 'package:equatable/equatable.dart';
import 'package:english_for_community/core/entity/notification_entity.dart';

enum NotificationStatus { initial, loading, success, failure }

class NotificationState extends Equatable {
  final NotificationStatus status;
  final List<NotificationEntity> notifications;
  final int unreadCount;
  final bool hasReachedMax; // Đã load hết dữ liệu chưa
  final int page; // Trang hiện tại
  final String? errorMessage;

  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notifications = const [],
    this.unreadCount = 0,
    this.hasReachedMax = false,
    this.page = 1,
    this.errorMessage,
  });

  NotificationState copyWith({
    NotificationStatus? status,
    List<NotificationEntity>? notifications,
    int? unreadCount,
    bool? hasReachedMax,
    int? page,
    String? errorMessage,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      page: page ?? this.page,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    notifications,
    unreadCount,
    hasReachedMax,
    page,
    errorMessage,
  ];
}