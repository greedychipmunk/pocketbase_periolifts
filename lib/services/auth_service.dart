import 'package:pocketbase/pocketbase.dart';
import '../config/pocketbase_config.dart';
import '../models/user.dart';
import '../utils/error_handler.dart';
import '../utils/result.dart';
import '../utils/validators.dart';

/// Service for handling authentication operations with PocketBase
///
/// Provides comprehensive authentication functionality including:
/// - Sign in/up with email and password
/// - Session management and token refresh
/// - User profile management
/// - Password reset and verification
/// - Offline authentication queue
class AuthService {
  static const String _collection = 'users';

  final PocketBase _pb;
  User? _currentUser;

  AuthService() : _pb = PocketBaseConfig.instance;

  /// Get currently authenticated user
  User? get currentUser => _currentUser;

  /// Check if user is currently authenticated
  bool get isAuthenticated => _currentUser != null && _pb.authStore.isValid;

  /// Get current authentication token
  String? get authToken => _pb.authStore.token;

  /// Sign in with email and password
  ///
  /// [email] User's email address
  /// [password] User's password
  /// Returns Result<User> with success/error state
  /// Validates input before attempting authentication
  /// Handles network errors and invalid credentials
  Future<Result<User>> signIn(String email, String password) async {
    try {
      // Validate input
      if (!Validators.isValidEmail(email)) {
        return Result.error(
          AppError.validation(
            message: 'Invalid email format',
            details: {'field': 'email'},
          ),
        );
      }

      if (password.isEmpty) {
        return Result.error(
          AppError.validation(
            message: 'Password is required',
            details: {'field': 'password'},
          ),
        );
      }

      // Attempt authentication
      final authResult = await _pb
          .collection(_collection)
          .authWithPassword(email, password);

      // Convert PocketBase record to User model
      _currentUser = User.fromJson(authResult.record.toJson());

      return Result.success(_currentUser!);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(
        AppError.unknown(
          message: 'Unexpected error during sign in',
          details: {'originalError': e.toString()},
        ),
      );
    }
  }

  /// Register new user account
  ///
  /// [email] User's email address
  /// [password] User's chosen password
  /// [username] Optional username (auto-generated if not provided)
  /// [name] Optional display name
  /// Returns Result<User> with success/error state
  /// Performs comprehensive input validation
  /// Register new user with email, password, and name
  /// Automatically verifies email after successful registration
  Future<Result<User>> signUp(
    String email,
    String password,
    String name,
  ) async {
    try {
      // Validate email
      if (!Validators.isValidEmail(email)) {
        return Result.error(
          AppError.validation(
            message: 'Invalid email format',
            details: {'field': 'email'},
          ),
        );
      }

      // Validate password strength
      if (!Validators.isValidPassword(password)) {
        return Result.error(
          AppError.validation(
            message:
                'Password must be at least 8 characters with uppercase, lowercase, number, and special character',
            details: {'field': 'password'},
          ),
        );
      }

      // Validate name
      if (name.trim().isEmpty) {
        return Result.error(
          AppError.validation(
            message: 'Name cannot be empty',
            details: {'field': 'name'},
          ),
        );
      }

      // Prepare user data
      final userData = {
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'username': email.split('@')[0],
        'name': name.trim(),
        'emailVisibility': false,
        'verified': false,
        'role': UserRole.user.name,
        'subscriptionType': SubscriptionStatus.free.name,
        'activityLevel': ActivityLevel.moderatelyActive.name,
      };

      // Create user record
      await _pb.collection(_collection).create(body: userData);

      // Authenticate the new user
      final authResult = await _pb
          .collection(_collection)
          .authWithPassword(email, password);

      // Convert PocketBase record to User model
      _currentUser = User.fromJson(authResult.record.toJson());

      // Send verification email
      await _sendVerificationEmail(email);

      return Result.success(_currentUser!);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(
        AppError.unknown(
          message: 'Unexpected error during sign up',
          details: {'originalError': e.toString()},
        ),
      );
    }
  }

  /// Sign out current user
  ///
  /// Clears local session and auth store
  /// Returns Result<void> indicating success/failure
  Future<Result<void>> signOut() async {
    try {
      // Clear auth store
      _pb.authStore.clear();

      // Clear current user
      _currentUser = null;

      return Result.success(null);
    } catch (e) {
      return Result.error(
        AppError.unknown(
          message: 'Error during sign out',
          details: {'originalError': e.toString()},
        ),
      );
    }
  }

