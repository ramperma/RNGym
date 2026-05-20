import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      );
      state = state.copyWith(isLoading: false, plan: plan, planes: [plan, ...state.planes]);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadPlans({int skip = 0, int limit = 20, bool soloActivos = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final planes = await _api.listPlans(skip: skip, limit: limit, soloActivos: soloActivos);
      PlanSemanal? activePlan;
      try {
        activePlan = planes.firstWhere((p) => p.activo);
      } catch (_) {
        activePlan = planes.isNotEmpty ? planes.first : null;
      }
      state = state.copyWith(
        isLoading: false,
        planes: planes,
        plan: activePlan,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadPlan(String planId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final plan = await _api.getPlan(planId);
      state = state.copyWith(isLoading: false, plan: plan);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearPlan() {
    state = state.copyWith(clearPlan: true);
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
      state = state.copyWith(isLoading: false, plan: activePlan, planes: updatedPlanes);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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