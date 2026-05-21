import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ErrorReporter {
  static final List<AppError> _errors = [];
  static BuildContext? _context;

  static void attachContext(BuildContext context) {
    _context = context;
  }

  static void detachContext() {
    _context = null;
  }

  static List<AppError> get errors => List.unmodifiable(_errors);

  static void report(Object error, StackTrace stackTrace, {String? source}) {
    final appError = AppError(
      timestamp: DateTime.now(),
      error: error.toString(),
      stackTrace: stackTrace.toString(),
      source: source ?? 'Unknown',
    );

    _errors.add(appError);

    // Limitar a los últimos 50 errores
    if (_errors.length > 50) {
      _errors.removeAt(0);
    }

    // Mostrar dialogo si hay contexto disponible y con MaterialLocalizations
    if (_context != null && _context!.mounted) {
      try {
        _showErrorDialog(_context!, appError);
      } catch (_) {
        // Contexto sin MaterialLocalizations — no mostrar dialogo aqui
      }
    }
  }

  static void _showErrorDialog(BuildContext context, AppError error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ErrorReportDialog(error: error),
    );
  }

  static Future<void> sendErrorEmail(AppError error) async {
    final subject = Uri.encodeComponent('Error en Gym Trainer - ${error.source}');
    final body = Uri.encodeComponent(
      'FECHA: ${error.timestamp}\n'
      'ORIGEN: ${error.source}\n\n'
      'ERROR:\n${error.error}\n\n'
      'STACK TRACE:\n${error.stackTrace}\n\n'
      '---\n'
      'Por favor, describe lo que estabas haciendo cuando ocurrió el error:',
    );

    final uri = Uri.parse('mailto:ramperma@gmail.com?subject=$subject&body=$body');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Si no se puede abrir el email, copiar al portapapeles
      await Clipboard.setData(ClipboardData(text:
        'SUBJECT: Error en Gym Trainer - ${error.source}\n\n'
        'BODY:\n'
        'FECHA: ${error.timestamp}\n'
        'ORIGEN: ${error.source}\n\n'
        'ERROR:\n${error.error}\n\n'
        'STACK TRACE:\n${error.stackTrace}'
      ));
      if (_context != null && _context!.mounted) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          const SnackBar(
            content: Text('Error copiado al portapapeles. Pégalo en un email.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}

class AppError {
  final DateTime timestamp;
  final String error;
  final String stackTrace;
  final String source;

  AppError({
    required this.timestamp,
    required this.error,
    required this.stackTrace,
    required this.source,
  });
}

class ErrorReportDialog extends StatelessWidget {
  final AppError error;

  const ErrorReportDialog({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF131317),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bug_report, color: Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Ha ocurrido un error',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Origen: ${error.source}',
              style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C24),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                error.error,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pulsa el botón de abajo para enviar el error al desarrollador. Esto abrirá tu app de correo con el error ya escrito.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar', style: TextStyle(color: Colors.white38)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            Navigator.pop(context);
            ErrorReporter.sendErrorEmail(error);
          },
          icon: const Icon(Icons.email, size: 16),
          label: const Text('Enviar error', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class ErrorReporterWrapper extends StatefulWidget {
  final Widget child;

  const ErrorReporterWrapper({super.key, required this.child});

  @override
  State<ErrorReporterWrapper> createState() => _ErrorReporterWrapperState();
}

class _ErrorReporterWrapperState extends State<ErrorReporterWrapper> {
  @override
  void initState() {
    super.initState();
    ErrorReporter.detachContext();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) {
        ErrorReporter.attachContext(ctx);
        return widget.child;
      },
    );
  }
}
