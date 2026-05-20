/// Singleton that holds the active API base URL at runtime.
///
/// Updated by [AuthNotifier._initializeServerUrlAndAuth] on startup (from
/// secure storage) and by [ServerConfigScreen] when the user saves a new
/// server URL.  All plain-Dart API classes (ExerciseApi, ProfileApi, etc.)
/// that cannot access Riverpod providers read from here instead of the
/// compile-time [Env.apiBaseUrl].
class AppConfig {
  AppConfig._();

  static String? _baseUrl;

  /// The currently active base URL (e.g. "https://gym.example.com/api/v1").
  /// Falls back to null when no server has been configured yet.
  static String? get baseUrl => _baseUrl;

  /// Update the active base URL.  Call this whenever the user saves a new
  /// server address or when the stored URL is loaded at startup.
  static void setBaseUrl(String url) {
    _baseUrl = url.isEmpty ? null : url;
  }

  /// Clear the stored URL (e.g. when the user disconnects from the server).
  static void clearBaseUrl() {
    _baseUrl = null;
  }
}
