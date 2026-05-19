import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gym_trainer_app/core/theme/app_colors.dart';
import 'package:gym_trainer_app/shared/widgets/gym_card.dart';
import '../providers/routines_provider.dart';

class RoutineListScreen extends ConsumerStatefulWidget {
  const RoutineListScreen({super.key});

  @override
  ConsumerState<RoutineListScreen> createState() => _RoutineListScreenState();
}

class _RoutineListScreenState extends ConsumerState<RoutineListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(routinesProvider.notifier).loadRutinas());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(routinesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mis Rutinas',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/routines/create'),
        label: const Text('Nueva rutina'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
      ),
    );
  }

  Widget _buildBody(RoutinesState state) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    if (state.error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Error: ${state.error}', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(routinesProvider.notifier).loadRutinas(),
            child: const Text('Reintentar'),
          ),
        ]),
      );
    }
    if (state.rutinas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'No tienes rutinas aún.',
              style: GoogleFonts.outfit(fontSize: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              '¡Crea la primera para empezar!',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(routinesProvider.notifier).loadRutinas(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: state.rutinas.length,
        itemBuilder: (context, index) {
          final rutina = state.rutinas[index];
          return GymCard(
            margin: const EdgeInsets.only(bottom: 16),
            onTap: () => context.push('/routines/${rutina.id}'),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.fitness_center, color: AppColors.accent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rutina.nombre,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${rutina.tipoRutina} · ${rutina.dificultad ?? '-'}',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: Icon(Icons.more_vert, color: AppColors.textMuted),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'view', child: Text('Ver detalle')),
                    const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                  onSelected: (value) {
                    if (value == 'view') context.push('/routines/${rutina.id}');
                    if (value == 'delete') _confirmDelete(rutina.id);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar rutina'),
        content: const Text('¿Estás seguro de que quieres eliminar esta rutina?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(routinesProvider.notifier).deleteRutina(id);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
