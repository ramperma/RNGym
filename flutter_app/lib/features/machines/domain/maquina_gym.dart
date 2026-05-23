import '../../../core/app_config.dart';
import '../../../core/env.dart';

class MaquinaGym {
  final String id;
  final String usuarioId;
  final String nombre;
  final String? fotoPath;
  final String? descripcionUso;
  final String? grupoMuscular;
  final DateTime createdAt;
  final DateTime updatedAt;

  String? get imageUrl {
    if (fotoPath == null) return null;
    final activeBaseUrl = AppConfig.baseUrl ?? Env.apiBaseUrl;
    final baseUrl = activeBaseUrl.replaceAll('/api/v1', '');
    final cleanPath = fotoPath!.replaceAll('backend/', '').replaceAll('backend/storage/', 'storage/');
    final path = cleanPath.startsWith('/') ? cleanPath : '/$cleanPath';
    if (path.contains('/api/v1/')) {
      return '$baseUrl$path';
    } else {
      final formattedPath = path.replaceAll('/storage/', '/api/v1/storage/');
      return '$baseUrl$formattedPath';
    }
  }

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