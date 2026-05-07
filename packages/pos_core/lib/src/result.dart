import 'errors.dart';

/// Functional result type. We prefer this over exceptions for predictable
/// control flow in repositories and use-cases.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T? getOrNull() => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  AppError? errorOrNull() => switch (this) {
        Ok<T>() => null,
        Err<T>(:final error) => error,
      };

  R fold<R>(R Function(T value) onOk, R Function(AppError error) onErr) =>
      switch (this) {
        Ok<T>(:final value) => onOk(value),
        Err<T>(:final error) => onErr(error),
      };

  Result<R> map<R>(R Function(T) f) => switch (this) {
        Ok<T>(:final value) => Ok(f(value)),
        Err<T>(:final error) => Err(error),
      };

  Future<Result<R>> mapAsync<R>(Future<R> Function(T) f) async =>
      switch (this) {
        Ok<T>(:final value) => Ok(await f(value)),
        Err<T>(:final error) => Err(error),
      };

  Result<R> flatMap<R>(Result<R> Function(T) f) => switch (this) {
        Ok<T>(:final value) => f(value),
        Err<T>(:final error) => Err(error),
      };
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.error);
  final AppError error;
}

/// Run a callback that may throw and lift the result into a [Result].
Future<Result<T>> guardAsync<T>(Future<T> Function() body, {AppError Function(Object e, StackTrace s)? onError}) async {
  try {
    return Ok(await body());
  } catch (e, s) {
    return Err(onError?.call(e, s) ?? UnknownError(e.toString(), cause: e, stackTrace: s));
  }
}

Result<T> guard<T>(T Function() body, {AppError Function(Object e, StackTrace s)? onError}) {
  try {
    return Ok(body());
  } catch (e, s) {
    return Err(onError?.call(e, s) ?? UnknownError(e.toString(), cause: e, stackTrace: s));
  }
}
