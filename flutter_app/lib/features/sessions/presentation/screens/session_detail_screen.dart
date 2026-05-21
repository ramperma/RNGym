import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../exercises/data/exercise_api.dart';
import '../../../exercises/domain/exercise.dart';
import '../../domain/sesion.dart';
import '../providers/sessions_provider.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  SesionEntreno? _session;
  List<Exercise> _exerciseCatalog = [];
  bool _isLoading = true;
  String? _error;

  /// Map ejercicioId -> Exercise para buscar nombres, grupos y equipos
  Map<String, Exercise> get _exerciseById => {
        for (var e in _exerciseCatalog) e.id: e,
      };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Cargar catálogo de ejercicios en paralelo con la sesión
      final api = ref.read(sessionApiProvider);
      final catalogFuture = ExerciseApi().fetchExercises();
      final sessionFuture = api.getSession(widget.sessionId);

      final results = await Future.wait([catalogFuture, sessionFuture]);
      final catalog = results[0] as List<Exercise>;
      final session = results[1] as SesionEntreno;

      if (mounted) {
        setState(() {
          _exerciseCatalog = catalog;
          _session = session;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Devuelve el nombre legible del ejercicio (del catálogo o del registro)
  String _resolveExerciseName(SesionEjercicioRegistro r) {
    // 1. Si el backend ya trae nombre, usarlo
    if (r.ejercicioNombre != null && r.ejercicioNombre!.isNotEmpty) {
      return r.ejercicioNombre!;
    }
    // 2. Buscar en el catálogo local
    final catalogExercise = _exerciseById[r.ejercicioId];
    if (catalogExercise != null) {
      return catalogExercise.name;
    }
    // 3. Fallback al ID (no debería pasar)
    return r.ejercicioId;
  }

  String? _resolveMuscleGroup(SesionEjercicioRegistro r) {
    if (r.ejercicioGrupoMuscular != null && r.ejercicioGrupoMuscular!.isNotEmpty) {
      return r.ejercicioGrupoMuscular;
    }
    return _exerciseById[r.ejercicioId]?.muscleGroup;
  }

  String? _resolveEquipment(SesionEjercicioRegistro r) {
    if (r.ejercicioEquipo != null && r.ejercicioEquipo!.isNotEmpty) {
      return r.ejercicioEquipo;
    }
    return _exerciseById[r.ejercicioId]?.equipment;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: AppBar(
        title: const Text('Detalle de Sesión', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F0F12),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            onPressed: _session != null ? () => _confirmDelete(_session!.id) : null,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error: $_error', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00)),
              child: const Text('Reintentar', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
    }
    if (_session == null) {
      return const Center(child: Text('Sesión no encontrada', style: TextStyle(color: Colors.white54)));
    }

    final s = _session!;
    final ejerciciosAgrupados = _agruparPorEjercicio(s.registros);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(s),
          const SizedBox(height: 24),
          _buildInfoCard(s),
          const SizedBox(height: 24),
          if (ejerciciosAgrupados.isNotEmpty) ...[
            const Text(
              'EJERCICIOS REALIZADOS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B00),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            ...ejerciciosAgrupados.entries.map((entry) => _buildEjercicioCard(entry.key, entry.value)),
          ] else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No hay ejercicios registrados en esta sesión.',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Map<String, List<SesionEjercicioRegistro>> _agruparPorEjercicio(List<SesionEjercicioRegistro> registros) {
    final map = <String, List<SesionEjercicioRegistro>>{};
    for (var r in registros) {
      final key = _resolveExerciseName(r);
      map.putIfAbsent(key, () => []).add(r);
    }
    // Ordenar sets por número dentro de cada grupo
    for (var list in map.values) {
      list.sort((a, b) => a.setNumero.compareTo(b.setNumero));
    }
    return map;
  }

  Widget _buildHeader(SesionEntreno s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16161E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.nombre ?? 'Sesión de Entrenamiento',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildEstadoChip(s.estado),
              const SizedBox(width: 12),
              if (s.duracionMinutos != null)
                Row(
                  children: [
                    const Icon(Icons.timer, color: Color(0xFFFF6B00), size: 16),
                    const SizedBox(width: 4),
                    Text('${s.duracionMinutos} min', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(SesionEntreno s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16161E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Fecha inicio', _formatDate(s.fechaInicio)),
          if (s.fechaFin != null) _buildInfoRow('Fecha fin', _formatDate(s.fechaFin!)),
          if (s.kcalEstimadas != null) _buildInfoRow('Kcal estimadas', '${s.kcalEstimadas}'),
          if (s.kcalReal != null) _buildInfoRow('Kcal reales', '${s.kcalReal}'),
          if (s.notas != null && s.notas!.isNotEmpty) _buildInfoRow('Notas', s.notas!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white38, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildEjercicioCard(String nombreEjercicio, List<SesionEjercicioRegistro> registros) {
    final primerRegistro = registros.first;
    final grupoMuscular = _resolveMuscleGroup(primerRegistro);
    final equipo = _resolveEquipment(primerRegistro);

    double volumenTotal = 0;
    final pesos = <int>[];
    final reps = <int>[];
    for (var r in registros) {
      if (r.completado) {
        if (r.pesoKg != null) pesos.add(r.pesoKg!.toInt());
        if (r.repeticiones != null) reps.add(r.repeticiones!);
        if (r.pesoKg != null && r.repeticiones != null) {
          volumenTotal += r.pesoKg! * r.repeticiones!;
        }
      }
    }

    final setsLabel = '${registros.length}×${reps.isEmpty ? "-" : reps.join("/")}';
    final pesoLabel = pesos.isEmpty ? '-' : (pesos.every((p) => p == pesos.first) ? '${pesos.first}' : pesos.join('/'));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF15151B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombreEjercicio,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (grupoMuscular != null && grupoMuscular.isNotEmpty) ...[
                      Icon(Icons.fitness_center, color: const Color(0xFFFF8C00), size: 11),
                      const SizedBox(width: 3),
                      Text(grupoMuscular, style: const TextStyle(fontSize: 11, color: Color(0xFFFF8C00))),
                      const SizedBox(width: 8),
                    ],
                    if (equipo != null && equipo.isNotEmpty) ...[
                      Icon(Icons.settings_suggest_rounded, color: Colors.white38, size: 11),
                      const SizedBox(width: 3),
                      Text(equipo, style: const TextStyle(fontSize: 11, color: Colors.white38)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$pesoLabel kg  $setsLabel',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 3),
              Text(
                '${volumenTotal.toInt()} kg',
                style: const TextStyle(fontSize: 11, color: Color(0xFFFF6B00), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(SesionEjercicioRegistro r) {
    return Container(
      color: r.completado ? const Color(0xFF1E281E).withValues(alpha: 0.3) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#${r.setNumero}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: r.completado ? Colors.green : Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                r.pesoKg != null ? '${r.pesoKg!.toInt()}' : '-',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: r.completado ? Colors.green : Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                r.repeticiones != null ? '${r.repeticiones}' : '-',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: r.completado ? Colors.green : Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                r.rpe != null ? '${r.rpe}' : '-',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: r.completado ? Colors.green : Colors.white70,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: r.completado ? Colors.green : Colors.white.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: r.completado ? Colors.transparent : Colors.white24,
                    width: 1.5,
                  ),
                ),
                child: r.completado
                    ? const Icon(Icons.check, color: Colors.black, size: 14)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    final color = switch (estado) {
      'planificada' => Colors.blue,
      'en_progreso' => Colors.orange,
      'completada' => Colors.green,
      'cancelada' => Colors.grey,
      _ => Colors.grey,
    };
    final label = switch (estado) {
      'planificada' => 'Planificada',
      'en_progreso' => 'En progreso',
      'completada' => 'Completada',
      'cancelada' => 'Cancelada',
      _ => estado,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16161E),
        title: const Text('Eliminar sesión', style: TextStyle(color: Colors.white)),
        content: const Text('¿Seguro que quieres eliminar esta sesión? No se podrá recuperar.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(sessionApiProvider).deleteSession(id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sesión eliminada'), backgroundColor: Colors.green),
                  );
                  context.pop(); // Volver a la lista
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
