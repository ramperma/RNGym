import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _storage;

  /// Evita que múltiples peticiones concurrentes disparen múltiples refrescos.
  Completer<Map<String, String>>? _refreshCompleter;

  AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;

    if (statusCode == 401 || statusCode == 403) {
      // Los FormData son streams y no se pueden reutilizar; no intentamos reintentar.
      if (err.requestOptions.data is FormData) {
        await _storage.clearAuthOnly();
        handler.next(err);
        return;
      }

      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _storage.clearAuthOnly();
        handler.next(err);
        return;
      }

      try {
        final newTokens = await _refresh(refreshToken, err.requestOptions.baseUrl);
        await _storage.saveTokens(newTokens['access_token']!, newTokens['refresh_token']!);

        // Reintentar la petición original con el nuevo access token
        final opts = Options(
          method: err.requestOptions.method,
          headers: Map<String, dynamic>.from(err.requestOptions.headers),
        );
        opts.headers?['Authorization'] = 'Bearer ${newTokens['access_token']}';

        final dio = Dio(BaseOptions(
          baseUrl: err.requestOptions.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

        final response = await dio.request<dynamic>(
          err.requestOptions.path,
          options: opts,
          data: err.requestOptions.data,
          queryParameters: err.requestOptions.queryParameters,
        );

        handler.resolve(response);
        return;
      } catch (_) {
        // Falló el refresh o el reintento: limpiar solo auth, preservar servidor
        await _storage.clearAuthOnly();
        handler.next(err);
        return;
      }
    }

    handler.next(err);
  }

  /// Ejecuta el refresh una sola vez incluso si llegan varios 401 simultáneos.
  Future<Map<String, String>> _refresh(String refreshToken, String baseUrl) async {
    if (_refreshCompleter == null) {
      _refreshCompleter = Completer<Map<String, String>>();
      try {
        final tokens = await _doRefresh(refreshToken, baseUrl);
        _refreshCompleter!.complete(tokens);
      } catch (e, st) {
        _refreshCompleter!.completeError(e, st);
      } finally {
        _refreshCompleter!.future.whenComplete(() {
          _refreshCompleter = null;
        });
      }
    }
    return _refreshCompleter!.future;
  }

  Future<Map<String, String>> _doRefresh(String refreshToken, String baseUrl) async {
    // Dio limpio sin interceptores para evitar bucle infinito de 401 → refresh
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    final data = response.data!;
    return {
      'access_token': data['access_token'] as String,
      'refresh_token': data['refresh_token'] as String,
    };
  }
}
