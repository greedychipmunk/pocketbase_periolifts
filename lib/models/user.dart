import '../utils/validators.dart';
import '../utils/error_handler.dart';
import 'base_model.dart';

/// User model representing authenticated users in the system
///
/// Integrates with PocketBase authentication and provides:
/// - Profile management
/// - Preference settings
/// - Offline sync capabilities
/// - Data validation
class User extends BasePocketBaseModel {
  /// User's email address (used for authentication)
  final String email;

  /// User's full name
  final String name;

  /// User's username (unique identifier)
  final String username;

  /// User's avatar URL (optional)
  final String? avatarUrl;

  /// Whether the user's email has been verified
  final bool emailVerified;

  /// User's preferred units (metric/imperial)
  final String preferredUnits;

  /// User's preferred theme (light/dark/system)
  final String preferredTheme;

  /// User's timezone identifier
  final String timezone;

  /// Whether user has completed onboarding
  final bool onboardingCompleted;

  /// User's fitness goals (JSON string)
  final String? fitnessGoals;

  /// User's current cycle phase for period tracking
  final String? currentCyclePhase;

  /// Average cycle length in days
  final int? averageCycleLength;

  /// User's birth date for age calculations
  final DateTime? birthDate;

  /// User's height in centimeters
  final double? height;

  /// User's weight in kilograms
  final double? weight;

  /// User's activity level (sedentary/lightly_active/moderately_active/very_active/extremely_active)
  final String? activityLevel;

  /// Whether user wants to receive notifications
  final bool notificationsEnabled;

  /// Whether user wants workout reminders
  final bool workoutRemindersEnabled;

  /// Whether user wants period tracking reminders
  final bool periodRemindersEnabled;

  /// User's subscription status (free/premium)
  final String subscriptionStatus;

  /// When the subscription expires (if applicable)
  final DateTime? subscriptionExpiresAt;

  /// User's role in the system (user/admin)
  final String role;

  /// Whether the user account is active
  final bool isActive;

  /// Last time the user was active
  final DateTime? lastActiveAt;

  const User({
    required super.id,
    required super.created,
    required super.updated,
    required this.email,
    required this.name,
    required this.username,
    this.avatarUrl,
    this.emailVerified = false,
    this.preferredUnits = 'metric',
    this.preferredTheme = 'system',
    this.timezone = 'UTC',
    this.onboardingCompleted = false,
    this.fitnessGoals,
    this.currentCyclePhase,
    this.averageCycleLength,
    this.birthDate,
    this.height,
    this.weight,
    this.activityLevel,
    this.notificationsEnabled = true,
    this.workoutRemindersEnabled = true,
    this.periodRemindersEnabled = true,
    this.subscriptionStatus = 'free',
    this.subscriptionExpiresAt,
    this.role = 'user',
    this.isActive = true,
    this.lastActiveAt,
  });

