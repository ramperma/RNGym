import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/error_reporter.dart';
import 'core/theme/app_theme.dart';

class GymTrainerApp extends ConsumerWidget {
  const GymTrainerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return ErrorReporterWrapper(
      child: MaterialApp.router(
        title: 'Gym Trainer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: router,
      ),
    );
  }
}