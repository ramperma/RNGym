import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AIExplanationCache {
  static const String _prefix = 'ai_explain_';

  String _cacheKey({
    required String nombreEjercicio,
    String? grupoMuscular,
    String? machineNombre,
    String? notasPlan,
  }) {
    final hash = Object.hash(
      nombreEjercicio.trim().toLowerCase(),
      grupoMuscular?.trim().toLowerCase(),
      machineNombre?.trim().toLowerCase(),
      notasPlan?.trim().toLowerCase(),
    );
    return '$_prefix$hash';
  }

  Future<List<Map<String, dynamic>>?> getMessages({
    required String nombreEjercicio,
    String? grupoMuscular,
    String? machineNombre,
    String? notasPlan,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _cacheKey(
      nombreEjercicio: nombreEjercicio,
      grupoMuscular: grupoMuscular,
      machineNombre: machineNombre,
      notasPlan: notasPlan,
    );
    final jsonStr = prefs.getString(key);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveMessages({
    required String nombreEjercicio,
    String? grupoMuscular,
    String? machineNombre,
    String? notasPlan,
    required List<Map<String, dynamic>> messages,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _cacheKey(
      nombreEjercicio: nombreEjercicio,
      grupoMuscular: grupoMuscular,
      machineNombre: machineNombre,
      notasPlan: notasPlan,
    );
    await prefs.setString(key, jsonEncode(messages));
  }

  Future<void> clearMessages({
    required String nombreEjercicio,
    String? grupoMuscular,
    String? machineNombre,
    String? notasPlan,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _cacheKey(
      nombreEjercicio: nombreEjercicio,
      grupoMuscular: grupoMuscular,
      machineNombre: machineNombre,
      notasPlan: notasPlan,
    );
    await prefs.remove(key);
  }
}
