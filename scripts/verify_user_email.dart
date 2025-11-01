#!/usr/bin/env dart

import 'dart:io';
import 'package:pocketbase/pocketbase.dart';

/// PocketBase User Email Verification Script
///
/// This script connects to PocketBase and marks a user's email as verified.
/// Usage: dart scripts/verify_user_email.dart <email>

class VerifyUserEmailScript {
  static const String defaultPocketBaseUrl = 'http://localhost:8090';

  late final PocketBase pb;
  late final String pocketBaseUrl;
  late final String? adminEmail;
  late final String? adminPassword;

  VerifyUserEmailScript() {
    pocketBaseUrl =
        Platform.environment['POCKETBASE_URL'] ?? defaultPocketBaseUrl;
    adminEmail = Platform.environment['POCKETBASE_ADMIN_EMAIL'];
    adminPassword = Platform.environment['POCKETBASE_ADMIN_PASSWORD'];
    pb = PocketBase(pocketBaseUrl);
  }

  /// Verify a user's email address by marking it as verified in PocketBase
  Future<void> verifyUserEmail(String email) async {
    try {
      // Authenticate as admin
      _logInfo('🔐 Authenticating as admin...');
      if (adminEmail == null || adminPassword == null) {
        throw Exception(
          'Admin credentials not provided. Set POCKETBASE_ADMIN_EMAIL and POCKETBASE_ADMIN_PASSWORD environment variables.',
        );
      }

      await pb.admins.authWithPassword(adminEmail!, adminPassword!);
      _logSuccess('✅ Admin authentication successful');

      // Find user by email
      _logInfo('🔍 Looking for user with email: $email');
      final users = await pb
          .collection('users')
          .getList(page: 1, perPage: 1, filter: 'email = "$email"');

      if (users.items.isEmpty) {
        throw Exception('❌ User with email "$email" not found');
      }

      final user = users.items.first;
      final username = user.data['username'] ?? user.data['email'];
      _logInfo('👤 Found user: $username (ID: ${user.id})');

      // Check if already verified
      final isVerified = user.data['verified'] as bool? ?? false;
      if (isVerified) {
        _logSuccess('✅ User is already verified');
        return;
      }

      // Update user to verified
      _logInfo('📧 Updating user verification status...');
      await pb.collection('users').update(user.id, body: {'verified': true});

      _logSuccess('✅ User email verified successfully!');
      _logInfo('📊 User details:');
      _logInfo('   - Email: ${user.data['email']}');
      _logInfo('   - Username: ${user.data['username'] ?? 'N/A'}');
      _logInfo('   - ID: ${user.id}');
      _logInfo('   - Verified: true');
    } catch (error) {
      _logError('❌ Error: $error');
      exit(1);
    }
  }

  /// Validate email format using regex
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  /// Display usage information
  void _showUsage() {
    print('❌ Error: Email address is required');
    print('');
    print('Usage: dart scripts/verify_user_email.dart <email>');
    print('');
    print('Environment variables required:');
    print('  POCKETBASE_ADMIN_EMAIL     - Admin email for PocketBase');
    print('  POCKETBASE_ADMIN_PASSWORD  - Admin password for PocketBase');
    print('');
    print('Optional environment variables:');
    print(
      '  POCKETBASE_URL            - PocketBase URL (default: $defaultPocketBaseUrl)',
    );
  }

  /// Main execution method
  Future<void> run(List<String> arguments) async {
    _logInfo('🚀 PocketBase User Email Verification Script');
    _logInfo('===========================================');

    // Check arguments
    if (arguments.isEmpty) {
      _showUsage();
      exit(1);
    }

    final email = arguments.first;

    // Validate email format
    if (!_isValidEmail(email)) {
      _logError('❌ Error: Invalid email format');
      exit(1);
    }

    _logInfo('🎯 Target email: $email');
    _logInfo('🌐 PocketBase URL: $pocketBaseUrl');
    print('');

    await verifyUserEmail(email);
  }

  // Logging helpers
  void _logInfo(String message) => print('[INFO] $message');
  void _logSuccess(String message) => print('[SUCCESS] $message');
  void _logError(String message) => stderr.writeln('[ERROR] $message');
}

/// Main entry point
void main(List<String> arguments) async {
  final script = VerifyUserEmailScript();

  try {
    await script.run(arguments);
  } catch (error, stackTrace) {
    stderr.writeln('💥 Uncaught Exception: $error');
    stderr.writeln('Stack trace: $stackTrace');
    exit(1);
  }
}
