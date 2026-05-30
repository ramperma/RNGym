import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../data/ai_api.dart';
import '../../../machines/domain/maquina_gym.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../weekly_plan/domain/plan_semanal.dart';

final aiApiProvider = Provider((ref) {
  return AIApi(ref.watch(apiClientProvider));
});

class WeeklyPlanState {
  final bool isLoading;
  final PlanSemanal? plan;
  final List<PlanSemanal> planes;
  final String? error;

  const WeeklyPlanState({
    this.isLoading = false,
    this.plan,
    this.planes = const [],
    this.error,
  });

  WeeklyPlanState copyWith({
    bool? isLoading,
    PlanSemanal? plan,
    bool clearPlan = false,
    List<PlanSemanal>? planes,
    String? error,
  }) {
    return WeeklyPlanState(
      isLoading: isLoading ?? this.isLoading,
      plan: clearPlan ? null : (plan ?? this.plan),
      planes: planes ?? this.planes,
      error: error,
    );
  }
}

class WeeklyPlanNotifier extends StateNotifier<WeeklyPlanState> {
  final AIApi _api;

  WeeklyPlanNotifier(this._api) : super(const WeeklyPlanState());

  Future<void> generateWeeklyPlan({
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
    bool esEnCasa = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final plan = await _api.generateWeeklyPlan(
        objetivo: objetivo,
        diasPorSemana: diasPorSemana,
        duracionMaxMinutos: duracionMaxMinutos,
        nivelExperiencia: nivelExperiencia,
        equipoDisponible: equipoDisponible,
        lesionesOLimitaciones: lesionesOLimitaciones,
        notasAdicionales: notasAdicionales,
        maquinasUsuarioIds: maquinasUsuarioIds,
        diasEntrenoSeleccionados: diasEntrenoSeleccionados,
        preferenciasEquipamiento: preferenciasEquipamiento,
        porcentajeMaquinasGuiadas: porcentajeMaquinasGuiadas,
        porcentajePesoLibre: porcentajePesoLibre,
        minEjerciciosPorSesion: minEjerciciosPorSesion,
        esEnCasa: esEnCasa,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_weekly_plan_id', plan.id);
      state = state.copyWith(isLoading: false, plan: plan, planes: [plan, ...state.planes]);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadPlans({int skip = 0, int limit = 20, bool soloActivos = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('active_weekly_plan_id');

      if (soloActivos) {
        PlanSemanal? activePlan;
        
        // 1. Try loading the savedId plan from the backend if it exists
        if (savedId != null && savedId.isNotEmpty) {
          try {
            activePlan = await _api.getPlan(savedId);
          } catch (_) {}
        }
        
        // 2. If not found or no savedId, fallback to the backend's active plan
        if (activePlan == null) {
          final activePlanes = await _api.listPlans(skip: 0, limit: 1, soloActivos: true);
          activePlan = activePlanes.isNotEmpty ? activePlanes.first : null;
        }
        
        // 3. Update savedId in SharedPreferences if we found a plan
        if (activePlan != null) {
          await prefs.setString('active_weekly_plan_id', activePlan.id);
        } else {
          await prefs.remove('active_weekly_plan_id');
        }
        
        state = state.copyWith(isLoading: false, plan: activePlan);
      } else {
        // Carga completa: actualizar lista y determinar el plan activo
        final planes = await _api.listPlans(skip: skip, limit: limit, soloActivos: false);
        
        PlanSemanal? activePlan;
        // 1. Try finding the savedId plan in the fetched list
        if (savedId != null && savedId.isNotEmpty) {
          try {
            activePlan = planes.firstWhere((p) => p.id == savedId);
          } catch (_) {}
        }
        
        // 2. Fallback to the first plan in the list where active is true
        if (activePlan == null) {
          try {
            activePlan = planes.firstWhere((p) => p.activo);
          } catch (_) {
            activePlan = state.plan;
          }
        }
        
        // 3. Update savedId in SharedPreferences if we found a plan
        if (activePlan != null) {
          await prefs.setString('active_weekly_plan_id', activePlan.id);
        } else {
          await prefs.remove('active_weekly_plan_id');
        }
        
        state = state.copyWith(isLoading: false, planes: planes, plan: activePlan);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadPlan(String planId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final plan = await _api.getPlan(planId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_weekly_plan_id', plan.id);
      state = state.copyWith(isLoading: false, plan: plan);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearPlan() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('active_weekly_plan_id');
    });
    state = state.copyWith(clearPlan: true);
  }

  Future<void> updateWeeklyPlanName(String planId, String newName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedPlan = await _api.updateWeeklyPlanName(planId, newName);
      final updatedPlanes = state.planes.map((p) => p.id == planId ? updatedPlan : p).toList();
      state = state.copyWith(isLoading: false, plan: updatedPlan, planes: updatedPlanes);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> modifyWeeklyPlan({
    required String planId,
    required String instrucciones,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedPlan = await _api.modifyWeeklyPlan(
        planId: planId,
        instrucciones: instrucciones,
      );
      // Reemplazar en la lista de planes
      final updatedPlanes = state.planes.map((p) => p.id == planId ? updatedPlan : p).toList();
      state = state.copyWith(isLoading: false, plan: updatedPlan, planes: updatedPlanes);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteWeeklyPlan(String planId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.deleteWeeklyPlan(planId);
      final updatedPlanes = state.planes.where((p) => p.id != planId).toList();
      final isCurrentPlanDeleted = state.plan?.id == planId;
      if (isCurrentPlanDeleted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('active_weekly_plan_id');
      }
      state = state.copyWith(
        isLoading: false,
        plan: isCurrentPlanDeleted ? null : state.plan,
        clearPlan: isCurrentPlanDeleted,
        planes: updatedPlanes,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> activateWeeklyPlan(String planId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final activePlan = await _api.activateWeeklyPlan(planId);
      final updatedPlanes = state.planes.map((p) {
        if (p.id == planId) {
          return activePlan;
        } else {
          return p.copyWith(activo: false);
        }
      }).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_weekly_plan_id', activePlan.id);
      state = state.copyWith(isLoading: false, plan: activePlan, planes: updatedPlanes);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addExercisesToPlan({
    required String planId,
    required int diaSemana,
    required String bloqueTipo,
    required List<String> ejerciciosIds,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedPlan = await _api.addExercisesToPlan(
        planId: planId,
        diaSemana: diaSemana,
        bloqueTipo: bloqueTipo,
        ejerciciosIds: ejerciciosIds,
      );
      final updatedPlanes = state.planes.map((p) => p.id == planId ? updatedPlan : p).toList();
      state = state.copyWith(isLoading: false, plan: updatedPlan, planes: updatedPlanes);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> removeExerciseFromPlan({
    required String planId,
    required int diaSemana,
    required String bloqueTipo,
    required String nombreEjercicio,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedPlan = await _api.removeExerciseFromPlan(
        planId: planId,
        diaSemana: diaSemana,
        bloqueTipo: bloqueTipo,
        nombreEjercicio: nombreEjercicio,
      );
      final updatedPlanes = state.planes.map((p) => p.id == planId ? updatedPlan : p).toList();
      state = state.copyWith(isLoading: false, plan: updatedPlan, planes: updatedPlanes);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> evolvePlan({
    required String planId,
    required int semanasRotacion,
    required double porcentajeProgresion,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedPlan = await _api.evolvePlan(
        planId: planId,
        semanasRotacion: semanasRotacion,
        porcentajeProgresion: porcentajeProgresion,
      );
      final updatedPlanes = state.planes.map((p) => p.id == planId ? updatedPlan : p).toList();
      state = state.copyWith(isLoading: false, plan: updatedPlan, planes: updatedPlanes);
    } catch (e) {
      String errorMsg;
      if (e is DioException && e.type == DioExceptionType.receiveTimeout) {
        errorMsg = 'La IA tardó demasiado en responder. Inténtalo de nuevo.';
      } else if (e is DioException && e.response?.data != null) {
        final detail = e.response!.data;
        if (detail is Map && detail['detail'] is Map) {
          errorMsg = detail['detail']['message'] as String? ?? e.toString();
        } else if (detail is Map && detail['detail'] is String) {
          errorMsg = detail['detail'] as String;
        } else {
          errorMsg = e.toString();
        }
      } else {
        errorMsg = e.toString();
      }
      state = state.copyWith(isLoading: false, error: errorMsg);
    }
  }
}

final weeklyPlanProvider = StateNotifierProvider<WeeklyPlanNotifier, WeeklyPlanState>((ref) {
  final api = ref.watch(aiApiProvider);
  return WeeklyPlanNotifier(api);
});

class MachineState {
  final bool isLoading;
  final List<MaquinaGym> machines;
  final String? error;
  final String? uploadSuccess;

  const MachineState({
    this.isLoading = false,
    this.machines = const [],
    this.error,
    this.uploadSuccess,
  });

  MachineState copyWith({
    bool? isLoading,
    List<MaquinaGym>? machines,
    String? error,
    String? uploadSuccess,
  }) {
    return MachineState(
      isLoading: isLoading ?? this.isLoading,
      machines: machines ?? this.machines,
      error: error,
      uploadSuccess: uploadSuccess,
    );
  }
}

class MachineNotifier extends StateNotifier<MachineState> {
  final AIApi _api;

  MachineNotifier(this._api) : super(const MachineState());

  Future<void> loadMachines() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final machines = await _api.listMachines();
      state = state.copyWith(isLoading: false, machines: machines);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> uploadMachine({
    required String nombre,
    String? grupoMuscular,
    String? descripcionUso,
    File? file,
  }) async {
    state = state.copyWith(isLoading: true, error: null, uploadSuccess: null);
    try {
      final maquina = await _api.uploadMachine(
        nombre: nombre,
        grupoMuscular: grupoMuscular,
        descripcionUso: descripcionUso,
        file: file,
      );
      state = state.copyWith(
        isLoading: false,
        machines: [maquina, ...state.machines],
        uploadSuccess: 'Máquina "${maquina.nombre}" subida correctamente',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> deleteMachine(String machineId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.deleteMachine(machineId);
      state = state.copyWith(
        isLoading: false,
        machines: state.machines.where((m) => m.id != machineId).toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Map<String, dynamic>?> proposeMachine({
    required String descripcionUso,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.proposeMachine(descripcionUso: descripcionUso);
      state = state.copyWith(isLoading: false);
      return res;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void clearUploadSuccess() {
    state = state.copyWith(uploadSuccess: null);
  }
}

final machineProvider = StateNotifierProvider<MachineNotifier, MachineState>((ref) {
  final api = ref.watch(aiApiProvider);
  return MachineNotifier(api);
});