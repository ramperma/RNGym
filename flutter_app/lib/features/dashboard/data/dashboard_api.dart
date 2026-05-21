import 'package:dio/dio.dart';
import '../../../../core/error_reporter.dart';
import '../../../../core/network/api_client.dart';
import '../domain/dashboard_stats.dart';

class DashboardApi {
  final ApiClient _client;

  DashboardApi(this._client);

  Future<DashboardStats> fetchStats() async {
    try {
      final response = await _client.get('/dashboard/stats');
      return DashboardStats.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail =
          'HTTP ${e.response?.statusCode} en /dashboard/stats\nBody: ${e.response?.data}';
      ErrorReporter.report(
        Exception('[DashboardApi] $detail'),
        e.stackTrace ?? StackTrace.current,
        source: 'DashboardApi.fetchStats',
      );
      throw Exception('Error cargando stats: ${e.response?.statusCode}\nRespuesta: ${e.response?.data}');
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
