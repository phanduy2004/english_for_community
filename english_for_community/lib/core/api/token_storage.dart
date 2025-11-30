import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _accessTokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _storage = FlutterSecureStorage();

  // --- Access Token ---
  static Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  static Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  // --- Refresh Token ---
  static Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  static Future<String?> readRefreshToken() =>
      _storage.read(key: _refreshTokenKey);

  // --- Clear All ---
  static Future<void> clearAllTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}