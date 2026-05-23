import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/user_exercise.dart';

class UserExerciseApi {
  final ApiClient _client;

  UserExerciseApi(this._client);

  Future<List<UserExercise>> listExercises() async {
    final response = await _client.get('/user-exercises');
    return (response.data as List<dynamic>)
        .map((e) => UserExercise.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserExercise> createExercise(Map<String, dynamic> data) async {
    final response = await _client.post('/user-exercises', data: data);
    return UserExercise.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserExercise> updateExercise(String id, Map<String, dynamic> data) async {
    final response = await _client.put('/user-exercises/$id', data: data);
    return UserExercise.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteExercise(String id) async {
    await _client.delete('/user-exercises/$id');
  }

  Future<String> uploadPhoto(File file) async {
    final path = file.path;
    final ext = path.contains('.') ? path.split('.').last.toLowerCase() : 'jpeg';
    final mimeSubtype = (ext == 'jpg') ? 'jpeg' : ext;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        path,
        filename: path.split('/').last,
        contentType: DioMediaType.parse('image/$mimeSubtype'),
      ),
    });
    final response = await _client.uploadFile('/user-exercises/upload-photo', formData);
    return (response.data as Map<String, dynamic>)['foto_path'] as String;
  }
}
