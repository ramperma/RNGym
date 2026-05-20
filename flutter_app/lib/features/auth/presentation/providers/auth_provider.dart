import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/auth_api.dart';
import '../../domain/user.dart';

final secureStorageProvider = Provider((ref) => SecureStorage());

final apiUrlProvider = StateProvider<String?>((ref) => null);

final apiClientProvider = Provider((ref) {
  final storage = ref.watch(secureStorageProvider);
  final customUrl = ref.watch(apiUrlProvider);
  return ApiClientWithAuth(storage, customBaseUrl: customUrl);
});

class ApiClientWithAuth extends ApiClient {
  final SecureStorage _storage;

  ApiClientWithAuth(this._storage, {String? customBaseUrl}) : super(customBaseUrl: customBaseUrl) {
    dio.interceptors.add(AuthInterceptor(_storage));
  }
}

final authApiProvider = Provider((ref) {
  return AuthApi(ref.watch(apiClientProvider));
});

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, User? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

String _humanReadableError(Object e) {
  if (e is DioException) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'No se pudo conectar al servidor. Revisa tu conexión.';
    }
    if (e.response?.statusCode == 401) {
      return 'Email o contraseña incorrectos.';
    }
    if (e.response?.statusCode == 422) {
      final detail = e.response?.data;
      if (detail is Map && detail.containsKey('detail')) {
        final d = detail['detail'];
        if (d is String) return d;
        if (d is Map && d.containsKey('message')) return d['message'] as String;
        if (d is List && d.isNotEmpty && d[0] is Map) {
          return 'Error de validación: ${d[0]['msg'] ?? 'datos inválidos'}';
        }
      }
      return 'Datos inválidos. Revisa los campos.';
    }
    if (e.response?.statusCode == 409) {
      return 'El email ya está registrado.';
    }
    if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
      return 'Error del servidor. Inténtalo más tarde.';
    }
    return 'Error de red: ${e.message ?? 'sin conexión'}';
  }
  final msg = e.toString();
  if (msg.length > 120) return '${msg.substring(0, 120)}…';
  return msg;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SecureStorage _storage;
  final Ref _ref;
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthNotifier(this._storage, this._ref) : super(const AuthState()) {
    _initializeServerUrlAndAuth();
  }

  AuthApi get _api => _ref.read(authApiProvider);

  Future<void> _initializeServerUrlAndAuth() async {
    final savedUrl = await _storage.getApiBaseUrl();
    if (savedUrl != null && savedUrl.isNotEmpty) {
      AppConfig.setBaseUrl(savedUrl);
      _ref.read(apiUrlProvider.notifier).state = savedUrl;
    }
    await _checkAuth();
  }

  Future<void> _checkAuth() async {
    final hasTokens = await _storage.hasTokens();
    if (!hasTokens) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await _api.getCurrentUser();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      await _storage.saveTokens('', ''); // Limpiar tokens caducados pero mantener biometría
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> deviceSupportsBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (_) {
      return false;
    }
  }

  Future<bool> loginWithBiometrics() async {
    if (state.status == AuthStatus.loading || state.status == AuthStatus.authenticated) {
      return false;
    }
    final email = await _storage.getUserEmail();
    final password = await _storage.getPassword();
    final isBioEnabled = await _storage.isBiometricEnabled();

    if (email == null || password == null || !isBioEnabled) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: 'Autenticación biométrica no habilitada o credenciales ausentes.',
      );
      return false;
    }

    try {
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Inicia sesión de forma segura en Gym Trainer',
      );

      if (authenticated) {
        await login(email, password);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: 'Error de biometría: ${_humanReadableError(e)}',
      );
      return false;
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final data = await _api.login(email: email, password: password);
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;
      final userData = data['user'] as Map<String, dynamic>;
      final user = User.fromJson(userData);

      await _storage.saveTokens(accessToken, refreshToken);
      await _storage.saveUser(user.id, user.email);
      await _storage.savePassword(password); // Guardar contraseña de forma segura

      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: _humanReadableError(e),
      );
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String nombre,
    String? apellidos,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final data = await _api.register(
        email: email,
        password: password,
        nombre: nombre,
        apellidos: apellidos,
      );
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;
      final userData = data['user'] as Map<String, dynamic>;
      final user = User.fromJson(userData);

      await _storage.saveTokens(accessToken, refreshToken);
      await _storage.saveUser(user.id, user.email);
      await _storage.savePassword(password); // Guardar contraseña de forma segura

      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: _humanReadableError(e),
      );
    }
  }

  Future<void> logout() async {
    await _storage.saveTokens('', ''); // Limpiar tokens pero preservar preferencia de huella y credenciales
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Limpia también la URL del servidor (llamado desde Settings → Desvincular).
  Future<void> disconnectServer() async {
    AppConfig.clearBaseUrl();
    _ref.read(apiUrlProvider.notifier).state = null;
    await _storage.saveApiBaseUrl('');
    await logout();
  }

  Future<void> updateSettings(Map<String, dynamic> data) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _api.updateSettings(data);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: _humanReadableError(e),
      );
      rethrow;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(storage, ref);
});
