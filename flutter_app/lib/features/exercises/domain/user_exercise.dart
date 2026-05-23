import '../../../core/app_config.dart';
import '../../../core/env.dart';

class UserExercise {
  final String id;
  final String nombre;
  final String? grupoMuscular;
  final String? machineNombre;
  final String? machineFotoPath;
  final int series;
  final String? repeticiones;
  final int descansoSegundos;
  final String? rirOPe;
  final String? notas;

  String? get imageUrl {
    if (machineFotoPath == null) return null;
    final activeBaseUrl = AppConfig.baseUrl ?? Env.apiBaseUrl;
    final baseUrl = activeBaseUrl.replaceAll('/api/v1', '');
    final cleanPath = machineFotoPath!.replaceAll('backend/', '').replaceAll('backend/storage/', 'storage/');
    // Ensure we don't have double slashes after the domain unless it's the protocol
    final path = cleanPath.startsWith('/') ? cleanPath : '/$cleanPath';
    return '$baseUrl$path';
  }

  UserExercise({
    required this.id,
    required this.nombre,
    this.grupoMuscular,
    this.machineNombre,
    this.machineFotoPath,
    this.series = 3,
    this.repeticiones,
    this.descansoSegundos = 90,
    this.rirOPe,
    this.notas,
  });

  factory UserExercise.fromJson(Map<String, dynamic> json) {
    return UserExercise(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      grupoMuscular: json['grupo_muscular'] as String?,
      machineNombre: json['machine_nombre'] as String?,
      machineFotoPath: json['machine_foto_path'] as String?,
      series: json['series'] as int? ?? 3,
      repeticiones: json['repeticiones'] as String?,
      descansoSegundos: json['descanso_segundos'] as int? ?? 90,
      rirOPe: json['rir_o_pe'] as String?,
      notas: json['notas'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'grupo_muscular': grupoMuscular,
        'machine_nombre': machineNombre,
        'machine_foto_path': machineFotoPath,
        'series': series,
        'repeticiones': repeticiones,
        'descanso_segundos': descansoSegundos,
        'rir_o_pe': rirOPe,
        'notas': notas,
      };

  UserExercise copyWith({
    String? id,
    String? nombre,
    String? grupoMuscular,
    String? machineNombre,
    String? machineFotoPath,
    int? series,
    String? repeticiones,
    int? descansoSegundos,
    String? rirOPe,
    String? notas,
  }) {
    return UserExercise(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      grupoMuscular: grupoMuscular ?? this.grupoMuscular,
      machineNombre: machineNombre ?? this.machineNombre,
      machineFotoPath: machineFotoPath ?? this.machineFotoPath,
      series: series ?? this.series,
      repeticiones: repeticiones ?? this.repeticiones,
      descansoSegundos: descansoSegundos ?? this.descansoSegundos,
      rirOPe: rirOPe ?? this.rirOPe,
      notas: notas ?? this.notas,
    );
  }
}
