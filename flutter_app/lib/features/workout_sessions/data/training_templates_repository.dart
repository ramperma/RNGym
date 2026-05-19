import '../domain/training_management_config.dart';
import '../domain/training_plan_template.dart';

class TrainingTemplatesRepository {
  const TrainingTemplatesRepository();

  List<TrainingPlanTemplate> filterTemplates({
    required TrainingManagementConfig config,
    BodyFocus? bodyFocus,
    TrainingObjective? objective,
    ExperienceLevel? experience,
    int? practiceDays,
  }) {
    final filtered = _templates.where((plan) {
      final bodyOk = bodyFocus == null || plan.bodyFocus == bodyFocus;
      final objectiveOk = objective == null || plan.objective == objective;
      final experienceOk = experience == null || plan.experience == experience;
      final practiceOk = practiceDays == null ||
          (practiceDays >= plan.minPracticeDays &&
              practiceDays <= plan.maxPracticeDays);
      return bodyOk && objectiveOk && experienceOk && practiceOk;
    }).toList();

    filtered.sort((a, b) {
      final scoreA = _scorePlan(a, config);
      final scoreB = _scorePlan(b, config);
      return scoreB.compareTo(scoreA);
    });
    return filtered;
  }

  int _scorePlan(
    TrainingPlanTemplate plan,
    TrainingManagementConfig config,
  ) {
    var score = 0;
    final intensity = config.intensityBias;
    final recovery = config.recoveryBias;

    if (config.coachPersonality == CoachPersonality.exigente &&
        plan.experience != ExperienceLevel.beginner) {
      score += 16;
    }

    if (config.coachPersonality == CoachPersonality.zen &&
        plan.objective == TrainingObjective.mobility) {
      score += 18;
    }

    if (intensity > recovery &&
        (plan.objective == TrainingObjective.strength ||
            plan.objective == TrainingObjective.buildMuscle)) {
      score += 12;
    }

    if (recovery > intensity &&
        (plan.objective == TrainingObjective.mobility ||
            plan.objective == TrainingObjective.endurance)) {
      score += 12;
    }

    final durationDelta = (plan.sessionMinutes - config.defaultSessionMinutes).abs();
    score += (40 - durationDelta).clamp(0, 40);

    if (config.strictSafetyMode && plan.experience == ExperienceLevel.beginner) {
      score += 8;
    }

    return score;
  }
}

