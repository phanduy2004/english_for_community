import 'package:dio/dio.dart';
import '../datasource/admin_teacher_application_remote_datasource.dart';
import '../model/either.dart';
import '../model/failure.dart';
import '../repository/admin_teacher_application_repository.dart';

class AdminTeacherApplicationRepositoryImpl implements AdminTeacherApplicationRepository {
  AdminTeacherApplicationRepositoryImpl({required this.remote});

  final AdminTeacherApplicationRemoteDatasource remote;

  String _dioMsg(DioException e) {
    if (e.response?.data is Map && (e.response!.data as Map)['message'] != null) {
      return (e.response!.data as Map)['message'].toString();
    }
    return e.message ?? 'Request failed';
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> list({String status = 'pending', int page = 1, int limit = 20}) async {
    try {
      return Right(await remote.list(status: status, page: page, limit: limit));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> approve(String applicationId) async {
    try {
      return Right(await remote.approve(applicationId));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> reject(String applicationId, String reason) async {
    try {
      return Right(await remote.reject(applicationId, reason));
    } on DioException catch (e) {
      return Left(ServerFailure(message: _dioMsg(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
