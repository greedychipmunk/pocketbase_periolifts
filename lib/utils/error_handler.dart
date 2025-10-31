import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'result.dart';

/// Comprehensive error handling utilities for the application
///
/// Provides centralized error processing, logging, and user-friendly
/// error messages for various error types.
class ErrorHandler {
  /// Convert any exception to AppError
  ///
  /// [error] The error object to convert
  /// [context] Additional context about where the error occurred
  /// Returns a standardized AppError
  static AppError handlePocketBaseError(dynamic error, {String? context}) {
    if (error is ClientException) {
      return _handleClientException(error);
    }

    if (error is Exception) {
      return AppError.unknown(
        message: error.toString().replaceFirst('Exception: ', ''),
        originalException: error,
      );
    }

    return AppError.unknown(
      message: error?.toString() ?? 'Unknown error occurred',
    );
  }

  /// Handle PocketBase ClientException specifically
  static AppError _handleClientException(ClientException error) {
    final response = error.response;
    final statusCode = error.statusCode;

    // Extract error message
    String message = _extractErrorMessage(error);

    // Map status codes to error types
    if (statusCode >= 400 && statusCode < 500) {
      // Client errors
      if (statusCode == 400) {
        return AppError.validation(
          message: message.isEmpty ? 'Invalid request data' : message,
          details: {'statusCode': statusCode, 'response': response},
        );
      }

      if (statusCode == 401) {
        return AppError.authentication(
          message: message.isEmpty ? 'Authentication required' : message,
          details: {'statusCode': statusCode, 'response': response},
        );
      }

      if (statusCode == 403) {
        return AppError.permission(
          message: message.isEmpty ? 'Permission denied' : message,
          details: {'statusCode': statusCode, 'response': response},
        );
      }

      if (statusCode == 404) {
        return AppError.notFound(
          message: message.isEmpty ? 'Resource not found' : message,
          details: {'statusCode': statusCode, 'response': response},
        );
      }

      return AppError.validation(
        message: message.isEmpty ? 'Client error' : message,
        details: {'statusCode': statusCode, 'response': response},
      );
    }

    if (statusCode >= 500) {
      // Server errors
      return AppError.server(
        message: message.isEmpty ? 'Server error' : message,
        details: {'statusCode': statusCode, 'response': response},
        originalException: error,
      );
    }

    // Network or other errors
    return AppError.network(
      message: message.isEmpty ? 'Network error' : message,
      details: {'statusCode': statusCode, 'response': response},
      originalException: error,
    );
  }

  /// Handle PocketBase-specific errors (legacy method)
  ///
  /// [error] The error object from PocketBase operations
  /// [context] Additional context about where the error occurred
  /// Returns a user-friendly error message
  static String handlePocketBaseErrorLegacy(dynamic error, {String? context}) {
    String message = _extractErrorMessage(error);

    // Log the error for debugging
    _logError(error, context: context, userMessage: message);

    return message;
  }

  /// Handle authentication errors specifically
  ///
  /// [error] The error object from authentication operations
  /// Returns a user-friendly authentication error message
  static String handleAuthError(dynamic error) {
    final message = _extractErrorMessage(error);

    // Map common auth errors to user-friendly messages
    if (message.toLowerCase().contains('invalid credentials') ||
        message.toLowerCase().contains('invalid login credentials')) {
      return 'Invalid email or password. Please try again.';
    }

    if (message.toLowerCase().contains('user not found')) {
      return 'No account found with this email address.';
    }

    if (message.toLowerCase().contains('email already exists') ||
        message.toLowerCase().contains('email_already_exists')) {
      return 'An account with this email already exists.';
    }

    if (message.toLowerCase().contains('password too short')) {
      return 'Password must be at least 8 characters long.';
    }

    if (message.toLowerCase().contains('invalid email')) {
      return 'Please enter a valid email address.';
    }

    _logError(error, context: 'Authentication', userMessage: message);
    return message.isEmpty
        ? 'Authentication failed. Please try again.'
        : message;
  }

