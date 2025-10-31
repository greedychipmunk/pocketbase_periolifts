/// Generic result wrapper for error handling
///
/// Provides a type-safe way to handle success/error states
/// without throwing exceptions. Follows the Railway Oriented Programming pattern.
sealed class Result<T> {
  const Result();

  /// Create a successful result with data
  const factory Result.success(T data) = Success<T>;

  /// Create an error result with error information
  const factory Result.error(AppError error) = Error<T>;

  /// Check if the result is successful
  bool get isSuccess => this is Success<T>;

  /// Check if the result is an error
  bool get isError => this is Error<T>;

  /// Get the data if successful, null otherwise
  T? get data => isSuccess ? (this as Success<T>).data : null;

  /// Get the error if failed, null otherwise
  AppError? get error => isError ? (this as Error<T>).error : null;

  /// Transform the result data with a function
  Result<U> map<U>(U Function(T data) transform) {
    return switch (this) {
      Success(data: final data) => Result.success(transform(data)),
      Error(error: final error) => Result.error(error),
    };
  }

  /// Chain another operation that returns a Result
  Result<U> flatMap<U>(Result<U> Function(T data) transform) {
    return switch (this) {
      Success(data: final data) => transform(data),
      Error(error: final error) => Result.error(error),
    };
  }

  /// Execute a function if successful
  Result<T> onSuccess(void Function(T data) action) {
    if (isSuccess) {
      action(data as T);
    }
    return this;
  }

  /// Execute a function if error
  Result<T> onError(void Function(AppError error) action) {
    if (isError) {
      action(error!);
    }
    return this;
  }

  /// Get data or throw an exception
  T getOrThrow() {
    return switch (this) {
      Success(data: final data) => data,
      Error(error: final error) => throw error,
    };
  }

  /// Get data or return a default value
  T getOrDefault(T defaultValue) {
    return switch (this) {
      Success(data: final data) => data,
      Error() => defaultValue,
    };
  }

  /// Get data or compute it from error
  T getOrElse(T Function(AppError error) orElse) {
    return switch (this) {
      Success(data: final data) => data,
      Error(error: final error) => orElse(error),
    };
  }
}

/// Successful result containing data
class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  String toString() => 'Success($data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;
}

/// Error result containing error information
class Error<T> extends Result<T> {
  final AppError error;

  const Error(this.error);

  @override
  String toString() => 'Error($error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Error<T> &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;
}

/// Application error with detailed context
class AppError {
  final String message;
  final String type;
  final Map<String, dynamic>? details;
  final Exception? originalException;

  const AppError({
    required this.message,
    required this.type,
    this.details,
    this.originalException,
  });

  /// Create a validation error
  factory AppError.validation({
    required String message,
    Map<String, dynamic>? details,
  }) {
    return AppError(
      message: message,
      type: 'ValidationError',
      details: details,
    );
  }

  /// Create an authentication error
  factory AppError.authentication({
    required String message,
    Map<String, dynamic>? details,
  }) {
    return AppError(
      message: message,
      type: 'AuthenticationError',
      details: details,
    );
  }

  /// Create a network error
  factory AppError.network({
    required String message,
    Map<String, dynamic>? details,
    Exception? originalException,
  }) {
    return AppError(
      message: message,
      type: 'NetworkError',
      details: details,
      originalException: originalException,
    );
  }

  /// Create a server error
  factory AppError.server({
    required String message,
    Map<String, dynamic>? details,
    Exception? originalException,
  }) {
    return AppError(
      message: message,
      type: 'ServerError',
      details: details,
      originalException: originalException,
    );
  }

  /// Create a not found error
  factory AppError.notFound({
    required String message,
    Map<String, dynamic>? details,
  }) {
    return AppError(message: message, type: 'NotFoundError', details: details);
  }

  /// Create a permission error
  factory AppError.permission({
    required String message,
    Map<String, dynamic>? details,
  }) {
    return AppError(
      message: message,
      type: 'PermissionError',
      details: details,
    );
  }

  /// Create an unknown error
  factory AppError.unknown({
    required String message,
    Map<String, dynamic>? details,
    Exception? originalException,
  }) {
    return AppError(
      message: message,
      type: 'UnknownError',
      details: details,
      originalException: originalException,
    );
  }

  @override
  String toString() => 'AppError($type): $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          type == other.type;

  @override
  int get hashCode => Object.hash(message, type);
}
