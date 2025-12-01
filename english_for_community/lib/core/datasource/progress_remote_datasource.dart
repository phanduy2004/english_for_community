import 'dart:developer';
import 'package:dio/dio.dart';
import '../entity/leaderboard_entity.dart';
import '../entity/progress_summary_entity.dart';

class ProgressRemoteDatasource {
  final Dio dio;

  ProgressRemoteDatasource({required this.dio});

  Future<ProgressSummaryEntity> getProgressSummary({
    required String range,
  }) async {
    try {
      final res = await dio.get(
        'progress/summary', // Endpoint
        queryParameters: {
          'range': range, // Gửi ?range=day, ?range=week, ...
        },
      );
      final entity = ProgressSummaryEntity.fromJson(res.data as Map<String, dynamic>);
      log('Fetched Progress Summary (range: $range) successfully.');
      return entity;
    } catch (e) {
      log('Error fetching progress summary: $e');
      rethrow;
    }
  }
  Future<List<ProgressDetailEntity>> getStatDetail({
    required String statKey,
    required String range,
  }) async {
    try {
      final res = await dio.get(
        'progress/detail', // Endpoint mới
        queryParameters: {
          'statKey': statKey, // 'reading', 'speaking',...
          'range': range,
        },
      );

      // Backend trả về { data: [ {..}, {..} ] }
      final List<dynamic> dataList = res.data['data'] as List<dynamic>;

      final detailList = dataList
          .map((json) => ProgressDetailEntity.fromJson(json as Map<String, dynamic>))
          .toList();

      log('Fetched Progress Detail (statKey: $statKey, range: $range) successfully.');
      return detailList;
    } catch (e) {
      log('Error fetching stat detail: $e');
      rethrow;
    }
  }
  Future<LeaderboardResultEntity> getLeaderboard() async {
    try {
      final res = await dio.get('progress/leaderboard'); // Endpoint API

      final result = LeaderboardResultEntity.fromJson(res.data as Map<String, dynamic>);

      log('Fetched Leaderboard successfully.');
      return result;
    } catch (e) {
      log('Error fetching leaderboard: $e');
      rethrow;
    }
  }

}