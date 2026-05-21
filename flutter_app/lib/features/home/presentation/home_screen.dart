import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gym_trainer_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:gym_trainer_app/core/theme/app_colors.dart';
import 'package:gym_trainer_app/core/error_reporter.dart';
import 'package:gym_trainer_app/shared/widgets/gym_card.dart';
import 'package:gym_trainer_app/features/exercises/data/exercise_api.dart';
import 'package:gym_trainer_app/features/exercises/domain/exercise.dart';
import 'package:gym_trainer_app/features/ai/presentation/providers/ai_provider.dart';
import 'package:gym_trainer_app/features/dashboard/data/dashboard_api.dart';
import 'package:gym_trainer_app/features/dashboard/domain/dashboard_stats.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _api = ExerciseApi();
  final _dashboardApi = DashboardApi();
  late Future<List<Exercise>> _futureExercises;
  late Future<DashboardStats> _futureStats;

  @override
  void initState() {
    super.initState();
    _futureExercises = _api.fetchExercises();
    _futureStats = _dashboardApi.fetchStats();
    // Pre-load the active weekly plan on application startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(weeklyPlanProvider.notifier).loadPlans(soloActivos: false);
    });
  }

  Future<void> _reload() async {
    setState(() {
      _futureExercises = _api.fetchExercises();
      _futureStats = _dashboardApi.fetchStats();
    });
    await _futureExercises;
    await _futureStats;
    await ref.read(weeklyPlanProvider.notifier).loadPlans(soloActivos: false);
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
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chevron_right),
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
    return FutureBuilder<DashboardStats>(
      future: _futureStats,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildProgressCard(completados: 0, objetivo: 4, porcentaje: 0.0, subtitulo: 'Cargando resumen...');
        }
        if (snapshot.hasError || !snapshot.hasData) {
          final errMsg = snapshot.error?.toString() ?? 'Sin datos';
          return _buildErrorProgressCard(
            context: context,
            error: errMsg,
          );
        }

        final stats = snapshot.data!;
        final pct = stats.semanalPorcentaje;
        final pctInt = (pct * 100).toInt();

        String subtitulo;
        if (stats.hoyEntrenado && stats.hoyResumen != null) {
          subtitulo = 'Hoy: ${stats.hoyResumen}';
          if (stats.hoyEjercicios > 0) {
            subtitulo += ' · ${stats.hoyEjercicios} ejercicios';
          }
        } else if (stats.proximoDia != null && stats.proximoNombre != null) {
          subtitulo = 'Próximo: ${stats.proximoDia} — ${stats.proximoNombre}';
        } else {
          subtitulo = 'Llevas $pctInt% de tu objetivo semanal';
        }

        return _buildProgressCard(
          completados: stats.semanalCompletados,
          objetivo: stats.semanalObjetivo,
          porcentaje: pct,
          subtitulo: subtitulo,
        );
      },
    );
  }

  Widget _buildProgressCard({
    required int completados,
    required int objetivo,
    required double porcentaje,
    required String subtitulo,
  }) {
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
                      subtitulo,
                      style: GoogleFonts.inter(
                        color: Colors.black.withOpacity(0.75),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$completados de $objetivo días',
                      style: GoogleFonts.inter(
                        color: Colors.black.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  value: porcentaje.clamp(0.0, 1.0),
                  backgroundColor: Colors.black12,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                  strokeWidth: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorProgressCard({required BuildContext context, required String error}) {
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
                      'No se pudo cargar el resumen',
                      style: GoogleFonts.inter(
                        color: Colors.black.withOpacity(0.75),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: Colors.black.withOpacity(0.8),
                      ),
                      icon: const Icon(Icons.bug_report, size: 14),
                      label: Text(
                        'Reportar error',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                      onPressed: () {
                        ErrorReporter.report(
                          Exception('DashboardStats error: $error'),
                          StackTrace.current,
                          source: 'HomeScreen._buildDailyProgress',
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.error_outline, color: Colors.black54, size: 40),
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
