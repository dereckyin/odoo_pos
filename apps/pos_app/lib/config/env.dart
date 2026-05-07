/// Compile-time configuration. Override via `--dart-define`:
///
///   flutter run -d macos --dart-define=API_BASE_URL=http://10.0.0.5:8000
class Env {
  static const apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000');

  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  static const enableDebugLogger =
      bool.fromEnvironment('DEBUG_LOG', defaultValue: true);

  /// Local DB filename inside app documents directory.
  static const localDbFile = 'pos.sqlite';
}
