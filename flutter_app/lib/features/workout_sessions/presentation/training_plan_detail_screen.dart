import 'package:flutter/material.dart';

import '../domain/training_management_config.dart';
import '../domain/training_plan_template.dart';

class TrainingPlanDetailScreen extends StatelessWidget {
  final TrainingPlanTemplate plan;
  final TrainingManagementConfig config;

  const TrainingPlanDetailScreen({
    super.key,
    required this.plan,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(plan.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F2747), Color(0xFF1E4F8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.description,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: const Color(0xFFD8E6F8)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ChipBadge(text: objectiveLabel(plan.objective)),
                    _ChipBadge(text: bodyFocusLabel(plan.bodyFocus)),
                    _ChipBadge(text: experienceLabel(plan.experience)),
                    _ChipBadge(text: '${plan.durationWeeks} semanas'),
                    _ChipBadge(text: '${plan.sessionMinutes} min/sesion'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parametros activos de gestion',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Coach ${coachPersonalityLabel(config.coachPersonality)} '
                    '(${coachToneLabel(config.coachTone)}). '
                    'Intensidad ${config.intensityBias}% · '
                    'Recuperacion ${config.recoveryBias}% · '
                    'Creatividad ${config.aiCreativity}%.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Microciclo recomendado',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          ...plan.sessions.map(
            (session) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F0FC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(session.dayLabel),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              session.focus,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...session.blocks.map(
                        (block) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(child: Text(block)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipBadge extends StatelessWidget {
  final String text;

  const _ChipBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Colors.white),
      ),
    );
  }
}
