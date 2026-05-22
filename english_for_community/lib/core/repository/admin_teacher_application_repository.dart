import '../model/either.dart';
import '../model/failure.dart';

abstract class AdminTeacherApplicationRepository {
  Future<Either<Failure, Map<String, dynamic>>> list({String status, int page, int limit});
  Future<Either<Failure, Map<String, dynamic>>> approve(String applicationId);
  Future<Either<Failure, Map<String, dynamic>>> reject(String applicationId, String reason);
}
