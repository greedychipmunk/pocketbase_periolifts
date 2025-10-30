import 'package:flutter/material.dart';

// Electric Blue Futuristic Theme Configuration (Issue #42)
// This theme implements the Electric Blue color palette specifically requested in issue #42
// Base configuration shared between light and dark themes
abstract class BaseThemeConfig {
  // Futuristic Electric Blue color palette (Issue #42) - maintaining Electric Blue theme
  static const Color primaryColor = Color(0xFF0077FF); // Electric Blue (Issue #42)
  static const Color accentColor = Color(0xFF00FFFF); // Cyan Accent
  static const Color secondaryColor = Color(0xFF6B46C1); // Purple
  
  // Modern gradient colors for futuristic effects
  static const Color gradientStart = Color(0xFF0077FF); // Electric Blue
  static const Color gradientEnd = Color(0xFF00FFFF); // Cyan
  
  // App bar colors - futuristic gradient-inspired
  static const Color appBarBackgroundColor = Color(0xFF0077FF); // Electric Blue
  static const Color appBarForegroundColor = Colors.white;
  
  // Modern styling values - enhanced for futuristic look
  static const double appBarElevation = 4.0;
  static const double bottomNavigationBarElevation = 12.0;
  static const double elevatedButtonElevation = 6.0;
  static const double cardElevation = 8.0;

  static const EdgeInsets elevatedButtonPadding = EdgeInsets.symmetric(horizontal: 32, vertical: 16);
  static const BorderRadius elevatedButtonBorderRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius cardBorderRadius = BorderRadius.all(Radius.circular(20));
  static const BorderRadius containerBorderRadius = BorderRadius.all(Radius.circular(12));
  
  // App bar theme with futuristic styling
  static AppBarTheme appBarTheme() {
    return const AppBarTheme(
      centerTitle: true,
      elevation: appBarElevation,
      backgroundColor: appBarBackgroundColor,
      foregroundColor: appBarForegroundColor,
      surfaceTintColor: Colors.transparent,
    );
  }
  
  // Modern elevated button theme with futuristic styling
  static ElevatedButtonThemeData elevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: elevatedButtonElevation,
        padding: elevatedButtonPadding,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: elevatedButtonBorderRadius,
        ),
        shadowColor: accentColor.withOpacity(0.3),
      ),
    );
  }
  
  // Modern bottom navigation bar theme
  static BottomNavigationBarThemeData bottomNavigationBarTheme() {
    return const BottomNavigationBarThemeData(
      elevation: bottomNavigationBarElevation,
      type: BottomNavigationBarType.fixed,
    );
  }
  
  // Futuristic card theme
  static CardThemeData cardTheme() {
    return CardThemeData(
      elevation: cardElevation,
      shape: const RoundedRectangleBorder(
        borderRadius: cardBorderRadius,
      ),
      shadowColor: accentColor.withOpacity(0.1),
    );
  }
}

// Light theme with futuristic styling
class LightThemeConfig extends BaseThemeConfig {
  // Light theme specific colors with Electric Blue theme
  static const Color surfaceColor = Color(0xFFF8F9FF); // Very light blue-tinted white
  static const Color onSurfaceColor = Color(0xFF1A1A1A);
  static const Color backgroundColor = Color(0xFFFCFCFF);
  
  static ColorScheme colorScheme() {
    return ColorScheme.fromSeed(
      seedColor: BaseThemeConfig.primaryColor,
      brightness: Brightness.light,
      primary: BaseThemeConfig.primaryColor,
      secondary: BaseThemeConfig.secondaryColor,
      tertiary: BaseThemeConfig.accentColor,
      surface: surfaceColor,
      onSurface: onSurfaceColor,
      background: backgroundColor,
    );
  }
  
  static ThemeData themeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme(),
      appBarTheme: BaseThemeConfig.appBarTheme(),
      elevatedButtonTheme: BaseThemeConfig.elevatedButtonTheme(),
      bottomNavigationBarTheme: BaseThemeConfig.bottomNavigationBarTheme(),
      cardTheme: BaseThemeConfig.cardTheme(),
      scaffoldBackgroundColor: backgroundColor,
    );
  }
}

// Dark theme with enhanced futuristic styling
class DarkThemeConfig extends BaseThemeConfig {
  // Dark theme futuristic colors - GitHub-inspired deep backgrounds
  static const Color scaffoldBackgroundColor = Color(0xFF0D1117); // Very deep blue-black
  static const Color surfaceColor = Color(0xFF161B22); // Dark blue-grey
  static const Color listTileColor = Color(0xFF21262D); // Slightly lighter dark blue
  static const Color cardColor = Color(0xFF161B22); // Dark blue card background
  static const Color onSurfaceColor = Color(0xFFF0F6FC); // Light blue-tinted white
  
  // Futuristic accent colors for dark mode with Electric Blue theme
  static const Color primaryDark = Color(0xFF0077FF); // Electric Blue for dark mode
  static const Color accentDark = Color(0xFF00FFFF); // Bright cyan
  static const Color secondaryDark = Color(0xFF6B46C1); // Purple
  
  static ColorScheme colorScheme() {
    return ColorScheme.fromSeed(
      seedColor: BaseThemeConfig.primaryColor,
      brightness: Brightness.dark,
      primary: primaryDark,
      secondary: secondaryDark,
      tertiary: accentDark,
      surface: surfaceColor,
      onSurface: onSurfaceColor,
      background: scaffoldBackgroundColor,
    );
  }
  
  static ListTileThemeData listTileTheme() {
    return ListTileThemeData(
      tileColor: listTileColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BaseThemeConfig.containerBorderRadius,
      ),
    );
  }
  
  // Enhanced card theme for dark mode with futuristic styling
  static CardThemeData cardTheme() {
    return CardThemeData(
      elevation: BaseThemeConfig.cardElevation,
      color: cardColor,
      shadowColor: BaseThemeConfig.accentColor.withOpacity(0.2),
      shape: const RoundedRectangleBorder(
        borderRadius: BaseThemeConfig.cardBorderRadius,
      ),
    );
  }
  
  static ThemeData themeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme(),
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      appBarTheme: BaseThemeConfig.appBarTheme(),
      elevatedButtonTheme: BaseThemeConfig.elevatedButtonTheme(),
      bottomNavigationBarTheme: BaseThemeConfig.bottomNavigationBarTheme(),
      listTileTheme: listTileTheme(),
      cardTheme: cardTheme(),
    );
  }
}

// Legacy compatibility class
class ThemeConfig extends BaseThemeConfig {
  static ColorScheme lightColorScheme() => LightThemeConfig.colorScheme();
  static ColorScheme darkColorScheme() => DarkThemeConfig.colorScheme();
  static ListTileThemeData darkListTileTheme() => DarkThemeConfig.listTileTheme();
  static const Color darkScaffoldBackgroundColor = DarkThemeConfig.scaffoldBackgroundColor;
}