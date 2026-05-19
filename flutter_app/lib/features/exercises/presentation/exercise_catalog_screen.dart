import 'package:flutter/material.dart';

import '../data/exercise_api.dart';
import '../domain/exercise.dart';
import 'exercise_detail_screen.dart';

class ExerciseCatalogScreen extends StatefulWidget {
  const ExerciseCatalogScreen({super.key});

  @override
  State<ExerciseCatalogScreen> createState() => _ExerciseCatalogScreenState();
}

class _ExerciseCatalogScreenState extends State<ExerciseCatalogScreen> {
  final _api = ExerciseApi();
  late Future<List<Exercise>> _futureExercises;

  @override
  void initState() {
    super.initState();
    _futureExercises = _api.fetchExercises();
  }

  Future<void> _reload() async {
    setState(() {
      _futureExercises = _api.fetchExercises();
    });
    await _futureExercises;
  }

  Future<void> _openExercise(Exercise exercise) async {
    final shouldReload = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ExerciseDetailScreen(
          exerciseId: exercise.id,
          exerciseName: exercise.name,
        ),
      ),
    );

    if (shouldReload == true) {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrenamientos'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar catálogo',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<Exercise>>(
          future: _futureExercises,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _CatalogErrorState(
                error: snapshot.error.toString(),
                onRetry: _reload,
              );
            }

            final exercises = snapshot.data ?? [];
            if (exercises.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No hay ejercicios cargados todavía.'),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: exercises.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return Card(
                  child: InkWell(
                    onTap: () => _openExercise(exercise),
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F2747), Color(0xFF1F5BA7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                exercise.name.isNotEmpty
                                    ? exercise.name
                                        .substring(0, 1)
                                        .toUpperCase()
                                    : '?',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(exercise.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 5),
                                Text(
                                  '${exercise.muscleGroup} · ${exercise.difficulty} · ${exercise.equipment}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CatalogErrorState extends StatelessWidget {
  final String error;
  final Future<void> Function() onRetry;

  const _CatalogErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.cloud_off, size: 40),
                const SizedBox(height: 12),
                const Text('No se pudo cargar el catálogo.'),
                const SizedBox(height: 8),
                Text(error, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
