import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/perfil_salud.dart';

final healthProfileApiProvider = Provider((ref) {
  return HealthProfileApi(ref.watch(apiClientProvider));
});

class HealthProfileApi {
  final ApiClient _client;

  HealthProfileApi(this._client);

  Future<PerfilSalud?> getProfile() async {
    try {
      final response = await _client.get('/health-profile');
      return PerfilSalud.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<PerfilSalud> upsertProfile(Map<String, dynamic> data) async {
    final response = await _client.put('/health-profile', data: data);
    return PerfilSalud.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteProfile() async {
    await _client.delete('/health-profile');
  }
}

class HealthProfileState {
  final bool isLoading;
  final PerfilSalud? perfil;
  final String? error;

  const HealthProfileState({
    this.isLoading = false,
    this.perfil,
    this.error,
  });

  HealthProfileState copyWith({bool? isLoading, PerfilSalud? perfil, String? error}) {
    return HealthProfileState(
      isLoading: isLoading ?? this.isLoading,
      perfil: perfil ?? this.perfil,
      error: error,
    );
  }
}

class HealthProfileNotifier extends StateNotifier<HealthProfileState> {
  final HealthProfileApi _api;

  HealthProfileNotifier(this._api) : super(const HealthProfileState());

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final perfil = await _api.getProfile();
      state = state.copyWith(isLoading: false, perfil: perfil);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> saveProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final perfil = await _api.upsertProfile(data);
      state = state.copyWith(isLoading: false, perfil: perfil);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.deleteProfile();
      state = state.copyWith(isLoading: false, perfil: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final healthProfileProvider = StateNotifierProvider<HealthProfileNotifier, HealthProfileState>((ref) {
  final api = ref.watch(healthProfileApiProvider);
  return HealthProfileNotifier(api);
});
