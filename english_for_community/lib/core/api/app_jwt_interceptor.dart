import 'package:dio/dio.dart';
import 'package:english_for_community/core/api/token_storage.dart';

// Service để xử lý logout (bạn cần tự implement)
// Ví dụ: điều hướng về màn hình Login
// class AuthService {
//   static Future<void> logout() async {
//     // clear tokens
//     await TokenStorage.clearAllTokens();
//     // navigate to login screen
//     // (sử dụng NavigatorKey global hoặc Riverpod/Provider/GetX...)
//   }
// }

class AppJwtInterceptor extends Interceptor {
  final Dio dio;
  bool _isRefreshing = false;

  // SỬA LỖI: Hàng đợi cần lưu cả Error và Handler
  // Chúng ta sẽ dùng Record (tính năng của Dart 3+)
  final List<({DioException error, ErrorInterceptorHandler handler})> _errorHandlers = [];

  AppJwtInterceptor({required this.dio});

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await TokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Nếu là lỗi từ chính endpoint /refresh, thì logout luôn
      if (err.requestOptions.path.endsWith('auth/refresh')) {
        print("Refresh token failed, logging out.");
        await TokenStorage.clearAllTokens();
        // await AuthService.logout(); // Gọi hàm logout
        return handler.next(err); // Trả về lỗi
      }

      // SỬA LỖI: Thêm cả `err` và `handler` vào hàng đợi
      _errorHandlers.add((error: err, handler: handler));

      // Nếu chưa có ai đang refresh, thì bắt đầu refresh
      if (!_isRefreshing) {
        _isRefreshing = true;
        try {
          final newAccessToken = await _performRefresh();

          if (newAccessToken != null) {
            // Refresh thành công, lưu token mới
            await TokenStorage.saveAccessToken(newAccessToken);
            // Thử lại tất cả request trong hàng đợi với token mới
            await _retryPendingRequests(newAccessToken);
          } else {
            // Refresh thất bại (do _performRefresh đã logout)
            _rejectPendingRequests(err);
          }
        } catch (e) {
          // Xử lý lỗi nếu bản thân việc refresh bị lỗi (ngoài DioException)
          _rejectPendingRequests(DioException(
            requestOptions: err.requestOptions,
            error: e,
            message: "Failed to refresh token",
          ));
        } finally {
          _isRefreshing = false;
          _errorHandlers.clear();
        }
      }
      // Nếu đang refresh rồi, thì request này chỉ cần đợi
      // (đã được thêm vào _errorHandlers)
    } else {
      // Không phải lỗi 401, bỏ qua
      handler.next(err);
    }
  }

  // SỬA LỖI CÚ PHÁP: Hàm này là một phương thức của class
  Future<String?> _performRefresh() async {
    final refreshToken = await TokenStorage.readRefreshToken();
    if (refreshToken == null) {
      print("No refresh token, logging out.");
      await TokenStorage.clearAllTokens();
      // await AuthService.logout();
      return null;
    }

    try {
      // Tạo một Dio instance mới CHỈ để gọi refresh,
      // để tránh vòng lặp vô hạn của interceptor
      final refreshDio = Dio(BaseOptions(
        baseUrl: dio.options.baseUrl,
      ));

      final response = await refreshDio.post(
        'auth/refresh', // ĐÃ SỬA LỖI: Bỏ '/api/' vì nó đã có trong baseUrl
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        return response.data['accessToken'];
      }
    } on DioException catch (e) {
      print("Error during token refresh: $e");
      // Không ném lỗi ở đây, chỉ cần trả về null để logout
    }

    // Nếu refresh thất bại (mọi lý do)
    await TokenStorage.clearAllTokens();
    // await AuthService.logout();
    return null;
  }

  // SỬA LỖI CÚ PHÁP: Hàm này là một phương thức của class
  Future<void> _retryPendingRequests(String newAccessToken) async {
    for (var pendingRequest in _errorHandlers) {
      final options = pendingRequest.error.requestOptions;
      options.headers['Authorization'] = 'Bearer $newAccessToken';

      try {
        // Thử lại request với Dio instance gốc
        final response = await dio.request(
          options.path,
          options: Options(
            method: options.method,
            headers: options.headers,
          ),
          data: options.data,
          queryParameters: options.queryParameters,
        );
        pendingRequest.handler.resolve(response); // Resolve request thành công
      } on DioException catch (e) {
        pendingRequest.handler.next(e); // Nếu vẫn lỗi thì trả về lỗi
      }
    }
  }

  void _rejectPendingRequests(DioException error) {
    for (var pendingRequest in _errorHandlers) {
      pendingRequest.handler.next(error);
    }
  }
}