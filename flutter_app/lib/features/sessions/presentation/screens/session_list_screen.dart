import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/sessions_provider.dart';

class SessionListScreen extends ConsumerStatefulWidget {
  const SessionListScreen({super.key});

  @override
  ConsumerState<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends ConsumerState<SessionListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(sessionsProvider.notifier).loadSessions());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sesiones de Entreno')),
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/sessions/create'),
        label: const Text('Nueva sesión'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(SessionsState state) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Error: ${state.error}'),
          ElevatedButton(onPressed: () => ref.read(sessionsProvider.notifier).loadSessions(), child: const Text('Reintentar')),
        ]),
      );
    }
    if (state.sesiones.isEmpty) {
      return const Center(child: Text('No tienes sesiones aún. ¡Planifica tu primera!'));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(sessionsProvider.notifier).loadSessions(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.sesiones.length,
        itemBuilder: (context, index) {
          final sesion = state.sesiones[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(sesion.nombre ?? 'Sesión', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('${sesion.fechaInicio.day}/${sesion.fechaInicio.month}/${sesion.fechaInicio.year}'),
                  Row(
                    children: [
                      _buildChip(_estadoLabel(sesion.estado), _estadoColor(sesion.estado)),
                      if (sesion.duracionMinutos != null) ...[
                        const SizedBox(width: 8),
                        Text('${sesion.duracionMinutos} min'),
                      ],
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton(
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'view', child: Text('Ver')),
                  const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
                onSelected: (value) {
                  if (value == 'view') context.push('/sessions/${sesion.id}');
                  if (value == 'delete') _confirmDelete(sesion.id);
                },
              ),
              onTap: () => context.push('/sessions/${sesion.id}'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }

  String _estadoLabel(String estado) {
    return switch (estado) {
      'planificada' => 'Planificada',
      'en_progreso' => 'En progreso',
      'completada' => 'Completada',
      'cancelada' => 'Cancelada',
      _ => estado,
    };
  }

  Color _estadoColor(String estado) {
    return switch (estado) {
      'planificada' => Colors.blue,
      'en_progreso' => Colors.orange,
      'completada' => Colors.green,
      'cancelada' => Colors.grey,
      _ => Colors.grey,
    };
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar sesión'),
        content: const Text('¿Seguro?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('No')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(sessionsProvider.notifier).deleteSession(id);
            },
            child: const Text('Sí', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}