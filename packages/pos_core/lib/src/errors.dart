/// Base class for domain-level failures.
///
/// We avoid throwing exceptions across architecture boundaries; instead
/// repositories / use-cases return `Result<T, AppError>` (see `result.dart`).
sealed class AppError implements Exception {
  const AppError(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType($message)';
}

class NetworkError extends AppError {
  const NetworkError(super.message, {super.cause, super.stackTrace, this.statusCode});
  final int? statusCode;
}

class TimeoutError extends AppError {
  const TimeoutError(super.message, {super.cause, super.stackTrace});
}

class OfflineError extends AppError {
  const OfflineError([super.message = 'No network connection']);
}

class AuthError extends AppError {
  const AuthError(super.message, {super.cause, super.stackTrace});
}

class NotFoundError extends AppError {
  const NotFoundError(super.message, {super.cause, super.stackTrace});
}

class ValidationError extends AppError {
  const ValidationError(super.message, {this.fieldErrors = const {}, super.cause, super.stackTrace});
  final Map<String, String> fieldErrors;
}

class ConflictError extends AppError {
  const ConflictError(super.message, {super.cause, super.stackTrace});
}

class StorageError extends AppError {
  const StorageError(super.message, {super.cause, super.stackTrace});
}

class PaymentError extends AppError {
  const PaymentError(super.message, {this.gatewayCode, super.cause, super.stackTrace});
  final String? gatewayCode;
}

class PrinterError extends AppError {
  const PrinterError(super.message, {super.cause, super.stackTrace});
}

class UnknownError extends AppError {
  const UnknownError(super.message, {super.cause, super.stackTrace});
}
