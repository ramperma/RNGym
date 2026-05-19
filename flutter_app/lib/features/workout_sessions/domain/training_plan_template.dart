enum BodyFocus {
  fullBody,
  torso,
  legs,
  core,
  push,
  pull,
  glutes,
}

enum TrainingObjective {
  loseFat,
  buildMuscle,
  strength,
  endurance,
  mobility,
}

enum ExperienceLevel {
  beginner,
  intermediate,
  advanced,
}

class TrainingSessionBlueprint {
  final String dayLabel;
  final String focus;
  final List<String> blocks;

  const TrainingSessionBlueprint({
    required this.dayLabel,
    required this.focus,
    required this.blocks,
  });
}

class TrainingPlanTemplate {
  final String id;
  final String name;
  final String description;
  final BodyFocus bodyFocus;
  final TrainingObjective objective;
  final ExperienceLevel experience;
  final int minPracticeDays;
  final int maxPracticeDays;
  final int durationWeeks;
  final int sessionMinutes;
  final List<String> tags;
  final List<TrainingSessionBlueprint> sessions;

  const TrainingPlanTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.bodyFocus,
    required this.objective,
    required this.experience,
    required this.minPracticeDays,
    required this.maxPracticeDays,
    required this.durationWeeks,
    required this.sessionMinutes,
    required this.tags,
    required this.sessions,
  });
}

String bodyFocusLabel(BodyFocus value) {
  switch (value) {
    case BodyFocus.fullBody:
      return 'Full body';
    case BodyFocus.torso:
      return 'Torso';
    case BodyFocus.legs:
      return 'Piernas';
    case BodyFocus.core:
      return 'Core';
    case BodyFocus.push:
      return 'Empuje';
    case BodyFocus.pull:
      return 'Traccion';
    case BodyFocus.glutes:
      return 'Gluteo';
  }
}

String objectiveLabel(TrainingObjective value) {
  switch (value) {
    case TrainingObjective.loseFat:
      return 'Perder grasa';
    case TrainingObjective.buildMuscle:
      return 'Ganar musculo';
    case TrainingObjective.strength:
      return 'Fuerza';
    case TrainingObjective.endurance:
      return 'Resistencia';
    case TrainingObjective.mobility:
      return 'Movilidad';
  }
}

String experienceLabel(ExperienceLevel value) {
  switch (value) {
    case ExperienceLevel.beginner:
      return 'Principiante';
    case ExperienceLevel.intermediate:
      return 'Intermedio';
    case ExperienceLevel.advanced:
      return 'Avanzado';
  }
}
