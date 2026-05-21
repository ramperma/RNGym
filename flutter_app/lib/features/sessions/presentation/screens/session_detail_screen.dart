import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final api = ref.read(sessionApiProvider);
      final session = await api.getSession(widget.sessionId);
      if (mounted) {
        setState(() {
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
              onPressed: _loadSession,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(s),
          const SizedBox(height: 24),
          _buildInfoCard(s),
          const SizedBox(height: 24),
          if (s.registros.isNotEmpty) ...[
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
            ...s.registros.map((r) => _buildRegistroCard(r)),
          ],
        ],
      ),
    );
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

  Widget _buildRegistroCard(SesionEjercicioRegistro r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF15151B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${r.setNumero}',
                style: const TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ejercicio: ${r.ejercicioId.substring(0, r.ejercicioId.length > 8 ? 8 : r.ejercicioId.length)}...',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (r.pesoKg != null)
                      _buildRegistroChip('${r.pesoKg!.toInt()} kg'),
                    if (r.repeticiones != null) ...[
                      const SizedBox(width: 6),
                      _buildRegistroChip('${r.repeticiones} reps'),
                    ],
                    if (r.rpe != null) ...[
                      const SizedBox(width: 6),
                      _buildRegistroChip('RPE ${r.rpe}'),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (r.completado)
            const Icon(Icons.check_circle, color: Colors.green, size: 20)
          else
            const Icon(Icons.radio_button_unchecked, color: Colors.white24, size: 20),
        ],
      ),
    );
  }

  Widget _buildRegistroChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11)),
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
}
