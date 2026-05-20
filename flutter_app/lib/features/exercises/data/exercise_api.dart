import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/app_config.dart';
import '../../../core/env.dart';
import '../domain/exercise.dart';

class ExerciseApi {
  /// Returns the active base URL: the one the user configured at runtime,
  /// or the compile-time default if none has been set yet.
  String get _base => AppConfig.baseUrl ?? Env.apiBaseUrl;

  Future<List<Exercise>> fetchExercises() async {
    final uri = Uri.parse('$_base/exercises');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Backend error: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body['data'] as List<dynamic>?) ?? [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(Exercise.fromJson)
        .toList();
  }

  Future<Exercise> fetchExerciseDetail(String exerciseId) async {
    final uri = Uri.parse('$_base/exercises/$exerciseId');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Backend error: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Backend error: missing exercise payload');
    }

    return Exercise.fromJson(data);
  }
}
