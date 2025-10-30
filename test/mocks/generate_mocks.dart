// Test helper classes for PocketBase testing
// These provide simplified mock functionality for unit tests

/// Test helper class that simulates PocketBase client behavior
class TestPocketBaseClient {
  final TestAuthStore authStore = TestAuthStore();
  final Map<String, TestRecordService> _collections = {};

  String get baseUrl => 'http://test.pocketbase.io';

  TestRecordService collection(String name) {
    _collections[name] ??= TestRecordService(name);
    return _collections[name]!;
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

  TestRecordService(this.collectionName);

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final id = 'test_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().toIso8601String();

    final record = {'id': id, 'created': now, 'updated': now, ...data};

    _records[id] = record;
    return record;
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> data,
  ) async {
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
    if (!_records.containsKey(id)) {
      throw Exception('Record not found');
    }

    _records.remove(id);
  }

  Future<Map<String, dynamic>> getOne(String id) async {
    if (!_records.containsKey(id)) {
      throw Exception('Record not found');
    }

    return _records[id]!;
  }

  Future<List<Map<String, dynamic>>> getList({
    int page = 1,
    int perPage = 30,
    String? filter,
    String? sort,
  }) async {
    return _records.values.toList();
  }

  Future<Map<String, dynamic>> authWithPassword(
    String email,
    String password,
  ) async {
    // Mock successful authentication
    final user = {
      'id': 'test_user_123',
      'email': email,
      'name': 'Test User',
      'created': DateTime.now().toIso8601String(),
      'updated': DateTime.now().toIso8601String(),
    };

    return user;
  }

  /// Helper method to add test data
  void addTestRecord(String id, Map<String, dynamic> data) {
    _records[id] = {
      'id': id,
      'created': DateTime.now().toIso8601String(),
      'updated': DateTime.now().toIso8601String(),
      ...data,
    };
  }

  /// Helper method to get all test records
  Map<String, Map<String, dynamic>> get testRecords => Map.from(_records);
}
