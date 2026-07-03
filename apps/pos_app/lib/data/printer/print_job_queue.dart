import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_core/pos_core.dart';

/// A failed print job surfaced to the UI (toast / snackbar).
class PrintJobFailure {
  PrintJobFailure({
    required this.label,
    required this.error,
    required this.attempts,
    required this.at,
  });

  final String label;
  final Object error;
  final int attempts;
  final DateTime at;

  @override
  String toString() => '$label: $error';
}

/// Serialises print I/O with automatic retry. Callers enqueue jobs instead of
/// talking to sockets directly so transient LAN hiccups do not drop tickets.
class PrintJobQueue {
  PrintJobQueue(this._logger);

  final AppLogger _logger;
  Future<void> _chain = Future<void>.value();
  final List<PrintJobFailure> _recentFailures = [];
  static const _maxRecent = 10;

  List<PrintJobFailure> get recentFailures => List.unmodifiable(_recentFailures);

  /// Runs [job] up to [maxAttempts] times (default 3). Jobs execute serially.
  Future<void> run(
    String label,
    Future<void> Function() job, {
    int maxAttempts = 3,
  }) {
    final completer = Completer<void>();
    _chain = _chain.then((_) async {
      Object? lastError;
      StackTrace? lastStack;
      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          await job();
          completer.complete();
          return;
        } catch (e, st) {
          lastError = e;
          lastStack = st;
          _logger.warn('print job "$label" attempt $attempt/$maxAttempts failed', e, st);
          if (attempt < maxAttempts) {
            await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
          }
        }
      }
      final failure = PrintJobFailure(
        label: label,
        error: lastError ?? StateError('unknown'),
        attempts: maxAttempts,
        at: DateTime.now(),
      );
      _recentFailures.insert(0, failure);
      if (_recentFailures.length > _maxRecent) {
        _recentFailures.removeLast();
      }
      completer.completeError(lastError!, lastStack);
    });
    return completer.future;
  }

  void clearFailures() => _recentFailures.clear();
}

final printJobQueueProvider = Provider<PrintJobQueue>(
  (ref) => PrintJobQueue(AppLogger.named('print-queue')),
);

final printJobFailuresProvider = StateProvider<List<PrintJobFailure>>((ref) => []);