const _templates = <TrainingPlanTemplate>[
  TrainingPlanTemplate(
    id: 'fb-fat-beginner',
    name: 'Reinicio Full Body',
    description: 'Plan base para perder grasa con tecnica simple y ritmo progresivo.',
    bodyFocus: BodyFocus.fullBody,
    objective: TrainingObjective.loseFat,
    experience: ExperienceLevel.beginner,
    minPracticeDays: 2,
    maxPracticeDays: 4,
    durationWeeks: 6,
    sessionMinutes: 45,
    tags: ['Baja complejidad', 'Cardio suave', 'Aprendizaje tecnico'],
    sessions: [
      TrainingSessionBlueprint(
        dayLabel: 'Dia 1',
        focus: 'Full body + core',
        blocks: [
          'Sentadilla goblet 3x12',
          'Press mancuernas 3x10',
          'Remo inclinado 3x12',
          'Plancha 3x35s',
        ],
      ),
      TrainingSessionBlueprint(
        dayLabel: 'Dia 2',
        focus: 'Cardio y movilidad',
        blocks: [
          'Circuito 18 min intensidad media',
          'Movilidad cadera y hombro 12 min',
        ],
      ),
    ],
  ),
  TrainingPlanTemplate(
    id: 'legs-strength-int',
    name: 'Piernas Potencia 8W',
    description: 'Aumento de fuerza en tren inferior con estructura por bloques.',
    bodyFocus: BodyFocus.legs,
    objective: TrainingObjective.strength,
    experience: ExperienceLevel.intermediate,
    minPracticeDays: 3,
    maxPracticeDays: 5,
    durationWeeks: 8,
    sessionMinutes: 65,
    tags: ['Fuerza', 'Sentadilla', 'Peso muerto tecnico'],
    sessions: [
      TrainingSessionBlueprint(
        dayLabel: 'Dia A',
        focus: 'Sentadilla dominante',
        blocks: [
          'Back squat 5x5',
          'Bulgarian split squat 3x10',
          'Curl femoral 4x10',
        ],
      ),
      TrainingSessionBlueprint(
        dayLabel: 'Dia B',
        focus: 'Bisagra de cadera',
        blocks: [
          'Peso muerto rumano 5x6',
          'Hip thrust 4x8',
          'Farmer carry 4x40m',
        ],
      ),
    ],
  ),
  TrainingPlanTemplate(
    id: 'torso-muscle-int',
    name: 'Torso Hipertrofia Smart',
    description: 'Construccion de masa muscular con volumen moderado y alta adherencia.',
    bodyFocus: BodyFocus.torso,
    objective: TrainingObjective.buildMuscle,
    experience: ExperienceLevel.intermediate,
    minPracticeDays: 3,
    maxPracticeDays: 6,
    durationWeeks: 10,
    sessionMinutes: 60,
    tags: ['Hipertrofia', 'Pecho', 'Espalda'],
    sessions: [
      TrainingSessionBlueprint(
        dayLabel: 'Dia Push',
        focus: 'Pecho, hombro, triceps',
        blocks: [
          'Press banca 4x8',
          'Press inclinado 3x10',
          'Press militar 3x8',
        ],
      ),
      TrainingSessionBlueprint(
        dayLabel: 'Dia Pull',
        focus: 'Espalda y biceps',
        blocks: [
          'Dominadas asistidas 4x8',
          'Remo con barra 4x10',
          'Curl alterno 3x12',
        ],
      ),
    ],
  ),
  TrainingPlanTemplate(
    id: 'core-mobility-beg',
    name: 'Core y Movilidad Base',
    description: 'Rutina segura para estabilidad lumbar y mejor rango articular.',
    bodyFocus: BodyFocus.core,
    objective: TrainingObjective.mobility,
    experience: ExperienceLevel.beginner,
    minPracticeDays: 2,
    maxPracticeDays: 5,
    durationWeeks: 5,
    sessionMinutes: 35,
    tags: ['Postura', 'Respiracion', 'Dolor lumbar'],
    sessions: [
      TrainingSessionBlueprint(
        dayLabel: 'Sesion 1',
        focus: 'Estabilidad central',
        blocks: [
          'Dead bug 3x10',
          'Bird dog 3x12',
          'Pallof press 3x12',
        ],
      ),
      TrainingSessionBlueprint(
        dayLabel: 'Sesion 2',
        focus: 'Movilidad global',
        blocks: [
          'CARS cadera 8 min',
          'Movilidad toracica 6 min',
          'Estiramientos activos 10 min',
        ],
      ),
    ],
  ),
  TrainingPlanTemplate(
    id: 'pull-endurance-adv',
    name: 'Pull Endurance Pro',
    description: 'Resistencia de traccion para usuarios avanzados y alta practica.',
    bodyFocus: BodyFocus.pull,
    objective: TrainingObjective.endurance,
    experience: ExperienceLevel.advanced,
    minPracticeDays: 4,
    maxPracticeDays: 6,
    durationWeeks: 9,
    sessionMinutes: 70,
    tags: ['Alta densidad', 'Agarre', 'Espalda'],
    sessions: [
      TrainingSessionBlueprint(
        dayLabel: 'Bloque 1',
        focus: 'Traccion vertical',
        blocks: [
          'Dominadas 6xAMRAP controlado',
          'Jalon pecho 4x15',
          'Face pull 4x20',
        ],
      ),
      TrainingSessionBlueprint(
        dayLabel: 'Bloque 2',
        focus: 'Traccion horizontal',
        blocks: [
          'Remo pendlay 5x8',
          'Remo polea 4x12',
          'Farmer hold 5x45s',
        ],
      ),
    ],
  ),
  TrainingPlanTemplate(
    id: 'glutes-muscle-beg',
    name: 'Glute Build Starter',
    description: 'Plan enfocado a gluteo para iniciacion con progresion semanal.',
    bodyFocus: BodyFocus.glutes,
    objective: TrainingObjective.buildMuscle,
    experience: ExperienceLevel.beginner,
    minPracticeDays: 2,
    maxPracticeDays: 4,
    durationWeeks: 7,
    sessionMinutes: 50,
    tags: ['Gluteo', 'Tecnica', 'Progresivo'],
    sessions: [
      TrainingSessionBlueprint(
        dayLabel: 'Dia 1',
        focus: 'Activacion y fuerza base',
        blocks: [
          'Hip thrust 4x10',
          'Peso muerto rumano 3x10',
          'Abduccion banda 3x20',
        ],
      ),
      TrainingSessionBlueprint(
        dayLabel: 'Dia 2',
        focus: 'Unilateral y estabilidad',
        blocks: [
          'Zancada atras 3x12',
          'Step up 3x10',
          'Plancha lateral 3x30s',
        ],
      ),
    ],
  ),
  TrainingPlanTemplate(
    id: 'push-strength-adv',
    name: 'Push Strength Peak',
    description: 'Ciclo avanzado de empuje con bloques de fuerza y potencia.',
    bodyFocus: BodyFocus.push,
    objective: TrainingObjective.strength,
    experience: ExperienceLevel.advanced,
    minPracticeDays: 4,
    maxPracticeDays: 6,
    durationWeeks: 8,
    sessionMinutes: 75,
    tags: ['Potencia', 'Press', 'Alta carga'],
    sessions: [
      TrainingSessionBlueprint(
        dayLabel: 'Sesion pesada',
        focus: 'Press principal',
        blocks: [
          'Press banca 6x4',
          'Press militar 5x5',
          'Fondos lastrados 4x6',
        ],
      ),
      TrainingSessionBlueprint(
        dayLabel: 'Sesion volumen',
        focus: 'Hipertrofia de soporte',
        blocks: [
          'Press inclinado mancuernas 4x10',
          'Elevaciones laterales 4x15',
          'Extension triceps 4x12',
        ],
      ),
    ],
  ),
];
