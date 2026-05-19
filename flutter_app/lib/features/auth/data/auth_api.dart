import '../../../core/network/api_client.dart';
import '../domain/user.dart';

class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String nombre,
    String? apellidos,
  }) async {
    final response = await _client.post('/auth/register', data: {
      'email': email,
      'password': password,
      'nombre': nombre,
      if (apellidos != null) 'apellidos': apellidos,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    final response = await _client.post('/auth/refresh', data: {
      'refresh_token': refreshToken,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<User> getCurrentUser() async {
    final response = await _client.get('/auth/me');
    final data = response.data as Map<String, dynamic>;
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<User> updateSettings(Map<String, dynamic> data) async {
    final response = await _client.patch('/me/settings', data: data);
    final resData = response.data as Map<String, dynamic>;
    return User.fromJson(resData['user'] as Map<String, dynamic>);
  }
}