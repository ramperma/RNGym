class EjercicioRutina {
  final String id;
  final String rutinaId;
  final String ejercicioId;
  final int orden;
  final int series;
  final String repeticiones;
  final int? descansoSegundos;
  final String? tempo;
  final String? notas;
  final DateTime createdAt;

  const EjercicioRutina({
    required this.id,
    required this.rutinaId,
    required this.ejercicioId,
    required this.orden,
    required this.series,
    required this.repeticiones,
    this.descansoSegundos,
    this.tempo,
    this.notas,
    required this.createdAt,
  });

  factory EjercicioRutina.fromJson(Map<String, dynamic> json) {
    return EjercicioRutina(
      id: json['id'] as String,
      rutinaId: json['rutina_id'] as String,
      ejercicioId: json['ejercicio_id'] as String,
      orden: json['orden'] as int,
      series: json['series'] as int,
      repeticiones: json['repeticiones'] as String,
      descansoSegundos: json['descanso_segundos'] as int?,
      tempo: json['tempo'] as String?,
      notas: json['notas'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class Rutina {
  final String id;
  final String nombre;
  final String? descripcion;
  final String tipoRutina;
  final String? dificultad;
  final int? duracionEstimadaMinutos;
  final int frecuenciaSemanal;
  final String? usuarioId;
  final String? creadorId;
  final bool esPublica;
  final String fuenteCreacion;
  final Map<String, dynamic>? metadataIa;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool activa;
  final List<EjercicioRutina> ejercicios;

  const Rutina({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.tipoRutina,
    this.dificultad,
    this.duracionEstimadaMinutos,
    this.frecuenciaSemanal = 3,
    this.usuarioId,
    this.creadorId,
    this.esPublica = false,
    this.fuenteCreacion = 'entrenador',
    this.metadataIa,
    required this.createdAt,
    required this.updatedAt,
    this.activa = true,
    this.ejercicios = const [],
  });

  factory Rutina.fromJson(Map<String, dynamic> json) {
    return Rutina(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      tipoRutina: json['tipo_rutina'] as String,
      dificultad: json['dificultad'] as String?,
      duracionEstimadaMinutos: json['duracion_estimada_minutos'] as int?,
      frecuenciaSemanal: json['frecuencia_semanal'] as int? ?? 3,
      usuarioId: json['usuario_id'] as String?,
      creadorId: json['creador_id'] as String?,
      esPublica: json['es_publica'] as bool? ?? false,
      fuenteCreacion: json['fuente_creacion'] as String? ?? 'entrenador',
      metadataIa: json['metadata_ia'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      activa: json['activa'] as bool? ?? true,
      ejercicios: (json['ejercicios'] as List<dynamic>?)
              ?.map((e) => EjercicioRutina.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'tipo_rutina': tipoRutina,
      'dificultad': dificultad,
      'duracion_estimada_minutos': duracionEstimadaMinutos,
      'frecuencia_semanal': frecuenciaSemanal,
      'es_publica': esPublica,
      'fuente_creacion': fuenteCreacion,
      'ejercicios': ejercicios.map((e) => {
        'ejercicio_id': e.ejercicioId,
        'orden': e.orden,
        'series': e.series,
        'repeticiones': e.repeticiones,
        'descanso_segundos': e.descansoSegundos,
        'tempo': e.tempo,
        'notas': e.notas,
      }).toList(),
    };
  }
}