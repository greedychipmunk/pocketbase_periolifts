import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../utils/validators.dart';
import 'sign_up_screen.dart';
import '../constants/app_constants.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback? onAuthSuccess;

  const LoginScreen({Key? key, this.onAuthSuccess}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref
        .read(authProvider.notifier)
        .signIn(_emailController.text.trim(), _passwordController.text);

    if (mounted) {
      if (result.isSuccess) {
        final user = result.data!;

        // Check if email verification is required
        if (!user.emailVerified) {
          _showEmailVerificationDialog(user);
        } else {
          if (widget.onAuthSuccess != null) {
            widget.onAuthSuccess!();
          }
        }
      } else {
        _handleSignInError(result.error!.message);
      }
    }
  }

  void _handleSignInError(String errorMessage) {
    String userFriendlyMessage = errorMessage;

    // Convert PocketBase errors to user-friendly messages
    if (errorMessage.toLowerCase().contains('invalid credentials') ||
        errorMessage.toLowerCase().contains('wrong email or password')) {
      userFriendlyMessage =
          'Invalid email or password. Please check your credentials and try again.';
    } else if (errorMessage.toLowerCase().contains('user not found')) {
      userFriendlyMessage =
          'No account found with this email address. Please sign up first.';
    } else if (errorMessage.toLowerCase().contains('network') ||
        errorMessage.toLowerCase().contains('connection')) {
      userFriendlyMessage =
          'Network error. Please check your internet connection and try again.';
    } else if (errorMessage.toLowerCase().contains('rate limit')) {
      userFriendlyMessage =
          'Too many login attempts. Please wait a moment and try again.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(userFriendlyMessage),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showEmailVerificationDialog(User user) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Email Verification Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please verify your email address (${user.email}) to continue.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Check your inbox for a verification email and click the link to verify your account.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authProvider.notifier).signOut();
              },
              child: const Text('Sign Out'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _resendEmailVerification();
              },
              child: const Text('Resend Email'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (widget.onAuthSuccess != null) {
                  widget.onAuthSuccess!();
                }
              },
              child: const Text('Continue Anyway'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resendEmailVerification() async {
    final result = await ref
        .read(authProvider.notifier)
        .sendEmailVerification();

    if (mounted) {
      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Verification email sent! Please check your inbox.',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send verification email: ${result.error?.message}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shadowColor: Theme.of(
                  context,
                ).colorScheme.shadow.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.fitness_center,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        Text(
                          AppConstants.appName,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          AppConstants.tagline,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32.0),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!Validators.isValidEmail(value.trim())) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20.0),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(
                              Icons.lock_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _signIn(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28.0),
                        ElevatedButton(
                          onPressed: isLoading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                                )
                              : Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 20.0),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => SignUpScreen(
                                  onAuthSuccess: widget.onAuthSuccess,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'Don\'t have an account? Sign Up',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
