import 'package:flutter/material.dart';

import '../data/exercise_api.dart';
import '../domain/exercise.dart';
import '../../workout_sessions/data/workout_session_api.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final String exerciseId;
  final String exerciseName;

  const ExerciseDetailScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  final _api = ExerciseApi();
  final _sessionApi = WorkoutSessionApi();
  late Future<Exercise> _futureExercise;
  bool _savingSession = false;

  @override
  void initState() {
    super.initState();
    _futureExercise = _api.fetchExerciseDetail(widget.exerciseId);
  }

  Future<void> _saveQuickSession(Exercise exercise) async {
    setState(() {
      _savingSession = true;
    });

    try {
      final session = await _sessionApi.createQuickSession(
        exerciseId: exercise.id,
        setsCompleted: exercise.defaultSets,
        repsCompleted: exercise.defaultReps,
        notes: 'Guardada desde Flutter en Raspberry.',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sesión guardada: ${session.exerciseName}')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la sesión: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingSession = false;
        });
      }
    }
  }

  Future<void> _reload() async {
    setState(() {
      _futureExercise = _api.fetchExerciseDetail(widget.exerciseId);
    });
    await _futureExercise;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseName),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar detalle',
          ),
        ],
      ),
      body: FutureBuilder<Exercise>(
        future: _futureExercise,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 42),
                    const SizedBox(height: 12),
                    Text(snapshot.error.toString(),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _reload,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final exercise = snapshot.data;
          if (exercise == null) {
            return const Center(child: Text('No se encontró el ejercicio.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise.name,
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                              label: 'Grupo', value: exercise.muscleGroup),
                          _InfoChip(label: 'Nivel', value: exercise.difficulty),
                          _InfoChip(label: 'Equipo', value: exercise.equipment),
                          _InfoChip(
                              label: 'Series',
                              value: exercise.defaultSets.toString()),
                          _InfoChip(label: 'Reps', value: exercise.defaultReps),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Descripción',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(exercise.description),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cómo hacerlo',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(exercise.instructions),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      _savingSession ? null : () => _saveQuickSession(exercise),
                  icon: _savingSession
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                      _savingSession ? 'Guardando...' : 'Guardar sesión real'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}
