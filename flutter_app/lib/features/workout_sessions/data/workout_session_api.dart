import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/env.dart';
import '../domain/workout_session.dart';

class WorkoutSessionApi {
  Future<List<WorkoutSession>> fetchSessions() async {
    final response =
        await http.get(Uri.parse('${Env.apiBaseUrl}/workout-sessions'));
    if (response.statusCode != 200) {
      throw Exception('Backend error: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body['data'] as List<dynamic>?) ?? [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(WorkoutSession.fromJson)
        .toList();
  }

  Future<WorkoutSession> createQuickSession({
    required String exerciseId,
    required int setsCompleted,
    required String repsCompleted,
    String notes = '',
  }) async {
    final response = await http.post(
      Uri.parse('${Env.apiBaseUrl}/workout-sessions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'exercise_id': exerciseId,
        'performed_at': DateTime.now().toUtc().toIso8601String(),
        'sets_completed': setsCompleted,
        'reps_completed': repsCompleted,
        'notes': notes,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Backend error: ${response.statusCode} ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Backend error: missing workout session payload');
    }

    return WorkoutSession.fromJson(data);
  }
}
