import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gym_trainer_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:gym_trainer_app/core/theme/app_colors.dart';
import 'package:gym_trainer_app/shared/widgets/gym_card.dart';
import 'package:gym_trainer_app/features/exercises/data/exercise_api.dart';
import 'package:gym_trainer_app/features/exercises/domain/exercise.dart';
import 'package:gym_trainer_app/features/ai/presentation/providers/ai_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _api = ExerciseApi();
  late Future<List<Exercise>> _futureExercises;

  @override
  void initState() {
    super.initState();
    _futureExercises = _api.fetchExercises();
    // Pre-load the active weekly plan on application startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(weeklyPlanProvider.notifier).loadPlans(soloActivos: false);
    });
  }

  Future<void> _reload() async {
    setState(() {
      _futureHomeData = _loadHomeData();
    });
    await _futureHomeData;
  }

  Future<void> _openExerciseCatalog() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ExerciseCatalogScreen()),
    );
    await _reload();
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WorkoutHistoryScreen()),
    );
    await _reload();
  }

  void _openProfileTab() {
    setState(() => _selectedIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.nombre ?? 'Atleta';

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F12),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B00),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF15151B),
        ),
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF15151B), Color(0xFF0F0F12)],
            ),
          ),
          child: RefreshIndicator(
            color: const Color(0xFFFF6B00),
            backgroundColor: const Color(0xFF15151B),
            onRefresh: _reload,
            child: CustomScrollView(
              slivers: [
                _buildAppBar(userName),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _buildDailyProgress(),
                        const SizedBox(height: 28),
                        _buildSectionHeader('Tu Panel Deportivo'),
                        const SizedBox(height: 16),
                        _buildDashboardGrid(),
                        const SizedBox(height: 36),
                        _buildSectionHeader('Catálogo de Ejercicios'),
                        const SizedBox(height: 16),
                        _buildExercisesList(),
                        const SizedBox(height: 120), // Extra bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(String userName) {
    return SliverAppBar(
      expandedHeight: 130,
      floating: true,
      pinned: true,
      backgroundColor: const Color(0xFF15151B),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HOLA, $userName!',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tu evolución física continúa hoy',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white70),
          onPressed: () => context.push('/settings'),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white70),
          onPressed: () => ref.read(authProvider.notifier).logout(),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: const Color(0xFFFF6B00),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyProgress() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B00), Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B00).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rendimiento Diario',
                      style: GoogleFonts.outfit(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¡Llevas completado el 85% de tu objetivo semanal!',
                      style: GoogleFonts.inter(
                        color: Colors.black.withOpacity(0.75),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  value: 0.85,
                  backgroundColor: Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  strokeWidth: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.15,
      children: [
        _buildDashboardTile(
          icon: Icons.flash_on_rounded,
          label: 'Entrenar Hoy',
          color: const Color(0xFFFFB300),
          isHighlight: true,
          onTap: () => context.push('/sessions'),
        ),
        _buildDashboardTile(
          icon: Icons.emoji_events_rounded,
          label: 'Historial',
          color: const Color(0xFF00E676),
          onTap: () => context.push('/daily-records'),
        ),
        _buildDashboardTile(
          icon: Icons.auto_awesome_rounded,
          label: 'Planificador IA',
          color: const Color(0xFFFF6B00),
          onTap: () => context.push('/ai'),
        ),
        _buildDashboardTile(
          icon: Icons.person_outline_rounded,
          label: 'Perfil & Salud',
          color: const Color(0xFF00E5FF),
          onTap: () => context.push('/health-profile'),
        ),
      ],
    );
  }

  Widget _buildDashboardTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isHighlight = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF15151B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight ? color.withOpacity(0.4) : Colors.white.withOpacity(0.06),
          width: isHighlight ? 1.5 : 1,
        ),
        boxShadow: isHighlight 
          ? [BoxShadow(color: color.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))] 
          : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                  color: isHighlight ? color : Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExercisesList() {
    return FutureBuilder<List<Exercise>>(
      future: _futureExercises,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
            ),
          );
        }
        if (snapshot.hasError) {
          return GymCard(
            child: Column(
              children: [
                const Icon(Icons.cloud_off, size: 40, color: Colors.white24),
                const SizedBox(height: 12),
                const Text('Error al cargar ejercicios', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextButton(onPressed: _reload, child: const Text('Reintentar', style: TextStyle(color: Color(0xFFFF6B00)))),
              ],
            ),
          );
        }
        final exercises = snapshot.data ?? [];
        if (exercises.isEmpty) {
          return const GymCard(
            child: Center(child: Text('No hay ejercicios disponibles')),
          );
        }
        return Column(
          children: exercises.take(5).map((e) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF15151B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFFF6B00).withOpacity(0.1),
                    child: Text(
                      e.name.isNotEmpty ? e.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.name,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${e.muscleGroup} · ${e.difficulty}',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white24),
                ],
              ),
            ),
          )).toList(),
        );
      },
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _CompactListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CompactListItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
            child: Icon(icon, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiCoachSummary extends StatelessWidget {
  final AiStatus status;

  const _AiCoachSummary({required this.status});

  @override
  Widget build(BuildContext context) {
    final readyColor = status.enabled ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 14, color: readyColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.enabled
                      ? 'Coach backend disponible'
                      : 'Coach pendiente de configuración',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Proveedor: ${status.provider}. ${status.personalizationReady ? 'El perfil ya aporta contexto.' : 'Faltan más datos de perfil para personalizar mejor.'}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ComingSoonTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Chip(label: Text('Próximamente')),
        ],
      ),
    );
  }
}

class _HomeErrorState extends StatelessWidget {
  final String error;
  final Future<void> Function() onRetry;

  const _HomeErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.cloud_off, size: 40),
                const SizedBox(height: 12),
                const Text('No se pudo cargar la home.'),
                const SizedBox(height: 8),
                Text(error, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
