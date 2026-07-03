/// Compile-time configuration. Override via `--dart-define`:
///
///   flutter run -d macos --dart-define=API_BASE_URL=http://10.0.0.5:8000
class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://pos.myvnc.com/api',
  );

  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  static const enableDebugLogger = bool.fromEnvironment(
    'DEBUG_LOG',
    defaultValue: true,
  );

  /// Local DB filename inside app documents directory.
  static const localDbFile = 'pos.sqlite';

  /// Temporary book-retail demo (scan ISBN → checkout). Remove when integrated.
  static const bookSaleDemo = bool.fromEnvironment(
    'BOOK_SALE_DEMO',
    defaultValue: true,
  );

  static const customerBaseUrl = String.fromEnvironment(
    'CUSTOMER_BASE_URL',
    defaultValue: 'https://pos.myvnc.com/customer',
  );

  static const bookSaleDemoApiUrl = String.fromEnvironment(
    'BOOK_SALE_DEMO_API_URL',
    defaultValue: 'https://api.taaze.tw/api/v1/book/latest',
  );
}
