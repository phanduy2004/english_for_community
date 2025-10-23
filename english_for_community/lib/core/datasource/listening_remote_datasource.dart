import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:english_for_community/core/entity/listening_entity.dart';

class ListeningRemoteDatasource {
  final Dio dio;

  ListeningRemoteDatasource({required this.dio});

  Future<List<ListeningEntity>> getListListening() async {
    final res = await dio.get('listening/');
    final data = res.data as Map<String, dynamic>;
    final items = (data['docs'] as List)
        .map((e) => ListeningEntity.fromJson(e as Map<String, dynamic>))
        .toList();
    log('item ${items}');
    return items;
  }

  /// GET /api/listenings/by-code/:code
  Future<ListeningEntity> getListeningById(String id) async {
    final res = await dio.get('listening/$id');
    return ListeningEntity.fromJson(res.data);
  }
}
