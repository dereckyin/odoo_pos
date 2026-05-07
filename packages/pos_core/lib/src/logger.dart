import 'package:logging/logging.dart';

/// Lightweight wrapper around `package:logging` so feature code does not
/// depend on a specific logger implementation.
class AppLogger {
  AppLogger(this._logger);

  factory AppLogger.named(String name) => AppLogger(Logger(name));

  final Logger _logger;

  static void initialize({Level level = Level.INFO, void Function(LogRecord)? onRecord}) {
    Logger.root.level = level;
    Logger.root.onRecord.listen(onRecord ?? _defaultPrint);
  }

  static void _defaultPrint(LogRecord r) {
    final ts = r.time.toIso8601String();
    final err = r.error != null ? '\n  err: ${r.error}' : '';
    final stack = r.stackTrace != null ? '\n${r.stackTrace}' : '';
    // ignore: avoid_print
    print('[$ts] ${r.level.name.padRight(7)} ${r.loggerName}: ${r.message}$err$stack');
  }

  void info(Object? message) => _logger.info(message);
  void warn(Object? message, [Object? error, StackTrace? stack]) =>
      _logger.warning(message, error, stack);
  void error(Object? message, [Object? error, StackTrace? stack]) =>
      _logger.severe(message, error, stack);
  void debug(Object? message) => _logger.fine(message);
  void trace(Object? message) => _logger.finer(message);
}
