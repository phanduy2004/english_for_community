import 'package:dio/dio.dart';
import 'package:english_for_community/core/entity/listening_entity.dart';

class ListeningRemoteDatasource {
  final Dio dio;

  ListeningRemoteDatasource({required this.dio});

  Future<ListeningEntity> getListListening() async {
    final response = await dio.get('listening/');
    return ListeningEntity.fromJson(response.data);
  }

  /// GET /api/listenings/by-code/:code
  Future<ListeningEntity> getListeningById(String id) async {
    final res = await dio.get('listening/$id');
    return ListeningEntity.fromJson(res.data);
  }
}
