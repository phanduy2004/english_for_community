import 'package:english_for_community/core/model/either.dart';
import 'package:english_for_community/core/model/failure.dart';

abstract class NotificationRepository {
  /// Lấy danh sách thông báo (Phân trang)
  /// Trả về Map chứa: items (List<NotificationEntity>), unreadCount (int), hasMore (bool)
  Future<Either<Failure, Map<String, dynamic>>> getNotifications(int page);
  Future<Either<Failure, Map<String, dynamic>>> respondToNotification(String id, String action);

  /// Đánh dấu 1 thông báo đã đọc
  Future<Either<Failure, void>> markAsRead(String id);

  /// Đánh dấu tất cả là đã đọc
  Future<Either<Failure, void>> markAllAsRead();
}