  /// Handle network and connectivity errors
  ///
  /// [error] The error object from network operations
  /// Returns a user-friendly network error message
  static String handleNetworkError(dynamic error) {
    final message = _extractErrorMessage(error);

    if (message.toLowerCase().contains('network') ||
        message.toLowerCase().contains('connection') ||
        message.toLowerCase().contains('timeout')) {
      return 'Network connection error. Please check your internet connection and try again.';
    }

    if (message.toLowerCase().contains('server') ||
        message.toLowerCase().contains('500') ||
        message.toLowerCase().contains('503')) {
      return 'Server error. Please try again later.';
    }

    _logError(error, context: 'Network', userMessage: message);
    return message.isEmpty ? 'Connection error. Please try again.' : message;
  }

  /// Handle data validation errors
  ///
  /// [error] The error object from validation operations
  /// Returns a user-friendly validation error message
  static String handleValidationError(dynamic error) {
    final message = _extractErrorMessage(error);

    if (error is ClientException) {
      final response = error.response;

      // Handle field-specific validation errors
      if (response['data'] != null && response['data'] is Map) {
        final data = response['data'] as Map<String, dynamic>;
        final fieldErrors = <String>[];

        data.forEach((field, errors) {
          if (errors is Map && errors['message'] != null) {
            final fieldName = _humanizeFieldName(field);
            fieldErrors.add('$fieldName: ${errors['message']}');
          }
        });

        if (fieldErrors.isNotEmpty) {
          final validationMessage = fieldErrors.join('\n');
          _logError(
            error,
            context: 'Validation',
            userMessage: validationMessage,
          );
          return validationMessage;
        }
      }
    }

    _logError(error, context: 'Validation', userMessage: message);
    return message.isEmpty ? 'Please check your input and try again.' : message;
  }

  /// Handle general application errors
  ///
  /// [error] The error object
  /// [context] Additional context about where the error occurred
  /// Returns a user-friendly error message
  static String handleGenericError(dynamic error, {String? context}) {
    final message = _extractErrorMessage(error);
    _logError(error, context: context, userMessage: message);
    return message.isEmpty
        ? 'An unexpected error occurred. Please try again.'
        : message;
  }

  /// Extract the core error message from various error types
  static String _extractErrorMessage(dynamic error) {
    if (error is ClientException) {
      final response = error.response;

      // Try to get the main error message
      if (response['message'] != null) {
        return response['message'].toString();
      }

      // Try to get error from data field
      if (response['data'] != null) {
        if (response['data'] is String) {
          return response['data'].toString();
        }

        if (response['data'] is Map) {
          final data = response['data'] as Map<String, dynamic>;
          if (data['message'] != null) {
            return data['message'].toString();
          }
        }
      }

      return 'Request failed';
    }

    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }

    return error?.toString() ?? 'Unknown error';
  }

  /// Convert technical field names to human-readable format
  static String _humanizeFieldName(String fieldName) {
    // Convert snake_case to Title Case
    return fieldName
        .split('_')
        .map(
          (word) =>
              word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }

  /// Log errors for debugging and monitoring
  static void _logError(dynamic error, {String? context, String? userMessage}) {
    final errorDetails = {
      'timestamp': DateTime.now().toIso8601String(),
      'context': context ?? 'Unknown',
      'error_type': error.runtimeType.toString(),
      'error_message': error.toString(),
      'user_message': userMessage,
    };

    if (kDebugMode) {
      dev.log(
        'Error occurred: ${errorDetails['context']}',
        name: 'ErrorHandler',
        error: error,
      );

      if (userMessage != null && userMessage != error.toString()) {
        dev.log('User message: $userMessage', name: 'ErrorHandler');
      }
    }

    // In production, you might want to send errors to a monitoring service
    // TODO: Integrate with crash reporting service (Firebase Crashlytics, Sentry, etc.)
  }
}

/// Custom exceptions for application-specific errors
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

/// Exception for authentication-related errors
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
}

/// Exception for network-related errors
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});
}

/// Exception for data validation errors
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(
    super.message, {
    this.fieldErrors,
    super.code,
    super.originalError,
  });
}

/// Exception for data not found errors
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.code, super.originalError});
}
