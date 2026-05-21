import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/error_reporter.dart';

void main() {
  // Capturar errores de Flutter (errores en widgets, builds, etc.)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    ErrorReporter.report(
      details.exception,
      details.stack ?? StackTrace.current,
      source: details.library ?? 'Flutter Framework',
    );
  };

  // Capturar errores asíncronos y de zonas (futures, timers, etc.)
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    ErrorReporter.report(error, stack, source: 'Platform/Async');
    return true; // true = error manejado, no propagar más
  };

  runApp(
    const ProviderScope(
      child: ErrorReporterWrapper(
        child: GymTrainerApp(),
      ),
    ),
  );
}
