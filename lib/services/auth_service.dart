import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

class AuthService {
  final Client client;
  late final Account account;

  AuthService({required this.client}) {
    account = Account(client);
  }

  Future<bool> isAuthenticated() async {
    try {
      await account.get();
      return true;
    } catch (e) {
      print('Auth check failed: $e');
      return false;
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      // Check if user is already authenticated
      final isAuth = await isAuthenticated();
      if (isAuth) {
        print('User already has an active session');
        return;
      }
      
      await account.createEmailSession(
        email: email,
        password: password,
      );
      final user = await account.get();
      print('Signed in successfully: ${user.$id}');
    } catch (e) {
      print('Sign in failed: $e');
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    try {
      await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      print('Account created successfully');
      await signIn(email, password);
    } catch (e) {
      print('Sign up failed: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await account.deleteSession(sessionId: 'current');
      print('Session deleted successfully');
    } catch (e) {
      print('Sign out failed: $e');
      rethrow;
    }
  }

  Stream<bool> get authStateChanges {
    // Implement real-time auth state changes when needed
    return Stream.value(true);
  }
}
