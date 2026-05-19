import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:gym_trainer_app/core/env.dart';

class TrainingPlanApi {
  Future<Map<String, dynamic>> generateTrainingPlan({
    required String trainingType,
    required int restDays,
    required List<String> selectedLimitations,
    required String additionalNotes,
    required bool wantExpertChat,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Env.apiBaseUrl}/ai/training-plan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'training_type': trainingType,
          'rest_days': restDays,
          'selected_limitations': selectedLimitations,
          'additional_notes': additionalNotes,
          'want_expert_chat': wantExpertChat,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          error['detail'] ?? 'Error al generar el plan de entrenamiento',
        );
      }
    } catch (e) {
      throw Exception('Error al generar el plan: $e');
    }
  }
}
