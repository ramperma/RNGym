import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../machines/domain/maquina_gym.dart';
import '../../weekly_plan/domain/plan_semanal.dart';

class AIApi {
  final ApiClient _client;

  AIApi(this._client);

  Future<PlanSemanal> generateWeeklyPlan({
    required String objetivo,
    required int diasPorSemana,
    required int duracionMaxMinutos,
    required String nivelExperiencia,
    required List<String> equipoDisponible,
    List<String> lesionesOLimitaciones = const [],
    String? notasAdicionales,
    List<String> maquinasUsuarioIds = const [],
    List<String> diasEntrenoSeleccionados = const [],
    List<String> preferenciasEquipamiento = const [],
    int? porcentajeMaquinasGuiadas,
    int? porcentajePesoLibre,
    int minEjerciciosPorSesion = 4,
  }) async {
    final response = await _client.post('/ai/weekly-plan', data: {
      'objetivo': objetivo,
      'dias_por_semana': diasPorSemana,
      'duracion_max_minutos': duracionMaxMinutos,
      'nivel_experiencia': nivelExperiencia,
      'equipo_disponible': equipoDisponible,
      'lesiones_o_limitaciones': lesionesOLimitaciones,
      'notas_adicionales': notasAdicionales,
      'maquinas_usuario_ids': maquinasUsuarioIds,
      'dias_entreno_seleccionados': diasEntrenoSeleccionados,
      'preferencias_equipamiento': preferenciasEquipamiento,
      'porcentaje_maquinas_guiadas': porcentajeMaquinasGuiadas,
      'porcentaje_peso_libre': porcentajePesoLibre,
      'min_ejercicios_por_sesion': minEjerciciosPorSesion,
    });
    final data = response.data as Map<String, dynamic>;
    return PlanSemanal.fromJson(data['plan_guardado'] as Map<String, dynamic>);
  }

  Future<List<PlanSemanal>> listPlans({int skip = 0, int limit = 20, bool soloActivos = false}) async {
    final response = await _client.get(
      '/ai/plans',
      queryParameters: {'skip': skip, 'limit': limit, 'solo_activos': soloActivos},
    );
    return (response.data as List<dynamic>)
        .map((e) => PlanSemanal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PlanSemanal> getPlan(String planId) async {
    final response = await _client.get('/ai/plans/$planId');
    return PlanSemanal.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MaquinaGym> uploadMachine({
    required String nombre,
    String? grupoMuscular,
    String? descripcionUso,
    File? file,
  }) async {
    final formData = FormData.fromMap({
      'nombre': nombre,
      if (grupoMuscular != null) 'grupo_muscular': grupoMuscular,
      if (descripcionUso != null) 'descripcion_uso': descripcionUso,
      if (file != null)
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
    });
    final response = await _client.uploadFile('/ai/machines/upload', formData);
    return MaquinaGym.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<MaquinaGym>> listMachines() async {
    final response = await _client.get('/ai/machines');
    return (response.data as List<dynamic>)
        .map((e) => MaquinaGym.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteMachine(String machineId) async {
    await _client.delete('/ai/machines/$machineId');
  }

  Future<Map<String, dynamic>> proposeMachine({
    required String descripcionUso,
  }) async {
    final response = await _client.post('/ai/machines/propose', data: {
      'descripcion_uso': descripcionUso,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<PlanSemanal> modifyWeeklyPlan({
    required String planId,
    required String instrucciones,
  }) async {
    final response = await _client.post('/ai/modify-plan', data: {
      'plan_id': planId,
      'instrucciones': instrucciones,
    });
    final data = response.data as Map<String, dynamic>;
    return PlanSemanal.fromJson(data['plan_guardado'] as Map<String, dynamic>);
  }

  Future<void> deleteWeeklyPlan(String planId) async {
    await _client.delete('/ai/plans/$planId');
  }

  Future<PlanSemanal> activateWeeklyPlan(String planId) async {
    final response = await _client.post('/ai/plans/$planId/activate');
    return PlanSemanal.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PlanSemanal> addExercisesToPlan({
    required String planId,
    required int diaSemana,
    required String bloqueTipo,
    required List<String> ejerciciosIds,
  }) async {
    final response = await _client.post('/ai/plans/$planId/add-exercises', data: {
      'dia_semana': diaSemana,
      'bloque_tipo': bloqueTipo,
      'ejercicios_ids': ejerciciosIds,
    });
    return PlanSemanal.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> exerciseHelp({
    required String nombreEjercicio,
    String? grupoMuscular,
    String? machineNombre,
    String? notasPlan,
    String? pregunta,
    File? foto,
  }) async {
    final formData = FormData.fromMap({
      'nombre_ejercicio': nombreEjercicio,
      if (grupoMuscular != null) 'grupo_muscular': grupoMuscular,
      if (machineNombre != null) 'machine_nombre': machineNombre,
      if (notasPlan != null) 'notas_plan': notasPlan,
      if (pregunta != null) 'pregunta': pregunta,
      if (foto != null)
        'file': await MultipartFile.fromFile(
          foto.path,
          filename: foto.path.split('/').last,
        ),
    });
    final response = await _client.uploadFile('/ai/exercise-help', formData);
    final data = response.data as Map<String, dynamic>;
    return data['respuesta'] as String;
  }
}