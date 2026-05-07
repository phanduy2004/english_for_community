import 'package:english_for_community/core/entity/admin/app_release_admin_entity.dart';
import 'package:english_for_community/core/model/either.dart';
import 'package:english_for_community/core/model/failure.dart';

abstract class AppReleaseRepository {
  Future<Either<Failure, List<AppReleaseAdminEntity>>> getReleases({
    String? status,
    String? platform,
    String? environment,
    int page = 1,
    int limit = 100,
  });

  Future<Either<Failure, void>> runAction({
    required String action,
    required String releaseId,
    Map<String, dynamic>? payload,
  });
}
