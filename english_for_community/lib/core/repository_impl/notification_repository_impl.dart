import 'package:dio/dio.dart';
import 'package:english_for_community/core/datasource/notification_remote_datasource.dart';
import 'package:english_for_community/core/model/either.dart';
import 'package:english_for_community/core/model/failure.dart';
import 'package:english_for_community/core/repository/notification_repository.dart';
import 'package:english_for_community/core/utils/notification_json_parse.dart';
import 'package:flutter/foundation.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource dataSource;

  NotificationRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, Map<String, dynamic>>> getNotifications(int page) async {
    try {
      final res = await dataSource.getNotifications(page);
      final parsed = await compute(parseNotificationPage, res);

      return Right({
        'items': parsed.items,
        'unreadCount': parsed.unreadCount,
        'hasMore': parsed.hasMore,
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
  Future<Either<Failure, Map<String, dynamic>>> respondToNotification(
    String id,
    String action,
  ) async {
    try {
      final res = await dataSource.respond(id, action);
      return Right(res);
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

