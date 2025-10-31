/// Base model class for all PocketBase entities
///
/// Provides common fields and functionality that all PocketBase records have:
/// - id: Unique identifier
/// - created: Creation timestamp
/// - updated: Last update timestamp
abstract class BasePocketBaseModel {
  /// Unique identifier for this record
  final String id;

  /// When this record was created (ISO 8601 string from PocketBase)
  final DateTime created;

  /// When this record was last updated (ISO 8601 string from PocketBase)
  final DateTime updated;

  const BasePocketBaseModel({
    required this.id,
    required this.created,
    required this.updated,
  });

  /// Convert the model to a JSON map for PocketBase operations
  ///
  /// Subclasses must implement this to provide their specific fields
  Map<String, dynamic> toJson();

  /// Copy with updated fields
  ///
  /// Subclasses must implement this to provide type-safe copying
  BasePocketBaseModel copyWith({
    String? id,
    DateTime? created,
    DateTime? updated,
  });

  /// Parse common PocketBase timestamp fields
  ///
  /// [json] The JSON map from PocketBase
  /// [field] The field name to parse
  /// Returns the parsed DateTime or current time if parsing fails
  static DateTime parseTimestamp(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        // If parsing fails, return current time as fallback
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  /// Extract base fields from PocketBase JSON
  ///
  /// [json] The JSON map from PocketBase
  /// Returns a map with id, created, and updated fields
  static Map<String, dynamic> extractBaseFields(Map<String, dynamic> json) {
    return {
      'id': json['id'] ?? '',
      'created': parseTimestamp(json, 'created'),
      'updated': parseTimestamp(json, 'updated'),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BasePocketBaseModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return '${runtimeType}(id: $id, created: $created, updated: $updated)';
  }
}

/// Mixin for models that belong to a specific user
mixin UserOwnedModel {
  /// The ID of the user who owns this record
  String get userId;

  /// Check if this record belongs to the given user
  bool belongsToUser(String? currentUserId) {
    return currentUserId != null && userId == currentUserId;
  }
}

/// Mixin for models that can be marked as custom/user-created
mixin CustomizableModel {
  /// Whether this is a custom/user-created record
  bool get isCustom;

  /// Whether this is a built-in/system record
  bool get isBuiltIn => !isCustom;
}
