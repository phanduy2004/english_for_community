import 'package:equatable/equatable.dart';
import 'package:english_for_community/core/entity/notification_entity.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Load danh sách lần đầu hoặc Refresh (kéo xuống để reload)
class NotificationLoadStarted extends NotificationEvent {
  final bool isRefresh;
  const NotificationLoadStarted({this.isRefresh = false});
}

/// Load thêm trang tiếp theo (khi cuộn xuống đáy)
class NotificationLoadMore extends NotificationEvent {}

/// Đánh dấu 1 tin là đã đọc
class NotificationMarkRead extends NotificationEvent {
  final String id;
  const NotificationMarkRead(this.id);

  @override
  List<Object?> get props => [id];
}

/// Đánh dấu tất cả là đã đọc
class NotificationMarkAllRead extends NotificationEvent {}

/// Chấp nhận / từ chối thông báo có hành động (lời mời GV phụ, duyệt vào lớp, …)
class NotificationRespondRequested extends NotificationEvent {
  final String notificationId;
  final String action;

  const NotificationRespondRequested({
    required this.notificationId,
    required this.action,
  });

  @override
  List<Object?> get props => [notificationId, action];
}

/// Cập nhật UI sau khi API respond thành công (gọi từ dialog).
class NotificationItemResolved extends NotificationEvent {
  final String notificationId;
  final String actionStatus;

  const NotificationItemResolved({
    required this.notificationId,
    required this.actionStatus,
  });

  @override
  List<Object?> get props => [notificationId, actionStatus];
}

/// Nhận thông báo mới từ Socket (Real-time)
class NotificationIncomingReceived extends NotificationEvent {
  final NotificationEntity notification;
  const NotificationIncomingReceived(this.notification);

  @override
  List<Object?> get props => [notification];
}