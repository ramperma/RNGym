import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userEmailKey = 'user_email';
  static const _passwordKey = 'user_password';
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _apiBaseUrlKey = 'api_base_url';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<void> saveUser(String id, String email) async {
    await _storage.write(key: _userIdKey, value: id);
    await _storage.write(key: _userEmailKey, value: email);
  }

  Future<String?> getUserId() async {
    return _storage.read(key: _userIdKey);
  }

  Future<String?> getUserEmail() async {
    return _storage.read(key: _userEmailKey);
  }

  Future<void> savePassword(String password) async {
    await _storage.write(key: _passwordKey, value: password);
  }

  Future<String?> getPassword() async {
    return _storage.read(key: _passwordKey);
  }

  Future<void> saveBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled ? 'true' : 'false');
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _biometricEnabledKey);
    return val == 'true';
  }

  Future<bool> hasTokens() async {
    final access = await _storage.read(key: _accessTokenKey);
    return access != null && access.isNotEmpty;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Borra solo las credenciales de autenticación (tokens + user_id),
  /// preservando la URL del servidor, email, contraseña y preferencias
  /// biométricas para que el usuario no tenga que reconfigurar todo.
  Future<void> clearAuthOnly() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
  }

  Future<void> saveApiBaseUrl(String url) async {
    await _storage.write(key: _apiBaseUrlKey, value: url);
  }

  Future<String?> getApiBaseUrl() async {
    return _storage.read(key: _apiBaseUrlKey);
  }
}