import 'package:dio/dio.dart';
import 'package:english_for_community/core/datasource/notification_remote_datasource.dart';
import 'package:english_for_community/core/entity/notification_entity.dart';
import 'package:english_for_community/core/model/either.dart';
import 'package:english_for_community/core/model/failure.dart';
import 'package:english_for_community/core/repository/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource dataSource;

  NotificationRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, Map<String, dynamic>>> getNotifications(int page) async {
    try {
      final res = await dataSource.getNotifications(page);

      // Parse dữ liệu từ API response
      final List data = res['data'];
      final items = data.map((e) => NotificationEntity.fromJson(e)).toList();
      final int unreadCount = res['unreadCount'] ?? 0;
      final bool hasMore = res['pagination']['hasMore'] ?? false;

      // Trả về map kết quả để Bloc xử lý
      return Right({
        'items': items,
        'unreadCount': unreadCount,
        'hasMore': hasMore,
      });
    } on DioException catch (e) {
      // Sử dụng ServerFailure hoặc class Failure tương ứng trong project của bạn
      return Left(ServerFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String id) async {
    try {
      await dataSource.markAsRead(id);
      return  Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    try {
      await dataSource.markAllAsRead();
      return  Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

