import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/rutina.dart';

final routineApiProvider = Provider((ref) {
  return RoutineApi(ref.watch(apiClientProvider));
});

class RoutineApi {
  final ApiClient _client;

  RoutineApi(this._client);

  Future<List<Rutina>> listRutinas({int skip = 0, int limit = 20}) async {
    final response = await _client.get('/routines', queryParameters: {'skip': skip, 'limit': limit});
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((e) => Rutina.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Rutina> getRutina(String id) async {
    final response = await _client.get('/routines/$id');
    return Rutina.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Rutina> createRutina(Map<String, dynamic> data) async {
    final response = await _client.post('/routines', data: data);
    return Rutina.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Rutina> updateRutina(String id, Map<String, dynamic> data) async {
    final response = await _client.put('/routines/$id', data: data);
    return Rutina.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteRutina(String id) async {
    await _client.delete('/routines/$id');
  }
}

class RoutinesState {
  final bool isLoading;
  final List<Rutina> rutinas;
  final String? error;

  const RoutinesState({this.isLoading = false, this.rutinas = const [], this.error});

  RoutinesState copyWith({bool? isLoading, List<Rutina>? rutinas, String? error}) {
    return RoutinesState(
      isLoading: isLoading ?? this.isLoading,
      rutinas: rutinas ?? this.rutinas,
      error: error,
    );
  }
}

class RoutinesNotifier extends StateNotifier<RoutinesState> {
  final RoutineApi _api;

  RoutinesNotifier(this._api) : super(const RoutinesState());

  Future<void> loadRutinas() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final rutinas = await _api.listRutinas();
      state = state.copyWith(isLoading: false, rutinas: rutinas);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createRutina(Map<String, dynamic> data) async {
    try {
      final rutina = await _api.createRutina(data);
      state = state.copyWith(rutinas: [rutina, ...state.rutinas]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteRutina(String id) async {
    try {
      await _api.deleteRutina(id);
      state = state.copyWith(rutinas: state.rutinas.where((r) => r.id != id).toList());
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final routinesProvider = StateNotifierProvider<RoutinesNotifier, RoutinesState>((ref) {
  final api = ref.watch(routineApiProvider);
  return RoutinesNotifier(api);
});
