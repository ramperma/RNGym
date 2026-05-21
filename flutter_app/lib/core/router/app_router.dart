import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/health_profile/presentation/screens/health_profile_screen.dart';
import '../../features/routines/presentation/screens/routine_list_screen.dart';
import '../../features/sessions/presentation/screens/session_list_screen.dart';
import '../../features/sessions/presentation/screens/session_detail_screen.dart';
import '../../features/sessions/presentation/screens/active_workout_screen.dart';
import '../../features/daily_records/presentation/screens/daily_records_screen.dart';
import '../../features/ai/presentation/screens/ai_recommendation_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/screens/server_config_screen.dart';

class RouterNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final routerNotifierProvider = Provider((ref) {
  final notifier = RouterNotifier();
  ref.listen(authProvider, (previous, next) {
    notifier.refresh();
  });
  ref.listen(apiUrlProvider, (previous, next) {
    notifier.refresh();
  });
  return notifier;
});

final routerProvider = Provider((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      // Todavía cargando desde storage — no tomar decisiones de routing aún
      if (authState.status == AuthStatus.initial) return null;

      final serverUrl = ref.read(apiUrlProvider);
      final hasServer = serverUrl != null;
      final isOnServerConfig = state.matchedLocation == '/server-config';

      // Si no hay servidor configurado, obligar a ir a configurar el servidor
      if (!hasServer) {
        return isOnServerConfig ? null : '/server-config';
      }

      // Si ya hay servidor y está en la pantalla de configuración, redirigir a Login o Home
      if (hasServer && isOnServerConfig) {
        return authState.status == AuthStatus.authenticated ? '/' : '/login';
      }

      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isOnAuth = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!isLoggedIn && !isOnAuth) return '/login';
      if (isLoggedIn && isOnAuth) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/server-config', builder: (context, state) => const ServerConfigScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/health-profile', builder: (context, state) => const HealthProfileScreen()),
      GoRoute(path: '/routines', builder: (context, state) => const RoutineListScreen()),
      GoRoute(path: '/sessions', builder: (context, state) => const ActiveWorkoutScreen()),
      GoRoute(
        path: '/sessions/:id',
        builder: (context, state) => SessionDetailScreen(sessionId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/daily-records', builder: (context, state) => const SessionListScreen()),
      GoRoute(path: '/ai', builder: (context, state) => const AIRecommendationScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    ],
  );
});