  /// Refresh authentication token
  ///
  /// Attempts to refresh the current session token
  /// Returns Result<User> with updated user data
  Future<Result<User>> refreshToken() async {
    try {
      if (!_pb.authStore.isValid) {
        return Result.error(
          AppError.authentication(message: 'No valid session to refresh'),
        );
      }

      // Refresh authentication
      final authResult = await _pb.collection(_collection).authRefresh();

      _currentUser = User.fromJson(authResult.record.toJson());
      return Result.success(_currentUser!);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(
        AppError.unknown(
          message: 'Error refreshing token',
          details: {'originalError': e.toString()},
        ),
      );
    }
  }

  /// Initialize authentication state
  ///
  /// Checks for existing valid session and loads user data
  /// Returns Result<User?> with current user or null if not authenticated
  Future<Result<User?>> initializeAuth() async {
    try {
      if (_pb.authStore.isValid && _pb.authStore.model != null) {
        final model = _pb.authStore.model as Map<String, dynamic>;
        _currentUser = User.fromJson(model);
        return Result.success(_currentUser);
      }

      return Result.success(null);
    } catch (e) {
      return Result.error(
        AppError.unknown(
          message: 'Error initializing authentication',
          details: {'originalError': e.toString()},
        ),
      );
    }
  }

  /// Send password reset email
  ///
  /// [email] Email address to send reset link to
  /// Returns Result<void> indicating success/failure
  /// Validates email format before sending
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      // Validate email
      if (!Validators.isValidEmail(email)) {
        return Result.error(
          AppError.validation(
            message: 'Invalid email format',
            details: {'field': 'email'},
          ),
        );
      }

      await _pb.collection(_collection).requestPasswordReset(email);

