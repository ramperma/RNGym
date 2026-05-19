import 'package:flutter/material.dart';

import '../data/training_management_store.dart';
import '../data/training_templates_repository.dart';
import '../domain/training_management_config.dart';
import '../domain/training_plan_template.dart';
import 'training_management_screen.dart';
import 'training_plan_detail_screen.dart';

class TrainingHubScreen extends StatefulWidget {
  const TrainingHubScreen({super.key});

  @override
  State<TrainingHubScreen> createState() => _TrainingHubScreenState();
}

class _TrainingHubScreenState extends State<TrainingHubScreen> {
  final _repository = const TrainingTemplatesRepository();
  final _store = TrainingManagementStore.instance;

  BodyFocus? _bodyFocus;
  TrainingObjective? _objective;
  ExperienceLevel? _experience;
  int _practiceDays = 3;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final config = _store.config;
        final plans = _repository.filterTemplates(
          config: config,
          bodyFocus: _bodyFocus,
          objective: _objective,
          experience: _experience,
          practiceDays: _practiceDays,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            _HeaderCard(
              config: config,
              onManage: _openManagement,
            ),
            const SizedBox(height: 14),
            _FilterCard(
              bodyFocus: _bodyFocus,
              objective: _objective,
              experience: _experience,
              practiceDays: _practiceDays,
              onBodyChanged: (value) => setState(() => _bodyFocus = value),
              onObjectiveChanged: (value) => setState(() => _objective = value),
              onExperienceChanged: (value) => setState(() => _experience = value),
              onPracticeChanged: (value) => setState(() => _practiceDays = value),
              onClear: () {
                setState(() {
                  _bodyFocus = null;
                  _objective = null;
                  _experience = null;
                  _practiceDays = 3;
                });
              },
            ),
            const SizedBox(height: 14),
            Text(
              'Planes predisenados (${plans.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            if (plans.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('No hay planes con estos filtros. Ajusta la configuracion.'),
                ),
              )
            else
              ...plans.map((plan) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PlanCard(
                    plan: plan,
                    onTap: () => _openPlanDetail(plan, config),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Future<void> _openManagement() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TrainingManagementScreen(),
      ),
    );
  }

  Future<void> _openPlanDetail(
    TrainingPlanTemplate plan,
    TrainingManagementConfig config,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TrainingPlanDetailScreen(plan: plan, config: config),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final TrainingManagementConfig config;
  final VoidCallback onManage;

  const _HeaderCard({required this.config, required this.onManage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2747), Color(0xFF1E4F8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pestana de entrenamientos',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Bloque cerrado con planes por objetivo, cuerpo, experiencia y practica semanal.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFD8E6F8),
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Coach ${coachPersonalityLabel(config.coachPersonality)} · '
            '${coachToneLabel(config.coachTone)} · '
            'Temp ${config.aiTemperature.toStringAsFixed(2)}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: const Color(0xFFDFECFB)),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF20C5D9),
              foregroundColor: const Color(0xFF042B32),
            ),
            onPressed: onManage,
            icon: const Icon(Icons.tune),
            label: const Text('Gestion de entrenamiento'),
          ),
        ],
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  final BodyFocus? bodyFocus;
  final TrainingObjective? objective;
  final ExperienceLevel? experience;
  final int practiceDays;
  final ValueChanged<BodyFocus?> onBodyChanged;
  final ValueChanged<TrainingObjective?> onObjectiveChanged;
  final ValueChanged<ExperienceLevel?> onExperienceChanged;
  final ValueChanged<int> onPracticeChanged;
  final VoidCallback onClear;

  const _FilterCard({
    required this.bodyFocus,
    required this.objective,
    required this.experience,
    required this.practiceDays,
    required this.onBodyChanged,
    required this.onObjectiveChanged,
    required this.onExperienceChanged,
    required this.onPracticeChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Filtros',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Limpiar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<BodyFocus?>(
              key: ValueKey<String>('body-${bodyFocus?.name ?? 'all'}'),
              initialValue: bodyFocus,
              decoration: const InputDecoration(
                labelText: 'Parte del cuerpo',
                prefixIcon: Icon(Icons.accessibility_new),
              ),
              items: [
                const DropdownMenuItem<BodyFocus?>(
                  value: null,
                  child: Text('Todas'),
                ),
                ...BodyFocus.values.map(
                  (value) => DropdownMenuItem<BodyFocus?>(
                    value: value,
                    child: Text(bodyFocusLabel(value)),
                  ),
                ),
              ],
              onChanged: onBodyChanged,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<TrainingObjective?>(
              key: ValueKey<String>(
                  'objective-${objective?.name ?? 'all'}'),
              initialValue: objective,
              decoration: const InputDecoration(
                labelText: 'Objetivo',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: [
                const DropdownMenuItem<TrainingObjective?>(
                  value: null,
                  child: Text('Todos'),
                ),
                ...TrainingObjective.values.map(
                  (value) => DropdownMenuItem<TrainingObjective?>(
                    value: value,
                    child: Text(objectiveLabel(value)),
                  ),
                ),
              ],
              onChanged: onObjectiveChanged,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<ExperienceLevel?>(
              key: ValueKey<String>(
                  'experience-${experience?.name ?? 'all'}'),
              initialValue: experience,
              decoration: const InputDecoration(
                labelText: 'Experiencia',
                prefixIcon: Icon(Icons.military_tech_outlined),
              ),
              items: [
                const DropdownMenuItem<ExperienceLevel?>(
                  value: null,
                  child: Text('Cualquier nivel'),
                ),
                ...ExperienceLevel.values.map(
                  (value) => DropdownMenuItem<ExperienceLevel?>(
                    value: value,
                    child: Text(experienceLabel(value)),
                  ),
                ),
              ],
              onChanged: onExperienceChanged,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Practica semanal',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  '$practiceDays dias',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            Slider(
              value: practiceDays.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              onChanged: (value) => onPracticeChanged(value.round()),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final TrainingPlanTemplate plan;
  final VoidCallback onTap;

  const _PlanCard({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1363DF), Color(0xFF1E4F8A)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.calendar_view_week, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(plan.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TinyTag(objectiveLabel(plan.objective)),
                        _TinyTag(experienceLabel(plan.experience)),
                        _TinyTag('${plan.minPracticeDays}-${plan.maxPracticeDays} dias'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _TinyTag extends StatelessWidget {
  final String label;
  const _TinyTag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FC),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
