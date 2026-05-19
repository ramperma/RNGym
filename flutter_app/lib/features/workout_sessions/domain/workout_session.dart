class WorkoutSession {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final DateTime performedAt;
  final int setsCompleted;
  final String repsCompleted;
  final String notes;

  const WorkoutSession({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.performedAt,
    required this.setsCompleted,
    required this.repsCompleted,
    required this.notes,
  });

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] as String? ?? '',
      exerciseId: json['exercise_id'] as String? ?? '',
      exerciseName: json['exercise_name'] as String? ?? 'Ejercicio',
      performedAt: DateTime.tryParse(json['performed_at'] as String? ?? '') ??
          DateTime.now(),
      setsCompleted: json['sets_completed'] as int? ?? 0,
      repsCompleted: json['reps_completed'] as String? ?? '-',
      notes: json['notes'] as String? ?? '',
    );
  }
}
