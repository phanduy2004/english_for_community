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

/// Nhận thông báo mới từ Socket (Real-time)
class NotificationIncomingReceived extends NotificationEvent {
  final NotificationEntity notification;
  const NotificationIncomingReceived(this.notification);

  @override
  List<Object?> get props => [notification];
}