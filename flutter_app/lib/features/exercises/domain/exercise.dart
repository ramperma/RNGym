class Exercise {
  final String id;
  final String name;
  final String muscleGroup;
  final String difficulty;
  final String equipment;
  final String description;
  final String instructions;
  final int defaultSets;
  final String defaultReps;

  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.difficulty,
    required this.equipment,
    required this.description,
    required this.instructions,
    required this.defaultSets,
    required this.defaultReps,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Sin nombre',
      muscleGroup: json['muscle_group'] as String? ?? '-',
      difficulty: json['difficulty'] as String? ?? '-',
      equipment: json['equipment'] as String? ?? '-',
      description: json['description'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      defaultSets: json['default_sets'] as int? ?? 0,
      defaultReps: json['default_reps'] as String? ?? '-',
    );
  }
}
