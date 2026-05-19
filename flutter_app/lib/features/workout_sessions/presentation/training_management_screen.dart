import 'package:flutter/material.dart';

import '../data/training_management_store.dart';
import '../domain/training_management_config.dart';

class TrainingManagementScreen extends StatefulWidget {
  const TrainingManagementScreen({super.key});

  @override
  State<TrainingManagementScreen> createState() => _TrainingManagementScreenState();
}

class _TrainingManagementScreenState extends State<TrainingManagementScreen> {
  late TrainingManagementConfig _draft;

  @override
  void initState() {
    super.initState();
    _draft = TrainingManagementStore.instance.config;
  }

  void _save() {
    TrainingManagementStore.instance.update(_draft);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuracion guardada.')),
    );
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() {
      _draft = TrainingManagementConfig.defaults();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion de entrenamientos'),
        actions: [
          IconButton(
            tooltip: 'Restablecer valores',
            onPressed: _reset,
            icon: const Icon(Icons.restore),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
        children: [
          _SectionCard(
            title: 'Parametros IA',
            children: [
              _SliderSetting(
                label: 'Temperatura IA',
                value: _draft.aiTemperature,
                min: 0,
                max: 1,
                divisions: 20,
                displayValue: _draft.aiTemperature.toStringAsFixed(2),
                onChanged: (v) => setState(() {
                  _draft = _draft.copyWith(aiTemperature: v);
                }),
              ),
              _SliderSetting(
                label: 'Creatividad',
                value: _draft.aiCreativity.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                displayValue: '${_draft.aiCreativity}%',
                onChanged: (v) => setState(() {
                  _draft = _draft.copyWith(aiCreativity: v.round());
                }),
              ),
              _SliderSetting(
                label: 'Sesgo intensidad',
                value: _draft.intensityBias.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                displayValue: '${_draft.intensityBias}%',
                onChanged: (v) => setState(() {
                  _draft = _draft.copyWith(intensityBias: v.round());
                }),
              ),
              _SliderSetting(
                label: 'Sesgo recuperacion',
                value: _draft.recoveryBias.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                displayValue: '${_draft.recoveryBias}%',
                onChanged: (v) => setState(() {
                  _draft = _draft.copyWith(recoveryBias: v.round());
                }),
              ),
              _SliderSetting(
                label: 'Duracion base',
                value: _draft.defaultSessionMinutes.toDouble(),
                min: 25,
                max: 120,
                divisions: 19,
                displayValue: '${_draft.defaultSessionMinutes} min',
                onChanged: (v) => setState(() {
                  _draft = _draft.copyWith(defaultSessionMinutes: v.round());
                }),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Personalidad del coach',
            children: [
              DropdownButtonFormField<CoachPersonality>(
                key: ValueKey<String>(
                    'personality-${_draft.coachPersonality.name}'),
                initialValue: _draft.coachPersonality,
                decoration: const InputDecoration(
                  labelText: 'Estilo del coach',
                  prefixIcon: Icon(Icons.psychology_alt_outlined),
                ),
                items: CoachPersonality.values
                    .map((value) => DropdownMenuItem<CoachPersonality>(
                          value: value,
                          child: Text(coachPersonalityLabel(value)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _draft = _draft.copyWith(coachPersonality: value);
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CoachTone>(
                key: ValueKey<String>('tone-${_draft.coachTone.name}'),
                initialValue: _draft.coachTone,
                decoration: const InputDecoration(
                  labelText: 'Tono comunicacion',
                  prefixIcon: Icon(Icons.record_voice_over_outlined),
                ),
                items: CoachTone.values
                    .map((value) => DropdownMenuItem<CoachTone>(
                          value: value,
                          child: Text(coachToneLabel(value)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _draft = _draft.copyWith(coachTone: value);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Comportamiento',
            children: [
              SwitchListTile(
                value: _draft.strictSafetyMode,
                title: const Text('Modo seguridad estricto'),
                subtitle: const Text('Prioriza tecnica y riesgo bajo.'),
                onChanged: (v) => setState(() {
                  _draft = _draft.copyWith(strictSafetyMode: v);
                }),
              ),
              SwitchListTile(
                value: _draft.explainTechnique,
                title: const Text('Explicar tecnica detallada'),
                subtitle: const Text('Incluye cues y errores frecuentes.'),
                onChanged: (v) => setState(() {
                  _draft = _draft.copyWith(explainTechnique: v);
                }),
              ),
              SwitchListTile(
                value: _draft.includeNutritionTips,
                title: const Text('Sugerencias de nutricion'),
                subtitle: const Text('Anade recomendaciones alimentarias.'),
                onChanged: (v) => setState(() {
                  _draft = _draft.copyWith(includeNutritionTips: v);
                }),
              ),
              SwitchListTile(
                value: _draft.adaptiveProgression,
                title: const Text('Progresion adaptativa'),
                subtitle: const Text('Ajusta carga segun rendimiento semanal.'),
                onChanged: (v) => setState(() {
                  _draft = _draft.copyWith(adaptiveProgression: v);
                }),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar configuracion'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SliderSetting extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;

  const _SliderSetting({
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 132,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 62,
            child: Text(
              displayValue,
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
