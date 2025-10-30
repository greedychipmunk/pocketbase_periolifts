import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/result.dart';

/// Auth state that tracks authentication status and user data
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  @override
  String toString() {
    return 'AuthState(user: $user, isLoading: $isLoading, error: $error, isAuthenticated: $isAuthenticated)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.user == user &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.isAuthenticated == isAuthenticated;
  }

  @override
  int get hashCode {
    return Object.hash(user, isLoading, error, isAuthenticated);
  }
}

/// AuthService provider - singleton instance
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Auth state provider that manages authentication state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  return AuthNotifier(authService);
});

/// Auth notifier that manages authentication operations
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _restoreSession();
  }

  /// Restore session from stored auth data on app startup
  Future<void> _restoreSession() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.restoreSession();
      final user = _authService.currentUser;
      final isAuthenticated = _authService.isAuthenticated;

      state = state.copyWith(
        user: user,
        isAuthenticated: isAuthenticated,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        user: null,
        isAuthenticated: false,
        isLoading: false,
        error: 'Failed to restore session: $e',
      );
    }
  }

  /// Sign in with email and password
  Future<Result<User>> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.signIn(email, password);

      if (result.isSuccess) {
        state = state.copyWith(
          user: result.data,
          isAuthenticated: true,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          user: null,
          isAuthenticated: false,
          isLoading: false,
          error: (result as Error).error.message,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        user: null,
        isAuthenticated: false,
        isLoading: false,
        error: 'Failed to sign in: $e',
      );
      return Result.error(AppError.unknown(message: 'Failed to sign in: $e'));
    }
  }

  /// Sign up with email, password, and name
  Future<Result<User>> signUp(
    String email,
    String password,
    String name,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.signUp(email, password, name);

      if (result.isSuccess) {
        state = state.copyWith(
          user: result.data,
          isAuthenticated: true,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          user: null,
          isAuthenticated: false,
          isLoading: false,
          error: (result as Error).error.message,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        user: null,
        isAuthenticated: false,
        isLoading: false,
        error: 'Failed to sign up: $e',
      );
      return Result.error(AppError.unknown(message: 'Failed to sign up: $e'));
    }
  }

  /// Sign out current user
  Future<Result<void>> signOut() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.signOut();

      if (result.isSuccess) {
        state = state.copyWith(
          user: null,
          isAuthenticated: false,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: (result as Error).error.message,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to sign out: $e');
      return Result.error(AppError.unknown(message: 'Failed to sign out: $e'));
    }
  }

  /// Refresh authentication token
  Future<Result<User>> refreshToken() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.refreshToken();

      if (result.isSuccess) {
        state = state.copyWith(
          user: result.data,
          isAuthenticated: true,
          isLoading: false,
          error: null,
        );
      } else {
        // Token refresh failed - user might need to re-authenticate
        state = state.copyWith(
          user: null,
          isAuthenticated: false,
          isLoading: false,
          error: (result as Error).error.message,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        user: null,
        isAuthenticated: false,
        isLoading: false,
        error: 'Failed to refresh token: $e',
      );
      return Result.error(
        AppError.unknown(message: 'Failed to refresh token: $e'),
      );
    }
  }

  /// Update user profile
  Future<Result<User>> updateProfile(Map<String, dynamic> updates) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.updateProfile(updates);

      if (result.isSuccess) {
        state = state.copyWith(
          user: result.data,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: (result as Error).error.message,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update profile: $e',
      );
      return Result.error(
        AppError.unknown(message: 'Failed to update profile: $e'),
      );
    }
  }

  /// Change password
  Future<Result<void>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.changePassword(
        currentPassword,
        newPassword,
      );

      if (result.isSuccess) {
        state = state.copyWith(isLoading: false, error: null);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: (result as Error).error.message,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to change password: $e',
      );
      return Result.error(
        AppError.unknown(message: 'Failed to change password: $e'),
      );
    }
  }

  /// Send password reset email
  Future<Result<void>> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.sendPasswordResetEmail(email);

      if (result.isSuccess) {
        state = state.copyWith(isLoading: false, error: null);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: (result as Error).error.message,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send password reset: $e',
      );
      return Result.error(
        AppError.unknown(message: 'Failed to send password reset: $e'),
      );
    }
  }

  /// Send email verification
  Future<Result<void>> sendEmailVerification() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = state.user;
      if (user == null) {
        final error = AppError.authentication(message: 'No user logged in');
        state = state.copyWith(isLoading: false, error: error.message);
        return Result.error(error);
      }

      final result = await _authService.sendEmailVerification(user.email);

      if (result.isSuccess) {
        state = state.copyWith(isLoading: false, error: null);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: (result as Error).error.message,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send email verification: $e',
      );
      return Result.error(
        AppError.unknown(message: 'Failed to send email verification: $e'),
      );
    }
  }

  /// Delete current user account
  Future<Result<void>> deleteAccount(String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.deleteAccount(password);

      if (result.isSuccess) {
        state = state.copyWith(
          user: null,
          isAuthenticated: false,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: (result as Error).error.message,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete account: $e',
      );
      return Result.error(
        AppError.unknown(message: 'Failed to delete account: $e'),
      );
    }
  }

  /// Clear any errors in the auth state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Force refresh of current auth state
  void refreshAuthState() {
    final user = _authService.currentUser;
    final isAuthenticated = _authService.isAuthenticated;

    state = state.copyWith(
      user: user,
      isAuthenticated: isAuthenticated,
      error: null,
    );
  }
}

/// Convenience providers for common auth state access

/// Current authenticated user
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

/// Authentication status
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Authentication loading state
final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

/// Authentication error
final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});

/// Helper provider for auth-dependent operations
final authRequiredProvider = Provider<AuthService>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  if (!isAuthenticated) {
    throw Exception('Authentication required for this operation');
  }
  return ref.read(authServiceProvider);
});
