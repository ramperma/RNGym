import '../../../core/app_config.dart';
import '../../../core/env.dart';

class PlanDiaEjercicio {
  final String nombreEjercicio;
  final String? grupoMuscular;
  final int series;
  final String repeticiones;
  final int descansoSegundos;
  final String? rirORpe;
  final String? notas;
  final String? machineId;
  final String? machineNombre;
  final String? machineFotoUrl;

  String? get imageUrl {
    if (machineFotoUrl == null) return null;
    final activeBaseUrl = AppConfig.baseUrl ?? Env.apiBaseUrl;
    final baseUrl = activeBaseUrl.replaceAll('/api/v1', '');
    final cleanPath = machineFotoUrl!.replaceAll('backend/', '').replaceAll('backend/storage/', 'storage/');
    final path = cleanPath.startsWith('/') ? cleanPath : '/$cleanPath';
    if (path.contains('/api/v1/')) {
      return '$baseUrl$path';
    } else {
      final formattedPath = path.replaceAll('/storage/', '/api/v1/storage/');
      return '$baseUrl$formattedPath';
    }
  }

  PlanDiaEjercicio({
    required this.nombreEjercicio,
    this.grupoMuscular,
    this.series = 3,
    this.repeticiones = '10-12',
    this.descansoSegundos = 90,
    this.rirORpe,
    this.notas,
    this.machineId,
    this.machineNombre,
    this.machineFotoUrl,
  });

  factory PlanDiaEjercicio.fromJson(Map<String, dynamic> json) {
    return PlanDiaEjercicio(
      nombreEjercicio: json['nombre_ejercicio'] as String? ?? '',
      grupoMuscular: json['grupo_muscular'] as String?,
      series: json['series'] as int? ?? 3,
      repeticiones: json['repeticiones'] as String? ?? '10-12',
      descansoSegundos: json['descanso_segundos'] as int? ?? 90,
      rirORpe: json['rir_o_rpe'] as String?,
      notas: json['notas'] as String?,
      machineId: json['machine_id'] as String?,
      machineNombre: json['machine_nombre'] as String?,
      machineFotoUrl: json['machine_foto_url'] as String?,
    );
  }
}

class PlanDiaBloque {
  final String tipo;
  final String nombre;
  final int? duracionMinutos;
  final List<PlanDiaEjercicio> ejercicios;

  PlanDiaBloque({
    required this.tipo,
    required this.nombre,
    this.duracionMinutos,
    this.ejercicios = const [],
  });

  factory PlanDiaBloque.fromJson(Map<String, dynamic> json) {
    return PlanDiaBloque(
      tipo: json['tipo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      duracionMinutos: json['duracion_minutos'] as int?,
      ejercicios: (json['ejercicios'] as List<dynamic>?)
              ?.map((e) => PlanDiaEjercicio.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PlanDia {
  final int diaSemana;
  final String nombreDia;
  final String tipo;
  final List<PlanDiaBloque> bloques;
  final int descansoEntreBloquesMinutos;
  final int? tiempoTotalEstimadoMinutos;
  final String? notas;

  PlanDia({
    required this.diaSemana,
    required this.nombreDia,
    required this.tipo,
    this.bloques = const [],
    this.descansoEntreBloquesMinutos = 2,
    this.tiempoTotalEstimadoMinutos,
    this.notas,
  });

  bool get isWorkout => tipo == 'workout';
  bool get isRest => tipo == 'rest';
  bool get isActiveRecovery => tipo == 'active_recovery';

  factory PlanDia.fromJson(Map<String, dynamic> json) {
    return PlanDia(
      diaSemana: json['dia_semana'] as int? ?? 0,
      nombreDia: json['nombre_dia'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'rest',
      bloques: (json['bloques'] as List<dynamic>?)
              ?.map((e) => PlanDiaBloque.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      descansoEntreBloquesMinutos: json['descanso_entre_bloques_minutos'] as int? ?? 2,
      tiempoTotalEstimadoMinutos: json['tiempo_total_estimado_minutos'] as int?,
      notas: json['notas'] as String?,
    );
  }
}

class PlanSemanal {
  final String id;
  final String usuarioId;
  final String nombre;
  final String objetivo;
  final String nivel;
  final int duracionMaxMinutos;
  final int diasEntrenoObjetivo;
  final List<String> equipoDisponible;
  final List<String>? lesionesOLimitaciones;
  final PlanSemanalJSON planJson;
  final Map<String, dynamic>? metadataIa;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlanSemanal({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.objetivo,
    required this.nivel,
    this.duracionMaxMinutos = 75,
    this.diasEntrenoObjetivo = 4,
    this.equipoDisponible = const [],
    this.lesionesOLimitaciones,
    required this.planJson,
    this.metadataIa,
    this.activo = true,
    required this.createdAt,
    required this.updatedAt,
  });

  PlanSemanal copyWith({
    bool? activo,
  }) {
    return PlanSemanal(
      id: id,
      usuarioId: usuarioId,
      nombre: nombre,
      objetivo: objetivo,
      nivel: nivel,
      duracionMaxMinutos: duracionMaxMinutos,
      diasEntrenoObjetivo: diasEntrenoObjetivo,
      equipoDisponible: equipoDisponible,
      lesionesOLimitaciones: lesionesOLimitaciones,
      planJson: planJson,
      metadataIa: metadataIa,
      activo: activo ?? this.activo,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory PlanSemanal.fromJson(Map<String, dynamic> json) {
    return PlanSemanal(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      nombre: json['nombre'] as String,
      objetivo: json['objetivo'] as String,
      nivel: json['nivel'] as String? ?? 'intermedio',
      duracionMaxMinutos: json['duracion_max_minutos'] as int? ?? 75,
      diasEntrenoObjetivo: json['dias_entreno_objetivo'] as int? ?? 4,
      equipoDisponible: (json['equipo_disponible'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      lesionesOLimitaciones: (json['lesiones_o_limitaciones'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      planJson: PlanSemanalJSON.fromJson(json['plan_json'] as Map<String, dynamic>),
      metadataIa: json['metadata_ia'] as Map<String, dynamic>?,
      activo: json['activo'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class PlanSemanalJSON {
  final List<PlanDia> dias;
  final String? notaGeneral;

  PlanSemanalJSON({required this.dias, this.notaGeneral});

  factory PlanSemanalJSON.fromJson(Map<String, dynamic> json) {
    return PlanSemanalJSON(
      dias: (json['dias'] as List<dynamic>?)
              ?.map((e) => PlanDia.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      notaGeneral: json['nota_general'] as String?,
    );
  }
}