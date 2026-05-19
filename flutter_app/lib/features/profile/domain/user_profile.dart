class UserProfile {
  final String id;
  final String displayName;
  final int? age;
  final double? weightKg;
  final int? heightCm;
  final String? sex;
  final String? goal;
  final String injuries;
  final String medicalNotes;
  final bool aiPersonalizationEnabled;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.displayName,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.sex,
    required this.goal,
    required this.injuries,
    required this.medicalNotes,
    required this.aiPersonalizationEnabled,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      age: (json['age'] as num?)?.toInt(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      heightCm: (json['height_cm'] as num?)?.toInt(),
      sex: json['sex'] as String?,
      goal: json['goal'] as String?,
      injuries: json['injuries'] as String? ?? '',
      medicalNotes: json['medical_notes'] as String? ?? '',
      aiPersonalizationEnabled:
          json['ai_personalization_enabled'] as bool? ?? true,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class UserProfileUpdate {
  final String displayName;
  final int? age;
  final double? weightKg;
  final int? heightCm;
  final String? sex;
  final String? goal;
  final String injuries;
  final String medicalNotes;
  final bool aiPersonalizationEnabled;

  const UserProfileUpdate({
    required this.displayName,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.sex,
    required this.goal,
    required this.injuries,
    required this.medicalNotes,
    required this.aiPersonalizationEnabled,
  });

  Map<String, dynamic> toJson() {
    return {
      'display_name': displayName,
      'age': age,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'sex': sex,
      'goal': goal,
      'injuries': injuries,
      'medical_notes': medicalNotes,
      'ai_personalization_enabled': aiPersonalizationEnabled,
    };
  }
}

class AiStatus {
  final bool enabled;
  final String provider;
  final String status;
  final bool personalizationReady;
  final bool usesBackendCredentials;
  final bool clientCanStoreApiKey;

  const AiStatus({
    required this.enabled,
    required this.provider,
    required this.status,
    required this.personalizationReady,
    required this.usesBackendCredentials,
    required this.clientCanStoreApiKey,
  });

  factory AiStatus.fromJson(Map<String, dynamic> json) {
    return AiStatus(
      enabled: json['enabled'] as bool? ?? false,
      provider: json['provider'] as String? ?? 'backend-unconfigured',
      status: json['status'] as String? ?? 'disabled',
      personalizationReady: json['personalization_ready'] as bool? ?? false,
      usesBackendCredentials: json['uses_backend_credentials'] as bool? ?? true,
      clientCanStoreApiKey: json['client_can_store_api_key'] as bool? ?? false,
    );
  }
}
