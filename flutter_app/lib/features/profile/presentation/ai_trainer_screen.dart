import 'package:flutter/material.dart';

import '../data/profile_api.dart';
import '../domain/user_profile.dart';

class AiTrainerScreen extends StatefulWidget {
  const AiTrainerScreen({super.key});

  @override
  State<AiTrainerScreen> createState() => _AiTrainerScreenState();
}

class _AiTrainerScreenState extends State<AiTrainerScreen> {
  final _api = ProfileApi();
  final _notesController = TextEditingController();

  bool _loading = true;
  bool _generating = false;
  String? _error;
  AiStatus? _aiStatus;
  UserProfile? _profile;

  // Plan config
  int _weeks = 4;
  int _daysPerWeek = 3;
  int _restDays = 2;
  bool _expertChat = false;
  final Set<String> _selectedTypes = {};
  final Set<String> _selectedLimitations = {};

  static const _trainingTypes = {
    'fuerza': 'Fuerza',
    'hipertrofia': 'Hipertrofia',
    'cardio': 'Cardio',
    'funcional': 'Funcional',
    'flexibilidad': 'Flexibilidad',
    'resistencia': 'Resistencia',
    'calistenia': 'Calistenia',
    'hiit': 'HIIT',
  };

  static const _limitations = {
    'lesion_espalda': 'Lesión espalda',
    'lesion_rodilla': 'Lesión rodilla',
    'lesion_hombro': 'Lesión hombro',
    'hipertension': 'Hipertensión',
    'diabetes': 'Diabetes',
    'embarazo': 'Embarazo',
    'sin_equipo': 'Sin equipo',
    'solo_mancuernas': 'Solo mancuernas',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([_api.fetchAiStatus(), _api.fetchProfile()]);
      final aiStatus = results[0] as AiStatus;
      final profile = results[1] as UserProfile;
      setState(() { _aiStatus = aiStatus; _profile = profile; _loading = false; });
    } catch (error) {
      setState(() { _error = error.toString(); _loading = false; });
    }
  }

  Future<void> _generatePlan() async {
    if (_aiStatus == null || !_aiStatus!.enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La IA no está disponible en este momento.')),
      );
      return;
    }
    setState(() { _generating = true; _error = null; });
    try {
      await Future.delayed(const Duration(seconds: 2)); // placeholder
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan generado correctamente.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() { _error = error.toString(); });
    } finally {
      if (mounted) setState(() { _generating = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _aiStatus == null) {
      return _ErrorState(error: _error!, onRetry: _load);
    }

    final aiReady = _aiStatus?.enabled ?? false;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
      children: [
        _SectionHeader(
          icon: Icons.smart_toy_outlined,
          iconColor: const Color(0xFF1A9D8C),
          title: 'Personal Trainer IA',
          subtitle: 'Genera un plan de entrenamiento adaptado a ti de forma automática.',
        ),
        const SizedBox(height: 14),
        _AiStatusBanner(status: _aiStatus, profile: _profile),
        const SizedBox(height: 14),

        // Configuración del plan
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardSectionTitle('Duración del plan'),
                const SizedBox(height: 14),
                _SliderRow(
                  label: 'Semanas',
                  value: _weeks.toDouble(),
                  min: 1,
                  max: 12,
                  divisions: 11,
                  displayValue: '$_weeks sem.',
                  onChanged: (v) => setState(() => _weeks = v.round()),
                ),
                const SizedBox(height: 8),
                _SliderRow(
                  label: 'Días / semana',
                  value: _daysPerWeek.toDouble(),
                  min: 1,
                  max: 7,
                  divisions: 6,
                  displayValue: '$_daysPerWeek días',
                  onChanged: (v) => setState(() => _daysPerWeek = v.round()),
                ),
                const SizedBox(height: 8),
                _SliderRow(
                  label: 'Días descanso',
                  value: _restDays.toDouble(),
                  min: 0,
                  max: 6,
                  divisions: 6,
                  displayValue: '$_restDays días',
                  onChanged: (v) => setState(() => _restDays = v.round()),
                ),
                const SizedBox(height: 20),
                _CardSectionTitle('Tipo de entrenamiento'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _trainingTypes.entries.map((e) {
                    final selected = _selectedTypes.contains(e.key);
                    return FilterChip(
                      label: Text(e.value),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        if (v) { _selectedTypes.add(e.key); }
                        else { _selectedTypes.remove(e.key); }
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                _CardSectionTitle('Limitaciones'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _limitations.entries.map((e) {
                    final selected = _selectedLimitations.contains(e.key);
                    return FilterChip(
                      label: Text(e.value),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        if (v) { _selectedLimitations.add(e.key); }
                        else { _selectedLimitations.remove(e.key); }
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                _CardSectionTitle('Notas adicionales'),
                const SizedBox(height: 10),
                TextField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'Equipamiento disponible, preferencias, lesiones puntuales…',
                    prefixIcon: Icon(Icons.edit_note_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F8FE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDE6F0)),
                  ),
                  child: SwitchListTile(
                    value: _expertChat,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    title: Text('Chat experto', style: Theme.of(context).textTheme.titleSmall),
                    subtitle: Text(
                      'Activa el modo conversacional para refinar el plan paso a paso.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onChanged: aiReady ? (v) => setState(() => _expertChat = v) : null,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: (!aiReady || _generating) ? null : _generatePlan,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1A9D8C),
                      disabledBackgroundColor: const Color(0xFFCCE9E6),
                    ),
                    icon: _generating
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome_outlined),
                    label: Text(_generating ? 'Generando plan…' : 'Generar plan de entrenamiento'),
                  ),
                ),
                if (!aiReady) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Configura un proveedor de IA en el servidor para usar esta función.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Componentes privados ────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  const _SectionHeader({required this.icon, required this.iconColor, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [iconColor, iconColor.withValues(alpha: 0.6)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 3),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        )),
      ],
    );
  }
}

class _CardSectionTitle extends StatelessWidget {
  final String text;
  const _CardSectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 0.9, color: const Color(0xFF7A8FA6)),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(
        width: 110,
        child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ),
      Expanded(child: Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged)),
      SizedBox(
        width: 56,
        child: Text(displayValue, style: Theme.of(context).textTheme.titleSmall, textAlign: TextAlign.end),
      ),
    ]);
  }
}

class _AiStatusBanner extends StatelessWidget {
  final AiStatus? status;
  final UserProfile? profile;
  const _AiStatusBanner({this.status, this.profile});

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();
    final ready = status!.enabled;
    final accent = ready ? const Color(0xFF0D7A5F) : const Color(0xFFB45309);
    final bg = ready ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB);
    final border = ready ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(ready ? Icons.check_circle_outline : Icons.info_outline, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ready ? 'IA lista para generar planes' : 'IA no disponible',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: accent)),
              const SizedBox(height: 2),
              Text(
                ready
                    ? 'Proveedor: ${status!.provider}${profile != null ? ' · Perfil: ${profile!.displayName}' : ''}'
                    : 'Configura el proveedor de IA en el backend para habilitar esta función.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          )),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 44, color: Color(0xFF7A8FA6)),
            const SizedBox(height: 14),
            Text(error, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
