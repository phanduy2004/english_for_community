import 'package:dio/dio.dart';
import 'package:english_for_community/core/api/api_client.dart';
import 'package:english_for_community/core/api/token_storage.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/feature/auth/bloc/user_bloc.dart';
import 'package:english_for_community/feature/auth/bloc/user_event.dart';

// Service để xử lý logout (bạn cần tự implement)
// Ví dụ: điều hướng về màn hình Login
// class AuthService {
//   static Future<void> logout() async {
//     // clear tokens
//     await TokenStorage.clearAllTokens();
//     // navigate to login screen
//     // (sử dụng Navigass torKey global hoặc Riverpod/Provider/GetX...)
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
      // Refresh endpoint failed — clear session (401 expired / 403 revoked).
      if (err.requestOptions.path.endsWith('auth/refresh')) {
        print("Refresh token failed, logging out.");
        await TokenStorage.clearAllTokens();
        _notifyLogout();
        return handler.next(err);
      }

      // SỬA LỖI: Thêm cả `err` và `handler` vào hàng đợi
      _errorHandlers.add((error: err, handler: handler));

      // Nếu chưa có ai đang refresh, thì bắt đầu refresh
      if (!_isRefreshing) {
        _isRefreshing = true;
        try {
          final newAccessToken = await _performRefresh();

          if (newAccessToken != null) {
            // Tokens already persisted in _performRefresh (access + rotated refresh).
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
    } else if (err.response?.statusCode == 403 &&
        err.requestOptions.path.endsWith('auth/refresh')) {
      print("Refresh token revoked, logging out.");
      await TokenStorage.clearAllTokens();
      _notifyLogout();
      handler.next(err);
    } else {
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
      final refreshDio = Dio(ApiClient.baseOptions(baseUrl: dio.options.baseUrl));

      final response = await refreshDio.post(
        'auth/refresh', // ĐÃ SỬA LỖI: Bỏ '/api/' vì nó đã có trong baseUrl
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return TokenStorage.saveTokensFromAuthResponse(data);
      }
    } on DioException catch (e) {
      print("Error during token refresh: ${e.response?.statusCode} ${e.message}");
      // Không ném lỗi ở đây, chỉ cần trả về null để logout
    }

    // Nếu refresh thất bại (mọi lý do)
    await TokenStorage.clearAllTokens();
    // await AuthService.logout();
    return null;
  }

  // SỬA LỖI CÚ PHÁP: Hàm này là một phương thức của class
  Future<void> _retryPendingRequests(String newAccessToken) async {
    // Xử lý theo snapshot + drain: mỗi vòng lấy bản sao rồi clear list gốc, nên
    // 401 mới chen vào giữa các `await` bên dưới không sửa list đang lặp
    // (tránh ConcurrentModificationError) và vẫn được vòng while sau nhặt lại
    // (tránh request bị bỏ rơi → treo spinner).
    while (_errorHandlers.isNotEmpty) {
      final pending = List.of(_errorHandlers);
      _errorHandlers.clear();
      for (var pendingRequest in pending) {
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
  }

  void _rejectPendingRequests(DioException error) {
    // Snapshot + clear trước khi lặp (đồng nhất với _retryPendingRequests).
    final pending = List.of(_errorHandlers);
    _errorHandlers.clear();
    for (var pendingRequest in pending) {
      pendingRequest.handler.next(error);
    }
    // Refresh đã thất bại → báo UserBloc đăng xuất để router đá về Login.
    _notifyLogout();
  }

  /// Phiên hết hạn & refresh thất bại: đẩy UserBloc về trạng thái chưa đăng nhập.
  /// Router có `refreshListenable` nghe `UserBloc.stream` nên sẽ tự điều hướng /login,
  /// thay vì để student kẹt trên màn đã đăng nhập với mọi request 401.
  void _notifyLogout() {
    try {
      getIt<UserBloc>().add(ForceLogoutEvent(
        reason: 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.',
      ));
    } catch (_) {
      // getIt/UserBloc chưa sẵn sàng — token đã bị xoá nên lần mở app sau sẽ vào Login.
    }
  }
}