// Test helper classes for PocketBase testing
// These provide comprehensive mock functionality for unit tests

import 'dart:async';
import 'package:pocketbase/pocketbase.dart';

import '../../lib/models/user.dart';

/// Test helper class that simulates PocketBase client behavior
class TestPocketBaseClient {
  final TestAuthStore authStore = TestAuthStore();
  final Map<String, TestRecordService> _collections = {};
  final Map<String, StreamController<dynamic>> _realtimeStreams = {};
  bool _isConnected = true;
  String _baseUrl = 'http://test.pocketbase.io';

  String get baseUrl => _baseUrl;

  bool get isConnected => _isConnected;

  TestRecordService collection(String name) {
    _collections[name] ??= TestRecordService(name);
    return _collections[name]!;
  }

  void setMockCollection(String collectionName, TestRecordService collection) {
    _collections[collectionName] = collection;
  }

  void reset() {
    authStore.reset();
    _collections.clear();
    _realtimeStreams.clear();
    _isConnected = true;
  }

  /// Mock network connectivity
  void setConnected(bool connected) {
    _isConnected = connected;
  }

  /// Mock base URL change
  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  /// Mock real-time subscription
  Stream<T> subscribe<T>(String topic) {
    _realtimeStreams[topic] ??= StreamController<T>.broadcast();
    return (_realtimeStreams[topic] as StreamController<T>).stream;
  }

  /// Mock real-time event emission
  void emitRealtimeEvent<T>(String topic, T data) {
    if (_realtimeStreams.containsKey(topic)) {
      (_realtimeStreams[topic] as StreamController<T>).add(data);
    }
  }

  /// Cleanup method for tests
  void dispose() {
    for (final controller in _realtimeStreams.values) {
      controller.close();
    }
    _realtimeStreams.clear();
    _collections.clear();
    authStore.clear();
  }
}

/// Test helper class that simulates AuthStore behavior
class TestAuthStore {
  Map<String, dynamic>? _user;
  String? _token;
  String? _refreshToken;
  String? _errorMessage;

  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get model => _user;
  String get token => _token ?? '';
  String get refreshToken => _refreshToken ?? '';
  bool get isValid =>
      _token != null && _token!.isNotEmpty && _errorMessage == null;

  void save(String token, dynamic model) {
    _token = token;
    _user = model is Map<String, dynamic> ? model : null;
    _errorMessage = null;
  }

  void setAuth(Map<String, dynamic>? user, String? token) {
    _user = user;
    _token = token;
    _errorMessage = null; // Clear any previous errors
  }

  void clear() {
    _user = null;
    _token = null;
    _refreshToken = null;
    _errorMessage = null;
  }

  void reset() {
    clear();
  }

  // Test helper methods for mocking specific states
  void setMockToken(String token) {
    _token = token;
    _errorMessage = null;
  }

  void setMockModel(Map<String, dynamic> user) {
    _user = user;
    _errorMessage = null;
  }

  void setMockError(String error, {int? statusCode}) {
    _errorMessage = error;
    _token = null;
    _user = null;
  }

  void setMockRefreshToken(String refreshToken) {
    _refreshToken = refreshToken;
    _token = refreshToken; // For simplicity, use refresh token as the new token
    _errorMessage = null;
  }

  // Test helper to simulate errors
  void throwIfError() {
    if (_errorMessage != null) {
      throw Exception(_errorMessage);
    }
  }
}

/// Test helper class that simulates RecordService behavior
class TestRecordService {
  final String collectionName;
  final Map<String, Map<String, dynamic>> _records = {};
  bool _shouldThrowError = false;
  String? _errorMessage;
  int? _errorStatusCode;

  // Authentication configuration
  final Map<String, dynamic> _authConfigurations = {};
  final Set<String> _passwordResetConfigurations = {};
  final Set<String> _passwordResetTokens = {};
  final Set<String> _emailVerificationConfigurations = {};
  final Set<String> _emailVerificationTokens = {};

  TestRecordService(this.collectionName);

  /// Configure error simulation
  void setMockError(String message, {int? statusCode}) {
    _shouldThrowError = true;
    _errorMessage = message;
    _errorStatusCode = statusCode;
  }

  /// Clear error simulation
  void clearMockError() {
    _shouldThrowError = false;
    _errorMessage = null;
    _errorStatusCode = null;
  }

  // Configuration methods for testing
  void configureError(Exception error) {
    if (error.toString().contains('ClientException')) {
      // Extract status code if available
      final statusMatch = RegExp(
        r'statusCode: (\d+)',
      ).firstMatch(error.toString());
      final statusCode = statusMatch != null
          ? int.parse(statusMatch.group(1)!)
          : 500;
      setMockError(error.toString(), statusCode: statusCode);
    } else {
      setMockError(error.toString());
    }
  }

  void configureAuthWithPassword({
    required String email,
    required String password,
    required dynamic user,
  }) {
    _authConfigurations[email] = user;
    _authConfigurations['${email}_password'] = password;
  }

  void configureCreate(dynamic user) {
    if (user != null && user is Map<String, dynamic>) {
      final id = user['id'] as String?;
      if (id != null) {
        _records[id] = user;
      }
    }
  }

  void configureUpdate(String id, dynamic user) {
    if (user != null && user is Map<String, dynamic>) {
      _records[id] = user;
    }
  }

  void configureDelete(String id) {
    _records.remove(id);
  }

  void configureAuthRefresh(dynamic user) {
    _authConfigurations['refresh_user'] = user;
  }

  void configureRequestPasswordReset(String email) {
    _passwordResetConfigurations.add(email);
  }