  /// Create User from PocketBase JSON response
  factory User.fromJson(Map<String, dynamic> json) {
    try {
      // Extract base fields
      final baseFields = BasePocketBaseModel.extractBaseFields(json);

      return User(
        id: baseFields['id'] as String,
        created: baseFields['created'] as DateTime,
        updated: baseFields['updated'] as DateTime,
        email: json['email'] as String? ?? '',
        name: json['name'] as String? ?? '',
        username: json['username'] as String? ?? '',
        avatarUrl: json['avatar'] as String?,
        emailVerified: json['emailVisibility'] as bool? ?? false,
        preferredUnits: json['preferredUnits'] as String? ?? 'metric',
        preferredTheme: json['preferredTheme'] as String? ?? 'system',
        timezone: json['timezone'] as String? ?? 'UTC',
        onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
        fitnessGoals: json['fitnessGoals'] as String?,
        currentCyclePhase: json['currentCyclePhase'] as String?,
        averageCycleLength: json['averageCycleLength'] as int?,
        birthDate: json['birthDate'] != null
            ? DateTime.tryParse(json['birthDate'] as String)
            : null,
        height: (json['height'] as num?)?.toDouble(),
        weight: (json['weight'] as num?)?.toDouble(),
        activityLevel: json['activityLevel'] as String?,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        workoutRemindersEnabled:
            json['workoutRemindersEnabled'] as bool? ?? true,
        periodRemindersEnabled: json['periodRemindersEnabled'] as bool? ?? true,
        subscriptionStatus: json['subscriptionStatus'] as String? ?? 'free',
        subscriptionExpiresAt: json['subscriptionExpiresAt'] != null
            ? DateTime.tryParse(json['subscriptionExpiresAt'] as String)
            : null,
        role: json['role'] as String? ?? 'user',
        isActive: json['isActive'] as bool? ?? true,
        lastActiveAt: json['lastActiveAt'] != null
            ? DateTime.tryParse(json['lastActiveAt'] as String)
            : null,
      );
    } catch (e) {
      throw ValidationException(
        'Failed to parse User from JSON',
        originalError: e,
        fieldErrors: {'json': 'Invalid user data format'},
      );
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
      'email': email,
      'name': name,
      'username': username,
      'avatar': avatarUrl,
      'emailVisibility': emailVerified,
      'preferredUnits': preferredUnits,
      'preferredTheme': preferredTheme,
      'timezone': timezone,
      'onboardingCompleted': onboardingCompleted,
      'fitnessGoals': fitnessGoals,
      'currentCyclePhase': currentCyclePhase,
      'averageCycleLength': averageCycleLength,
      'birthDate': birthDate?.toIso8601String(),
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
      'notificationsEnabled': notificationsEnabled,
      'workoutRemindersEnabled': workoutRemindersEnabled,
      'periodRemindersEnabled': periodRemindersEnabled,
      'subscriptionStatus': subscriptionStatus,
      'subscriptionExpiresAt': subscriptionExpiresAt?.toIso8601String(),
      'role': role,
      'isActive': isActive,
      'lastActiveAt': lastActiveAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  @override
  User copyWith({
    String? id,
    DateTime? created,
    DateTime? updated,
    String? email,
    String? name,
    String? username,
    String? avatarUrl,
    bool? emailVerified,
    String? preferredUnits,
    String? preferredTheme,
    String? timezone,
    bool? onboardingCompleted,
    String? fitnessGoals,
    String? currentCyclePhase,
    int? averageCycleLength,
    DateTime? birthDate,
    double? height,
    double? weight,
    String? activityLevel,
    bool? notificationsEnabled,
    bool? workoutRemindersEnabled,
    bool? periodRemindersEnabled,
    String? subscriptionStatus,
    DateTime? subscriptionExpiresAt,
    String? role,
    bool? isActive,
    DateTime? lastActiveAt,
  }) {
    return User(
      id: id ?? this.id,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      email: email ?? this.email,
      name: name ?? this.name,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      preferredUnits: preferredUnits ?? this.preferredUnits,
      preferredTheme: preferredTheme ?? this.preferredTheme,
      timezone: timezone ?? this.timezone,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      fitnessGoals: fitnessGoals ?? this.fitnessGoals,
      currentCyclePhase: currentCyclePhase ?? this.currentCyclePhase,
      averageCycleLength: averageCycleLength ?? this.averageCycleLength,
      birthDate: birthDate ?? this.birthDate,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      workoutRemindersEnabled:
          workoutRemindersEnabled ?? this.workoutRemindersEnabled,
      periodRemindersEnabled:
          periodRemindersEnabled ?? this.periodRemindersEnabled,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionExpiresAt:
          subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  /// Validate user data
  List<String> validate() {
    final errors = <String>[];

    // Email validation
    if (!Validators.isValidEmail(email)) {
      errors.add('Please enter a valid email address');
    }

    // Name validation
    if (name.trim().isEmpty) {
      errors.add('Name cannot be empty');
    } else if (name.trim().length < 2) {
      errors.add('Name must be at least 2 characters long');
    }

    // Username validation
    if (username.trim().isEmpty) {
      errors.add('Username cannot be empty');
    } else if (username.trim().length < 3) {
      errors.add('Username must be at least 3 characters long');
    } else if (!Validators.isValidUsername(username)) {
      errors.add('Username can only contain letters, numbers, and underscores');
    }

    // Weight validation (if provided)
    if (weight != null && (weight! < 20 || weight! > 500)) {
      errors.add('Weight must be between 20 and 500 kg');
    }

    // Height validation (if provided)
    if (height != null && (height! < 50 || height! > 300)) {
      errors.add('Height must be between 50 and 300 cm');
    }

    // Age validation (if birth date provided)
    if (birthDate != null) {
      final age = calculateAge();
      if (age != null && (age < 13 || age > 120)) {
        errors.add('Age must be between 13 and 120 years');
      }
    }

    // Cycle length validation (if provided)
    if (averageCycleLength != null &&
        (averageCycleLength! < 21 || averageCycleLength! > 35)) {
      errors.add('Average cycle length must be between 21 and 35 days');
    }

    return errors;
  }

  /// Calculate user's age from birth date
  int? calculateAge() {
    if (birthDate == null) return null;
    final now = DateTime.now();
    final age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      return age - 1;
    }
    return age;
  }

  /// Check if user has premium subscription
  bool get isPremium =>
      subscriptionStatus == 'premium' &&
      (subscriptionExpiresAt == null ||
          subscriptionExpiresAt!.isAfter(DateTime.now()));

  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  /// Get display name (preferred name or username)
  String get displayName => name.isNotEmpty ? name : username;

  /// Get user's initials for avatar
  String get initials {
    if (name.isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    return username.isNotEmpty ? username[0].toUpperCase() : '?';
  }

  /// Check if user prefers metric units
  bool get usesMetricUnits => preferredUnits == 'metric';

  /// Check if user prefers imperial units
  bool get usesImperialUnits => preferredUnits == 'imperial';

  /// Check if user needs to complete onboarding
  bool get needsOnboarding => !onboardingCompleted;

  /// Check if user profile is complete
  bool get isProfileComplete {
    return name.isNotEmpty &&
        email.isNotEmpty &&
        username.isNotEmpty &&
        birthDate != null &&
        height != null &&
        weight != null &&
        activityLevel != null;
  }

  /// Create a user for sign-up (minimal required data)
  factory User.forSignUp({
    required String email,
    required String name,
    required String username,
  }) {
    final now = DateTime.now();
    return User(
      id: '', // Will be set by PocketBase
      created: now,
      updated: now,
      email: email,
      name: name,
      username: username,
    );
  }

  /// Create empty user for initial state
  factory User.empty() {
    final now = DateTime.now();
    return User(
      id: '',
      created: now,
      updated: now,
      email: '',
      name: '',
      username: '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.username == username;
  }

  @override
  int get hashCode => Object.hash(id, email, name, username);

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, username: $username)';
  }
}

/// Enumeration for user roles
enum UserRole {
  user('user'),
  admin('admin');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'user':
      default:
        return UserRole.user;
    }
  }
}

/// Enumeration for subscription status
enum SubscriptionStatus {
  free('free'),
  premium('premium'),
  trial('trial'),
  expired('expired');

