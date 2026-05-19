import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class GymTrainerApp extends ConsumerWidget {
  const GymTrainerApp({super.key});

  // Paleta principal
  static const _navy = Color(0xFF0F2747);
  static const _blue = Color(0xFF1363DF);
  static const _cyan = Color(0xFF20C5D9);
  static const _pearl = Color(0xFFF4F7FB);
  static const _cardBorder = Color(0xFFDDE6F0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Gym Trainer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}