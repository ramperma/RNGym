class User {
  final String id;
  final String email;
  final String nombre;
  final String? apellidos;
  final String rol;
  final String idioma;
  final String timezone;
  final bool emailVerificado;
  final DateTime? fechaAlta;
  final bool estaActivo;
  final String? openaiApiKey;
  final String? deepseekApiKey;
  final String? minimaxApiKey;
  final String? proveedorIaPreferido;
  final int maxRutinas;
  final int maxSesionesSemana;

  const User({
    required this.id,
    required this.email,
    required this.nombre,
    this.apellidos,
    required this.rol,
    this.idioma = 'es',
    this.timezone = 'Europe/Madrid',
    this.emailVerificado = false,
    this.fechaAlta,
    this.estaActivo = true,
    this.openaiApiKey,
    this.deepseekApiKey,
    this.minimaxApiKey,
    this.proveedorIaPreferido,
    this.maxRutinas = 5,
    this.maxSesionesSemana = 7,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      nombre: json['nombre'] as String,
      apellidos: json['apellidos'] as String?,
      rol: json['rol'] as String,
      idioma: json['idioma'] as String? ?? 'es',
      timezone: json['timezone'] as String? ?? 'Europe/Madrid',
      emailVerificado: json['email_verificado'] as bool? ?? false,
      fechaAlta: json['fecha_alta'] != null
          ? DateTime.parse(json['fecha_alta'] as String)
          : null,
      estaActivo: json['esta_activo'] as bool? ?? true,
      openaiApiKey: json['openai_api_key'] as String?,
      deepseekApiKey: json['deepseek_api_key'] as String?,
      minimaxApiKey: json['minimax_api_key'] as String?,
      proveedorIaPreferido: json['proveedor_ia_preferido'] as String?,
      maxRutinas: json['max_rutinas'] as int? ?? 5,
      maxSesionesSemana: json['max_sesiones_semana'] as int? ?? 7,
    );
  }

  bool get isAdmin => rol == 'admin';
  bool get isAuthenticated => true;
}