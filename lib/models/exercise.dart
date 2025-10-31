import 'base_model.dart';

/// Exercise model representing individual exercises in the workout system
///
/// An exercise defines a specific movement or activity with metadata about
/// muscle groups, instructions, and media resources. Exercises can be
/// built-in (system-provided) or custom (user-created).
class Exercise extends BasePocketBaseModel
    with UserOwnedModel, CustomizableModel {
  /// Display name of the exercise (e.g., "Push-up", "Bench Press")
  final String name;

  /// Category of the exercise (e.g., "Strength", "Cardio", "Flexibility")
  final String category;

  /// Detailed description with instructions for performing the exercise
  final String description;

  /// List of primary muscle groups targeted by this exercise
  final List<String> muscleGroups;

  /// Optional URL to an image demonstrating the exercise
  final String? imageUrl;

  /// Optional URL to a video demonstrating the exercise
  final String? videoUrl;

  /// Whether this is a custom exercise created by a user
  @override
  final bool isCustom;

  /// ID of the user who created this exercise (null for built-in exercises)
  @override
  final String userId;

  const Exercise({
    required super.id,
    required super.created,
    required super.updated,
    required this.name,
    required this.category,
    required this.description,
    required this.muscleGroups,
    this.imageUrl,
    this.videoUrl,
    required this.isCustom,
    required this.userId,
  });

  /// Create an Exercise from PocketBase JSON response
  factory Exercise.fromJson(Map<String, dynamic> json) {
    final baseFields = BasePocketBaseModel.extractBaseFields(json);

    return Exercise(
      id: baseFields['id'] as String,
      created: baseFields['created'] as DateTime,
      updated: baseFields['updated'] as DateTime,
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      muscleGroups: _parseMuscleGroups(json['muscle_groups']),
      imageUrl: json['image_url']?.toString(),
      videoUrl: json['video_url']?.toString(),
      isCustom: json['is_custom'] == true,
      userId: json['user_id']?.toString() ?? '',
    );
  }

  /// Convert Exercise to JSON for PocketBase operations
  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'muscle_groups': muscleGroups,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'is_custom': isCustom,
      'user_id': userId.isEmpty ? null : userId,
    };
  }

  /// Create a copy of this Exercise with updated fields
  @override
  Exercise copyWith({
    String? id,
    DateTime? created,
    DateTime? updated,
    String? name,
    String? category,
    String? description,
    List<String>? muscleGroups,
    String? imageUrl,
    String? videoUrl,
    bool? isCustom,
    String? userId,
  }) {
    return Exercise(
      id: id ?? this.id,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      isCustom: isCustom ?? this.isCustom,
      userId: userId ?? this.userId,
    );
  }

  /// Parse muscle groups from various JSON formats
  static List<String> _parseMuscleGroups(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    if (value is String) {
      // Handle comma-separated string format
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return [];
  }

  /// Create a built-in (system) exercise
  factory Exercise.builtin({
    required String id,
    required DateTime created,
    required DateTime updated,
    required String name,
    required String category,
    required String description,
    required List<String> muscleGroups,
    String? imageUrl,
    String? videoUrl,
  }) {
    return Exercise(
      id: id,
      created: created,
      updated: updated,
      name: name,
      category: category,
      description: description,
      muscleGroups: muscleGroups,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      isCustom: false,
      userId: '', // Built-in exercises don't belong to any user
    );
  }

  /// Create a custom (user-created) exercise
  factory Exercise.custom({
    required String id,
    required DateTime created,
    required DateTime updated,
    required String name,
    required String category,
    required String description,
    required List<String> muscleGroups,
    required String userId,
    String? imageUrl,
    String? videoUrl,
  }) {
    return Exercise(
      id: id,
      created: created,
      updated: updated,
      name: name,
      category: category,
      description: description,
      muscleGroups: muscleGroups,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      isCustom: true,
      userId: userId,
    );
  }

  @override
  String toString() {
    return 'Exercise(id: $id, name: $name, category: $category, isCustom: $isCustom)';
  }
}
