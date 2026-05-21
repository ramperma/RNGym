import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/sesion.dart';

final sessionApiProvider = Provider((ref) {
  return SessionApi(ref.watch(apiClientProvider));
});

class SessionApi {
  final ApiClient _client;

  SessionApi(this._client);

  Future<List<SesionEntreno>> listSessions({int skip = 0, int limit = 20, String? estado}) async {
    final params = <String, dynamic>{'skip': skip, 'limit': limit};
    if (estado != null) params['estado'] = estado;
    final response = await _client.get('/sessions', queryParameters: params);
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((e) => SesionEntreno.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SesionEntreno> getSession(String id) async {
    final response = await _client.get('/sessions/$id');
    return SesionEntreno.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SesionEntreno> createSession(Map<String, dynamic> data) async {
    final response = await _client.post('/sessions', data: data);
    return SesionEntreno.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SesionEntreno> updateSession(String id, Map<String, dynamic> data) async {
    final response = await _client.patch('/sessions/$id', data: data);
    return SesionEntreno.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteSession(String id) async {
    await _client.delete('/sessions/$id');
  }

  Future<void> registerSets(
    String sesionId,
    String? ejercicioId,
    List<Map<String, dynamic>> registros, {
    String? ejercicioNombre,
    String? ejercicioGrupoMuscular,
    String? ejercicioEquipo,
  }) async {
    await _client.post('/sessions/$sesionId/exercises', data: {
      'ejercicio_id': ejercicioId,
      'ejercicio_nombre': ejercicioNombre,
      'ejercicio_grupo_muscular': ejercicioGrupoMuscular,
      'ejercicio_equipo': ejercicioEquipo,
      'registros': registros,
    });
  }
}

class SessionsState {
  final bool isLoading;
  final List<SesionEntreno> sesiones;
  final String? error;

  const SessionsState({this.isLoading = false, this.sesiones = const [], this.error});

  SessionsState copyWith({bool? isLoading, List<SesionEntreno>? sesiones, String? error}) {
    return SessionsState(
      isLoading: isLoading ?? this.isLoading,
      sesiones: sesiones ?? this.sesiones,
      error: error,
    );
  }
}

class SessionsNotifier extends StateNotifier<SessionsState> {
  final SessionApi _api;

  SessionsNotifier(this._api) : super(const SessionsState());

  Future<void> loadSessions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sesiones = await _api.listSessions();
      state = state.copyWith(isLoading: false, sesiones: sesiones);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createSession(Map<String, dynamic> data) async {
    try {
      final sesion = await _api.createSession(data);
      state = state.copyWith(sesiones: [sesion, ...state.sesiones]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteSession(String id) async {
    try {
      await _api.deleteSession(id);
      state = state.copyWith(sesiones: state.sesiones.where((s) => s.id != id).toList());
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final sessionsProvider = StateNotifierProvider<SessionsNotifier, SessionsState>((ref) {
  final api = ref.watch(sessionApiProvider);
  return SessionsNotifier(api);
});
