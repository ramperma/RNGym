import 'package:flutter/material.dart';

import '../../exercises/presentation/exercise_detail_screen.dart';
import '../data/workout_session_api.dart';
import '../domain/workout_session.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  final _api = WorkoutSessionApi();
  late Future<List<WorkoutSession>> _futureSessions;

  @override
  void initState() {
    super.initState();
    _futureSessions = _api.fetchSessions();
  }

  Future<void> _reload() async {
    setState(() {
      _futureSessions = _api.fetchSessions();
    });
    await _futureSessions;
  }

  void _openSessionExercise(WorkoutSession session) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExerciseDetailScreen(
          exerciseId: session.exerciseId,
          exerciseName: session.exerciseName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial y seguimiento'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar historial',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<WorkoutSession>>(
          future: _futureSessions,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _HistoryErrorState(
                error: snapshot.error.toString(),
                onRetry: _reload,
              );
            }

            final sessions = snapshot.data ?? [];
            if (sessions.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Todavía no hay sesiones registradas.'),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final session = sessions[index];
                return Card(
                  child: InkWell(
                    onTap: () => _openSessionExercise(session),
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F2FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.history),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.exerciseName,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${session.setsCompleted} series · ${session.repsCompleted} reps',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  session.notes.isEmpty
                                      ? 'Sin notas'
                                      : session.notes,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_formatDate(session.performedAt)),
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

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
  }
}

class _HistoryErrorState extends StatelessWidget {
  final String error;
  final Future<void> Function() onRetry;

  const _HistoryErrorState({required this.error, required this.onRetry});

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
                const Text('No se pudo cargar el historial.'),
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
