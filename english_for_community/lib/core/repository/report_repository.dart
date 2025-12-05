import '../../../core/model/either.dart';
import '../../../core/model/failure.dart';
import '../../../core/entity/report_entity.dart';

abstract class ReportRepository {
  // User gửi
  Future<Either<Failure, void>> sendReport(ReportEntity report);

}