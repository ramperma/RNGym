class DashboardStats {
  final int semanalCompletados;
  final int semanalObjetivo;
  final double semanalPorcentaje;
  final bool hoyEntrenado;
  final String? hoyResumen;
  final int hoyEjercicios;
  final String? proximoDia;
  final String? proximoNombre;

  DashboardStats({
    required this.semanalCompletados,
    required this.semanalObjetivo,
    required this.semanalPorcentaje,
    required this.hoyEntrenado,
    this.hoyResumen,
    required this.hoyEjercicios,
    this.proximoDia,
    this.proximoNombre,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      semanalCompletados: json['semanal_completados'] as int? ?? 0,
      semanalObjetivo: json['semanal_objetivo'] as int? ?? 4,
      semanalPorcentaje: (json['semanal_porcentaje'] as num?)?.toDouble() ?? 0.0,
      hoyEntrenado: json['hoy_entrenado'] as bool? ?? false,
      hoyResumen: json['hoy_resumen'] as String?,
      hoyEjercicios: json['hoy_ejercicios'] as int? ?? 0,
      proximoDia: json['proximo_dia'] as String?,
      proximoNombre: json['proximo_nombre'] as String?,
    );
  }
}
