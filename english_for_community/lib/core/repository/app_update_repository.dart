import 'package:english_for_community/core/entity/app_update_info_entity.dart';
import 'package:english_for_community/core/model/either.dart';
import 'package:english_for_community/core/model/failure.dart';

abstract class AppUpdateRepository {
  Future<Either<Failure, AppUpdateInfoEntity>> checkVersion({
    required String platform,
    required int versionCode,
    String environment = 'production',
  });
}
