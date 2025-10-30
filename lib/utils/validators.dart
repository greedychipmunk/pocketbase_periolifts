/// Comprehensive validation utilities for the application
///
/// Provides reusable validation functions for common data types
/// and user input scenarios.
class Validators {
  /// Email validation using regex pattern
  ///
  /// [email] The email string to validate
  /// Returns true if email format is valid
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;

    // Comprehensive email regex pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    return emailRegex.hasMatch(email.trim());
  }

  /// Username validation
  ///
  /// [username] The username string to validate
  /// Returns true if username format is valid
  /// Rules:
  /// - 3-30 characters
  /// - Letters, numbers, underscores only
  /// - Cannot start or end with underscore
  static bool isValidUsername(String username) {
    if (username.isEmpty) return false;

    final cleanUsername = username.trim();

    // Length check
    if (cleanUsername.length < 3 || cleanUsername.length > 30) {
      return false;
    }

    // Pattern check: letters, numbers, underscores only
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(cleanUsername)) {
      return false;
    }

    // Cannot start or end with underscore
    if (cleanUsername.startsWith('_') || cleanUsername.endsWith('_')) {
      return false;
    }

    return true;
  }

  /// Password strength validation
  ///
  /// [password] The password string to validate
  /// Returns true if password meets strength requirements
  /// Requirements:
  /// - At least 8 characters
  /// - At least one uppercase letter
  /// - At least one lowercase letter
  /// - At least one number
  /// - At least one special character
  static bool isValidPassword(String password) {
    if (password.isEmpty || password.length < 8) {
      return false;
    }

    // Check for uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return false;
    }

    // Check for lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return false;
    }

    // Check for number
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return false;
    }

    // Check for special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return false;
    }

    return true;
  }

  /// Get password strength score (0-4)
  ///
  /// [password] The password to analyze
  /// Returns strength score:
  /// - 0: Very weak
  /// - 1: Weak
  /// - 2: Fair
  /// - 3: Good
  /// - 4: Strong
  static int getPasswordStrength(String password) {
    if (password.isEmpty) return 0;

    int score = 0;

    // Length bonus
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Character variety bonus
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    // Penalty for common patterns
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) score--; // Repeated characters
    if (RegExp(
      r'(123|abc|qwe|password|admin)',
      caseSensitive: false,
    ).hasMatch(password)) {
      score--; // Common patterns
    }

    return score.clamp(0, 4);
  }

  /// Get password strength description
  ///
  /// [password] The password to analyze
  /// Returns human-readable strength description
  static String getPasswordStrengthText(String password) {
    final strength = getPasswordStrength(password);
    switch (strength) {
      case 0:
        return 'Very Weak';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return 'Unknown';
    }
  }

  /// Name validation
  ///
  /// [name] The name string to validate
  /// Returns true if name format is valid
  static bool isValidName(String name) {
    if (name.isEmpty) return false;

    final cleanName = name.trim();

    // Length check (2-50 characters)
    if (cleanName.length < 2 || cleanName.length > 50) {
      return false;
    }

    // Pattern check: letters, spaces, hyphens, apostrophes only
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    return nameRegex.hasMatch(cleanName);
  }

  /// Phone number validation (basic format)
  ///
  /// [phone] The phone number string to validate
  /// Returns true if phone format is valid
  static bool isValidPhoneNumber(String phone) {
    if (phone.isEmpty) return false;

    // Remove all non-digit characters for validation
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Check length (7-15 digits)
    return digitsOnly.length >= 7 && digitsOnly.length <= 15;
  }

  /// URL validation
  ///
  /// [url] The URL string to validate
  /// Returns true if URL format is valid
  static bool isValidUrl(String url) {
    if (url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Age validation
  ///
  /// [birthDate] The birth date to validate
  /// [minAge] Minimum allowed age (default: 13)
  /// [maxAge] Maximum allowed age (default: 120)
  /// Returns true if age is within valid range
  static bool isValidAge(
    DateTime birthDate, {
    int minAge = 13,
    int maxAge = 120,
  }) {
    final now = DateTime.now();
    final age = now.year - birthDate.year;
    final adjustedAge =
        (now.month < birthDate.month ||
            (now.month == birthDate.month && now.day < birthDate.day))
        ? age - 1
        : age;

    return adjustedAge >= minAge && adjustedAge <= maxAge;
  }

  /// Weight validation (in kilograms)
  ///
  /// [weight] The weight value to validate
  /// Returns true if weight is within reasonable range
  static bool isValidWeight(double? weight) {
    if (weight == null) return false;
    return weight >= 20 && weight <= 500; // 20kg to 500kg
  }

  /// Height validation (in centimeters)
  ///
  /// [height] The height value to validate
  /// Returns true if height is within reasonable range
  static bool isValidHeight(double? height) {
    if (height == null) return false;
    return height >= 50 && height <= 300; // 50cm to 300cm
  }

  /// Cycle length validation (in days)
  ///
  /// [cycleLength] The cycle length to validate
  /// Returns true if cycle length is within normal range
  static bool isValidCycleLength(int? cycleLength) {
    if (cycleLength == null) return false;
    return cycleLength >= 21 && cycleLength <= 35; // 21-35 days
  }

  /// Generic required field validation
  ///
  /// [value] The value to validate
  /// Returns true if value is not null and not empty
  static bool isRequired(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Generic minimum length validation
  ///
  /// [value] The string to validate
  /// [minLength] Minimum required length
  /// Returns true if string meets minimum length requirement
  static bool hasMinLength(String? value, int minLength) {
    return value != null && value.trim().length >= minLength;
  }

  /// Generic maximum length validation
  ///
  /// [value] The string to validate
  /// [maxLength] Maximum allowed length
  /// Returns true if string is within maximum length
  static bool hasMaxLength(String? value, int maxLength) {
    return value != null && value.trim().length <= maxLength;
  }

  /// Numeric range validation
  ///
  /// [value] The numeric value to validate
  /// [min] Minimum allowed value
  /// [max] Maximum allowed value
  /// Returns true if value is within range
  static bool isInRange(num? value, num min, num max) {
    return value != null && value >= min && value <= max;
  }

  /// Date range validation
  ///
  /// [date] The date to validate
  /// [minDate] Minimum allowed date
  /// [maxDate] Maximum allowed date
  /// Returns true if date is within range
  static bool isDateInRange(
    DateTime? date,
    DateTime? minDate,
    DateTime? maxDate,
  ) {
    if (date == null) return false;

    if (minDate != null && date.isBefore(minDate)) return false;
    if (maxDate != null && date.isAfter(maxDate)) return false;

    return true;
  }

  /// File extension validation
  ///
  /// [fileName] The file name to validate
  /// [allowedExtensions] List of allowed file extensions
  /// Returns true if file extension is allowed
  static bool hasValidFileExtension(
    String fileName,
    List<String> allowedExtensions,
  ) {
    if (fileName.isEmpty) return false;

    final extension = fileName.split('.').last.toLowerCase();
    return allowedExtensions.map((e) => e.toLowerCase()).contains(extension);
  }

  /// Image file validation
  ///
  /// [fileName] The file name to validate
  /// Returns true if file is a valid image format
  static bool isValidImageFile(String fileName) {
    return hasValidFileExtension(fileName, [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
    ]);
  }
}