  void configureConfirmPasswordReset(String token, String password) {
    _passwordResetTokens.add(token);
  }

  void configureRequestVerification(String email) {
    _emailVerificationConfigurations.add(email);
  }

  void configureConfirmVerification(String token) {
    _emailVerificationTokens.add(token);
  }

  void _throwIfError() {
    if (_shouldThrowError) {
      final message = _errorMessage ?? 'Mock error';
      if (_errorStatusCode != null) {
        throw Exception('HTTP $_errorStatusCode: $message');
      } else {
        throw Exception(message);
      }
    }
  }

  Future<Map<String, dynamic>> create(
    Map<String, dynamic> data, {
    String? expand,
    Map<String, dynamic>? query,
  }) async {
    _throwIfError();

    final id = 'test_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().toIso8601String();

    final record = {
      'id': id,
      'created': now,
      'updated': now,
      'collectionId': 'col_$collectionName',
      'collectionName': collectionName,
      ...data,
    };

    _records[id] = record;
    return record;
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> data, {
    String? expand,
    Map<String, dynamic>? query,
  }) async {
    _throwIfError();

    if (!_records.containsKey(id)) {
      throw Exception('Record not found');
    }

    final record = Map<String, dynamic>.from(_records[id]!);
    record.addAll(data);
    record['updated'] = DateTime.now().toIso8601String();

    _records[id] = record;
    return record;
  }

  Future<void> delete(String id) async {
    _throwIfError();

    if (!_records.containsKey(id)) {
      throw Exception('Record not found');
    }

    _records.remove(id);
  }

  Future<Map<String, dynamic>> getOne(
    String id, {
    String? expand,
    Map<String, dynamic>? query,
  }) async {
    _throwIfError();

    if (!_records.containsKey(id)) {
      throw Exception('Record not found');
    }

    return _records[id]!;
  }

  Future<Map<String, dynamic>> getList({
    int page = 1,
    int perPage = 30,
    String? filter,
    String? sort,
    String? expand,
    Map<String, dynamic>? query,
  }) async {
    _throwIfError();

    final items = _records.values.toList();
    final totalItems = items.length;
    final totalPages = (totalItems / perPage).ceil();

    // Simple pagination simulation
    final start = (page - 1) * perPage;
    final end = (start + perPage).clamp(0, totalItems);
    final pageItems = items.sublist(start.clamp(0, totalItems), end);

    return {
      'page': page,
      'perPage': perPage,
      'totalItems': totalItems,
      'totalPages': totalPages,
      'items': pageItems,
    };
  }

  Future<Map<String, dynamic>> getFirstListItem(
    String filter, {
    String? sort,
    String? expand,
    Map<String, dynamic>? query,
  }) async {
    _throwIfError();

    // Simple filter simulation - in real implementation, would parse filter
    final items = _records.values.toList();
    if (items.isEmpty) {
      throw Exception('Record not found');
    }
    return items.first;
  }

  Future<Map<String, dynamic>> getFullList({
    int batch = 200,
    String? filter,
    String? sort,
    String? expand,
    Map<String, dynamic>? query,
  }) async {
    _throwIfError();

    return {'items': _records.values.toList(), 'totalItems': _records.length};
  }

  Future<Map<String, dynamic>> authWithPassword(
    String usernameOrEmail,
    String password, {
    String? expand,
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
  }) async {
    _throwIfError();

    // Check if we have configured authentication for this email/password
    final user = _authConfigurations[usernameOrEmail];
    final expectedPassword = _authConfigurations['${usernameOrEmail}_password'];

    if (user == null || expectedPassword != password) {
      throw Exception('HTTP 401: Invalid credentials');
    }

    final userJson = user is Map<String, dynamic>
        ? user
        : {
            'id': 'test_user_123',
            'email': usernameOrEmail,
            'username': usernameOrEmail.split('@').first,
            'name': 'Test User',
            'verified': true,
            'created': DateTime.now().toIso8601String(),
            'updated': DateTime.now().toIso8601String(),
          };

    final token = 'auth-token-${userJson['id']}';

    return {'token': token, 'record': userJson};
  }

  Future<void> authRefresh({
    String? expand,
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
  }) async {
    _throwIfError();
    // Mock token refresh - would normally update tokens in AuthStore
  }

  Future<void> requestPasswordReset(
    String email, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
  }) async {
    _throwIfError();
    // Mock password reset request
  }

  Future<void> confirmPasswordReset(
    String passwordResetToken,
    String password,
    String passwordConfirm, {
    String? expand,
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
  }) async {
    _throwIfError();
    // Mock password reset confirmation
  }

  /// Helper method to add test data
  void addTestRecord(String id, Map<String, dynamic> data) {
    _records[id] = {
      'id': id,
      'created': DateTime.now().toIso8601String(),
      'updated': DateTime.now().toIso8601String(),
      'collectionId': 'col_$collectionName',
      'collectionName': collectionName,
      ...data,
    };
  }

  /// Helper method to get all test records
  Map<String, Map<String, dynamic>> get testRecords => Map.from(_records);

  /// Helper method to clear all test data
  void clearTestData() {
    _records.clear();
  }

  /// Reset all configurations and data
  void reset() {
    _records.clear();
    _authConfigurations.clear();
    _passwordResetConfigurations.clear();
    _passwordResetTokens.clear();
    _emailVerificationConfigurations.clear();
    _emailVerificationTokens.clear();
    _shouldThrowError = false;
    _errorMessage = null;
    _errorStatusCode = null;
  }

  /// Helper method to get record count
  int get recordCount => _records.length;
}
