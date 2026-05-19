class SesionEntreno {
  final String id;
  final String usuarioId;
  final String? rutinaId;
  final String? nombre;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final int? duracionMinutos;
  final String estado;
  final int? kcalEstimadas;
  final int? kcalReal;
  final String? notas;
  final DateTime createdAt;
  final List<SesionEjercicioRegistro> registros;

  const SesionEntreno({
    required this.id,
    required this.usuarioId,
    this.rutinaId,
    this.nombre,
    required this.fechaInicio,
    this.fechaFin,
    this.duracionMinutos,
    this.estado = 'planificada',
    this.kcalEstimadas,
    this.kcalReal,
    this.notas,
    required this.createdAt,
    this.registros = const [],
  });

  factory SesionEntreno.fromJson(Map<String, dynamic> json) {
    return SesionEntreno(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      rutinaId: json['rutina_id'] as String?,
      nombre: json['nombre'] as String?,
      fechaInicio: DateTime.parse(json['fecha_inicio'] as String),
      fechaFin: json['fecha_fin'] != null ? DateTime.parse(json['fecha_fin'] as String) : null,
      duracionMinutos: json['duracion_minutos'] as int?,
      estado: json['estado'] as String? ?? 'planificada',
      kcalEstimadas: json['kcal_estimadas'] as int?,
      kcalReal: json['kcal_real'] as int?,
      notas: json['notas'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      registros: (json['registros'] as List<dynamic>?)
              ?.map((e) => SesionEjercicioRegistro.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SesionEjercicioRegistro {
  final String id;
  final String sesionId;
  final String ejercicioId;
  final int setNumero;
  final double? pesoKg;
  final int? repeticiones;
  final int? rpe;
  final bool completado;
  final String? notas;
  final DateTime createdAt;

  const SesionEjercicioRegistro({
    required this.id,
    required this.sesionId,
    required this.ejercicioId,
    required this.setNumero,
    this.pesoKg,
    this.repeticiones,
    this.rpe,
    this.completado = true,
    this.notas,
    required this.createdAt,
  });

  factory SesionEjercicioRegistro.fromJson(Map<String, dynamic> json) {
    return SesionEjercicioRegistro(
      id: json['id'] as String,
      sesionId: json['sesion_id'] as String,
      ejercicioId: json['ejercicio_id'] as String,
      setNumero: json['set_numero'] as int,
      pesoKg: (json['peso_kg'] as num?)?.toDouble(),
      repeticiones: json['repeticiones'] as int?,
      rpe: json['rpe'] as int?,
      completado: json['completado'] as bool? ?? true,
      notas: json['notas'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}