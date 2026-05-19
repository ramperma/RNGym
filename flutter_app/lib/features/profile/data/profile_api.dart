import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/env.dart';
import '../domain/user_profile.dart';

class ProfileApi {
  Future<UserProfile> fetchProfile() async {
    final response =
        await http.get(Uri.parse('${Env.apiBaseUrl}/user-profile'));
    if (response.statusCode != 200) {
      throw Exception('Backend error: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Backend error: missing user profile payload');
    }

    return UserProfile.fromJson(data);
  }

  Future<UserProfile> saveProfile(UserProfileUpdate update) async {
    final response = await http.put(
      Uri.parse('${Env.apiBaseUrl}/user-profile'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(update.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Backend error: ${response.statusCode} ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Backend error: missing saved user profile payload');
    }

    return UserProfile.fromJson(data);
  }

  Future<AiStatus> fetchAiStatus() async {
    final response = await http.get(Uri.parse('${Env.apiBaseUrl}/ai/status'));
    if (response.statusCode != 200) {
      throw Exception('Backend error: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Backend error: missing AI status payload');
    }

    return AiStatus.fromJson(data);
  }
}
