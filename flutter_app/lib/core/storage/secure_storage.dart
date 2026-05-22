import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userEmailKey = 'user_email';
  static const _passwordKey = 'user_password';
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _apiBaseUrlKey = 'api_base_url';

  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  SharedPreferences? _prefs;
  bool? _secureAvailable;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<bool> _isSecureAvailable() async {
    if (_secureAvailable != null) return _secureAvailable!;
    try {
      await _secure.read(key: 'test_key');
      _secureAvailable = true;
    } catch (_) {
      _secureAvailable = false;
    }
    return _secureAvailable!;
  }

  Future<void> _write(String key, String value) async {
    if (await _isSecureAvailable()) {
      try {
        await _secure.write(key: key, value: value);
        return;
      } catch (_) {}
    }
    final p = await _getPrefs();
    await p.setString(key, value);
  }

  Future<String?> _read(String key) async {
    if (await _isSecureAvailable()) {
      try {
        final val = await _secure.read(key: key);
        if (val != null) return val;
      } catch (_) {}
    }
    final p = await _getPrefs();
    return p.getString(key);
  }

  Future<void> _delete(String key) async {
    if (await _isSecureAvailable()) {
      try {
        await _secure.delete(key: key);
      } catch (_) {}
    }
    final p = await _getPrefs();
    await p.remove(key);
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _write(_accessTokenKey, accessToken);
    await _write(_refreshTokenKey, refreshToken);
  }

  Future<String?> getAccessToken() async => _read(_accessTokenKey);

  Future<String?> getRefreshToken() async => _read(_refreshTokenKey);

  Future<void> saveUser(String id, String email) async {
    await _write(_userIdKey, id);
    await _write(_userEmailKey, email);
  }

  Future<String?> getUserId() async => _read(_userIdKey);

  Future<String?> getUserEmail() async => _read(_userEmailKey);

  Future<void> savePassword(String password) async {
    await _write(_passwordKey, password);
  }

  Future<String?> getPassword() async => _read(_passwordKey);

  Future<void> saveBiometricEnabled(bool enabled) async {
    await _write(_biometricEnabledKey, enabled ? 'true' : 'false');
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _read(_biometricEnabledKey);
    return val == 'true';
  }

  Future<bool> hasTokens() async {
    final access = await _read(_accessTokenKey);
    return access != null && access.isNotEmpty;
  }

  Future<void> clearAll() async {
    try {
      await _secure.deleteAll();
    } catch (_) {}
    final p = await _getPrefs();
    await p.clear();
  }

  Future<void> clearAuthOnly() async {
    await _delete(_accessTokenKey);
    await _delete(_refreshTokenKey);
    await _delete(_userIdKey);
  }

  Future<void> saveApiBaseUrl(String url) async {
    await _write(_apiBaseUrlKey, url);
  }

  Future<String?> getApiBaseUrl() async => _read(_apiBaseUrlKey);
}
