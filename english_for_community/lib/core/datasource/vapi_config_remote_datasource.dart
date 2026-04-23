import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api/api_client.dart';

/// Kết quả gọi API cấu hình Vapi (không throw — để UI phân biệt 401 / mạng / 503).
class VapiConfigFetchOutcome {
  const VapiConfigFetchOutcome({
    this.publicKey,
    this.assistantId,
    this.statusCode,
    this.message,
  });

  final String? publicKey;
  final String? assistantId;
  final int? statusCode;
  final String? message;

  bool get hasKeys =>
      (publicKey?.trim().isNotEmpty ?? false) &&
      (assistantId?.trim().isNotEmpty ?? false);
}

/// Lấy public key + assistant id từ backend (yêu cầu JWT).
class VapiConfigRemoteDatasource {
  VapiConfigRemoteDatasource({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<VapiConfigFetchOutcome> fetchConfig() async {
    try {
      final dio = _api.getDio(authorized: true);
      final res = await dio.get<Map<String, dynamic>>('speaking/vapi-config');
      final data = res.data;
      if (data == null) {
        return const VapiConfigFetchOutcome(
          statusCode: 200,
          message: 'Empty response body',
        );
      }
      final pk = (data['publicKey'] as String?)?.trim() ??
          (data['public_key'] as String?)?.trim() ??
          '';
      final aid = (data['assistantId'] as String?)?.trim() ??
          (data['assistant_id'] as String?)?.trim() ??
          '';
      if (pk.isEmpty || aid.isEmpty) {
        return VapiConfigFetchOutcome(
          statusCode: res.statusCode,
          message: 'Response missing publicKey / assistantId',
        );
      }
      return VapiConfigFetchOutcome(
        publicKey: pk,
        assistantId: aid,
        statusCode: res.statusCode,
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final msg = e.message ?? e.toString();
      debugPrint('[VapiConfig] GET speaking/vapi-config failed: $code $msg');
      return VapiConfigFetchOutcome(
        statusCode: code,
        message: msg,
      );
    } catch (e) {
      debugPrint('[VapiConfig] unexpected: $e');
      return VapiConfigFetchOutcome(message: e.toString());
    }
  }
}