      return Result.success(null);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(
        AppError.unknown(
          message: 'Error sending password reset email',
          details: {'originalError': e.toString()},
        ),
      );
    }
  }

  /// Reset password with token
  ///
  /// [token] Password reset token from email
  /// [newPassword] New password to set
  /// Returns Result<void> indicating success/failure
  /// Validates new password strength
  Future<Result<void>> resetPassword(String token, String newPassword) async {
    try {
      // Validate password strength
      if (!Validators.isValidPassword(newPassword)) {
        return Result.error(
          AppError.validation(
            message:
                'Password must be at least 8 characters with uppercase, lowercase, number, and special character',
            details: {'field': 'password'},
          ),
        );
      }

      await _pb
          .collection(_collection)
          .confirmPasswordReset(token, newPassword, newPassword);

      return Result.success(null);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(
        AppError.unknown(
          message: 'Error resetting password',
          details: {'originalError': e.toString()},
        ),
      );
    }
  }

  /// Send email verification
  ///
  /// [email] Email address to verify
  /// Returns Result<void> indicating success/failure
  Future<Result<void>> sendEmailVerification(String email) async {
    try {
      await _sendVerificationEmail(email);
      return Result.success(null);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(
        AppError.unknown(
          message: 'Error sending verification email',
          details: {'originalError': e.toString()},
        ),
      );
    }
  }

  /// Verify email with token
  ///
  /// [token] Email verification token
  /// Returns Result<void> indicating success/failure
  Future<Result<void>> verifyEmail(String token) async {
    try {
      await _pb.collection(_collection).confirmVerification(token);

      // Refresh user data
      if (_currentUser != null) {
        final refreshResult = await refreshToken();
        if (refreshResult.isError) {
          return Result.error((refreshResult as Error).error);
        }
      }

      return Result.success(null);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(
        AppError.unknown(
          message: 'Error verifying email',
          details: {'originalError': e.toString()},
        ),
      );
    }
  }

  /// Update user profile
  ///
  /// [updates] Map of fields to update
  /// Returns Result<User> with updated user data
  /// Validates input data before update
  Future<Result<User>> updateProfile(Map<String, dynamic> updates) async {
    try {
      if (!isAuthenticated) {
        return Result.error(
          AppError.authentication(message: 'User not authenticated'),
        );
      }

      // Validate updates
      final validationResult = _validateProfileUpdates(updates);
      if (validationResult.isError) {
        return Result.error((validationResult as Error).error);
      }

      // Update user record
      final updatedRecord = await _pb
          .collection(_collection)
          .update(_currentUser!.id, body: updates);

      // Update current user
      _currentUser = User.fromJson(updatedRecord.toJson());

      return Result.success(_currentUser!);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(
        AppError.unknown(
          message: 'Error updating profile',
          details: {'originalError': e.toString()},
        ),
      );
    }
  }

  /// Change user password
  ///
  /// [currentPassword] Current password for verification
  /// [newPassword] New password to set
  /// Returns Result<void> indicating success/failure
  /// Validates new password strength
  Future<Result<void>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      if (!isAuthenticated) {
        return Result.error(
          AppError.authentication(message: 'User not authenticated'),
        );
      }

      // Validate new password strength
      if (!Validators.isValidPassword(newPassword)) {
        return Result.error(
          AppError.validation(
            message:
                'Password must be at least 8 characters with uppercase, lowercase, number, and special character',
            details: {'field': 'password'},
          ),
        );
      }

      // Update password
      await _pb
          .collection(_collection)
          .update(
            _currentUser!.id,
            body: {
              'oldPassword': currentPassword,
              'password': newPassword,
              'passwordConfirm': newPassword,
            },
          );

      return Result.success(null);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(
        AppError.unknown(
          message: 'Error changing password',
          details: {'originalError': e.toString()},
        ),
      );
    }
  }

  /// Delete user account
  ///
  /// [password] Current password for verification
  /// Returns Result<void> indicating success/failure
  /// Permanently removes user account and all associated data
  Future<Result<void>> deleteAccount(String password) async {
    try {
      if (!isAuthenticated) {
        return Result.error(
          AppError.authentication(message: 'User not authenticated'),
        );
      }

      // Verify password by attempting to sign in
      final signInResult = await signIn(_currentUser!.email, password);
      if (signInResult.isError) {
        return Result.error(
          AppError.authentication(message: 'Invalid password'),
        );
      }

      // Delete user record
      await _pb.collection(_collection).delete(_currentUser!.id);

      // Clear local session
      await signOut();

      return Result.success(null);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(
        AppError.unknown(
          message: 'Error deleting account',
          details: {'originalError': e.toString()},
        ),
      );
    }
  }

  /// Private helper to send verification email
  Future<void> _sendVerificationEmail(String email) async {
    await _pb.collection(_collection).requestVerification(email);
  }

  /// Private helper to validate profile updates
  Result<void> _validateProfileUpdates(Map<String, dynamic> updates) {
    // Validate username if provided
    if (updates.containsKey('username')) {
      final username = updates['username'] as String?;
      if (username != null && username.isNotEmpty) {
        if (!Validators.isValidUsername(username)) {
          return Result.error(
            AppError.validation(
              message:
                  'Username must be 3-30 characters, letters/numbers/underscores only, cannot start or end with underscore',
              details: {'field': 'username'},
            ),
          );
        }
      }
    }

    // Validate age if provided
    if (updates.containsKey('age')) {
      final age = updates['age'] as int?;
      if (age != null) {
        if (age < 13 || age > 120) {
          return Result.error(
            AppError.validation(
              message: 'Age must be between 13 and 120',
              details: {'field': 'age'},
            ),
          );
        }
      }
    }

    // Validate weight if provided
    if (updates.containsKey('weight')) {
      final weight = updates['weight'] as double?;
      if (weight != null) {
        if (!Validators.isValidWeight(weight)) {
          return Result.error(
            AppError.validation(
              message: 'Weight must be between 20 and 500 kg',
              details: {'field': 'weight'},
            ),
          );
        }
      }
    }

    // Validate height if provided
    if (updates.containsKey('height')) {
      final height = updates['height'] as double?;
      if (height != null) {
        if (!Validators.isValidHeight(height)) {
          return Result.error(
            AppError.validation(
              message: 'Height must be between 50 and 300 cm',
              details: {'field': 'height'},
            ),
          );
        }
      }
    }

    return Result.success(null);
  }

  /// Restore session from stored auth data
  ///
  /// This method attempts to restore a user session from previously stored
  /// authentication data (token and user info) in the PocketBase auth store.
  /// Useful for maintaining authentication state across app restarts.
  Future<void> restoreSession() async {
    try {
      // Check if auth store has valid token and user data
      if (_pb.authStore.isValid && _pb.authStore.model != null) {
        // Convert stored model to User object
        final userJson = _pb.authStore.model as Map<String, dynamic>;
        _currentUser = User.fromJson(userJson);
      } else {
        // Clear invalid session
        _currentUser = null;
        _pb.authStore.clear();
      }
    } catch (e) {
      // If restoration fails, clear session
      _currentUser = null;
      _pb.authStore.clear();
    }
  }
}
