import 'package:dio/dio.dart';
import '../../../core/model/either.dart';
import '../../../core/model/failure.dart';
import '../../../core/entity/report_entity.dart';
import '../datasource/report_remote_datasource.dart';
import '../repository/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDatasource reportRemoteDatasource;

  ReportRepositoryImpl({required this.reportRemoteDatasource});

  // Helper xử lý lỗi (Reuse)
  String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return "Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng.";
    }
    if (e.response != null && e.response!.data is Map) {
      final data = e.response!.data as Map;
      if (data.containsKey('message')) {
        return data['message'].toString();
      }
    }
    return e.message ?? "Lỗi không xác định";
  }

  @override
  Future<Either<Failure, void>> sendReport(ReportEntity report) async {
    try {
      await reportRemoteDatasource.createReport(report);
      return  Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(message: _handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}