  const SubscriptionStatus(this.value);
  final String value;

  static SubscriptionStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'premium':
        return SubscriptionStatus.premium;
      case 'trial':
        return SubscriptionStatus.trial;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'free':
      default:
        return SubscriptionStatus.free;
    }
  }
}

/// Enumeration for activity levels
enum ActivityLevel {
  sedentary('sedentary'),
  lightlyActive('lightly_active'),
  moderatelyActive('moderately_active'),
  veryActive('very_active'),
  extremelyActive('extremely_active');

  const ActivityLevel(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
      case ActivityLevel.extremelyActive:
        return 'Extremely Active';
    }
  }

  static ActivityLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'lightly_active':
        return ActivityLevel.lightlyActive;
      case 'moderately_active':
        return ActivityLevel.moderatelyActive;
      case 'very_active':
        return ActivityLevel.veryActive;
      case 'extremely_active':
        return ActivityLevel.extremelyActive;
      case 'sedentary':
      default:
        return ActivityLevel.sedentary;
    }
  }
}

/// Enumeration for cycle phases
enum CyclePhase {
  menstrual('menstrual'),
  follicular('follicular'),
  ovulation('ovulation'),
  luteal('luteal');

  const CyclePhase(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Menstrual';
      case CyclePhase.follicular:
        return 'Follicular';
      case CyclePhase.ovulation:
        return 'Ovulation';
      case CyclePhase.luteal:
        return 'Luteal';
    }
  }

  static CyclePhase fromString(String value) {
    switch (value.toLowerCase()) {
      case 'follicular':
        return CyclePhase.follicular;
      case 'ovulation':
        return CyclePhase.ovulation;
      case 'luteal':
        return CyclePhase.luteal;
      case 'menstrual':
      default:
        return CyclePhase.menstrual;
    }
  }
}
