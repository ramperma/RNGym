import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/error_reporter.dart';
import '../../domain/user_exercise.dart';
import '../providers/user_exercises_provider.dart';

class UserExercisesScreen extends ConsumerStatefulWidget {
  const UserExercisesScreen({super.key});

  @override
  ConsumerState<UserExercisesScreen> createState() => _UserExercisesScreenState();
}

class _UserExercisesScreenState extends ConsumerState<UserExercisesScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userExercisesProvider.notifier).loadExercises();
    });
  }

  List<UserExercise> _filterExercises(List<UserExercise> all) {
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all.where((e) {
      return e.nombre.toLowerCase().contains(q) ||
          (e.grupoMuscular?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void _showExerciseForm({UserExercise? exercise}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExerciseFormSheet(exercise: exercise),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userExercisesProvider);
    final filtered = _filterExercises(state.exercises);

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F12),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ejercicios Personalizados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: const Color(0xFF0F0F12),
          elevation: 0,
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C24),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar ejercicio...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
            ),
            // List
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
                  : filtered.isEmpty
                      ? _buildEmptyView()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _buildExerciseCard(filtered[i]),
                        ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFFFF6B00),
          onPressed: () => _showExerciseForm(),
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center_rounded, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('No tienes ejercicios personalizados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Toca el botón + para crear el primero', style: TextStyle(fontSize: 13, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(UserExercise e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF15151B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: e.machineFotoPath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(e.machineFotoPath!.replaceAll('backend/', '')),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
                ),
              )
            : _buildPlaceholderIcon(),
        title: Text(e.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${e.grupoMuscular ?? 'Sin grupo'} • ${e.series}x${e.repeticiones ?? '-'}',
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
            if (e.machineNombre != null)
              Text(
                e.machineNombre!,
                style: const TextStyle(fontSize: 11, color: Color(0xFFFF8C00), fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white38, size: 18),
              onPressed: () => _showExerciseForm(exercise: e),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
              onPressed: () => _confirmDelete(e),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.fitness_center_rounded, color: Colors.white24, size: 24),
    );
  }

  void _confirmDelete(UserExercise e) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131317),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar ejercicio?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('"${e.nombre}" se eliminará permanentemente.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref.read(userExercisesProvider.notifier).deleteExercise(e.id);
              if (!ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al eliminar'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Exercise Form Sheet ─────────────────────────────────────────────────────

class _ExerciseFormSheet extends StatefulWidget {
  final UserExercise? exercise;

  const _ExerciseFormSheet({this.exercise});

  @override
  State<_ExerciseFormSheet> createState() => _ExerciseFormSheetState();
}

class _ExerciseFormSheetState extends State<_ExerciseFormSheet> {
  final _nombreCtrl = TextEditingController();
  final _repsCtrl = TextEditingController(text: '10-12');
  final _rirCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  final _machineCtrl = TextEditingController();
  String? _grupoMuscular;
  int _series = 3;
  int _descanso = 90;
  File? _photo;
  bool _isSaving = false;

  final _grupos = [
    'pecho', 'espalda', 'hombros', 'biceps', 'triceps',
    'piernas', 'cuadriceps', 'isquiotibiales', 'gluteos',
    'abdomen', 'core', 'gemelos', 'antebrazos', 'cardio',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.exercise != null) {
      final e = widget.exercise!;
      _nombreCtrl.text = e.nombre;
      _grupoMuscular = e.grupoMuscular;
      _machineCtrl.text = e.machineNombre ?? '';
      _series = e.series;
      _repsCtrl.text = e.repeticiones ?? '10-12';
      _descanso = e.descansoSegundos;
      _rirCtrl.text = e.rirOPe ?? '';
      _notasCtrl.text = e.notas ?? '';
      if (e.machineFotoPath != null) {
        _photo = File(e.machineFotoPath!.replaceAll('backend/', ''));
      }
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _repsCtrl.dispose();
    _rirCtrl.dispose();
    _notasCtrl.dispose();
    _machineCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 1280);
    if (picked != null) {
      setState(() => _photo = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (_nombreCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    try {
      final notifier = ProviderScope.containerOf(context).read(userExercisesProvider.notifier);

      String? fotoPath;
      if (_photo != null && !(_photo!.path.contains('backend/storage'))) {
        // Upload new photo
        final api = ProviderScope.containerOf(context).read(userExerciseApiProvider);
        fotoPath = await api.uploadPhoto(_photo!);
      } else if (widget.exercise?.machineFotoPath != null) {
        fotoPath = widget.exercise!.machineFotoPath;
      }

      if (!mounted) return;

      final data = {
        'nombre': _nombreCtrl.text.trim(),
        'grupo_muscular': _grupoMuscular,
        'machine_nombre': _machineCtrl.text.trim().isEmpty ? null : _machineCtrl.text.trim(),
        'machine_foto_path': fotoPath,
        'series': _series,
        'repeticiones': _repsCtrl.text.trim().isEmpty ? null : _repsCtrl.text.trim(),
        'descanso_segundos': _descanso,
        'rir_o_pe': _rirCtrl.text.trim().isEmpty ? null : _rirCtrl.text.trim(),
        'notas': _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      };

      if (widget.exercise != null) {
        await notifier.updateExercise(widget.exercise!.id, data);
      } else {
        await notifier.createExercise(data);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ErrorReporter.report(Exception('Error guardando ejercicio: $e'), StackTrace.current);
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
    final isEditing = widget.exercise != null;
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  isEditing ? 'Editar Ejercicio' : 'Nuevo Ejercicio',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Photo picker
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C24),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: _photo != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(_photo!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFFFF6B00), size: 36),
                                const SizedBox(height: 8),
                                Text('Añadir foto de máquina (opcional)', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(_nombreCtrl, 'Nombre del ejercicio', Icons.fitness_center_rounded),
                  const SizedBox(height: 16),
                  // Grupo muscular dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C24),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _grupoMuscular,
                        hint: const Text('Grupo muscular', style: TextStyle(color: Colors.white38)),
                        dropdownColor: const Color(0xFF1C1C24),
                        style: const TextStyle(color: Colors.white),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white38),
                        items: _grupos.map((g) => DropdownMenuItem(value: g, child: Text(g[0].toUpperCase() + g.substring(1)))).toList(),
                        onChanged: (v) => setState(() => _grupoMuscular = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(_machineCtrl, 'Máquina / Equipamiento (opcional)', Icons.settings_suggest_rounded),
                  const SizedBox(height: 16),
                  // Series & Reps row
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField('Series', _series, (v) => setState(() => _series = v)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(_repsCtrl, 'Repeticiones', Icons.repeat_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Descanso & RIR row
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField('Descanso (seg)', _descanso, (v) => setState(() => _descanso = v)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(_rirCtrl, 'RIR/RPE (opcional)', Icons.speed_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(_notasCtrl, 'Notas (opcional)', Icons.notes_rounded, maxLines: 3),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : Text(isEditing ? 'Guardar Cambios' : 'Crear Ejercicio', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.28)),
          prefixIcon: Icon(icon, color: Colors.white24, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildNumberField(String label, int value, ValueChanged<int> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.white38, size: 18),
                onPressed: () { if (value > 0) onChanged(value - 1); },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              ),
              Text('$value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFF6B00), size: 18),
                onPressed: () => onChanged(value + 1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
