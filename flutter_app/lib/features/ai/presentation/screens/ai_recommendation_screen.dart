import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../weekly_plan/domain/plan_semanal.dart';
import '../../../exercises/presentation/providers/user_exercises_provider.dart';
import '../providers/ai_provider.dart';

class AIRecommendationScreen extends ConsumerStatefulWidget {
  const AIRecommendationScreen({super.key});

  @override
  ConsumerState<AIRecommendationScreen> createState() => _AIRecommendationScreenState();
}

class _AIRecommendationScreenState extends ConsumerState<AIRecommendationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _modInstructionsCtrl = TextEditingController();
  final _notasAdicionalesCtrl = TextEditingController();
  
  String _objetivo = 'hipertrofia';
  int _diasPorSemana = 4;
  int _duracionMax = 75;
  String _nivelExperiencia = 'intermedio';
  final List<String> _equiposDisponibles = ['barra', 'mancuernas', 'polea', 'leg_press', 'smith'];
  final List<String> _selectedMachines = [];

  final List<String> _diasSemanaNombres = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  final List<String> _diasSeleccionados = [];
  final List<String> _lesionesSeleccionadas = [];
  final List<String> _prefEquipamientoSeleccionados = [];

  bool _personalizarProporcion = false;
  int _porcentajeMaquinasGuiadas = 50;
  int _porcentajePesoLibre = 50;
  bool _usarMisMaquinas = true;
  int _minEjerciciosPorSesion = 4;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(machineProvider.notifier).loadMachines();
      ref.read(weeklyPlanProvider.notifier).loadPlans();
    });
  }

  @override
  void dispose() {
    _modInstructionsCtrl.dispose();
    _notasAdicionalesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(weeklyPlanProvider);
    final machineState = ref.watch(machineProvider);

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F12),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B00),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF1E1E24),
          error: Color(0xFFFF3366),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF19191F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
          ),
          elevation: 4,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.auto_awesome, color: const Color(0xFFFF6B00), size: 22),
              const SizedBox(width: 8),
              const Text(
                'Plan IA Semanal',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F0F12),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.history_rounded, color: Colors.white),
              onPressed: () => _showPlansSheet(context, planState.planes),
              tooltip: 'Ver planes guardados',
            ),
            IconButton(
              icon: const Icon(Icons.settings_suggest_rounded, color: Colors.white),
              onPressed: () => _showMachinesSheet(context),
              tooltip: 'Gestionar máquinas',
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: Colors.white.withOpacity(0.08),
              height: 1,
            ),
          ),
        ),
        body: Stack(
          children: [
            planState.plan != null
                ? _buildPlanView(planState.plan!, planState.isLoading)
                : planState.isLoading && !planState.planes.contains(planState.plan)
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Color(0xFFFF6B00)),
                            SizedBox(height: 16),
                            Text(
                              'Diseñando tu plan con IA...',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white70),
                            ),
                          ],
                        ),
                      )
                    : _buildForm(context, machineState, planState),
            if (planState.isLoading && planState.plan != null)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFFFF6B00)),
                      SizedBox(height: 16),
                      Text(
                        'Ajustando tu rutina con IA...',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, MachineState machineState, WeeklyPlanState planState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFFF6B00).withOpacity(0.15), const Color(0xFF00E5FF).withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFF6B00).withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.flash_on_rounded, color: Color(0xFFFF6B00), size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Entrenamiento Científico con IA',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Generamos una planificación semanal estructurada, equilibrando descansos y grupos musculares de forma óptima.',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Objetivo principal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _objetivo,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0F0F12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'fuerza', child: Text('Fuerza Máxima')),
                        DropdownMenuItem(value: 'hipertrofia', child: Text('Masa Muscular (Hipertrofia)')),
                        DropdownMenuItem(value: 'definicion', child: Text('Definición / Quema Grasa')),
                        DropdownMenuItem(value: 'cardio', child: Text('Resistencia / Cardio')),
                        DropdownMenuItem(value: 'funcional', child: Text('Entrenamiento Funcional')),
                      ],
                      onChanged: (v) => setState(() => _objetivo = v!),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Días de entreno por semana', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                        Text('$_diasPorSemana días', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6B00))),
                      ],
                    ),
                    Slider(
                      value: _diasPorSemana.toDouble(),
                      min: 1,
                      max: 6,
                      activeColor: const Color(0xFFFF6B00),
                      inactiveColor: Colors.white.withOpacity(0.1),
                      divisions: 5,
                      onChanged: (v) {
                        setState(() {
                          _diasPorSemana = v.round();
                          _diasSeleccionados.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text('Días específicos que prefieres entrenar (opcional)', style: TextStyle(fontSize: 12, color: Colors.white60)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _diasSemanaNombres.map((day) {
                        final isSelected = _diasSeleccionados.contains(day);
                        return FilterChip(
                          label: Text(day.substring(0, 3)),
                          selected: isSelected,
                          selectedColor: const Color(0xFFFF6B00),
                          backgroundColor: const Color(0xFF0F0F12),
                          side: BorderSide(color: isSelected ? Colors.transparent : Colors.white12),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 11,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _diasSeleccionados.add(day);
                              } else {
                                _diasSeleccionados.remove(day);
                              }
                              if (_diasSeleccionados.isNotEmpty) {
                                _diasPorSemana = _diasSeleccionados.length;
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Duración máxima de sesión', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                        Text('$_duracionMax min', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6B00))),
                      ],
                    ),
                    Slider(
                      value: _duracionMax.toDouble(),
                      min: 30,
                      max: 120,
                      activeColor: const Color(0xFFFF6B00),
                      inactiveColor: Colors.white.withOpacity(0.1),
                      divisions: 9,
                      onChanged: (v) => setState(() => _duracionMax = v.round()),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Mínimo de ejercicios por sesión', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                        Text('$_minEjerciciosPorSesion ejercicios', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6B00))),
                      ],
                    ),
                    Slider(
                      value: _minEjerciciosPorSesion.toDouble(),
                      min: 2,
                      max: 12,
                      activeColor: const Color(0xFFFF6B00),
                      inactiveColor: Colors.white.withOpacity(0.1),
                      divisions: 10,
                      onChanged: (v) => setState(() => _minEjerciciosPorSesion = v.round()),
                    ),
                    const SizedBox(height: 16),
                    const Text('Nivel de experiencia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _nivelExperiencia,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0F0F12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'principiante', child: Text('Principiante')),
                        DropdownMenuItem(value: 'intermedio', child: Text('Intermedio (1-3 años)')),
                        DropdownMenuItem(value: 'avanzado', child: Text('Avanzado (3+ años)')),
                      ],
                      onChanged: (v) => setState(() => _nivelExperiencia = v!),
                    ),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 12),
                    const Text('Lesiones o limitaciones (Cuidado articular)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        '🤕 Hombro operado / lesión',
                        '🦵 Rodilla (Meniscos / ligamento)',
                        '💥 Espalda baja / lumbar',
                      ].map((lesion) {
                        final isSelected = _lesionesSeleccionadas.contains(lesion);
                        return FilterChip(
                          label: Text(lesion),
                          selected: isSelected,
                          selectedColor: const Color(0xFFFF6B00),
                          backgroundColor: const Color(0xFF0F0F12),
                          side: BorderSide(color: isSelected ? Colors.transparent : Colors.white12),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _lesionesSeleccionadas.add(lesion);
                              } else {
                                _lesionesSeleccionadas.remove(lesion);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text('Preferencia de equipamiento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        '🤖 Máquinas guiadas (Selectorizadas)',
                        '⛓️ Poleas regulables',
                        '🏋️ Peso libre (Mancuernas / barras)',
                      ].map((pref) {
                        final isSelected = _prefEquipamientoSeleccionados.contains(pref);
                        return FilterChip(
                          label: Text(pref),
                          selected: isSelected,
                          selectedColor: const Color(0xFFFF6B00),
                          backgroundColor: const Color(0xFF0F0F12),
                          side: BorderSide(color: isSelected ? Colors.transparent : Colors.white12),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _prefEquipamientoSeleccionados.add(pref);
                              } else {
                                _prefEquipamientoSeleccionados.remove(pref);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Distribución de equipamiento',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Define la proporción de tipos de ejercicios',
                              style: TextStyle(fontSize: 11, color: Colors.white38),
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: _personalizarProporcion,
                          activeColor: const Color(0xFFFF6B00),
                          onChanged: (val) {
                            setState(() {
                              _personalizarProporcion = val;
                            });
                          },
                        ),
                      ],
                    ),
                    if (_personalizarProporcion) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0F12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.04)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.smart_toy_outlined, color: Color(0xFF00E5FF), size: 16),
                                    SizedBox(width: 6),
                                    Text('Máquinas Guiadas / Poleas', style: TextStyle(fontSize: 12, color: Colors.white70)),
                                  ],
                                ),
                                Text(
                                  '$_porcentajeMaquinasGuiadas%',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00E5FF), fontSize: 13),
                                ),
                              ],
                            ),
                            Slider(
                              value: _porcentajeMaquinasGuiadas.toDouble(),
                              min: 0,
                              max: 100,
                              divisions: 20,
                              activeColor: const Color(0xFF00E5FF),
                              inactiveColor: Colors.white.withOpacity(0.05),
                              onChanged: (val) {
                                setState(() {
                                  _porcentajeMaquinasGuiadas = val.round();
                                  _porcentajePesoLibre = 100 - _porcentajeMaquinasGuiadas;
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.fitness_center_rounded, color: Color(0xFFFF6B00), size: 16),
                                    SizedBox(width: 6),
                                    Text('Peso Libre / Mancuernas / Barras', style: TextStyle(fontSize: 12, color: Colors.white70)),
                                  ],
                                ),
                                Text(
                                  '$_porcentajePesoLibre%',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6B00), fontSize: 13),
                                ),
                              ],
                            ),
                            Slider(
                              value: _porcentajePesoLibre.toDouble(),
                              min: 0,
                              max: 100,
                              divisions: 20,
                              activeColor: const Color(0xFFFF6B00),
                              inactiveColor: Colors.white.withOpacity(0.05),
                              onChanged: (val) {
                                setState(() {
                                  _porcentajePesoLibre = val.round();
                                  _porcentajeMaquinasGuiadas = 100 - _porcentajePesoLibre;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text('Notas adicionales o médicas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notasAdicionalesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Ej: Tengo operado el hombro derecho y roto los meniscos internos de ambas rodillas. Prefiero máquinas que guíen el movimiento.',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF0F0F12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF19191F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFF6B00).withOpacity(0.15)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.auto_awesome, color: const Color(0xFFFF6B00), size: 18),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Tener en cuenta mis máquinas',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Si está activado, la IA integrará obligatoriamente tus máquinas del gym.',
                                  style: TextStyle(fontSize: 11, color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _usarMisMaquinas,
                            activeColor: const Color(0xFFFF6B00),
                            onChanged: (val) {
                              setState(() {
                                _usarMisMaquinas = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (machineState.machines.isNotEmpty) ...[
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 12),
                      const Text('Tus máquinas guardadas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: machineState.machines.map((m) {
                          final selected = _selectedMachines.contains(m.id);
                          return FilterChip(
                            label: Text(m.nombre, style: TextStyle(color: selected ? Colors.black : Colors.white70, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                            selected: selected,
                            selectedColor: const Color(0xFFFF6B00),
                            backgroundColor: const Color(0xFF0F0F12),
                            side: BorderSide(color: selected ? Colors.transparent : Colors.white12),
                            onSelected: (v) {
                              setState(() {
                                if (v) {
                                  _selectedMachines.add(m.id);
                                } else {
                                  _selectedMachines.remove(m.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B00), Color(0xFFFF8C00)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _generar,
                        icon: const Icon(Icons.auto_awesome, color: Colors.black, size: 20),
                        label: const Text(
                          'Generar Plan Semanal (7 días)',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (planState.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Card(
                color: const Color(0xFF2C1318),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFFF3366), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFFF3366)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Error: ${planState.error}',
                          style: const TextStyle(color: Color(0xFFFFE0E5), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanView(PlanSemanal plan, bool isLoading) {
    final dias = plan.planJson.dias;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF131317),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            plan.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (plan.activo)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF4CAF50), width: 1),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'Activo ✓',
                                  style: TextStyle(color: Color(0xFF4CAF50), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        else
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B00).withOpacity(0.12),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              await ref.read(weeklyPlanProvider.notifier).activateWeeklyPlan(plan.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Color(0xFF4CAF50),
                                    content: Text('Plan semanal aplicado como tu rutina activa ⚡', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.flash_on_rounded, color: Color(0xFFFF6B00), size: 14),
                            label: const Text(
                              'Aplicar Plan',
                              style: TextStyle(color: Color(0xFFFF6B00), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${plan.objetivo.toUpperCase()} · Nivel ${plan.nivel} · ${plan.diasEntrenoObjetivo} días/semana',
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFF6B00)),
                  onPressed: () {
                    ref.read(weeklyPlanProvider.notifier).clearPlan();
                  },
                  tooltip: 'Crear nuevo plan',
                ),
              ),
            ],
          ),
        ),
        if (plan.planJson.notaGeneral != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: const Color(0xFFFF6B00).withOpacity(0.1),
            child: Text(
              plan.planJson.notaGeneral!,
              style: const TextStyle(color: Color(0xFFFF9C59), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: dias.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return _buildAdaptationCard(plan);
              }
               return _buildDayCard(dias[i - 1], plan.id);
            },
          ),
        ),
        _buildModifyChatDock(plan.id),
      ],
    );
  }

  Widget _buildAdaptationCard(PlanSemanal plan) {
    final lesiones = plan.lesionesOLimitaciones ?? [];
    final maquinasRealesUsadas = <String>[];
    
    // Scan plan for any custom machine names used
    for (var dia in plan.planJson.dias) {
      for (var bloque in dia.bloques) {
        for (var ex in bloque.ejercicios) {
          if (ex.machineNombre != null && !maquinasRealesUsadas.contains(ex.machineNombre)) {
            maquinasRealesUsadas.add(ex.machineNombre!);
          }
        }
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131317),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.15)),
        gradient: LinearGradient(
          colors: [const Color(0xFF00E5FF).withOpacity(0.05), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFF00E5FF), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Adaptación & Seguridad Personalizada',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'IA VERIFIED',
                  style: TextStyle(color: Color(0xFF00E5FF), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Este entrenamiento ha sido procesado por el motor de IA adaptando la selección de ejercicios a tu perfil físico y máquinas configuradas:',
            style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.3),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.healing_outlined, color: Color(0xFFFF3366), size: 14),
                        SizedBox(width: 4),
                        Text('Limitaciones Médicas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    lesiones.isEmpty
                        ? const Text('✅ Rutina estándar (Sin limitaciones)', style: TextStyle(fontSize: 11, color: Colors.white38))
                        : Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: lesiones.map((l) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3366).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFFF3366).withOpacity(0.15)),
                              ),
                              child: Text(
                                l,
                                style: const TextStyle(color: Color(0xFFFF8FA3), fontSize: 10, fontWeight: FontWeight.w500),
                              ),
                            )).toList(),
                          ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.settings_outlined, color: Color(0xFFFF8C00), size: 14),
                        SizedBox(width: 4),
                        Text('Tus Máquinas Gym', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    maquinasRealesUsadas.isEmpty
                        ? const Text('No se requirieron máquinas específicas', style: TextStyle(fontSize: 11, color: Colors.white38))
                        : Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: maquinasRealesUsadas.map((m) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF8C00).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFFF8C00).withOpacity(0.15)),
                              ),
                              child: Text(
                                m,
                                style: const TextStyle(color: Color(0xFFFFB070), fontSize: 10, fontWeight: FontWeight.w500),
                              ),
                            )).toList(),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(PlanDia dia, String planId) {
    final color = dia.isWorkout
        ? const Color(0xFF00E5FF)
        : dia.isActiveRecovery
            ? const Color(0xFFFF8C00)
            : const Color(0xFF7E8B9B);
            
    final bgGrad = dia.isWorkout
        ? LinearGradient(colors: [const Color(0xFF00E5FF).withOpacity(0.12), const Color(0xFF00E5FF).withOpacity(0.04)])
        : dia.isActiveRecovery
            ? LinearGradient(colors: [const Color(0xFFFF8C00).withOpacity(0.12), const Color(0xFFFF8C00).withOpacity(0.04)])
            : LinearGradient(colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)]);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      color: const Color(0xFF15151B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: bgGrad,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: color.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Icon(_iconFor(dia), color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dia.nombreDia,
                        style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
                      ),
                      Text(
                        _labelFor(dia),
                        style: TextStyle(fontSize: 11, color: color.withOpacity(0.8), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (dia.tiempoTotalEstimadoMinutos != null && dia.tiempoTotalEstimadoMinutos! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${dia.tiempoTotalEstimadoMinutos} min',
                      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (dia.isWorkout)
                  IconButton(
                    icon: const Icon(Icons.add_circle_rounded, color: Color(0xFFFF6B00), size: 22),
                    tooltip: 'Añadir ejercicios personalizados',
                    onPressed: () => _showAddExerciseToDaySheet(dia, planId),
                  ),
              ],
            ),
          ),
          if (dia.notas != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                dia.notas!,
                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.white70),
              ),
            ),
          ...dia.bloques.expand((bloque) => [
            if (bloque.ejercicios.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Text(
                        bloque.nombre.toUpperCase(),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFF8C00)),
                      ),
                    ),
                    if (bloque.duracionMinutos != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${bloque.duracionMinutos} min',
                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
                      ),
                    ],
                  ],
                ),
              ),
              ...bloque.ejercicios.map((e) => _buildExerciseItem(e)),
            ]
          ]),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildExerciseItem(PlanDiaEjercicio e) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(Icons.chevron_right_rounded, size: 16, color: const Color(0xFFFF6B00).withOpacity(0.8)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.nombreEjercicio,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${e.series} series × ${e.repeticiones}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '  ·  ${e.descansoSegundos}s desc.',
                      style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
                    ),
                    if (e.rirORpe != null)
                      Text(
                        '  ·  ${e.rirORpe}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFFF8C00), fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
                if (e.machineNombre != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.fitness_center_rounded, size: 12, color: Colors.white.withOpacity(0.4)),
                      const SizedBox(width: 4),
                      Text(
                        e.machineNombre!,
                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4), fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ],
                if (e.notas != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    e.notas!,
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6), height: 1.3),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModifyChatDock(String planId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF15151B),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: _modInstructionsCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Ajusta algo. Ej: "Cambia press banca por flexiones"',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B00), Color(0xFFFF8C00)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.black),
                onPressed: () {
                  final text = _modInstructionsCtrl.text.trim();
                  if (text.isEmpty) return;
                  ref.read(weeklyPlanProvider.notifier).modifyWeeklyPlan(
                    planId: planId,
                    instrucciones: text,
                  );
                  _modInstructionsCtrl.clear();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(PlanDia dia) {
    switch (dia.tipo) {
      case 'workout':
        return Icons.fitness_center_rounded;
      case 'active_recovery':
        return Icons.directions_run_rounded;
      default:
        return Icons.hotel_rounded;
    }
  }

  String _labelFor(PlanDia dia) {
    switch (dia.tipo) {
      case 'workout':
        return 'ENTRENAMIENTO';
      case 'active_recovery':
        return 'RECUPERACIÓN ACTIVA';
      default:
        return 'DESCANSO';
    }
  }

  void _generar() async {
    final allMachineIds = ref.read(machineProvider).machines.map((m) => m.id).toList();
    await ref.read(weeklyPlanProvider.notifier).generateWeeklyPlan(
      objetivo: _objetivo,
      diasPorSemana: _diasPorSemana,
      duracionMaxMinutos: _duracionMax,
      nivelExperiencia: _nivelExperiencia,
      equipoDisponible: _equiposDisponibles,
      maquinasUsuarioIds: _usarMisMaquinas ? allMachineIds : const [],
      lesionesOLimitaciones: _lesionesSeleccionadas,
      notasAdicionales: _notasAdicionalesCtrl.text.trim().isEmpty ? null : _notasAdicionalesCtrl.text.trim(),
      diasEntrenoSeleccionados: _diasSeleccionados,
      preferenciasEquipamiento: _prefEquipamientoSeleccionados,
      porcentajeMaquinasGuiadas: _personalizarProporcion ? _porcentajeMaquinasGuiadas : null,
      porcentajePesoLibre: _personalizarProporcion ? _porcentajePesoLibre : null,
      minEjerciciosPorSesion: _minEjerciciosPorSesion,
    );
  }

  void _showMachinesSheet(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: ThemeData.dark(),
        child: StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Consumer(
              builder: (ctx, ref, __) {
                final state = ref.watch(machineProvider);
                return Dialog(
                  backgroundColor: const Color(0xFF131317),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540, maxHeight: 560),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header — full-width row, NOT wrapped in IntrinsicWidth like AlertDialog
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                          child: Row(
                            children: [
                              const Icon(Icons.fitness_center_rounded, color: Color(0xFFFF6B00)),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Tus Máquinas Guardadas',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Añadir máquina',
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6B00),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.all(6),
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showAddMachineDialog(context);
                                },
                                icon: const Icon(Icons.add, color: Colors.black, size: 20),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white10, height: 16),
                        // Content
                        Flexible(
                          child: state.machines.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Center(
                                    child: Text('No hay máquinas añadidas aún.', style: TextStyle(color: Colors.white30)),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.only(bottom: 8),
                                  itemCount: state.machines.length,
                                  itemBuilder: (_, i) {
                                    final m = state.machines[i];
                                    final selected = _selectedMachines.contains(m.id);
                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1C1C24),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white.withOpacity(0.04)),
                                      ),
                                      child: ListTile(
                                        leading: m.fotoPath != null
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.file(
                                                  File(m.fotoPath!.replaceAll('backend/', '')),
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => const Icon(Icons.fitness_center_rounded, color: Color(0xFFFF6B00)),
                                                ),
                                              )
                                            : const Icon(Icons.fitness_center_rounded, color: Color(0xFFFF6B00)),
                                        title: Text(m.nombre, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                                        subtitle: m.grupoMuscular != null
                                            ? Text(
                                                m.grupoMuscular!.toUpperCase(),
                                                style: const TextStyle(fontSize: 10, color: Color(0xFFFF8C00), fontWeight: FontWeight.bold),
                                              )
                                            : null,
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            FilterChip(
                                              label: Text(
                                                selected ? 'Usando' : 'Usar',
                                                style: TextStyle(color: selected ? Colors.black : Colors.white, fontSize: 11),
                                              ),
                                              selected: selected,
                                              selectedColor: const Color(0xFFFF6B00),
                                              backgroundColor: const Color(0xFF0F0F12),
                                              onSelected: (v) {
                                                setState(() {
                                                  if (v) _selectedMachines.add(m.id);
                                                  else _selectedMachines.remove(m.id);
                                                });
                                                setDialogState(() {});
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF3366)),
                                              onPressed: () async {
                                                await ref.read(machineProvider.notifier).deleteMachine(m.id);
                                                setState(() => _selectedMachines.remove(m.id));
                                                setDialogState(() {});
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        // Footer
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 8, 8),
                            child: TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cerrar', style: TextStyle(color: Colors.white70)),
                            ),
                          ),
                        ),
                      ],
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

  void _showAddMachineDialog(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedGrupoMuscular;
    File? pickedFile;
    bool isAnalyzing = false;
    List<dynamic> proposedExercises = [];

    // Map backend muscle groups to dropdown values
    String? mapMuscleGroup(String? group) {
      if (group == null) return null;
      final g = group.toLowerCase().trim();
      if (g == 'pecho') return 'pecho';
      if (g == 'espalda') return 'espalda';
      if (g == 'hombro' || g == 'hombros') return 'hombro';
      if (g == 'bicep' || g == 'biceps') return 'bicep';
      if (g == 'tricep' || g == 'triceps') return 'tricep';
      if (g == 'cuadriceps') return 'cuadriceps';
      if (g == 'femoral' || g == 'isquiotibiales' || g == 'femoral') return 'femoral';
      if (g == 'gluteo' || g == 'gluteos') return 'gluteo';
      if (g == 'gemelo' || g == 'gemelos') return 'gemelo';
      if (g == 'core') return 'core';
      return null;
    }

    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: ThemeData.dark(),
        child: StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: const Color(0xFF19191F),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.auto_awesome, color: const Color(0xFFFF6B00), size: 22),
                const SizedBox(width: 8),
                const Text('Añadir Máquina al Gym', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Explica para qué sirve o cómo usas la máquina y la IA autocompletará el nombre, grupo muscular y te propondrá ejercicios.',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                        labelText: 'Explicación de uso / Cómo es la máquina *',
                        hintText: 'Ej: Una polea alta con barra para hacer jalones hacia el pecho y trabajar la espalda.',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF0F0F12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00).withOpacity(0.15),
                        foregroundColor: const Color(0xFFFF6B00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFFFF6B00), width: 1),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: isAnalyzing
                          ? null
                          : () async {
                              if (descCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Por favor, escribe primero una explicación para la IA.'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }
                              setDialogState(() => isAnalyzing = true);
                              final res = await ref.read(machineProvider.notifier).proposeMachine(
                                    descripcionUso: descCtrl.text.trim(),
                                  );
                              setDialogState(() {
                                isAnalyzing = false;
                                if (res != null) {
                                  nombreCtrl.text = res['nombre'] ?? '';
                                  selectedGrupoMuscular = mapMuscleGroup(res['grupo_muscular']);
                                  proposedExercises = res['ejercicios'] ?? [];
                                }
                              });
                            },
                      icon: isAnalyzing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF6B00)),
                            )
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(
                        isAnalyzing ? 'Analizando máquina...' : 'Autocompletar con IA 🤖',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nombreCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nombre de la máquina *',
                        filled: true,
                        fillColor: const Color(0xFF0F0F12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedGrupoMuscular,
                      decoration: InputDecoration(
                        labelText: 'Grupo muscular',
                        filled: true,
                        fillColor: const Color(0xFF0F0F12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'pecho', child: Text('Pecho')),
                        DropdownMenuItem(value: 'espalda', child: Text('Espalda')),
                        DropdownMenuItem(value: 'hombro', child: Text('Hombro')),
                        DropdownMenuItem(value: 'bicep', child: Text('Bíceps')),
                        DropdownMenuItem(value: 'tricep', child: Text('Tríceps')),
                        DropdownMenuItem(value: 'cuadriceps', child: Text('Cuádriceps')),
                        DropdownMenuItem(value: 'femoral', child: Text('Femoral')),
                        DropdownMenuItem(value: 'gluteo', child: Text('Glúteo')),
                        DropdownMenuItem(value: 'gemelo', child: Text('Gemelo')),
                        DropdownMenuItem(value: 'core', child: Text('Core')),
                      ],
                      onChanged: (v) => setDialogState(() => selectedGrupoMuscular = v),
                    ),
                    const SizedBox(height: 12),
                    if (proposedExercises.isNotEmpty) ...[
                      const Text(
                        'Ejercicios sugeridos por la IA:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFFF8C00)),
                      ),
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: proposedExercises.length,
                          itemBuilder: (_, idx) {
                            final ex = proposedExercises[idx];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F0F12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withOpacity(0.04)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ex['nombre_ejercicio'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${ex['series']} series × ${ex['repeticiones']} · Descanso: ${ex['descanso_segundos']}s',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF00E5FF)),
                                  ),
                                  if (ex['notas'] != null && ex['notas'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      ex['notas'],
                                      style: const TextStyle(fontSize: 10, color: Colors.white60, fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFF6B00)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final img = await picker.pickImage(source: ImageSource.gallery);
                        if (img != null) {
                          setDialogState(() => pickedFile = File(img.path));
                        }
                      },
                      icon: const Icon(Icons.photo_library_rounded, color: Color(0xFFFF6B00)),
                      label: Text(pickedFile != null ? 'Imagen elegida' : 'Elegir foto de la máquina', style: const TextStyle(color: Color(0xFFFF6B00))),
                    ),
                    if (pickedFile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(pickedFile!, height: 120, fit: BoxFit.cover),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  if (nombreCtrl.text.trim().isEmpty) return;
                  final ok = await ref.read(machineProvider.notifier).uploadMachine(
                    nombre: nombreCtrl.text.trim(),
                    grupoMuscular: selectedGrupoMuscular,
                    descripcionUso: descCtrl.text.trim(),
                    file: pickedFile,
                  );
                  if (ok && ctx.mounted) {
                    Navigator.pop(ctx);
                    ref.read(machineProvider.notifier).loadMachines();
                  }
                },
                child: const Text('Subir y Guardar 💾', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlansSheet(BuildContext context, List<PlanSemanal> planes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131317),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // Consumer allows reactive updates when plans are deleted inside the sheet
      builder: (ctx) => Consumer(
        builder: (ctx, sheetRef, _) {
          final currentPlanes = sheetRef.watch(weeklyPlanProvider).planes;
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Planes Semanales Guardados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const Divider(color: Colors.white10),
              Expanded(
                child: currentPlanes.isEmpty
                    ? const Center(child: Text('No hay planes guardados', style: TextStyle(color: Colors.white30)))
                    : ListView.builder(
                        itemCount: currentPlanes.length,
                        itemBuilder: (_, i) {
                          final p = currentPlanes[i];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C24),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.04)),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.event_note_rounded, color: Color(0xFFFF8C00)),
                              title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              subtitle: Text('${p.objetivo.toUpperCase()} · ${p.nivel}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF3366)),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      backgroundColor: const Color(0xFF15151B),
                                      title: const Text('¿Eliminar plan?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      content: const Text('Esta acción eliminará permanentemente esta planificación semanal.', style: TextStyle(color: Colors.white70)),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar', style: TextStyle(color: Colors.white30))),
                                        TextButton(
                                          onPressed: () => Navigator.pop(c, true),
                                          child: const Text('Eliminar', style: TextStyle(color: Color(0xFFFF3366), fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await sheetRef.read(weeklyPlanProvider.notifier).deleteWeeklyPlan(p.id);
                                    // List updates reactively via Consumer — no need to pop
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          backgroundColor: Color(0xFFFF3366),
                                          content: Text('Plan semanal eliminado.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                              onTap: () {
                                Navigator.pop(ctx);
                                sheetRef.read(weeklyPlanProvider.notifier).loadPlan(p.id);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddExerciseToDaySheet(PlanDia dia, String planId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddExerciseToDaySheet(dia: dia, planId: planId),
    );
  }
}

// ─── Add Exercise to Day Bottom Sheet ───────────────────────────────────────

class _AddExerciseToDaySheet extends ConsumerStatefulWidget {
  final PlanDia dia;
  final String planId;

  const _AddExerciseToDaySheet({required this.dia, required this.planId});

  @override
  ConsumerState<_AddExerciseToDaySheet> createState() => _AddExerciseToDaySheetState();
}

class _AddExerciseToDaySheetState extends ConsumerState<_AddExerciseToDaySheet> {
  final Set<String> _selectedIds = {};
  String _bloqueTipo = 'principal';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userExercisesProvider.notifier).loadExercises();
    });
  }

  Future<void> _addExercises() async {
    if (_selectedIds.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(weeklyPlanProvider.notifier).addExercisesToPlan(
        planId: widget.planId,
        diaSemana: widget.dia.diaSemana,
        bloqueTipo: _bloqueTipo,
        ejerciciosIds: _selectedIds.toList(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userExercisesProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Añadir ejercicios a ${widget.dia.nombreDia}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedIds.length} seleccionados',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFFF6B00)),
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
          // Block selector
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                const Text('Bloque:', style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'calentamiento', label: Text('Calentamiento', style: TextStyle(fontSize: 11))),
                      ButtonSegment(value: 'principal', label: Text('Principal', style: TextStyle(fontSize: 11))),
                      ButtonSegment(value: 'enfriamiento', label: Text('Estiramiento', style: TextStyle(fontSize: 11))),
                    ],
                    selected: {_bloqueTipo},
                    onSelectionChanged: (s) => setState(() => _bloqueTipo = s.first),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) return const Color(0xFFFF6B00);
                        return const Color(0xFF1C1C24);
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) return Colors.black;
                        return Colors.white70;
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          // Exercise list
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
                : state.exercises.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fitness_center_rounded, size: 48, color: Colors.white24),
                            SizedBox(height: 12),
                            Text('No tienes ejercicios personalizados', style: TextStyle(color: Colors.white54)),
                            SizedBox(height: 8),
                            Text('Crea ejercicios desde Ejercicios Personalizados', style: TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: state.exercises.length,
                        itemBuilder: (_, i) {
                          final e = state.exercises[i];
                          final isSelected = _selectedIds.contains(e.id);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (_) {
                              setState(() {
                                if (isSelected) {
                                  _selectedIds.remove(e.id);
                                } else {
                                  _selectedIds.add(e.id);
                                }
                              });
                            },
                            activeColor: const Color(0xFFFF6B00),
                            checkColor: Colors.black,
                            title: Text(e.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                            subtitle: Text(
                              '${e.grupoMuscular ?? 'Sin grupo'} • ${e.series}x${e.repeticiones ?? '-'}${e.machineNombre != null ? ' • ${e.machineNombre}' : ''}',
                              style: const TextStyle(fontSize: 12, color: Colors.white54),
                            ),
                            secondary: e.machineFotoPath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(e.machineFotoPath!.replaceAll('backend/', '')),
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.fitness_center_rounded, color: Colors.white24),
                                    ),
                                  )
                                : const Icon(Icons.fitness_center_rounded, color: Colors.white24),
                          );
                        },
                      ),
          ),
          // Bottom button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F0F12),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _selectedIds.isEmpty || _isSaving ? null : _addExercises,
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text('Añadir ${_selectedIds.length} ejercicio(s)', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}