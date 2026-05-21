import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/app_config.dart';
import '../../../../core/env.dart';
import '../../../../core/error_reporter.dart';
import '../domain/dashboard_stats.dart';

class DashboardApi {
  String get _base => AppConfig.baseUrl ?? Env.apiBaseUrl;

  Future<DashboardStats> fetchStats() async {
    try {
      final uri = Uri.parse('$_base/dashboard/stats');
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        final detail = 'HTTP ${response.statusCode} en $uri\nBody: ${response.body}';
        ErrorReporter.report(
          Exception('[DashboardApi] $detail'),
          StackTrace.current,
          source: 'DashboardApi.fetchStats',
        );
        throw Exception('Error cargando stats: ${response.statusCode}\nURI: $uri\nRespuesta: ${response.body}');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return DashboardStats.fromJson(body);
    } catch (e, st) {
      ErrorReporter.report(
        Exception('[DashboardApi] fetchStats falló: $e'),
        st,
        source: 'DashboardApi.fetchStats',
      );
      rethrow;
    }
  }
}
