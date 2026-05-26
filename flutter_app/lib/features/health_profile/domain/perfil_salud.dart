class PerfilSalud {
  final String id;
  final String usuarioId;
  final DateTime? fechaNacimiento;
  final String? sexoBiologico;
  final double? alturaCm;
  final double? pesoActualKg;
  final double? pesoDeseadoKg;
  final double? porcentajeGrasa;
  final double? porcentajeMusculo;
  final int? tmbKcal;
  final double factorActividad;
  final List<String>? lesiones;
  final List<String>? condicionesMedicas;
  final List<String>? alergias;
  final List<String>? medicamentos;
  final List<String>? restriccionesNutricionales;
  final String? objetivoPrincipal;
  final String? objetivoDetalle;
  final bool consentimientoSalud;
  final DateTime? fechaConsentimientoSalud;
  final DateTime? fechaUltimaActualizacion;
  final DateTime createdAt;
  final int semanasRotacion;
  final double porcentajeProgresion;

  const PerfilSalud({
    required this.id,
    required this.usuarioId,
    this.fechaNacimiento,
    this.sexoBiologico,
    this.alturaCm,
    this.pesoActualKg,
    this.pesoDeseadoKg,
    this.porcentajeGrasa,
    this.porcentajeMusculo,
    this.tmbKcal,
    this.factorActividad = 1.2,
    this.lesiones,
    this.condicionesMedicas,
    this.alergias,
    this.medicamentos,
    this.restriccionesNutricionales,
    this.objetivoPrincipal,
    this.objetivoDetalle,
    this.consentimientoSalud = false,
    this.fechaConsentimientoSalud,
    this.fechaUltimaActualizacion,
    required this.createdAt,
    this.semanasRotacion = 3,
    this.porcentajeProgresion = 5.0,
  });

  factory PerfilSalud.fromJson(Map<String, dynamic> json) {
    return PerfilSalud(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      fechaNacimiento: json['fecha_nacimiento'] != null
          ? DateTime.parse(json['fecha_nacimiento'] as String)
          : null,
      sexoBiologico: json['sexo_biologico'] as String?,
      alturaCm: (json['altura_cm'] as num?)?.toDouble(),
      pesoActualKg: (json['peso_actual_kg'] as num?)?.toDouble(),
      pesoDeseadoKg: (json['peso_deseado_kg'] as num?)?.toDouble(),
      porcentajeGrasa: (json['porcentaje_grasa'] as num?)?.toDouble(),
      porcentajeMusculo: (json['porcentaje_musculo'] as num?)?.toDouble(),
      tmbKcal: json['tmb_kcal'] as int?,
      factorActividad: (json['factor_actividad'] as num?)?.toDouble() ?? 1.2,
      lesiones: (json['lesiones'] as List<dynamic>?)?.cast<String>(),
      condicionesMedicas: (json['condiciones_medicas'] as List<dynamic>?)?.cast<String>(),
      alergias: (json['alergias'] as List<dynamic>?)?.cast<String>(),
      medicamentos: (json['medicamentos'] as List<dynamic>?)?.cast<String>(),
      restriccionesNutricionales: (json['restricciones_nutricionales'] as List<dynamic>?)?.cast<String>(),
      objetivoPrincipal: json['objetivo_principal'] as String?,
      objetivoDetalle: json['objetivo_detalle'] as String?,
      consentimientoSalud: json['consentimiento_salud'] as bool? ?? false,
      fechaConsentimientoSalud: json['fecha_consentimiento_salud'] != null
          ? DateTime.parse(json['fecha_consentimiento_salud'] as String)
          : null,
      fechaUltimaActualizacion: json['fecha_ultima_actualizacion'] != null
          ? DateTime.parse(json['fecha_ultima_actualizacion'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      semanasRotacion: (json['semanas_rotacion'] as int?) ?? 3,
      porcentajeProgresion: (json['porcentaje_progresion'] as num?)?.toDouble() ?? 5.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fecha_nacimiento': fechaNacimiento?.toIso8601String().split('T')[0],
      'sexo_biologico': sexoBiologico,
      'altura_cm': alturaCm,
      'peso_actual_kg': pesoActualKg,
      'peso_deseado_kg': pesoDeseadoKg,
      'porcentaje_grasa': porcentajeGrasa,
      'porcentaje_musculo': porcentajeMusculo,
      'tmb_kcal': tmbKcal,
      'factor_actividad': factorActividad,
      'lesiones': lesiones,
      'condiciones_medicas': condicionesMedicas,
      'alergias': alergias,
      'medicamentos': medicamentos,
      'restricciones_nutricionales': restriccionesNutricionales,
      'objetivo_principal': objetivoPrincipal,
      'objetivo_detalle': objetivoDetalle,
      'consentimiento_salud': consentimientoSalud,
      'semanas_rotacion': semanasRotacion,
      'porcentaje_progresion': porcentajeProgresion,
    };
  }
}