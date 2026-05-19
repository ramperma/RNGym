enum CoachPersonality {
  motivador,
  tecnico,
  exigente,
  zen,
}

enum CoachTone {
  cercano,
  directo,
  profesional,
  inspirador,
}

class TrainingManagementConfig {
  final double aiTemperature;
  final int aiCreativity;
  final int intensityBias;
  final int recoveryBias;
  final int defaultSessionMinutes;
  final CoachPersonality coachPersonality;
  final CoachTone coachTone;
  final bool strictSafetyMode;
  final bool includeNutritionTips;
  final bool explainTechnique;
  final bool adaptiveProgression;

  const TrainingManagementConfig({
    required this.aiTemperature,
    required this.aiCreativity,
    required this.intensityBias,
    required this.recoveryBias,
    required this.defaultSessionMinutes,
    required this.coachPersonality,
    required this.coachTone,
    required this.strictSafetyMode,
    required this.includeNutritionTips,
    required this.explainTechnique,
    required this.adaptiveProgression,
  });

  factory TrainingManagementConfig.defaults() {
    return const TrainingManagementConfig(
      aiTemperature: 0.35,
      aiCreativity: 50,
      intensityBias: 60,
      recoveryBias: 40,
      defaultSessionMinutes: 55,
      coachPersonality: CoachPersonality.tecnico,
      coachTone: CoachTone.profesional,
      strictSafetyMode: true,
      includeNutritionTips: true,
      explainTechnique: true,
      adaptiveProgression: true,
    );
  }

  TrainingManagementConfig copyWith({
    double? aiTemperature,
    int? aiCreativity,
    int? intensityBias,
    int? recoveryBias,
    int? defaultSessionMinutes,
    CoachPersonality? coachPersonality,
    CoachTone? coachTone,
    bool? strictSafetyMode,
    bool? includeNutritionTips,
    bool? explainTechnique,
    bool? adaptiveProgression,
  }) {
    return TrainingManagementConfig(
      aiTemperature: aiTemperature ?? this.aiTemperature,
      aiCreativity: aiCreativity ?? this.aiCreativity,
      intensityBias: intensityBias ?? this.intensityBias,
      recoveryBias: recoveryBias ?? this.recoveryBias,
      defaultSessionMinutes:
          defaultSessionMinutes ?? this.defaultSessionMinutes,
      coachPersonality: coachPersonality ?? this.coachPersonality,
      coachTone: coachTone ?? this.coachTone,
      strictSafetyMode: strictSafetyMode ?? this.strictSafetyMode,
      includeNutritionTips: includeNutritionTips ?? this.includeNutritionTips,
      explainTechnique: explainTechnique ?? this.explainTechnique,
      adaptiveProgression: adaptiveProgression ?? this.adaptiveProgression,
    );
  }
}

String coachPersonalityLabel(CoachPersonality value) {
  switch (value) {
    case CoachPersonality.motivador:
      return 'Motivador';
    case CoachPersonality.tecnico:
      return 'Tecnico';
    case CoachPersonality.exigente:
      return 'Exigente';
    case CoachPersonality.zen:
      return 'Zen';
  }
}

String coachToneLabel(CoachTone value) {
  switch (value) {
    case CoachTone.cercano:
      return 'Cercano';
    case CoachTone.directo:
      return 'Directo';
    case CoachTone.profesional:
      return 'Profesional';
    case CoachTone.inspirador:
      return 'Inspirador';
  }
}
