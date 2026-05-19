class MaquinaGym {
  final String id;
  final String usuarioId;
  final String nombre;
  final String? fotoPath;
  final String? descripcionUso;
  final String? grupoMuscular;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaquinaGym({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    this.fotoPath,
    this.descripcionUso,
    this.grupoMuscular,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MaquinaGym.fromJson(Map<String, dynamic> json) {
    return MaquinaGym(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      nombre: json['nombre'] as String,
      fotoPath: json['foto_path'] as String?,
      descripcionUso: json['descripcion_uso'] as String?,
      grupoMuscular: json['grupo_muscular'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}