class Exercise {
  final String id;
  final String name;
  final String description;
  final List<String> muscleGroups;
  final String? videoUrl;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.muscleGroups,
    this.videoUrl,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['\$id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      muscleGroups: List<String>.from(json['muscleGroups'] as List),
      videoUrl: json['videoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'muscleGroups': muscleGroups,
      'videoUrl': videoUrl,
    };
  }
}
