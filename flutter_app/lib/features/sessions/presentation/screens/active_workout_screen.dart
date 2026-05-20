import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../exercises/data/exercise_api.dart';
import '../../../exercises/domain/exercise.dart';
import '../../../ai/data/ai_api.dart';
import '../../../ai/presentation/providers/ai_provider.dart';
import '../../../weekly_plan/domain/plan_semanal.dart';
import '../providers/sessions_provider.dart';

class WorkoutSetRecord {
  final int setIndex;
  double weight;
  int reps;
  bool isCompleted;

  WorkoutSetRecord({
    required this.setIndex,
    this.weight = 20.0,
    this.reps = 10,
    this.isCompleted = false,
  });
}

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  PlanDia? _selectedDayPlan;
  final Map<String, List<WorkoutSetRecord>> _workoutRecords = {};
  List<Exercise> _exerciseCatalog = [];
  bool _isLoadingCatalog = true;

  // Timer fields
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isWorkoutActive = false;

  @override
  void initState() {
    super.initState();
    _loadCatalogAndPlan();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _isWorkoutActive = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final hStr = hours > 0 ? '${hours.toString().padLeft(2, '0')}:' : '';
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    return '$hStr$mStr:$sStr';
  }

  Future<void> _loadCatalogAndPlan() async {
    try {
      final catalog = await ExerciseApi().fetchExercises();
      if (mounted) {
        setState(() {
          _exerciseCatalog = catalog;
          _isLoadingCatalog = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCatalog = false;
        });
      }
    }

    // Load active weekly plan
    final planState = ref.read(weeklyPlanProvider);
    if (planState.plan == null) {
      await ref.read(weeklyPlanProvider.notifier).loadPlans(soloActivos: true);
    }

    final currentPlan = ref.read(weeklyPlanProvider).plan;
    if (currentPlan != null && currentPlan.planJson.dias.isNotEmpty) {
      final currentWeekdayIndex = DateTime.now().weekday - 1; // 0 = Lunes, ..., 6 = Domingo
      // Find a PlanDia that matches this weekday or fallback
      PlanDia? defaultDay;
      for (var d in currentPlan.planJson.dias) {
        if (d.diaSemana == currentWeekdayIndex) {
          defaultDay = d;
          break;
        }
      }
      defaultDay ??= currentPlan.planJson.dias.firstWhere(
        (d) => d.tipo == 'workout',
        orElse: () => currentPlan.planJson.dias.first,
      );

      _loadDayPlan(defaultDay);
    }
  }

  void _loadDayPlan(PlanDia dayPlan) {
    setState(() {
      _selectedDayPlan = dayPlan;
      _workoutRecords.clear();

      // Initialize sets for each exercise in this day
      for (var bloque in dayPlan.bloques) {
        for (var ex in bloque.ejercicios) {
          final targetReps = int.tryParse(ex.repeticiones.split('-').first) ?? 10;
          _workoutRecords[ex.nombreEjercicio] = List.generate(
            ex.series,
            (index) => WorkoutSetRecord(
              setIndex: index + 1,
              weight: 20.0,
              reps: targetReps,
              isCompleted: false,
            ),
          );
        }
      }

      if (!_isWorkoutActive) {
        _startTimer();
      }
    });
  }

  String _getExerciseIdByName(String name) {
    final match = _exerciseCatalog.firstWhere(
      (e) => e.name.toLowerCase().trim() == name.toLowerCase().trim(),
      orElse: () => _exerciseCatalog.isNotEmpty
          ? _exerciseCatalog.first
          : const Exercise(
              id: '00000000-0000-0000-0000-000000000000',
              name: '',
              muscleGroup: '',
              difficulty: '',
              equipment: '',
              description: '',
              instructions: '',
              defaultSets: 0,
              defaultReps: '',
            ),
    );
    return match.id;
  }

  void _finishWorkout() async {
    if (_selectedDayPlan == null) return;

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
      ),
    );

    try {
      final sessionApi = ref.read(sessionApiProvider);
      
      // 1. Create a completed training session
      final session = await sessionApi.createSession({
        'rutina_id': null,
        'nombre': 'Sesión: ${_selectedDayPlan!.nombreDia} (${_selectedDayPlan!.tipo == 'workout' ? 'Entreno' : 'Recuperación'})',
        'fecha_inicio': DateTime.now().subtract(Duration(seconds: _elapsedSeconds)).toIso8601String(),
        'fecha_fin': DateTime.now().toIso8601String(),
        'duracion_minutos': _elapsedSeconds ~/ 60,
        'estado': 'completada',
        'notas': 'Entrenamiento realizado con éxito siguiendo el plan de IA.',
      });

      // 2. Register sets for each exercise with completed sets
      int totalSetsCompleted = 0;
      double totalTonnage = 0;

      for (var bloque in _selectedDayPlan!.bloques) {
        for (var ex in bloque.ejercicios) {
          final records = _workoutRecords[ex.nombreEjercicio] ?? [];
          final completed = records.where((r) => r.isCompleted).toList();
          
          if (completed.isNotEmpty) {
            final exerciseId = _getExerciseIdByName(ex.nombreEjercicio);
            
            final payload = completed.map((r) => {
              'set_numero': r.setIndex,
              'peso_kg': r.weight,
              'repeticiones': r.reps,
              'rpe': 8,
              'completado': true,
            }).toList();

            await sessionApi.registerSets(session.id, exerciseId, payload);
            
            totalSetsCompleted += completed.length;
            for (var r in completed) {
              totalTonnage += r.weight * r.reps;
            }
          }
        }
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Stop timer
      _timer?.cancel();
      _isWorkoutActive = false;

      // Show gorgeous congratulations screen modal
      if (mounted) {
        _showSuccessDialog(totalSetsCompleted, totalTonnage);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar sesión: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog(int totalSets, double tonnage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Theme(
        data: ThemeData.dark(),
        child: AlertDialog(
          backgroundColor: const Color(0xFF131317),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6B00),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Colors.black, size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                '¡ENTRENAMIENTO COMPLETADO!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: const Color(0xFFFF6B00),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu sesión ha sido guardada en tu registro diario de PostgreSQL.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Tiempo', _formatDuration(_elapsedSeconds), Icons.timer),
                  _buildStatItem('Series', '$totalSets sets', Icons.fitness_center),
                  _buildStatItem('Volumen', '${tonnage.toInt()} kg', Icons.bolt),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ref.read(sessionsProvider.notifier).loadSessions();
                  context.go('/');
                },
                child: const Text('Excelente', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFF6B00), size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
      ],
    );
  }

  void _showChangeRoutineSheet() {
    final plan = ref.read(weeklyPlanProvider).plan;
    if (plan == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131317),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Seleccionar Rutina / Día',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: plan.planJson.dias.length,
                itemBuilder: (_, i) {
                  final dia = plan.planJson.dias[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        dia.tipo == 'workout' ? Icons.fitness_center_rounded : Icons.hotel_rounded,
                        color: dia.tipo == 'workout' ? const Color(0xFFFF6B00) : Colors.white24,
                      ),
                      title: Text(dia.nombreDia, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: Text(
                        dia.tipo == 'workout' ? 'Entrenamiento' : 'Descanso / Recuperación',
                        style: TextStyle(fontSize: 11, color: dia.tipo == 'workout' ? const Color(0xFFFF8C00) : Colors.white38),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _loadDayPlan(dia);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(weeklyPlanProvider);
    final plan = planState.plan;

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F12),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: Color(0xFFFF6B00), size: 22),
              const SizedBox(width: 8),
              Text(
                'Entrenar Hoy',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F0F12),
          elevation: 0,
          actions: [
            if (plan != null)
              TextButton.icon(
                icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFFFF6B00), size: 18),
                label: const Text('Cargar otro', style: TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: _showChangeRoutineSheet,
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: _isLoadingCatalog || planState.isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
            : plan == null
                ? _buildNoPlanView()
                : _buildWorkoutView(),
      ),
    );
  }

  Widget _buildNoPlanView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'No tienes un plan activo de IA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Para empezar a entrenar hoy, ve al Planificador IA en la pantalla principal para que diseñe tu plan personalizado.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.white54, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () => context.go('/ai'),
              icon: const Icon(Icons.auto_awesome, color: Colors.black),
              label: const Text('Ir al Planificador', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutView() {
    if (_selectedDayPlan == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)));
    }

    final isWorkout = _selectedDayPlan!.tipo == 'workout';

    return Column(
      children: [
        // Glowing status bar with active Timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: const Color(0xFF14141A),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedDayPlan!.nombreDia.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6B00), fontSize: 11, letterSpacing: 1),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedDayPlan!.tipo == 'workout' ? 'Rutina de Entrenamiento' : 'Descanso / Recuperación',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Color(0xFFFF6B00), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _formatDuration(_elapsedSeconds),
                      style: GoogleFonts.shareTechMono(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Main List
        Expanded(
          child: !isWorkout
              ? _buildRestDayView()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (var bloque in _selectedDayPlan!.bloques) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 16,
                              color: const Color(0xFFFF6B00),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              bloque.nombre.toUpperCase(),
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                      for (var ex in bloque.ejercicios) _buildExerciseExecutionCard(ex),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 100), // padding for bottom button
                  ],
                ),
        ),

        // Bottom sticky button
        if (isWorkout)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF14141A),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              onPressed: _finishWorkout,
              icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.black),
              label: const Text(
                'Finalizar Entrenamiento 🏆',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRestDayView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hotel_rounded, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              '¡Hoy toca Descanso!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tu plan te recomienda descansar o realizar una recuperación activa hoy para permitir que tus músculos crezcan y se recuperen.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.white54, height: 1.4),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: _showChangeRoutineSheet,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Cargar otro día'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showExerciseAIHelp(PlanDiaEjercicio ex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExerciseAIHelpSheet(
        ejercicio: ex,
        aiApi: ref.read(aiApiProvider),
      ),
    );
  }

  Widget _buildExerciseExecutionCard(PlanDiaEjercicio ex) {
    final records = _workoutRecords[ex.nombreEjercicio] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF15151B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header of Exercise
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex.nombreEjercicio,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                      ),
                      if (ex.machineNombre != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.settings_suggest_rounded, color: Color(0xFFFF8C00), size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'Máquina: ${ex.machineNombre}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFFFF8C00), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                      if (ex.notas != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          ex.notas!,
                          style: const TextStyle(fontSize: 11, color: Colors.white38),
                        ),
                      ],
                    ],
                  ),
                ),
                // AI help button
                GestureDetector(
                  onTap: () => _showExerciseAIHelp(ex),
                  child: Container(
                    margin: const EdgeInsets.only(left: 6, right: 6),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B00).withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFF6B00).withOpacity(0.35)),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFF6B00), size: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B00).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Meta: ${ex.series}x${ex.repeticiones}',
                    style: const TextStyle(color: Color(0xFFFF6B00), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),

          // Sets execution row headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 28, child: Text('SET', style: TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.bold))),
                const Expanded(flex: 3, child: Center(child: Text('PESO (KG)', style: TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.bold)))),
                const Expanded(flex: 3, child: Center(child: Text('REPS', style: TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.bold)))),
                const SizedBox(width: 44, child: Center(child: Text('LISTO', style: TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.bold)))),
              ],
            ),
          ),

          // Sets List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: records.length,
            itemBuilder: (_, i) {
              final record = records[i];
              return Container(
                color: record.isCompleted ? const Color(0xFF1E281E).withOpacity(0.3) : Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    // Set Number
                    SizedBox(
                      width: 28,
                      child: Text(
                        '#${record.setIndex}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: record.isCompleted ? Colors.green : Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    // Weight input with tactile buttons
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.white38, size: 16),
                            onPressed: record.isCompleted
                                ? null
                                : () {
                                    setState(() {
                                      if (record.weight > 2.5) record.weight -= 2.5;
                                    });
                                  },
                          ),
                          const SizedBox(width: 4),
                          Container(
                            constraints: const BoxConstraints(minWidth: 32),
                            alignment: Alignment.center,
                            child: Text(
                              '${record.weight % 1 == 0 ? record.weight.toInt() : record.weight}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: record.isCompleted ? Colors.green : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.add_circle_outline, color: Colors.white38, size: 16),
                            onPressed: record.isCompleted
                                ? null
                                : () {
                                    setState(() {
                                      record.weight += 2.5;
                                    });
                                  },
                          ),
                        ],
                      ),
                    ),

                    // Reps input with tactile buttons
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.white38, size: 16),
                            onPressed: record.isCompleted
                                ? null
                                : () {
                                    setState(() {
                                      if (record.reps > 1) record.reps--;
                                    });
                                  },
                          ),
                          const SizedBox(width: 4),
                          Container(
                            constraints: const BoxConstraints(minWidth: 24),
                            alignment: Alignment.center,
                            child: Text(
                              '${record.reps}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: record.isCompleted ? Colors.green : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.add_circle_outline, color: Colors.white38, size: 16),
                            onPressed: record.isCompleted
                                ? null
                                : () {
                                    setState(() {
                                      record.reps++;
                                    });
                                  },
                          ),
                        ],
                      ),
                    ),

                    // Completed Checkmark
                    SizedBox(
                      width: 48,
                      child: Center(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            setState(() {
                              record.isCompleted = !record.isCompleted;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: record.isCompleted ? Colors.green : Colors.white.withOpacity(0.04),
                              border: Border.all(
                                color: record.isCompleted ? Colors.transparent : Colors.white24,
                                width: 1.5,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: record.isCompleted
                                ? const Icon(Icons.check, color: Colors.black, size: 16)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─── AI Help bottom sheet ────────────────────────────────────────────────────

class _ChatMessage {
  final String role; // 'user' | 'ai'
  final String text;
  final File? image;
  const _ChatMessage({required this.role, required this.text, this.image});
}

class _ExerciseAIHelpSheet extends StatefulWidget {
  final PlanDiaEjercicio ejercicio;
  final AIApi aiApi;

  const _ExerciseAIHelpSheet({required this.ejercicio, required this.aiApi});

  @override
  State<_ExerciseAIHelpSheet> createState() => _ExerciseAIHelpSheetState();
}

class _ExerciseAIHelpSheetState extends State<_ExerciseAIHelpSheet> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchExplanation();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchExplanation() async {
    setState(() => _isLoading = true);
    try {
      final response = await widget.aiApi.exerciseHelp(
        nombreEjercicio: widget.ejercicio.nombreEjercicio,
        grupoMuscular: widget.ejercicio.grupoMuscular,
        machineNombre: widget.ejercicio.machineNombre,
        notasPlan: widget.ejercicio.notas,
      );
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(role: 'ai', text: response));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(role: 'ai', text: 'No se pudo cargar la explicación. Intenta de nuevo.'));
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final question = _textCtrl.text.trim();
    final image = _selectedImage;
    if (question.isEmpty && image == null) return;

    setState(() {
      _messages.add(_ChatMessage(
        role: 'user',
        text: question.isEmpty ? '📷 Foto adjunta' : question,
        image: image,
      ));
      _textCtrl.clear();
      _selectedImage = null;
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await widget.aiApi.exerciseHelp(
        nombreEjercicio: widget.ejercicio.nombreEjercicio,
        grupoMuscular: widget.ejercicio.grupoMuscular,
        machineNombre: widget.ejercicio.machineNombre,
        notasPlan: widget.ejercicio.notas,
        pregunta: question.isEmpty ? null : question,
        foto: image,
      );
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(role: 'ai', text: response));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(role: 'ai', text: 'Error: $e'));
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 1280);
    if (picked != null && mounted) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C24),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFFFF6B00)),
              title: const Text('Tomar foto', style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFFFF6B00)),
              title: const Text('Elegir de galería', style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.87,
      decoration: const BoxDecoration(
        color: Color(0xFF15151B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B00).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFF6B00), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Asistente IA', style: TextStyle(fontSize: 10, color: Color(0xFFFF6B00), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      Text(
                        widget.ejercicio.nombreEjercicio,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),

          // Messages area
          Expanded(
            child: _messages.isEmpty && _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFFF6B00)),
                        SizedBox(height: 14),
                        Text('Analizando el ejercicio...', style: TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == _messages.length) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF6B00))),
                          ),
                        );
                      }
                      return _buildBubble(_messages[i]);
                    },
                  ),
          ),

          // Image preview strip
          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF0F0F12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_selectedImage!, width: 52, height: 52, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Foto adjunta', style: TextStyle(color: Colors.white60, fontSize: 13))),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ],
              ),
            ),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(10, 8, 10, MediaQuery.of(context).viewInsets.bottom + 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F0F12),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.add_photo_alternate_rounded,
                      color: _selectedImage != null ? const Color(0xFFFF6B00) : Colors.white38,
                      size: 24,
                    ),
                    onPressed: _isLoading ? null : _showImageSourceSheet,
                    tooltip: 'Adjuntar foto',
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF15151B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: TextField(
                        controller: _textCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'Pregunta sobre el ejercicio...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.28), fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isLoading ? null : _sendMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _isLoading ? Colors.white10 : const Color(0xFFFF6B00),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        color: _isLoading ? Colors.white24 : Colors.black,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    final isAI = msg.role == 'ai';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isAI)
            Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B00).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFF6B00), size: 13),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isAI ? const Color(0xFF1E1E28) : const Color(0xFFFF6B00).withOpacity(0.13),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isAI ? Radius.zero : const Radius.circular(16),
                  bottomRight: isAI ? const Radius.circular(16) : Radius.zero,
                ),
                border: Border.all(
                  color: isAI ? Colors.white10 : const Color(0xFFFF6B00).withOpacity(0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.image != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(msg.image!, width: 200, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: isAI ? Colors.white : const Color(0xFFFFD0A0),
                      fontSize: 13,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isAI) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
